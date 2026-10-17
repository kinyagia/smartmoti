"""Provider configuration and validated access boundary around Jac AI functions."""
import from dataclasses { asdict }
import from contextlib { contextmanager, AbstractContextManager }
import from contextvars { ContextVar }
import from collections.abc { Iterator, Callable }
import importlib;
import os;
import from pathlib { Path }
import from typing { cast }
import time;
import re;
import domain;
import support;
with entry {
    ENV_FILE = Path(str(__file__)).resolve().parent / ".env";
    REQUEST_CONFIG = ContextVar("smartmoti_ai_config", `default=None);
}
@contextmanager
def config_scope(config: tuple[str, str]) -> Iterator[None] {
    token = REQUEST_CONFIG.set(config);
    try {
        yield ;
    } finally {
        REQUEST_CONFIG.reset(token);
    }
}

def use_config(config: tuple[str, str]) -> AbstractContextManager[None] {
    factory = cast(Callable[[tuple[str, str]], AbstractContextManager[None]], config_scope);
    return cast(AbstractContextManager[None], factory(config));
}
class AIUnavailable(RuntimeError) {}
"""Read only Smartmoti's local configuration; do not borrow project credentials."""
def load_ai_config() -> tuple[str, str] {
    if (REQUEST_CONFIG.get() is not None) {
        return cast(tuple[str, str], REQUEST_CONFIG.get());
    }
    config = {};
    if ENV_FILE.exists() {
        for raw in ENV_FILE.read_text(encoding="utf-8-sig").splitlines() {
            raw = raw.strip();
            if (not raw or raw.startswith("#") or ("=" not in raw)) {
                continue;
            }
            (name, value) = raw.split("=", 1);
            if (name.strip() in {"GEMINI_API_KEY", "SMARTMOTI_AI_MODEL"}) {
                config[name.strip()] = value.strip().strip('"').strip("'");
            }
        }
    }
    key = config.get("GEMINI_API_KEY", os.environ.get("GEMINI_API_KEY", ""));
    model = (
        config.get("SMARTMOTI_AI_MODEL")
        or os.environ.get("SMARTMOTI_AI_MODEL", "gemini/gemini-3.8-flash")
    );
    return (key, model);
}
def status() -> any {
    (key, model) = load_ai_config();
    return {
        "configured": bool(key),
        "available": bool(key),
        "provider": "Gemini",
        "model": model,
        "setup": "Add your new GEMINI_API_KEY in the local .env file."
    };
}
def record_date(record: dict[str, any]) -> str {
    return str(record["date"]);
}

def review_context(workspace: dict[str, any], vehicle_id: str) -> dict[str, any] {
    vehicle = domain.passport(workspace, vehicle_id);
    records = [
        record
        for record in vehicle["records"]
        if not record.get("superseded_by")
    ];
    if (len(records) > 100) {
        raise ValueError(
            "Select a vehicle with at most 100 current records for this AI review"
        );
    }
    public_fields = [
        {
            "id": r["id"],
            "type": r["type"],
            "date": r["date"],
            "title": r["title"],
            "odometer": r["odometer"],
            "source": r["source"],
            "verification": r["verification"]
        } for r in records
    ];
    return {
        "vehicle": {
            "make": vehicle["make"],
            "model": vehicle["model"],
            "year": vehicle["year"]
        },
        "records": sorted(public_fields, key=record_date),
        "scope": "Recorded events only; reported entries are not independently verified."
    };
}
def market_context(workspace: dict[str, any], vehicle_id: str, selected_ids: any) -> dict[str, any] {
    if (
        not isinstance(selected_ids, `list)
        or not all(isinstance(value, str) for value in selected_ids)
    ) {
        raise ValueError("Select the history records to share");
    }
    context = review_context(workspace, vehicle_id);
    permitted = {record["id"] for record in context["records"]};
    if not `set(selected_ids).issubset(permitted) {
        raise ValueError(
            "Selected history is not part of this vehicle's current records"
        );
    }
    context["selected_history"] = [
        record
        for record in context.pop("records")
        if (record["id"] in cast(list[str], selected_ids))
    ];
    return context;
}

def issue_context(workspace: dict[str, any], vehicle_id: str, symptoms: any) -> dict[str, any] {
    context = review_context(workspace, vehicle_id);
    symptoms = support.text(symptoms, "Issue description", 2000);
    compact = re.sub(r"[^A-Z0-9]", "", str(symptoms).upper());
    for vehicle in workspace["vehicles"] {
        for key in ["plate", "vin"] {
            identifier = re.sub(r"[^A-Z0-9]", "", str(vehicle.get(key, "")).upper());
            if identifier and identifier in compact {
                raise ValueError("Describe symptoms only. Remove registration, VIN, contact and location details.");
            }
        }
    }
    if re.search(r"[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}|\b[A-HJ-NPR-Z0-9]{17}\b|\bK[A-Z]{2,3}\s*\d{3}[A-Z]?\b|\+?\d[\d ().-]{7,}\d|-?\d{1,3}\.\d{3,}\s*,\s*-?\d{1,3}\.\d{3,}", str(symptoms), re.IGNORECASE) {
        raise ValueError("Describe symptoms only. Remove registration, VIN, contact and location details.");
    }
    context["symptoms"] = symptoms;
    return context;
}
def validate_result(kind: any, result: any, context: any) -> any {
    if not isinstance(result, `dict) {
        raise AIUnavailable("Gemini returned an invalid result. Try again.");
    }
    source_records = context.get("records", context.get("selected_history", []));
    allowed = {record["id"] for record in source_records};
    def validate_ids(value: any, required: any = False) -> any {
        if (
            not isinstance(value, `list)
            or not all(isinstance(record_id, str) for record_id in value)
        ) {
            raise AIUnavailable(
                "AI citations were invalid. No result has been applied."
            );
        }
        if ((required and not value) or not `set(value).issubset(allowed)) {
            raise AIUnavailable(
                "AI cited unsupported records. No result has been applied."
            );
        }
    }
    if kind == "diagnosis" {
        support.text(result.get("summary"), "Issue summary", 3000);
        if result.get("urgency") not in ["routine", "soon", "stop_driving"] {
            raise AIUnavailable("AI urgency format was invalid");
        }
        causes = result.get("possible_causes");
        if not isinstance(causes, `list) or len(causes) > 5 {
            raise AIUnavailable("AI possible causes format was invalid");
        }
        for item in causes {
            if not isinstance(item, `dict) { raise AIUnavailable("AI cause format was invalid"); }
            support.text(item.get("cause"), "Possible cause", 300);
            support.text(item.get("reasoning"), "Cause reasoning", 1500);
            validate_ids(item.get("record_ids"));
        }
        for (field, maximum, minimum) in [("next_checks", 6, 1), ("questions", 4, 0)] {
            values = result.get(field);
            if not isinstance(values, `list) or len(values) > maximum or len(values) < minimum {
                raise AIUnavailable("AI troubleshooting format was invalid");
            }
            for value in values {
                if not isinstance(value, str) { raise AIUnavailable("AI troubleshooting item was invalid"); }
                support.text(value, "Troubleshooting item", 1500);
            }
        }
    } elif (kind == "review") {
        support.text(result.get("overview"), "AI overview", 3000);
        highlights = result.get("highlights");
        gaps = result.get("gaps");
        if (
            not isinstance(highlights, `list)
            or (len(highlights) > 5)
            or not isinstance(gaps, `list)
            or (len(gaps) > 4)
        ) {
            raise AIUnavailable(
                "The AI review did not match the required structure. Try again."
            );
        }
        for item in highlights {
            if not isinstance(item, `dict) {
                raise AIUnavailable("AI highlight format was invalid");
            }
            support.text(item.get("statement"), "AI highlight", 1500);
            validate_ids(item.get("record_ids"), required=True);
        }
        for gap in gaps {
            if not isinstance(gap, str) {
                raise AIUnavailable("AI gap format was invalid");
            }
            support.text(gap, "AI gap", 1500);
        }
    } else {
        support.text(result.get("description"), "AI description", 2000);
        validate_ids(result.get("record_ids"));
    }
    return result;
}
def generate(workspace: dict[str, any], kind: str, payload: dict[str, any]) -> dict[str, any] {
    vehicle_id = str(payload.get("vehicle_id", ""));
    if (kind == "review") {
        context = review_context(workspace, vehicle_id);
    } elif kind == "diagnosis" {
        context = issue_context(workspace, vehicle_id, payload.get("symptoms"));
    } elif (kind == "draft") {
        context = market_context(
            workspace, vehicle_id, payload.get("shared_record_ids", [])
        );
    } else {
        raise ValueError("Unknown AI workflow");
    }
    (key, model) = load_ai_config();
    if not key {
        raise AIUnavailable(
            "Gemini is not configured or AI is paused. Open Settings to configure your account."
        );
    }
    if not model.startswith("gemini/") {
        raise AIUnavailable("Choose a Gemini model in SMARTMOTI_AI_MODEL.");
    }
    started = time.monotonic();
    try {
        module = importlib.import_module("vehicle_ai");
        if kind == "diagnosis" { value = module.assess_issue(context); }
        elif kind == "review" { value = module.review_history(context); }
        else { value = module.draft_marketplace(context); }
        result = validate_result(kind, support.dataclass_payload(value), context);
    } except (ValueError, AIUnavailable) {
        raise;
    } except Exception {
        raise AIUnavailable(
            "Gemini could not complete this request. Check the key, model access and quota, then try again."
        ) from None;
    }
    return {
        "result": result,
        "provider": "Gemini",
        "model": model,
        "generated_at": support.now(),
        "duration_seconds": support.rounded(cast(float, time.monotonic() - started), 2),
        "kind": kind,
        "evidence_record_ids": [
            record["id"]
            for record in context.get("records", context.get("selected_history", []))
        ]
    };
}
