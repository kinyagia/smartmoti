import unittest;
import from typing { Any }
import domain;
import from showcase { build_demo }
class ShowcaseFixtures(unittest.TestCase) {
    def test_showcase_uses_jac_records_and_keeps_private_documents_out_of_market(
        self: ShowcaseFixtures
    ) -> Any {
        workspace = build_demo();
        snapshot = domain.snapshot(workspace);
        self.assertEqual(len(snapshot["vehicles"]), 3);
        hilux = snapshot["vehicles"][0];
        self.assertEqual(hilux["fuel_summary"]["latest_economy"], 8.57);
        self.assertEqual(
            hilux["fuel_summary"]["cycles"][-1]["cost_per_km"]["KES"], 15.86
        );
        self.assertEqual(hilux["tracking_status"], "Demo observation");
        self.assertEqual(len(workspace["demo_documents"]), 2);
        self.assertTrue(
            all(
                doc["content"].startswith(b'%PDF-1.4')
                for doc in workspace["demo_documents"]
            )
        );
        self.assertEqual(len(workspace["listings"][0]["history"]), 3);
        self.assertTrue(
            all(
                (("document" not in record) and ("notes" not in record))
                for record in workspace["listings"][0]["history"]
            )
        );
    }
}
with entry {
    if (__name__ == "__main__") {
        unittest.main();
    }
}
