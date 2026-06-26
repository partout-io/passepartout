#!/bin/bash
platforms="iOS macOS tvOS"
changelog="CHANGELOG.txt"
metadata_root="fastlane/metadata"
metadata_path="default/release_notes.txt"
translations_input_path="l10n"
translations_output_path="app-apple/Sources/AppStrings/Resources"
cmake_toolchains_path="partout/cmake/swift"
cmake_swift_version=6.3.1
codegen=$(pwd)/node_modules/.bin/openapi-generator-cli
