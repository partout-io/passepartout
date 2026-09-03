#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
android_dir="$(cd "$script_dir/.." && pwd)"

gradle_args=(--no-daemon :app:publishReleaseListing)

if [[ "${1:-}" == "-force" ]]; then
    gradle_args+=(--rerun-tasks)
    shift
fi

if (( $# > 0 )); then
    echo "Usage: $(basename "$0") [-force]" >&2
    exit 2
fi

cd "$android_dir"
exec ./gradlew "${gradle_args[@]}"
