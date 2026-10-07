# PROGRESS: pp-modules (DNS, HTTP proxy, IP, on-demand editors)

## Done
- `lib/ui/modules/dns_view.dart`: DNSView + DNSModule.Builder. Sections in upstream (iOS) order: inherit from VPN,
  route through VPN (Default/Yes/No), only for configured domains (disabled unless inherit or cleartext), custom
  settings (protocol cleartext/HTTPS/TLS + URL or hostname), servers, domains (cleartext only), first is primary
  (disabled without non-empty domains). builder() reads domainName/searchDomains and the legacy protocol encoding.
- `lib/ui/modules/http_proxy_view.dart`: HTTP, HTTPS (address + port), PAC URL, bypass domains. Endpoint "addr:port".
- `lib/ui/modules/ip_view.dart`: per family (IPv4, IPv6): address (first subnet, normalised like `Subnet(rawValue:)`,
  footer "Leave empty…"), included routes + "Include route", excluded routes + "Exclude route"; Interface/MTU.
  Route dialog = RouteView (Default toggle, destination, gateway; OK ignores wrong-family input like upstream).
  Routes add/remove/copy (upstream has no route edit). Empty IPSettings omitted (`nilIfEmpty`).
- `lib/ui/modules/on_demand_view.dart`: policy (All networks/Excluding/Including) + footer; when not "any":
  Networks (Mobile, "Ethernet (Mac/TV)", shown on every platform as upstream does) and Wi-Fi SSID list with
  per-SSID switch. Rename semantics follow upstream `allSSIDs` setter (new SSID is off).
- `common/`: `addresses.dart` (pure-Dart IPv4/IPv6/Subnet/Route rules, no dart:io), `module_builder_cache.dart`
  (raw builder per module id so half-typed text survives rebuilds; edits applied via `withField`, null = omit,
  unknown keys kept), `editable_list_section.dart` (upstream EditableListSection: stable row ids, swipe or minus to
  remove, Add disabled while the last row is empty), `module_validation.dart` (`moduleValidationError(module)`).
- Validation as upstream: build() rules mirrored. Invalid input is never written (JSON stays schema-valid);
  the save-time error string (`errors.modules.DNS.*`, `errors.modules.HTTPProxy.*`) comes from
  `moduleValidationError`.

## Tests
- `test/modules_schema_test.dart` (10): address/subnet/route rules, builder round-trips, and a mini validator for
  openapi.yaml module schemas (reads `~/passepartout/partout/scripts/openapi.yaml`; partout submodule is empty in the
  worktree).
- `test/modules_editors_test.dart` (5 widget tests): each editor in MaterialApp, edits like a user, every written
  module validated against openapi.yaml, unknown fields kept, no nulls.
- `dart analyze lib`: 0 errors. `dartvel routes`: OK. Screenshots (light/dark) of all four editors checked.

## Partial / not ported
- Upstream fills a new SSID row with the current Wi-Fi SSID (CoreLocation); no Dartvel API, row starts empty.
- Paywall (`PurchaseRequiredView`, policies limited to "any" on non-paid builds) not ported: all three policies shown.
- macOS edit mode (reordering list rows by drag) not ported; remove + add only.
- Raw (invalid) text lives in an in-memory cache: it survives rebuilds, not an app restart (valid JSON does).
- IP: editing one family's address only rewrites that family (upstream re-saves both from text state; same result
  except a multi-subnet IPSettings keeps its extra subnets on the untouched family).

## Requests to lead
1. On profile Save, call `moduleValidationError(module)` (lib/ui/modules/common/module_validation.dart) for each
   module and show the error like upstream (alert, blocks save). Without this, invalid half-typed DNS/proxy input is
   silently left out of the JSON.
2. kit `PSStringListSection` keys rows by index and never syncs its controller: removing row i shows row i's old
   text in place of row i+1. Use stable ids (see common/editable_list_section.dart) or adopt that widget.
3. Add `yaml` to dev_dependencies (tests use it transitively, with an ignore).
4. DARTVEL-GAPS (file does not exist yet, not created to avoid add/add conflicts): no API for current Wi-Fi SSID
   (`DV.Platform.*`), needed by on-demand "Add SSID".
