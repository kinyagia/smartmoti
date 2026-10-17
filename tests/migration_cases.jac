"""Regression checks for the Jac migration and source-share gate."""
import from pathlib { Path }
import from tempfile { TemporaryDirectory }
import from datetime { datetime, timezone, timedelta }
import unittest;
import ai_service;
import domain;
import showcase;
import source_audit;

class MigrationRegressions(unittest.TestCase) {
    def test_pdf_keeps_every_receipt_line(self: MigrationRegressions) -> None {
        pdf = showcase.sample_pdf(
            "Receipt (demo)", ["First service", "Second service"]
        );
        self.assertIn(b"(SMARTMOTI - DEMO DOCUMENT) Tj", pdf);
        self.assertIn(b"T* (Receipt \\(demo\\)) Tj", pdf);
        self.assertIn(b"T* (First service) Tj", pdf);
        self.assertIn(b"T* (Second service) Tj", pdf);
        self.assertTrue(pdf.rstrip().endswith(b"%%EOF"));
    }

    def test_telemetry_distinguishes_missing_demo_and_real_observations(
        self: MigrationRegressions
    ) -> None {
        self.assertEqual(domain.telemetry_state(None), "Not connected");
        self.assertEqual(
            domain.telemetry_state({"source": "demo"}), "Demo observation"
        );
        recent = datetime.now(timezone.utc).isoformat();
        stale = (datetime.now(timezone.utc) - timedelta(minutes=10)).isoformat();
        future = (datetime.now(timezone.utc) + timedelta(minutes=10)).isoformat();
        self.assertEqual(domain.telemetry_state({"observed_at": recent}), "Fresh");
        self.assertEqual(domain.telemetry_state({"observed_at": stale}), "Stale");
        with self.assertRaisesRegex(ValueError, "future") {
            domain.telemetry_state({"observed_at": future});
        }
        with self.assertRaisesRegex(ValueError, "timezone") {
            domain.telemetry_state({"observed_at": "2026-10-17T08:00:00"});
        }
    }

    def test_request_configuration_restores_after_failure(
        self: MigrationRegressions
    ) -> None {
        before = ai_service.REQUEST_CONFIG.get();
        with ai_service.use_config(("test-only-outer", "gemini/test-model")) {
            with self.assertRaises(ValueError) {
                with ai_service.use_config(("test-only-inner", "gemini/test-model")) {
                    raise ValueError("test rollback");
                }
            }
            self.assertEqual(ai_service.REQUEST_CONFIG.get()[0], "test-only-outer");
        }
        self.assertEqual(ai_service.REQUEST_CONFIG.get(), before);
    }

    def test_source_audit_counts_styles_tests_and_tools_but_excludes_runtime_data(
        self: MigrationRegressions
    ) -> None {
        with TemporaryDirectory() as directory {
            project = Path(directory);
            (project / "main.jac").write_text("with entry { print(1); }\n");
            (project / "styles.css").write_text("body { color: black; }\n");
            (project / "tests").mkdir();
            (project / "tests" / "example.py").write_text("assert True\n");
            (project / "tools").mkdir();
            (project / "tools" / "example.py").write_text("print(1)\n");
            (project / "data").mkdir();
            (project / "data" / "private.py").write_text("PRIVATE_RUNTIME_DATA\n");
            result = source_audit.audit(project);
            paths = [item["path"] for item in result["files"]];
            self.assertEqual(
                set(paths),
                {"main.jac", "styles.css", "tests/example.py", "tools/example.py"}
            );
            self.assertFalse(result["meetsLocalThreshold"]);
            self.assertEqual(result["totals"][".py"]["files"], 2);
            self.assertEqual(result["application"]["totals"][".py"]["files"], 1);
        }
    }
}
