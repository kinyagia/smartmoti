"""Build the browser program from Jac using the pinned ECMAScript backend."""
import hashlib;
import sys;
import from pathlib { Path }
import from jaclang.jac0core.program { JacProgram }
import from jaclang.compiler.passes.ecmascript { EsastGenPass }

def compile_source(source: Path, target: Path) -> Path {
    signature_file = target.with_suffix(".sha256");
    signature = hashlib.sha256(
        source.read_bytes() + Path(str(__file__)).read_bytes()
    ).hexdigest();
    if target.exists()
    and signature_file.exists()
    and signature_file.read_text() == signature {
        return target;
    }
    program = JacProgram();
    module = program.compile(file_path=str(source), no_cgen=True);
    if not program.errors_had {
        # On Windows, the normal backend schedule can skip ES generation
        # when the optional native compiler is absent. Run ES explicitly.
        program.run_schedule(module, [EsastGenPass]);
    }
    if program.errors_had or not module.gen.js {
        raise RuntimeError(
            "Jac browser compilation failed: " + "\n".join(
                [str(error) for error in program.errors_had]
            )
        );
    }
    target.parent.mkdir(parents=True, exist_ok=True);
    target.write_text(module.gen.js, encoding="utf-8");
    signature_file.write_text(signature);
    return target;
}

def build_client() -> Path {
    project = Path(str(__file__)).resolve().parent;
    return compile_source(
        project / "web" / "app.cl.jac", project / ".jac" / "client" / "app.js"
    );
}

def build_ui_test() -> Path {
    project = Path(str(__file__)).resolve().parent;
    return compile_source(
        project / "tests" / "ui.cl.jac", project / ".jac" / "tests" / "ui.mjs"
    );
}

with entry:__main__ {
    print(build_client());
    if "--tests" in sys.argv {
        print(build_ui_test());
    }
}
