$Arch = "arm64"
$Preset = "windows-$Arch-debug"
$Jobs = 8
cmake --preset "windows-$Arch"
cmake --build --preset $Preset --parallel $Jobs | Out-Host
cmake --build --preset $Preset --target clean
Measure-Command {
    cmake --build --preset $Preset --parallel $Jobs | Out-Host
}
