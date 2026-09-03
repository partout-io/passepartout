#!/bin/bash

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
app_dir=$(cd "$script_dir/.." && pwd -P)

usage() {
    cat <<'EOF'
Usage: ci/package.sh <target> <output-directory>

Targets:
  play    Build the release Android App Bundle for Google Play

The script builds but does not upload the bundle. Release signing must be
configured in Gradle before the resulting bundle can be published.
EOF
}

fail() {
    echo "error: $*" >&2
    exit 1
}

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
    usage
    exit 0
fi

[[ $# -le 2 ]] || fail "Too many arguments"

target=${1:-}
output_dir=${2:-}

if [[ -z $target || -z $output_dir ]]; then
    usage >&2
    exit 1
fi

if [[ $output_dir != /* ]]; then
    output_dir="$PWD/$output_dir"
fi
mkdir -p "$output_dir"
output_dir=$(cd "$output_dir" && pwd -P)

cd "$app_dir"

case $target in
    play)
        ./gradlew --no-daemon :app:bundleRelease

        bundle="app/build/outputs/bundle/release/app-release.aab"
        [[ -f $bundle ]] || fail "Expected package was not produced: $bundle"
        cp -f "$bundle" "$output_dir/Passepartout.aab"

        if command -v jarsigner >/dev/null && \
            ! jarsigner -verify "$bundle" >/dev/null 2>&1; then
            echo "warning: Passepartout.aab is unsigned" >&2
        fi
        ;;
    *)
        usage >&2
        fail "Unknown target: $target"
        ;;
esac

echo "Package ready in $output_dir"
