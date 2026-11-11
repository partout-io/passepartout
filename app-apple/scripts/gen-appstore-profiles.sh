#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
source "$script_dir/env.sh"
source "$script_dir/../fastlane/.env.secret"

usage() {
    cat <<'EOF'
Usage: FASTLANE_USER=<apple-id> SIGH_CERT_ID=<certificate-id> \
       scripts/gen-appstore-profiles.sh [output-directory]

Regenerate the iOS, tvOS, and macOS App Store profiles for the app and Tunnel
using an existing distribution certificate. Apple ID login may require 2FA.
SIGH_CERT_ID is Apple's certificate record ID, not a keychain name or SHA-1.

Defaults to the Xcode provisioning profile directory used by export-certs.sh.
Relative output directories are resolved against the current working directory.
EOF
}

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
    usage
    exit 0
fi

if [[ $# -gt 1 ]]; then
    usage >&2
    exit 1
fi

: "${FASTLANE_USER:?Set FASTLANE_USER to your Apple ID}"
: "${SIGH_CERT_ID:?Set SIGH_CERT_ID to your distribution certificate record ID}"

profiles_dir=${1:-$certs_profiles_root}
mkdir -p "$profiles_dir"
profiles_dir=$(cd "$profiles_dir" && pwd -P)
cd "$script_dir/.."
team_id=$(ci/team-id.sh)

for platform in ios tvos macos; do
    case "$platform" in
        ios) label=iOS ;;
        tvos) label=tvOS ;;
        macos) label=macOS ;;
    esac

    for target in app tunnel; do
        bundle_id="com.algoritmico.ios.Passepartout"
        profile_name="Passepartout AppStore $label"
        if [[ $target == tunnel ]]; then
            bundle_id="$bundle_id.Tunnel"
            profile_name="Passepartout AppStore Tunnel $label"
        fi

        echo "Generating $profile_name"
        bundle exec fastlane sigh \
            --team_id "$team_id" \
            --username "$FASTLANE_USER" \
            --platform "$platform" \
            --app_identifier "$bundle_id" \
            --provisioning_name "$profile_name" \
            --ignore_profiles_with_different_name \
            --output_path "$profiles_dir" \
            --skip_install \
            --force
    done
done

echo "App Store profiles saved in $profiles_dir"
