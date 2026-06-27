$cwd = Get-Location
$root_dir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$build_dir = ".cmake"
$bin_dir = "bin"
$build_type = "Release"

$swift_arch = switch ($env:PROCESSOR_ARCHITECTURE) {
    "ARM64" { "aarch64" }
    "AMD64" { "x86_64" }
    default { $env:PROCESSOR_ARCHITECTURE } # fallback for other values
}

$swift_root = "$env:USERPROFILE/AppData/Local/Programs/Swift"
$swift_version = "6.3.1"
$output_dir = "$root_dir/$bin_dir/windows-$swift_arch"
$dist_dir = "$root_dir/dist"

try {
    Set-Location -Path "$root_dir"

    # Create build folder if it doesn't exist
    if (-not (Test-Path -Path "$build_dir")) {
        New-Item -ItemType Directory -Path "$build_dir" | Out-Null
    }

    # Change directory to build
    Set-Location -Path "$build_dir"

    # Run CMake
    #cmake -G "Visual Studio 17 2022" -DBUILD_APP=ON ..
    cmake -G "Ninja" -DCMAKE_BUILD_TYPE="$build_type" `
        -DCMAKE_CONFIGURATION_TYPES="$build_type" `
        -DOUTPUT_DIR="$output_dir" `
        -DCMAKE_INSTALL_LIBDIR="." `
        -DCMAKE_INSTALL_BINDIR="." `
        -DSWIFT_ROOT="$swift_root" `
        -DSWIFT_VERSION="$swift_version" `
        -DBUILD_APP=ON ..

    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    cmake --build . --config "$build_type"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    cmake --install . --config "$build_type" --prefix "$dist_dir"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Set-Location -Path $cwd
}
