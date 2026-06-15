#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: $0 [-n|--dry-run] BUILD_NUMBER"
    echo
    echo "Deletes local and remote tags named builds/N where N < BUILD_NUMBER."
    echo "Remote tags are deleted from origin and github."
}

dry_run=0
build_arg=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run)
            dry_run=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*|--*)
            echo "Unknown option $1"
            usage
            exit 1
            ;;
        *)
            if [[ -n "$build_arg" ]]; then
                echo "Too many arguments"
                usage
                exit 1
            fi
            build_arg="$1"
            shift
            ;;
    esac
done

if [[ -z "$build_arg" ]]; then
    echo "Missing BUILD_NUMBER"
    usage
    exit 1
fi

if ! [[ "$build_arg" =~ ^[0-9]+$ ]]; then
    echo "BUILD_NUMBER must be a positive integer"
    exit 1
fi

build_limit=$((10#$build_arg))
if [[ $build_limit -lt 1 ]]; then
    echo "BUILD_NUMBER must be a positive integer"
    exit 1
fi

remotes=(origin github)

for remote in "${remotes[@]}"; do
    if ! git remote get-url "$remote" >/dev/null 2>&1; then
        echo "Missing required remote: $remote"
        exit 1
    fi
done

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/clean-build-tags.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT

append_if_old_build_tag() {
    local tag="$1"
    local output="$2"
    local build_number

    if [[ "$tag" =~ ^builds/([0-9]+)$ ]]; then
        build_number=$((10#${BASH_REMATCH[1]}))
        if [[ $build_number -lt $build_limit ]]; then
            echo "$tag" >>"$output"
        fi
    fi
}

print_tags() {
    local input="$1"
    local tag

    while IFS= read -r tag; do
        echo "  $tag"
    done <"$input"
}

collect_local_tags() {
    local output="$1"
    local tag

    git tag -l 'builds/*' | while IFS= read -r tag; do
        append_if_old_build_tag "$tag" "$output"
    done
    sort -u "$output" -o "$output"
}

collect_remote_tags() {
    local remote="$1"
    local output="$2"
    local ref
    local tag

    git ls-remote --tags --refs "$remote" 'refs/tags/builds/*' | while read -r _ ref; do
        tag="${ref#refs/tags/}"
        append_if_old_build_tag "$tag" "$output"
    done
    sort -u "$output" -o "$output"
}

delete_local_tags() {
    local input="$1"
    local tag

    if [[ ! -s "$input" ]]; then
        echo "No local builds/N tags below $build_limit"
        return
    fi

    if [[ $dry_run -eq 1 ]]; then
        echo "Would delete local tags:"
        print_tags "$input"
        return
    fi

    echo "Deleting local tags:"
    print_tags "$input"
    while IFS= read -r tag; do
        git tag -d "$tag"
    done <"$input"
}

delete_remote_tags() {
    local remote="$1"
    local input="$2"
    local tag
    local refspecs=()

    if [[ ! -s "$input" ]]; then
        echo "No $remote builds/N tags below $build_limit"
        return
    fi

    if [[ $dry_run -eq 1 ]]; then
        echo "Would delete $remote tags:"
        print_tags "$input"
        return
    fi

    echo "Deleting $remote tags:"
    print_tags "$input"
    while IFS= read -r tag; do
        refspecs+=(":refs/tags/$tag")
    done <"$input"
    git push "$remote" "${refspecs[@]}"
}

local_tags="$tmp_dir/local"
touch "$local_tags"
collect_local_tags "$local_tags"

for remote in "${remotes[@]}"; do
    remote_tags="$tmp_dir/$remote"
    touch "$remote_tags"
    collect_remote_tags "$remote" "$remote_tags"
done

delete_local_tags "$local_tags"

for remote in "${remotes[@]}"; do
    remote_tags="$tmp_dir/$remote"
    delete_remote_tags "$remote" "$remote_tags"
done
