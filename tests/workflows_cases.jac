"""Integration tests exercise the actual compiled Jac workflows and HTTP access."""
import from typing { Any }
import base64;
import http.cookiejar;
import json;
import os;
import from pathlib { Path }
import tempfile;
import threading;
import unittest;
import from unittest.mock { patch }
import from urllib.error { HTTPError }
import from urllib.request { build_opener, HTTPCookieProcessor, Request }
import jaclang;
import domain;
import server;
class VehicleWorkflows(unittest.TestCase) {
    def setUp(self: VehicleWorkflows) -> Any {
        self.state = {"vehicles": [], "listings": []};
        self.vehicle = domain.dispatch(
            self.state,
            "register_vehicle",
            {
                "plate": "KAA 123A",
                "make": "Toyota",
                "model": "Hilux",
                "year": 2020,
                "odometer": 1000,
                "vin": "TESTVIN"
            }
        );
    }
    def record(self: VehicleWorkflows, day: Any, reading: Any, **fields: Any) -> Any {
        return domain.dispatch(
            self.state,
            "add_record",
            (
                {} | {"vehicle_id": self.vehicle["id"]} | {"date": day} | {
                    "odometer": reading
                } | {"type": "odometer"} | {"title": "Reading"} | fields
            )
        );
    }
    def test_graph_passport_and_duplicate_identity(self: VehicleWorkflows) -> Any {
        self.record("2026-01-01", 1100);
        result = domain.passport(self.state, self.vehicle["id"]);
        self.assertEqual(result["records"][0]["odometer"], 1100);
        with self.assertRaisesRegex(ValueError, "already exists") {
            domain.register_vehicle(
                self.state,
                {
                    "plate": "kaa 123a",
                    "vin": "",
                    "make": "X",
                    "model": "Y",
                    "year": 2020
                }
            );
        }
    }
    def test_full_tank_interval_includes_partial_fills(self: VehicleWorkflows) -> Any {
        self.record(
            "2026-01-01",
            1000,
            `type="fuel",
            litres=50,
            cost=10000,
            currency="KES",
            full_tank=True
        );
        self.record(
            "2026-01-02",
            1200,
            `type="fuel",
            litres=20,
            cost=4000,
            currency="KES",
            full_tank=False
        );
        self.record(
            "2026-01-03",
            1500,
            `type="fuel",
            litres=30,
            cost=6000,
            currency="KES",
            full_tank=True
        );
        result = domain.fuel_summary(self.vehicle["records"]);
        self.assertEqual(result["latest_economy"], 10);
        self.assertEqual(result["cycles"][0]["cost_per_km"]["KES"], 20);
        self.assertEqual(result["costs"]["KES"], 20000);
    }
    def test_incomplete_interval_and_mixed_currency(self: VehicleWorkflows) -> Any {
        self.record(
            "2026-01-01",
            1000,
            `type="fuel",
            litres=10,
            cost=20,
            currency="USD",
            full_tank=False
        );
        self.record(
            "2026-01-02",
            1200,
            `type="fuel",
            litres=20,
            cost=4000,
            currency="KES",
            full_tank=True
        );
        result = domain.fuel_summary(self.vehicle["records"]);
        self.assertIsNone(result["latest_economy"]);
        self.assertEqual(result["costs"], {"USD": 20, "KES": 4000});
    }
    def test_backdated_odometer_and_nonfinite_input_are_rejected(
        self: VehicleWorkflows
    ) -> Any {
        self.record("2026-01-10", 1200);
        with self.assertRaises(ValueError) {
            self.record("2026-01-01", 1300);
        }
        with self.assertRaises(ValueError) {
            self.record("2026-01-11", float("nan"));
        }
    }
    def test_correction_retains_original(self: VehicleWorkflows) -> Any {
        original = self.record("2026-01-01", 1200);
        correction = self.record(
            "2026-01-01", 1150, corrects=original["id"], title="Corrected reading"
        );
        self.assertEqual(original["superseded_by"], correction["id"]);
        self.assertEqual(len(self.vehicle["records"]), 2);
        self.assertEqual(domain.snapshot(self.state)["vehicles"][0]["odometer"], 1150);
        with self.assertRaises(ValueError) {
            self.record("2026-01-01", 1175, corrects=original["id"]);
        }
    }
    def test_market_history_excludes_private_fields(self: VehicleWorkflows) -> Any {
        record = self.record(
            "2026-01-01", 1100, notes="PRIVATE NOTES", document="PRIVATE DOCUMENT"
        );
        listing = domain.publish_listing(
            self.state,
            {
                "vehicle_id": self.vehicle["id"],
                "price": 50000,
                "location": "Nairobi",
                "description": "For sale",
                "shared_record_ids": [record["id"]]
            }
        );
        serialized = json.dumps(listing);
        self.assertNotIn("PRIVATE", serialized);
        self.assertNotIn("TESTVIN", serialized);
        self.assertEqual(len(listing["history"]), 1);
        with self.assertRaises(ValueError) {
            domain.publish_listing(self.state, {"vehicle_id": self.vehicle["id"]});
        }
    }
    def test_mint_metadata_is_optional_and_excludes_private_identity(
        self: VehicleWorkflows
    ) -> Any {
        result = domain.mint_metadata(self.state, self.vehicle["id"]);
        self.assertNotIn("TESTVIN", json.dumps(result));
        self.assertNotIn("KAA 123A", json.dumps(result));
        self.assertIsNone(self.vehicle["mint"]);
    }
}
class HTTPAccess(unittest.TestCase) {
    @classmethod
    def setUpClass(cls: Any) -> Any {
        cls.temp = tempfile.TemporaryDirectory();
        server.DB_PATH = Path(cls.temp.name) / "test.db";
        server.initialize();
        cls.http = server.HTTPServer(("127.0.0.1", 0), server.Handler);
        cls.url = f"http://127.0.0.1:{cls.http.server_port}";
        cls.thread = threading.Thread(target=cls.http.serve_forever, daemon=True);
        cls.thread.start();
    }
    @classmethod
    def tearDownClass(cls: Any) -> Any {
        cls.http.shutdown();
        cls.http.server_close();
        cls.thread.join(timeout=5);
        cls.temp.cleanup();
    }
    def client(self: HTTPAccess) -> Any {
        return build_opener(HTTPCookieProcessor(http.cookiejar.CookieJar()));
    }
    def request(
        self: HTTPAccess,
        client: Any,
        path: Any,
        payload: Any = None,
        origin: Any = None
    ) -> Any {
        headers = {};
        if (payload is not None) {
            headers["Content-Type"] = "application/json";
        }
        if origin {
            headers["Origin"] = origin;
        }
        req = Request(
            (self.url + path),
            data=None if (payload is None) else json.dumps(payload).encode(),
            headers=headers
        );
        try {
            with client.open(req) as response {
                return (response.status, json.loads(response.read()));
            }
        } except HTTPError as error {
            return (error.code, json.loads(error.read()));
        }
    }
    def account(self: HTTPAccess, suffix: Any) -> Any {
        client = self.client();
        (status, _) = self.request(
            client,
            "/api/signup",
            {
                "email": (suffix + "@test.invalid"),
                "name": suffix,
                "password": "test-password-123"
            }
        );
        self.assertEqual(status, 200);
        return client;
    }
    def test_agent_approval_is_owned_atomic_idempotent_and_rejects_stale_changes(
        self: HTTPAccess
    ) -> Any {
        import agent_runtime;
        import ai_service;
        import from test_agent { response, turn }
        (owner, stranger) = (
            self.account("agent-owner"),
            self.account("agent-stranger")
        );
        (_, registered) = self.request(
            owner,
            "/api/workflow",
            {
                "action": "register_vehicle",
                "payload": {
                    "plate": "KAA 555A",
                    "make": "Toyota",
                    "model": "Hilux",
                    "year": 2021,
                    "odometer": 1000
                }
            }
        );
        vehicle_id = registered["result"]["id"];
        args = {
            "vehicle_id": vehicle_id,
            "type": "inspection",
            "title": "Reviewed inspection",
            "date": "2026-10-13",
            "odometer": 1100
        };
        def propose() -> Any {
            with patch.object(
                agent_runtime,
                "urlopen",
                side_effect=[
                    response(turn("propose_add_record", args)),
                    response(turn(text="Test proposal awaiting approval"))
                ]
            ), patch.object(
                ai_service,
                "load_ai_config",
                return_value=("test-key", "gemini/gemini-3.8-flash")
            ) {
                (status, result) = self.request(
                    owner,
                    "/api/agent/chat",
                    {
                        "message": "Record inspection today at 1100 km",
                        "vehicle_id": vehicle_id
                    }
                );
            }
            self.assertEqual(status, 200, result);
            self.assertNotIn("state_hash", str(result));
            return result;
        }
        chat = propose();
        proposal_id = chat["proposals"][0]["id"];
        self.assertEqual(
            self.request(owner, "/api/state")[1]["vehicles"][0]["records"], []
        );
        self.assertEqual(
            self.request(stranger, "/api/agent/approve", {"proposal_id": proposal_id})[
                0
            ],
            400
        );
        self.assertEqual(
            self.request(
                stranger,
                "/api/agent/chat",
                {"message": "Read", "session_id": chat["session_id"]}
            )[0],
            400
        );
        (status, applied) = self.request(
            owner,
            "/api/agent/approve",
            {"proposal_id": proposal_id, "payload": {"title": "Tampered title"}}
        );
        self.assertEqual(status, 200, applied);
        self.assertEqual(applied["result"]["title"], "Reviewed inspection");
        self.assertTrue(
            self.request(owner, "/api/agent/approve", {"proposal_id": proposal_id})[1][
                "already_applied"
            ]
        );
        self.assertEqual(
            len(self.request(owner, "/api/state")[1]["vehicles"][0]["records"]), 1
        );
        with patch.object(
            agent_runtime,
            "urlopen",
            side_effect=[
                response(turn("search_vehicles", {})),
                response(turn(text="Test continued conversation"))
            ]
        ) as transport, patch.object(
            ai_service,
            "load_ai_config",
            return_value=("test-key", "gemini/gemini-3.8-flash")
        ) {
            self.assertEqual(
                self.request(
                    owner,
                    "/api/agent/chat",
                    {"message": "Was it saved?", "session_id": chat["session_id"]}
                )[0],
                200
            );
        }
        continued = json.loads(transport.call_args_list[0].args[0].data);
        previous_proposal = continued["contents"][2]["parts"][0]["functionResponse"][
            "response"
        ];
        self.assertEqual(previous_proposal["proposal_status"], "applied");
        stale = propose()["proposals"][0]["id"];
        self.request(
            owner,
            "/api/workflow",
            {
                "action": "add_record",
                "payload": ({} | args | {"title": "Manual update"})
            }
        );
        self.assertEqual(
            self.request(owner, "/api/agent/approve", {"proposal_id": stale})[0], 409
        );
        self.assertEqual(
            len(self.request(owner, "/api/state")[1]["vehicles"][0]["records"]), 2
        );
        rejected = propose()["proposals"][0]["id"];
        self.assertEqual(
            self.request(owner, "/api/agent/reject", {"proposal_id": rejected})[1][
                "status"
            ],
            "rejected"
        );
        self.assertEqual(
            self.request(owner, "/api/agent/approve", {"proposal_id": rejected})[0], 400
        );
        before = self.request(owner, "/api/state")[1]["vehicles"];
        with patch.object(
            agent_runtime,
            "urlopen",
            side_effect=[
                response(turn("propose_add_record", args)),
                ai_service.AIUnavailable("Test provider failure")
            ]
        ), patch.object(
            ai_service,
            "load_ai_config",
            return_value=("test-key", "gemini/gemini-3.8-flash")
        ) {
            self.assertEqual(
                self.request(
                    owner, "/api/agent/chat", {"message": "Prepare inspection"}
                )[0],
                503
            );
        }
        self.assertEqual(before, self.request(owner, "/api/state")[1]["vehicles"]);
    }
    def test_account_settings_profile_password_preferences_and_isolation(
        self: HTTPAccess
    ) -> Any {
        (owner, other) = (
            self.account("settings-owner"),
            self.account("settings-other")
        );
        self.assertEqual(self.request(self.client(), "/api/settings")[0], 401);
        self.assertEqual(
            self.request(
                owner,
                "/api/settings/profile",
                {
                    "name": "New name",
                    "email": "changed@test.invalid",
                    "email_password": "wrong"
                }
            )[0],
            400
        );
        self.assertEqual(
            self.request(
                owner,
                "/api/settings/profile",
                {
                    "name": "New name",
                    "email": "changed@test.invalid",
                    "email_password": "test-password-123"
                }
            )[0],
            200
        );
        self.assertEqual(
            self.request(owner, "/api/state")[1]["user"]["name"], "New name"
        );
        self.assertEqual(
            self.request(
                owner,
                "/api/settings/profile",
                {
                    "name": "Collision",
                    "email": "settings-other@test.invalid",
                    "email_password": "test-password-123"
                }
            )[0],
            409
        );
        self.assertEqual(
            self.request(
                owner,
                "/api/settings/preferences",
                {"currency": "USD", "start_page": "assistant"}
            )[0],
            200
        );
        self.assertEqual(self.request(other, "/api/settings")[1]["currency"], "KES");
        self.assertEqual(
            self.request(
                owner,
                "/api/settings/preferences",
                {"currency": "BTC", "start_page": "garage"}
            )[0],
            400
        );
        second = self.client();
        self.assertEqual(
            self.request(
                second,
                "/api/login",
                {"email": "changed@test.invalid", "password": "test-password-123"}
            )[0],
            200
        );
        self.assertEqual(
            self.request(
                owner,
                "/api/settings/password",
                {"current_password": "wrong", "new_password": "new-password-123"}
            )[0],
            400
        );
        self.assertEqual(
            self.request(
                owner,
                "/api/settings/password",
                {
                    "current_password": "test-password-123",
                    "new_password": "new-password-123"
                }
            )[0],
            200
        );
        self.assertEqual(self.request(second, "/api/state")[0], 401);
        self.assertEqual(self.request(owner, "/api/state")[0], 200);
        self.assertEqual(
            self.request(
                self.client(),
                "/api/login",
                {"email": "changed@test.invalid", "password": "test-password-123"}
            )[0],
            401
        );
        signed_in = self.client();
        self.assertEqual(
            self.request(
                signed_in,
                "/api/login",
                {"email": "changed@test.invalid", "password": "new-password-123"}
            )[0],
            200
        );
        self.assertEqual(
            self.request(signed_in, "/api/settings")[1]["currency"], "USD"
        );
    }
    def test_personal_keys_are_encrypted_scoped_and_used_for_all_ai_paths(
        self: HTTPAccess
    ) -> Any {
        import account_settings;
        import agent_runtime;
        import ai_service;
        import gemini_gateway;
        import from test_agent { response, turn }
        (owner, other) = (self.account("key-owner"), self.account("key-other"));
        config = {
            "model": "gemini/gemini-3.8-flash",
            "api_key": "test-only-personal-key",
            "ai_enabled": True,
            "use_server_ai": False
        };
        (status, settings) = self.request(owner, "/api/settings/ai", config);
        self.assertEqual(status, 200, settings);
        self.assertEqual(settings["ai"]["source"], "personal");
        self.assertNotIn(config["api_key"], str(settings));
        user_id = self.request(owner, "/api/state")[1]["user"]["id"];
        with server.database() as db {
            credential = db.execute(
                "SELECT credential FROM account_settings WHERE user_id=?", (user_id, )
            ).fetchone()[0];
            self.assertNotIn(config["api_key"], credential);
            self.assertEqual(
                account_settings.effective_config(db, user_id)[0], config["api_key"]
            );
        }
        self.assertFalse(self.request(other, "/api/settings")[1]["personal_key_saved"]);
        self.request(owner, "/api/settings/ai", ({} | config | {"api_key": ""}));
        with patch.object(
            agent_runtime,
            "urlopen",
            return_value=response(turn(text="Test personal-key response"))
        ) as transport {
            self.assertEqual(
                self.request(owner, "/api/agent/chat", {"message": "Hello"})[0], 200
            );
        }
        self.assertEqual(
            transport.call_args.args[0].get_header("X-goog-api-key"), config["api_key"]
        );
        (_, registration) = self.request(
            owner,
            "/api/workflow",
            {
                "action": "register_vehicle",
                "payload": {
                    "plate": "KAA 888A",
                    "make": "Ford",
                    "model": "Ranger",
                    "year": 2020,
                    "odometer": 1000
                }
            }
        );
        vehicle_id = registration["result"]["id"];
        import from io { BytesIO }
        for (endpoint, result) in [
            (
                "review",
                {"overview": "No events", "highlights": [], "gaps": ["No history"]}
            ),
            ("draft", {"description": "Test draft", "record_ids": []}),
            ("diagnosis", {"summary": "A tentative symptoms-only assessment.", "urgency": "soon", "possible_causes": [], "next_checks": ["Arrange qualified inspection."], "questions": []})
        ] {
            envelope = {
                "candidates": [
                    {
                        "finishReason": "STOP",
                        "content": {"parts": [{"text": json.dumps(result)}]}
                    }
                ]
            };
            with patch.object(
                gemini_gateway,
                "urlopen",
                return_value=BytesIO(json.dumps(envelope).encode())
            ) as transport {
                (status, output) = self.request(
                    owner,
                    ("/api/ai/" + endpoint),
                    {"vehicle_id": vehicle_id, "shared_record_ids": [], "symptoms": "A vibration occurs at idle after starting."}
                );
                self.assertEqual(status, 200, output);
                self.assertEqual(
                    transport.call_args.args[0].get_header("X-goog-api-key"),
                    config["api_key"]
                );
            }
        }
        self.assertEqual(self.request(other, "/api/ai/diagnosis", {"vehicle_id": vehicle_id, "symptoms": "A vibration occurs at idle."})[0], 400);
        with patch.object(
            account_settings, "urlopen", return_value=response(turn(text="OK"))
        ) as transport {
            self.assertTrue(self.request(owner, "/api/settings/test-ai", {})[1]["ok"]);
            self.assertEqual(
                transport.call_args.args[0].get_header("X-goog-api-key"),
                config["api_key"]
            );
        }
        self.request(
            owner,
            "/api/settings/ai",
            ({} | config | {"api_key": ""} | {"ai_enabled": False})
        );
        with patch.object(agent_runtime, "urlopen") as transport {
            self.assertEqual(
                self.request(owner, "/api/agent/chat", {"message": "Hello"})[0], 503
            );
            transport.assert_not_called();
        }
        self.assertFalse(
            self.request(owner, "/api/settings/remove-key", {})[1]["personal_key_saved"]
        );
        self.assertFalse(self.request(owner, "/api/settings")[1]["ai"]["available"]);
        self.assertIsNone(ai_service.REQUEST_CONFIG.get());
    }
    def test_auth_isolation_persistence_and_logout(self: HTTPAccess) -> Any {
        (alice, bob) = (self.account("alice"), self.account("bob"));
        self.assertEqual(self.request(self.client(), "/api/state")[0], 401);
        (_, result) = self.request(
            alice,
            "/api/workflow",
            {
                "action": "register_vehicle",
                "payload": {
                    "plate": "KAA 444A",
                    "make": "Mazda",
                    "model": "CX5",
                    "year": 2022,
                    "odometer": 100
                }
            }
        );
        vehicle_id = result["result"]["id"];
        self.assertEqual(self.request(bob, "/api/state")[1]["vehicles"], []);
        (status, _) = self.request(
            bob,
            "/api/workflow",
            {"action": "add_record", "payload": {"vehicle_id": vehicle_id}}
        );
        self.assertEqual(status, 400);
        (_, state) = self.request(alice, "/api/state");
        self.assertEqual(state["vehicles"][0]["id"], vehicle_id);
        self.request(alice, "/api/logout", {});
        self.assertEqual(self.request(alice, "/api/state")[0], 401);
        self.assertEqual(
            self.request(
                alice,
                "/api/login",
                {"email": "alice@test.invalid", "password": "test-password-123"}
            )[0],
            200
        );
        self.assertEqual(
            self.request(alice, "/api/state")[1]["vehicles"][0]["id"], vehicle_id
        );
        with server.database() as db {
            persisted = server.load_state(db, state["user"]["id"]);
        }
        self.assertEqual(persisted["vehicles"][0]["id"], vehicle_id);
    }
    def test_private_document_and_cross_origin_request(self: HTTPAccess) -> Any {
        (owner, stranger) = (self.account("owner"), self.account("stranger"));
        (status, result) = self.request(
            owner,
            "/api/upload",
            {
                "name": "receipt.pdf",
                "mime": "application/pdf",
                "content": base64.b64encode(b'%PDF-1.4\nTest receipt').decode()
            }
        );
        self.assertEqual(status, 200);
        self.assertEqual(
            self.request(stranger, ("/api/files/" + result["id"]))[0], 404
        );
        self.assertEqual(
            self.request(
                owner,
                "/api/workflow",
                {"action": "snapshot"},
                origin="https://untrusted.invalid"
            )[0],
            403
        );
    }
    def test_failed_workflow_does_not_persist_partial_state(self: HTTPAccess) -> Any {
        client = self.account("rollback");
        (status, _) = self.request(
            client,
            "/api/workflow",
            {
                "action": "register_vehicle",
                "payload": {
                    "plate": "KAA 666A",
                    "make": "Toyota",
                    "model": "Hilux",
                    "year": "invalid"
                }
            }
        );
        self.assertEqual(status, 400);
        self.assertEqual(self.request(client, "/api/state")[1]["vehicles"], []);
    }
    def test_marketplace_offer_and_demo_separation(self: HTTPAccess) -> Any {
        (seller, buyer) = (self.account("seller"), self.account("buyer"));
        (_, created) = self.request(
            seller,
            "/api/workflow",
            {
                "action": "register_vehicle",
                "payload": {
                    "plate": "KAA 777A",
                    "make": "Toyota",
                    "model": "Hilux",
                    "year": 2021,
                    "odometer": 1000
                }
            }
        );
        vehicle_id = created["result"]["id"];
        (_, published) = self.request(
            seller,
            "/api/workflow",
            {
                "action": "publish_listing",
                "payload": {
                    "vehicle_id": vehicle_id,
                    "price": 1200000,
                    "location": "Nairobi",
                    "description": "For sale",
                    "shared_record_ids": []
                }
            }
        );
        listing_id = published["result"]["id"];
        (status, _) = self.request(
            buyer,
            "/api/offer",
            {
                "listing_id": listing_id,
                "amount": 1100000,
                "message": "Can I arrange a viewing?"
            }
        );
        self.assertEqual(status, 200);
        self.assertEqual(
            self.request(seller, "/api/state")[1]["offers"][0]["amount"], 1100000
        );
        demo = self.client();
        self.assertEqual(self.request(demo, "/api/demo", {})[0], 200);
        self.assertTrue(
            all(item["demo"] for item in self.request(demo, "/api/state")[1]["market"])
        );
        self.assertTrue(
            all(
                not item["demo"]
                for item in self.request(buyer, "/api/state")[1]["market"]
            )
        );
        self.assertEqual(
            self.request(
                demo,
                "/api/offer",
                {"listing_id": listing_id, "amount": 1, "message": "Demo"}
            )[0],
            400
        );
        (status, public) = self.request(self.client(), "/api/public/market");
        self.assertEqual(status, 200);
        listed = [item for item in public["listings"] if item["id"] == listing_id];
        self.assertEqual(len(listed), 1);
        self.assertEqual(listed[0]["seller"], "seller");
        self.assertTrue(all(item.get("seller") != "Demo" for item in public["listings"]));
        exposed = json.dumps(public);
        for private in ["KAA 777A", "seller_id", "vehicle_id", "@test.invalid", '"demo"'] {
            self.assertNotIn(private, exposed);
        }
    }
}
with entry {
    if (__name__ == "__main__") {
        unittest.main();
    }
}
