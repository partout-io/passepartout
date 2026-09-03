#!/bin/bash

# run inside macOS/tvOS

FILELIST="copyright.txt primary_category.txt primary_first_sub_category.txt primary_second_sub_category.txt review_information secondary_category.txt secondary_first_sub_category.txt secondary_second_sub_category.txt"
DST="../iOS"

rm *.txt
rm -rf review_information
for FILENAME in $FILELIST; do
    echo "Symlink $FILENAME to $DST/$FILENAME"
    ln -sf "$DST/$FILENAME"
done
