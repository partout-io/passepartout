$Arch = "arm64"
cmake --preset "windows-$Arch"
cmake --build --preset "windows-$Arch-debug" --target clean
Measure-Command {
    cmake --build --preset "windows-$Arch-debug" --parallel 8 | Out-Host
}
