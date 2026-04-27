#!/bin/bash
ref_from=$1
ref_to=$2
if [[ -z $ref_from ]]; then
    echo "Initial ref required"
    exit 1
fi
if [[ -z $ref_to ]]; then
    ref_to="HEAD"
fi

old_modules=(`git diff "${ref_from}".."${ref_to}" app-cross/partout/ | grep -- "-Subproject" | cut -d ' ' -f 3 | tr "\n" " "`)
new_modules=(`git diff "${ref_from}".."${ref_to}" app-cross/partout/ | grep -- "\+Subproject" | cut -d ' ' -f 3 | tr "\n" " "`)
partout_range="${old_modules[0]}..${new_modules[0]}"
partout_core_range="${old_modules[1]}..${new_modules[1]}"

function git_cmd() {
    local from=$1
    local to=$2
    if [[ -z $from || -z $to ]]; then
        return
    fi
    name=$(basename $(pwd))
    echo "=== $name ==="
    echo ""
    git --no-pager log ${from}..${to} --oneline
    echo ""
}

git_cmd $ref_from $ref_to
(cd app-cross/partout && git_cmd ${old_modules[0]} ${new_modules[0]})
