"""One-time source migration to the Automotive Journal interface."""
import from typing { Any }
import from pathlib { Path }
import json;
import re;
def literal(html: str) -> str {
    return json.dumps(html, ensure_ascii=False);
}
def color_token(`match: re.Match[str]) -> str {
    h = `match[0][1:];
    if (len(h) in (3, 4)) {
        h = ''.join((c * 2) for c in h);
    }
    rgb = [int.from_bytes(bytes.fromhex(h[i:(i + 2)]), "big") for i in (0, 2, 4)];
    light = sum(rgb) / 3;
    if ((len(h) == 8) and (int.from_bytes(bytes.fromhex(h[6:8]), "big") < 110)) {
        return 'var(--shadow-color)' if (light < 120) else 'var(--line)';
    }
    if (light > 247) {
        return 'var(--surface)';
    }
    if (light > 224) {
        return 'var(--surface-alt)';
    }
    if (light > 185) {
        return 'var(--line)';
    }
    if (light > 90) {
        return 'var(--muted)';
    }
    return 'var(--ink)';
}
def main() -> Any {
    `root = Path(str(__file__)).resolve().parents[1];
    p = `root / 'web/app.cl.jac';
    s = p.read_text(encoding='utf-8');
    at = 'glob modal: any = document.querySelector("#modal");';
    s = s.replace(
        at,
        (
            at + '\n\nglob themeMode: any = "light";\n\ndef applyTheme() -> any {\n    document.documentElement.dataset.theme = themeMode;\n    document.querySelector("meta[name=\'theme-color\']").content = (\n        "#202522" if themeMode == "dark" else "#F5F2EA"\n    );\n    document.querySelectorAll("[data-action=\'theme\']").forEach(\n        lambda (button: any) -> any {\n            button.setAttribute("aria-pressed", String(themeMode == "dark"));\n            button.setAttribute("aria-label", "Dark mode");\n            button.innerHTML = icon("contrast") + "<span>Dark mode</span>";\n        }\n    );\n}\n\ndef themeButton() -> any {\n    return "<button class=\\"theme-toggle\\" data-action=\\"theme\\" aria-label=\\"Dark mode\\" aria-pressed=\\"false\\"></button>";\n}\n'
        )
    );
    s = s.replace(
        '"settings": "m9',
        '"contrast": "M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18Zm0 0v18M12 3a9 9 0 0 1 0 18",\n         "settings": "m9',
        1
    );
    s = s.replace(
        '<span class=\\"brand-mark\\">s</span>',
        '<span class=\\"brand-mark\\" aria-hidden=\\"true\\">//</span>'
    );
    s = s.replace(
        'class=\\"nav-actions\\"><button',
        'class=\\"nav-actions\\">" + String(themeButton()) + "<button',
        1
    );
    s = s.replace(
        'class=\\"topbar-right\\"><button',
        'class=\\"topbar-right\\">" + String(themeButton()) + "<button',
        1
    );
    s = s.replace(
        '    );\n}\n\nglob navItems:',
        '    );\n    applyTheme();\n}\n\nglob navItems:',
        1
    );
    s = s.replace(
        '    );\n}\n\ndef pageHead(', '    );\n    applyTheme();\n}\n\ndef pageHead(', 1
    );
    s = s.replace(
        'class=\\"page\\">',
        'class=\\"page\\" id=\\"main-content\\" tabindex=\\"-1\\" data-view=\\"" + String(page) + "\\">',
        1
    );
    s = s.replace(
        '<main><section class=\\"hero\\">',
        '<main id=\\"main-content\\" tabindex=\\"-1\\"><section class=\\"hero\\">',
        1
    );
    s = s.replace('A lifetime, kept together', 'THE AUTOMOTIVE JOURNAL / EST. 2026', 1);
    s = s.replace(
        'A record of the road.<br>A little more peace of mind.',
        'RECORDED. REFERENCED.<br>READY FOR THE ROAD.',
        1
    );
    s = s.replace(
        'Built with Jac · Vehicle records first', 'THE AUTOMOTIVE JOURNAL', 1
    );
    s = s.replace(
        '("A little clarity.<br>A better journey.")',
        '("Your garage.<br><em>Stories in motion.</em>")',
        1
    );
    s = s.replace(
        '"<div class=\\"section-head\\"><h2>Your garage',
        'String(garageFeature()) + "<div class=\\"section-head\\"><h2>The collection',
        1
    );
    s = s.replace(
        '"<div class=\\"page-head\\"><div><h1>"',
        '"<div class=\\"page-head\\"><div><div class=\\"eyebrow journal-kicker\\">SMARTMOTI / OWNERSHIP JOURNAL</div><h1>"',
        1
    );
    feature = '\ndef garageFeature() -> any {\n    v = vehicle();\n    if (not v) { return ""; }\n    current = v.records.filter(lambda (r: any) -> any { return not r.superseded_by; });\n    ownership = current.find(lambda (r: any) -> any { return ["acquisition", "ownership"].includes(r.`type); });\n    service = current.find(lambda (r: any) -> any { return ["maintenance", "repair", "inspection"].includes(r.`type); });\n    return (\n        "<section class=\\"garage-feature\\" aria-label=\\"Primary vehicle\\"><div class=\\"feature-vehicle\\"><div class=\\"feature-topline\\"><span class=\\"eyebrow\\">01 / IN FOCUS</span>" + String(selector()) + "</div><div class=\\"feature-identity\\"><span class=\\"registration\\">" + String(esc(v.plate)) + "</span><h2>" + String(esc(v.make)) + "<br><em>" + String(esc(v.model)) + "</em></h2><span class=\\"feature-year\\">" + String(v.year) + " / VEHICLE ILLUSTRATION</span></div><div class=\\"feature-drawing\\">" + String(carArt("#bbb5a5", True)) + "</div><div class=\\"feature-bottomline\\"><span>THE ROAD SO FAR</span><strong>" + String(fmt(v.odometer)) + " <small>km</small></strong></div></div><div class=\\"feature-journal\\"><div class=\\"eyebrow\\">YOUR OWNERSHIP FILE</div><h3>A life on the road.<br>Kept in detail.</h3><div class=\\"ownership-fact\\"><span>Latest ownership entry</span><strong>" + String(dateLabel(ownership.date) if ownership else "Not recorded") + "</strong><small>" + String(esc(ownership.source) if ownership else "Add an acquisition or ownership record.") + "</small></div><div class=\\"ownership-fact\\"><span>Maintenance outlook</span><strong>No due schedule recorded</strong><small>" + String(("Latest service / inspection: " + dateLabel(service.date)) if service else "No service or inspection recorded yet.") + "</small></div><p class=\\"note\\">Reported history, not independent verification. Documents stay private; you choose the history to share.</p><div class=\\"feature-actions\\"><button class=\\"btn primary\\" data-passport=\\"" + String(v.id) + "\\">Open passport " + String(icon("arrow")) + "</button><button class=\\"btn\\" data-action=\\"record\\">" + String(icon("plus")) + " Add record</button></div></div></section>"\n    );\n}\n\n';
    s = s.replace(
        'def timelineMarkup(v: any)', (feature + 'def timelineMarkup(v: any)'), 1
    );
    s = s.replace(
        '"<article class=\\"timeline-row " + String(',
        '"<article class=\\"timeline-row event-" + String(esc(r.`type)) + " " + String(',
        1
    );
    s = s.replace(
        '"\\"><div class=\\"timeline-date\\">" + String(dateLabel(r.date)) + "</div><div class=\\"timeline-body\\"><h3>"',
        '"\\"><div class=\\"timeline-date\\"><time datetime=\\"" + String(esc(r.date)) + "\\">" + String(dateLabel(r.date)) + "</time><strong>" + String(fmt(r.odometer)) + "<small> km</small></strong></div><div class=\\"timeline-body\\"><span class=\\"event-stamp\\">" + String(esc(r.`type)) + "</span><h3>"',
        1
    );
    s = s.replace(
        ') + "</div>" + String(\n                (("<p>"',
        ') + "</div><details class=\\"record-evidence\\"><summary>Source &amp; evidence <span>" + String("Document attached" if r.document else "No document attached") + "</span></summary><p class=\\"note\\">Workspace record. Unverified source: " + String(esc(r.source)) + ". Notes and documents are private. Public listings include only the history you select.</p>" + String(\n                (("<p>"',
        1
    );
    s = s.replace(
        ') + "</div></div></article>"', ') + "</div></details></div></article>"', 1
    );
    s = s.replace(
        ') + "</strong></div></div></div></div><div class=\\"section-head\\">',
        ') + "</strong></div></div><p class=\\"privacy-notice\\">" + String(icon("shield")) + " Private workspace · Notes, VIN and documents are excluded from marketplace history.</p></div></div><div class=\\"section-head\\">',
        1
    );
    s = s.replace(
        '    button = event.target.closest("button");',
        '    if (event.target.closest(".skip-link")) {\n        document.querySelector("#main-content").focus();\n    }\n    button = event.target.closest("button");',
        1
    );
    s = s.replace(
        '    action = button.dataset.action;\n    try {',
        '    action = button.dataset.action;\n    if (action == "theme") {\n        themeMode = ("light" if themeMode == "dark" else "dark");\n        try { localStorage.setItem("smartmoti-theme", themeMode); } except Error { }\n        applyTheme();\n        return;\n    }\n    try {',
        1
    );
    s = s.replace(
        'agentDraft,tourOpen,tourStep;\n    if',
        'agentDraft,tourOpen,tourStep,themeMode;\n    if',
        1
    );
    s = s.replace(
        'with entry {\n    bootstrap().catch(',
        'with entry {\n    try {\n        if (localStorage.getItem("smartmoti-theme") == "dark") { themeMode = "dark"; }\n    } except Error { }\n    applyTheme();\n    bootstrap().catch(',
        1
    );
    p.write_text(s, encoding='utf-8');
    index = `root / 'web/index.html';
    html = index.read_text(encoding='utf-8').replace('#163f35', '#F5F2EA');
    html = html.replace(
        '<body>',
        '<body>\n  <a class="skip-link" href="#main-content">Skip to content</a>'
    );
    index.write_text(html, encoding='utf-8');
    p = `root / 'web/styles.css';
    css = p.read_text(encoding='utf-8');
    css = re.sub(':root\\{[^}]+\\}', '', css, count=1);
    css = re.sub(
        '#[0-9a-fA-F]{8}\\b|#[0-9a-fA-F]{6}\\b|#[0-9a-fA-F]{4}\\b|#[0-9a-fA-F]{3}\\b',
        color_token,
        css
    );
    css = re.sub('font-size:(9|10|11)px', 'font-size:12px', css);
    css = css.replace('}', '}\n');
    p.write_text(css, encoding='utf-8');
}
