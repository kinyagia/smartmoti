"""Owned UI transcript projection. Native model parts remain server-only."""
import json;
import from typing { cast }
import agent_tools;

def public_proposal(
    db: any, user_id: str, proposal_id: str, state: dict[str, any]
) -> dict[str, any] {
    row = db.execute(
        "SELECT * FROM agent_proposals WHERE id=? AND user_id=?", (proposal_id, user_id)
    ).fetchone();
    if not row {
        return {};
    }
    stored = cast(dict[str, any], json.loads(str(row["proposal"])));
    status = str(row["status"]);
    if status == "pending"
    and stored["state_hash"] != agent_tools.workspace_hash(state) {
        status = "stale";
    }
    result = {key: stored[key] for key in ["id", "tool", "preview", "summary"]};
    result["status"] = status;
    payload = cast(dict[str, any], stored["payload"]);
    result["vehicle_id"] = str(payload.get("vehicle_id", ""));
    if status == "applied" and stored["action"] == "register_vehicle" {
        saved = cast(dict[str, any], json.loads(str(row["result"])));
        result["vehicle_id"] = str(saved["id"]);
    }
    return result;
}

def latest_conversation(
    db: any, user_id: str, state: dict[str, any]
) -> dict[str, any] {
    session = db.execute(
        "SELECT id, contents FROM agent_sessions WHERE user_id=? ORDER BY updated_at DESC, rowid DESC LIMIT 1",
        (user_id, )
    ).fetchone();
    if not session {
        return {"session_id": None, "messages": [], "vehicle_id": ""};
    }
    messages: list[dict[str, any]] = [];
    vehicle_id: str = "";
    for turn in db.execute(
        "SELECT * FROM agent_turns WHERE session_id=? AND user_id=? ORDER BY rowid",
        (session["id"], user_id)
    ) {
        response = cast(dict[str, any], json.loads(str(turn["response"])));
        proposals: list[dict[str, any]] = [];
        for item in cast(list[dict[str, any]], response.get("proposals", [])) {
            proposal = public_proposal(db, user_id, str(item["id"]), state);
            if proposal {
                proposals.append(proposal);
            }
        }
        messages.append({"role": "user", "text": str(turn["message"])});
        messages.append(
            {
                "role": "assistant",
                "text": response["answer"],
                "trace": response["trace"],
                "proposals": proposals,
                "limited": response["limited"]
            }
        );
        vehicle_id = str(turn["vehicle_id"]);
        for proposal in proposals {
            if proposal["status"] == "applied"
            and proposal["tool"] == "propose_register_vehicle" {
                vehicle_id = str(proposal["vehicle_id"]);
            }
        }
    }
    if not messages and str(session["contents"]) != "[]" {
        # Older native-only sessions have no display transcript. Preserve them,
        # but do not silently continue a conversation the user cannot see.
        return {"session_id": None, "messages": [], "vehicle_id": ""};
    }
    return {
        "session_id": str(session["id"]),
        "messages": messages,
        "vehicle_id": vehicle_id
    };
}
