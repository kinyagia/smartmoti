"""Smartmoti's vehicle graph and deterministic application workflows."""
import from support { identifier, now, text, number, rounded, local_today }
import from typing { cast }
import from datetime { date, datetime, timezone }

def year_number(value: any) -> int {
    result = number(value, "Year", 1886, local_today().year);
    if not result.is_integer() {
        raise ValueError("Year must be a whole number");
    }
    return int(result);
}

def calendar_date(value: any) -> str {
    try {
        result = date.fromisoformat(str(value));
    } except (TypeError, ValueError) {
        raise ValueError("Use a valid date") from None;
    }
    if result > local_today() {
        raise ValueError("Historical records cannot be dated in the future");
    }
    return result.isoformat();
}

def odometer_valid(records: list[dict[str, any]], day: str, odometer: float) -> None {
    for record in records {
        if record.get("superseded_by") {
            continue;
        }
        if record["date"] < day and record["odometer"] > odometer {
            raise ValueError("Odometer is below an earlier recorded reading");
        }
        if record["date"] > day and record["odometer"] < odometer {
            raise ValueError("Odometer exceeds a later recorded reading");
        }
    }
}

def telemetry_state(observation: any) -> str {
    if not observation {
        return "Not connected";
    }
    reading = cast(dict[str, any], observation);
    if reading.get("source") == "demo" {
        return "Demo observation";
    }
    timestamp = datetime.fromisoformat(
        str(reading["observed_at"]).replace("Z", "+00:00")
    );
    if timestamp.tzinfo is None {
        raise ValueError("Telemetry needs a timezone");
    }
    age = (datetime.now(timezone.utc) - timestamp).total_seconds();
    if age < -60 {
        raise ValueError("Telemetry is dated in the future");
    }
    return "Fresh" if age <= 300 else "Stale";
}

node Garage {}
node Vehicle {
    has data: dict[str, any];
}
node LifetimeEvent {
    has data: dict[str, any];
}

walker Passport {
    has vehicle_id: str;
    has result: dict[str, any] = {};

    can enter with Garage entry {
        visit [-->][?:Vehicle];
    }

    can collect with Vehicle entry {
        if here.data["id"] == self.vehicle_id {
            self.result = dict(here.data);
            self.result["records"] = [event.data for event in [-->][?:LifetimeEvent]];
            disengage;
        }
    }
}

def passport(state: dict[str, any], vehicle_id: str) -> dict[str, any] {
    garage = Garage();
    for item in cast(list[dict[str, any]], state["vehicles"]) {
        vehicle = Vehicle(data=item);
        garage ++> vehicle;
        for record in cast(list[dict[str, any]], item["records"]) {
            vehicle ++> LifetimeEvent(data=record);
        }
    }
    query = garage spawn Passport(vehicle_id=vehicle_id);
    if not query.result {
        raise ValueError("Vehicle not found in your workspace");
    }
    return query.result;
}

def find_vehicle(state: dict[str, any], vehicle_id: str) -> dict[str, any] {
    for vehicle in cast(list[dict[str, any]], state["vehicles"]) {
        if vehicle["id"] == vehicle_id {
            return vehicle;
        }
    }
    raise ValueError("Vehicle not found in your workspace");
}

def fuel_summary(records: list[dict[str, any]]) -> dict[str, any] {
    entries = sorted(
        [
            r
            for r in records
            if r["type"] == "fuel" and not r.get("superseded_by")
        ],
        key=lambda (r: dict[str, any]) -> tuple {
            return (r["date"], r["odometer"], r["created_at"]);
        }
    );
    totals: dict[str, float] = {};
    cycles: list[dict[str, any]] = [];
    checkpoint: dict[str, any] = {};
    litres: float = 0.0;
    costs: dict[str, float] = {};
    for entry in entries {
        currency = str(entry["currency"]);
        totals[currency] = rounded(
            totals.get(currency, 0.0) + cast(float, entry["cost"]), 2
        );
        if checkpoint {
            litres += cast(float, entry["litres"]);
            costs[currency] = costs.get(currency, 0.0) + cast(float, entry["cost"]);
        }
        if entry["full_tank"] {
            if checkpoint {
                distance = cast(float, entry["odometer"]) - cast(
                    float, checkpoint["odometer"]
                );
                if distance > 0 {
                    cycles.append(
                        {
                            "from": checkpoint["date"],
                            "to": entry["date"],
                            "distance": distance,
                            "litres": rounded(litres, 3),
                            "l_per_100km": rounded(litres / distance * 100, 2),
                            "cost_per_km": {
                                code: rounded(amount / distance, 2)
                                for (code, amount) in costs.items()
                            }
                        }
                    );
                }
            }
            checkpoint = entry;
            litres = 0.0;
            costs = {};
        }
    }
    return {
        "entries": len(entries),
        "total_litres": rounded(sum([cast(float, e["litres"]) for e in entries]), 2),
        "costs": totals,
        "cycles": cycles,
        "latest_economy": cycles[-1]["l_per_100km"] if cycles else None
    };
}

def snapshot(state: dict[str, any]) -> dict[str, any] {
    vehicles: list[dict[str, any]] = [];
    for item in cast(list[dict[str, any]], state["vehicles"]) {
        vehicle = passport(state, str(item["id"]));
        records = cast(list[dict[str, any]], vehicle["records"]);
        vehicle["fuel_summary"] = fuel_summary(records);
        vehicle["tracking_status"] = telemetry_state(vehicle.get("telemetry"));
        active = [
            r
            for r in records
            if not r.get("superseded_by")
        ];
        vehicle["odometer"] = max(
            [cast(float, r["odometer"]) for r in active] + [
                cast(float, vehicle["initial_odometer"])
            ]
        );
        vehicle["records"] = sorted(
            records,
            key=lambda (r: dict[str, any]) -> tuple {
                return (str(r["date"]), str(r["created_at"]));
            },
            reverse=True
        );
        vehicles.append(vehicle);
    }
    return {"vehicles": vehicles, "listings": state.get("listings", [])};
}

def register_vehicle(state: dict[str, any], payload: dict[str, any]) -> dict[str, any] {
    plate = text(payload.get("plate"), "Registration", 30).upper();
    vin = text(payload.get("vin"), "VIN", 40, False).upper();
    for vehicle in cast(list[dict[str, any]], state["vehicles"]) {
        if vehicle["plate"] == plate or (vin and vehicle["vin"] == vin) {
            raise ValueError("A vehicle with this registration or VIN already exists");
        }
    }
    vehicle = {
        "id": identifier(),
        "plate": plate,
        "vin": vin,
        "make": text(payload.get("make"), "Make", 60),
        "model": text(payload.get("model"), "Model", 60),
        "year": year_number(payload.get("year")),
        "initial_odometer": number(payload.get("odometer", 0), "Odometer"),
        "created_at": now(),
        "records": [],
        "telemetry": None,
        "mint": None
    };
    state["vehicles"].append(vehicle);
    return vehicle;
}

def add_record(state: dict[str, any], payload: dict[str, any]) -> dict[str, any] {
    vehicle = find_vehicle(state, str(payload.get("vehicle_id", "")));
    kind = str(payload.get("type", ""));
    if kind not in [
        "acquisition",
        "maintenance",
        "repair",
        "inspection",
        "incident",
        "odometer",
        "fuel",
        "ownership",
        "retirement"
    ] {
        raise ValueError("Unsupported record type");
    }
    day = calendar_date(payload.get("date"));
    reading = number(payload.get("odometer"), "Odometer");
    replacement = payload.get("corrects", "");
    original: dict[str, any] = {};
    for record in cast(list[dict[str, any]], vehicle["records"]) {
        if record["id"] == replacement {
            original = record;
        }
    }
    if replacement and (not original or original.get("superseded_by")) {
        raise ValueError("Only a current record can be corrected");
    }
    validation_records = [
        r
        for r in cast(list[dict[str, any]], vehicle["records"])
        if r["id"] != replacement
    ];
    odometer_valid(validation_records, day, reading);
    if reading < vehicle["initial_odometer"] {
        raise ValueError("Reading is below the vehicle's starting odometer");
    }
    source = str(payload.get("source", "Owner reported"));
    if source not in ["Owner reported", "Workshop reported", "Document reference"] {
        raise ValueError("Invalid record source");
    }
    entry = {
        "id": identifier(),
        "type": kind,
        "date": day,
        "odometer": reading,
        "title": text(payload.get("title"), "Title", 140),
        "notes": text(payload.get("notes"), "Notes", 3000, False),
        "document": text(payload.get("document"), "Document reference", 400, False),
        "source": source,
        "verification": "Unverified",
        "created_at": now(),
        "corrects": replacement
    };
    if kind == "fuel" {
        entry["litres"] = number(payload.get("litres"), "Litres", 0.01, 3000);
        entry["cost"] = number(payload.get("cost"), "Fuel cost", 0.01);
        entry["currency"] = text(payload.get("currency", "KES"), "Currency", 3).upper();
        if entry["currency"] not in ["KES", "USD", "UGX", "TZS", "EUR", "GBP"] {
            raise ValueError("Unsupported currency");
        }
        entry["full_tank"] = payload.get("full_tank") is True;
    }
    if original {
        original["superseded_by"] = entry["id"];
    }
    vehicle["records"].append(entry);
    return entry;
}

def publish_listing(state: dict[str, any], payload: dict[str, any]) -> dict[str, any] {
    vehicle = find_vehicle(state, str(payload.get("vehicle_id", "")));
    for listing in state.get("listings", []) {
        if listing["vehicle_id"] == vehicle["id"]
        and listing["status"] in ["active", "reserved"] {
            raise ValueError("This vehicle already has an active listing");
        }
    }
    shared = cast(list[str], payload.get("shared_record_ids", []));
    records = [
        r
        for r in cast(list[dict[str, any]], vehicle["records"])
        if r["id"] in shared and not r.get("superseded_by")
    ];
    summary = [
        {
            "type": r["type"],
            "date": r["date"],
            "title": r["title"],
            "odometer": r["odometer"],
            "source": r["source"],
            "verification": r["verification"]
        } for r in records
    ];
    listing = {
        "id": identifier(),
        "vehicle_id": vehicle["id"],
        "make": vehicle["make"],
        "model": vehicle["model"],
        "year": vehicle["year"],
        "odometer": max(
            [
                r["odometer"]
                for r in vehicle["records"]
                if not r.get("superseded_by")
            ] + [vehicle["initial_odometer"]]
        ),
        "price": number(payload.get("price"), "Price", 1, 1000000000),
        "currency": "KES",
        "location": text(payload.get("location"), "Town", 80),
        "description": text(payload.get("description"), "Description", 2000),
        "history": summary,
        "status": "active",
        "created_at": now()
    };
    if "listings" not in state {
        state["listings"] = [];
    }
    state["listings"].append(listing);
    return listing;
}

def find_listing(listings: list[dict[str, any]], listing_id: any) -> dict[str, any] {
    for listing in listings {
        if listing["id"] == listing_id {
            return listing;
        }
    }
    return {};
}

def set_listing_status(
    state: dict[str, any], payload: dict[str, any]
) -> dict[str, any] {
    listing = find_listing(
        cast(list[dict[str, any]], state["listings"]), payload.get("listing_id")
    );
    if not listing {
        raise ValueError("Listing not found");
    }
    status = payload.get("status");
    if status not in ["reserved", "withdrawn", "sold"]
    or listing["status"] in ["withdrawn", "sold"] {
        raise ValueError("Invalid listing transition");
    }
    if status == "sold" and payload.get("handover_confirmed") is not True {
        raise ValueError("Confirm the handover before recording a sale");
    }
    if status == "sold" {
        vehicle = find_vehicle(state, str(listing["vehicle_id"]));
        add_record(
            state,
            {
                "vehicle_id": vehicle["id"],
                "type": "ownership",
                "date": payload.get("date"),
                "odometer": payload.get("odometer"),
                "title": "Sale handover recorded",
                "notes": "Seller recorded handover. Buyer account transfer is not implemented in this release."
            }
        );
    }
    listing["status"] = status;
    return listing;
}

def mint_metadata(state: dict[str, any], vehicle_id: str) -> dict[str, any] {
    vehicle = find_vehicle(state, vehicle_id);
    return {
        "name": "Smartmoti " + str(vehicle["make"]) + " " + str(vehicle["model"]),
        "description": "Vehicle identity snapshot. This NFT is not proof of legal ownership or verified vehicle history.",
        "attributes": [
            {"trait_type": "Make", "value": vehicle["make"]},
            {"trait_type": "Model", "value": vehicle["model"]},
            {"trait_type": "Year", "value": vehicle["year"]}
        ],
        "snapshot_created_at": now()
    };
}

def dispatch(
    state: dict[str, any], action: str, payload: dict[str, any]
) -> dict[str, any] {
    if action == "register_vehicle" {
        return register_vehicle(state, payload);
    }
    if action == "add_record" {
        return add_record(state, payload);
    }
    if action == "publish_listing" {
        return publish_listing(state, payload);
    }
    if action == "mint_metadata" {
        return mint_metadata(state, str(payload.get("vehicle_id", "")));
    }
    if action == "snapshot" {
        return snapshot(state);
    }
    raise ValueError("Unknown workflow");
}
