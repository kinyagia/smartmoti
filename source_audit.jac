"""Reproducible first-party source inventory for the hackathon Jac requirement."""
import json;
import sys;
import from pathlib { Path }
import from typing { cast }

glob EXCLUDED: set[str] = {
         ".git",
         ".venv",
         ".jac",
         "node_modules",
         "__pycache__",
         "data",
         "artifacts"
     },
     EXTENSIONS: set[str] = {
         ".jac",
         ".py",
         ".js",
         ".mjs",
         ".cjs",
         ".jsx",
         ".ts",
         ".tsx",
         ".css",
         ".html",
         ".ps1",
         ".sh",
         ".sql",
         ".sol"
     };

def inventory(project: Path) -> list[dict[str, any]] {
    files: list[dict[str, any]] = [];
    for filename in sorted(project.rglob("*")) {
        relative = filename.relative_to(project);
        if `any(part in EXCLUDED for part in relative.parts) or filename.is_symlink() {
            continue;
        }
        if not filename.is_file() or filename.suffix not in EXTENSIONS {
            continue;
        }
        content = filename.read_bytes();
        lines = [
            line
            for line in content.decode("utf-8-sig").splitlines()
            if line.strip()
        ];
        files.append(
            {
                "path": relative.as_posix(),
                "language": filename.suffix,
                "bytes": len(content),
                "nonblankLines": len(lines)
            }
        );
    }
    return files;
}

def distribution(files: list[dict[str, any]]) -> dict[str, any] {
    totals: dict[str, any] = {};
    total_bytes: int = 0;
    total_lines: int = 0;
    jac_bytes: int = 0;
    jac_lines: int = 0;
    for file in files {
        language = str(file["language"]);
        size = cast(int, file["bytes"]);
        lines = cast(int, file["nonblankLines"]);
        if language not in totals {
            totals[language] = {"bytes": 0, "nonblankLines": 0, "files": 0};
        }
        total = cast(dict[str, int], totals[language]);
        total["bytes"] += size;
        total["nonblankLines"] += lines;
        total["files"] += 1;
        total_bytes += size;
        total_lines += lines;
        if language == ".jac" {
            jac_bytes += size;
            jac_lines += lines;
        }
    }
    byte_percent = 100.0 * jac_bytes / total_bytes if total_bytes else 0.0;
    line_percent = 100.0 * jac_lines / total_lines if total_lines else 0.0;
    return {
        "jacBytePercent": byte_percent,
        "jacLinePercent": line_percent,
        "meetsLocalThreshold": byte_percent >= 80.0 and line_percent >= 80.0,
        "totals": totals,
        "totalBytes": total_bytes,
        "totalNonblankLines": total_lines
    };
}

def audit(project: Path) -> dict[str, any] {
    files = inventory(project);
    result = distribution(files);
    result["thresholdPercent"] = 80;
    result["files"] = files;
    # Report the application separately so a test-suite migration cannot
    # conceal an application that still relies predominantly on another language.
    application_files = [
        file
        for file in files
        if not str(file["path"]).startswith("tests/")
    ];
    result["application"] = distribution(application_files);
    return result;
}

def main() -> None {
    result = audit(Path(str(__file__)).resolve().parent);
    if "--json" in sys.argv {
        print(json.dumps(result, indent=2));
    } else {
        print("First-party source, including styles, HTML, tests and tooling:");
        for (language, amounts) in cast(dict[str, any], result["totals"]).items() {
            total = cast(dict[str, int], amounts);
            print(
                f"{language}: {total['bytes']} bytes; {total[
                    'nonblankLines'
                ]} nonblank lines; {total['files']} files"
            );
        }
        bytes_share = cast(float, result["jacBytePercent"]);
        lines_share = cast(float, result["jacLinePercent"]);
        print(
            f"Jac: {bytes_share:.2f}% by bytes; {lines_share:.2f}% by nonblank lines."
        );
        application = cast(dict[str, any], result["application"]);
        app_bytes_share = cast(float, application["jacBytePercent"]);
        app_lines_share = cast(float, application["jacLinePercent"]);
        print(
            f"Application without tests: {app_bytes_share:.2f}% by bytes; {app_lines_share:.2f}% by nonblank lines."
        );
        status = "PASS" if result["meetsLocalThreshold"] else "FAIL";
        print(
            f"{status}: local 80% estimate. Organizer counting method and eligibility require separate confirmation."
        );
    }
    if "--enforce" in sys.argv and not result["meetsLocalThreshold"] {
        sys.exit(1);
    }
}

with entry:__main__ {
    main();
}
