#!/bin/bash
set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$script_dir/../app-apple/scripts/import-translations-txts.sh"
"$script_dir/../app-android/scripts/import-apple-strings.sh"
