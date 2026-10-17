"""Interactive local setup. Never echo a provider key or include it in arguments."""
import from getpass { getpass }
import from pathlib { Path }

def main() -> None {
    target = Path(str(__file__)).resolve().parent / ".env";
    key = getpass("Paste your new Gemini API key (input is hidden): ").strip();
    if not key or "\n" in key or "\r" in key {
        raise SystemExit("A nonempty API key is required.");
    }
    target.write_text(
        f"GEMINI_API_KEY={key}\nSMARTMOTI_AI_MODEL=gemini/gemini-3.8-flash\n",
        encoding="utf-8"
    );
    print(
        "Gemini key saved to Smartmoti's ignored .env file. The key was not displayed."
    );
}

with entry:__main__ {
    main();
}
