#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
cd $cwd/..

set -e
infile=app-cross/abi.yaml
models_dir=`realpath app-android/app`
abi_package=com.algoritmico.passepartout.abi

# Clean up
rm -rf $models_dir/src/main/kotlin/io/partout/abi
rm -rf $models_dir/src/main/kotlin/com/algoritmico/passepartout/abi

# Generate Partout entities
( cd app-cross/partout && scripts/gen-models.sh kotlin $models_dir )

# Generate Passepartout ABI entities
npx --no-install openapi-generator-cli generate \
    -i $infile \
    -o $models_dir \
    -g kotlin \
    --global-property=models,modelDocs=false,modelTests=false \
    --type-mappings number=Double,URI=String \
    --import-mappings Double=kotlin.Double,String=kotlin.String \
    --additional-properties=serializationLibrary=kotlinx_serialization \
    --additional-properties=packageName=$abi_package \
    --additional-properties=modelPackage=$abi_package
