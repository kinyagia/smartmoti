"""Authorized tools for the Jac agent. Writes are dry-run proposals only."""
import from typing { cast }
import from copy { deepcopy }
import hashlib;
import json;
import from typing { cast }
import ai_service;
import domain;
import support;
def declaration(
    name: any, description: any, properties: any, required: any = ()
) -> any {
    return {
        "name": name,
        "description": description,
        "parameters": {
            "type": "object",
            "properties": properties,
            "required": `list(required)
        }
    };
}

with entry {
    STRING = {"type": "string"};
    NUMBER = {"type": "number"};
    VEHICLE = {
        "type": "string",
        "description": "Exact vehicle ID returned by search_vehicles, or the selected vehicle ID."
    };
    RECORD_FIELDS = {
        "vehicle_id": VEHICLE,
        "type": {
            "type": "string",
            "enum": [
                "acquisition",
                "maintenance",
                "repair",
                "inspection",
                "incident",
                "odometer",
                "fuel",
                "ownership",
                "retirement"
            ]
        },
        "date": {
            "type": "string",
            "description": "Historical date YYYY-MM-DD. Ask if not provided; today only when the user says today."
        },
        "odometer": {
            "type": "number",
            "description": "Actual odometer reading explicitly supplied by the user. Never guess."
        },
        "title": STRING,
        "litres": NUMBER,
        "cost": NUMBER,
        "currency": {
            "type": "string",
            "enum": ["KES", "USD", "UGX", "TZS", "EUR", "GBP"]
        },
        "full_tank": {
            "type": "boolean",
            "description": "For fuel, ask whether full or partial if not supplied."
        }
    };
    TOOLS = [
        declaration(
            "assess_vehicle_issue",
            "Read-only troubleshooting of symptoms against the selected vehicle history. Returns validated possible causes, urgency, safe next checks and record citations; never a confirmed diagnosis or saved record. Use after clarifying the vehicle and symptoms. Symptoms must exclude personal information, registration, VIN and location.",
            {"vehicle_id": VEHICLE, "symptoms": STRING},
            ["vehicle_id", "symptoms"]
        ),
        declaration(
            "search_vehicles",
            "Search your authorized garage by make/model/year or a registration the user explicitly supplied. Empty query lists the garage. Returned data excludes registration and VIN.",
            {"query": STRING}
        ),
        declaration(
            "get_vehicle_history",
            "Retrieve the selected vehicle's current recorded events, excluding private notes, documents, VIN, registration and GPS. Use this before discussing or correcting history.",
            {"vehicle_id": VEHICLE},
            ["vehicle_id"]
        ),
        declaration(
            "get_fuel_summary",
            "Calculate actual recorded fuel totals and complete full-tank intervals with Jac. Costs remain separated by currency. No sensor readings are inferred.",
            {"vehicle_id": VEHICLE},
            ["vehicle_id"]
        ),
        declaration(
            "get_listings",
            "Get your own marketplace listing summaries and selected public history, without private vehicle information.",
            {}
        ),
        declaration(
            "propose_add_record",
            "Prepare a record or fuel entry for review; does NOT save. Need user-provided date and odometer. Fuel also needs litres, cost, currency and full/partial status. Ask for missing facts.",
            RECORD_FIELDS,
            ["vehicle_id", "type", "date", "odometer", "title"]
        ),
        declaration(
            "propose_correct_record",
            "Prepare a correction of an existing current record after reading its history. The original remains preserved. Does NOT save until approved.",
            ({} | RECORD_FIELDS | {"record_id": STRING}),
            ["vehicle_id", "record_id", "type", "date", "odometer", "title"]
        ),
        declaration(
            "propose_register_vehicle",
            "Prepare a vehicle registration for explicit review. Need all identity fields from the user. Never invent a registration, year or starting odometer; VIN uses the manual form.",
            {
                "plate": STRING,
                "make": STRING,
                "model": STRING,
                "year": {"type": "integer"},
                "odometer": NUMBER
            },
            ["plate", "make", "model", "year", "odometer"]
        )
    ];
    WRITE_TOOLS = {
        "propose_add_record",
        "propose_correct_record",
        "propose_register_vehicle"
    };
}

def workspace_hash(workspace: dict[str, any]) -> str {
    return hashlib.sha256(
        json.dumps(
            workspace, sort_keys=True, separators=(",", ":"), allow_nan=False
        ).encode()
    ).hexdigest();
}

def prepare_proposal(
    workspace: dict[(str, any)], tool: str, args: dict[(str, any)]
) -> dict[(str, any)] {
    if (tool not in WRITE_TOOLS) {
        raise ValueError("This tool cannot modify data");
    }
    schema = cast(
        dict[str, any],
        [
            item
            for item in TOOLS
            if item["name"] == tool
        ][0]["parameters"]
    );
    properties = cast(dict[str, any], schema["properties"]);
    if (not isinstance(args, `dict) or not `set(args).issubset(properties)) {
        raise ValueError("The proposed change contains unsupported fields");
    }
    if `any((field not in args) for field in schema["required"]) {
        raise ValueError("Ask for every required field before preparing this change");
    }
    payload: dict[str, any] = {};
    action: str = "";
    public_preview: dict[str, any] = {};
    summary: str = "";
    if (tool == "propose_register_vehicle") {
        (action, payload) = ("register_vehicle", `dict(args));
    } else {
        (action, payload) = ("add_record", ({} | args | {"source": "Owner reported"}));
        if (tool == "propose_correct_record") {
            payload["corrects"] = payload.pop("record_id");
            vehicle = domain.find_vehicle(workspace, str(payload["vehicle_id"]));
            original = record_by_id(
                cast(list[dict[str, any]], vehicle["records"]), payload["corrects"]
            );
            if (
                not original
                or original.get("superseded_by")
                or (original["type"] != payload["type"])
            ) {
                raise ValueError(
                    "Read and correct a current record using its original type"
                );
            }
            if (original.get("document") or original.get("notes")) {
                raise ValueError(
                    "Use the manual correction form for records with private notes or documents, so those details are preserved"
                );
            }
        }
        if (payload.get("type") == "fuel") {
            for field in ["litres", "cost", "currency", "full_tank"] {
                if (field not in payload) {
                    raise ValueError(
                        "Fuel entries require litres, cost, currency and full/partial status"
                    );
                }
            }
            if not isinstance(payload["full_tank"], bool) {
                raise ValueError("Full tank status must be true or false");
            }
        } elif (`set(payload) & {"litres", "cost", "currency", "full_tank"}) {
            raise ValueError("Fuel fields belong only to fuel records");
        }
    }
    preview = domain.dispatch(deepcopy(workspace), action, payload);
    if (action == "register_vehicle") {
        public_preview = {
            field: preview[field]
            for field in ["plate", "make", "model", "year", "initial_odometer"]
        };
        summary = f"Add {preview['make']} {preview['model']} to your garage";
    } else {
        vehicle = domain.find_vehicle(workspace, str(payload["vehicle_id"]));
        public_preview = {
            field: preview[field]
            for field in ["type", "title", "date", "odometer", "source"]
        };
        public_preview["vehicle"] = f"{vehicle['make']} {vehicle['model']} ({vehicle[
            'year'
        ]})";
        if payload.get("corrects") {
            original = record_by_id(
                cast(list[dict[str, any]], vehicle["records"]), payload["corrects"]
            );
            public_preview["replaces"] = f"{original['title']} - {original['date']} - {original[
                'odometer'
            ]} km";
        }
        for field in ["litres", "cost", "currency", "full_tank", "corrects"] {
            if (field in preview) {
                public_preview[field] = preview[field];
            }
        }
        summary = (
            ("Correct " if payload.get("corrects") else "Record ") + str(
                preview["title"]
            )
        );
    }
    return {
        "id": support.identifier(),
        "tool": tool,
        "action": action,
        "payload": payload,
        "preview": public_preview,
        "summary": summary,
        "state_hash": workspace_hash(workspace),
        "status": "pending",
        "created_at": support.now()
    };
}

def execute_tool(
    workspace: dict[(str, any)],
    name: str,
    args: dict[(str, any)],
    run: dict[(str, any)]
) -> dict[(str, any)] {
    result: dict[str, any] = {};
    label: str = "";
    if not isinstance(args, `dict) {
        raise ValueError("Tool arguments must be an object");
    }
    if (name == "search_vehicles") {
        query = support.text(args.get("query"), "Search", 100, False).lower();
        matches = [
            v
            for v in workspace["vehicles"]
            if (query in f"{v['make']} {v['model']} {v['year']} {v['plate']}".lower())
        ];
        result = {
            "vehicles": [
                {
                    "id": v["id"],
                    "make": v["make"],
                    "model": v["model"],
                    "year": v["year"],
                    "record_count": len(
                        [
                            r
                            for r in v["records"]
                            if not r.get("superseded_by")
                        ]
                    )
                } for v in matches[:30]
            ],
            "total_matches": len(matches)
        };
        label = f"Searched garage: {len(matches)} matching vehicles";
    } elif name == "assess_vehicle_issue" {
        result = ai_service.generate(workspace, "diagnosis", args);
        label = "Reviewed symptoms against selected vehicle history (possible causes only)";
    } elif (name == "get_vehicle_history") {
        result = ai_service.review_context(workspace, str(args.get("vehicle_id", "")));
        label = f"Read {result['vehicle']['make']} {result['vehicle'][
            'model'
        ]} history: {len(cast(list[any], result['records']))} records";
    } elif (name == "get_fuel_summary") {
        vehicle = domain.passport(workspace, str(args.get("vehicle_id", "")));
        result = {
            "vehicle": {"make": vehicle["make"], "model": vehicle["model"]},
            "fuel": domain.fuel_summary(cast(list[dict[str, any]], vehicle["records"]))
        };
        label = f"Calculated {vehicle['make']} {vehicle['model']} fuel summary";
    } elif (name == "get_listings") {
        result = {
            "listings": [
                {
                    key: listing[key]
                    for key in [
                        "id",
                        "make",
                        "model",
                        "year",
                        "price",
                        "currency",
                        "location",
                        "history",
                        "status"
                    ]
                } for listing in workspace.get("listings", [])[:30]
            ]
        };
        label = "Read your marketplace listings";
    } elif (name in WRITE_TOOLS) {
        if (len(cast(list[any], run["proposals"])) >= 3) {
            raise ValueError(
                "Review the existing proposals before preparing more changes"
            );
        }
        proposal = prepare_proposal(workspace, name, args);
        run["proposals"].append(proposal);
        preview = {
            k: v
            for (k, v) in proposal["preview"].items()
            if (k != "plate")
        };
        result = {
            "proposal_id": proposal["id"],
            "requires_confirmation": True,
            "summary": proposal["summary"],
            "preview": preview,
            "notice": "Not saved. The user must approve the exact proposal in the application."
        };
        label = "Prepared change for review: " + str(proposal["summary"]);
    } else {
        raise ValueError("Tool is not allowed");
    }
    run["trace"].append(
        {
            "tool": name,
            "label": label,
            "status": "prepared" if (name in WRITE_TOOLS) else "read"
        }
    );
    return result;
}


def record_by_id(records: list[dict[str, any]], record_id: any) -> dict[str, any] {
    for record in records {
        if record["id"] == record_id {
            return record;
        }
    }
    return {};
}
