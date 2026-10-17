"""TEST ONLY: scripted native Gemini exchanges, never a production fallback."""
import json;
import from io { BytesIO }
import from urllib.error { HTTPError }
import from typing { cast }

def model_reply(name: str, args: dict[str, any], text: str = "") -> BytesIO {
    part: dict[str, any] = {"text": text};
    if name {
        part = {
            "functionCall": {"name": name, "args": args, "id": "e2e-call"},
            "thoughtSignature": "e2e-test-signature"
        };
    }
    return BytesIO(
        json.dumps(
            {
                "candidates": [
                    {
                        "finishReason": "STOP",
                        "content": {"role": "model", "parts": [part]}
                    }
                ]
            }
        ).encode()
    );
}

def transport(request: any, timeout: int = 35) -> BytesIO {
    body = cast(dict[str, any], json.loads(request.data));
    current: dict[str, any] = {};
    responses: list[dict[str, any]] = [];
    for content in cast(list[dict[str, any]], body["contents"]) {
        for part in cast(list[dict[str, any]], content["parts"]) {
            if content["role"] == "user" and part.get("text") {
                current = cast(dict[str, any], json.loads(str(part["text"])));
                responses = [];
            }
            if part.get("functionResponse") {
                responses.append(cast(dict[str, any], part["functionResponse"]));
            }
        }
    }
    prompt = str(current["request"]);
    selected = str(current.get("selected_vehicle_id") or "");
    phase = len(responses);
    if prompt == "Exercise the test provider failure" {
        raise HTTPError(request.full_url, 429, "Test-only quota failure", {}, None);
    }
    if prompt.startswith("Register a Toyota Corolla") {
        if phase == 0 {
            return model_reply(
                "propose_register_vehicle",
                {
                    "plate": "KAA 700A",
                    "make": "Toyota",
                    "model": "Corolla",
                    "year": 2020,
                    "odometer": 1000
                }
            );
        }
    } elif prompt.startswith("Record an inspection") {
        if phase == 0 {
            return model_reply("search_vehicles", {"query": "Toyota Corolla"});
        }
        vehicles = cast(list[dict[str, any]], responses[0]["response"]["vehicles"]);
        selected = str(vehicles[0]["id"]);
        if phase == 1 {
            return model_reply("get_vehicle_history", {"vehicle_id": selected});
        }
        if phase == 2 {
            return model_reply(
                "propose_add_record",
                {
                    "vehicle_id": selected,
                    "type": "inspection",
                    "date": current["local_date"],
                    "odometer": 1100,
                    "title": "E2E inspection"
                }
            );
        }
    } elif prompt.startswith("Log a full tank") {
        if phase == 0 {
            return model_reply("get_fuel_summary", {"vehicle_id": selected});
        }
        if phase == 1 {
            second = "1400 km" in prompt;
            return model_reply(
                "propose_add_record",
                {
                    "vehicle_id": selected,
                    "type": "fuel",
                    "date": current["local_date"],
                    "odometer": 1400 if second else 1200,
                    "litres": 20 if second else 40,
                    "cost": 3700 if second else 7400,
                    "currency": "KES",
                    "full_tank": True,
                    "title": "E2E second full tank" if second else "E2E first full tank"
                }
            );
        }
    } elif prompt.startswith("Correct the inspection") {
        if phase == 0 {
            return model_reply("get_vehicle_history", {"vehicle_id": selected});
        }
        if phase == 1 {
            records = cast(list[dict[str, any]], responses[0]["response"]["records"]);
            matching = [
                record
                for record in records
                if record["title"] == "E2E inspection"
            ];
            return model_reply(
                "propose_correct_record",
                {
                    "vehicle_id": selected,
                    "record_id": matching[0]["id"],
                    "type": "inspection",
                    "title": "E2E inspection corrected",
                    "date": current["local_date"],
                    "odometer": 1100
                }
            );
        }
    } elif prompt.startswith("Explain the recorded fuel") {
        if phase == 0 {
            return model_reply("get_vehicle_history", {"vehicle_id": selected});
        }
        if phase == 1 {
            return model_reply("get_fuel_summary", {"vehicle_id": selected});
        }
        summary = responses[1]["response"]["fuel"];
        return model_reply(
            "",
            {},
            "Test provider fixture: Jac reports " + str(summary["latest_economy"]) + " L/100 km and " + str(
                summary["cycles"][-1]["cost_per_km"]["KES"]
            ) + " KES/km."
        );
    } else {
        raise ValueError("Unexpected prompt in the test-only provider fixture");
    }
    return model_reply(
        "",
        {},
        "Test provider fixture: review the exact proposed fields and approve to save."
    );
}
