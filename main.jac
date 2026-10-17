"""Hosted entry point: `jac start` (Jac Hammer) runs this module to serve Smartmoti.

server.py owns HTTP, sessions and SQLite transactions; vehicle workflows stay in
domain.jac. Listens on 0.0.0.0 and $PORT (default 8000) unless SMARTMOTI_HOST or
PORT say otherwise.
"""
import os;
import server;

with entry {
    os.environ.setdefault("SMARTMOTI_HOST", "0.0.0.0");
    server.main([]);
}
