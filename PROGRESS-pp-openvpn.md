# PROGRESS-pp-openvpn

## Overview
Port of upstream Passepartout OpenVPN module editor (SwiftUI `OpenVPNView`, `+Configuration`, `+Remotes`, `+Import`, `OpenVPNModule+UI`, `OpenVPNCredentialsGroup`, `OpenVPNModule+L10n`) to universal Dartvel, 1:1.

Files owned:
- `app-dartvel/lib/ui/modules/openvpn_view.dart`
- `app-dartvel/lib/ui/modules/openvpn/openvpn_content_screen.dart`
- `app-dartvel/lib/ui/modules/openvpn/openvpn_credentials_screen.dart`
- `app-dartvel/lib/ui/modules/openvpn/openvpn_formatters.dart`
- `app-dartvel/lib/ui/modules/openvpn/openvpn_import_dialog.dart`
- `app-dartvel/lib/ui/modules/openvpn/openvpn_remotes_screen.dart`
- `app-dartvel/test/openvpn_engine_test.dart`
- `app-dartvel/test/openvpn_widget_test.dart`

## Done
1. Analyzed upstream SwiftUI sources, models in `openapi.yaml`, and Partout C ABI / native bindings.
2. Implemented `openvpn_formatters.dart`:
   - `formatTimeString`: seconds to '0s', '10s', '1m', '1h1m1s' (upstream `TimeInterval.asTimeString`).
   - `formatEntriesCount`: localized entries string for endpoints and routes.
   - `formatTlsWrapStrategy`: `--tls-auth`, `--tls-crypt`, `--tls-crypt-v2`, Disabled.
   - `formatCompressionFraming`: Disabled, `comp-lzo`, `compress`.
   - `formatCompressionAlgorithm`: Disabled, `LZO`, `Not supported`.
   - `formatEnabledDisabled`: localized Enabled / Disabled.
   - `formatOtpMethod` and `formatOtpApproach`: localized OTP methods and explanatory notes.
   - `ParsedRemote`: bidirectional parsing and formatting for `address:proto:port`.
3. Implemented `openvpn_credentials_screen.dart`:
   - Interactive credentials toggle with OTP method picker (`none`, `append`, `encode`) and approach explanation footer.
   - Username and password inputs with placeholders and secure field for secret.
   - Real-time updates via `onChanged`, preserving module and credentials fields.
4. Implemented `openvpn_remotes_screen.dart`:
   - Remotes list with `host:port` text fields and socket type dropdowns (`UDP`, `UDP4`, `UDP6`, `TCP`, `TCP4`, `TCP6`).
   - Add new remote (`tr(Strings.globalActionsAdd)`).
   - Delete remote (`tr(Strings.globalActionsDelete)`).
   - Preserves all other configuration fields.
5. Implemented `openvpn_content_screen.dart`:
   - Dedicated viewer screen for CA, Certificate, Key, TLS wrap key hex, Data ciphers, and XOR scramble info.
   - Includes "Copy" action to clipboard.
6. Implemented `openvpn_import_dialog.dart`:
   - Import flow for unconfigured modules and re-importing.
   - Allows pasting `.ovpn` configuration text or loading from file.
   - Uses `VpnService.instance.importModule(text)`.
   - Merges configuration and credentials into current module identity.
7. Implemented `openvpn_view.dart`:
   - Entry point: `List<Widget> openVPNSections(BuildContext context, ModuleViewArgs args)`.
   - Empty configuration flow displaying Import section.
   - Full configuration sections matching upstream:
     - Import section
     - Connection section (remotes list with entries count)
     - Account section (credentials navigation link)
     - Pull section (pulled routes, DNS, proxy)
     - Redirect gateway section (IPv4, IPv6, blockLocal)
     - IPv4 section (address, gateway, included/excluded routes)
     - IPv6 section (address, gateway, included/excluded routes)
     - DNS section (servers, domain, search domains)
     - Proxy section (HTTP, HTTPS, PAC URL, bypass domains)
     - Communication section (data ciphers, cipher, digest, XOR)
     - Compression section (framing, algorithm)
     - TLS section (CA, Certificate, Key, TLS wrap, EKU)
     - Keep-alive section (interval, timeout)
     - Other section (renegotiation, randomize endpoint, randomize hostname)
8. Created comprehensive test suites:
   - `test/openvpn_engine_test.dart`: Native Partout engine import of `sample.ovpn`, `protonvpn.ovpn`, and `pia-hungary.ovpn`, export and re-import verification, and lossless JSON round-tripping.
   - `test/openvpn_widget_test.dart`: Widget tests verifying sections rendering, credentials screen, remotes screen, content viewer, import dialog, and profile serialization round-trip.

## Test Results
- `dart analyze lib`: 0 errors.
- `flutter test test/openvpn_*`: 11 passed, 0 failed.
  - Native engine import of `sample.ovpn`: PASS
  - Native engine import of `protonvpn.ovpn` (TLS wrap + XOR scramble): PASS
  - Native engine import of `pia-hungary.ovpn` (remotes + compression): PASS
  - Native engine JSON round-trip with custom/unknown fields: PASS
  - Widget test empty configuration import row: PASS
  - Widget test full upstream sections rendering for `protonvpn.ovpn`: PASS
  - Widget test `OpenVPNCredentialsScreen` credentials & interactive OTP edits: PASS
  - Widget test `OpenVPNRemotesScreen` add/delete/update remotes: PASS
  - Widget test `OpenVPNContentScreen` copy action and content: PASS
  - Widget test `showOpenVPNImportDialog` import flow: PASS
  - Widget test profile JSON round-trip edit preservation: PASS

## Blockers
- None.

## Requests to Lead (Sub-pages for typed routing)
The following sub-pages are currently pushed via `Navigator.push` with a `PSScaffold` and can be bound to typed routes later:
1. `OpenVPNCredentialsScreen`: `/profiles/:id/modules/:moduleId/credentials`
2. `OpenVPNRemotesScreen`: `/profiles/:id/modules/:moduleId/remotes`
3. `OpenVPNContentScreen`: `/profiles/:id/modules/:moduleId/content` (for CA PEM, Certificate PEM, Key PEM, TLS wrap hex, data ciphers list, and XOR obfuscation details)

## Final Report
The OpenVPN module editor has been ported 1:1 from upstream Passepartout (SwiftUI) to Dartvel.
All sections, rows, formatting, sub-screens (credentials, remotes, content view, import flow), and data shapes matching `partout/scripts/openapi.yaml` and upstream Swift models have been implemented using the shared UI kit (`PSScaffold`, `PSForm`, `PSSection`, `PSRow`, `PSToggleRow`, `PSTextRow`, `PSPickerRow`).
Lossless round-trip serialization and native engine imports with real `.ovpn` fixtures were tested and verified against the live Partout ABI on Linux.
`dart analyze lib` reports 0 errors, and all 11 OpenVPN tests pass.
