#!/bin/bash

# run inside iOS/macOS/tvOS directory

for SRC in `ls -d */`; do
    if [[ "$SRC" == "en-US/" ]] || [[ "$SRC" == "review_information/" ]]; then
        echo "Skip $SRC"
        continue
    fi
    DST="en-US"
    echo "Symlink from $SRC to $DST"
    cd $DST
    ln -sf "../$SRC/release_notes.txt"
    cd ..
done
