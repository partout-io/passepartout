#!/bin/bash
cwd=`dirname $0`
source $cwd/env.sh
cd $cwd/..

set -e
abi_schemas=$schemas_path/abi/*.json
abi_output="app-cross/Sources/CommonLibraryCore/DomainCodegen/Quicktype.swift"
abi_prefix="Quicktype"

quicktype \
    -l swift \
    --no-initializers \
    --access-level public \
    --type-prefix $abi_prefix \
    --protocol equatable \
    --sendable \
    -s schema $abi_schemas \
    -o $abi_output

# Replace import
sed -i '' "s/import Foundation/import Partout/" $abi_output

# Replace Data with JSON in fields
sed -i '' "s/data: ${abi_prefix}Data/data: [String: JSON]/g" $abi_output

# Drop "Equatable" from Data/Datum
sed -i '' "s/${abi_prefix}Data: Codable, Equatable, Sendable/${abi_prefix}Data: Codable, Sendable/" $abi_output
sed -i '' "s/${abi_prefix}Datum: Codable, Equatable, Sendable/${abi_prefix}Datum: Codable, Sendable/" $abi_output

# Add "@unchecked Sendable" to JSONAny
sed -i '' "s/JSONAny: Codable/JSONAny: Codable, @unchecked Sendable/" $abi_output

# Make "JSONCodingKey" final
sed -i '' "s/^class JSONCodingKey/final class JSONCodingKey/" $abi_output

# Inject CaseIterable
echo >>$abi_output
echo "extension QuicktypeAppFeature: CaseIterable {}" >>$abi_output
echo "extension QuicktypeConfigFlag: CaseIterable {}" >>$abi_output
