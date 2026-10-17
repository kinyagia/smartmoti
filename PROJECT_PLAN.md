# Smartmoti vehicle lifecycle and implementation plan

Smartmoti will maintain a vehicle's lifetime record, supported by tracking, fuel management, and a vehicle marketplace. Jac will implement the vehicle graph and application workflows. AI is optional and secondary. Blockchain is limited to optional vehicle NFT minting. Records, ownership updates, and marketplace operations remain in the application database.

## Product priorities

The local foundation is implemented. See [README.md](README.md) for launch instructions, verification, and integration limits. It includes the landing page, accounts, vehicle passports, corrections, private documents, fuel calculations, marketplace listings and offers, and NFT metadata preparation. Live tracking, actual minting, organization roles, and buyer account transfers remain later phases.

The user also requested AI support. The implementation now includes optional Gemini history reviews and editable marketplace drafts through typed Jac functions and structured Gemini responses. These augment the records; deterministic fuel calculations and record validation remain independent of AI. Provider credentials and a successful inference are required before presenting generated results.

| Priority | Capability | Purpose |
| --- | --- | --- |
| 1 | Vehicle lifetime record | Identity, ownership history, mileage, maintenance, repairs, incidents, inspections, and documents |
| 2 | Tracking | Location, last update, recorded trips, mileage, and geofence alerts |
| 3 | Fuel management | Refuelling, costs, consumption summaries, and later compatible sensor integration |
| 4 | Marketplace | Vehicle listings, shared history summaries, enquiries, offers, and sale records |
| 5 | Optional NFT minting | Mint a vehicle NFT and attach its confirmed token reference |

Support individual owners and organizations through a shared vehicle model. The exact launch audience remains open. Vehicles do not need trackers or NFTs to have records or listings.

## Vehicle lifetime record

Use a stable internal vehicle ID, with VIN where available, registration, make, model, year, and photos. A chronological timeline records acquisition, ownership periods, odometer readings, services, repairs, parts replacement, inspections, incidents, insurance documents, refuelling, and disposal or retirement.

Each event includes its occurrence date, entry date, author, source, supporting documents, and odometer reading when relevant. Distinguish owner reports, workshop submissions, tracker observations, and reviewed records. A stored entry is not automatically verified. Display the history coverage period and gaps rather than implying a complete lifespan before records exist.

Corrections retain the original event and identify the replacement. Confirmed handovers preserve history while changing access. Buyers see a seller-approved summary; precise tracking history, personal information, and sensitive documents stay private.

Maintenance reminders use date and mileage intervals. AI diagnosis, chat assistants, predictive maintenance, and weather advice are optional later features.

## Tracking and fuel

Reuse Omni's Protrack and IOPGPS adapters as integration candidates. Store provider, device assignment, observation and ingestion times, freshness, and live or simulated status. Show stale or offline readings explicitly. Build trip history from recorded telemetry. Replacing a tracker must not create a new vehicle identity. Keep device assignment history and review conflicting odometers.

Start fuel management with a ledger: vehicle, refuelling date, odometer, litres, total cost, currency, full-tank status, station, receipt, and submitter. Between consecutive full-tank checkpoints, calculate litres per 100 kilometres from all fuel added after the earlier checkpoint through the later one, divided by distance and multiplied by 100. Match fuel costs to the same distance interval for cost per kilometre. Keep currencies separate. Incomplete records or invalid distances produce an unavailable result.

GPS distance alone does not measure fuel consumed. Live fuel levels require compatible hardware and provider fields. Inspect device capabilities and sample payloads before promising measured consumption or fuel-loss alerts. Sudden level changes require validation and do not by themselves establish theft.

Omni's inspected telemetry model lacks measured fuel readings; report endpoints generate mock fuel values when records are absent. The fuel ledger is a new core feature. Move synthetic values into explicit demo fixtures.

## Marketplace

Reuse Neurocar's listing and offer interface concepts. Link listings to internal vehicle IDs independent of NFT token IDs. Include photos, price and currency, mileage, description, seller details, seller-chosen location detail, and an approved history summary.

Support draft, active, reserved, sold, and withdrawn states, plus enquiries and offers. Accepted offers do not automatically change ownership. Confirm a completed handover before changing access and recording the ownership event. Begin with listings, enquiries, offers, and sale records; integrated payments can follow separately. Marketplace operations do not use smart contracts or cryptocurrency settlement.

## NFT minting boundary

Offer minting as an optional vehicle-profile action. Blockchain interaction covers mint submission and confirmation. Store chain ID, contract address, token ID, transaction hash, and status. Failed or pending minting must not block ordinary records or listings.

Mint a selected metadata snapshot containing non-sensitive vehicle details. Keep personal information, private documents, and precise tracking history out of public metadata. Subsequent maintenance and ownership updates occur in the application and do not trigger blockchain writes. The minted snapshot represents its creation time.

Minting does not establish legal ownership or prove historical entries are true. Application ownership follows the confirmed handover workflow. NFT trading, token transfers as a sale mechanism, on-chain maintenance, insurance pools, and blockchain marketplace settlement are outside scope.

Review Neurocar's CarNFT mint permissions and dependencies before adapting it or creating a smaller mint-only contract. Exclude its marketplace and insurance contracts from the core application.

## Jac architecture and reuse

Use Jac nodes and walkers for ordinary vehicle workflows; the graph does not require AI. Jac's [core concepts](https://www.jac-lang.org/quick-guide/what-makes-jac-different/) describe nodes, edges, traversal, and persistence.

```text
Web interface
      |
Authenticated Jac workflows
      |
      +-- Vehicle timeline and ownership access
      +-- Maintenance and fuel ledger
      +-- Marketplace listings and offers
      +-- Omni telemetry integration
      +-- Document storage
      +-- Optional NFT minting adapter
```

Jac owns canonical vehicle identities, lifetime events, access relationships, fuel entries, and marketplace records. Initially retain Omni's Django service for tracker integration and telemetry storage. Map Omni IDs to Smartmoti IDs through a defined API and prevent independently editable identity registries. Reuse selected Next.js components and evaluate Jac client tooling during the runtime spike. Pin Jac before choosing persistence and authentication integration details.

Core nodes include Account, Organization, User, Vehicle, OwnershipPeriod, DriverAssignment, DeviceAssignment, TimelineEvent, MaintenanceRecord, OdometerReading, FuelEntry, Document, Listing, Enquiry, Offer, and MintRecord. Enforce access in every workflow; graph connectivity alone is not authorization. Keep high-volume telemetry history in the operational store.

Walkers register vehicles, add and correct events, retrieve authorized timelines, review service deadlines, record fuel, calculate summaries, manage listings and offers, confirm handovers, and reconcile minting. Deterministic validation handles dates, units, odometers, permissions, and state transitions. No LLM is required.

Reuse Omni's maps, vehicle lists, provider adapters, alerts, and geofences; reuse Neurocar's maintenance, document, listing, and offer concepts. Adapt its token-based identity and wallet dependencies. Mobile follows the shared API. Keep AI diagnosis, decentralized insurance, blockchain marketplace, and weather assistants outside the initial implementation.

## Source issues to resolve

1. Omni simulates movement for named demo accounts and creates synthetic mileage and fuel reports on missing data. Use explicit fixtures and source labels; live reports must not fabricate history.
2. Omni's map includes simulated trails. Use recorded positions for actual trip history.
3. Neurocar's vehicle detail services use token_id as a lookup key. Use an internal vehicle ID with optional NFT references.
4. Neurocar permits a Supabase service key under a NEXT_PUBLIC variable name. Keep privileged keys exclusively on the server and use browser-safe keys with access policies.
5. Omni stores provider credentials as plaintext for its MVP. Introduce protected credential storage before real onboarding.
6. Neurocar's checked-in Hardhat test targets MockNFTMarketplace rather than the listed vehicle contracts. Validate the selected mint contract with relevant tests.
7. Omni's cutoff handler lacks missing or stale telemetry checks and can report success without a provider account. Remote immobilization is outside the initial tracking scope.

These are source findings; runtime behavior, live provider connectivity, and deployed contract behavior remain to be verified.

## Implementation sequence

1. **Vehicle passport and Jac foundation.** Pin the runtime, implement login and access, vehicle identity, timeline events, and documents. Verify persistence after restart and access isolation.
2. **Maintenance and ownership.** Add services, odometer validation, corrections, reminders, and confirmed handovers. Verify preserved history and correct private access after handover.
3. **Tracking.** Connect one read-only provider, then the second. Verify fresh, stale, offline, and simulated states, tracker reassignment, and recorded trips.
4. **Fuel ledger.** Add refuelling, receipts, costs, and valid full-tank calculations. Verify partial fills, missing records, invalid odometers, and currency separation.
5. **Marketplace.** Add controlled history sharing, listings, enquiries, offers, and confirmed sale records. Verify edit permissions and prevent private data appearing publicly.
6. **NFT minting.** Add the isolated adapter and metadata snapshot on a test network first. Verify permissions, failures, confirmation, and duplicate-request reconciliation.
7. **Demonstration and expansion.** Demonstrate the complete lifecycle. Add mobile or measured fuel integration after validating capabilities. Consider AI only for an identified need.

## First demonstration

Register a vehicle, record acquisition and services, connect tracking, add a valid refuelling sequence, and display fuel costs and economy. Publish a listing with selected history, receive an offer, and record a confirmed handover. Demonstrate NFT minting as a separate optional action.

The supplied **AI Hackathon (Kenya) - Hacker Guide.pdf** is the reference for the October 16–17 Kenya event. It requires at least 80% Jac code and coding during the event. The source-share gate counts all first-party application source, styles, tests and tools. Parallel stylesheet additions currently leave the byte threshold below 80%, while the line share remains above it. See [HACKATHON.md](HACKATHON.md) for the counting method and remaining submission requirements. The Spring event is not the rule source for this submission.
