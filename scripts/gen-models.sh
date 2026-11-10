#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd -P)
root_dir=$(cd "$script_dir/.." && pwd -P)
mode=${1:-all}
if [[ $# -gt 1 ]]; then
    echo "Usage: $0 [all|swift|kotlin|cpp]" >&2
    exit 1
fi
case "$mode" in
    all|swift|kotlin|cpp) ;;
    *) echo "Unknown model language: $mode" >&2; exit 1 ;;
esac

# Both repositories use Partout's schema reader and native renderers.
cd "$root_dir/partout"
scripts/build.sh -gen-models "$mode"
input="$root_dir/scripts/openapi.yaml"
external=ConnectionStatus,ModuleType,TaggedProfile
if [[ "$mode" == all || "$mode" == swift ]]; then
    scripts/gen-models.sh "$input" swift \
        "$root_dir/app-apple/Sources/CommonLibraryCore/Domain/Codegen" \
        CommonLibraryCore "$external" OpenAPI
fi
if [[ "$mode" == all || "$mode" == kotlin ]]; then
    scripts/gen-models.sh "$input" kotlin "$root_dir/app-android/app" \
        com.algoritmico.passepartout.models "$external"
fi
if [[ "$mode" == all || "$mode" == cpp ]]; then
    scripts/gen-models.sh "$input" cpp "$root_dir/app-cross/models" \
        Passepartout.Models "$external"
fi
