#!/bin/bash
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
tmp_plist="$TMPDIR/options.$platform.plist"

if [[ $developer_id == 1 ]]; then
    sed "s/CFG_TEAM_ID/$team_id/g" "$cwd/export/options_dmg.plist" >"$tmp_plist"
else
    sed "s/CFG_TEAM_ID/$team_id/g" "$cwd/export/options.plist" | \
        sed "s/CFG_PLATFORM/$platform/g" >"$tmp_plist"
fi

xcodebuild -exportArchive \
    -archivePath "$src/$platform/$project_name.xcarchive" \
    -exportPath "$dst/$platform" \
    -exportOptionsPlist "$tmp_plist"

rm "$tmp_plist"
