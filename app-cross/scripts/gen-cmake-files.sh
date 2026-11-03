#!/bin/bash
set -e
export LC_ALL=C
script_dir="$(cd "$(dirname "$0")" && pwd)"
cd "$script_dir/.."
# Core sources belong to core.cmake; platform sources must remain conditional.
python3 - <<'PYTHON'
from pathlib import Path
sources = sorted(str(p) for p in Path("app").rglob("*.cc")
                 if not any(part in ("business", "observables", "platform") for part in p.parts))
windows = sorted(str(p) for p in Path("app/platform").glob("windows_*.cc"))
Path("files.cmake").write_text("set(APP_SOURCES\n" +
    "".join("    " + p + "\n" for p in sources) + ")\n" +
    "if(WIN32)\n    list(APPEND APP_SOURCES\n" +
    "".join("        " + p + "\n" for p in windows) + "    )\nendif()\n")
PYTHON
