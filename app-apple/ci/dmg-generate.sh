#!/bin/bash
cwd=`dirname $0`
name="Passepartout"
arch="$1"
is_template="$2"
if [[ -z "$arch" ]]; then
    echo "Missing arch"
    exit 1
fi

version=`$cwd/version-number.sh`
volname="$name $version $arch"
srcfolder="$cwd/dmg"
dmg="$name.$arch"

set -e

echo "Copy .app to .dmg contents..."
cp -RH "dist/macOS/$name.app" "$srcfolder"

echo "Add link to /Applications..."
ln -sf /Applications "$srcfolder/Applications"

if [[ -n "$is_template" ]]; then
    echo "Create template $volname..."
    diskutil image create from \
        --volumeName "$volname" \
        --format RAW \
        "$srcfolder" \
        "$dmg.template.dmg"

    echo "Mount template $volname..."
    mnt="/Volumes/$volname"
    hdiutil attach "$dmg.template.dmg" \
        -mountpoint "$mnt" \
        -readwrite -noautoopen

    echo "Reapply .DS_Store..."
    cp "$srcfolder/.DS_Store" "$mnt"
    chmod 644 "$mnt/.DS_Store"

    # stop at template to edit .DS_Store
    exit
fi

echo "Create $volname..."
diskutil image create from \
    --volumeName "$volname" \
    --format UDZO \
    "$srcfolder" \
    "$dmg.dmg"
