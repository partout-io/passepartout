$cwd = Get-Location
$root_dir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$source_dir = Join-Path $root_dir "app-cross"
$build_dir = Join-Path $root_dir ".cmake"
$bin_dir = "bin"
$configuration = "Debug"
$generator = "Ninja Multi-Config"
$gen_build = $false
$build_app = $false
$prebuiltsVersion = (Get-Content -Raw (Join-Path $root_dir "prebuilts-version.txt")).Trim()

$index = 0
while ($index -lt $args.Count) {
    switch ($args[$index]) {
        "-gen" {
            $gen_build = $true
            $index += 1
        }
        "-config" {
            if (($index + 1) -ge $args.Count -or $args[$index + 1].StartsWith("-")) {
                Write-Error "-config requires a value"
                exit 1
            }
            $configuration = $args[$index + 1]
            $index += 2
        }
        "-app" {
            $build_app = $true
            $index += 1
        }
        "-prebuilts" {
            if (($index + 1) -ge $args.Count -or $args[$index + 1].StartsWith("-")) {
                Write-Error "-prebuilts requires a version"
                exit 1
            }
            $prebuiltsVersion = $args[$index + 1]
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

if ($prebuiltsVersion -notmatch '^[0-9A-Za-z][0-9A-Za-z._+-]*$') {
    Write-Error "Invalid prebuilts version: $prebuiltsVersion"
    exit 1
}

$bin_arch = switch ($env:PROCESSOR_ARCHITECTURE) {
    "ARM64" { "aarch64" }
    "AMD64" { "x86_64" }
    default { $env:PROCESSOR_ARCHITECTURE } # fallback for other values
}

$output_dir = "$root_dir/$bin_dir/windows-$bin_arch"
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
        "-DPASSEPARTOUT_PREBUILTS_VERSION=$prebuiltsVersion"
    )
    if ($is_multi_config) {
        $cmake_opts += "-DCMAKE_CONFIGURATION_TYPES=$configuration"
    } else {
        $cmake_opts += "-DCMAKE_BUILD_TYPE=$configuration"
    }
    if ($build_app) {
        $cmake_opts += "-DBUILD_APP=ON"
    } else {
        $cmake_opts += "-DBUILD_APP=OFF"
    }
    if ($gen_build) {
        cmake @cmake_opts $source_dir
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }

    cmake --build . --config "$configuration"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    cmake --install . --config "$configuration" --prefix "$dist_dir" --strip
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Set-Location -Path $cwd
}
