#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
cd $cwd/..

set -e
abi_schemas=$schemas_path/abi/*.json
abi_output="app-android/app/src/main/java/com/algoritmico/passepartout/abi/ABIEntities.kt"
abi_package="com.algoritmico.passepartout.abi"

quicktype \
    -l kotlin \
    --framework kotlinx \
    --package $abi_package \
    -s schema $abi_schemas \
    -o $abi_output

# Inject sealed ABIEvent
awk '
/^data class .*Event/ {           # match lines with "data class" AND "Event"
    inEventClass = 1              # flag to indicate we are inside target class
}
inEventClass && /^[[:space:]]*\)[[:space:]]*$/ {  # line with only ")"
    sub(/\)[[:space:]]*$/, ") : ABIEvent()")
    inEventClass = 0             # reset flag after modification
}
{ print }
' $abi_output >$abi_output.tmp
mv $abi_output.tmp $abi_output

sed -E '/^class .*Event.*\(\)/ s/\(\)$/(): ABIEvent()/' $abi_output >$abi_output.tmp

event=$(cat <<EVENT
@Serializable
sealed class ABIEvent
EVENT
)
echo $event >>$abi_output.tmp
mv $abi_output.tmp $abi_output
