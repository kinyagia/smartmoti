"""Smartmoti client program, authored and compiled in Jac."""
import from "playwright-core" { chromium }

import from "node:fs/promises" { mkdir }

import from "node:assert/strict" { default as `assert }

glob base: any = process.env.SMARTMOTI_URL or "http://127.0.0.1:8000";

glob executablePath: any = (
         process.env.EDGE_PATH
         or "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
     );

with entry {
    (await mkdir("artifacts", {"recursive": True}));
}

glob browser: any = (
         await chromium.launch({"executablePath": executablePath, "headless": True})
     );

glob context: any = (
         await browser.newContext({"viewport": {"width": 1440, "height": 1000}})
     );

glob page: any = await context.newPage();

glob errors: any = [];

with entry {
    page.on(
        "pageerror", lambda (error: any) -> any { return errors.push(error.message); }
    );
}

with entry {
    try {
        (await page.goto(base));
        (
            await page.getByRole(
                "heading", {"name": "Your vehicle. Every chapter."}
            ).waitFor()
        );
        (await premiumLandingChecks());
        (
            await page.screenshot(
                {"path": "artifacts/landing-desktop.png", "fullPage": True}
            )
        );
        (
            await page.screenshot(
                {"path": "artifacts/landing-preview.png", "fullPage": False}
            )
        );
        (await page.getByRole("button", {"name": "Explore the demo"}).click());
        (
            await page.getByRole(
                "heading", {"name": "Your garage. Stories in motion."}
            ).waitFor()
        );
        (
            await page.screenshot(
                {"path": "artifacts/garage-desktop.png", "fullPage": True}
            )
        );
        (await navigate("Vehicle passport"));
        (
            await page.getByRole(
                "heading", {"name": "Every chapter, together."}
            ).waitFor()
        );
        (await page.getByRole("button", {"name": "Add record", "exact": True}).click());
        (await page.getByLabel("Record title").fill("UI verified inspection"));
        (await page.getByLabel("Record date").fill("2026-09-21"));
        (await page.getByLabel("Odometer (km)").fill("44100"));
        (await page.getByRole("button", {"name": "Save record"}).click());
        (await page.getByRole("heading", {"name": "UI verified inspection"}).waitFor());
        (await page.reload());
        (await navigate("Vehicle passport"));
        (await page.getByRole("heading", {"name": "UI verified inspection"}).waitFor());
        (
            await page.screenshot(
                {"path": "artifacts/passport-desktop.png", "fullPage": True}
            )
        );
        (await navigate("Fuel & costs"));
        (await page.getByRole("heading", {"name": "Every fill adds up."}).waitFor());
        `assert.`match(
            (
                await page.locator(".stat-value").allTextContents().then(
                    lambda (values: any) -> any { return values.join(" "); }
                )
            ),
            new(RegExp, "8.57", "")
        );
        (
            await page.screenshot(
                {"path": "artifacts/fuel-desktop.png", "fullPage": True}
            )
        );
        (await navigate("Marketplace"));
        (await page.getByRole("button", {"name": "View details"}).click());
        (
            await page.getByRole("dialog").getByRole(
                "heading", {"name": "Mazda CX-5", "exact": True}
            ).waitFor()
        );
        (await page.getByRole("button", {"name": "Close dialog"}).click());
        (
            await page.screenshot(
                {"path": "artifacts/marketplace-desktop.png", "fullPage": True}
            )
        );
        (await page.setViewportSize({"width": 390, "height": 844}));
        (await navigate("My garage"));
        (
            await page.screenshot(
                {"path": "artifacts/garage-mobile.png", "fullPage": True}
            )
        );
        `assert.equal(
            (
                await page.evaluate(
                    lambda() -> any { return (
                        document.documentElement.scrollWidth > innerWidth
                    ); }
                )
            ),
            False,
            "Mobile dashboard should not overflow"
        );
        (await context.clearCookies());
        (await page.goto(base));
        (
            await page.getByRole(
                "heading", {"name": "Your vehicle. Every chapter."}
            ).waitFor()
        );
        (
            await page.screenshot(
                {"path": "artifacts/landing-mobile.png", "fullPage": True}
            )
        );
        `assert.equal(
            (
                await page.evaluate(
                    lambda() -> any { return (
                        document.documentElement.scrollWidth > innerWidth
                    ); }
                )
            ),
            False,
            "Mobile landing should not overflow"
        );
        (await page.setViewportSize({"width": 1440, "height": 1000}));
        (await page.goto((base + "/demo")));
        (
            await page.getByRole(
                "heading", {"name": "One garage. Three vehicle stories."}
            ).waitFor()
        );
        (await page.getByRole("button", {"name": "Next chapter"}).click());
        (
            await page.getByRole(
                "heading", {"name": "Follow the Hilux through its lifetime."}
            ).waitFor()
        );
        (await page.getByRole("button", {"name": "Next chapter"}).click());
        (
            await page.getByRole(
                "heading", {"name": "Ask for data. Propose an update."}
            ).waitFor()
        );
        (
            await page.getByRole(
                "heading", {"name": "A little help. A clearer garage."}
            ).waitFor()
        );
        if (not (await page.request.get((base + "/api/ai/status"))).ok()) {
            raise new(Error, "AI status endpoint is unavailable");
        }
        (await page.getByRole("button", {"name": "Next chapter"}).click());
        (
            await page.getByRole(
                "heading", {"name": "Explain the cost of each kilometre."}
            ).waitFor()
        );
        (await page.getByRole("button", {"name": "Next chapter"}).click());
        (await page.getByRole("heading", {"name": "Sample trip summary"}).waitFor());
        (
            await page.screenshot(
                {"path": "artifacts/showcase-tracking.png", "fullPage": True}
            )
        );
        (await page.getByRole("button", {"name": "Next chapter"}).click());
        (
            await page.getByRole(
                "heading", {"name": "Share a clearer history with a buyer."}
            ).waitFor()
        );
        (
            await page.getByText(
                "Illustrative buyer enquiry:", {"exact": False}
            ).waitFor()
        );
        (await page.getByRole("button", {"name": "Next chapter"}).click());
        (
            await page.getByRole(
                "heading", {"name": "Keep blockchain to optional minting."}
            ).waitFor()
        );
        (await page.getByRole("button", {"name": "Preview mint metadata"}).click());
        (
            await page.getByRole(
                "heading", {"name": "A snapshot, ready to review."}
            ).waitFor()
        );
        (await page.getByRole("button", {"name": "Close dialog"}).click());
        (await page.getByRole("button", {"name": "Finish", "exact": True}).click());
        (
            await page.getByRole(
                "button", {"name": "Presentation guide", "exact": True}
            ).click()
        );
        (
            await page.getByRole(
                "heading", {"name": "One garage. Three vehicle stories."}
            ).waitFor()
        );
        (
            await Promise.all(
                [
                    page.waitForResponse(
                        lambda (response: any) -> any { return (
                            response.url().endsWith("/api/state") and response.ok()
                        ); }
                    ),
                    page.getByRole(
                        "button", {"name": "Fresh demo", "exact": True}
                    ).click()
                ]
            )
        );
        (
            await page.getByRole(
                "heading", {"name": "One garage. Three vehicle stories."}
            ).waitFor()
        );
        (await page.setViewportSize({"width": 390, "height": 844}));
        `assert.equal(
            (
                await page.evaluate(
                    lambda() -> any { return (
                        document.documentElement.scrollWidth > innerWidth
                    ); }
                )
            ),
            False,
            "Showcase should not overflow on mobile"
        );
        (await navigate("Assistant"));
        (
            await page.getByRole(
                "heading", {"name": "A little help. A clearer garage."}
            ).waitFor()
        );
        (
            await page.screenshot(
                {"path": "artifacts/assistant-mobile.png", "fullPage": True}
            )
        );
        `assert.equal(
            (
                await page.evaluate(
                    lambda() -> any { return (
                        document.documentElement.scrollWidth > innerWidth
                    ); }
                )
            ),
            False,
            "Assistant should not overflow on mobile"
        );
        (await page.setViewportSize({"width": 1440, "height": 1000}));
        (
            await page.screenshot(
                {"path": "artifacts/assistant-desktop.png", "fullPage": True}
            )
        );
        (await page.route("**/api/state", _asyncHandler1));
        (await page.route("**/api/agent/chat", _asyncHandler2));
        (await page.route("**/api/agent/approve", _asyncHandler3));
        (await page.reload());
        (await navigate("Assistant"));
        (
            await page.getByRole(
                "heading", {"name": "A little help. A clearer garage."}
            ).waitFor()
        );
        (
            await page.getByLabel("Message Smartmoti").fill(
                "Record an inspection today at 44700 km called Test inspection"
            )
        );
        (
            await page.locator("form[data-form=\"agent\"]").getByRole(
                "button", {"name": "Ask Smartmoti"}
            ).click()
        );
        (
            await page.getByText(
                "UI test fixture: the inspection is prepared and awaits your approval.",
                {"exact": True}
            ).waitFor()
        );
        (await page.getByText("2 steps", {"exact": False}).click());
        (
            await page.screenshot(
                {"path": "artifacts/assistant-proposal-test.png", "fullPage": True}
            )
        );
        (await page.getByRole("button", {"name": "Approve and save"}).click());
        (
            await page.locator(".proposal-card .tag").filter(
                {"hasText": "applied"}
            ).waitFor()
        );
        `assert.equal(
            (await page.getByRole("button", {"name": "Approve and save"}).count()), 0
        );
        (await page.setViewportSize({"width": 390, "height": 844}));
        `assert.equal(
            (
                await page.evaluate(
                    lambda() -> any { return (
                        document.documentElement.scrollWidth > innerWidth
                    ); }
                )
            ),
            False,
            "Assistant conversation should not overflow on mobile"
        );
        (await page.unroute("**/api/state"));
        (await navigate("Settings"));
        (await page.getByRole("heading", {"name": "Make it yours."}).waitFor());
        `assert.equal(
            (
                await page.evaluate(
                    lambda() -> any { return (
                        document.documentElement.scrollWidth > innerWidth
                    ); }
                )
            ),
            False,
            "Settings should not overflow on mobile"
        );
        (
            await page.screenshot(
                {"path": "artifacts/settings-mobile.png", "fullPage": True}
            )
        );
        (await page.setViewportSize({"width": 1440, "height": 1000}));
        (
            await page.screenshot(
                {"path": "artifacts/settings-desktop.png", "fullPage": True}
            )
        );
        profile = page.locator("form[data-form=\"settings-profile\"]");
        (await profile.getByLabel("Display name").fill("Showcase owner"));
        (await profile.getByRole("button", {"name": "Save profile"}).click());
        (
            await page.locator(".settings-summary h2").filter(
                {"hasText": "Showcase owner"}
            ).waitFor()
        );
        preferences = page.locator("form[data-form=\"settings-preferences\"]");
        (await preferences.getByLabel("Default fuel currency").selectOption("USD"));
        (
            await Promise.all(
                [
                    page.waitForResponse(
                        lambda (response: any) -> any { return (
                            response.url().endsWith("/api/state") and response.ok()
                        ); }
                    ),
                    preferences.getByRole(
                        "button", {"name": "Save preferences"}
                    ).click()
                ]
            )
        );
        (await page.reload());
        (await navigate("Settings"));
        `assert.equal(
            (await page.getByLabel("Default fuel currency").inputValue()), "USD"
        );
        aiForm = page.locator("form[data-form=\"settings-ai\"]");
        (
            await aiForm.getByLabel("Gemini API key", {"exact": True}).fill(
                "ui-test-only-key"
            )
        );
        (
            await aiForm.getByLabel(
                "Use the server key when I have no personal key"
            ).uncheck()
        );
        (await aiForm.getByRole("button", {"name": "Save AI settings"}).click());
        (await page.getByText("Personal key saved", {"exact": True}).waitFor());
        `assert.equal(
            (await page.getByLabel("Replace Gemini API key").inputValue()), ""
        );
        `assert.doesNotMatch(
            (await page.content()), new(RegExp, "ui-test-only-key", "")
        );
        (await page.getByRole("button", {"name": "Remove personal key"}).click());
        (await page.getByText("Key needed", {"exact": True}).waitFor());
        (await navigate("Fuel & costs"));
        (
            await page.getByRole(
                "button", {"name": "Log refuelling", "exact": True}
            ).click()
        );
        `assert.equal(
            (
                await page.getByRole("dialog").getByLabel(
                    "Currency", {"exact": True}
                ).inputValue()
            ),
            "USD"
        );
        (await page.getByRole("button", {"name": "Close dialog"}).click());
        personalContext = (
            await browser.newContext({"viewport": {"width": 1440, "height": 1000}})
        );
        accountEmail = "ui-settings-" + String(Date.now()) + "@test.invalid";
        signup = (
            await personalContext.request.post(
                (base + "/api/signup"),
                {
                    "data": {
                        "name": "Settings test account",
                        "email": accountEmail,
                        "password": "test-password-123"
                    }
                }
            )
        );
        `assert.equal(signup.status(), 200);
        personalPage = await personalContext.newPage();
        personalPage.on(
            "pageerror",
            lambda (error: any) -> any { return errors.push(error.message); }
        );
        (await personalPage.goto(base));
        (
            await personalPage.getByRole(
                "button", {"name": "Settings", "exact": True}
            ).click()
        );
        (
            await personalPage.getByRole(
                "heading", {"name": "Account security", "exact": True}
            ).waitFor()
        );
        security = personalPage.locator("form[data-form=\"settings-password\"]");
        (
            await security.getByLabel("Current password", {"exact": True}).fill(
                "test-password-123"
            )
        );
        (
            await security.getByLabel("New password", {"exact": True}).fill(
                "new-password-123"
            )
        );
        (
            await security.getByLabel("Confirm new password", {"exact": True}).fill(
                "different-password"
            )
        );
        (await security.getByRole("button", {"name": "Update password"}).click());
        (
            await security.getByText(
                "The new passwords do not match.", {"exact": True}
            ).waitFor()
        );
        (
            await security.getByLabel("Confirm new password", {"exact": True}).fill(
                "new-password-123"
            )
        );
        (
            await Promise.all(
                [
                    personalPage.waitForResponse(
                        lambda (response: any) -> any { return (
                            response.url().endsWith("/api/state") and response.ok()
                        ); }
                    ),
                    security.getByRole("button", {"name": "Update password"}).click()
                ]
            )
        );
        (await personalPage.reload());
        (
            await personalPage.getByRole(
                "button", {"name": "Settings", "exact": True}
            ).click()
        );
        (
            await personalPage.screenshot(
                {"path": "artifacts/settings-account-desktop.png", "fullPage": True}
            )
        );
        (await personalPage.getByLabel("Opening page").selectOption("assistant"));
        (
            await Promise.all(
                [
                    personalPage.waitForResponse(
                        lambda (response: any) -> any { return (
                            response.url().endsWith("/api/state") and response.ok()
                        ); }
                    ),
                    personalPage.getByRole(
                        "button", {"name": "Save preferences"}
                    ).click()
                ]
            )
        );
        (await personalPage.goto(base));
        (
            await personalPage.getByRole(
                "heading", {"name": "A little help. A clearer garage."}
            ).waitFor()
        );
        (await personalContext.close());
        (await journalChecks());
        (await issueChecks());
        `assert.deepEqual(errors, []);
        console.log(
            "UI checks passed: landing, timeline persistence, fuel, marketplace, mobile layout and seven-step showcase, settings persistence, personal-key handling, currency defaults and password management."
        );
    } finally {
        (await browser.close());
    }
}

async def _asyncHandler1(route: any) -> any {
    response = await route.fetch();
    body = await response.json();
    body.ai.available = True;
    body.ai.configured = True;
    (await route.fulfill({"response": response, "json": body}));
}

async def _asyncHandler2(route: any) -> any {
    return route.fulfill(
        {
            "json": {
                "session_id": "ui-test-session",
                "answer": "UI test fixture: the inspection is prepared and awaits your approval.",
                "trace": [
                    {
                        "tool": "get_vehicle_history",
                        "label": "Read Toyota Hilux history",
                        "status": "read"
                    },
                    {
                        "tool": "propose_add_record",
                        "label": "Prepared inspection for review",
                        "status": "prepared"
                    }
                ],
                "proposals": [
                    {
                        "id": "ui-test-proposal",
                        "summary": "Record Test inspection",
                        "tool": "propose_add_record",
                        "status": "pending",
                        "preview": {
                            "type": "inspection",
                            "title": "Test inspection",
                            "date": "2026-10-13",
                            "odometer": 44700,
                            "source": "Owner reported"
                        }
                    }
                ]
            }
        }
    );
}

async def _asyncHandler3(route: any) -> any {
    return route.fulfill({"json": {"status": "applied"}});
}


async def journalChecks() -> any {
    (await navigate("My garage"));
    (await page.locator(".garage-feature").waitFor());
    (await page.getByLabel("Select vehicle", {"exact": True}).selectOption({"index": 1}));
    `assert.match((await page.locator(".feature-identity h2").textContent()), new(RegExp, "Isuzu", ""));
    (await navigate("Tracking"));
    (await page.getByText("No live tracker is connected to this local workspace.", {"exact": False}).waitFor());
    (await navigate("My garage"));
    (await page.getByLabel("Select vehicle", {"exact": True}).selectOption({"index": 0}));
    (await page.getByRole("radiogroup", {"name": "Colour theme", "exact": True}).getByRole("radio", {"name": "Dark", "exact": True}).click());
    `assert.equal((await page.locator("html").getAttribute("data-theme")), "dark");
    (await page.reload());
    (await page.locator(".garage-feature").waitFor());
    `assert.equal((await page.getByRole("radiogroup", {"name": "Colour theme", "exact": True}).getByRole("radio", {"name": "Dark", "exact": True}).getAttribute("aria-checked")), "true");
    (await page.getByRole("radiogroup", {"name": "Colour theme", "exact": True}).getByRole("radio", {"name": "Light", "exact": True}).click());
    (await navigate("My garage"));
    (await page.evaluate(lambda() -> any { return window.scrollTo(0, 900); }));
    `assert.equal((await page.evaluate(lambda() -> any { return document.querySelector(".topbar").getBoundingClientRect().top; })), 0, "Navbar must stay pinned");
    (await page.evaluate(lambda() -> any { return window.scrollTo(0, 0); }));
    `assert.equal((await page.locator(".topbar [data-action=logout]").count()), 0, "Sign out belongs in the sidebar");
    (await page.locator(".sidebar-foot").getByRole("button", {"name": "Sign out", "exact": True}).waitFor());
    (await page.getByRole("button", {"name": "Add vehicle", "exact": True}).click());
    `assert.equal((await page.evaluate(lambda() -> any { return document.querySelector("#modal").contains(document.activeElement); })), True);
    (await page.keyboard.press("Escape"));
    `assert.equal((await page.locator("#modal").getAttribute("open")), None);
    (await navigate("Vehicle passport"));
    evidence = page.locator(".record-evidence").first();
    (await evidence.locator("summary").focus());
    (await page.keyboard.press("Enter"));
    `assert.equal((await evidence.getAttribute("open")), "");
    (await evidence.getByText("Unverified source:", {"exact": False}).waitFor());
    (await page.keyboard.press("Enter"));
    (await page.emulateMedia({"reducedMotion": "reduce"}));
    `assert.equal((await page.evaluate(lambda() -> any { return getComputedStyle(document.querySelector(".btn")).transitionDuration; })), "0s");
    for width in [320, 390, 768, 1440] {
        (await page.setViewportSize({"width": width, "height": 960}));
        for label in ["My garage", "Vehicle passport", "Fuel & costs", "Tracking", "Marketplace", "Assistant", "Settings"] {
            (await navigate(label));
            `assert.equal((await page.evaluate(lambda() -> any { return document.documentElement.scrollWidth > innerWidth; })), False, label + " overflows at " + String(width));
            if width == 390 and label == "Vehicle passport" {
                (await page.screenshot({"path": "artifacts/journal-passport-mobile.png", "fullPage": True}));
            }
            if label == "My garage" and [390, 1440].includes(width) {
                (await page.screenshot({"path": "artifacts/journal-garage-" + String(width) + ".png", "fullPage": True}));
            }
        }
    }
    (await page.getByRole("radiogroup", {"name": "Colour theme", "exact": True}).getByRole("radio", {"name": "Dark", "exact": True}).click());
    for label in ["My garage", "Vehicle passport", "Fuel & costs", "Tracking", "Marketplace", "Assistant", "Settings"] {
        (await navigate(label));
        `assert.equal((await page.locator("html").getAttribute("data-theme")), "dark");
        (await page.screenshot({"path": "artifacts/journal-dark-" + label.replaceAll(" ", "-").replaceAll("&", "and") + ".png", "fullPage": True}));
        (await page.setViewportSize({"width": 320, "height": 844}));
        `assert.equal((await page.evaluate(lambda() -> any { return document.documentElement.scrollWidth > innerWidth; })), False, "Dark " + label + " overflows at 320");
        (await page.setViewportSize({"width": 1440, "height": 960}));
    }
    (await navigate("My garage"));
    (await page.setViewportSize({"width": 390, "height": 844}));
    (await page.screenshot({"path": "artifacts/journal-garage-dark-mobile.png", "fullPage": True}));
    (await page.getByRole("radiogroup", {"name": "Colour theme", "exact": True}).getByRole("radio", {"name": "Light", "exact": True}).click());
    (await page.reload());
    (await page.locator(".garage-feature").waitFor());
    (await page.keyboard.press("Tab"));
    `assert.equal((await page.evaluate(lambda() -> any { return document.activeElement.textContent; })), "Skip to content");
    (await page.keyboard.press("Enter"));
    `assert.equal((await page.evaluate(lambda() -> any { return document.activeElement.id; })), "main-content");
    (await navigate("My garage"));
    (await page.locator("#main-content").focus());
    (await page.screenshot({"path": "artifacts/journal-mobile-preview.png", "fullPage": False}));
    (await page.locator(".garage-feature").screenshot({"path": "artifacts/journal-mobile-vehicle.png"}));
    (await page.setViewportSize({"width": 1440, "height": 1080}));
    (await page.evaluate(lambda() -> any { return window.scrollTo(0, 0); }));
    (await page.screenshot({"path": "artifacts/journal-desktop-preview.png", "fullPage": False}));
    console.log("Journal checks passed: primary selection, evidence keyboard disclosure, theme persistence, reduced motion, skip navigation, all seven screens at 320/390/768/1440, and dark mode screenshots.");
}

async def premiumLandingChecks() -> any {
    publicMarket = await (await page.request.get(base + "/api/public/market")).json();
    `assert.equal(JSON.stringify(publicMarket).includes("seller_id"), False, "Public marketplace must not expose account identifiers");
    (await page.goto(base + "/market"));
    (await page.getByRole("heading", {"name": "A new owner.", "exact": False}).waitFor());
    `assert.equal((await page.evaluate(lambda() -> any { return document.documentElement.scrollWidth > innerWidth; })), False, "Public marketplace overflows");
    (await page.goto(base));
    (await page.locator(".cinematic-hero").waitFor());
    (await page.locator(".cinematic-image img").waitFor());
    (await page.locator(".cinematic-image img").evaluate(lambda (img: any) -> any { return img.decode(); }));
    `assert.equal((await page.evaluate(lambda() -> any { return Array.from(document.images).every(lambda (img: any) -> any { return img.complete and img.naturalWidth > 0; }); })), True, "Editorial imagery must load");
    `assert.equal((await page.getByRole("radiogroup", {"name": "Colour theme", "exact": True}).getByRole("radio").count()), 2);
    (await page.getByRole("radiogroup", {"name": "Colour theme", "exact": True}).getByRole("radio", {"name": "Dark", "exact": True}).click());
    (await page.reload());
    (await page.locator(".cinematic-hero").waitFor());
    `assert.equal((await page.getByRole("radiogroup", {"name": "Colour theme", "exact": True}).getByRole("radio", {"name": "Dark", "exact": True}).getAttribute("aria-checked")), "true");
    (await page.emulateMedia({"colorScheme": "light"}));
    `assert.equal((await page.locator("html").getAttribute("data-theme")), "dark", "Chosen theme must remain stable");
    (await page.screenshot({"path": "artifacts/premium-landing-dark-desktop.png", "fullPage": True}));
    (await page.getByRole("radiogroup", {"name": "Colour theme", "exact": True}).getByRole("radio", {"name": "Light", "exact": True}).click());
    for width in [320, 390, 768, 1440] {
        (await page.setViewportSize({"width": width, "height": 1000}));
        (await page.evaluate(lambda() -> any { return window.scrollTo(0, 0); }));
        `assert.equal((await page.evaluate(lambda() -> any { return document.documentElement.scrollWidth > innerWidth; })), False, "Premium landing overflows at " + String(width));
        if [390, 1440].includes(width) {
            (await page.screenshot({"path": "artifacts/premium-landing-" + String(width) + ".png", "fullPage": True}));
            (await page.screenshot({"path": "artifacts/premium-landing-preview-" + String(width) + ".png", "fullPage": False}));
            if width == 390 {
                (await page.locator(".public-menu summary").click());
                (await page.locator(".public-menu[open]").getByRole("button", {"name": "Sign in", "exact": True}).waitFor());
                (await page.keyboard.press("Escape"));
                `assert.equal((await page.locator(".public-menu").getAttribute("open")), None);
                (await page.getByRole("radiogroup", {"name": "Colour theme", "exact": True}).getByRole("radio", {"name": "Dark", "exact": True}).click());
                (await page.evaluate(lambda() -> any { return window.scrollTo(0, 0); }));
                (await page.screenshot({"path": "artifacts/premium-landing-dark-mobile.png", "fullPage": True}));
                `assert.equal((await page.evaluate(lambda() -> any { return document.documentElement.scrollWidth > innerWidth; })), False, "Dark premium landing should fit mobile");
                (await page.getByRole("radiogroup", {"name": "Colour theme", "exact": True}).getByRole("radio", {"name": "Light", "exact": True}).click());
            }
        }
    }
    (await page.evaluate(lambda() -> any { return window.scrollTo(0, 0); }));
    console.log("Premium checks passed: locally served responsive image, single Light/Dark selector, persisted preference, explicit theme, landing at 320/390/768/1440.");
}



async def navigate(label: any) -> any {
    target = page.getByRole("button", {"name": label, "exact": True});
    # Let pending viewport media-query changes settle the menu before checking it.
    (await page.evaluate(lambda() -> any { return new(Promise, lambda (done: any) -> any { requestAnimationFrame(lambda() -> any { requestAnimationFrame(done); }); }); }));
    if not (await target.isVisible()) { (await page.locator(".workspace-menu summary").click()); }
    (await target.click());
}

async def issueChecks() -> any {
    (await page.route("**/api/state", _asyncHandler1));
    (await page.reload());
    (await navigate("Assistant"));
    snapshot = await (await page.request.get(base + "/api/state")).json();
    vehicle = snapshot.vehicles[0];
    record = vehicle.records[0];
    before = JSON.stringify(snapshot.vehicles);
    (await page.route("**/api/ai/diagnosis", lambda (route: any) -> any { return route.fulfill({"status": 503, "json": {"error": "UI test: provider unavailable"}}); }));
    (await page.getByRole("button", {"name": "Describe a vehicle issue", "exact": True}).click());
    (await page.getByLabel("What is happening?", {"exact": True}).fill("A vibration appears at idle after starting."));
    (await page.getByRole("button", {"name": "Review possible causes", "exact": True}).click());
    (await page.getByText("UI test: provider unavailable", {"exact": True}).waitFor());
    `assert.equal((await page.locator("#issue-assessment").count()), 0, "Failed inference must not produce a canned result");
    (await page.unroute("**/api/ai/diagnosis"));
    fixture = {"kind": "diagnosis", "model": "Gemini UI fixture (not live)", "generated_at": "2026-10-17T09:00:00Z", "result": {"summary": "UI test fixture: history may help narrow the reported vibration.", "urgency": "soon", "possible_causes": [{"cause": "Fixture possible cause", "reasoning": "A hypothesis, not a confirmed fault.", "record_ids": [record.id]}], "next_checks": ["Arrange a qualified inspection."], "questions": ["Does it happen when cold or warm?"]}};
    (await page.route("**/api/ai/diagnosis", lambda (route: any) -> any { return route.fulfill({"json": fixture}); }));
    (await page.getByRole("dialog").getByLabel("Vehicle", {"exact": True}).selectOption(vehicle.id));
    (await page.getByRole("button", {"name": "Review possible causes", "exact": True}).click());
    (await page.locator("#issue-assessment").waitFor());
    (await page.getByText("Fixture possible cause", {"exact": True}).waitFor());
    `assert.equal(JSON.stringify((await (await page.request.get(base + "/api/state")).json()).vehicles), before, "Issue assessment must not change records");
    (await page.setViewportSize({"width": 1440, "height": 1000}));
    (await page.locator("#issue-assessment").screenshot({"path": "artifacts/issue-assessment-desktop-test.png"}));
    (await page.setViewportSize({"width": 390, "height": 844}));
    `assert.equal((await page.evaluate(lambda() -> any { return document.documentElement.scrollWidth > innerWidth; })), False);
    (await page.locator("#issue-assessment").screenshot({"path": "artifacts/issue-assessment-mobile-test.png"}));
    (await page.locator(".issue-citations button").first().click());
    `assert.equal((await page.locator("#record-" + record.id + " details").getAttribute("open")), "");
    (await page.unroute("**/api/ai/diagnosis"));
    (await page.unroute("**/api/state"));
    for width in [320, 390, 768, 1024] {
        (await page.setViewportSize({"width": width, "height": 900}));
        (await navigate("My garage"));
        `assert.equal((await page.locator(".workspace-menu").getAttribute("open")), None);
        (await page.locator(".workspace-menu summary").click());
        `assert.equal((await page.evaluate(lambda() -> any { return document.querySelector(".side-nav").scrollWidth > document.querySelector(".side-nav").clientWidth; })), False, "Navigation must not scroll sideways");
        (await page.locator(".workspace-menu").screenshot({"path": "artifacts/workspace-menu-" + String(width) + ".png"}));
        (await page.keyboard.press("Escape"));
        `assert.equal((await page.locator(".workspace-menu").getAttribute("open")), None);
    }
    console.log("Issue checks passed: explicit provider failure, cited assessment UI (mock only), read-only history, citation navigation, mobile menu at 320/390/768/1024.");
}
