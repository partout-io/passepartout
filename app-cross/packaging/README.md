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

## Current behavior

- `PassepartoutApp` composes repositories, managers, observables, and the wxWidgets
  frontend. `--demo` uses a fake tunnel and a separate profile directory.
- Profile objects are authoritative. A Windows VPN entry is created or refreshed
  from the saved object when connecting. Entries use a stable ID-based name and
  are only managed when they belong to this package.
- Removal disconnects first and checks the observed state. If disconnect is still
  pending, the saved profile remains and the user can retry. Other applications'
  entries are never removed. Orphan Windows entries are not automatically deleted.
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
