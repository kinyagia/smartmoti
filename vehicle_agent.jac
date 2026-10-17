"""Bounded agent orchestration in Jac: model -> authorized tools -> model."""
import from agent_runtime { begin_run, model_turn, handle_turn, finish_run }
import from domain { find_vehicle }

def run_agent(workspace: dict[str, any], message: str, selected_vehicle_id: str, prior: list[dict[str, any]]) -> dict[str, any] {
    if selected_vehicle_id { find_vehicle(workspace, selected_vehicle_id); }
    run = begin_run(message, selected_vehicle_id, prior);
    for step in range(5) {
        content = model_turn(run);
        if handle_turn(workspace, run, content) { break; }
    }
    return finish_run(run);
}
