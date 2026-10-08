#!/bin/bash
set -e
cwd=`dirname $0`
team_id=`$cwd/team-id.sh`
platform=$1
developer_id=$2
if [[ -z $platform ]]; then
    echo "Missing platform"
    exit 1
fi
project_name="Passepartout"
src="build"
dst="dist"
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/passepartout-export.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT
tmp_plist="$tmp_dir/options.plist"
authentication_args=()

if [[ $developer_id == 1 ]]; then
    sed "s/CFG_TEAM_ID/$team_id/g" "$cwd/export/options_dmg.plist" >"$tmp_plist"
else
    sed "s/CFG_TEAM_ID/$team_id/g" "$cwd/export/options.plist" >"$tmp_plist"
    authentication_args=(-allowProvisioningUpdates)
    if [[ -n ${APP_STORE_CONNECT_API_KEY:-} ]]; then
        # Reuse the Fastlane API key JSON without putting private key contents in argv.
        authentication_ids=$(ruby -rjson -rbase64 -e '
            begin
                api_key = JSON.parse(ENV.fetch("APP_STORE_CONNECT_API_KEY"))
                key_id = api_key.fetch("key_id")
                issuer_id = api_key.fetch("issuer_id")
                key = api_key.fetch("key")
                raise unless key_id.is_a?(String) && key_id.match?(/\A[A-Za-z0-9]+\z/)
                raise unless issuer_id.is_a?(String) && issuer_id.match?(/\A[A-Za-z0-9-]+\z/)
                raise unless key.is_a?(String) && !key.empty?
                key = Base64.decode64(key) if api_key["is_key_content_base64"]
                File.write(ARGV.fetch(0), key, perm: 0600)
                puts "#{key_id} #{issuer_id}"
            rescue StandardError
                abort "Invalid APP_STORE_CONNECT_API_KEY: expected key_id, issuer_id, and key"
            end
        ' "$tmp_dir/AuthKey.p8")
        read -r key_id issuer_id <<< "$authentication_ids"
        authentication_args+=(
            -authenticationKeyPath "$tmp_dir/AuthKey.p8"
            -authenticationKeyID "$key_id"
            -authenticationKeyIssuerID "$issuer_id"
        )
    elif [[ ${CI:-} == true ]]; then
        echo "Missing APP_STORE_CONNECT_API_KEY for automatic signing in CI" >&2
        exit 1
    fi
fi

xcodebuild -exportArchive \
    -archivePath "$src/$platform/$project_name.xcarchive" \
    -exportPath "$dst/$platform" \
    -exportOptionsPlist "$tmp_plist" \
    "${authentication_args[@]}"
