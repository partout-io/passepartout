# Windows integration checkpoint

The frontend and VPN plugin share an MSIX identity. The initial target is Windows
11, with the existing x64 and ARM64 builds. Distribution and signing identity
still require a release decision. Changing the publisher changes package identity.

Configure with `BUILD_APP=ON`, `PASSEPARTOUT_PACKAGE_VERSION` (four numeric parts),
and `PASSEPARTOUT_PACKAGE_PUBLISHER` matching the signing certificate. From a
Windows SDK developer shell:

```powershell
./app-cross/scripts/package.ps1 -BuildDirectory app-cross/.cmake `
    -OutputPath app-cross/Passepartout.msix -Configuration Release `
    -CertificateThumbprint <current-user-signing-certificate-thumbprint>
```

The script builds, stages, validates with MakeAppx, signs, and verifies the package.
It does not install certificates, register a loose package, or publish anything.
Omitting the thumbprint produces an unsigned prototype. VCLibs is a declared
framework dependency; clean-system delivery must supply it or use a distribution
channel that resolves it.

## Development launch and debugger attach

For an already registered ARM64 development package, run the VS Code task
`Windows: Launch packaged app offline (ARM64)`. It activates the frontend through
Windows with `--demo`, prints its process ID, and does not build, install, register,
or stop the tunnel host. Then select `CMake: Attach to packaged app (Windows)`
and choose that `passepartout.exe` process ID. Pause/continue and normal Quit were
verified with native VS Code debugging and package identity present.

The equivalent launch from the repository root is:

```powershell
./app-cross/scripts/launch-packaged-app.ps1 `
    -InstallDirectory app-cross/out/install/windows-arm64 -Demo
```

Direct EXE launch, including `CMake: Debug installed app offline (Windows ARM64)`,
does not provide package identity. Use package activation followed by attach for
identity-dependent checks. Ordinary install/debug tasks may stop the tunnel host.

The local development registration was repaired by updating version `1.0.0.0` to
`1.0.0.1` and registering the manifest again with `Add-AppxPackage -Register`.
The package name and publisher stayed unchanged, preserving the package family.
Same-version registration had failed in the indexed-state handler with
`0x80070490`. The new registration exposes the frontend in Start apps. Existing
CMake caches must also set `PASSEPARTOUT_PACKAGE_VERSION` to `1.0.0.1` or newer;
changing the default does not override a cached value. This loose-package repair
does not establish signed-package installation or upgrade behavior.

## Current behavior

- `PassepartoutApp` composes repositories, managers, observables, and the wxWidgets
  frontend. `--demo` uses a fake tunnel and a separate profile directory.
- Profile objects are authoritative. A Windows VPN entry is created or refreshed
  from the saved object when connecting. Entries use a stable ID-based name and
  are only managed when they belong to this package.
- Local profile deletion is independent of VPN availability. Reconciliation
  disconnects/removes owned Windows entries without local profiles, retrying
  after outages or restart. Failed local loading suppresses orphan cleanup.
- Storage follows Android: `local/index.json`, `local/objects/<id>.json`, and
  `local/tmp/<uuid>.tmp` under the application's local data directory. The
  version-1 index stores IDs, names, and optional lastUpdate/fingerprint metadata.
  Missing/corrupt indexes rebuild from objects. Demo mode uses `demo-local`.
  The previous `profiles` layout is not migrated; its files remain untouched.
- Configuration content is embedded in the plugin's existing XML envelope, so
  connecting does not depend on the original imported file remaining accessible.
- Window close hides to the tray when available. Quit exits the frontend and
  leaves any system-managed VPN running; use Disconnect to stop it.
- The file picker and initial command-line paths share the import flow. Import
  never connects automatically. **File associations are not registered yet:**
  standard Windows activation redirection must be verified before enabling them.

## Windows verification still required

1. Compile the MSVC frontend and plugin on x64 and ARM64; run the portable tests.
2. Validate and install a signed package on a clean Windows 11 system with VCLibs.
3. Launch from Start; import a test configuration; connect, cancel, disconnect,
   and observe external changes from Windows Settings.
4. Verify credential interaction, denied permission, connection failure, plugin
   restart, and shutdown while an operation is pending.
5. Test upgrade, repair, uninstall, and restoration policy. Do not claim release
   readiness until those pass.

The current adapter uses [VpnManagementAgent](https://learn.microsoft.com/en-us/uwp/api/windows.networking.vpn.vpnmanagementagent)
for management and [VpnPlugInProfile.ConnectionStatus](https://learn.microsoft.com/en-us/uwp/api/windows.networking.vpn.vpnpluginprofile.connectionstatus)
for observation. Transfer counters and detailed tunnel errors remain unavailable
through this adapter; missing values are left absent.
