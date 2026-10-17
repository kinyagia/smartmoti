# Smartmoti development

Vehicle business workflows belong in `domain.jac`. Keep Jac as the application domain language. Python provides the local HTTP host, SQLite transactions, authentication, and small validation helpers. The interface lives in `web/`.

Preserve the product scope: vehicle lifetime records first, tracking and fuel support, marketplace, and blockchain only for optional NFT minting. AI is optional. Do not move ordinary records or marketplace transactions onto a blockchain.

AI reviews and editable marketplace drafts use `vehicle_ai.jac` with typed Gemini structured responses. Keep record notes, document data, VIN, registration, personal information and GPS out of model context. Drafts may use only selected public history. Validate output citations against supplied records. Never replace a failed model call with canned text presented as AI.

Keep demo workspaces isolated from real accounts. Never fabricate missing live tracking or fuel data. Marketplace history must not expose private notes, documents, VIN, registration, or precise location history.

Keep Jac sources compatible with jaclang 0.16.7 (local) and 0.34.23 (Jac Hammer): braced lambdas with explicit `return`, `glob` module state without `global` statements, no `del` in client code. `main.jac` is the hosted entry point; do not pin `jaclang` in `jac.toml` or `requirements.txt`. The GitHub workflow verifies 0.34.23 startup on every push.

After domain changes, run `.venv\Scripts\jac.exe check domain.jac --nowarn` and `.venv\Scripts\python.exe -m unittest discover -s tests -v`. For interface changes, run `npm.cmd run check` and the applicable browser checks in `tests/ui.mjs` against the local server. Document any changed integration limits in `README.md`.

The source folders for Neurocar and Omni are reference projects; keep them unchanged unless the user requests otherwise.

The agent loop belongs in `vehicle_agent.jac`. Authorized tools in `agent_tools.py` read only the signed-in workspace and dry-run Jac writes into proposals. Keep mutations behind owned, fingerprint-checked, idempotent approval transactions. Do not add automatic deletes, payments, messages, vehicle control or minting. Preserve native model thought signatures during tool exchanges. Run Jac checks on all three .jac modules after agent changes. Provider and UI mocks are test-only; report live inference separately.

Account settings live in `account_settings.py`. Keep credentials encrypted and account-bound, return status only, and scope provider configuration with ContextVar rather than global environment mutation. Personal keys must work across all AI paths. Never add keys to logs, JSON exports, browser storage, conversation contents or public listings.
