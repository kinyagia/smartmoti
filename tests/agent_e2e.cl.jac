"""Browser-to-SQLite agent workflows. No browser API interception or UI fixtures."""
import from "playwright-core" { chromium }
import from "node:assert/strict" { default as `assert }

glob base: any = process.env.SMARTMOTI_URL;
glob browser: any = await chromium.launch(
         {
             "executablePath": process.env.EDGE_PATH
             or "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
             "headless": True
         }
     );
glob context: any = await browser.newContext(
         {"viewport": {"width": 1440, "height": 1000}}
     );
glob page: any = await context.newPage();
glob errors: any = [];

async def state() -> any {
    response = await context.request.get(base + "/api/state");
    `assert.equal(response.status(), 200);
    return await response.json();
}

async def assistant() -> any {
    await page.getByRole("button", {"name": "Assistant", "exact": True}).click();
    await page.getByLabel("Message Smartmoti").waitFor();
}

async def ask(message: any) -> any {
    await page.getByLabel("Message Smartmoti").fill(message);
    await page.locator("form[data-form='agent']").getByRole(
        "button", {"name": "Ask Smartmoti"}
    ).click();
    await page.locator("form[data-form='agent']").getByRole(
        "button", {"name": "Ask Smartmoti", "exact": True}
    ).waitFor();
    await page.locator(".agent-working").waitFor({"state": "hidden"});
}

async def approve() -> any {
    await page.getByRole("button", {"name": "Approve and save"}).click();
    await page.locator(".proposal-card").last().locator(".tag").filter(
        {"hasText": "applied"}
    ).waitFor();
}

async def main() -> any {
    page.on("pageerror", lambda (error: any) -> any { errors.push(error.message); });
    signup = await context.request.post(
        base + "/api/signup",
        {
            "data": {
                "name": "Agent E2E owner",
                "email": "agent-e2e@test.invalid",
                "password": "test-password-123"
            }
        }
    );
    `assert.equal(signup.status(), 200);
    await page.goto(base);
    await assistant();
    await ask(
        "Register a Toyota Corolla, year 2020, registration KAA 700A, starting odometer 1000 km."
    );
    await page.getByRole("button", {"name": "Approve and save"}).waitFor();
    `assert.equal(
        (await state()).vehicles.length, 0, "Preparing registration must not write"
    );
    await page.reload();
    await assistant();
    await page.getByRole("button", {"name": "Approve and save"}).waitFor();
    await approve();
    garage = await state();
    `assert.equal(garage.vehicles.length, 1);
    vehicleId = garage.vehicles[0].id;
    await page.reload();
    await assistant();
    `assert.equal(
        await page.getByRole("button", {"name": "Approve and save"}).count(), 0
    );
    `assert.equal(
        await page.getByLabel("Focus this conversation").inputValue(), vehicleId
    );

    await ask(
        "Record an inspection for my Toyota Corolla today at 1100 km titled E2E inspection."
    );
    await page.getByRole("button", {"name": "Approve and save"}).waitFor();
    `assert.equal((await state()).vehicles[0].records.length, 0);
    await approve();
    `assert.equal((await state()).vehicles[0].records[0].title, "E2E inspection");

    await ask(
        "Log a full tank today at 1200 km: 40 litres costing KES 7400, titled E2E first full tank."
    );
    await page.getByRole("button", {"name": "Approve and save"}).waitFor();
    await approve();
    await ask(
        "Log a full tank today at 1400 km: 20 litres costing KES 3700, titled E2E second full tank."
    );
    await page.getByRole("button", {"name": "Approve and save"}).waitFor();
    await approve();
    `assert.equal((await state()).vehicles[0].fuel_summary.latest_economy, 10);
    await ask("Explain the recorded fuel economy and cost per kilometre.");
    await page.getByText(
        "Test provider fixture: Jac reports 10.0 L/100 km and 18.5 KES/km.",
        {"exact": True}
    ).waitFor();

    await ask(
        "Correct the inspection title to E2E inspection corrected; keep today and 1100 km."
    );
    await page.getByRole("button", {"name": "Approve and save"}).waitFor();
    await approve();
    garage = await state();
    original = garage.vehicles[0].records.find(
        lambda (record: any) -> any { return record.title == "E2E inspection"; }
    );
    corrected = garage.vehicles[0].records.find(
        lambda (record: any) -> any { return record.title == "E2E inspection corrected"; }
    );
    `assert.equal(original.superseded_by, corrected.id);
    await page.getByRole(
        "button", {"name": "View saved vehicle passport"}
    ).last().click();
    await page.getByRole(
        "heading", {"name": "E2E inspection corrected", "exact": True}
    ).waitFor();
    await assistant();

    await ask(
        "Record an inspection for my Toyota Corolla today at 1100 km titled E2E inspection."
    );
    await page.getByRole("button", {"name": "Approve and save"}).waitFor();
    await page.getByRole("button", {"name": "Discard proposal"}).click();
    await page.locator(".proposal-card").last().locator(".tag").filter(
        {"hasText": "rejected"}
    ).waitFor();
    `assert.equal((await state()).vehicles[0].records.length, 4);

    await ask("Record an inspection for my Toyota Corolla today at 1100 km titled E2E inspection.");
    await page.getByRole("button", {"name": "Approve and save"}).waitFor();
    manual = await context.request.post(base + "/api/workflow", {"data": {"action": "add_record", "payload": {"vehicle_id": vehicleId, "type": "inspection", "date": corrected.date, "odometer": 1500, "title": "E2E concurrent manual change"}}});
    `assert.equal(manual.status(), 200);
    await page.getByRole("button", {"name": "Approve and save"}).click();
    await page.locator(".proposal-card").last().locator(".tag").filter({"hasText": "stale"}).waitFor();
    `assert.equal((await state()).vehicles[0].records.length, 5);

    before = JSON.stringify((await state()).vehicles);
    await ask("Exercise the test provider failure");
    await page.getByText(
        "Gemini quota or rate limit reached. No changes were saved.", {"exact": True}
    ).waitFor();
    `assert.equal(JSON.stringify((await state()).vehicles), before);

    await page.reload();
    await assistant();
    await page.getByRole(
        "button", {"name": "View saved vehicle passport"}
    ).last().waitFor();
    await page.getByRole("button", {"name": "New conversation", "exact": True}).click();
    await page.reload();
    await assistant();
    `assert.equal(await page.locator(".proposal-card").count(), 0);
    `assert.deepEqual(errors, []);
    console.log(
        "Agent E2E passed: native tool chains, reviewed registration/inspection/fuel/correction, Jac fuel calculation, persisted conversation and proposal statuses, rejection, stale approval and provider failure. Model transport is an explicit test fixture; HTTP/Jac/SQLite/browser are real."
    );
}

with entry {
    try {
        await main();
    } finally {
        await browser.close();
    }
}
