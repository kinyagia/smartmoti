# Smartmoti showcase walkthrough

Open **http://127.0.0.1:8000/demo** on this computer. It opens an isolated sample garage and a seven-step presentation guide. **Next chapter** moves through the guide. Close it for an unobstructed view; **Presentation guide** opens it again. **Fresh demo** creates a new sample workspace.

Before live AI, open **Settings -> AI, on your terms**, save a personal Gemini key and model, and choose **Test connection**. The shared server key can also be configured through `configure_ai.py`. The server reads it without restarting. A valid key and available model quota are required. If setup is missing, show the Assistant interface and explain the workflow; do not present a sample response as a live model result.

## A five minute presentation

| Time | Screen | Demonstration |
| --- | --- | --- |
| 0:00-0:30 | Landing and My garage | A lifetime story supported by fuel, tracking and resale. Three sample vehicles. |
| 0:30-1:15 | Hilux passport | Acquisition, services, inspection, historical ownership and private sample PDFs. |
| 1:15-2:30 | Assistant | Retrieve fuel data, show the tool trail, prepare an inspection, review its exact fields and approve. |
| 2:30-3:00 | Fuel and costs | Explain 8.57 L/100 km and KES 15.86/km for the latest complete interval. |
| 3:00-3:30 | Tracking | Illustrative Nairobi to Naivasha route; live provider integration remains a later phase. |
| 3:30-4:30 | Marketplace | Mazda listing, three selected history entries and illustrative buyer enquiry. Gemini drafts use selected history. |
| 4:30-5:00 | NFT metadata and Jac | Preview make/model/year metadata. Explain optional minting and Jac's workflows and agent loop. |

## Opening pitch

"Smartmoti gives a vehicle one continuous story. Ownership chapters, services, repairs and fuel records stay together. Owners choose what a buyer can see. The Assistant retrieves current facts and prepares updates that owners review before saving. Jac powers the vehicle graph, workflows and agent loop; blockchain is reserved for optional NFT minting."

## The agentic AI demonstration

From the Hilux passport, choose **Explore this vehicle with Smartmoti**. **Ask Smartmoti** in the top bar and **Assistant** navigation offer the same workspace. Keep **Toyota Hilux** selected in the context panel.

1. Ask: **"What is the Hilux's latest fuel economy and cost per kilometre?"** Gemini chooses the fuel tool. Jac calculates from stored fills. Expand **Data and actions used** to show what ran. The sample result should explain 8.57 L/100 km and KES 15.86/km, with the limits of the ledger.
2. Ask: **"Record an inspection for the Hilux today at 44,700 km titled Showcase inspection."** Review type, title, local date, odometer and owner-reported source. Nothing has been saved yet.
3. Choose **Approve and save**. Return to **Vehicle passport** to show the new entry. Refresh to demonstrate persistence. It remains unverified, like a manual owner-reported entry.
4. Explain **Discard proposal**, clarification for missing facts, and stale-data checks. If the garage changes after preparation, Smartmoti requires a fresh proposal. Repeated approval cannot create duplicates.

5. Refresh, reopen **Assistant**, and show that the conversation, tool trail and applied status return. Choose **View saved vehicle passport** on the proposal to inspect the actual saved record. **New conversation** starts a fresh thread without deleting earlier records.

For a longer lifecycle demonstration, start in an empty personal workspace, provide the vehicle registration/make/model/year/starting odometer, and approve its registration. The Assistant focuses the newly saved vehicle. Supply actual inspection or fuel details in follow-up messages, approve each change, then ask for the recorded fuel economy. Two complete full-tank checkpoints are required for an economy calculation. Corrections retain the original record. These flows require live provider access; `npm.cmd run test:agent-e2e` exercises the complete browser/API/Jac/database path using an explicitly test-only model transport.

Optional questions: **"Find vehicles with reported incidents or repairs."**, **"Summarize this vehicle's recorded history and gaps."**, and **"Show my active marketplace listings."** The assistant retrieves histories from this account's garage. **Detailed history review** provides a structured overview with record citations.

For fuel, explicitly supply date, actual odometer, litres, amount, currency and full/partial tank status. Example: **"Prepare a full-tank fuel entry for the Hilux today at 45,100 km: 60 litres costing KES 11,100, titled Showcase refuel."** Review before approving.

The Assistant cannot delete history, send messages, make payments, control a vehicle or mint an NFT. Stored private notes, documents, VIN, registration and GPS are excluded from retrieved model context. A registration you supply for a new vehicle may appear in its local review card. Corrections involving private notes or documents use the manual form to preserve those details.

## Sample vehicles

- **Toyota Hilux, KDK 482A:** acquisition, servicing, inspection, historical ownership, fuel fills, private sample PDFs and illustrative trip. Main presentation vehicle.
- **Isuzu D-Max, KCY 716B:** clutch repair, reported cosmetic incident, follow-up repair and inspection. Useful for intelligent history search.
- **Mazda CX-5, KDG 903C:** KES 3,250,000 listing, three shared history entries and illustrative KES 3,100,000 enquiry.

## Fuel calculation

A full-tank checkpoint at 43,000 km is followed by a 20-litre partial fill at 43,300 km and a 40-litre full fill at 43,700 km. That is 60 litres over 700 km: **8.57 L/100 km**. The following interval also uses 60 litres over 700 km. At KES 185/litre, its cost is **KES 15.86/km**. The starting fill counts in total spending but not consumption for the following interval. GPS alone does not measure fuel usage.

## Describe the integration state accurately

Sample records, receipts, offers and tracking observations are illustrative. The route diagram is schematic. No real GPS feed, sensor measurement, external message, payment or actual sale is involved.

The demo executes Jac nodes, a passport walker, deterministic workflows and bounded agent orchestration in `vehicle_agent.jac`. SQLite persists workspaces, private documents, conversations and proposal results. Core workflows work without Gemini; live AI requires an available provider.

Metadata preparation does not mint an NFT. Live minting needs a contract and wallet. Automatic buyer account transfer and organization roles remain future work. Localhost works on this computer; remote audiences need screen sharing or a configured deployment.

For a settings demonstration, show the profile, preferred fuel currency, personal-key form, connection check and AI pause toggle. Use a personal account to preserve settings between demos. Password changes close other signed-in sessions. Saved keys are never displayed back in the form.
