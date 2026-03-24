#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
cd $cwd/..

rm -rf "$translations_input_path"
mkdir -p "$translations_input_path"

# Split translations into separate files
awk -v input_path="$translations_input_path" '
BEGIN {
    lang_code = "";
}
/^\/\/ [a-z]{2}/ {
    # Save the language code from lines starting with "//"
    lang_code = substr($0, 4);  # Extract language code (e.g., "de")
    next;
}
/^$/ {
    # Skip empty lines
    next;
}
{
    # Write to the appropriate language file
    if (lang_code != "") {
        file_path = input_path "/" lang_code;
        print $0 >> file_path;
    }
}
' 

echo "Files have been created in the '$translations_input_path' directory."

for lang in `ls $translations_input_path`; do
    input_path="$translations_input_path/$lang"
    output_dir="$translations_output_path/$lang.lproj"
    output_path="$output_dir/Localizable.strings"
    keys_path="$output_path.keys"
    tmp_path="$output_path.tmp"

    mkdir -p "$output_dir"

    # remove keys
    grep '^"' $input_path | sed -E 's/^"(.*)" = .*$/"\1"/' >$keys_path
    grep -vf $keys_path $output_path >$tmp_path

    # append new strings
    cat $input_path >>$tmp_path

    # sort and replace
    sort $tmp_path | uniq >$output_path
    rm "$keys_path" "$tmp_path"
done
