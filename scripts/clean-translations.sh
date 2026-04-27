#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
cd $cwd/..

cd $translations_output_path

# Base language file
base_file="en.lproj/Localizable.strings"
base_entries_file="base.tmp"
keys_file="keys.tmp"

# Extract all keys and English entries from the base file
grep '^"' "$base_file" >"$base_entries_file"
sed -n 's/^"\(.*\)"[[:space:]]*=.*/"\1"/p' "$base_entries_file" >"$keys_file"

# Process all other localization files
for dir in *.lproj; do
    if [[ "$dir" != "en.lproj" && -d "$dir" ]]; then
        target_file="$dir/Localizable.strings"

        if [[ -f "$target_file" ]]; then
            echo "Cleaning $target_file..."

            # Use grep to filter only keys that exist in the base file
            grep -F -f "$keys_file" "$target_file" > "$target_file.tmp"
            mv "$target_file.tmp" "$target_file"

            # Exit if there are missing keys after printing them
            sed -n 's/^"\(.*\)"[[:space:]]*=.*/"\1"/p' "$target_file" >"$target_file.excluded"
            grep -F -v -f "$target_file.excluded" "$keys_file" >"$target_file.missing"
            if [[ -s "$target_file.missing" ]]; then
                grep -F -f "$target_file.missing" "$base_entries_file"
                rm "$base_entries_file"
                rm "$keys_file"
                rm "$target_file.excluded"
                rm "$target_file.missing"
                echo "Stopped."
                exit 1
            fi

            rm "$target_file.excluded"
            rm "$target_file.missing"
        fi
    fi
done

rm "$base_entries_file"
rm "$keys_file"
echo "Localization files cleaned."
