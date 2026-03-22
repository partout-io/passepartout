#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
cd $cwd/..

set -e
infile=app-cross/abi.yaml
models_dir=app-cross/Sources/CommonLibraryCore/Domain
models_tmp=$models_dir/tmp
models_out=$models_tmp/Sources/OpenAPIClient/Models
models_gen=$models_dir/Codegen
abi_prefix=OpenAPI

$codegen generate \
    -i $infile \
    -o $models_tmp \
    -g swift6 \
    --global-property=models,modelDocs=false,modelTests=false \
    --type-mappings JSONValue=JSON \
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
