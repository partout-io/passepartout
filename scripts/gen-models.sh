#!/bin/bash
set -e

script_dir="$(cd "$(dirname "$0")" && pwd)"
root_dir="$(cd "$script_dir/.." && pwd)"
cd "$root_dir"
source "$script_dir/env.sh"

usage() {
    echo "Usage: $0 [all|swift|kotlin]"
    exit 1
}

mode=${1:-all}
if [[ $# -gt 0 ]]; then
    shift
fi
if [[ $# -gt 0 ]]; then
    usage
fi

generate_partout_models() {
    pushd partout
    scripts/build.sh -gen-models
    popd
}

generate_swift_models() {
    infile=scripts/openapi.yaml
    models_dir=`realpath app-shared/Sources/CommonLibraryCore/Domain`
    models_tmp=$models_dir/tmp
    models_out=$models_tmp/Sources/OpenAPIClient/Models
    models_gen=$models_dir/Codegen
    abi_prefix=OpenAPI

    # TaggedProfile is an external Partout type. Keep the schema ref, but do not
    # generate a Swift model for it here.
    $codegen generate \
        -i $infile \
        -o $models_tmp \
        -g swift6 \
        --global-property=models,modelDocs=false,modelTests=false \
        --type-mappings JSONValue=JSON \
        --schema-mappings ConnectionStatus=ConnectionStatus \
        --schema-mappings ModuleType=ModuleType \
        --schema-mappings TaggedProfile=TaggedProfile \
        --import-mappings JSONValue=JSON \
        --model-name-prefix=$abi_prefix \
        --additional-properties=enumPropertyNaming=original

    # Flatten output directory
    rm -rf $models_gen
    mv $models_out $models_gen
    rm -rf $models_tmp

    abi_output=$models_gen/*.swift

    # Replace Foundation imports
    sed -i '' "s/import Foundation/import Partout/" $abi_output

    # Replace String with URL in fields ending in "URL"
    sed -i '' 's/let \([A-Za-z0-9_ ,]*\)URL: String/let \1URL: URL/g' $abi_output
    sed -i '' 's/\([A-Za-z0-9_]*\)URL: String/\1URL: URL/g' $abi_output

    # Replace external Partout types
    sed -i '' 's/OpenAPIConnectionStatus/ConnectionStatus/g' $models_gen/${abi_prefix}*.swift
    sed -i '' 's/OpenAPIModuleType/ModuleType/g' $models_gen/${abi_prefix}*.swift
    sed -i '' 's/OpenAPITaggedProfile/TaggedProfile/g' $models_gen/${abi_prefix}*.swift

    # openapi-generator models the event discriminator as a regular property.
    # Keep the Swift payloads aligned with the ABI by hardcoding the discriminator
    # value in the generated event subtypes.
    for file in $models_gen/*Event*.swift; do
        case "$(basename "$file")" in
            OpenAPIEvent.swift) continue ;;
        esac

        ruby -i -pe '
            if !$patched
                if (case_line = $_.match(/case ([A-Za-z0-9_]+) = \"([^\"]+)\"/))
                    $case_name = case_line[1]
                    $patched = true
                end
            end

            if $patched
                constant = ".#{$case_name}"
                $_ = $_.sub(/public var type: OpenAPIType(?: = \.[A-Za-z0-9_]+)?/, "public let type: OpenAPIType = #{constant}")
                $_ = $_.sub(/public init\(type: OpenAPIType(?: = \.[A-Za-z0-9_]+)?(?:, )?/, "public init(")
                $_ = $_.gsub(/^\s*self\.type = (?:type|\.[A-Za-z0-9_]+)\n/m, "")
            end
        ' "$file"
    done
}

generate_kotlin_models() {
    openapi=`realpath scripts/openapi.yaml`
    models_dir=`realpath app-android/app`
    package_name=com.algoritmico.passepartout.models
    extra_imports="ConnectionStatus,ModuleType,TaggedProfile"

    # Clean up
    rm -rf $models_dir/src/main/kotlin/com/algoritmico/passepartout/models

    # Enter package
    pushd partout

    # Generate Passepartout models
    echo "Generate kotlin models..."
    scripts/gen-models.sh \
        $openapi \
        kotlin \
        $models_dir \
        $package_name \
        $extra_imports

    # Exit package
    popd
}

case $mode in
    all)
        generate_partout_models
        generate_swift_models
        generate_kotlin_models
        ;;
    swift)
        generate_partout_models
        generate_swift_models
        ;;
    kotlin)
        generate_partout_models
        generate_kotlin_models
        ;;
    -*|--*|*)
        usage
        ;;
esac
