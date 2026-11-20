#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd -P)
root_dir=$(cd "$script_dir/.." && pwd -P)
mode=all
update_golden=
language_selected=
for arg in "$@"; do
    if [[ $arg == --update-golden && -z $update_golden ]]; then
        update_golden=1
    elif [[ $arg != -* && -z $language_selected ]]; then
        mode=$arg
        language_selected=1
    else
        echo "Usage: $0 [all|swift|kotlin|cpp] [--update-golden]" >&2
        exit 1
    fi
done
case "$mode" in
    all|swift|kotlin|cpp) ;;
    *) echo "Unknown model language: $mode" >&2; exit 1 ;;
esac

generate_model_files() {
    if [[ $update_golden == 1 ]]; then
        set -- "$@" --update-golden "$root_dir/ci/codegen-golden.json"
    fi
    scripts/gen-models.sh "$@"
}

# Both repositories use Partout's schema reader and native renderers.
cd "$root_dir/partout"
set -- -gen-models "$mode"
if [[ $update_golden == 1 ]]; then
    set -- "$@" --update-golden
fi
scripts/build.sh "$@"
input="$root_dir/scripts/openapi.yaml"
external=ConnectionStatus,ModuleType,TaggedProfile
if [[ "$mode" == all || "$mode" == swift ]]; then
    generate_model_files "$input" swift \
        "$root_dir/app-apple/Sources/CommonLibraryCore/Domain/Codegen" \
        CommonLibraryCore "$external" OpenAPI
fi
if [[ "$mode" == all || "$mode" == kotlin ]]; then
    generate_model_files "$input" kotlin "$root_dir/app-android/app" \
        com.algoritmico.passepartout.models "$external"
fi
if [[ "$mode" == all || "$mode" == cpp ]]; then
    generate_model_files "$input" cpp "$root_dir/app-cross/models" \
        Passepartout.Models "$external"
fi
