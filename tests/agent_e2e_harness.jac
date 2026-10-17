"""Isolated real-server/browser run; mock only provider transport, never the APIs."""
import os;
import sys;
import subprocess;
import threading;
import from pathlib { Path }
import from tempfile { TemporaryDirectory }
import from unittest.mock { patch }
import server;
import agent_runtime;
import ai_service;
import client_build;
import from tests.agent_provider_fixture { transport }

def main() -> None {
    project = Path(str(__file__)).resolve().parent.parent;
    browser_test = client_build.compile_source(
        project / "tests" / "agent_e2e.cl.jac",
        project / ".jac" / "tests" / "agent-e2e.mjs"
    );
    with TemporaryDirectory() as directory {
        with patch.object(server, "DB_PATH", Path(directory) / "agent-e2e.db"), patch.object(
            ai_service,
            "load_ai_config",
            return_value=("test-only-provider-key", "gemini/gemini-test")
        ), patch.object(agent_runtime, "urlopen", side_effect=transport) {
            server.initialize();
            http = server.HTTPServer(("127.0.0.1", 0), server.Handler);
            thread = threading.Thread(target=http.serve_forever, daemon=True);
            thread.start();
            try {
                environment = dict(os.environ);
                environment["SMARTMOTI_URL"] = f"http://127.0.0.1:{http.server_port}";
                subprocess.run(
                    ["node", str(browser_test)],
                    cwd=str(project),
                    env=environment,
                    check=True,
                    timeout=180
                );
                if "--all-ui" in sys.argv {
                    subprocess.run(["node", "tests/ui.mjs"], cwd=str(project), env=environment, check=True, timeout=240);
                }
            } finally {
                http.shutdown();
                http.server_close();
                thread.join(timeout=5);
            }
        }
    }
}

with entry {
    if __name__ == "__main__" {
        main();
    }
}
