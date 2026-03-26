#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
cd $cwd/..

set -e
partout_infile=app-cross/partout/scripts/openapi.yaml
partout_package=io.partout.abi
abi_infile=app-cross/abi.yaml
abi_package=com.algoritmico.passepartout.abi
models_dir=`realpath app-android/app`

# Clean up
rm -rf $models_dir/src/main/kotlin/io/partout/abi
rm -rf $models_dir/src/main/kotlin/com/algoritmico/passepartout/abi

shared_flags=(
    -o "$models_dir"
    -g kotlin
    --global-property=models,modelDocs=false,modelTests=false
    --type-mappings number=Double,URI=String,kotlin.Any=kotlinx.serialization.json.JsonElement
    --import-mappings Double=kotlin.Double,String=kotlin.String
    --additional-properties=serializationLibrary=kotlinx_serialization
)

# Generate Partout entities
"$codegen" generate \
    -i "$partout_infile" \
    --additional-properties=packageName=$partout_package \
    --additional-properties=modelPackage=$partout_package \
    "${shared_flags[@]}"

# Generate Passepartout ABI entities
"$codegen" generate \
    -i "$abi_infile" \
    --additional-properties=packageName=$abi_package \
    --additional-properties=modelPackage=$abi_package \
    --schema-mappings TaggedProfile=TaggedProfile \
    --import-mappings TaggedProfile=io.partout.abi.TaggedProfile \
    "${shared_flags[@]}"
