# Smartmoti’s current audit reports **78.03% Jac by source bytes and 84.29% by nonblank lines**. The repository currently fails the local byte threshold after parallel stylesheet additions; its nonblank-line share remains above 80%. This includes first-party application source, CSS, HTML, tests and tools. The developer confirmed event-window development. External submission requirements remain incomplete; the guide does not specify an official counting method.

Smartmoti now passes the local 80% repository source-share check: **81.31% Jac by source bytes and 86.54% by nonblank lines**. This counts first-party application source, CSS, HTML, tests and tools. The developer confirmed that Smartmoti was built during this hackathon. External submission requirements remain incomplete, and the guide does not specify an official counting method.

Source: `C:\Users\user\Downloads\AI Hackathon (Kenya) - Hacker Guide.pdf`, nine pages, reviewed on 17 October 2026. Page references below refer to that supplied guide, rather than a different JacHacks event.

## Requirements and evidence

| Requirement | Status | Evidence or remaining action |
| --- | --- | --- |
| At least 80% of code in Jac (pages 2, 5, 6) | FAIL by bytes under local method | `npm.cmd run check:hackathon`: 78.03% Jac by source bytes and 84.29% by nonblank lines. Parallel stylesheet additions are included. Confirm the organizer’s counting method. |
| Working software meaningfully using Jac (page 6) | Implemented and locally verified | Jac nodes, edges, `Passport` walker, vehicle and fuel workflows, typed AI results, and bounded agent orchestration execute in the application. |
| All coding during the event; repositories checked (page 6) | Developer confirmed | On 17 October 2026, the developer confirmed Smartmoti was built during this hackathon. Guide starts coding Friday 16 October at 4:00 PM. This repository currently has no commits, so independent repository-history verification remains unavailable. Preserve authentic development evidence; do not backdate or invent history. |
| Every member registered and checked in via Discord (pages 6–7) | Team action required | Confirm for every member; registration/check-in is not evidenced by this repository. |
| One to four members and one project per team (pages 2, 6) | Team action required | Record the actual team and ensure no second project is entered. |
| GitHub code link (page 5) | Missing | Publish the eligible source and provide its actual URL. Exclude `.env`, `data/`, credentials, private documents and dependencies. |
| Working-project demo video by deadline (pages 5–6) | Missing | Record the actual application using `SHOWCASE.md`; include real tool use and approved persistence if live inference succeeds. |
| Pitch deck (page 5) | Missing | Build an actual presentation from the outline below and attach/export it for submission. An outline is not the required deck. |
| Written project description including Jac/Jaseci use (page 5) | Draft below | Update final features, links and team details before submission. |
| Star `github.com/jaseci-labs/jac` (page 5) | Team action required | Complete from the appropriate GitHub account. |
| Submit on Devpost on time (pages 6–7, 9) | Team action required | Guide gives Saturday 17 October, 3:30 PM; submission link will be shared. Confirm timezone and exact link in organizer announcements. |
| Host on Jac Hammer (page 5) | Optional, not completed | Encouraged rather than mandatory. Current host is localhost only; do not claim Jac Hammer deployment. |
| Good faith and accurate claims (page 6) | Required throughout | Separate sample data, mocked tests, successful live inference and incomplete integrations. |

The guide describes 24 hours, but its stated 4:00 PM start and next-day 3:30 PM submission leave 23.5 hours. Use the explicit submission time and confirm organizer announcements. The PDF does not state a timezone; Africa/Nairobi is the local planning assumption, not a confirmed organizer rule.

## Reproduce the language audit

```powershell
npm.cmd run audit:jac
npm.cmd run check:hackathon
node tools/audit-jac.mjs --json
```

The first command reports the distribution. The second exits with failure if either repository-wide estimate falls below 80%. JSON includes the counted file inventory. It scans first-party source recursively, includes tests and tools, and excludes installed dependencies, compiled caches, generated artifacts and private runtime data. Documentation and configuration are not counted as application code. Byte and nonblank-line counts are estimates, not parser-based logical statement counts or an official eligibility ruling. Nonblank lines include comments, and formatting affects that estimate; neither metric should be gamed.

The audit also reports the application without `tests/`: **71.85% by bytes and 79.00% by nonblank lines**, still including styles and tooling. This separate view is informational; the gate evaluates all first-party repository source. If organizers exclude tests while retaining CSS, the byte-based application-only estimate does not meet 80%, so obtain their counting method before making a broader eligibility claim. Do not hide files, rename source extensions, add filler or count generated output to change the result.

## Implemented migration and evidence

- `web/app.cl.jac` is the canonical browser program. `client_build.jac` compiles it with Jac’s ECMAScript backend; Python serves the generated `.jac/client/app.js`. Generated output is not counted again.
- Jac now executes request/account orchestration, agent transport, dry-run tool workflows, typed provider requests, non-secret preferences, demo fixtures and the source audit. Python retains HTTP hosting, password hashing, sessions, encrypted account credentials, SQLite transactions and small validation helpers.
- Vehicle year/date/odometer validation, telemetry freshness and listing transitions are in `domain.jac`. `vehicle_agent.jac` remains the bounded orchestration loop and `vehicle_ai.jac` retains typed AI results.
- Backend and browser test cases are authored in Jac. Python and Node launchers remain thin compatibility entry points. Existing privacy, demo isolation, native model signatures and owned idempotent approvals are covered by the executable tests.
- The parallel Automotive Journal redesign is preserved. Its one-time maintenance script now executes as `tools/redesign_ui_workflow.jac`, through the existing Python command. It was type-checked without rerunning the destructive one-time migration against the redesigned interface.
- Verification: 17 server/tool Jac modules type-check, 37 backend tests pass, generated JavaScript passes syntax checks, and browser checks pass for the current Automotive Journal interface, including mobile layouts and theme controls. Provider tests use explicit fixtures; live Gemini inference was not verified.

The exact inventory is reproducible with the JSON audit command and is captured locally in `artifacts/jac-source-audit.json`. Source changes, including parallel redesign work, can change these percentages; rerun the gate against the exact submitted repository.

## Remaining submission actions

Preserve authentic event-window evidence, confirm team registration/check-in and the organizer’s counting method, then provide the GitHub URL, working-project video, actual pitch deck and timely Devpost submission. With a valid provider configuration, separately verify live retrieval, an exact-field proposal and one approved save in an isolated demo workspace. Do not expose credentials in the recording.

## Written submission description draft

Smartmoti helps vehicle owners keep a continuous record of acquisition, maintenance, repairs, inspections and fuel spending, then select which history to share when listing a vehicle for sale. The prototype connects private record keeping with a buyer-facing history summary while keeping notes, documents and vehicle identifiers private.

Jac supplies the application domain: `domain.jac` defines vehicle and event nodes, connects their histories through graph edges, retrieves passports through a walker, validates lifetime-record changes, calculates fuel economy between complete full-tank intervals, and controls marketplace workflows. The browser interface, request orchestration, agent transport and test cases are also authored in Jac. SQLite persists account workspaces through a local Python HTTP host.

The optional Gemini assistant uses a bounded loop in `vehicle_agent.jac` to choose authorized tools, retrieve account-scoped facts and prepare changes. Proposed writes require the owner's review and approval. Approval checks ownership and the workspace fingerprint and persists the result atomically and idempotently. `vehicle_ai.jac` defines typed history reviews and marketplace drafts; citations are checked against supplied records. Failed inference is reported rather than replaced with fabricated AI output.

The demo includes explicitly illustrative records and tracking. Live tracking, sensor fuel readings, buyer-account transfers and NFT minting are not implemented. NFT support currently prepares public-safe metadata only. Ordinary records and marketplace operations use the application database. Core vehicle workflows work without AI; successful live AI requires provider access and quota.

The repository currently fails the local byte threshold after parallel stylesheet additions; its nonblank-line share remains above 80%. The guide does not define its counting method; organizer confirmation, team eligibility, source URL, video, deck and Devpost submission still require completion.

## Pitch deck outline

1. **Vehicle history stays fragmented.** Explain the owner/buyer problem without unsupported market-size or fraud statistics.
2. **One vehicle passport joins its recorded history.** Show an actual passport screenshot and explain source labels, corrections and history gaps.
3. **The assistant retrieves facts and proposes reviewed changes.** Show the tool trail, exact fields and approval result from an actual run. Label live inference evidence separately from test mocks.
4. **Jac executes the vehicle graph and agent loop.** Show `domain.jac`, `vehicle_agent.jac`, `vehicle_ai.jac` and the host/persistence boundary. Report the actual source share.
5. **Fuel and resale use the same underlying records.** Show the deterministic 8.57 L/100 km sample interval and seller-selected public history; identify sample data.
6. **The prototype works locally, with explicit next steps.** Report verification, actual integration limits, team details and final repository/demo links. Avoid presenting future tracking or minting as working features.

The judging criteria on page 4 are technical execution/use of Jac and Jaseci, creativity and innovation, depth of agentic behaviour, impact and novelty, and clear presentation/demo video. Focus the presentation on working graph workflows, iterative tool use and reviewed persistence rather than optional NFT metadata.

## End to end agent evidence

`npm.cmd run test:agent-e2e -- --all-ui` starts an isolated temporary SQLite database and real local HTTP server. A real browser completes native tool chains for reviewed registration, inspection, two full fuel entries, deterministic fuel analysis and an append-only correction. It verifies conversation recovery, saved-passport navigation, rejection, stale approval and provider failure, then runs the complete interface suite. Only provider transport/configuration is mocked in this dedicated test harness; application APIs, the Jac agent loop, domain writes and SQLite approval transactions execute normally. This is not evidence of live Gemini inference. No shared provider key was configured during verification.

The Assistant now restores its latest account-owned conversation after reload/sign-in. Public display messages and current proposal statuses are projected separately from native model content; thought signatures remain server-only. New conversation does not delete earlier data. Earlier native-only sessions are preserved without silently continuing invisible context. Full archive selection remains outside this change.
