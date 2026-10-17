"""Isolated, clearly labelled presentation fixtures using actual Jac workflows."""
import domain;
import support;
import from typing { cast }
with entry {
    SHOWCASE_VERSION = 2;
}
"""Create a small valid PDF containing only illustrative receipt information."""
def sample_pdf(title: str, lines: list[str]) -> bytes {
    text: list[str] = [
        "SMARTMOTI - DEMO DOCUMENT",
        title,
        "",
        *lines,
        "",
        "Illustrative sample only. Not a real invoice or verified service record."
    ];
    operations: list[str] = ["BT /F1 11 Tf 50 770 Td 18 TL"];
    for (index, line) in enumerate(text) {
        escaped = line.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)");
        operations.append(("T* " if index else "") + f"({escaped}) Tj");
    }
    operations.append("ET");
    stream = "\n".join(operations).encode("ascii");
    objects = [
        b'<< /Type /Catalog /Pages 2 0 R >>',
        b'<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
        b'<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
        b'<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
        (f"<< /Length {len(stream)} >>\nstream\n".encode() + stream + b'\nendstream')
    ];
    pdf = bytearray(b'%PDF-1.4\n');
    offsets = [0];
    for (index, `obj) in enumerate(objects, 1) {
        offsets.append(len(pdf));
        pdf.extend((f"{index} 0 obj\n".encode() + `obj + b'\nendobj\n'));
    }
    xref = len(pdf);
    pdf.extend(f"xref\n0 {(len(objects) + 1)}\n0000000000 65535 f \n".encode());
    for offset in offsets[1:] {
        pdf.extend(f"{offset:010d} 00000 n \n".encode());
    }
    pdf.extend(
        f"trailer\n<< /Size {(len(objects) + 1)} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF".encode()
    );
    return `bytes(pdf);
}
def build_demo() -> any {
    state = {
        "vehicles": [],
        "listings": [],
        "showcase_version": SHOWCASE_VERSION,
        "demo_documents": []
    };
    for (plate, make, model, year) in [
        ("KDK 482A", "Toyota", "Hilux", 2021),
        ("KCY 716B", "Isuzu", "D-Max", 2020),
        ("KDG 903C", "Mazda", "CX-5", 2022)
    ] {
        domain.dispatch(
            state,
            "register_vehicle",
            {
                "plate": plate,
                "make": make,
                "model": model,
                "year": year,
                "odometer": 0,
                "vin": ""
            }
        );
    }
    def add(
        vehicle: any,
        kind: any,
        day: any,
        km: any,
        title: any,
        notes: any,
        source: any = "Owner reported",
        **extra: any
    ) -> any {
        return domain.dispatch(
            state,
            "add_record",
            cast(dict[str, any], (
                {} | {"vehicle_id": vehicle["id"]} | {"type": kind} | {"date": day} | {
                    "odometer": km
                } | {"title": title} | {"notes": notes} | {"source": source} | extra
            ))
        );
    }
    def attach(record: any, filename: str, title: str, lines: list[str]) -> any {
        doc_id = support.identifier();
        record["document"] = doc_id;
        state["demo_documents"].append(
            {
                "id": doc_id,
                "name": filename,
                "mime": "application/pdf",
                "content": sample_pdf(title, lines)
            }
        );
    }
    (hilux, isuzu, mazda) = state["vehicles"];
    add(
        hilux,
        "acquisition",
        "2021-08-05",
        18,
        "First owner takes the keys",
        "Illustrative first acquisition entry. The vehicle passport begins here."
    );
    add(
        hilux,
        "maintenance",
        "2022-04-12",
        9800,
        "First scheduled service",
        "Engine oil, filters and routine safety checks. Sample workshop report.",
        "Workshop reported"
    );
    add(
        hilux,
        "inspection",
        "2023-05-21",
        21000,
        "Annual condition inspection",
        "Brakes, suspension and tyres inspected. This is a reported demo entry, not a verified inspection.",
        "Workshop reported"
    );
    add(
        hilux,
        "ownership",
        "2024-11-10",
        39000,
        "Second ownership chapter",
        "Sample historical handover record. The vehicle timeline continues across ownership periods."
    );
    add(
        hilux,
        "maintenance",
        "2025-10-19",
        42500,
        "Major service and brake pads",
        "Service history remains attached to the vehicle, including after ownership changes.",
        "Workshop reported"
    );
    for (day, km, litres, full) in [
        ("2026-09-01", 43000, 55, True),
        ("2026-09-08", 43300, 20, False),
        ("2026-09-15", 43700, 40, True),
        ("2026-10-02", 44400, 60, True)
    ] {
        record = add(
            hilux,
            "fuel",
            day,
            km,
            ("Refuelling - " + "full tank" if full else "partial fill"),
            "Illustrative fuel ledger entry at KES 185 per litre.",
            litres=litres,
            cost=(litres * 185),
            currency="KES",
            full_tank=full
        );
        if (day == "2026-10-02") {
            attach(
                record,
                "demo-fuel-receipt.pdf",
                "Sample fuel receipt",
                [
                    "Date: 02 October 2026",
                    "Vehicle: KDK 482A",
                    "Odometer: 44,400 km",
                    "Fuel: 60 litres",
                    "Total: KES 11,100"
                ]
            );
        }
    }
    service = add(
        hilux,
        "maintenance",
        "2026-09-20",
        44000,
        "Oil and filter service",
        "Engine oil and air filter replaced. Open the supporting sample service receipt.",
        "Workshop reported"
    );
    attach(
        service,
        "demo-service-receipt.pdf",
        "Sample service record",
        [
            "Date: 20 September 2026",
            "Vehicle: KDK 482A",
            "Odometer: 44,000 km",
            "Work: Engine oil and filter replacement",
            "Source: Illustrative workshop report"
        ]
    );
    add(
        hilux,
        "odometer",
        "2026-10-12",
        44700,
        "Odometer after a sample journey",
        "Illustrative reading. The route displayed in Tracking is a demo fixture, not a live GPS observation."
    );
    hilux["telemetry"] = {
        "source": "demo",
        "observed_at": "2026-10-12T13:30:00+00:00",
        "latitude": -0.7176,
        "longitude": 36.431,
        "speed": 0,
        "journey": {
            "from": "Nairobi",
            "to": "Naivasha",
            "date": "2026-10-12",
            "distance_km": 94.2,
            "duration_minutes": 115,
            "status": "Parked",
            "device": "DEMO-TRACKER-01"
        }
    };
    add(
        isuzu,
        "acquisition",
        "2020-02-18",
        12,
        "Commercial vehicle acquired",
        "Illustrative delivery record."
    );
    add(
        isuzu,
        "maintenance",
        "2022-06-14",
        31000,
        "Scheduled fleet service",
        "Routine service and tyre rotation.",
        "Workshop reported"
    );
    add(
        isuzu,
        "repair",
        "2024-03-09",
        59000,
        "Clutch assembly replacement",
        "Parts and labour recorded as a workshop report.",
        "Workshop reported"
    );
    add(
        isuzu,
        "incident",
        "2025-05-06",
        67000,
        "Minor bumper damage reported",
        "Cosmetic damage recorded to preserve a more transparent vehicle history."
    );
    add(
        isuzu,
        "repair",
        "2025-05-12",
        67150,
        "Bumper repaired",
        "Follow-up repair linked by its date and notes to the reported incident.",
        "Workshop reported"
    );
    add(
        isuzu,
        "inspection",
        "2026-05-11",
        68900,
        "Roadworthiness inspection reported",
        "Illustrative inspection. No verified certification is implied.",
        "Workshop reported"
    );
    add(
        mazda,
        "acquisition",
        "2022-04-04",
        16,
        "Vehicle acquisition recorded",
        "Sample purchase record for the current demo owner."
    );
    add(
        mazda,
        "maintenance",
        "2024-03-18",
        9800,
        "Routine maintenance completed",
        "Oil, filters and brake inspection. Illustrative workshop entry.",
        "Workshop reported"
    );
    add(
        mazda,
        "inspection",
        "2026-08-01",
        18200,
        "Pre-listing condition report",
        "Seller-reported condition record for selective sharing.",
        "Workshop reported"
    );
    domain.dispatch(
        state,
        "publish_listing",
        {
            "vehicle_id": mazda["id"],
            "price": 3250000,
            "location": "Nairobi",
            "description": "Illustrative showcase listing. A 2022 Mazda CX-5 with acquisition, maintenance and inspection entries selected for buyers. Private documents and notes stay in the seller's workspace.",
            "shared_record_ids": [record["id"] for record in mazda["records"]]
        }
    );
    return state;
}
def seed_demo(db: any, user_id: any) -> any {
    state = build_demo();
    for document in state.pop("demo_documents") {
        db.execute(
            "INSERT INTO files VALUES (?,?,?,?,?)",
            (
                document["id"],
                user_id,
                document["name"],
                document["mime"],
                document["content"]
            )
        );
    }
    listing = state["listings"][0];
    db.execute(
        "INSERT INTO offers VALUES (?,?,?,?,?,?,?,?)",
        (
            support.identifier(),
            listing["id"],
            user_id,
            "illustrative-demo-buyer",
            3100000,
            "Illustrative buyer enquiry: I have reviewed the shared history. Could we arrange a viewing of the Mazda CX-5?",
            "pending",
            support.now()
        )
    );
    return state;
}
