#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
cd $cwd/..

set -e
abi_schemas=$schemas_path/abi/*.json
abi_output="app-cross/Sources/CommonLibraryCore/Domain/Codegen/Quicktype.swift"
abi_prefix="Quicktype"

quicktype \
    -l swift \
    --no-initializers \
    --access-level public \
    --type-prefix $abi_prefix \
    --protocol equatable \
    --sendable \
    --density normal \
    -s schema $abi_schemas \
    -o $abi_output

# Replace import
sed -i '' "s/import Foundation/import Partout/" $abi_output

# Replace String with URL in fields ending in "URL"
sed -i '' 's/let \([A-Za-z0-9_ ,]*\)URL: String/let \1URL: URL/g' $abi_output
sed -i '' 's/\([A-Za-z0-9_]*\)URL: String/\1URL: URL/g' $abi_output

# Replace JSONAny with JSON in fields
sed -i '' "s/: JSONAny/: JSON/g" $abi_output

# Add "@unchecked Sendable" to JSONAny
sed -i '' "s/JSONAny: Codable/JSONAny: Codable, @unchecked Sendable/" $abi_output

# Make "JSONCodingKey" final
sed -i '' "s/^class JSONCodingKey/final class JSONCodingKey/" $abi_output

# Inject CaseIterable
echo >>$abi_output
echo "extension QuicktypeAppFeature: CaseIterable {}" >>$abi_output
echo "extension QuicktypeConfigFlag: CaseIterable {}" >>$abi_output
