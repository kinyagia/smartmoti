"""Smartmoti client program, authored and compiled in Jac."""
glob app: any = document.querySelector("#app");

glob modal: any = document.querySelector("#modal");

glob themeMode: any = "light";
glob themePreference: any = "light";
glob issueAssessment: any = None;
glob compactNavigation: any = window.matchMedia("(max-width: 1100px)");

def applyNavigation() -> any {
    menu = document.querySelector(".workspace-menu");
    if menu { menu.open = not compactNavigation.matches; }
}

def applyTheme() -> any {
    themeMode = themePreference;
    document.documentElement.dataset.theme = themeMode;
    document.documentElement.dataset.themePreference = themePreference;
    document.querySelector("meta[name='theme-color']").content = (
        "#0E1211" if themeMode == "dark" else "#F4F5F0"
    );
    document.querySelectorAll("[data-theme-choice]").forEach(
        lambda (control: any) -> any {
            control.setAttribute("aria-checked", String(control.dataset.themeChoice == themePreference));
        }
    );
}

def themeButton() -> any {
    choices = [["light", "sun", "Light"], ["dark", "moon", "Dark"]];
    return "<div class=\"theme-switcher\" role=\"radiogroup\" aria-label=\"Colour theme\">" + choices.map(
        lambda (choice: any) -> any {
            return "<button type=\"button\" role=\"radio\" data-theme-choice=\"" + String(choice[0]) + "\" aria-checked=\"" + String(choice[0] == themePreference) + "\" title=\"" + String(choice[2]) + "\">" + String(icon(choice[1])) + "<span class=\"sr-only\">" + String(choice[2]) + "</span></button>";
        }
    ).join("") + "</div>";
}


glob state: any = None;

glob page: any = "garage";

glob selected: any = None;

glob passportTab: any = "timeline";

glob marketQuery: any = "";

glob authMode: any = "signup";

glob aiReviews: any = new(Map);

glob agentGeneration: any = 0;

glob agentMessages: any = [];

glob agentSession: any = None;

glob agentBusy: any = False;

glob assistantVehicle: any = "";

glob agentDraft: any = "";

glob tourOpen: any = location.pathname == "/demo";

glob tourStep: any = 0;

glob tourSteps: any = [
         {
             "page": "garage",
             "title": "One garage. Three vehicle stories.",
             "copy": "Introduce Smartmoti: a lifetime vehicle record, supported by fuel, tracking and resale. Each sample vehicle has a different story."
         },
         {
             "page": "passport",
             "title": "Follow the Hilux through its lifetime.",
             "copy": "Show acquisition, servicing, inspection and an ownership chapter. Open Documents to show a private sample receipt. Reported records are clearly unverified."
         },
         {
             "page": "assistant",
             "title": "Ask for data. Propose an update.",
             "copy": "Ask for the Hilux fuel economy, then ask to record an inspection today at 44,700 km. Show the retrieved-data trail and the exact proposed fields. Approve only after reviewing them. A configured Gemini key is required."
         },
         {
             "page": "fuel",
             "title": "Explain the cost of each kilometre.",
             "copy": "The Hilux has full and partial fills. Show 8.57 L/100 km and KES 15.86/km from the latest complete full-tank interval. These are calculations on sample entries."
         },
         {
             "page": "tracking",
             "title": "Show the illustrative journey.",
             "copy": "Present the Nairobi to Naivasha route diagram. State clearly that it is a demo fixture; live GPS and measured fuel need provider integration."
         },
         {
             "page": "market",
             "title": "Share a clearer history with a buyer.",
             "copy": "Open the Mazda listing. Three selected history entries are visible, while private notes and documents stay hidden. Show the illustrative buyer enquiry below."
         },
         {
             "page": "passport",
             "title": "Keep blockchain to optional minting.",
             "copy": "Preview the Hilux NFT metadata: make, model and year only. This prepares a snapshot; it does not mint an NFT. Jac handles the record workflows without AI."
         }
     ];

glob paths: any = {
         "menu": "M4 6h16M4 12h16M4 18h16",
         "monitor": "M3 4h18v13H3zM8 21h8m-4-4v4",
         "sun": "M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8m0-6v2m0 16v2M4.9 4.9l1.4 1.4m11.4 11.4 1.4 1.4M2 12h2m16 0h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4",
         "moon": "M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5",
         "contrast": "M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18Zm0 0v18M12 3a9 9 0 0 1 0 18",
         "settings": "m9 3-1 3-3 1-2 3 2 2v3l3 1 1 3h4l1-3 3-1v-3l2-2-2-3-3-1-1-3H9m6 9a3 3 0 1 1-6 0 3 3 0 0 1 6 0",
         "spark": "m12 3 2.5 6.5L21 12l-6.5 2.5L12 21l-2.5-6.5L3 12l6.5-2.5L12 3m7-2v4m-2-2h4",
         "arrow": "M4 12h16m-6-6 6 6-6 6",
         "car": "m5 7 2-4h10l2 4M3 8h18v9H3zM6 17v3m12-3v3M6 12h2m8 0h2",
         "garage": "m3 9 9-6 9 6v12H3V9zm3 4h12v8M6 17h12",
         "book": "M4 4h6a3 3 0 0 1 3 3v14a4 4 0 0 0-4-2H4V4zm9 3a3 3 0 0 1 3-3h5v15h-4a4 4 0 0 0-4 2",
         "fuel": "M4 21V3h9v18H4zm0-12h9m0 6h3a2 2 0 0 1 2 2v1a2 2 0 0 0 4 0V8l-4-4m-1 17H2",
         "pin": "M20 10c0 6-8 11-8 11S4 16 4 10a8 8 0 1 1 16 0zm-5 0a3 3 0 1 1-6 0 3 3 0 0 1 6 0",
         "market": "M4 9h16v12H4V9zm-1 0 2-6h14l2 6M9 21v-7h6v7",
         "plus": "M12 5v14M5 12h14",
         "service": "m14 3 3 3-4 4-3-3 4-4zm-4 7-7 7a2.8 2.8 0 0 0 4 4l7-7M3 3l5 5",
         "check": "m5 12 4 4L19 6",
         "close": "m6 6 12 12M6 18 18 6",
         "logout": "M9 3H4v18h5m6-14 5 5-5 5m-7-5h12",
         "clock": "M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0M12 7v5l3 2",
         "download": "M12 3v12m-5-5 5 5 5-5M4 17v4h16v-4",
         "shield": "m12 3 8 3v6c0 5-8 9-8 9s-8-4-8-9V6l8-3zm-4 9 3 3 5-6",
         "leaf": "M20 3C8 2 2 8 5 16c7 4 16-1 15-13ZM4 21 16 9"
     };

glob icon: any = lambda (name: any) -> any { return (
         "<svg class=\"icon\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.5\" stroke-linecap=\"round\" stroke-linejoin=\"round\" aria-hidden=\"true\"><path d=\"" + String(
             (paths[name] or paths.book)
         ) + "\"/></svg>"
     ); };

# Call the native String.prototype.replace: Jac's string polyfill treats
# .replace() as Python's str.replace and would stringify the callback.
glob esc: any = lambda (value: any) -> any { return Reflect.apply(
         String.prototype.replace,
         String((value if (value != None and value != globalThis.undefined) else "")),
         [
             new(RegExp, "[&<>\"']", "g"),
             lambda (c: any) -> any { return {
                 "&": "&amp;",
                 "<": "&lt;",
                 ">": "&gt;",
                 "\"": "&quot;",
                 "'": "&#39;"
             }[c]; }
         ]
     ); };

glob fmt: any = lambda (value: any) -> any { return new(
         Intl.NumberFormat, "en-KE", {"maximumFractionDigits": 2}
     ).format(
         (value or 0)
     ); };

glob money: any = lambda (value: any, currency: any = "KES") -> any { return (
         String(esc(currency)) + " " + String(fmt(value))
     ); };

glob dateLabel: any = lambda (value: any) -> any { if (not value) { return "Date not recorded"; } return new(
         Date, (String(value) + "T12:00:00")
     ).toLocaleDateString(
         "en-GB", {"day": "numeric", "month": "short", "year": "numeric"}
     ); };

glob today: any = lambda() -> any { return new(
         Intl.DateTimeFormat,
         "en-CA",
         {
             "timeZone": "Africa/Nairobi",
             "year": "numeric",
             "month": "2-digit",
             "day": "2-digit"
         }
     ).format(
         new(Date)
     ); };

glob brand: any = (
         "<a href=\"/\" class=\"brand\" aria-label=\"Smartmoti home\"><span class=\"brand-mark\" aria-hidden=\"true\">//</span>smartmoti<span class=\"dot\"></span></a>"
     );

def carArt(colour: any = "", dark: any = False) -> any {
    return "<svg class=\"car-svg neutral-silhouette\" viewBox=\"0 0 760 280\" role=\"img\" aria-label=\"Neutral vehicle silhouette. Actual vehicle photo unavailable.\"><path class=\"silhouette-ground\" d=\"M25 238h710\"/><path class=\"silhouette-body\" d=\"M62 197v-34c0-16 12-28 31-32l78-13 84-66c14-11 32-16 52-16h144c29 0 48 11 69 30l60 54 77 13c24 4 39 16 42 34l4 30h-45c-3-38-26-61-58-61s-56 24-59 61H240c-2-38-25-61-58-61s-57 24-60 61H62Z\"/><path class=\"silhouette-window\" d=\"m208 116 64-52c9-7 20-10 35-10h140c19 0 34 8 49 22l43 40H208Z\"/><path class=\"silhouette-detail\" d=\"M344 55v63m96-63 21 63m-117 17v54m121-54 5 54M83 151h49m499-5h43M80 210h39m124-5h292m123 5h26M359 138h21m104 0h21\"/><g class=\"silhouette-wheel\"><circle cx=\"182\" cy=\"195\" r=\"40\"/><circle cx=\"600\" cy=\"195\" r=\"40\"/></g><g class=\"silhouette-rim\"><circle cx=\"182\" cy=\"195\" r=\"25\"/><circle cx=\"600\" cy=\"195\" r=\"25\"/></g><path class=\"silhouette-spoke\" d=\"M182 171v48m-24-24h48m-41-17 34 34m0-34-34 34M600 171v48m-24-24h48m-41-17 34 34m0-34-34 34\"/><circle class=\"silhouette-hub\" cx=\"182\" cy=\"195\" r=\"8\"/><circle class=\"silhouette-hub\" cx=\"600\" cy=\"195\" r=\"8\"/></svg>";
}

async def api(path: any, payload: any) -> any {
    response = (
        await fetch(
            ("/api/" + String(path)),
            {
                "credentials": "same-origin",
                ** (
                    {}
                        if (payload == globalThis.undefined)
                        else {
                            "method": "POST",
                            "headers": {"Content-Type": "application/json"},
                            "body": JSON.stringify(payload)
                        }
                )
            }
        )
    );
    data = await response.json();
    if (not response.ok) {
        raise Object.assign(
            new(Error, (data.error or "Request failed")), {"status": response.status}
        );
    }
    return data;
}

async def refresh() -> any {
    state = await api("state");
    if (
        not state.vehicles.some(lambda (v: any) -> any { return (v.id == selected); })
    ) {
        selected = (
            (
                state.vehicles[0].id
                    if (
                        (
                            state.vehicles[0] != None
                            and state.vehicles[0] != globalThis.undefined
                        )
                    )
                    else globalThis.undefined
            )
            or None
        );
    }
    render();
}

def notify(message: any) -> any {
    toast = document.querySelector("#toast");
    toast.textContent = message;
    toast.classList.add("visible");
    clearTimeout(notify.timer);
    notify.timer = setTimeout(
        lambda() -> any { return toast.classList.remove("visible"); }, 4000
    );
}

def landing() -> any {
    app.innerHTML = "<div class=\"landing premium-landing film-landing\"><nav class=\"land-nav\" aria-label=\"Main navigation\">" + String(brand) + "<div class=\"nav-links\"><a href=\"#story\">Discover Smartmoti</a><a href=\"#features\">The experience</a><a href=\"/market\">Marketplace</a></div><div class=\"nav-actions\"><button class=\"btn text\" data-action=\"login\">Sign in</button><button class=\"btn primary\" data-action=\"signup\">Start your story " + String(icon("arrow")) + "</button></div><details class=\"public-menu\"><summary aria-label=\"Open navigation\"><span></span><span></span></summary><div class=\"public-menu-content\"><a href=\"#story\">Discover Smartmoti</a><a href=\"#features\">The experience</a><a href=\"/market\">Marketplace</a><button class=\"btn\" data-action=\"login\">Sign in</button><button class=\"btn lime\" data-action=\"signup\">Create your garage</button></div></details></nav><main id=\"main-content\" tabindex=\"-1\"><section class=\"cinematic-hero\"><div class=\"cinematic-copy\"><div class=\"eyebrow\"><span class=\"dot\"></span>THE DIGITAL HOME FOR YOUR VEHICLE</div><h1>Your vehicle.<br>Every <em>chapter.</em></h1><p>A lifetime of journeys. One enduring record.<br>Everything that makes your vehicle yours.</p><div class=\"hero-buttons\"><button class=\"btn lime\" data-action=\"signup\">Create your garage " + String(icon("arrow")) + "</button><button class=\"btn cinematic-secondary\" data-action=\"demo\">Explore the demo " + String(icon("arrow")) + "</button></div><div class=\"edition-mark\"><span>01 — THE OWNERSHIP EDITION</span><a href=\"#story\">SCROLL TO EXPLORE ↓</a></div></div><figure class=\"cinematic-image\"><img src=\"/assets/road-editorial-2000.webp\" srcset=\"/assets/road-editorial-900.webp 900w, /assets/road-editorial-2000.webp 2000w\" sizes=\"(max-width: 800px) 100vw, 60vw\" width=\"2000\" height=\"2500\" fetchpriority=\"high\" alt=\"A matte black sports car photographed beside a harbour\"></figure><div class=\"editorial-credit\" id=\"editorial-credit\">Editorial photography · Not a listed vehicle <a href=\"https://unsplash.com/photos/pjxe3p4u5aI\" target=\"_blank\" rel=\"noopener\">Josh Berquist / Unsplash ↗</a></div></section><div class=\"edition-strip\"><span>VEHICLE LIFETIME RECORDS</span><span>01 — RECORD</span><span>02 — UNDERSTAND</span><span>03 — PASS IT ON " + String(icon("arrow")) + "</span></div><section class=\"ownership-intro\" id=\"story\"><div><span class=\"eyebrow\">A DIGITAL PASSPORT. A CLEARER PICTURE.</span><h2>Every kilometre<br>has a <em>story.</em></h2></div><div><p class=\"intro-lead\">Give yours a place to live.</p><p>Keep your vehicle’s history, supporting documents and ownership milestones together. Know what was recorded, where it came from, and what you choose to share.</p><button class=\"btn text\" data-action=\"demo\">Step inside the garage " + String(icon("arrow")) + "</button></div></section><section class=\"ownership-chapters\" id=\"features\"><article><span class=\"chapter-number\">01 / THE RECORD</span>" + String(icon("book")) + "<h3>A history worth<br>holding on to.</h3><p>Services, inspections, ownership changes and private documents. One chronological record with sources and evidence.</p><span class=\"chapter-footer\">YOUR DIGITAL VEHICLE PASSPORT " + String(icon("arrow")) + "</span></article><article><span class=\"chapter-number\">02 / THE EVERYDAY</span>" + String(icon("fuel")) + "<h3>Know what<br>keeps you moving.</h3><p>Recorded fuel, running costs and optional tracking. Clear information, with honest gaps when data is unavailable.</p><span class=\"chapter-footer\">MORE CONTEXT. BETTER DECISIONS. " + String(icon("arrow")) + "</span></article><article><span class=\"chapter-number\">03 / THE NEXT OWNER</span>" + String(icon("market")) + "<h3>A new chapter.<br>A clearer handover.</h3><p>List your vehicle and select the history a buyer can see. Your notes, documents and sensitive identifiers stay private.</p><span class=\"chapter-footer\">SHARE THE HISTORY YOU CHOOSE " + String(icon("arrow")) + "</span></article></section><section class=\"ownership-promise\"><span class=\"eyebrow\">BUILT AROUND TRUST</span><h2>Good records.<br><span>No guesswork.</span></h2><div><p>Reported history stays labelled. Missing telemetry stays missing. AI suggestions wait for your approval.</p><p>Your vehicle’s story deserves that precision.</p></div></section><section class=\"land-cta\"><div><span class=\"eyebrow\">YOUR NEXT CHAPTER</span><h2>Make room for<br>the road ahead.</h2><p>One vehicle or a growing collection. Start with what you know.</p></div><button class=\"btn lime\" data-action=\"signup\">Create your garage " + String(icon("arrow")) + "</button></section></main><footer class=\"land-footer\"><span>© " + String(new(Date).getFullYear()) + " Smartmoti. Every kilometre has a story.</span><span>VEHICLE RECORDS FIRST. ALWAYS.</span>" + String(themeButton()) + "</footer></div>";
    applyTheme();
}

glob navItems: any = [
         ["garage", "garage", "My garage"],
         ["passport", "book", "Vehicle passport"],
         ["fuel", "fuel", "Fuel & costs"],
         ["tracking", "pin", "Tracking"],
         ["market", "market", "Marketplace"],
         ["assistant", "spark", "Assistant"],
         ["settings", "settings", "Settings"]
     ];

def render() -> any {
    if (not state) {
        return landing();
    }
    title = (
        (
            navItems.find(lambda (i: any) -> any { return (i[0] == page); })[2]
                if (
                    (
                        navItems.find(
                            lambda (i: any) -> any { return (i[0] == page); }
                        ) != None
                        and navItems.find(
                            lambda (i: any) -> any { return (i[0] == page); }
                        ) != globalThis.undefined
                    )
                )
                else globalThis.undefined
        )
        or "My garage"
    );
    body = (
        {
            "garage": garagePage,
            "passport": passportPage,
            "fuel": fuelPage,
            "tracking": trackingPage,
            "market": marketPage,
            "assistant": assistantPage,
            "settings": settingsPage
        }[page]
        or garagePage
    )();
    app.innerHTML = (
        "<div class=\"app-shell\"><aside class=\"sidebar\">" + String(brand) + "<div class=\"nav-caption\">YOUR WORKSPACE</div><details class=\"workspace-menu\" open><summary><span>Menu</span>" + String(icon("menu")) + "</summary><nav class=\"side-nav\" aria-label=\"Workspace\">" + String(
            navItems.map(
                lambda (_pair1: any) -> any {
                    id = _pair1[0];
                    name = _pair1[1];
                    label = _pair1[2];
                    return (
                        "<button class=\"side-link " + String(
                            ("active" if (page == id) else "")
                        ) + "\" data-page=\"" + String(id) + "\" " + String(
                            ("aria-current=\"page\"" if (page == id) else "")
                        ) + ">" + String(icon(name)) + String(label) + "</button>"
                    );
                }
            ).join(
                ""
            )
        ) + "<button class=\"side-link side-signout\" data-action=\"logout\">" + String(icon("logout")) + "Sign out</button></nav></details><div class=\"sidebar-foot\"><button class=\"user-box\" data-page=\"settings\" title=\"Account settings\"><span class=\"avatar\">" + String(
            esc(state.user.name.slice(0, 2).toUpperCase())
        ) + "</span><span class=\"user-box-name\">" + String(esc(state.user.name)) + "<small>" + String(
            ("Demo workspace" if state.user.demo else "Personal workspace")
        ) + "</small></span></button><button class=\"sidebar-signout\" data-action=\"logout\">" + String(
            icon("logout")
        ) + "<span>Sign out</span></button></div></aside><div class=\"workspace\">" + String(workspaceHeader(title)) + "" + String(
            (
                "<div class=\"demo-banner\"><span class=\"dot\"></span> DEMO GARAGE · Illustrative records and tracking. No live trackers or actual sales.<button class=\"btn text small\" data-action=\"tour\">Presentation guide</button><button class=\"btn text small\" data-action=\"restart-demo\">Fresh demo</button></div>"
                    if state.user.demo
                    else ""
            )
        ) + "<main class=\"page\" id=\"main-content\" tabindex=\"-1\" data-view=\"" + String(page) + "\">" + String(body) + "<footer class=\"footer-note\"><span>smartmoti · Every kilometre has a story.</span><span>Your vehicle records, kept together.</span></footer></main></div></div>" + String(
            (tourGuide() if (tourOpen and state.user.demo) else "")
        )
    );
    applyTheme();
    applyNavigation();
}


def workspaceHeader(title: any) -> any {
    day = new(Date).toLocaleDateString("en-GB", {"day": "numeric", "month": "long", "year": "numeric", "timeZone": "Africa/Nairobi"});
    return (
        "<header class=\"topbar\"><div class=\"topbar-location\"><div class=\"workspace-breadcrumb\"><span>Your workspace</span><span aria-hidden=\"true\">/</span><strong>" + String(esc(title)) + "</strong></div><time class=\"top-date\" datetime=\"" + String(today()) + "\">" + String(esc(day)) + "</time></div><div class=\"topbar-right\"><button class=\"ask-pill\" data-action=\"open-assistant\">" + String(icon("spark")) + " Ask Smartmoti</button><div class=\"topbar-utilities\">" + String(themeButton()) + "<button class=\"avatar account-button\" data-page=\"settings\" aria-label=\"Account settings\" title=\"" + String(esc(state.user.name)) + " · Account settings\">" + String(esc(state.user.name.slice(0, 2).toUpperCase())) + "</button></div></div></header>"
    );
}

def pageHead(title: any, subtitle: any, button: any = "") -> any {
    return (
        "<div class=\"page-head\"><div><div class=\"eyebrow journal-kicker\">SMARTMOTI / THE OWNERSHIP EXPERIENCE</div><h1>" + String(title) + "</h1><p>" + String(
            subtitle
        ) + "</p></div>" + String(button) + "</div>"
    );
}

def stats(items: any) -> any {
    return (
        "<div class=\"stats\">" + String(
            items.map(
                lambda (_pair2: any) -> any {
                    label = _pair2[0];
                    value = _pair2[1];
                    note = _pair2[2];
                    name = _pair2[3];
                    return (
                        "<div class=\"stat\"><div class=\"stat-label\">" + String(
                            label
                        ) + String(icon((name or "book"))) + "</div><div class=\"stat-value\">" + String(
                            value
                        ) + "</div><small>" + String(note) + "</small></div>"
                    );
                }
            ).join(
                ""
            )
        ) + "</div>"
    );
}

def empty(title: any, description: any, button: any = "") -> any {
    return (
        "<div class=\"empty\"><h3>" + String(title) + "</h3><p>" + String(
            description
        ) + "</p>" + String(button) + "</div>"
    );
}

glob registerButton: any = (
         "<button class=\"btn primary\" data-action=\"vehicle\">" + String(
             icon("plus")
         ) + " Add vehicle</button>"
     );

glob vehicle: any = lambda() -> any { return state.vehicles.find(
         lambda (v: any) -> any { return (v.id == selected); }
     ); };

def selector() -> any {
    return (
        "<select class=\"vehicle-selector\" id=\"vehicle-select\" aria-label=\"Select vehicle\">" + String(
            state.vehicles.map(
                lambda (v: any) -> any { return (
                    "<option value=\"" + String(v.id) + "\" " + String(
                        ("selected" if (v.id == selected) else "")
                    ) + ">" + String(esc(v.plate)) + " · " + String(esc(v.make)) + " " + String(
                        esc(v.model)
                    ) + "</option>"
                ); }
            ).join(
                ""
            )
        ) + "</select>"
    );
}

def vehicleCard(v: any, index: any) -> any {
    return (
        "<article class=\"vehicle-card\"><div class=\"vehicle-visual\"><span class=\"tag\">" + String(
            esc(v.plate)
        ) + "</span>" + String(
            carArt(["#bdb9ad", "#aab0ad", "#b8aba0"][(index % 3)])
        ) + "</div><div class=\"vehicle-info\"><h3>" + String(esc(v.make)) + " " + String(
            esc(v.model)
        ) + "</h3><div class=\"vehicle-meta\"><span>" + String(v.year) + "</span><span>•</span><span>" + String(
            fmt(v.odometer)
        ) + " km</span></div><div class=\"vehicle-data\"><div><strong>" + String(
            v.records.filter(
                lambda (r: any) -> any { return (not r.superseded_by); }
            ).length
        ) + " records</strong><span class=\"muted\">In its lifetime</span></div><div><strong>" + String(
            (
                "—"
                    if (v.fuel_summary.latest_economy == None)
                    else fmt(v.fuel_summary.latest_economy)
            )
        ) + "</strong><span class=\"muted\">L / 100 km</span></div></div><div class=\"card-footer\"><span class=\"tag neutral\">" + String(
            esc(v.tracking_status)
        ) + "</span><button class=\"btn text small\" data-passport=\"" + String(v.id) + "\">View passport " + String(
            icon("arrow")
        ) + "</button></div></div></article>"
    );
}

def settingsPage() -> any {
    prefs = state.settings or {};
    ai = state.ai or {};
    heading = lambda (name: any, title: any, copy: any) -> any { return (
        "<div class=\"settings-card-head\"><span class=\"settings-icon\">" + String(
            icon(name)
        ) + "</span><div><h2>" + String(title) + "</h2><p>" + String(copy) + "</p></div></div>"
    ); };
    return (
        pageHead(
            "Make it yours.",
            "Your profile, your AI, your way of keeping a garage.",
            (
                "<button class=\"btn small\" data-action=\"export-workspace\">" + String(
                    icon("download")
                ) + " Export my records</button>"
            )
        ) + (
            "<div class=\"settings-layout\"><aside class=\"settings-summary\"><span class=\"avatar settings-avatar\">" + String(
                esc(state.user.name.slice(0, 2).toUpperCase())
            ) + "</span><h2>" + String(esc(state.user.name)) + "</h2><p>" + String(
                esc(state.user.email)
            ) + "</p><span class=\"tag neutral\">" + String(
                ("Demo account" if state.user.demo else "Personal account")
            ) + "</span><div class=\"settings-summary-note\">" + String(
                icon("shield")
            ) + "<p>Settings belong to this account. " + String(
                (
                    "Create a personal account to keep them beyond a fresh demo."
                        if state.user.demo
                        else "Your private records stay in your workspace."
                )
            ) + "</p></div><small>JSON history export. Download supporting documents from each passport.</small></aside><div class=\"settings-cards\">\n  <section class=\"panel settings-card\">" + String(
                heading(
                    "garage",
                    "Your profile",
                    "The details people see beside your garage."
                )
            ) + "<form data-form=\"settings-profile\">" + String(
                field(
                    "name",
                    "Display name",
                    "text",
                    state.user.name,
                    "required maxlength=\"80\""
                )
            ) + String(
                field(
                    "email",
                    "Email address",
                    "email",
                    state.user.email,
                    (
                        "required maxlength=\"200\" " + String(
                            ("readonly" if state.user.demo else "")
                        )
                    )
                )
            ) + String(
                (
                    field(
                        "email_password",
                        "Current password (to change email)",
                        "password",
                        "",
                        "autocomplete=\"current-password\" maxlength=\"200\""
                    )
                        if (not state.user.demo)
                        else ""
                )
            ) + "<p class=\"form-error\" role=\"alert\"></p><button type=\"submit\" class=\"btn primary small\">Save profile</button></form></section>\n  <section class=\"panel settings-card\">" + String(
                heading(
                    "settings",
                    "Workspace preferences",
                    "Small defaults that make everyday logging easier."
                )
            ) + "<form data-form=\"settings-preferences\">" + String(
                selectField(
                    "currency",
                    "Default fuel currency",
                    ["KES", "USD", "UGX", "TZS", "EUR", "GBP"].map(
                        lambda (c: any) -> any { return [c, c]; }
                    ),
                    (prefs.currency or "KES")
                )
            ) + String(
                selectField(
                    "start_page",
                    "Opening page",
                    [
                        ["garage", "My garage"],
                        ["passport", "Vehicle passport"],
                        ["fuel", "Fuel & costs"],
                        ["assistant", "Assistant"],
                        ["settings", "Settings"]
                    ],
                    (prefs.start_page or "garage")
                )
            ) + "<p class=\"note\">Currency sets the default for new fills. Existing amounts keep their original currency. Distances use kilometres.</p><p class=\"form-error\" role=\"alert\"></p><button type=\"submit\" class=\"btn primary small\">Save preferences</button></form></section>\n  <section class=\"panel settings-card settings-wide\">" + String(
                heading(
                    "spark",
                    "AI, on your terms",
                    "Bring your own Gemini key. Choose a model and decide when AI is available."
                )
            ) + "<div class=\"settings-ai-status\"><span class=\"tag " + String(
                ("" if ai.available else "amber")
            ) + "\">" + String(
                (
                    "AI paused"
                        if (not ai.enabled)
                        else (
                            "Personal key saved"
                                if (ai.source == "personal")
                                else (
                                    "Server key configured"
                                        if (ai.source == "server")
                                        else "Key needed"
                                )
                        )
                )
            ) + "</span><span>Saving a key does not verify access. Use Test connection below.</span></div><form data-form=\"settings-ai\"><div class=\"form-grid\">" + String(
                field(
                    "api_key",
                    (
                        "Replace Gemini API key"
                            if prefs.personal_key_saved
                            else "Gemini API key"
                    ),
                    "password",
                    "",
                    "autocomplete=\"off\" maxlength=\"512\" spellcheck=\"false\""
                )
            ) + String(
                field(
                    "model",
                    "Gemini model",
                    "text",
                    (prefs.model or "gemini/gemini-3.8-flash"),
                    "required maxlength=\"100\" spellcheck=\"false\""
                )
            ) + "</div><p class=\"note\">Leave the key blank to keep your saved key. It is encrypted on the server and never returned to your browser. Your Gemini account handles API usage and billing.</p><label class=\"check-row\"><input type=\"checkbox\" name=\"ai_enabled\" " + String(
                ("checked" if (prefs.ai_enabled != False) else "")
            ) + ">Enable AI for my account</label><label class=\"check-row\"><input type=\"checkbox\" name=\"use_server_ai\" " + String(
                ("checked" if (prefs.use_server_ai != False) else "")
            ) + ">Use the server key when I have no personal key</label><p class=\"note\">Your personal key takes priority for the Assistant, history reviews and marketplace drafts. Stored private notes, documents, VIN and GPS stay outside AI context.</p><p class=\"form-error\" role=\"alert\"></p><div class=\"settings-actions\"><button type=\"submit\" class=\"btn primary small\">Save AI settings</button><button type=\"button\" class=\"btn small\" data-action=\"test-api-key\">Test connection</button><button type=\"button\" class=\"btn text small\" data-action=\"remove-api-key\" " + String(
                ("" if prefs.personal_key_saved else "disabled")
            ) + ">Remove personal key</button></div><p class=\"settings-feedback\" id=\"ai-test-result\" aria-live=\"polite\"></p></form></section>\n  <section class=\"panel settings-card settings-wide\">" + String(
                heading(
                    "shield",
                    "Account security",
                    "Update your password and close your other signed-in sessions."
                )
            ) + String(
                (
                    "<p class=\"panel-copy\">Password management is available in a personal account. This sample workspace has no password to manage.</p>"
                        if state.user.demo
                        else (
                            "<form data-form=\"settings-password\">" + String(
                                field(
                                    "current_password",
                                    "Current password",
                                    "password",
                                    "",
                                    "required autocomplete=\"current-password\" maxlength=\"200\""
                                )
                            ) + "<div class=\"form-grid\">" + String(
                                field(
                                    "new_password",
                                    "New password",
                                    "password",
                                    "",
                                    "required minlength=\"8\" maxlength=\"200\" autocomplete=\"new-password\""
                                )
                            ) + String(
                                field(
                                    "confirm_password",
                                    "Confirm new password",
                                    "password",
                                    "",
                                    "required minlength=\"8\" maxlength=\"200\" autocomplete=\"new-password\""
                                )
                            ) + "</div><p class=\"note\">Changing your password signs out your other sessions. This session stays open.</p><p class=\"form-error\" role=\"alert\"></p><button type=\"submit\" class=\"btn primary small\">Update password</button></form>"
                        )
                )
            ) + "</section></div></div>"
        )
    );
}

def garagePage() -> any {
    records = state.vehicles.flatMap(
        lambda (v: any) -> any { return v.records.filter(
            lambda (r: any) -> any { return (not r.superseded_by); }
        ).map(
            lambda (r: any) -> any { return {
                ** r,
                "plate": v.plate,
                "vehicle_id": v.id
            }; }
        ); }
    ).sort.call(
        state.vehicles.flatMap(
            lambda (v: any) -> any { return v.records.filter(
                lambda (r: any) -> any { return (not r.superseded_by); }
            ).map(
                lambda (r: any) -> any { return {
                    ** r,
                    "plate": v.plate,
                    "vehicle_id": v.id
                }; }
            ); }
        ),
        lambda (a: any, b: any) -> any { return b.date.localeCompare(a.date); }
    ).slice(
        0, 4
    );
    return (
        (
            pageHead(
                ("Your garage.<br><em>Stories in motion.</em>"),
                (
                    "Welcome back, " + String(esc(state.user.name)) + ". Your vehicles' stories are right here."
                ),
                registerButton
            ) + stats(
                [
                    ["Vehicles", state.vehicles.length, "In your garage", "car"],
                    [
                        "Lifetime records",
                        state.vehicles.reduce(
                            lambda (n: any, v: any) -> any { return (
                                n + v.records.filter(
                                    lambda (r: any) -> any { return (
                                        not r.superseded_by
                                    ); }
                                ).length
                            ); },
                            0
                        ),
                        "Services, fuel and milestones",
                        "book"
                    ],
                    [
                        "Fuel logged",
                        (
                            String(
                                fmt(
                                    state.vehicles.reduce(
                                        lambda (n: any, v: any) -> any { return (
                                            n + v.fuel_summary.total_litres
                                        ); },
                                        0
                                    )
                                )
                            ) + " <small>L</small>"
                        ),
                        "From your refuelling entries",
                        "fuel"
                    ],
                    [
                        "Active listings",
                        state.listings.filter(
                            lambda (l: any) -> any { return (l.status == "active"); }
                        ).length,
                        "Your marketplace vehicles",
                        "market"
                    ]
                ]
            )
        ) + (
            String(garageFeature()) + "<div class=\"section-head\"><h2>The collection <small> / " + String(
                state.vehicles.length
            ) + " vehicles</small></h2><span class=\"tag neutral\">Lifetime view</span></div>" + String(
                (
                    (
                        "<div class=\"vehicle-grid\">" + String(
                            state.vehicles.map(vehicleCard).join("")
                        ) + "</div>"
                    )
                        if state.vehicles.length
                        else empty(
                            "Your first chapter starts with a vehicle.",
                            "Add its registration, make and starting mileage. Then build its history, one record at a time.",
                            registerButton
                        )
                )
            ) + "<div class=\"two-columns\"><section class=\"panel\"><h2>Recently in your timeline</h2>" + String(
                (
                    records.map(
                        lambda (r: any) -> any { return (
                            "<div class=\"recent-row\"><span class=\"record-icon\">" + String(
                                icon(
                                    (
                                        "fuel"
                                            if (r.`type == "fuel")
                                            else (
                                                "service"
                                                    if (r.`type == "maintenance")
                                                    else "book"
                                            )
                                    )
                                )
                            ) + "</span><div><strong>" + String(esc(r.title)) + "</strong><small>" + String(
                                esc(r.plate)
                            ) + " · " + String(esc(r.source)) + "</small></div><small>" + String(
                                dateLabel(r.date)
                            ) + "</small></div>"
                        ); }
                    ).join(
                        ""
                    )
                        if records.length
                        else "<p class=\"panel-copy\">Your services, repairs and milestones will appear here as you record them.</p>"
                )
            ) + "</section><section class=\"panel\"><span class=\"eyebrow\">The vehicle passport</span><h2 class=\"section-title\">Good records.<br>Better perspective.</h2><div class=\"lifecycle\"><span></span><span></span><span></span><span></span></div><p class=\"panel-copy\">Start where you are. Keep supporting documents, record the source, and build a history you can understand and selectively share.</p><button class=\"btn text small\" data-page=\"passport\">Open vehicle passport " + String(
                icon("arrow")
            ) + "</button></section></div>"
        )
    );
}


def garageFeature() -> any {
    v = vehicle();
    if (not v) { return ""; }
    current = v.records.filter(lambda (r: any) -> any { return not r.superseded_by; });
    ownership = current.find(lambda (r: any) -> any { return ["acquisition", "ownership"].includes(r.`type); });
    service = current.find(lambda (r: any) -> any { return ["maintenance", "repair", "inspection"].includes(r.`type); });
    return (
        "<section class=\"garage-feature\" aria-label=\"Primary vehicle\"><div class=\"feature-vehicle\"><div class=\"feature-topline\"><span class=\"eyebrow\">01 / IN FOCUS</span>" + String(selector()) + "</div><div class=\"feature-identity\"><span class=\"registration\">" + String(esc(v.plate)) + "</span><h2>" + String(esc(v.make)) + "<br><em>" + String(esc(v.model)) + "</em></h2><span class=\"feature-year\">" + String(v.year) + " / PHOTO UNAVAILABLE</span></div><div class=\"feature-drawing\"><span class=\"silhouette-caption\">NEUTRAL VEHICLE SILHOUETTE</span>" + String(carArt("#bbb5a5", True)) + "</div><div class=\"feature-bottomline\"><span>THE ROAD SO FAR</span><strong>" + String(fmt(v.odometer)) + " <small>km</small></strong></div></div><div class=\"feature-journal\"><div class=\"eyebrow\">YOUR OWNERSHIP FILE</div><h3>A life on the road.<br>Kept in detail.</h3><div class=\"ownership-fact\"><span>Latest ownership entry</span><strong>" + String(dateLabel(ownership.date) if ownership else "Not recorded") + "</strong><small>" + String(esc(ownership.source) if ownership else "Add an acquisition or ownership record.") + "</small></div><div class=\"ownership-fact\"><span>Maintenance outlook</span><strong>No due schedule recorded</strong><small>" + String(("Latest service / inspection: " + dateLabel(service.date)) if service else "No service or inspection recorded yet.") + "</small></div><p class=\"note\">Reported history, not independent verification. Documents stay private; you choose the history to share.</p><div class=\"feature-actions\"><button class=\"btn primary\" data-passport=\"" + String(v.id) + "\">Open passport " + String(icon("arrow")) + "</button><button class=\"btn\" data-action=\"record\">" + String(icon("plus")) + " Add record</button></div></div></section>"
    );
}

def timelineMarkup(v: any) -> any {
    if (not v.records.length) {
        return empty(
            "A story waiting to be told.",
            "Add an acquisition, service, inspection or odometer reading."
        );
    }
    return v.records.map(
        lambda (r: any) -> any { return (
            "<article tabindex=\"-1\" id=\"record-" + String(esc(r.id)) + "\" class=\"timeline-row event-" + String(esc(r.`type)) + " " + String(
                ("corrected" if r.superseded_by else "")
            ) + "\"><div class=\"timeline-date\"><time datetime=\"" + String(esc(r.date)) + "\">" + String(dateLabel(r.date)) + "</time><strong>" + String(fmt(r.odometer) if r.odometer != None else "Not recorded") + "<small> km</small></strong></div><div class=\"timeline-body\"><span class=\"event-stamp\">" + String(icon("service" if ["maintenance", "repair"].includes(r.`type) else ("fuel" if r.`type == "fuel" else ("shield" if r.`type == "inspection" else "book")))) + String(esc(r.`type)) + "</span><h3>" + String(
                esc(r.title)
            ) + "</h3><div class=\"record-tags\"><span>" + String(fmt(r.odometer) if r.odometer != None else "Not recorded") + " km</span><span>· " + String(
                esc(r.source)
            ) + "</span><span class=\"tag neutral\">" + String(
                ("Corrected" if r.superseded_by else "Unverified")
            ) + "</span>" + String(
                (
                    (
                        "<span>" + String(fmt(r.litres)) + " L · " + String(
                            money(r.cost, r.currency)
                        ) + "</span>"
                    )
                        if (r.`type == "fuel")
                        else ""
                )
            ) + "</div><details class=\"record-evidence\"><summary>Source &amp; evidence <span>" + String("Document attached" if r.document else "No document attached") + "</span></summary><p class=\"note\">Workspace record. Unverified source: " + String(esc(r.source)) + ". Notes and documents are private. Public listings include only the history you select.</p>" + String(
                (("<p>" + String(esc(r.notes)) + "</p>") if r.notes else "")
            ) + "<div class=\"record-tags\">" + String(
                (
                    (
                        "<a href=\"/api/files/" + String(
                            encodeURIComponent(r.document)
                        ) + "\" target=\"_blank\" rel=\"noopener\">View supporting document ↗</a>"
                    )
                        if r.document
                        else ""
                )
            ) + String(
                (
                    (
                        "<button class=\"btn text small\" data-correct=\"" + String(
                            r.id
                        ) + "\">Correct record</button>"
                    )
                        if (not r.superseded_by)
                        else ""
                )
            ) + "</div></details></div></article>"
        ); }
    ).join(
        ""
    );
}

def passportPage() -> any {
    v = vehicle();
    if (not v) {
        return (
            pageHead(
                "The vehicle passport.",
                "Its whole story, in one place.",
                registerButton
            ) + empty(
                "Add a vehicle to begin.",
                "A passport is created automatically for each vehicle.",
                registerButton
            )
        );
    }
    types = ["timeline", "maintenance", "documents"];
    content = timelineMarkup(v);
    if (passportTab == "maintenance") {
        content = timelineMarkup(
            {
                ** v,
                "records": v.records.filter(
                    lambda (r: any) -> any { return [
                        "maintenance",
                        "repair",
                        "inspection"
                    ].includes(
                        r.`type
                    ); }
                )
            }
        );
    }
    if (passportTab == "documents") {
        content = timelineMarkup(
            {
                ** v,
                "records": v.records.filter(
                    lambda (r: any) -> any { return r.document; }
                )
            }
        );
    }
    if (passportTab == "ai") {
        content = aiReviewPanel(v);
    }
    return (
        (
            pageHead(
                "Every chapter, together.",
                "A lifetime record. Its sources, milestones and supporting documents.",
                (
                    "<button class=\"btn primary\" data-action=\"record\">" + String(
                        icon("plus")
                    ) + " Add record</button>"
                )
            ) + selector()
        ) + (
            "<button class=\"passport-assistant-link\" data-action=\"open-assistant\">" + String(
                icon("spark")
            ) + " Explore this vehicle with Smartmoti " + String(icon("arrow")) + "</button><div class=\"passport-header\"><div class=\"passport-art\">" + String(
                carArt()
            ) + "</div><div class=\"passport-summary\"><span class=\"tag\">" + String(
                esc(v.plate)
            ) + "</span><h2>" + String(esc(v.make)) + " " + String(esc(v.model)) + "</h2><p class=\"muted\">" + String(
                v.year
            ) + " · A story still unfolding</p><div class=\"detail-grid\"><div><small>Recorded odometer</small><strong>" + String(
                fmt(v.odometer)
            ) + " km</strong></div><div><small>Lifetime entries</small><strong>" + String(
                v.records.length
            ) + " records</strong></div><div><small>VIN</small><strong>" + String(
                esc((v.vin or "Not recorded"))
            ) + "</strong></div><div><small>Tracking</small><strong>" + String(
                esc(v.tracking_status)
            ) + "</strong></div><div><small>NFT</small><strong>Not minted</strong></div><div><small>Record coverage</small><strong>" + String(
                (
                    dateLabel(v.records[(v.records.length - 1)].date)
                        if v.records.length
                        else "No history yet"
                )
            ) + "</strong></div></div><p class=\"privacy-notice\">" + String(icon("shield")) + " Private workspace · Notes, VIN and documents are excluded from marketplace history.</p></div></div><div class=\"section-head\"><div class=\"tabs\">" + String(
                types.map(
                    lambda (t: any) -> any { return (
                        "<button class=\"tab " + String(
                            ("active" if (passportTab == t) else "")
                        ) + "\" data-tab=\"" + String(t) + "\">" + String(
                            {
                                "timeline": "Lifetime timeline",
                                "maintenance": "Services & repairs",
                                "documents": "Documents",
                                "ai": "AI review"
                            }[t]
                        ) + "</button>"
                    ); }
                ).join(
                    ""
                )
            ) + "</div><button class=\"btn text small\" data-action=\"export\">" + String(
                icon("download")
            ) + " Export</button></div>" + String(content) + "<div class=\"panel\"><div class=\"section-head\"><h2>Optional NFT snapshot</h2><span class=\"tag neutral\">Separate from your records</span></div><p class=\"panel-copy\">Prepare a public metadata snapshot containing make, model and year. Private history, VIN and documents are excluded. Minting needs a configured contract and wallet; this local version prepares metadata only.</p><button class=\"btn small\" data-action=\"metadata\">Preview mint metadata " + String(
                icon("arrow")
            ) + "</button></div>"
        )
    );
}

def fuelPage() -> any {
    v = vehicle();
    if (not v) {
        return (
            pageHead(
                "Every fill adds up.",
                "Understand fuel use and running costs.",
                registerButton
            ) + empty(
                "Add a vehicle first.",
                "Fuel entries stay linked to its lifetime record.",
                registerButton
            )
        );
    }
    fuel = v.fuel_summary;
    entries = v.records.filter(
        lambda (r: any) -> any { return (
            (r.`type == "fuel") and (not r.superseded_by)
        ); }
    );
    return (
        (
            (
                pageHead(
                    "Every fill adds up.",
                    "Your refuelling ledger, with a clearer view of the cost.",
                    (
                        "<button class=\"btn primary\" data-action=\"fuel\">" + String(
                            icon("plus")
                        ) + " Log refuelling</button>"
                    )
                ) + selector()
            ) + stats(
                [
                    [
                        "Fuel recorded",
                        (String(fmt(fuel.total_litres)) + " <small>L</small>"),
                        "Across all fuel entries",
                        "fuel"
                    ],
                    [
                        "Fuel costs",
                        (
                            Object.entries(fuel.costs).map(
                                lambda (_pair3: any) -> any {
                                    c = _pair3[0];
                                    n = _pair3[1];
                                    return money(n, c);
                                }
                            ).join(
                                "<br>"
                            )
                            or "—"
                        ),
                        "Currencies kept separate",
                        "book"
                    ],
                    [
                        "Latest economy",
                        (
                            "—"
                                if (fuel.latest_economy == None)
                                else (
                                    String(fmt(fuel.latest_economy)) + " <small>L/100km</small>"
                                )
                        ),
                        "Last complete full-tank interval",
                        "leaf"
                    ],
                    ["Fuel entries", fuel.entries, "With litres and odometer", "clock"]
                ]
            )
        ) + (
            "<div class=\"fuel-callout\">Fuel economy uses complete full-tank intervals, including partial fills between them. Missing refuelling records affect the result. GPS mileage alone cannot measure fuel consumed.</div><section class=\"panel\"><h2>Refuelling ledger</h2>" + String(
                (
                    (
                        "<div class=\"table-wrap\"><table><thead><tr><th>Date</th><th>Odometer</th><th>Litres</th><th>Cost</th><th>Fill</th></tr></thead><tbody>" + String(
                            entries.map(
                                lambda (r: any) -> any { return (
                                    "<tr><td>" + String(dateLabel(r.date)) + "</td><td>" + String(
                                        fmt(r.odometer)
                                    ) + " km</td><td>" + String(fmt(r.litres)) + " L</td><td>" + String(
                                        money(r.cost, r.currency)
                                    ) + "</td><td><span class=\"tag " + String(
                                        ("" if r.full_tank else "neutral")
                                    ) + "\">" + String(
                                        ("Full tank" if r.full_tank else "Partial fill")
                                    ) + "</span></td></tr>"
                                ); }
                            ).join(
                                ""
                            )
                        ) + "</tbody></table></div>"
                    )
                        if entries.length
                        else empty(
                            "Your first fuel entry is a good start.",
                            "Record litres, cost and odometer. Mark full tanks so consumption can be calculated."
                        )
                )
            ) + "</section>" + String(
                (
                    (
                        "<section class=\"panel two-columns\"><div><h2>Completed fuel intervals</h2>" + String(
                            fuel.cycles.map(
                                lambda (c: any) -> any { return (
                                    "<div class=\"recent-row\"><div><strong>" + String(
                                        dateLabel(c.`from)
                                    ) + " → " + String(dateLabel(c.`to)) + "</strong><small>" + String(
                                        fmt(c.distance)
                                    ) + " km · " + String(fmt(c.litres)) + " L</small></div><strong>" + String(
                                        fmt(c.l_per_100km)
                                    ) + " L/100km</strong></div>"
                                ); }
                            ).join(
                                ""
                            )
                        ) + "</div><div><h2>Cost per kilometre</h2>" + String(
                            Object.entries(
                                fuel.cycles[(fuel.cycles.length - 1)].cost_per_km
                            ).map(
                                lambda (_pair4: any) -> any {
                                    code = _pair4[0];
                                    n = _pair4[1];
                                    return (
                                        "<p class=\"stat-value\">" + String(
                                            money(n, code)
                                        ) + " <small>/ km</small></p>"
                                    );
                                }
                            ).join(
                                ""
                            )
                        ) + "<p class=\"panel-copy\">Fuel added within the latest complete full-tank interval. Different currencies are shown separately.</p></div></section>"
                    )
                        if fuel.cycles.length
                        else ""
                )
            )
        )
    );
}

def aiReviewPanel(v: any) -> any {
    generated = aiReviews.get(v.id);
    review = (
        generated.result
            if ((generated != None and generated != globalThis.undefined))
            else globalThis.undefined
    );
    return (
        "<section class=\"panel ai-panel\"><div class=\"section-head\"><h2>A clearer reading of its story.</h2><span class=\"tag\">Gemini · Jac</span></div><p class=\"panel-copy\">AI summarizes recorded history and points out gaps. It cannot verify a record or diagnose the vehicle. Private documents, notes, VIN and tracking coordinates are excluded from the model context.</p><button class=\"btn primary\" data-action=\"ai-review\">" + String(
            ("Regenerate AI review" if generated else "Generate AI review")
        ) + " " + String(icon("arrow")) + "</button>" + String(
            (
                "<p class=\"note\">Open Settings to save your Gemini key and enable AI before generating.</p>"
                    if (
                        not (
                            state.ai.configured
                                if (
                                    (
                                        state.ai != None
                                        and state.ai != globalThis.undefined
                                    )
                                )
                                else globalThis.undefined
                        )
                    )
                    else ""
            )
        ) + String(
            (
                (
                    "<div class=\"ai-summary\"><span class=\"eyebrow\">AI-generated review · Check against the records</span><h3>History overview</h3><p>" + String(
                        esc(review.overview)
                    ) + "</p><h3>Highlights with evidence</h3>" + String(
                        review.highlights.map(
                            lambda (item: any) -> any { return (
                                "<article class=\"ai-highlight\"><p>" + String(
                                    esc(item.statement)
                                ) + "</p><div class=\"record-tags\">" + String(
                                    item.record_ids.map(
                                        lambda (id: any) -> any {
                                            r = v.records.find(
                                                lambda (r: any) -> any { return (
                                                    r.id == id
                                                ); }
                                            );
                                            return (
                                                "<span class=\"tag neutral\">" + String(
                                                    esc(
                                                        (
                                                            (
                                                                r.title
                                                                    if (
                                                                        (
                                                                            r != None
                                                                            and r != globalThis.undefined
                                                                        )
                                                                    )
                                                                    else globalThis.undefined
                                                            )
                                                            or "Record"
                                                        )
                                                    )
                                                ) + " · " + String(
                                                    (dateLabel(r.date) if r else "")
                                                ) + "</span>"
                                            );
                                        }
                                    ).join(
                                        ""
                                    )
                                ) + "</div></article>"
                            ); }
                        ).join(
                            ""
                        )
                    ) + "<h3>Gaps and uncertainties</h3>" + String(
                        (
                            (
                                "<ul>" + String(
                                    review.gaps.map(
                                        lambda (gap: any) -> any { return (
                                            "<li>" + String(esc(gap)) + "</li>"
                                        ); }
                                    ).join(
                                        ""
                                    )
                                ) + "</ul>"
                            )
                                if review.gaps.length
                                else "<p>No additional gaps were identified by the model. This does not establish a complete history.</p>"
                        )
                    ) + "<p class=\"note\">Generated by " + String(
                        esc(generated.model)
                    ) + " · " + String(
                        new(Date, generated.generated_at).toLocaleString(
                            "en-GB", {"timeZone": "Africa/Nairobi"}
                        )
                    ) + ". This review is separate from the vehicle timeline.</p></div>"
                )
                    if review
                    else empty(
                        "Let the records tell their story.",
                        "Generate a review from the recorded facts. No AI text will be presented until Gemini responds."
                    )
            )
        ) + "</section>"
    );
}


def issueForm() -> any {
    if not state.vehicles.length { notify("Add a vehicle before reviewing an issue."); return; }
    openModal("Describe a vehicle issue", "Possible causes from symptoms and recorded history. A qualified inspection is needed to confirm a diagnosis.",
        "<form data-form=\"issue\">" + String(selectField("vehicle_id", "Vehicle", state.vehicles.map(lambda (v: any) -> any { return [v.id, v.make + " " + v.model + " · " + v.year]; }), assistantVehicle or selected)) +
        "<div class=\"field\"><label for=\"issue-symptoms\">What is happening?</label><textarea id=\"issue-symptoms\" name=\"symptoms\" required minlength=\"10\" maxlength=\"2000\" placeholder=\"Describe the sound, warning lights, when it happens, and when it started.\"></textarea><small>Symptoms only. Leave out names, contacts, registration, VIN and location. Private notes and documents are excluded from the review.</small></div><p class=\"note\">This does not save a record or approve a repair. For an immediate safety concern, stop safely and seek professional assistance.</p><p class=\"form-error\" role=\"alert\"></p><p class=\"issue-progress\" role=\"status\" aria-live=\"polite\"></p><button class=\"btn primary full-width\" type=\"submit\">Review possible causes</button></form>"
    );
}

async def submitIssue(form: any) -> any {
    data = Object.fromEntries(new(FormData, form).entries());
    owner = state.user.id;
    generation = agentGeneration;
    submit = form.querySelector("[type=submit]");
    submit.disabled = True;
    form.querySelector(".form-error").textContent = "";
    form.querySelector(".issue-progress").textContent = "Reviewing symptoms and recorded history…";
    try {
        generated = await api("ai/diagnosis", data);
        if not state or state.user.id != owner or generation != agentGeneration { return; }
        issueAssessment = {"owner_id": owner, "vehicle_id": data.vehicle_id, "generated": generated};
        assistantVehicle = data.vehicle_id;
        page = "assistant";
        modal.close();
        render();
        document.querySelector("#issue-assessment").focus();
    } except Error as error {
        form.querySelector(".form-error").textContent = error.message;
    } finally {
        submit.disabled = False;
        form.querySelector(".issue-progress").textContent = "";
    }
}

def issuePanel() -> any {
    if not issueAssessment or issueAssessment.owner_id != state.user.id { return ""; }
    v = state.vehicles.find(lambda (v: any) -> any { return v.id == issueAssessment.vehicle_id; });
    if not v { return ""; }
    generated = issueAssessment.generated;
    review = generated.result;
    urgency = {"routine": "Routine inspection", "soon": "Arrange inspection soon", "stop_driving": "Stop safely and seek assistance"}[review.urgency];
    listItems = lambda (items: any) -> any { return "<ul>" + String(items.map(lambda (item: any) -> any { return "<li>" + String(esc(item)) + "</li>"; }).join("")) + "</ul>"; };
    return "<section class=\"issue-assessment panel\" id=\"issue-assessment\" tabindex=\"-1\"><div class=\"section-head\"><h2>Possible causes · " + String(esc(v.make)) + " " + String(esc(v.model)) + "</h2><span class=\"tag " + String("issue-danger" if review.urgency == "stop_driving" else "amber") + "\">" + String(urgency) + "</span></div><p class=\"issue-limit\">Remote troubleshooting, not a confirmed diagnosis. Reported history is unverified. A qualified mechanic must confirm the fault and driving safety.</p><p>" + String(esc(review.summary)) + "</p>" + String(review.possible_causes.map(lambda (cause: any) -> any {
        return "<article class=\"issue-cause\"><h3>" + String(esc(cause.cause)) + "</h3><p>" + String(esc(cause.reasoning)) + "</p><div class=\"issue-citations\">" + String(cause.record_ids.map(lambda (id: any) -> any {
            r = v.records.find(lambda (record: any) -> any { return record.id == id; });
            if not r { return ""; }
            return "<button class=\"btn text small\" data-evidence-record=\"" + String(esc(id)) + "\" data-evidence-vehicle=\"" + String(esc(v.id)) + "\">" + String(icon("book")) + String(esc(r.title)) + " · " + String(dateLabel(r.date)) + "</button>";
        }).join("")) + String("<span class=\"note\">Based on symptoms; no supporting history citation.</span>" if not cause.record_ids.length else "") + "</div></article>";
    }).join("")) + "<h3>Suggested next checks</h3>" + String(listItems(review.next_checks)) + String(("<h3>Questions to narrow this down</h3>" + listItems(review.questions)) if review.questions.length else "") + "<p class=\"note\">Generated by " + String(esc(generated.model)) + " · " + String(new(Date, generated.generated_at).toLocaleString("en-GB", {"timeZone": "Africa/Nairobi"})) + ". No vehicle record was changed.</p></section>";
}

def assistantPage() -> any {
    context = state.vehicles.find(
        lambda (v: any) -> any { return (v.id == assistantVehicle); }
    );
    prompts = [
        [
            "Understand fuel costs",
            "Look up the selected vehicle or search my garage, then explain recorded fuel economy and cost per kilometre using the fuel tool.",
            "fuel"
        ],
        [
            "Find the right records",
            "Which vehicles have repair or incident records? Look up the actual history.",
            "book"
        ],
        [
            "See the bigger picture",
            "Summarize ownership and maintenance in the selected vehicle history.",
            "car"
        ],
        [
            "Prepare a new chapter",
            "Help me record an inspection for the selected vehicle. Ask for the date, actual odometer and title before preparing it.",
            "plus"
        ],
        ["Log a refuel", "Help me log fuel for the selected vehicle. Ask for the date, actual odometer, litres, cost, currency and full or partial tank status before preparing it.", "fuel"],
        ["Correct a record", "Read the selected vehicle history and help me correct a record. Ask which record and which fields need changing; preserve the original.", "book"]
    ];
    messages = agentMessages.map(
        lambda (message: any) -> any { return (
            (
                "<article class=\"chat-message user\"><span class=\"chat-role\">You</span><p>" + String(
                    esc(message.text)
                ) + "</p></article>"
            )
                if (message.role == "user")
                else (
                    (
                        "<article class=\"chat-message error\" role=\"alert\"><span class=\"chat-role\">Request unavailable</span><p>" + String(
                            esc(message.text)
                        ) + "</p></article>"
                    )
                        if (message.role == "error")
                        else (
                            "<article class=\"chat-message assistant\"><span class=\"chat-role\">" + String(
                                icon("spark")
                            ) + " Smartmoti " + String(
                                ("· Run paused" if message.limited else "")
                            ) + "</span><p>" + String(esc(message.text)) + "</p>" + String(
                                (
                                    (
                                        "<details class=\"tool-trail\"><summary>" + String(
                                            message.trace.length
                                        ) + " steps · Data and actions used</summary>" + String(
                                            message.trace.map(
                                                lambda (step: any) -> any { return (
                                                    "<div>" + String(
                                                        icon(
                                                            (
                                                                "book"
                                                                    if (
                                                                        step.status == "read"
                                                                    )
                                                                    else (
                                                                        "close"
                                                                            if (
                                                                                step.status == "error"
                                                                            )
                                                                            else "check"
                                                                    )
                                                            )
                                                        )
                                                    ) + "<span>" + String(
                                                        esc(step.label)
                                                    ) + "</span><span class=\"tag neutral\">" + String(
                                                        esc(step.status)
                                                    ) + "</span></div>"
                                                ); }
                                            ).join(
                                                ""
                                            )
                                        ) + "</details>"
                                    )
                                        if (
                                            message.trace.length
                                                if (
                                                    (
                                                        message.trace != None
                                                        and message.trace != globalThis.undefined
                                                    )
                                                )
                                                else globalThis.undefined
                                        )
                                        else ""
                                )
                            ) + String(
                                (
                                    (
                                        message.proposals.map(
                                            lambda (proposal: any) -> any { return proposalCard(
                                                proposal
                                            ); }
                                        ).join(
                                            ""
                                        )
                                            if (
                                                (
                                                    message.proposals != None
                                                    and message.proposals != globalThis.undefined
                                                )
                                            )
                                            else globalThis.undefined
                                    )
                                    or ""
                                )
                            ) + "</article>"
                        )
                )
        ); }
    ).join(
        ""
    );
    return (
        "<div class=\"assistant-layout\"><section class=\"assistant-main\"><div class=\"assistant-heading\"><span class=\"assistant-emblem\">" + String(
            icon("spark")
        ) + "</span><div><span class=\"eyebrow\">YOUR VEHICLE ASSISTANT</span><h1>A little help.<br><em>A clearer garage.</em></h1><p>Ask in plain language. Find the facts. Shape the next chapter.</p></div></div><div class=\"assistant-tools\"><button class=\"btn\" data-action=\"issue\">" + String(icon("service")) + " Describe a vehicle issue</button><p class=\"note\">Review symptoms alongside the selected vehicle’s history for possible causes and next checks.</p></div>" + String(
            (
                (
                    "<div class=\"prompt-grid\">" + String(
                        prompts.map(
                            lambda (_pair5: any) -> any {
                                label = _pair5[0];
                                prompt = _pair5[1];
                                name = _pair5[2];
                                return (
                                    "<button class=\"prompt-card\" data-agent-prompt=\"" + String(
                                        esc(prompt)
                                    ) + "\">" + String(icon(name)) + "<strong>" + String(
                                        label
                                    ) + "</strong><span>" + String(esc(prompt)) + "</span>" + String(
                                        icon("arrow")
                                    ) + "</button>"
                                );
                            }
                        ).join(
                            ""
                        )
                    ) + "</div>"
                )
                    if (not agentMessages.length)
                    else (
                        "<div class=\"chat-thread\" aria-live=\"polite\">" + String(
                            messages
                        ) + String(
                            (
                                "<div class=\"agent-working\"><span class=\"dot\"></span> Working through your request...</div>"
                                    if agentBusy
                                    else ""
                            )
                        ) + "</div>"
                    )
            )
        ) + String(issuePanel()) + "<form class=\"agent-composer\" data-form=\"agent\"><label for=\"agent-message\" class=\"sr-only\">Message Smartmoti</label><textarea id=\"agent-message\" name=\"message\" maxlength=\"2000\" rows=\"2\" placeholder=\"Describe a vehicle issue, ask about history, or prepare a record...\" " + String(
            ("disabled" if agentBusy else "")
        ) + ">" + String(esc(agentDraft)) + "</textarea><div class=\"composer-foot\"><span>" + String(
            icon("shield")
        ) + " Changes wait for your review</span><button class=\"btn primary small\" type=\"submit\" " + String(
            (
                "disabled"
                    if (
                        agentBusy
                        or (
                            not (
                                state.ai.available
                                    if (
                                        (
                                            state.ai != None
                                            and state.ai != globalThis.undefined
                                        )
                                    )
                                    else globalThis.undefined
                            )
                        )
                    )
                    else ""
            )
        ) + ">" + String(("Working..." if agentBusy else "Ask Smartmoti")) + " " + String(
            icon("arrow")
        ) + "</button></div></form><p class=\"assistant-note\">" + String(
            (
                "Gemini uses authorized tool results. Private documents, stored notes, VIN and GPS stay outside its context."
                    if (
                        state.ai.available
                            if ((state.ai != None and state.ai != globalThis.undefined))
                            else globalThis.undefined
                    )
                    else "Configure your personal Gemini key or enable AI in Settings to start a conversation."
            )
        ) + "</p></section><aside class=\"assistant-context\"><div class=\"context-head\"><span class=\"eyebrow\">IN CONTEXT</span><span class=\"tag " + String(
            (
                ""
                    if (
                        state.ai.available
                            if ((state.ai != None and state.ai != globalThis.undefined))
                            else globalThis.undefined
                    )
                    else "amber"
            )
        ) + "\">" + String(
            (
                "Gemini ready"
                    if (
                        state.ai.available
                            if ((state.ai != None and state.ai != globalThis.undefined))
                            else globalThis.undefined
                    )
                    else "Setup needed"
            )
        ) + "</span></div><label for=\"assistant-context\">Focus this conversation</label><select class=\"vehicle-selector\" id=\"assistant-context\"><option value=\"\">Entire garage</option>" + String(
            state.vehicles.map(
                lambda (v: any) -> any { return (
                    "<option value=\"" + String(v.id) + "\" " + String(
                        ("selected" if (v.id == assistantVehicle) else "")
                    ) + ">" + String(esc(v.make)) + " " + String(esc(v.model)) + "</option>"
                ); }
            ).join(
                ""
            )
        ) + "</select>" + String(
            (
                (
                    "<div class=\"context-vehicle\">" + String(carArt()) + "<h2>" + String(
                        esc(context.make)
                    ) + " " + String(esc(context.model)) + "</h2><p>" + String(
                        context.year
                    ) + " · " + String(fmt(context.odometer)) + " km</p><span class=\"tag neutral\">" + String(
                        context.records.filter(
                            lambda (r: any) -> any { return (not r.superseded_by); }
                        ).length
                    ) + " current records</span></div>"
                )
                    if context
                    else "<p class=\"panel-copy\">Search and compare the vehicles in your garage. The assistant will retrieve current data before answering.</p>"
            )
        ) + "<div class=\"assistant-capabilities\"><h3>Read with context</h3><p>Find vehicles, explore timelines, compare fuel costs and look up listings.</p><h3>Write with your say</h3><p>Prepare vehicle registrations, records, fuel entries and eligible corrections. Review the exact fields before saving.</p></div><button class=\"btn small full-width\" data-action=\"agent-review-history\" " + String(
            ("disabled" if (not selected) else "")
        ) + ">Detailed history review " + String(icon("arrow")) + "</button><button class=\"btn text small full-width\" data-action=\"agent-new\" " + String(
            ("disabled" if agentBusy else "")
        ) + ">New conversation</button></aside></div>"
    );
}

def proposalCard(proposal: any) -> any {
    labels = {
        "vehicle": "Vehicle",
        "replaces": "Replaces preserved record",
        "plate": "Registration",
        "make": "Make",
        "model": "Model",
        "year": "Year",
        "initial_odometer": "Starting odometer (km)",
        "type": "Record type",
        "title": "Title",
        "date": "Date",
        "odometer": "Odometer (km)",
        "source": "Source",
        "litres": "Litres",
        "cost": "Total cost",
        "currency": "Currency",
        "full_tank": "Full tank",
        "corrects": "Original record"
    };
    return (
        "<section class=\"proposal-card\"><div class=\"section-head\"><span class=\"eyebrow\">" + String(
            ("PROPOSED CHANGE" if (proposal.status == "pending") else "CHANGE STATUS")
        ) + "</span><span class=\"tag " + String(
            ("amber" if (proposal.status == "pending") else "neutral")
        ) + "\">" + String(esc(proposal.status)) + "</span></div><h3>" + String(
            esc(proposal.summary)
        ) + "</h3><dl>" + String(
            Object.entries(proposal.preview).filter(
                lambda (_pair6: any) -> any {
                    key = _pair6[0];
                    value = _pair6[1];
                    return ((value != "") and (key != "corrects"));
                }
            ).map(
                lambda (_pair7: any) -> any {
                    key = _pair7[0];
                    value = _pair7[1];
                    return (
                        "<div><dt>" + String((labels[key] or esc(key))) + "</dt><dd>" + String(
                            esc(
                                (
                                    ("Yes" if value else "No")
                                        if (
                                            (value == True or value == False)
                                        )
                                        else value
                                )
                            )
                        ) + "</dd></div>"
                    );
                }
            ).join(
                ""
            )
        ) + "</dl>" + String(
            (
                (
                    "<p class=\"note\">Nothing has been saved. Check each field before approving.</p><div class=\"modal-actions\"><button class=\"btn small\" data-agent-reject=\"" + String(
                        proposal.id
                    ) + "\">Discard proposal</button><button class=\"btn primary small\" data-agent-approve=\"" + String(
                        proposal.id
                    ) + "\">Approve and save " + String(icon("check")) + "</button></div>"
                )
                    if (proposal.status == "pending")
                    else (
                        "<p class=\"note\">" + String(
                            (
                                "Saved through the validated Jac workflow."
                                    if (proposal.status == "applied")
                                    else (
                                        "Data changed. Ask for a fresh proposal."
                                            if (proposal.status == "stale")
                                            else "This proposal will not be applied."
                                    )
                            )
                        ) + "</p>"
                    )
            )
        ) + String(("<button class=\"btn small\" data-agent-view=\"" + esc(proposal.vehicle_id) + "\">View saved vehicle passport</button>") if (proposal.status == "applied" and proposal.vehicle_id) else "") + "</section>"
    );
}

async def sendAgentMessage() -> any {
    generation = agentGeneration;
    message = agentDraft.trim();
    if ((not message) or agentBusy) {
        return;
    }
    agentMessages.push({"role": "user", "text": message});
    agentDraft = "";
    agentBusy = True;
    render();
    try {
        response = (
            await api(
                "agent/chat",
                {
                    "message": message,
                    "vehicle_id": (assistantVehicle or None),
                    "session_id": agentSession
                }
            )
        );
        if (generation != agentGeneration) {
            return;
        }
        agentSession = response.session_id;
        agentMessages.push(
            {
                "role": "assistant",
                "text": response.answer,
                "trace": response.trace,
                "proposals": response.proposals,
                "limited": response.limited
            }
        );
    } except Error as error {
        if (generation == agentGeneration) {
            agentMessages.push({"role": "error", "text": error.message});
        }
    } finally {
        if (generation == agentGeneration) {
            agentBusy = False;
            render();
            (
                document.querySelector("#agent-message").focus()
                    if (
                        (
                            document.querySelector("#agent-message") != None
                            and document.querySelector("#agent-message") != globalThis.undefined
                        )
                    )
                    else globalThis.undefined
            );
        }
    }
}

async def decideProposal(id: any, approve: any, button: any) -> any {
    proposal = agentMessages.flatMap(
        lambda (m: any) -> any { return (m.proposals or []); }
    ).find(
        lambda (p: any) -> any { return (p.id == id); }
    );
    if ((not proposal) or (proposal.status != "pending")) {
        return;
    }
    button.disabled = True;
    try {
        result = (
            await api(
                ("agent/approve" if approve else "agent/reject"), {"proposal_id": id}
            )
        );
        proposal.status = result.status;
        if approve {
            if result.result and result.result.make {
                proposal.vehicle_id = result.result.id;
                assistantVehicle = result.result.id;
                selected = result.result.id;
            }
            agentMessages.forEach(lambda(m: any) -> any {
                (m.proposals or []).forEach(lambda(p: any) -> any {
                    if p.id != id and p.status == "pending" { p.status = "stale"; }
                });
            });
        }
        aiReviews.clear();
        (await refresh());
        notify(("Change approved and saved." if approve else "Proposal discarded."));
    } except Error as error {
        if (error.status == 409) {
            proposal.status = "stale";
        }
        notify(error.message);
        render();
    }
}

async def restoreAgentConversation() -> any {
    generation = agentGeneration;
    owner = state.user.id;
    response = await api("agent/conversation");
    if generation != agentGeneration or not state or state.user.id != owner or agentBusy { return; }
    agentSession = response.session_id;
    agentMessages = response.messages;
    if state.vehicles.some(lambda(v: any) -> any { return v.id == response.vehicle_id; }) {
        assistantVehicle = response.vehicle_id;
    }
}

def trackingPage() -> any {
    v = vehicle();
    if (not v) {
        return (
            pageHead(
                "Know where its story goes.",
                "Tracker observations, kept separate from reported history.",
                registerButton
            ) + empty(
                "Add a vehicle first.",
                "You can keep vehicle records without a tracker.",
                registerButton
            )
        );
    }
    journey = (
        v.telemetry.journey
            if (
                state.user.demo
                and (
                    (
                        v.telemetry.source
                            if (
                                (
                                    v.telemetry != None
                                    and v.telemetry != globalThis.undefined
                                )
                            )
                            else globalThis.undefined
                    ) == "demo"
                )
            )
            else None
    );
    if journey {
        return (
            (
                pageHead(
                    "A journey in its story.",
                    "An illustrative tracking example. No live GPS connection is used."
                ) + selector()
            ) + (
                "<div class=\"fuel-callout\">DEMO TRACKING · This sample route, distance and observation are fixtures for the presentation. The route diagram is schematic, not a geographic map.</div><div class=\"tracking-grid\"><section class=\"demo-route\"><span class=\"eyebrow\">Sample journey / " + String(
                    dateLabel(journey.date)
                ) + "</span><svg viewBox=\"0 0 600 280\" role=\"img\" aria-label=\"Illustrative route diagram from Nairobi to Naivasha\"><path class=\"route-road\" d=\"M0 85 120 105 200 50 320 80 600 60M20 280 130 190 180 110 350 140 430 40M220 280 280 150 400 180 600 220\"/><path class=\"route-line\" d=\"M85 215 C140 215 130 165 205 160 S290 110 335 120 S390 70 490 70\"/><circle cx=\"85\" cy=\"215\" r=\"9\"/><circle cx=\"490\" cy=\"70\" r=\"9\"/><text x=\"65\" y=\"250\">Nairobi</text><text x=\"450\" y=\"44\">Naivasha</text><circle cx=\"335\" cy=\"120\" r=\"5\"/></svg><span class=\"tag demo\">Illustrative route · " + String(
                    esc(journey.status)
                ) + "</span></section><section class=\"panel\"><h2>Sample trip summary</h2><div class=\"detail-grid\"><div><small>Distance</small><strong>" + String(
                    fmt(journey.distance_km)
                ) + " km</strong></div><div><small>Duration</small><strong>" + String(
                    journey.duration_minutes
                ) + " minutes</strong></div><div><small>Reported speed</small><strong>" + String(
                    v.telemetry.speed
                ) + " km/h</strong></div><div><small>Sample device</small><strong>" + String(
                    esc(journey.device)
                ) + "</strong></div><div><small>Observation source</small><strong>Demo fixture</strong></div><div><small>Status</small><strong>" + String(
                    esc(journey.status)
                ) + "</strong></div></div><p class=\"panel-copy\">In a connected version, provider observations will carry timestamps and freshness status. The device remains separate from the vehicle identity.</p><p class=\"note\">This route does not measure fuel consumption. Fuel economy comes from the refuelling ledger.</p></section></div>"
            )
        );
    }
    return (
        (
            pageHead(
                "Know where its story goes.",
                "Tracking is optional. Its sources and freshness should always be clear."
            ) + selector()
        ) + (
            "<div class=\"tracking-grid\"><div class=\"tracking-map\"><div>" + String(
                icon("pin")
            ) + "<strong>" + String(esc(v.tracking_status)) + "</strong><p>No live tracker is connected to this local workspace. Vehicle records and fuel logging remain available.</p></div></div><section class=\"panel\"><h2>Tracking integration</h2><span class=\"tag neutral\">Awaiting provider setup</span><p class=\"panel-copy\">Protrack and IOPGPS adapters from Omni are the next integration step. Connect an account and assign its device to this vehicle before showing live positions.</p><div class=\"recent-row\">" + String(
                icon("clock")
            ) + "<div><strong>Freshness matters</strong><small>Old readings should never appear as current.</small></div></div><div class=\"recent-row\">" + String(
                icon("car")
            ) + "<div><strong>A tracker is not the vehicle</strong><small>Device reassignment preserves the vehicle's history.</small></div></div><p class=\"note\">Measured fuel levels require a compatible sensor and provider fields. This version uses your refuelling ledger.</p></section></div>"
        )
    );
}

def marketPage() -> any {
    listings = state.market.filter(
        lambda (l: any) -> any { return (
            String(l.make) + " " + String(l.model) + " " + String(l.location)
        ).toLowerCase().includes(
            marketQuery.toLowerCase()
        ); }
    );
    return (
        pageHead(
            "A new owner. A clearer story.",
            "Explore vehicles with selected history shared by their sellers.",
            (
                "<div class=\"head-actions\"><a class=\"btn\" href=\"/market\" target=\"_blank\" rel=\"noopener\">Public marketplace ↗</a><button class=\"btn primary\" data-action=\"listing\">" + String(
                    icon("plus")
                ) + " List a vehicle</button></div>"
            )
        ) + (
            "<div class=\"market-toolbar\"><input class=\"search\" id=\"market-search\" aria-label=\"Search marketplace\" placeholder=\"Search make, model or town…\" value=\"" + String(
                esc(marketQuery)
            ) + "\"><span class=\"tag neutral\">" + String(listings.length) + " listings</span></div>" + String(
                (
                    (
                        "<div class=\"vehicle-grid\">" + String(
                            listings.map(
                                lambda (l: any, i: any) -> any { return (
                                    "<article class=\"vehicle-card\"><div class=\"vehicle-visual\"><span class=\"tag\">" + String(
                                        esc(l.location)
                                    ) + " " + String(("· Demo" if l.demo else "")) + "</span>" + String(
                                        carArt(
                                            ["#bdb9ad", "#aab0ad", "#b8aba0"][(i % 3)]
                                        )
                                    ) + "</div><div class=\"vehicle-info\"><h3>" + String(
                                        esc(l.make)
                                    ) + " " + String(esc(l.model)) + "</h3><div class=\"vehicle-meta\"><span>" + String(
                                        l.year
                                    ) + "</span><span>· " + String(fmt(l.odometer)) + " km</span></div><div class=\"market-price\">" + String(
                                        money(l.price, l.currency)
                                    ) + "</div><p class=\"note\">" + String(
                                        l.history.length
                                    ) + " shared history records · " + String(
                                        esc(l.seller)
                                    ) + "</p><div class=\"card-footer\"><span class=\"tag neutral\">" + String(
                                        esc(l.status)
                                    ) + "</span><button class=\"btn text small\" data-listing=\"" + String(
                                        l.id
                                    ) + "\">View details " + String(icon("arrow")) + "</button></div></div></article>"
                                ); }
                            ).join(
                                ""
                            )
                        ) + "</div>"
                    )
                        if listings.length
                        else empty(
                            "Room for the next chapter.",
                            "List a vehicle and choose which history records a buyer can see."
                        )
                )
            ) + "<section class=\"panel two-columns\"><div><h2>Your listings</h2>" + String(
                (
                    state.listings.map(
                        lambda (l: any) -> any { return (
                            "<div class=\"recent-row\"><div><strong>" + String(
                                esc(l.make)
                            ) + " " + String(esc(l.model)) + "</strong><small>" + String(
                                money(l.price)
                            ) + " · " + String(esc(l.status)) + "</small></div>" + String(
                                (
                                    (
                                        "<button class=\"btn small\" data-manage=\"" + String(
                                            l.id
                                        ) + "\">Manage</button>"
                                    )
                                        if (
                                            (l.status == "active")
                                            or (l.status == "reserved")
                                        )
                                        else ""
                                )
                            ) + "</div>"
                        ); }
                    ).join(
                        ""
                    )
                        if state.listings.length
                        else "<p class=\"panel-copy\">Your listings will appear here.</p>"
                )
            ) + "</div><div><h2>Offers</h2>" + String(
                (
                    state.offers.map(
                        lambda (o: any) -> any { return (
                            "<div class=\"offer-row\"><strong>" + String(
                                money(o.amount)
                            ) + "</strong><span class=\"tag neutral\">" + String(
                                (
                                    "Sent"
                                        if (o.buyer_id == state.user.id)
                                        else "Received"
                                )
                            ) + " · " + String(esc(o.status)) + "</span><p>" + String(
                                esc(o.message)
                            ) + "</p></div>"
                        ); }
                    ).join(
                        ""
                    )
                        if state.offers.length
                        else "<p class=\"panel-copy\">Offers you send or receive will appear here. No payment is taken through this local marketplace.</p>"
                )
            ) + "</div></section>"
        )
    );
}

def field(
    name: any, label: any, `type: any = "text", value: any = "", extra: any = ""
) -> any {
    return (
        "<div class=\"field\"><label for=\"f-" + String(name) + "\">" + String(label) + "</label><input id=\"f-" + String(
            name
        ) + "\" name=\"" + String(name) + "\" type=\"" + String(`type) + "\" value=\"" + String(
            esc(value)
        ) + "\" " + String(extra) + "></div>"
    );
}

def selectField(name: any, label: any, options: any, value: any = "") -> any {
    return (
        "<div class=\"field\"><label for=\"f-" + String(name) + "\">" + String(label) + "</label><select name=\"" + String(
            name
        ) + "\" id=\"f-" + String(name) + "\">" + String(
            options.map(
                lambda (_pair8: any) -> any {
                    id = _pair8[0];
                    label = _pair8[1];
                    return (
                        "<option value=\"" + String(esc(id)) + "\" " + String(
                            ("selected" if (id == value) else "")
                        ) + ">" + String(esc(label)) + "</option>"
                    );
                }
            ).join(
                ""
            )
        ) + "</select></div>"
    );
}

def openModal(title: any, subtitle: any, content: any) -> any {
    modal.innerHTML = (
        "<button class=\"modal-close\" data-action=\"close\" aria-label=\"Close dialog\">" + String(
            icon("close")
        ) + "</button><h2 class=\"modal-heading\" id=\"modal-title\">" + String(
            title
        ) + "</h2><p class=\"modal-sub\">" + String(subtitle) + "</p>" + String(content)
    );
    if (not modal.open) {
        modal.showModal();
    }
}

def formWrap(kind: any, content: any, label: any, extra: any = "") -> any {
    return (
        "<form data-form=\"" + String(kind) + "\">" + String(extra) + "<div class=\"form-error\" role=\"alert\"></div>" + String(
            content
        ) + "<div class=\"modal-actions\"><button class=\"btn\" type=\"button\" data-action=\"close\">Cancel</button><button class=\"btn primary\" type=\"submit\">" + String(
            label
        ) + " " + String(icon("arrow")) + "</button></div></form>"
    );
}

def auth(mode: any) -> any {
    authMode = mode;
    openModal(
        ("Start your vehicle story." if (mode == "signup") else "Back to your garage."),
        (
            "Create a local account. Your new workspace starts with a clean slate."
                if (mode == "signup")
                else "Your vehicle records are waiting where you left them."
        ),
        (
            "<form data-form=\"auth\"><div class=\"form-error\" role=\"alert\"></div>" + String(
                (
                    field(
                        "name",
                        "Your name",
                        "text",
                        "",
                        "required autocomplete=\"name\" maxlength=\"80\""
                    )
                        if (mode == "signup")
                        else ""
                )
            ) + String(
                field(
                    "email",
                    "Email address",
                    "email",
                    "",
                    "required autocomplete=\"email\""
                )
            ) + String(
                field(
                    "password",
                    "Password",
                    "password",
                    "",
                    (
                        (
                            "required minlength=\"8\" maxlength=\"200\" autocomplete=\"" + (
                                "new-password"
                                    if (mode == "signup")
                                    else "current-password"
                            )
                        ) + "\""
                    )
                )
            ) + "<button class=\"btn primary full-width\" type=\"submit\">" + String(
                ("Create your garage" if (mode == "signup") else "Sign in")
            ) + " " + String(icon("arrow")) + "</button></form><div class=\"auth-switch\">" + String(
                (
                    "Already have a garage?"
                        if (mode == "signup")
                        else "New to Smartmoti?"
                )
            ) + " <button data-action=\"" + String(
                ("login" if (mode == "signup") else "signup")
            ) + "\">" + String(
                ("Sign in" if (mode == "signup") else "Create an account")
            ) + "</button></div>"
        )
    );
}

def vehicleForm() -> any {
    openModal(
        "A new chapter.",
        "Add a vehicle to your garage. You can build its history over time.",
        formWrap(
            "vehicle",
            (
                "<div class=\"form-grid\">" + String(
                    field(
                        "plate",
                        "Registration",
                        "text",
                        "",
                        "required maxlength=\"30\" placeholder=\"KDK 482A\""
                    )
                ) + String(
                    field("vin", "VIN (optional)", "text", "", "maxlength=\"40\"")
                ) + String(
                    field(
                        "make",
                        "Make",
                        "text",
                        "",
                        "required maxlength=\"60\" placeholder=\"Toyota\""
                    )
                ) + String(
                    field(
                        "model",
                        "Model",
                        "text",
                        "",
                        "required maxlength=\"60\" placeholder=\"Hilux\""
                    )
                ) + String(
                    field(
                        "year",
                        "Year",
                        "number",
                        new(Date).getFullYear(),
                        (
                            (
                                "required min=\"1886\" max=\"" + new(Date).getFullYear()
                            ) + "\" step=\"1\""
                        )
                    )
                ) + String(
                    field(
                        "odometer",
                        "Starting odometer (km)",
                        "number",
                        0,
                        "required min=\"0\" max=\"10000000\" step=\"1\""
                    )
                ) + "</div>"
            ),
            "Add vehicle"
        )
    );
}

def recordForm(fuel: any = False, correctId: any = None) -> any {
    v = vehicle();
    if (not v) {
        return notify("Add a vehicle first.");
    }
    original = v.records.find(lambda (r: any) -> any { return (r.id == correctId); });
    if original {
        fuel = original.`type == "fuel";
    }
    types = [
        "acquisition",
        "maintenance",
        "repair",
        "inspection",
        "incident",
        "odometer",
        "ownership",
        "retirement"
    ];
    selectedType = (
        (
            original.`type
                if ((original != None and original != globalThis.undefined))
                else globalThis.undefined
        )
        or "maintenance"
    );
    openModal(
        (
            "Correct a record."
                if original
                else ("One more fill." if fuel else "Keep the story going.")
        ),
        (
            "The original remains in the timeline. This entry becomes its correction."
                if original
                else (
                    String(esc(v.plate)) + " · " + String(
                        (
                            "Record litres, cost and an odometer reading."
                                if fuel
                                else "Record what happened and where the information came from."
                        )
                    )
                )
        ),
        formWrap(
            "record",
            (
                String(
                    (
                        "<input name=\"type\" value=\"fuel\" type=\"hidden\">"
                            if fuel
                            else selectField(
                                "type",
                                "Record type",
                                types.map(
                                    lambda (t: any) -> any { return [
                                        t,
                                        (t.charAt(0).toUpperCase() + t.slice(1))
                                    ]; }
                                ),
                                selectedType
                            )
                    )
                ) + "<div class=\"form-grid\">" + String(
                    field(
                        "date",
                        "Record date",
                        "date",
                        (
                            (
                                original.date
                                    if (
                                        (
                                            original != None
                                            and original != globalThis.undefined
                                        )
                                    )
                                    else globalThis.undefined
                            )
                            or today()
                        ),
                        (("required max=\"" + today()) + "\"")
                    )
                ) + String(
                    field(
                        "odometer",
                        "Odometer (km)",
                        "number",
                        (
                            (
                                original.odometer
                                    if (
                                        (
                                            original != None
                                            and original != globalThis.undefined
                                        )
                                    )
                                    else globalThis.undefined
                            )
                                if (
                                    (
                                        original.odometer
                                            if (
                                                (
                                                    original != None
                                                    and original != globalThis.undefined
                                                )
                                            )
                                            else globalThis.undefined
                                    ) != None
                                    and (
                                        original.odometer
                                            if (
                                                (
                                                    original != None
                                                    and original != globalThis.undefined
                                                )
                                            )
                                            else globalThis.undefined
                                    ) != globalThis.undefined
                                )
                                else v.odometer
                        ),
                        "required min=\"0\" step=\"1\""
                    )
                ) + "</div>" + String(
                    field(
                        "title",
                        "Record title",
                        "text",
                        (
                            (
                                original.title
                                    if (
                                        (
                                            original != None
                                            and original != globalThis.undefined
                                        )
                                    )
                                    else globalThis.undefined
                            )
                            or ("Refuelling" if fuel else "")
                        ),
                        "required maxlength=\"140\""
                    )
                ) + String(
                    (
                        (
                            "<div class=\"form-grid\">" + String(
                                field(
                                    "litres",
                                    "Litres added",
                                    "number",
                                    (
                                        (
                                            original.litres
                                                if (
                                                    (
                                                        original != None
                                                        and original != globalThis.undefined
                                                    )
                                                )
                                                else globalThis.undefined
                                        )
                                        or ""
                                    ),
                                    "required min=\"0.01\" max=\"3000\" step=\"0.01\""
                                )
                            ) + String(
                                field(
                                    "cost",
                                    "Total fuel cost",
                                    "number",
                                    (
                                        (
                                            original.cost
                                                if (
                                                    (
                                                        original != None
                                                        and original != globalThis.undefined
                                                    )
                                                )
                                                else globalThis.undefined
                                        )
                                        or ""
                                    ),
                                    "required min=\"0.01\" step=\"0.01\""
                                )
                            ) + "</div>" + String(
                                selectField(
                                    "currency",
                                    "Currency",
                                    ["KES", "USD", "UGX", "TZS", "EUR", "GBP"].map(
                                        lambda (c: any) -> any { return [c, c]; }
                                    ),
                                    (
                                        (
                                            (
                                                original.currency
                                                    if (
                                                        (
                                                            original != None
                                                            and original != globalThis.undefined
                                                        )
                                                    )
                                                    else globalThis.undefined
                                            )
                                            or (
                                                state.settings.currency
                                                    if (
                                                        (
                                                            state.settings != None
                                                            and state.settings != globalThis.undefined
                                                        )
                                                    )
                                                    else globalThis.undefined
                                            )
                                        )
                                        or "KES"
                                    )
                                )
                            ) + "<label class=\"check-row\"><input type=\"checkbox\" name=\"full_tank\" " + String(
                                (
                                    "checked"
                                        if (
                                            original.full_tank
                                                if (
                                                    (
                                                        original != None
                                                        and original != globalThis.undefined
                                                    )
                                                )
                                                else globalThis.undefined
                                        )
                                        else ""
                                )
                            ) + ">Tank was full after this fill</label>"
                        )
                            if fuel
                            else ""
                    )
                ) + String(
                    selectField(
                        "source",
                        "Record source",
                        [
                            "Owner reported",
                            "Workshop reported",
                            "Document reference"
                        ].map(
                            lambda (s: any) -> any { return [s, s]; }
                        ),
                        (
                            (
                                original.source
                                    if (
                                        (
                                            original != None
                                            and original != globalThis.undefined
                                        )
                                    )
                                    else globalThis.undefined
                            )
                            or "Owner reported"
                        )
                    )
                ) + "<div class=\"field\"><label for=\"f-notes\">Notes (optional)</label><textarea name=\"notes\" id=\"f-notes\" maxlength=\"3000\">" + String(
                    esc(
                        (
                            (
                                original.notes
                                    if (
                                        (
                                            original != None
                                            and original != globalThis.undefined
                                        )
                                    )
                                    else globalThis.undefined
                            )
                            or ""
                        )
                    )
                ) + "</textarea></div><div class=\"field\"><label for=\"f-file\">Supporting document (optional)</label><input id=\"f-file\" name=\"file\" type=\"file\" accept=\"application/pdf,image/png,image/jpeg\"><small>PDF, PNG or JPEG, up to 5 MB. Documents stay private.</small></div>"
            ),
            "Save record",
            (
                "<input name=\"vehicle_id\" value=\"" + String(v.id) + "\" type=\"hidden\"><input name=\"corrects\" value=\"" + String(
                    (correctId or "")
                ) + "\" type=\"hidden\"><input name=\"document\" value=\"" + String(
                    esc(
                        (
                            (
                                original.document
                                    if (
                                        (
                                            original != None
                                            and original != globalThis.undefined
                                        )
                                    )
                                    else globalThis.undefined
                            )
                            or ""
                        )
                    )
                ) + "\" type=\"hidden\">"
            )
        )
    );
}

def listingForm() -> any {
    if (not state.vehicles.length) {
        return notify("Add a vehicle before creating a listing.");
    }
    options = state.vehicles.map(
        lambda (v: any) -> any { return [
            v.id,
            (String(v.plate) + " · " + String(v.make) + " " + String(v.model))
        ]; }
    );
    openModal(
        "Ready for its next chapter.",
        "Publish a listing. Only the history you select below will be shared.",
        formWrap(
            "listing",
            (
                String(selectField("vehicle_id", "Vehicle", options, selected)) + "<div class=\"form-grid\">" + String(
                    field(
                        "price",
                        "Asking price (KES)",
                        "number",
                        "",
                        "required min=\"1\" max=\"1000000000\" step=\"1\""
                    )
                ) + String(
                    field("location", "Town", "text", "", "required maxlength=\"80\"")
                ) + "</div><div class=\"field\"><label for=\"f-description\">Description</label><textarea name=\"description\" id=\"f-description\" required maxlength=\"2000\"></textarea><button class=\"btn small\" type=\"button\" data-action=\"ai-draft\">Draft with Gemini</button><small>AI uses vehicle details and only the history you select below. Review the draft before publishing.</small></div><div class=\"field\"><label>History to share</label><small>Titles, dates, odometer and sources only. Notes, documents and location history remain private.</small></div><div id=\"share-options\"></div>"
            ),
            "Publish listing"
        )
    );
    updateShareOptions((selected or state.vehicles[0].id));
}

def updateShareOptions(id: any) -> any {
    v = state.vehicles.find(lambda (v: any) -> any { return (v.id == id); });
    document.querySelector("#share-options").innerHTML = (
        v.records.filter(lambda (r: any) -> any { return (not r.superseded_by); }).map(
            lambda (r: any) -> any { return (
                "<label class=\"check-row\"><input type=\"checkbox\" name=\"shared\" value=\"" + String(
                    r.id
                ) + "\">" + String(esc(r.title)) + " · " + String(dateLabel(r.date)) + "</label>"
            ); }
        ).join(
            ""
        )
        or "<p class=\"note\">No history records yet. You can still publish a listing.</p>"
    );
}

def listingDetails(id: any) -> any {
    l = state.market.find(lambda (l: any) -> any { return (l.id == id); });
    if (not l) {
        return;
    }
    openModal(
        (String(esc(l.make)) + " " + String(esc(l.model))),
        (
            String(l.year) + " · " + String(fmt(l.odometer)) + " km · " + String(
                esc(l.location)
            ) + String((" · Illustrative demo listing" if l.demo else ""))
        ),
        (
            String(carArt()) + "<div class=\"market-price\">" + String(
                money(l.price)
            ) + "</div><p class=\"listing-description\">" + String(
                esc(l.description)
            ) + "</p><div class=\"listing-history\"><h3>History selected by the seller</h3>" + String(
                (
                    l.history.map(
                        lambda (r: any) -> any { return (
                            "<div class=\"recent-row\"><div><strong>" + String(
                                esc(r.title)
                            ) + "</strong><small>" + String(dateLabel(r.date)) + " · " + String(
                                fmt(r.odometer)
                            ) + " km · " + String(esc(r.source)) + "</small></div><span class=\"tag neutral\">Unverified</span></div>"
                        ); }
                    ).join(
                        ""
                    )
                    or "<p class=\"note\">No history shared by this seller.</p>"
                )
            ) + "</div><p class=\"note\">Seller: " + String(esc(l.seller)) + ". These are reported records, not a guarantee of condition or ownership.</p>" + String(
                (
                    "<span class=\"tag\">Your listing</span>"
                        if (l.seller_id == state.user.id)
                        else (
                            "<button class=\"btn primary full-width\" data-offer=\"" + String(
                                l.id
                            ) + "\" " + String(
                                ("disabled" if (l.status != "active") else "")
                            ) + ">Make an offer " + String(icon("arrow")) + "</button>"
                        )
                )
            )
        )
    );
}

def offerForm(id: any) -> any {
    l = state.market.find(lambda (l: any) -> any { return (l.id == id); });
    openModal(
        "Start the conversation.",
        (
            "Make an offer for " + String(esc(l.make)) + " " + String(esc(l.model)) + ". No payment is taken."
        ),
        formWrap(
            "offer",
            (
                String(
                    field(
                        "amount",
                        "Offer amount (KES)",
                        "number",
                        l.price,
                        "required min=\"1\" step=\"1\""
                    )
                ) + "<div class=\"field\"><label for=\"f-message\">Message to the seller</label><textarea name=\"message\" id=\"f-message\" required maxlength=\"1000\"></textarea></div>"
            ),
            "Send offer",
            ("<input name=\"listing_id\" value=\"" + String(id) + "\" type=\"hidden\">")
        )
    );
}

def manageForm(id: any) -> any {
    l = state.listings.find(lambda (l: any) -> any { return (l.id == id); });
    v = state.vehicles.find(lambda (v: any) -> any { return (v.id == l.vehicle_id); });
    openModal(
        "Manage the next chapter.",
        (
            String(esc(l.make)) + " " + String(esc(l.model)) + " · " + String(
                esc(l.status)
            )
        ),
        formWrap(
            "manage",
            (
                String(
                    selectField(
                        "status",
                        "Listing status",
                        [
                            ["reserved", "Reserved"],
                            ["withdrawn", "Withdrawn"],
                            ["sold", "Sold — handover recorded"]
                        ]
                    )
                ) + "<div class=\"field\"><small>For a sale, confirm the handover and record its date and odometer. Buyer account transfer is not included in this first local release.</small></div><div class=\"form-grid\">" + String(
                    field(
                        "date",
                        "Handover date",
                        "date",
                        today(),
                        (("max=\"" + today()) + "\"")
                    )
                ) + String(
                    field(
                        "odometer",
                        "Handover odometer",
                        "number",
                        v.odometer,
                        "min=\"0\" step=\"1\""
                    )
                ) + "</div><label class=\"check-row\"><input type=\"checkbox\" name=\"handover_confirmed\">I confirm the vehicle handover was completed.</label>"
            ),
            "Save status",
            ("<input name=\"listing_id\" value=\"" + String(id) + "\" type=\"hidden\">")
        )
    );
}

def downloadJSON(filename: any, data: any) -> any {
    url = URL.createObjectURL(
        new(Blob, [JSON.stringify(data, None, 2)], {"type": "application/json"})
    );
    anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = filename;
    anchor.click();
    setTimeout(lambda() -> any { return URL.revokeObjectURL(url); }, 1000);
}

def tourGuide() -> any {
    step = tourSteps[tourStep];
    return (
        "<aside class=\"demo-guide\" aria-label=\"Presentation guide\"><div class=\"section-head\"><span class=\"eyebrow\">SHOWCASE / " + String(
            (tourStep + 1)
        ) + " OF " + String(tourSteps.length) + "</span><button class=\"btn text small\" data-action=\"tour-close\" aria-label=\"Close presentation guide\">" + String(
            icon("close")
        ) + "</button></div><h2>" + String(step.title) + "</h2><p>" + String(
            step.copy
        ) + "</p><div class=\"tour-progress\">" + String(
            tourSteps.map(
                lambda (_: any, i: any) -> any { return (
                    "<span class=\"" + String(("done" if (i <= tourStep) else "")) + "\"></span>"
                ); }
            ).join(
                ""
            )
        ) + "</div><div class=\"modal-actions\"><button class=\"btn small\" data-action=\"tour-back\" " + String(
            ("disabled" if (tourStep == 0) else "")
        ) + ">Back</button><button class=\"btn primary small\" data-action=\"tour-next\">" + String(
            ("Finish" if (tourStep == (tourSteps.length - 1)) else "Next chapter")
        ) + " " + String(icon("arrow")) + "</button></div></aside>"
    );
}

def showTour(index: any) -> any {
    tourStep = Math.max(0, Math.min((tourSteps.length - 1), index));
    page = tourSteps[tourStep].page;
    selected = (
        (
            state.vehicles[0].id
                if (
                    (
                        state.vehicles[0] != None
                        and state.vehicles[0] != globalThis.undefined
                    )
                )
                else globalThis.undefined
        )
        or None
    );
    passportTab = tourSteps[tourStep].tab or "timeline";
    if (page == "assistant") {
        assistantVehicle = selected or "";
    }
    modal.close();
    render();
    window.scrollTo(0, 0);
}

glob publicListings: any = [];
glob publicQuery: any = "";

def publicMarketCards() -> any {
    listings = publicListings.filter(
        lambda (l: any) -> any {
            return (String(l.make) + " " + String(l.model) + " " + String(l.location)).toLowerCase().includes(publicQuery.toLowerCase());
        }
    );
    if not listings.length {
        return empty(
            ("No vehicles match your search." if publicQuery else "No vehicles are listed right now."),
            "Owners list vehicles from their Smartmoti garage and choose which history a buyer can see."
        );
    }
    return "<div class=\"vehicle-grid\">" + listings.map(
        lambda (l: any, i: any) -> any {
            return "<article class=\"vehicle-card\"><div class=\"vehicle-visual\"><span class=\"tag\">" + String(esc(l.location)) + "</span>" + String(carArt(["#bdb9ad", "#aab0ad", "#b8aba0"][(i % 3)])) + "</div><div class=\"vehicle-info\"><h3>" + String(esc(l.make)) + " " + String(esc(l.model)) + "</h3><div class=\"vehicle-meta\"><span>" + String(esc(l.year)) + "</span><span>· " + String(fmt(l.odometer)) + " km</span></div><div class=\"market-price\">" + String(money(l.price, l.currency)) + "</div><p class=\"note\">" + String(l.history.length) + " shared history records · " + String(esc(l.seller)) + "</p><div class=\"card-footer\"><span class=\"tag neutral\">" + String(esc(l.status)) + "</span><button class=\"btn text small\" data-public-listing=\"" + String(esc(l.id)) + "\">View details " + String(icon("arrow")) + "</button></div></div></article>";
        }
    ).join("") + "</div>";
}

def publicMarket() -> any {
    document.title = "Marketplace — Smartmoti";
    app.innerHTML = "<div class=\"landing public-market\"><nav class=\"land-nav\" aria-label=\"Main navigation\">" + String(brand) + "<div class=\"nav-links\"><a href=\"/\">Home</a><a href=\"/market\" aria-current=\"page\">Marketplace</a></div><div class=\"nav-actions\">" + String(themeButton()) + "<button class=\"btn text\" data-action=\"login\">Sign in</button><button class=\"btn primary\" data-action=\"signup\">List your vehicle " + String(icon("arrow")) + "</button></div></nav><main id=\"main-content\" tabindex=\"-1\" class=\"public-market-main\"><div class=\"page-head\"><div><div class=\"eyebrow journal-kicker\">SMARTMOTI / OPEN MARKETPLACE</div><h1>A new owner.<br><em>A clearer story.</em></h1><p>Browse vehicles listed by their owners, with the history each seller chose to share. No account needed to look.</p></div></div><div class=\"market-toolbar\"><input class=\"search\" id=\"public-market-search\" aria-label=\"Search marketplace\" placeholder=\"Search make, model or town…\" value=\"" + String(esc(publicQuery)) + "\"><span class=\"tag neutral\" id=\"public-market-count\">" + String(publicListings.length) + " listings</span></div><div id=\"public-market-results\">" + String(publicMarketCards()) + "</div><p class=\"note public-market-note\">Listings show reported records selected by each seller. Private notes, documents, VIN, registration and location history are never shared.</p></main><footer class=\"land-footer\"><span>© " + String(new(Date).getFullYear()) + " Smartmoti. Every kilometre has a story.</span><span>VEHICLE RECORDS FIRST. ALWAYS.</span></footer></div>";
    applyTheme();
}

def publicListingDetails(id: any) -> any {
    l = publicListings.find(lambda (l: any) -> any { return (l.id == id); });
    if not l { return; }
    openModal(
        String(esc(l.make)) + " " + String(esc(l.model)),
        String(esc(l.year)) + " · " + String(fmt(l.odometer)) + " km · " + String(esc(l.location)),
        String(carArt()) + "<div class=\"market-price\">" + String(money(l.price, l.currency)) + "</div><p class=\"listing-description\">" + String(esc(l.description)) + "</p><div class=\"listing-history\"><h3>History selected by the seller</h3>" + String(
            l.history.map(
                lambda (r: any) -> any {
                    return "<div class=\"recent-row\"><div><strong>" + String(esc(r.title)) + "</strong><small>" + String(dateLabel(r.date)) + " · " + String(fmt(r.odometer)) + " km · " + String(esc(r.source)) + "</small></div><span class=\"tag neutral\">Unverified</span></div>";
                }
            ).join("") or "<p class=\"note\">No history shared by this seller.</p>"
        ) + "</div><p class=\"note\">Seller: " + String(esc(l.seller)) + ". These are reported records, not a guarantee of condition or ownership.</p><button class=\"btn primary full-width\" data-action=\"login\">Sign in to make an offer " + String(icon("arrow")) + "</button>"
    );
}

async def openPublicMarket() -> any {
    publicListings = (await api("public/market")).listings;
    publicMarket();
}

async def bootstrap() -> any {
    if (location.pathname == "/market") {
        (await openPublicMarket());
        return;
    }
    if (location.pathname == "/demo") {
        existing = None;
        try {
            existing = await api("state");
        } except Error as error {
            if (error.status != 401) {
                raise error;
            }
        }
        if (
            (
                not (
                    existing.user.demo
                        if ((existing != None and existing != globalThis.undefined))
                        else globalThis.undefined
                )
            )
            or (existing.showcase_version < 2)
        ) {
            (await api("demo", {}));
        }
    }
    (await refresh());
    (await restoreAgentConversation());
    if (not tourOpen) {
        page = (
            (
                state.settings.start_page
                    if (
                        (
                            state.settings != None
                            and state.settings != globalThis.undefined
                        )
                    )
                    else globalThis.undefined
            )
            or "garage"
        );
        render();
    }
}

async def upload(file: any) -> any {
    if (file.size > ((5 * 1024) * 1024)) {
        raise new(Error, "Supporting documents must be at most 5 MB.");
    }
    content = (
        await new(
            Promise,
            lambda (resolve: any, reject: any) -> any {
                reader = new(FileReader);
                reader.onload = lambda() -> any { return resolve(
                    reader.result.split(",")[1]
                ); };
                reader.onerror = lambda() -> any { return reject(
                    new(Error, "Could not read this file")
                ); };
                reader.readAsDataURL(file);
            }
        )
    );
    return api("upload", {"name": file.name, "mime": file.`type, "content": content});
}

with entry {
    document.addEventListener("click", _asyncHandler9);
}

with entry {
    document.addEventListener(
        "change",
        lambda (event: any) -> any {
            if (event.target.id == "assistant-context") {
                assistantVehicle = event.target.value;
                render();
            }
            if (event.target.id == "vehicle-select") {
                selected = event.target.value;
                render();
            }
            if (
                (event.target.name == "vehicle_id")
                and event.target.closest("[data-form=\"listing\"]")
            ) {
                updateShareOptions(event.target.value);
            }
        }
    );
}

with entry {
    document.addEventListener(
        "input",
        lambda (event: any) -> any {
            if (event.target.id == "agent-message") {
                agentDraft = event.target.value;
            }
            if (event.target.id == "market-search") {
                marketQuery = event.target.value;
                cursor = event.target.selectionStart;
                render();
                input = document.querySelector("#market-search");
                input.focus();
                input.setSelectionRange(cursor, cursor);
            }
        }
    );
}

with entry {
    document.addEventListener("submit", _asyncHandler10);
}

with entry {
    modal.addEventListener(
        "click",
        lambda (event: any) -> any { if (event.target == modal) {
            r = modal.getBoundingClientRect();
            if (
                (
                    ((event.clientX < r.left) or (event.clientX > r.right))
                    or (event.clientY < r.top)
                )
                or (event.clientY > r.bottom)
            ) {
                modal.close();
            }
        }}
    );
}

with entry {
    try {
        savedTheme = localStorage.getItem("smartmoti-theme");
        if (["light", "dark"].includes(savedTheme)) { themePreference = savedTheme; }
    } except Error { }
    applyTheme();
    document.addEventListener(
        "click",
        lambda (event: any) -> any {
            listing = event.target.closest("[data-public-listing]");
            if listing { publicListingDetails(listing.dataset.publicListing); return; }
            choice = event.target.closest("[data-theme-choice]");
            if not choice or not ["light", "dark"].includes(choice.dataset.themeChoice) { return; }
            themePreference = choice.dataset.themeChoice;
            try { localStorage.setItem("smartmoti-theme", themePreference); } except Error { }
            applyTheme();
        }
    );
    document.addEventListener(
        "input",
        lambda (event: any) -> any {
            if event.target.id != "public-market-search" { return; }
            publicQuery = event.target.value;
            document.querySelector("#public-market-results").innerHTML = publicMarketCards();
        }
    );
    compactNavigation.addEventListener("change", applyNavigation);
    bootstrap().catch(
        lambda (error: any) -> any {
            state = None;
            landing();
            if (error.status != 401) {
                notify("Could not connect to your workspace. Please reload.");
            }
        }
    );
}

async def _asyncHandler9(event: any) -> any {
    if (event.target.closest(".skip-link")) {
        document.querySelector("#main-content").focus();
    }
    publicMenu = event.target.closest(".public-menu");
    if (publicMenu and not event.target.closest("summary")) { publicMenu.removeAttribute("open"); }
    button = event.target.closest("button");
    if (not button) {
        return;
    }
    if button.dataset.evidenceRecord {
        selected = button.dataset.evidenceVehicle;
        page = "passport";
        passportTab = "timeline";
        render();
        row = document.getElementById("record-" + button.dataset.evidenceRecord);
        if row { row.querySelector("details").open = True; row.scrollIntoView({"block": "center"}); row.focus(); }
        return;
    }
    if button.dataset.agentView {
        if state.vehicles.some(lambda(v: any) -> any { return v.id == button.dataset.agentView; }) {
            selected = button.dataset.agentView;
            page = "passport";
            passportTab = "timeline";
            render();
        }
        return;
    }
    if button.dataset.agentPrompt {
        agentDraft = button.dataset.agentPrompt;
        render();
        (
            document.querySelector("#agent-message").focus()
                if (
                    (
                        document.querySelector("#agent-message") != None
                        and document.querySelector("#agent-message") != globalThis.undefined
                    )
                )
                else globalThis.undefined
        );
        return;
    }
    if button.dataset.agentApprove {
        (await decideProposal(button.dataset.agentApprove, True, button));
        return;
    }
    if button.dataset.agentReject {
        (await decideProposal(button.dataset.agentReject, False, button));
        return;
    }
    if button.dataset.page {
        page = button.dataset.page;
        tourOpen = False;
        render();
        window.scrollTo(0, 0);
        return;
    }
    if button.dataset.passport {
        selected = button.dataset.passport;
        page = "passport";
        render();
        window.scrollTo(0, 0);
        return;
    }
    if button.dataset.tab {
        passportTab = button.dataset.tab;
        render();
        return;
    }
    if button.dataset.correct {
        recordForm(False, button.dataset.correct);
        return;
    }
    if button.dataset.listing {
        listingDetails(button.dataset.listing);
        return;
    }
    if button.dataset.offer {
        offerForm(button.dataset.offer);
        return;
    }
    if button.dataset.manage {
        manageForm(button.dataset.manage);
        return;
    }
    action = button.dataset.action;
    try {
        if (action == "issue") { issueForm(); }
        if (action == "close") {
            modal.close();
        }
        if (action == "tour") {
            tourOpen = True;
            showTour(0);
        }
        if (action == "tour-close") {
            tourOpen = False;
            render();
        }
        if (action == "tour-next") {
            if (tourStep < (tourSteps.length - 1)) {
                showTour((tourStep + 1));
            } else {
                tourOpen = False;
                render();
                notify("Your showcase walkthrough is complete.");
            }
        }
        if (action == "tour-back") {
            showTour((tourStep - 1));
        }
        if ((action == "signup") or (action == "login")) {
            auth(action);
        }
        if ((action == "demo") or (action == "restart-demo")) {
            button.disabled = True;
            (await api("demo", {}));
            tourOpen = True;
            tourStep = 0;
            page = "garage";
            agentGeneration += 1;
            agentBusy = False;
            agentMessages = [];
            agentSession = None;
            agentDraft = "";
            (await refresh());
            window.scrollTo(0, 0);
        }
        if (action == "remove-api-key") {
            button.disabled = True;
            (await api("settings/remove-key", {}));
            aiReviews.clear();
            (await refresh());
            notify("Personal Gemini key removed.");
        }
        if (action == "test-api-key") {
            button.disabled = True;
            feedback = document.querySelector("#ai-test-result");
            feedback.textContent = "Checking your saved configuration...";
            try {
                result = await api("settings/test-ai", {});
                feedback.textContent = result.message;
            } except Error as error {
                feedback.textContent = error.message;
            } finally {
                button.disabled = False;
            }
        }
        if (action == "export-workspace") {
            downloadJSON(
                "smartmoti-my-records.json",
                {
                    "profile": state.user,
                    "vehicles": state.vehicles,
                    "listings": state.listings,
                    "exported_at": new(Date).toISOString()
                }
            );
            notify(
                "Your vehicle records exported. Documents are downloaded separately."
            );
        }
        if (action == "logout") {
            (await api("logout", {}));
            state = None;
            page = "garage";
            aiReviews.clear();
            agentGeneration += 1;
            agentBusy = False;
            agentMessages = [];
            agentSession = None;
            agentDraft = "";
            modal.close();
            landing();
        }
        if (action == "ai-review") {
            button.disabled = True;
            button.textContent = "Gemini is reviewing?";
            result = await api("ai/review", {"vehicle_id": selected});
            aiReviews.`set(selected, result);
            render();
            notify("AI review generated by Gemini.");
        }
        if (action == "ai-draft") {
            form = button.closest("form");
            fields = new(FormData, form);
            button.disabled = True;
            button.textContent = "Gemini is drafting?";
            data = (
                await api(
                    "ai/draft",
                    {
                        "vehicle_id": fields.get("vehicle_id"),
                        "shared_record_ids": fields.getAll("shared")
                    }
                )
            );
            form.querySelector("[name=\"description\"]").value = data.result.description;
            button.disabled = False;
            button.textContent = "Draft with Gemini";
            notify("Gemini draft added. Review it before publishing.");
        }
        if (action == "open-assistant") {
            assistantVehicle = selected or "";
            page = "assistant";
            tourOpen = False;
            render();
            (
                document.querySelector("#agent-message").focus()
                    if (
                        (
                            document.querySelector("#agent-message") != None
                            and document.querySelector("#agent-message") != globalThis.undefined
                        )
                    )
                    else globalThis.undefined
            );
        }
        if (action == "agent-new") {
            agentGeneration += 1;
            agentBusy = False;
            agentMessages = [];
            agentSession = None;
            agentDraft = "";
            conversation = await api("agent/conversation/new", {});
            agentSession = conversation.session_id;
            render();
        }
        if (action == "agent-review-history") {
            if assistantVehicle {
                selected = assistantVehicle;
            }
            passportTab = "ai";
            page = "passport";
            render();
        }
        if (action == "vehicle") {
            vehicleForm();
        }
        if (action == "record") {
            recordForm();
        }
        if (action == "fuel") {
            recordForm(True);
        }
        if (action == "listing") {
            listingForm();
        }
        if (action == "export") {
            v = vehicle();
            downloadJSON(("smartmoti-" + String(v.plate) + "-passport.json"), v);
            notify("Vehicle passport exported.");
        }
        if (action == "metadata") {
            data = (
                await api(
                    "workflow",
                    {"action": "mint_metadata", "payload": {"vehicle_id": selected}}
                )
            );
            openModal(
                "A snapshot, ready to review.",
                "Make, model and year only. Downloading this file does not mint an NFT.",
                (
                    "<pre class=\"note\">" + String(
                        esc(JSON.stringify(data.result, None, 2))
                    ) + "</pre><button class=\"btn primary full-width\" id=\"download-metadata\">Download metadata " + String(
                        icon("download")
                    ) + "</button>"
                )
            );
            document.querySelector("#download-metadata").addEventListener(
                "click",
                lambda() -> any { return downloadJSON(
                    "smartmoti-mint-metadata.json", data.result
                ); }
            );
        }
    } except Error as error {
        notify(error.message);
        button.disabled = False;
        if (action == "ai-review") {
            button.textContent = "Generate AI review";
        }
        if (action == "ai-draft") {
            button.textContent = "Draft with Gemini";
        }
    }
}

async def _asyncHandler10(event: any) -> any {
    form = event.target;
    if (not form.dataset.form) {
        return;
    }
    if (form.dataset.form == "issue") {
        event.preventDefault();
        await submitIssue(form);
        return;
    }
    if (form.dataset.form == "agent") {
        event.preventDefault();
        (await sendAgentMessage());
        return;
    }
    event.preventDefault();
    data = new(FormData, form);
    payload = Object.fromEntries(data.entries());
    submit = form.querySelector("[type=\"submit\"]");
    submit.disabled = True;
    form.querySelector(".form-error").textContent = "";
    try {
        kind = form.dataset.form;
        if kind.startsWith("settings-") {
            section = kind.slice(9);
            if (
                (section == "password")
                and (payload.new_password != payload.confirm_password)
            ) {
                raise new(Error, "The new passwords do not match.");
            }
            if (section == "ai") {
                payload.ai_enabled = data.`has("ai_enabled");
                payload.use_server_ai = data.`has("use_server_ai");
            }
            (await api(("settings/" + section), payload));
            if (section == "ai") {
                aiReviews.clear();
            }
        }
        if (kind == "auth") {
            (await api(authMode, payload));
        }
        if (kind == "vehicle") {
            result = (
                await api(
                    "workflow", {"action": "register_vehicle", "payload": payload}
                )
            );
            selected = result.result.id;
            page = "passport";
        }
        if (kind == "record") {
            payload.full_tank = data.`has("full_tank");
            Reflect.deleteProperty(payload, "file");
            file = data.get("file");
            if (
                file.size
                    if ((file != None and file != globalThis.undefined))
                    else globalThis.undefined
            ) {
                payload.document = (await upload(file)).id;
            }
            (await api("workflow", {"action": "add_record", "payload": payload}));
            aiReviews.delete(payload.vehicle_id);
        }
        if (kind == "listing") {
            payload.shared_record_ids = data.getAll("shared");
            (await api("workflow", {"action": "publish_listing", "payload": payload}));
            page = "market";
        }
        if (kind == "offer") {
            (await api("offer", payload));
        }
        if (kind == "manage") {
            payload.handover_confirmed = data.`has("handover_confirmed");
            (await api("listing-status", payload));
        }
        (await refresh());
        if (kind == "auth") {
            await restoreAgentConversation();
            page = (
                (
                    state.settings.start_page
                        if (
                            (
                                state.settings != None
                                and state.settings != globalThis.undefined
                            )
                        )
                        else globalThis.undefined
                )
                or "garage"
            );
            render();
        }
        modal.close();
        notify(
            (
                "Your garage is ready."
                    if (kind == "auth")
                    else (
                        "Offer recorded for the seller."
                            if (kind == "offer")
                            else "Saved to your workspace."
                    )
            )
        );
    } except Error as error {
        form.querySelector(".form-error").textContent = error.message;
        submit.disabled = False;
    }
}


with entry {
    document.addEventListener("keydown", lambda (event: any) -> any {
        if (event.key == "Escape") {
            menu = document.querySelector(".public-menu[open], .workspace-menu[open]");
            if menu and (menu.classList.contains("public-menu") or compactNavigation.matches) { menu.removeAttribute("open"); menu.querySelector("summary").focus(); }
        }
    });
}
