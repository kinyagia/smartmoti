"""Mock only Gemini transport; exercise actual Jac tools and persisted approvals."""
import from typing { Any }
import from copy { deepcopy }
import from io { BytesIO }
import json;
import unittest;
import from unittest.mock { patch }
import jaclang;
import agent_runtime;
import agent_tools;
import ai_service;
import domain;
import vehicle_agent;
import from showcase { build_demo }
def turn(name: Any = None, args: Any = None, text: Any = "Test model response") -> Any {
    part = {
        "functionCall": {"name": name, "args": (args or {}), "id": "test-call"},
        "thoughtSignature": "test-signature"
    }
        if name
        else {"text": text};
    return {"role": "model", "parts": [part]};
}
def response(content: Any) -> Any {
    return BytesIO(
        json.dumps(
            {"candidates": [{"finishReason": "STOP", "content": content}]}
        ).encode()
    );
}
class AgentWorkflows(unittest.TestCase) {
    def setUp(self: AgentWorkflows) -> Any {
        self.workspace = build_demo();
        self.workspace.pop("demo_documents");
        self.vehicle = self.workspace["vehicles"][0];
        self.args = {
            "vehicle_id": self.vehicle["id"],
            "type": "inspection",
            "title": "Test inspection",
            "date": "2026-10-13",
            "odometer": 44700
        };
    }
    def test_native_tool_exchange_preserves_signatures_and_reads_jac_fuel(
        self: AgentWorkflows
    ) -> Any {
        before = deepcopy(self.workspace);
        replies = [
            response(turn("get_fuel_summary", {"vehicle_id": self.vehicle["id"]})),
            response(turn(text="Test model fuel explanation"))
        ];
        with patch.object(agent_runtime, "urlopen", side_effect=replies) as transport, patch.object(
            ai_service,
            "load_ai_config",
            return_value=("test-key", "gemini/gemini-3.8-flash")
        ) {
            result = vehicle_agent.run_agent(
                self.workspace, "Explain my fuel", self.vehicle["id"], []
            );
        }
        self.assertEqual(self.workspace, before);
        self.assertEqual(result["trace"][0]["tool"], "get_fuel_summary");
        (first, second) = [
            json.loads(call.args[0].data) for call in transport.call_args_list
        ];
        self.assertEqual(len(first["tools"][0]["functionDeclarations"]), 8);
        self.assertEqual(
            second["contents"][1]["parts"][0]["thoughtSignature"], "test-signature"
        );
        fuel = second["contents"][2]["parts"][0]["functionResponse"]["response"][
            "fuel"
        ];
        self.assertEqual(fuel["latest_economy"], 8.57);
        self.assertNotIn(self.vehicle["plate"], str(second));
        self.assertNotIn("test-key", transport.call_args.args[0].full_url);
    }
    def test_proposals_are_dry_runs_and_incomplete_registration_is_rejected(
        self: AgentWorkflows
    ) -> Any {
        before = deepcopy(self.workspace);
        proposal = agent_tools.prepare_proposal(
            self.workspace, "propose_add_record", self.args
        );
        self.assertEqual(self.workspace, before);
        self.assertEqual(proposal["preview"]["source"], "Owner reported");
        with self.assertRaisesRegex(ValueError, "required") {
            agent_tools.prepare_proposal(
                self.workspace,
                "propose_register_vehicle",
                {"plate": "KAA 555A", "make": "Ford", "model": "Ranger", "year": 2020}
            );
        }
        with self.assertRaises(ValueError) {
            agent_tools.prepare_proposal(
                self.workspace,
                "propose_add_record",
                ({} | self.args | {"document": "private-id"})
            );
        }
        with self.assertRaises(ValueError) {
            agent_tools.prepare_proposal(
                self.workspace,
                "propose_add_record",
                ({} | self.args | {"type": "fuel"})
            );
        }
    }
    def test_correction_preserves_original_and_private_corrections_use_manual_form(
        self: AgentWorkflows
    ) -> Any {
        original = domain.dispatch(self.workspace, "add_record", self.args);
        proposal = agent_tools.prepare_proposal(
            self.workspace,
            "propose_correct_record",
            (
                {} | self.args | {"record_id": original["id"]} | {
                    "title": "Corrected inspection"
                }
            )
        );
        result = domain.dispatch(
            self.workspace, proposal["action"], proposal["payload"]
        );
        self.assertEqual(original["superseded_by"], result["id"]);
        current = next(
            r
            for r in self.vehicle["records"]
            if (r["id"] == result["id"])
        );
        current["notes"] = "private detail";
        with self.assertRaisesRegex(ValueError, "manual") {
            agent_tools.prepare_proposal(
                self.workspace,
                "propose_correct_record",
                ({} | self.args | {"record_id": result["id"]})
            );
        }
    }
    def test_unknown_tools_foreign_vehicle_and_missing_key_fail_without_writes(
        self: AgentWorkflows
    ) -> Any {
        before = deepcopy(self.workspace);
        run = agent_runtime.begin_run("Delete a vehicle", "", []);
        self.assertFalse(
            agent_runtime.handle_turn(self.workspace, run, turn("delete_vehicle", {}))
        );
        self.assertEqual(run["trace"][0]["status"], "error");
        self.assertEqual(run["proposals"], []);
        with self.assertRaises(ValueError) {
            vehicle_agent.run_agent(self.workspace, "Read this", "foreign-id", []);
        }
        with patch.object(
            ai_service, "load_ai_config", return_value=("", "gemini/gemini-3.8-flash")
        ) {
            with self.assertRaises(ai_service.AIUnavailable) {
                vehicle_agent.run_agent(
                    self.workspace, "Explain fuel", self.vehicle["id"], []
                );
            }
        }
        self.assertEqual(before, self.workspace);
    }
    def test_registration_fuel_proposals_and_listing_reads_use_real_rules(
        self: AgentWorkflows
    ) -> Any {
        proposal = agent_tools.prepare_proposal(
            self.workspace,
            "propose_register_vehicle",
            {
                "plate": "KAA 555A",
                "make": "Ford",
                "model": "Ranger",
                "year": 2020,
                "odometer": 1000
            }
        );
        self.assertEqual(len(self.workspace["vehicles"]), 3);
        added = domain.dispatch(
            self.workspace, proposal["action"], proposal["payload"]
        );
        self.assertEqual(added["initial_odometer"], 1000);
        fuel = agent_tools.prepare_proposal(
            self.workspace,
            "propose_add_record",
            (
                {} | self.args | {"type": "fuel"} | {"litres": 60} | {"cost": 11100} | {
                    "currency": "KES"
                } | {"full_tank": True}
            )
        );
        saved = domain.dispatch(self.workspace, fuel["action"], fuel["payload"]);
        self.assertTrue(saved["full_tank"]);
        run = agent_runtime.begin_run("Show listings", "", []);
        listings = agent_tools.execute_tool(self.workspace, "get_listings", {}, run);
        self.assertEqual(len(listings["listings"]), 1);
        self.assertNotIn("demo-service-receipt", str(listings));
        self.assertNotIn("notes", str(listings));
    }
    def test_tool_budget_is_bounded(self: AgentWorkflows) -> Any {
        with patch.object(
            agent_runtime,
            "urlopen",
            side_effect=[response(turn("search_vehicles", {})) for _ in range(5)]
        ), patch.object(
            ai_service,
            "load_ai_config",
            return_value=("test-key", "gemini/gemini-3.8-flash")
        ) {
            result = vehicle_agent.run_agent(self.workspace, "Read the garage", "", []);
        }
        self.assertTrue(result["limited"]);
        self.assertEqual(len(result["trace"]), 5);
    }
}
with entry {
    if (__name__ == "__main__") {
        unittest.main();
    }
}
