---
title: Smartmoti
emoji: 🚗
colorFrom: yellow
colorTo: green
sdk: docker
app_port: 7860
pinned: false
---

# Smartmoti

A Jac project for vehicle lifetime records, fuel management, and a vehicle marketplace, with an elegant public landing page and a responsive garage interface. AI is not required. Blockchain is reserved for optional NFT minting.

## Kenya hackathon readiness

The supplied October 16–17 hacker guide requires at least 80% Jac code. Current audit: **78.03% Jac by source bytes and 84.29% by nonblank lines**, counting first-party CSS, HTML, tests and tools alongside application code. **The repository currently fails the local byte threshold after parallel stylesheet additions; its nonblank-line share remains above 80%.** Run `npm.cmd run check:hackathon` to enforce both thresholds, or `npm.cmd run audit:jac -- --json` for the inventory. Generated output, dependencies, caches and private runtime data are excluded. The guide does not specify its counting method; see [HACKATHON.md](HACKATHON.md) for the methodology and remaining submission requirements.

## Run locally on Windows

Requires Python 3.12 or newer. The application binds to localhost only.

```powershell
cd C:\Users\user\Desktop\Ken\smartmoti
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install --no-deps jaclang==0.16.7
.\.venv\Scripts\python.exe -m pip install cryptography==50.0.2
.\.venv\Scripts\python.exe server.py
```

Open **http://127.0.0.1:8000**. Select **Explore the demo** for a clearly labelled sample garage, or create an account for an empty workspace. The launch helper is `start.ps1`; the direct Python command also works where PowerShell script execution is restricted. Pass `--port 8080` to use another port.

Jac 0.16.7 is pinned. Server modules use its Python-bytecode runtime; `web/app.cl.jac` compiles through its ECMAScript backend. Startup generates `.jac/client/app.js`; edit the Jac source rather than generated JavaScript. `--no-deps` avoids the unused native compiler dependency. On Windows, `client_build.jac` explicitly runs the ES generation pass because the ordinary backend schedule can skip it when the optional native dependency is absent. Native compilation targets require installing Jac with its normal dependencies.

## Implemented

For presentations, open **http://127.0.0.1:8000/demo**. The showcase includes a guided seven-step walkthrough, deeper vehicle histories, private sample receipts, an illustrative trip, and a sample buyer enquiry. See [SHOWCASE.md](SHOWCASE.md) for a five-minute script. **Fresh demo** creates a new sample session without modifying real account data.

- Public landing page, responsive dashboard, signup, login, logout, and isolated account workspaces.
- Vehicle passports with stable IDs, VIN and registration, acquisition, maintenance, repairs, inspections, incidents, odometers, ownership events, and retirement records.
- Append-only record corrections that preserve the original; source labels and explicit unverified status.
- Private PDF, PNG and JPEG supporting documents, limited to 5 MB each.
- Fuel entries, receipts, totals separated by currency, and consumption calculations across consecutive full-tank checkpoints, including intervening partial fills.
- Marketplace listings with a selected history summary, enquiries through offer messages, offers, and seller-controlled listing status.
- Vehicle passport export and non-sensitive NFT metadata preview and download.
- Separate demo garages; demo listings cannot appear in real account marketplaces or send offers to them.

## Gemini AI

Open **Ask Smartmoti** in the top bar, **Assistant** in navigation, or **Explore this vehicle with Smartmoti** in a passport. The Assistant has a dedicated conversation workspace, a selected vehicle context, suggested prompts, a visible tool trail and exact-field proposal cards.

`vehicle_agent.jac` runs a bounded Gemini agent loop: model -> authorized tools -> model, up to five turns and twelve tool calls. Gemini can search your garage, retrieve recorded history, ask Jac for actual fuel calculations, and retrieve your listings. It can prepare vehicle registrations, new lifetime or fuel records, and eligible corrections. **Prepare does not save.** Approve and save applies the reviewed proposal through the same Jac workflows as the manual forms. Discard rejects it. Missing facts require clarification; corrections involving private documents or notes use the manual form.

Conversations and proposal status are persisted per account. Approval checks the current workspace fingerprint, applies the trusted stored payload atomically, and records the result. Repeated approvals return the same saved result. Changed workspaces invalidate pending proposals. The agent has no delete, payment, vehicle control, message-sending or minting tool.

The latest conversation now resumes on reload and sign-in, including the tool trail and current proposal statuses. Registration, inspection, fuel logging and eligible corrections can be completed from the Assistant: describe the facts, let Gemini retrieve the relevant records, review the proposal, approve, then use **View saved vehicle passport** to inspect the saved result. After approving a new vehicle, the conversation focuses that vehicle for follow-up records. Suggested inspection/refuelling prompts ask for missing facts rather than inserting demo mileage. **New conversation** starts a separate thread without deleting earlier data. Conversation display data stays in the account-bound SQLite store; native model thought signatures remain server-only.

**Assistant -> Detailed history review** retains the typed, record-cited overview in `vehicle_ai.jac`. **Marketplace -> List a vehicle -> Draft with Gemini** uses only the history selected for sharing. These two actions use structured-output Gemini requests in `gemini_gateway.jac`; the agent uses native [Gemini function calling](https://ai.google.dev/gemini-api/docs/function-calling) through `agent_runtime.jac` and the Python entry boundary in `agent_tools.py`, backed by executing `agent_tool_workflows.jac`.

No provider SDK is required. Users can configure a personal Gemini key directly in **Settings -> AI, on your terms**, choose a model, save, and use **Test connection**. Leave the password field blank to keep an existing key; remove it with the explicit removal button. AI can be paused, and server fallback is optional. Personal keys take priority across all three AI features. For the shared server configuration, use:

```powershell
.\.venv\Scripts\python.exe configure_ai.py
```

The setup command accepts a new Gemini key without echoing it and saves it in the ignored `.env` file. Alternatively edit `.env` directly. The server reads it when a request is made, so saving a key does not require a restart. The default is `gemini/gemini-3.8-flash`; choose an available Gemini model through `SMARTMOTI_AI_MODEL`.

Record notes, document contents and IDs, VIN, registration, owner details and GPS coordinates are excluded from model context. Input record titles remain untrusted data; output citations must refer to supplied records. AI text is displayed as a review or editable draft. It is not a verified vehicle record, a mechanical diagnosis, a valuation, or an automatically published listing.

The request uses Gemini's [generateContent API](https://ai.google.dev/api/generate-content) with a JSON response schema. The key remains on the server and is never sent to the browser. No existing project keys are reused. If configuration or inference fails, the application reports the failure rather than substituting canned text and claiming it is AI. Core vehicle and fuel workflows continue without a model.

## Account settings

**Settings** in navigation or the account avatar opens profile editing, personal Gemini credentials, fuel currency and opening-page preferences, password changes and a JSON export of your own records. Email changes require the current password; password changes close other sessions while keeping the current session open. Demo users can edit their display name but cannot change a sign-in email or password. Their settings remain tied to that demo workspace.

Credentials are encrypted using [Fernet](https://cryptography.io/en/latest/fernet/) and bound to the account ID. Plain keys are never returned in settings or state responses. The encryption key is created beside the database as `smartmoti.credentials.key`, within ignored `data/`; set `SMARTMOTI_SECRET_FILE` for a separate protected path. Back up the encryption key securely with the database; losing it makes saved personal keys unreadable. Credentials remain accessible to the server that performs inference. Saved configuration is not proof of provider access: Test connection performs a small real Gemini request, which can use quota. Inference tests use mocked provider responses.

Fuel currency changes only defaults for new entries; existing records retain their currency. The opening-page preference applies on sign-in and ordinary reload, while `/demo` opens its guided showcase. Exports include your profile and vehicle records, not credentials or document binaries.

## Jac and persistence

`domain.jac` contains the graph nodes, the `Passport` walker, and deterministic vehicle, timeline, fuel, listing, and metadata workflows. The Python host imports and compiles that Jac module through Jac's import hook. This is an executing Jac backend.

`server.py` supplies HTTP, password hashing, cookie sessions, private file delivery and SQLite transactions. `account_access.jac` orchestrates account requests; `application.jac` routes workspace requests inside the Python-owned transaction. Vehicle validation, fuel calculations and listing transitions live in `domain.jac`. Workspace snapshots are persisted in SQLite and hydrated into Jac nodes and edges for passport traversal. Graph persistence is explicit through SQLite snapshots rather than Jac's native graph database. The browser reads and writes through the server; records are not held only in browser storage.

Data is stored in `data/smartmoti.db`. Set `SMARTMOTI_DB` to use a different database path. Include that database in backups; it contains account records and private uploaded documents. This is a local MVP with one personal workspace per account. Organization roles and shared fleet access are future work.

The interface is authored in `web/app.cl.jac` and compiled to plain browser JavaScript by `client_build.jac`. Shared CSS lives in `web/styles.css`; no frontend component framework or external font service is required. Cryptography encrypts personal credentials. Node runs the browser checks. Vehicle drawings are illustrations, not photos of the listed models.

## Obsidian x Electric Lime interface

The Obsidian (`#111514`), Electric Lime (`#D5FF4F`) and Porcelain (`#F4F5F0`) interface uses Slate (`#303936`), Muted Sage (`#8C9A92`) and white supporting surfaces. Dark automotive stages contrast with light reading surfaces. Bold system-font headlines, monospaced identifiers and mileage, roadline event markers and evidence stamps carry the same design across the landing page, garage, passport, fuel, tracking, marketplace, Assistant and settings. Lime identifies selected navigation and important actions; darker semantic accent text preserves contrast on light backgrounds. A two-way Light/Dark switch in the sticky top bar saves your choice in the browser; dark mode uses layered obsidian surfaces and a darker sidebar with an edge. Account details and Sign out live at the foot of the sidebar, or in the Menu on smaller screens.

My Garage features the selected vehicle, its latest reported ownership entry and latest service or inspection. Use the vehicle selector to change the featured passport. The collection uses ledger-style rows; marketplace listings use an editorial lead layout. Source & evidence disclosures expose private notes, supporting document links and correction actions in the signed-in workspace. Unverified records remain explicitly labelled.

The labelled **Theme** switcher offers **Light** and **Dark** on every workspace screen and in the landing footer. Porcelain light is the initial default. Only the chosen display preference is saved in browser local storage. No account, vehicle, conversation or credential information is stored there. Older system-mode preferences fall back to light. The workspace toolbar groups its page and date on the left, with the Assistant, theme and account actions on the right. System fonts avoid external requests. Keyboard skip navigation, visible focus, native dialog focus handling and reduced-motion styles are supported.

The public landing page uses a full-width dark automotive stage, a minimal desktop masthead and an expandable mobile menu with Escape-to-close support. Display preferences sit in the footer to keep the public navbar focused. It uses locally served responsive WebP editorial photography by [Josh Berquist on Unsplash](https://unsplash.com/photos/pjxe3p4u5aI), under the [Unsplash License](https://unsplash.com/license). Attribution and provenance are retained in `web/assets/LICENSE.txt`. Responsive 900px and 2000px WebP variants load from this server without third-party browser requests. The photograph is labelled editorial and does not represent a listed or registered vehicle. Where actual vehicle photography is unavailable, garages and listings use a clearly labelled neutral silhouette. Vehicle photo upload and account-owned image management are not implemented by this redesign.

There is no maintenance due-date schedule in the current domain model. The garage therefore shows **No due schedule recorded**, alongside the latest recorded service or inspection, rather than inventing a service interval. Verification labels describe the existing reported evidence; this redesign adds no independent verification service. Tracking, fuel sensors, AI access and NFT minting retain the integration limits below.

## Integration limits

**Tracking:** real workspaces accurately show that no live provider is connected. The showcase has an explicitly labelled sample route diagram and demo observation; these are not live positions or sensor data. Protrack and IOPGPS integration still requires credentials, device assignment, and verified payload mapping. Fuel sensors are a later integration.

**NFTs:** metadata preparation works. No contract is deployed, wallet connected, or NFT minted in this release. Minting will remain an isolated action; routine records and marketplace transactions will stay off-chain.

**Marketplace:** offers are stored in the application; no external messages or payments are sent. Recording a sale adds a seller-reported handover event. Automatic transfer of records and permissions to a buyer account is not implemented. A recorded history is not proof of legal ownership or mechanical condition.

**Documents:** ownership access is enforced for uploaded files. Shared marketplace history excludes document IDs, notes, VIN, registration, and tracking information. Anyone can browse active and reserved listings from real accounts at `/market` without signing in (`GET /api/public/market`). That view returns only the listing summary, the selected history and the seller's first name, with no account or vehicle identifiers. Making an offer requires signing in. Demo listings never appear publicly and stay isolated in demo workspaces.

**Hosting:** by default the server listens only on `127.0.0.1`. `render.yaml` deploys one instance to Render behind its HTTPS proxy; see **Deploy on Render** below. The host is Python's single-threaded `HTTPServer` on one SQLite file, so requests are handled one at a time and the service cannot scale beyond one instance. Authentication abuse controls (rate limiting, lockout), password reset, email verification and organization authorization are not implemented. Treat a hosted deployment as a pilot.

## Deploy on Jac Hammer

Jac Hammer runs **jaclang 0.34.23** and starts the `jac.toml` entry point with `jac start`, expecting the app on port 8000. `main.jac` is that entry point: it starts the Smartmoti host (`server.py`) on `0.0.0.0` and `$PORT` (default 8000). `jac.toml` and `requirements.txt` deliberately do not pin `jaclang`, because the host provides it; pinning 0.16.7 makes Jac Hammer's dependency install fail. Behind Jac Hammer's HTTPS proxy, the server reads `X-Forwarded-Proto` and `X-Forwarded-Host`, so sign-up and login work without setting `SMARTMOTI_HTTPS`. Add `GEMINI_API_KEY` in Jac Hammer's environment settings for server AI. Jac Hammer keeps its own copy of the project files, so after pushing to GitHub, re-import or sync the project in Jac Hammer and confirm its `domain.jac` matches `main` before reading a new startup log.

The source is compatible with both jaclang 0.16.7 (local Windows development) and 0.34.23: lambdas use the braced form with an explicit `return`, module state uses `glob` without `global` statements, and client code avoids `del`. Under 0.34.23, `jac check` reports type errors for browser globals and untyped JSON in `web/app.cl.jac` and the test suites; the Jac guide documents these as checker limitations, and they do not affect the build or runtime. Hosted storage on Jac Hammer is not guaranteed to persist; treat it as a demo deployment.

## Automated checks and deployment

`.github/workflows/deploy.yml` runs on every push to `main`: the backend unit tests on jaclang 0.16.7, and a Jac Hammer startup check that downloads the official jaclang 0.34.23 Linux build (checksum-verified), runs `jac install` and `jac start`, and probes health, the web client and an HTTPS-proxied sign-up. To also deploy to Hugging Face Spaces automatically, add a repository variable `HF_SPACE` (for example `kinyagia/smartmoti`) and a secret `HF_TOKEN` with write access under **Settings -> Secrets and variables -> Actions**; the deploy job runs only after both checks pass.

## Deploy on Render

`render.yaml` is a Render Blueprint. Push the repository to GitHub, then in Render choose **New -> Blueprint**, select the repository, enter `GEMINI_API_KEY` when prompted (leave it blank to rely on personal keys in Settings), and apply. Render builds with the pinned Jac and cryptography versions, starts `python server.py`, and checks `/api/health`.

| Variable | Purpose |
| --- | --- |
| `PORT` | Listening port; Render sets it. `--port` overrides it. |
| `SMARTMOTI_HOST` | Bind address; `0.0.0.0` on Render. Defaults to `127.0.0.1`. |
| `SMARTMOTI_HTTPS` | `1` behind an HTTPS proxy: accepts `https://` request origins (matching `X-Forwarded-Host` when the proxy sends it, otherwise `Host`), marks the session cookie `Secure` and sends HSTS. Leave unset locally. |
| `SMARTMOTI_DB`, `SMARTMOTI_SECRET_FILE` | Database and credential key paths. Unset on the free plan, so they default to `data/` in the app folder. |

The Blueprint uses Render's **free plan**, which has no persistent disk. **Hosted accounts, records and uploads are temporary**: they are erased whenever the service restarts, redeploys, or sleeps after 15 minutes without traffic, and the first request after sleeping takes about a minute. **Explore the demo** creates a fresh sample garage each time, so it remains usable for presentations. Do not invite real users to a free deployment. For lasting data, switch to a paid plan, attach a disk at `/var/data`, set `SMARTMOTI_DB=/var/data/smartmoti.db` and `SMARTMOTI_SECRET_FILE=/var/data/smartmoti.credentials.key`, and back up both files. Vercel is unsuitable without a rewrite, because its serverless functions have no persistent disk for SQLite.

## Deploy on Hugging Face Spaces

Render asks for a card even for free services. Hugging Face Spaces runs the `Dockerfile` on free CPU hardware; the YAML block at the top of this README is the Space configuration (`sdk: docker`, `app_port: 7860`). Create a **Docker** Space with the blank template, add `GEMINI_API_KEY` under **Settings -> Variables and secrets** as a secret (optional), then upload the project from this folder:

```powershell
.\.venv\Scripts\python.exe -m pip install huggingface_hub
.\.venv\Scripts\hf.exe auth login
.\.venv\Scripts\hf.exe upload <your-username>/smartmoti . . --repo-type=space --exclude ".env" ".venv/*" ".jac/*" "data/*" "artifacts/*" "node_modules/*" "*.pptx" ".git/*"
```

Open the app at `https://<your-username>-smartmoti.hf.space`, not the huggingface.co Space page: the page embeds the app in a frame, which Smartmoti's security headers refuse. Free Space storage is temporary, with the same data-loss limits as Render's free plan, and a Space sleeps after a period without visitors.

## Verification

```powershell
.\.venv\Scripts\jac.exe check domain.jac vehicle_ai.jac vehicle_agent.jac --nowarn
.\.venv\Scripts\python.exe -m unittest discover -s tests -v
npm.cmd install --ignore-scripts --no-audit --no-fund
npm.cmd run check:hackathon
npm.cmd run check
# Start server.py in another terminal before the browser test:
npm.cmd run test:ui
npm.cmd run test:agent-e2e
# Also run the full UI suite against the same isolated temporary server:
npm.cmd run test:agent-e2e -- --all-ui
```

Browser cases are authored in `tests/ui.cl.jac`; `tests/ui.mjs` compiles and launches their generated JavaScript using installed Microsoft Edge through Playwright Core. Backend cases live in `tests/*_cases.jac`, with thin Python unittest-discovery bridges. Set `EDGE_PATH` to an alternative Chromium executable or `SMARTMOTI_URL` to a different local port. They check the landing page, demo access, timeline writes and reload persistence, fuel calculations, marketplace details, mobile overflow, the Assistant conversation, and proposal approval UI using explicitly mocked model fixtures. Automotive Journal checks also exercise featured-vehicle selection, theme persistence, keyboard evidence disclosures, skip navigation, reduced motion and all seven workspace screens at 320, 390, 768 and 1440 pixels. Dark mode screenshots cover all workspace screens. Backend tests exercise real Jac proposal approval, stale changes, ownership, idempotency, and failure rollback with mocked provider transport. Live inference requires a working key and was not verified by the source migration. Screenshots are written into ignored `artifacts/`.

For an isolated visual review, set `SMARTMOTI_DB` and `SMARTMOTI_SECRET_FILE` to separate files under `artifacts/` before starting the server on another port, then point `SMARTMOTI_URL` at that port. Browser tests create demo workspaces and test accounts; do not target a database containing real accounts.

Backend tests use temporary databases and exercise actual compiled Jac workflows, including account isolation, document access, currency separation, odometer consistency, corrections, marketplace privacy, offers, and demo separation.

`test:agent-e2e` creates an isolated temporary database and a real local HTTP server, then drives the actual browser interface through native model tool exchanges, registration, inspection, two full-tank fuel entries, fuel calculations, correction, reload recovery, rejection, stale approval and provider failure. Only `agent_runtime.urlopen` and provider configuration are mocked in this test harness; chat, approval, state and conversation APIs execute normally through Jac and SQLite. The test provider is clearly labelled and exists only under `tests/`. This verifies the complete application path, not live Gemini reasoning. Live inference remains unverified because no shared provider key is configured; users can configure and test their own key in Settings.

**Assistant recovery limit:** the UI restores the latest thread, rather than offering a conversation archive chooser. Older native-only sessions are retained on the server, but do not silently continue an invisible conversation; display recovery covers new exchanges saved after this update. Conversation history is not included in the vehicle-record JSON export.

## Project files

| File | Purpose |
| --- | --- |
| `domain.jac` | Jac graph and business workflows |
| `vehicle_agent.jac` | Bounded agent orchestration |
| `agent_tools.py` / `agent_tool_workflows.jac` | Authorized tool entry and dry-run proposal workflows |
| `agent_runtime.jac` / `gemini_gateway.jac` | Tool exchanges and structured provider transport |
| `application.jac` / `account_access.jac` | Workspace and account request orchestration |
| `account_settings.py` / `account_preferences.jac` | Encrypted credentials and non-secret preference validation |
| `client_build.jac` / `source_audit.jac` | Browser compilation and the source-share gate |
| `support.py` | Identifiers, local dates, text and numeric validation helpers |
| `server.py` | Local HTTP host, authentication and SQLite persistence |
| `web/` | Landing page and workspace interface |
| `tests/` | Backend integration and browser checks |
| `PROJECT_PLAN.md` | Product direction and later integration phases |

The Neurocar and Omni source folders remain unchanged.
