#!/bin/bash
# SPDX-FileCopyrightText: 2026 Davide De Rosa
#
# SPDX-License-Identifier: GPL-3.0

set -euo pipefail
if [[ "$(uname -s)" != Darwin ]]; then
    echo 'This task requires macOS; use the Windows run tasks on Windows.' >&2
    exit 1
fi
architecture="${1:-}"
configuration="${2:-}"
case "$architecture" in arm64|x64) ;; *) echo 'Architecture must be arm64 or x64.' >&2; exit 1 ;; esac
case "$configuration" in Debug|Release) ;; *) echo 'Configuration must be Debug or Release.' >&2; exit 1 ;; esac
if [[ $# -gt 3 || ( $# -eq 3 && "$3" != --demo ) ]]; then
    echo 'Usage: run-app.sh arm64|x64 Debug|Release [--demo]' >&2
    exit 1
fi
source_dir="$(cd "$(dirname "$0")/.." && pwd)"
preset="macos-$architecture"
build_dir="$source_dir/out/build/$preset"
install_dir="$source_dir/out/install/$preset"
if pgrep -x passepartout >/dev/null; then
    echo 'Quit the frontend before installing.' >&2
    exit 1
fi
cd "$source_dir"
cmake --preset "$preset" "-DCMAKE_INSTALL_PREFIX=$install_dir"
cmake --build "$build_dir" --config "$configuration"
cmake --install "$build_dir" --config "$configuration" --prefix "$install_dir"
bundle="$install_dir/passepartout.app"
codesign --force --deep --sign - "$bundle"
if [[ $# -eq 3 ]]; then
    open -n "$bundle" --args --demo
else
    open -n "$bundle"
fi
