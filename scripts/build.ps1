$cwd = Get-Location
$root_dir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$build_dir = ".cmake"
$bin_dir = "bin"
$configuration = "Release"
$generator = "Ninja Multi-Config"

$index = 0
while ($index -lt $args.Count) {
    switch ($args[$index]) {
        "-config" {
            if (($index + 1) -ge $args.Count -or $args[$index + 1].StartsWith("-")) {
                Write-Error "-config requires a value"
                exit 1
            }
            $configuration = $args[$index + 1]
            $index += 2
        }
        "-generator" {
            if (($index + 1) -ge $args.Count -or $args[$index + 1].StartsWith("-")) {
                Write-Error "-generator requires a value"
                exit 1
            }
            $generator = $args[$index + 1]
            $index += 2
        }
        default {
            Write-Error "Unknown option $($args[$index])"
            exit 1
        }
    }
}

$swift_arch = switch ($env:PROCESSOR_ARCHITECTURE) {
    "ARM64" { "aarch64" }
    "AMD64" { "x86_64" }
    default { $env:PROCESSOR_ARCHITECTURE } # fallback for other values
}

$swift_root = "$env:USERPROFILE/AppData/Local/Programs/Swift"
$swift_version = "6.3.1"
$output_dir = "$root_dir/$bin_dir/windows-$swift_arch"
$dist_dir = "$root_dir/dist"
$is_multi_config = $generator -match "Multi-Config|Visual Studio|Xcode"

try {
    Set-Location -Path "$root_dir"

    # Create build folder if it doesn't exist
    if (-not (Test-Path -Path "$build_dir")) {
        New-Item -ItemType Directory -Path "$build_dir" | Out-Null
    }

    # Change directory to build
    Set-Location -Path "$build_dir"

    # Run CMake
    $cmake_opts = @(
        "-G", $generator,
        "-DOUTPUT_DIR=$output_dir",
        "-DCMAKE_INSTALL_LIBDIR=.",
        "-DCMAKE_INSTALL_BINDIR=.",
        "-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL",
        "-DSWIFT_ROOT=$swift_root",
        "-DSWIFT_VERSION=$swift_version",
        "-DBUILD_APP=ON"
    )
    if ($is_multi_config) {
        $cmake_opts += "-DCMAKE_CONFIGURATION_TYPES=$configuration"
    } else {
        $cmake_opts += "-DCMAKE_BUILD_TYPE=$configuration"
    }
    cmake @cmake_opts ..

    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    cmake --build . --config "$configuration"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    cmake --install . --config "$configuration" --prefix "$dist_dir"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Set-Location -Path $cwd
}
