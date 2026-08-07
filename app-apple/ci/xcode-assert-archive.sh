#!/bin/bash
set -euo pipefail

archive_path=${1:-}
developer_id=${2:-}
framework_name="PartoutNative.framework"
framework_install_name="@rpath/$framework_name/PartoutNative"

fail() {
    echo "Archive assertion failed: $*" >&2
    exit 1
}

bundle_info_plist() {
    local bundle=$1
    if [[ -f "$bundle/Contents/Info.plist" ]]; then
        echo "$bundle/Contents/Info.plist"
    elif [[ -f "$bundle/Info.plist" ]]; then
        echo "$bundle/Info.plist"
    else
        fail "missing Info.plist in $bundle"
    fi
}

bundle_executable() {
    local bundle=$1
    local info_plist
    local executable
    info_plist=$(bundle_info_plist "$bundle")
    executable=$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$info_plist")
    if [[ -f "$bundle/Contents/MacOS/$executable" ]]; then
        echo "$bundle/Contents/MacOS/$executable"
    elif [[ -f "$bundle/$executable" ]]; then
        echo "$bundle/$executable"
    else
        fail "missing executable $executable in $bundle"
    fi
}

bundle_identifier() {
    local info_plist
    info_plist=$(bundle_info_plist "$1")
    /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$info_plist"
}

assert_loads_framework() {
    local binary=$1
    local dependencies
    dependencies=$(otool -L "$binary")
    [[ "$dependencies" == *"$framework_install_name"* ]] || \
        fail "$binary does not load $framework_install_name"
}

assert_rpath() {
    local binary=$1
    local expected=$2
    local load_commands
    load_commands=$(otool -l "$binary")
    [[ "$load_commands" == *"path $expected (offset"* ]] || \
        fail "$binary is missing LC_RPATH $expected"
}

assert_framework_install_name() {
    local framework_binary=$1
    local install_names
    install_names=$(otool -D "$framework_binary")
    [[ "$install_names" == *"$framework_install_name"* ]] || \
        fail "$framework_binary has an unexpected install name"
}

assert_single_framework() {
    local app=$1
    local expected=$2
    local found=()
    local path
    while IFS= read -r path; do
        found[${#found[@]}]=$path
    done < <(find "$app" -type d -name "$framework_name" -prune -print)

    [[ ${#found[@]} -eq 1 ]] || \
        fail "expected exactly one $framework_name in $app, found ${#found[@]}"
    [[ "${found[0]}" == "$expected" ]] || \
        fail "expected $framework_name at $expected, found ${found[0]}"
    [[ -f "$expected/PartoutNative" ]] || \
        fail "missing framework binary at $expected/PartoutNative"
}

[[ -n "$archive_path" ]] || fail "usage: $0 <archive-path> [developer-id]"
[[ -d "$archive_path" ]] || fail "archive does not exist: $archive_path"

shopt -s nullglob
apps=("$archive_path/Products/Applications/"*.app)
[[ ${#apps[@]} -eq 1 ]] || \
    fail "expected exactly one archived app, found ${#apps[@]}"
app=${apps[0]}
app_binary=$(bundle_executable "$app")

if [[ "$developer_id" == 1 ]]; then
    system_extensions=("$app/Contents/Library/SystemExtensions/"*.systemextension)
    [[ ${#system_extensions[@]} -eq 1 ]] || \
        fail "expected exactly one system extension, found ${#system_extensions[@]}"
    system_extension=${system_extensions[0]}
    system_extension_name=$(basename "$system_extension")
    system_extension_id=$(bundle_identifier "$system_extension")
    [[ "$system_extension_name" == "$system_extension_id.systemextension" ]] || \
        fail "system extension filename does not match CFBundleIdentifier: $system_extension_name"

    expected_framework="$system_extension/Contents/Frameworks/$framework_name"
    assert_single_framework "$app" "$expected_framework"
    assert_framework_install_name "$expected_framework/PartoutNative"

    system_extension_binary=$(bundle_executable "$system_extension")
    assert_loads_framework "$app_binary"
    assert_rpath "$app_binary" \
        "@executable_path/../Library/SystemExtensions/$system_extension_name/Contents/Frameworks"
    assert_loads_framework "$system_extension_binary"
    assert_rpath "$system_extension_binary" "@executable_path/../Frameworks"
else
    if [[ -d "$app/Contents" ]]; then
        expected_framework="$app/Contents/Frameworks/$framework_name"
        tunnel="$app/Contents/PlugIns/PassepartoutTunnel.appex"
        app_rpath="@executable_path/../Frameworks"
        tunnel_rpath="@executable_path/../../../../Frameworks"
    else
        expected_framework="$app/Frameworks/$framework_name"
        tunnel="$app/PlugIns/PassepartoutTunnel.appex"
        app_rpath="@executable_path/Frameworks"
        tunnel_rpath="@executable_path/../../Frameworks"
    fi

    [[ -d "$tunnel" ]] || fail "missing tunnel extension at $tunnel"
    assert_single_framework "$app" "$expected_framework"
    assert_framework_install_name "$expected_framework/PartoutNative"

    tunnel_binary=$(bundle_executable "$tunnel")
    assert_loads_framework "$app_binary"
    assert_rpath "$app_binary" "$app_rpath"
    assert_loads_framework "$tunnel_binary"
    assert_rpath "$tunnel_binary" "$tunnel_rpath"
fi

echo "Archive layout verified: $archive_path"
