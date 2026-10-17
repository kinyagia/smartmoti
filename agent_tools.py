"""Authorized Python entry boundary for account-scoped Jac tools.

The caller supplies only its signed-in workspace. Jac reads that snapshot or
dry-runs domain changes; saving remains an owned approval transaction.
"""
import jaclang
from agent_tool_workflows import (
    TOOLS, WRITE_TOOLS, STRING, NUMBER, VEHICLE, RECORD_FIELDS,
    declaration, workspace_hash,
    prepare_proposal as _prepare_proposal,
    execute_tool as _execute_tool,
)


def prepare_proposal(workspace, tool, args):
    if tool not in WRITE_TOOLS:
        raise ValueError("This tool cannot modify data")
    return _prepare_proposal(workspace, tool, args)


def execute_tool(workspace, name, args, run):
    if not isinstance(args, dict):
        raise ValueError("Tool arguments must be an object")
    return _execute_tool(workspace, name, args, run)
