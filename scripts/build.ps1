$cwd = Get-Location
$build_dir = ".cmake"
$bin_dir = "bin"
$build_type = "Release"

$swift_arch = switch ($env:PROCESSOR_ARCHITECTURE) {
    "ARM64" { "aarch64" }
    "AMD64" { "x86_64" }
    default { $env:PROCESSOR_ARCHITECTURE } # fallback for other values
}

$swift_root = "$env:USERPROFILE/AppData/Local/Programs/Swift"
$swift_version = "6.2.1"
$env:SWIFT_SDK = "$swift_root/Platforms/$swift_version/Windows.platform/Developer/SDKs/Windows.sdk/usr/lib/swift/windows/$swift_arch"
$env:SWIFT_RUNTIME = "$swift_root/Runtimes/$swift_version/usr/bin"

try {
    # Remove all .txt files in the build folder
    Remove-Item -Path "$build_dir\*.txt" -ErrorAction SilentlyContinue

    # Create build folder if it doesn't exist
    if (-not (Test-Path -Path "$build_dir")) {
        New-Item -ItemType Directory -Path "$build_dir" | Out-Null
    }

    # Change directory to build
    Set-Location -Path "$build_dir"

    # Run CMake
    #cmake -G "Visual Studio 17 2022" -DBUILD_APP=ON ..
    cmake -G "Ninja" -DCMAKE_BUILD_TYPE="$build_type" -DCMAKE_CONFIGURATION_TYPES="$build_type" -DBUILD_APP=ON ..

    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    cmake --build . --config "$build_type"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Set-Location -Path $cwd
}
