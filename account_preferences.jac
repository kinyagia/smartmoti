"""Non-secret account preference validation and public status projection."""
import re;
import support;

def update_preferences(
    prefs: dict[str, any], payload: dict[str, any], section: str, currencies: list[str]
) -> dict[str, any] {
    result = dict(prefs);
    if section == "preferences" {
        if payload.get("currency") not in currencies
        or payload.get("start_page") not in [
            "garage",
            "passport",
            "fuel",
            "assistant",
            "settings"
        ] {
            raise ValueError("Choose a supported currency and opening page");
        }
        result.update(currency=payload["currency"], start_page=payload["start_page"]);
    } elif section == "ai" {
        model = support.text(payload.get("model"), "Gemini model", 100);
        if not re.fullmatch(r"gemini/(gemini-[a-zA-Z0-9._-]+)", model) {
            raise ValueError("Use a Gemini model name such as gemini/gemini-3.8-flash");
        }
        for field in ["ai_enabled", "use_server_ai"] {
            if not isinstance(payload.get(field), bool) {
                raise ValueError("AI preferences must be true or false");
            }
        }
        result.update(
            model=model,
            ai_enabled=payload["ai_enabled"],
            use_server_ai=payload["use_server_ai"]
        );
    } else {
        raise ValueError("Unknown settings section");
    }
    return result;
}

def public_settings(
    prefs: dict[str, any], personal_key_saved: bool, server_status: dict[str, any]
) -> dict[str, any] {
    source: str = "none";
    if personal_key_saved {
        source = "personal";
    } elif prefs["use_server_ai"] and server_status["configured"] {
        source = "server";
    }
    configured = source != "none";
    result = dict(prefs);
    result["personal_key_saved"] = personal_key_saved;
    result["ai"] = {
        "configured": configured,
        "available": configured and prefs["ai_enabled"],
        "provider": "Gemini",
        "model": server_status["model"] if source == "server" else prefs["model"],
        "source": source,
        "enabled": prefs["ai_enabled"]
    };
    return result;
}
