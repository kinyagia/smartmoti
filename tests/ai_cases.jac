import from pathlib { Path }
import from typing { Any }
import tempfile;
import unittest;
import from unittest.mock { patch }
import ai_service;
import domain;
import from showcase { build_demo }
class AIBoundary(unittest.TestCase) {
    def setUp(self: AIBoundary) -> Any {
        self.workspace = build_demo();
        self.vehicle = self.workspace["vehicles"][0];
    }
    def test_ai_context_excludes_private_fields(self: AIBoundary) -> Any {
        record = self.vehicle["records"][0];
        record["notes"] = "PRIVATE NOTES";
        record["document"] = "PRIVATE DOCUMENT";
        self.vehicle["vin"] = "PRIVATE VIN";
        context = ai_service.review_context(self.workspace, self.vehicle["id"]);
        serialized = str(context);
        self.assertNotIn("PRIVATE", serialized);
        self.assertNotIn(self.vehicle["plate"], serialized);
        self.assertNotIn("telemetry", serialized);
        self.assertTrue(
            all(
                (("notes" not in r) and ("document" not in r))
                for r in context["records"]
            )
        );
    }
    def test_listing_ai_only_receives_selected_history(self: AIBoundary) -> Any {
        selected = self.vehicle["records"][0];
        context = ai_service.market_context(
            self.workspace, self.vehicle["id"], [selected["id"]]
        );
        self.assertEqual(
            [r["id"] for r in context["selected_history"]], [selected["id"]]
        );
        self.assertNotIn("records", context);
        with self.assertRaises(ValueError) {
            ai_service.market_context(
                self.workspace, self.vehicle["id"], ["another-vehicle-record"]
            );
        }
    }
    def test_unknown_citations_are_rejected(self: AIBoundary) -> Any {
        context = ai_service.review_context(self.workspace, self.vehicle["id"]);
        result = {
            "overview": "History summary",
            "highlights": [
                {"statement": "Observed service", "record_ids": ["invented-id"]}
            ],
            "gaps": []
        };
        with self.assertRaises(ai_service.AIUnavailable) {
            ai_service.validate_result("review", result, context);
        }
    }
    def test_supported_citations_and_empty_history_are_valid(self: AIBoundary) -> Any {
        context = ai_service.review_context(self.workspace, self.vehicle["id"]);
        result = {
            "overview": "A reported history",
            "highlights": [
                {
                    "statement": "Acquisition recorded",
                    "record_ids": [context["records"][0]["id"]]
                }
            ],
            "gaps": ["Records are unverified."]
        };
        self.assertEqual(ai_service.validate_result("review", result, context), result);
        empty = {
            "overview": "No records supplied",
            "highlights": [],
            "gaps": ["History is not available."]
        };
        self.assertEqual(
            ai_service.validate_result("review", empty, {"records": []}), empty
        );
    }
    def test_missing_key_does_not_generate_fake_ai_output(self: AIBoundary) -> Any {
        with patch.object(
            ai_service, "load_ai_config", return_value=("", "gemini/gemini-2.5-flash")
        ) {
            with self.assertRaisesRegex(ai_service.AIUnavailable, "not configured") {
                ai_service.generate(
                    self.workspace, "review", {"vehicle_id": self.vehicle["id"]}
                );
            }
        }
    }
    def test_local_config_accepts_bom_and_key_is_not_in_status(
        self: AIBoundary
    ) -> Any {
        with tempfile.TemporaryDirectory() as directory {
            env = Path(directory) / ".env";
            env.write_text(
                "GEMINI_API_KEY=test-placeholder\nSMARTMOTI_AI_MODEL=gemini/gemini-2.5-flash\n",
                encoding="utf-8-sig"
            );
            with patch.object(ai_service, "ENV_FILE", env) {
                status = ai_service.status();
            }
        }
        self.assertTrue(status["configured"]);
        self.assertNotIn("test-placeholder", str(status));
    }
}
with entry {
    if (__name__ == "__main__") {
        unittest.main();
    }
}
