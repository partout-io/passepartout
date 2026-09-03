#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
android_dir="$(cd "$script_dir/.." && pwd)"

cd "$android_dir"
exec ./gradlew --no-daemon :app:publishReleaseListing --rerun-tasks
