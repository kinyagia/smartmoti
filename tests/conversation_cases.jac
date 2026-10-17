"""Owned conversation recovery exercises real HTTP, SQLite and Jac approval."""
import json;
import tempfile;
import threading;
import unittest;
import from pathlib { Path }
import from unittest.mock { patch }
import server;
import agent_runtime;
import ai_service;
import support;
import tests.workflows_cases as workflow_tests;
import from tests.agent_cases { response, turn }

class ConversationRecovery(unittest.TestCase) {
    def test_legacy_native_sessions_remain_private_and_do_not_continue_invisibly(self: ConversationRecovery) -> any {
        owner = self.account("conversation-legacy");
        with server.database() as db {
            user_id = db.execute("SELECT id FROM users WHERE email=?", ("conversation-legacy@test.invalid",)).fetchone()[0];
            session_id = support.identifier();
            native = json.dumps([{"role": "model", "parts": [{"text": "Private native-only session", "thoughtSignature": "legacy-signature"}]}]);
            db.execute("INSERT INTO agent_sessions VALUES (?,?,?,?)", (session_id, user_id, native, support.now()));
        }
        (_, recovered) = self.request(owner, "/api/agent/conversation");
        self.assertEqual(recovered["messages"], []);
        self.assertIsNone(recovered["session_id"]);
        self.assertNotIn("legacy-signature", json.dumps(recovered));
        with server.database() as db {
            self.assertEqual(db.execute("SELECT contents FROM agent_sessions WHERE id=?", (session_id,)).fetchone()[0], native);
        }
    }
    @classmethod
    def setUpClass(cls: any) -> any {
        cls.temp = tempfile.TemporaryDirectory();
        cls.previous_db = server.DB_PATH;
        server.DB_PATH = Path(cls.temp.name) / "conversation.db";
        server.initialize();
        cls.http = server.HTTPServer(("127.0.0.1", 0), server.Handler);
        cls.url = f"http://127.0.0.1:{cls.http.server_port}";
        cls.thread = threading.Thread(target=cls.http.serve_forever, daemon=True);
        cls.thread.start();
    }

    @classmethod
    def tearDownClass(cls: any) -> any {
        cls.http.shutdown();
        cls.http.server_close();
        cls.thread.join(timeout=5);
        server.DB_PATH = cls.previous_db;
        cls.temp.cleanup();
    }

    def client(self: ConversationRecovery) -> any {
        return workflow_tests.HTTPAccess.client(self);
    }

    def request(
        self: ConversationRecovery, client: any, path: any, payload: any = None
    ) -> any {
        return workflow_tests.HTTPAccess.request(self, client, path, payload);
    }

    def account(self: ConversationRecovery, suffix: str) -> any {
        return workflow_tests.HTTPAccess.account(self, suffix);
    }

    def prepare(self: ConversationRecovery, client: any) -> any {
        (_, registration) = self.request(
            client,
            "/api/workflow",
            {
                "action": "register_vehicle",
                "payload": {
                    "plate": "KAA 800A",
                    "make": "Toyota",
                    "model": "Corolla",
                    "year": 2020,
                    "odometer": 1000
                }
            }
        );
        vehicle_id = registration["result"]["id"];
        fields = {
            "vehicle_id": vehicle_id,
            "type": "inspection",
            "title": "Recovered inspection",
            "date": "2026-10-13",
            "odometer": 1100
        };
        with patch.object(
            agent_runtime,
            "urlopen",
            side_effect=[
                response(turn("propose_add_record", fields)),
                response(turn(text="Test fixture: review your inspection proposal."))
            ]
        ), patch.object(
            ai_service,
            "load_ai_config",
            return_value=("test-provider-key", "gemini/gemini-test")
        ) {
            (status, result) = self.request(
                client,
                "/api/agent/chat",
                {"message": "Prepare my inspection", "vehicle_id": vehicle_id}
            );
        }
        self.assertEqual(status, 200, result);
        return (vehicle_id, result);
    }

    def test_recovery_is_owned_projects_status_and_keeps_native_parts_private(
        self: ConversationRecovery
    ) -> any {
        owner = self.account("conversation-owner");
        stranger = self.account("conversation-stranger");
        (vehicle_id, prepared) = self.prepare(owner);
        proposal_id = prepared["proposals"][0]["id"];
        (_, recovered) = self.request(owner, "/api/agent/conversation");
        self.assertEqual(recovered["session_id"], prepared["session_id"]);
        self.assertEqual(recovered["messages"][0]["text"], "Prepare my inspection");
        self.assertEqual(recovered["messages"][1]["proposals"][0]["status"], "pending");
        self.assertNotIn("thoughtSignature", json.dumps(recovered));
        self.assertNotIn("test-provider-key", json.dumps(recovered));
        (_, foreign) = self.request(stranger, "/api/agent/conversation");
        self.assertEqual(foreign["messages"], []);
        (status, _) = self.request(
            stranger,
            "/api/agent/chat",
            {"session_id": prepared["session_id"], "message": "Read that conversation"}
        );
        self.assertEqual(status, 400);
        (status, _) = self.request(
            stranger, "/api/agent/approve", {"proposal_id": proposal_id}
        );
        self.assertEqual(status, 400);
        (status, _) = self.request(
            owner, "/api/agent/approve", {"proposal_id": proposal_id}
        );
        self.assertEqual(status, 200);
        (_, repeated) = self.request(
            owner, "/api/agent/approve", {"proposal_id": proposal_id}
        );
        self.assertTrue(repeated["already_applied"]);
        (_, recovered) = self.request(owner, "/api/agent/conversation");
        proposal = recovered["messages"][1]["proposals"][0];
        self.assertEqual(proposal["status"], "applied");
        self.assertEqual(proposal["vehicle_id"], vehicle_id);
        with server.database() as db {
            stored = json.loads(
                db.execute(
                    "SELECT contents FROM agent_sessions WHERE id=?",
                    (prepared["session_id"], )
                ).fetchone()[0]
            );
            self.assertEqual(
                stored[1]["parts"][0]["thoughtSignature"], "test-signature"
            );
        }
        (_, new) = self.request(owner, "/api/agent/conversation/new", {});
        (_, blank) = self.request(owner, "/api/agent/conversation");
        self.assertEqual(blank["session_id"], new["session_id"]);
        self.assertEqual(blank["messages"], []);
        with server.database() as db {
            self.assertIsNotNone(
                db.execute(
                    "SELECT id FROM agent_sessions WHERE id=?",
                    (prepared["session_id"], )
                ).fetchone()
            );
        }
    }

    def test_recovered_pending_proposals_show_stale_after_manual_write(
        self: ConversationRecovery
    ) -> any {
        owner = self.account("conversation-stale");
        (vehicle_id, prepared) = self.prepare(owner);
        self.request(
            owner,
            "/api/workflow",
            {
                "action": "add_record",
                "payload": {
                    "vehicle_id": vehicle_id,
                    "type": "inspection",
                    "title": "A concurrent update",
                    "date": "2026-10-13",
                    "odometer": 1100
                }
            }
        );
        (_, recovered) = self.request(owner, "/api/agent/conversation");
        self.assertEqual(recovered["messages"][1]["proposals"][0]["status"], "stale");
        with patch.object(agent_runtime, "urlopen", return_value=response(turn(text="Test fixture: the earlier proposal is stale."))) as transport, patch.object(ai_service, "load_ai_config", return_value=("test-provider-key", "gemini/gemini-test")) {
            (status, _) = self.request(owner, "/api/agent/chat", {"session_id": prepared["session_id"], "vehicle_id": vehicle_id, "message": "Check my earlier proposal status"});
        }
        self.assertEqual(status, 200);
        request_body = json.loads(transport.call_args.args[0].data);
        original_response = request_body["contents"][2]["parts"][0]["functionResponse"]["response"];
        self.assertEqual(original_response["proposal_status"], "stale");
        self.assertEqual(request_body["contents"][1]["parts"][0]["thoughtSignature"], "test-signature");
        (status, _) = self.request(
            owner, "/api/agent/approve", {"proposal_id": prepared["proposals"][0]["id"]}
        );
        self.assertEqual(status, 409);
        (_, state) = self.request(owner, "/api/state");
        self.assertEqual(len(state["vehicles"][0]["records"]), 1);
    }
}
