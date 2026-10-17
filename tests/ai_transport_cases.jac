"""Exercise the real Jac-to-Gemini request path with a mocked HTTP response."""
import from typing { Any }
import from io { BytesIO }
import json;
import unittest;
import from unittest.mock { patch }
import from urllib.error { HTTPError }
import ai_service;
import gemini_gateway;
import from showcase { build_demo }
class JacAITransport(unittest.TestCase) {
    def test_issue_assessment_is_typed_cited_private_and_read_only(self: JacAITransport) -> Any {
        import from copy { deepcopy }
        import agent_tools;
        import agent_runtime;
        workspace = build_demo();
        vehicle = workspace["vehicles"][0];
        vehicle["vin"] = "JT123456789012345";
        vehicle["records"][0]["notes"] = "PRIVATE-NOTE-SENTINEL";
        before = deepcopy(workspace);
        record_id = vehicle["records"][0]["id"];
        reply = {"summary": "Tentative assessment of reported vibration.", "urgency": "soon", "possible_causes": [{"cause": "A possible cause", "reasoning": "A hypothesis alongside reported history.", "record_ids": [record_id]}], "next_checks": ["Arrange a qualified inspection."], "questions": ["When does the vibration occur?"]};
        envelope = {"candidates": [{"finishReason": "STOP", "content": {"parts": [{"text": json.dumps(reply)}]}}]};
        with patch.object(gemini_gateway, "urlopen", return_value=BytesIO(json.dumps(envelope).encode())) as transport, patch.object(ai_service, "load_ai_config", return_value=("test-key", "gemini/gemini-3.8-flash")) {
            run = agent_runtime.begin_run("A vibration at idle", vehicle["id"], []);
            generated = agent_tools.execute_tool(workspace, "assess_vehicle_issue", {"vehicle_id": vehicle["id"], "symptoms": "There is a vibration at idle."}, run);
        }
        self.assertEqual(generated["result"]["possible_causes"][0]["record_ids"], [record_id]);
        self.assertEqual(workspace, before);
        self.assertEqual(run["proposals"], []);
        body = json.loads(transport.call_args.args[0].data);
        for excluded in [vehicle["plate"], vehicle["vin"], "PRIVATE-NOTE-SENTINEL", "demo-service-receipt"] { self.assertNotIn(excluded, str(body)); }
        self.assertIn("responseJsonSchema", body["generationConfig"]);
        self.assertIn("There is a vibration at idle.", str(body));
    }
    def test_issue_rejects_foreign_vehicles_private_inputs_and_bad_citations(self: JacAITransport) -> Any {
        workspace = build_demo();
        vehicle = workspace["vehicles"][0];
        with self.assertRaises(ValueError) { ai_service.issue_context(workspace, "foreign-id", "Vibration at idle"); }
        for symptoms in ["Vibration in " + vehicle["plate"], "Contact me at person@example.test", "Call +254712345678", "Location -1.23456, 36.12345", "VIN JT123456789012345"] {
            with self.assertRaisesRegex(ValueError, "symptoms only") { ai_service.issue_context(workspace, vehicle["id"], symptoms); }
        }
        context = ai_service.issue_context(workspace, vehicle["id"], "Vibration at idle after starting.");
        reply = {"summary": "Possible issue", "urgency": "soon", "possible_causes": [{"cause": "Possible cause", "reasoning": "Reported symptoms", "record_ids": ["invented-id"]}], "next_checks": ["Seek inspection"], "questions": []};
        with self.assertRaises(ai_service.AIUnavailable) { ai_service.validate_result("diagnosis", reply, context); }
        reply["possible_causes"][0]["record_ids"] = [];
        self.assertEqual(ai_service.validate_result("diagnosis", reply, context)["urgency"], "soon");
        reply["urgency"] = "safe_to_drive";
        with self.assertRaises(ai_service.AIUnavailable) { ai_service.validate_result("diagnosis", reply, context); }
        with ai_service.use_config(("", "gemini/gemini-3.8-flash")), patch.object(gemini_gateway, "urlopen") as transport {
            with self.assertRaises(ai_service.AIUnavailable) { ai_service.generate(workspace, "diagnosis", {"vehicle_id": vehicle["id"], "symptoms": "Vibration at idle after starting."}); }
            transport.assert_not_called();
        }
    }
    def test_typed_jac_review_and_structured_request(self: JacAITransport) -> Any {
        workspace = build_demo();
        vehicle_id = workspace["vehicles"][0]["id"];
        record_id = workspace["vehicles"][0]["records"][0]["id"];
        reply = {
            "overview": "A reported vehicle history is available.",
            "highlights": [
                {
                    "statement": "An acquisition entry starts the timeline.",
                    "record_ids": [record_id]
                }
            ],
            "gaps": ["The records are not independently verified."]
        };
        envelope = {
            "candidates": [
                {
                    "finishReason": "STOP",
                    "content": {"parts": [{"text": json.dumps(reply)}]}
                }
            ]
        };
        with patch.object(
            gemini_gateway,
            "urlopen",
            return_value=BytesIO(json.dumps(envelope).encode())
        ) as transport, patch.object(
            ai_service,
            "load_ai_config",
            return_value=("test-only-key", "gemini/gemini-3.8-flash")
        ) {
            generated = ai_service.generate(
                workspace, "review", {"vehicle_id": vehicle_id}
            );
        }
        self.assertEqual(generated["result"]["overview"], reply["overview"]);
        self.assertEqual(
            generated["result"]["highlights"][0]["record_ids"], [record_id]
        );
        request = transport.call_args.args[0];
        self.assertNotIn("test-only-key", request.full_url);
        body = json.loads(request.data);
        self.assertEqual(
            body["generationConfig"]["responseMimeType"], "application/json"
        );
        self.assertNotIn("demo-service-receipt", str(body));
    }
    def test_listing_draft_is_typed_and_only_uses_selected_record(
        self: JacAITransport
    ) -> Any {
        workspace = build_demo();
        vehicle = workspace["vehicles"][2];
        record_id = vehicle["records"][0]["id"];
        reply = {
            "description": "A 2022 Mazda CX-5 with a reported acquisition entry.",
            "record_ids": [record_id]
        };
        envelope = {
            "candidates": [
                {
                    "finishReason": "STOP",
                    "content": {"parts": [{"text": json.dumps(reply)}]}
                }
            ]
        };
        with patch.object(
            gemini_gateway,
            "urlopen",
            return_value=BytesIO(json.dumps(envelope).encode())
        ) as transport, patch.object(
            ai_service,
            "load_ai_config",
            return_value=("test-only-key", "gemini/gemini-3.8-flash")
        ) {
            generated = ai_service.generate(
                workspace,
                "draft",
                {"vehicle_id": vehicle["id"], "shared_record_ids": [record_id]}
            );
        }
        self.assertEqual(generated["result"]["description"], reply["description"]);
        body = json.loads(transport.call_args.args[0].data);
        self.assertNotIn(vehicle["records"][1]["id"], str(body));
    }
    def test_provider_auth_error_is_sanitized(self: JacAITransport) -> Any {
        with patch.object(
            gemini_gateway,
            "urlopen",
            side_effect=HTTPError(
                "https://example.invalid", 403, "PRIVATE PROVIDER DETAIL", {}, None
            )
        ), patch.object(
            ai_service,
            "load_ai_config",
            return_value=("test-only-key", "gemini/gemini-3.8-flash")
        ) {
            with self.assertRaises(ai_service.AIUnavailable) as error {
                gemini_gateway.request_generation("review", {"records": []});
            }
        }
        self.assertNotIn("PRIVATE", str(error.exception));
        self.assertNotIn("test-only-key", str(error.exception));
    }
}
with entry {
    if (__name__ == "__main__") {
        unittest.main();
    }
}
