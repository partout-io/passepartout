# PROGRESS: pp-wireguard

WireGuard module editor, ported from `app-apple/Sources/AppLibraryMain/Views/Modules/WireGuard/*`.

## Done
- `lib/ui/modules/wireguard_view.dart`: `wireGuardSections` in upstream order: import section; then, when the
  module has a configuration: Interface (private key, derived public key with copy, "Generate new key"); addresses + MTU;
  DNS (servers, search domains, footer); one "Peer #n" section per peer (public key, pre-shared key, endpoint, allowed
  IPs, keep-alive, "Delete peer"); "Add peer" (disabled while a peer with an empty key exists, as upstream).
  Upstream shows only the import button when the module has no configuration; same here.
- `lib/ui/modules/wireguard/wireguard_configuration.dart`: port of `ConfigurationView.ViewModel` load/save on the JSON.
  Each edit writes only its own field, so listenPort, the DNS module's id/protocol and unknown keys survive. Never
  writes nulls (empty/invalid optional values remove the key: preSharedKey, endpoint, keepAlive, mtu, dns). Blank
  private key ignored (upstream). Empty DNS servers drop `dns` (footer). DNS domain list merges `domainName` like
  `DNSModule.builder()`. IPv6 endpoints shown in wg-quick bracket form.
- `lib/ui/modules/wireguard/wireguard_rows.dart`: `ThemeLongContentLink` equivalent (row + preview, pushes a PSScaffold
  monospaced editor page), "N entries" previews, public-key row deriving through `VpnService.wireGuardPublicKey`.
- `lib/ui/modules/wireguard/wireguard_import.dart`: "Import from file" → `DV.Platform.fileStorage.pick()` →
  `VpnService.instance.importModule(text, contextJson: {"type":"WireGuard"})`; module keeps its id, takes the imported
  configuration; errors shown via `runGuarded` titled "WireGuard".

## Tests (real libpartout engine; PARTOUT_LIBRARY + LD_LIBRARY_PATH set)
- `test/wireguard_configuration_test.dart`: 9 passing. Imports parser.zig fixtures (full, repeated keys, hostname),
  rejects non-WG text, edits a peer and checks the key set is unchanged, no nulls, JSON text round-trip, engine
  export → re-import equality, clearing optionals removes keys, DNS id/protocol kept, add/remove peer, keygen = base64
  32 bytes, pubkey matches an independent X25519 computation.
- `test/wireguard_view_test.dart`: 4 passing + 1 screenshot test (skipped unless `WG_SHOT_DIR` is set). Renders the
  sections, checks section order and real English strings, edits keep-alive inline and endpoint via the pushed editor
  page, asserts the JSON keeps every field and exports through the engine, add/delete peer, import via a fake file
  reader, generate key.
- Screenshots (light + dark) looked at; layout matches upstream's grouped form.
- `dart analyze lib`: 0 errors (1 pre-existing warning in generated bindings). `dartvel build linux`: builds.

## Next / not done
- Upstream `editConfiguration()` is a TODO upstream (#397); not ported.
- Paywall modifier (`ModuleDynamicPaywallModifier`) not ported; no IAP layer in this app yet.

## Blockers
- None.

## Requests to lead
1. **New WireGuard module needs a configuration with a generated key.** Upstream `RegistryObservable.newModule` gives a
   new WireGuard module `WireGuard.Configuration.Builder(keyGenerator:)` (fresh private key, no peers). Our
   `TaggedModule.empty(ModuleType.wireGuard)` gives only `{id}`, so the editor shows just "Import from file" (which is
   what upstream shows for a configuration-less module). Suggest the add-module flow does, async:
   `value['configuration'] = {'interface': {'privateKey': await VpnService.instance.generateWireGuardKey(), 'addresses': []}, 'peers': []}`.
2. `test/engine_test.dart` calls the engine synchronously (stale vs the async `VpnService`); it does not compile now.
3. Kit: `PSTextRow` label is smaller than `PSRow` titles (visible in the WireGuard form: "MTU", "Keep-alive"). Could use
   `bodyLarge` to match ListTile titles. A kit `PSLongContentRow` (ThemeLongContentLink) would let OpenVPN reuse
   `WireGuardLongContentRow`; happy for it to move to kit.
4. Widget tests need `DVI18n().loadAll(stringCatalogs.values)` in setUp, else `tr()` returns keys; a shared test helper
   would help every workstream.
5. `dartvel build linux` rewrites `analysis_options.yaml`, `pubspec.lock` and adds `.metadata` in the worktree (reverted
   here).
