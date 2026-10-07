# PROGRESS: pp-settings (follow-up)

The first pass was merged into agent/passepartout-dartvel; this covers the follow-up.

## Done

- **Tunnel logs:** `lib/platform/tunnel/tunnel_logs_facade.dart` exports `tunnel_logs_io.dart` (re-exports
  `tunnel_logs.dart`, adds `deleteTunnelLogs`, which deletes only files `tunnelLogFiles()` lists) or
  `tunnel_logs_stub.dart` on web (no logs). `TunnelLogAccess` (`lib/ui/settings/tunnel_log_access.dart`) dates each
  `<micros>.log` from its file name, newest first.
- **Diagnostics > Tunnel:** one row per saved log, opening `/settings/diagnostics/log?source=tunnel&file=<name>`.
  "Delete all logs" runs after `confirmDestructive`. The live tunnel log (`?source=tunnel`) is the newest file,
  re-read every second while the page is open; a saved log is read once.
- **Engine version:** `VpnService.engineVersion()`. Native returns `partout_version()` (a static string, not freed).
  The stub returns "Not available on this target" and web returns "Not available in the browser". The Partout row
  on the Version screen shows it.
- **Report issue:** the address is one constant, `SettingsConstants.issuesEmail`, with a TODO(owner). It is
  unchanged.

## Tests

- Settings tests: 30 passed.
- Full `flutter test`: 79 passed, 1 skipped.
- `dart analyze lib`: 0 errors.
- `dartvel build web-server`: see the final report.

## Requests to lead

- Web could ask the web-server binary for the engine version (it links Partout).
- Optional proper routes in place of the query URLs, as asked before.
- The owner must choose the Report issue address (`SettingsConstants.issuesEmail`).
