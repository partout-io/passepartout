#!/bin/bash

# run inside macOS/tvOS for each language
LANGUAGE=$1
PLATFORM=`basename $(pwd)`

# except release_notes.txt
FILELIST="apple_tv_privacy_policy.txt keywords.txt marketing_url.txt name.txt privacy_url.txt promotional_text.txt subtitle.txt support_url.txt"

# except description.txt on tvOS
if [[ $PLATFORM == "macOS" ]]; then
    FILELIST="$FILELIST description.txt"
fi

DST="../../iOS/$LANGUAGE"

cd $LANGUAGE
for FILENAME in $FILELIST; do
    SRC_PATH="$FILENAME"
    rm -f $SRC_PATH
    echo "Symlink $SRC_PATH to $DST/$FILENAME"
    ln -sf "$DST/$FILENAME"
done
