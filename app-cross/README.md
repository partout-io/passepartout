# Windows integration checkpoint

The frontend and VPN plugin share an MSIX identity. Root-level `package.cmake`
assembles `AppxManifest.xml.in` with the optional `frontend.xml.in` entry and
installs the shared package assets. `frontend.manifest.in` supplies matching EXE
identity metadata; `tunnel/plugin.cmake` only builds the VPN plugin.

The initial target is Windows 11, with the existing x64 and ARM64 builds. Distribution and signing identity
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

Development defaults to `0.1.0.0`; increment within `0.*` during development and
reserve `1.0.0.0` for the first production release. The package family derives
from name and publisher, not version. Versions order updates within that family.
Set the version explicitly in existing CMake caches, for example
`cmake -S app-cross -B app-cross/out/build/windows-arm64 '-DPASSEPARTOUT_PACKAGE_VERSION=0.1.0.0'`.

## Run and attach

VS Code has eight Run configurations (also available as tasks) and four separate
Attach configurations:

| Platform | Run tasks | Attach configuration |
| --- | --- | --- |
| Windows ARM64 | Run Windows ARM64 Debug / Release | Attach Windows ARM64 |
| Windows x64 | Run Windows X64 Debug / Release | Attach Windows X64 |
| macOS ARM64 | Run macOS ARM64 Debug / Release | Attach macOS ARM64 |
| macOS x64 | Run macOS X64 Debug / Release | Attach macOS X64 |

In **Run and Debug**, select **Run Windows ARM64 Debug** (or the matching
platform, architecture, and configuration), then press **F5**. It builds,
installs, and launches the installed app under the native C++ debugger without a
process picker. Windows uses cppvsdbg; macOS uses lldb-dap. Hidden Prepare tasks
call the same run scripts with -PrepareOnly/--prepare-only. No terminal debugger
or custom extension is involved.

To debug native code, select a separate **Attach** entry, press F5, and choose
the running process. Attach does not build or reinstall. CMake Tools' raw EXE
Run/Debug buttons remain hidden because they bypass package preparation.

The run tasks call one script per platform, with the same responsibility:

```powershell
./app-cross/scripts/run-app.ps1 -Architecture arm64 -Configuration Debug
```

```bash
bash app-cross/scripts/run-app.sh arm64 Debug
```

Both accept arm64/x64 and Debug/Release. Optional `-Demo` on Windows or `--demo`
on macOS uses the fake tunnel and separate profile storage. For F5 demo runs,
set the selected launch configuration's args to ["--demo"]. Run tasks use the
regular backend. Agent verification must remain in demo mode. Quit the frontend
before reinstalling; Windows refuses to stop a running VPN host.

Windows initializes the matching MSVC environment, configures the explicit
architecture preset, builds, installs EXE/PDB/runtime files, registers the local
0.* development package with external location when needed. The installed
frontend embeds matching identity metadata, so native debugger launch preserves
the same package family and application ID. Only the installed development
manifest is adapted; the distribution manifest and VPN plugin entries remain
unchanged. An existing registration with the same version but a different layout
requires another 0.* PASSEPARTOUT_PACKAGE_VERSION in the CMake cache. See
[Microsoft's identity documentation](https://learn.microsoft.com/en-us/windows/apps/desktop/modernize/grant-identity-to-nonpackaged-apps).
Microsoft's C/C++ extension supplies cppvsdbg.

macOS uses distinct macos-arm64 and macos-x64 presets, installs a
`passepartout.app` bundle with its dependencies, signs it locally, and launches
through `open`. It rejects non-macOS hosts before building or installing. The
attach backend is `lldb-dap`, supplied by the LLVM extension and an installed
LLDB DAP executable. wxWidgets and the build toolchain must support the requested
architecture. The old macos-clang directory is not used by any task or preset;
misplaced output there is left intact.

Build outputs are `out/build/<platform>-<architecture>` and installed output is
`out/install/<platform>-<architecture>`. Debug and Release share the installation
for that architecture; each run installs the chosen configuration.

Windows ARM64 Debug/Release builds and Debug preparation passed. Native debugger
launch and attach captured application/Partout output from the packaged demo,
and a consumer of the installed headers/exported DLL passed ten read-only VPN
enumerations. The diagnostic demo processes were terminated after log capture;
this does not verify graceful GUI shutdown. Actual VS Code F5, macOS bundle runs,
x64 execution, and live VPN lifecycle remain manual/platform checks. No UI
automation or live VPN changes were performed. This is a development workflow,
not signed production distribution validation.

## Current behavior

- `PassepartoutApp` composes repositories, managers, observables, and the wxWidgets
  frontend. `--demo` uses a fake tunnel and a separate profile directory.
- Normal Windows launches use the public `Partout::Tunnel` management API from
  `partout_winrt.h`. The frontend adapter only maps presentation state.
- Enabling another profile requests disconnection of the current profile and
  waits for observed inactivity before installing and connecting the next one.
  Pending activation ends only after observed connection, failure, or timeout.
- The footer activity indicator represents foreground work, pending handover,
  or observed connection transitions. Idle background polling does not animate it.
- Application and Partout diagnostics go to the Windows debugger output stream
  (`OutputDebugString`), including startup, profile operations, tunnel requests,
  state changes, and failures with native operation/status codes. Repeated
  observation failures are suppressed until their message changes or recovery.
  Private Partout logging remains disabled; profile payloads are not logged.
  Orphan-cleanup failures remain separate from successful state observation.
- Profile objects are authoritative. A Windows VPN entry is created or refreshed
  from the saved object when connecting. Entry names match the app's profile
  names; stable IDs remain in their typed configuration. Only this package's
  recognized profiles are managed. Existing UUID-named entries are replaced on
  the next Connect, while disconnected; another profile's name cannot be reused.
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
- A single tray click shows the window. The tray menu has Disconnect and Quit.
- Profile rows use a custom DPI-scaled Theme switch on Windows and a stock
  toggle on other platforms, alongside name and status. Toggles
  act through the tunnel observable, reflect observed state, and disable during
  pending actions or when VPN control is unavailable. Selection remains for
  deletion; connecting does not require selecting a row first.
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
