# PROGRESS: pp-settings

Branch `agent/pp-settings`. Files: `app-dartvel/lib/ui/settings/*`, `app-dartvel/test/settings_*_test.dart`,
`app-dartvel/assets/credits/credits.json`, `app-dartvel/docs/DARTVEL-GAPS.md` (settings section).

## Done

- **Settings** (`SettingsCoordinator` + `SettingsContentView`): iOS layout on phones/tablets/web
  (Preferences, Version with trailing version; About: Links, Credits; Troubleshooting: FAQ; Diagnostics);
  macOS layout on desktop builds (Version under About, FAQ + Diagnostics under Troubleshooting, version string
  under the list, title "Settings" vs "Settings" noun as upstream). Typed routes via `DV.Navigation.push(DVRoutes.*)`.
- **Preferences** (`PreferencesView`): System appearance picker, Launch on login + Keep in menu (desktop only,
  upstream `#if os(macOS)`), Pin active profile, DNS fallback, each with upstream footer. All read/write
  `PreferencesStore`.
- **Diagnostics** (`DiagnosticsView`): Live log (App, Tunnel), Extensive logging + Include private data toggles
  (write `PreferencesStore`), Active profiles (when one is active), Tunnel section (Remove tunnel logs, disabled,
  lists nothing yet), Report issue (comment dialog, then `mailto:` with upstream's issue.txt body).
- **Live log** (`DebugLogView`): `AppLogLines` as one selectable monospaced text, live; Copy, Share
  (`DV.Platform.share`), Remove (clears `AppLog`). `?source=tunnel` shows the tunnel log: empty for now.
- **About** = upstream `LinksView` (title "Links"): Support (Start a discussion, Make a donation =
  `WebDonationLink`), Web (Home page, Blog), Disclaimer, Privacy policy. URLs from upstream constants.json.
- **Credits** (`GenericCreditsView`): licenses (sorted, license name trailing), notices, translators; license
  page fetches the text (dio) and caches it; notice page. Data: upstream credits.json copied byte-identical to
  `assets/credits/credits.json`. Detail pages have their own URL: `?license=<name>`, `?notice=<name>`.
- **Version** (`VersionView`): logo, name, version, `views.version.extra` credit line, CHANGELOG button
  (`?changelog=1` -> `ChangelogScreen`, upstream parser for `* text (#issue)` lines, issue rows open GitHub),
  plus a Partout row (shows "—" until VpnService exposes the engine version).

### Donate/Purchases decision

Upstream shows Donate (IAP sheet) and Purchased only when `distributionTarget.supportsIAP` (App Store only).
Off the App Store and not beta, `LinksView` shows `WebDonationLink` (opens partout.io/donate) instead. This app
has no IAP, so: no Donate/Purchased rows in Settings; the web "Make a donation" link is in About, as upstream.

### Omitted

- omitted: Apple-only — Lock in background (iOS Face ID lock), Enable purchases (IAP), Erase iCloud (CloudKit),
  Donate sheet + Purchased (IAP), System extension (macOS developerID), Beta section (TestFlight).
- omitted: Crypto backend picker (upstream shows it only on beta builds; `Preferences` has no field).
- omitted: Advanced (config-flag overrides): no config flags in this app; Android hides it too.
- omitted: `VersionUpdateLink` (no version checker in this app yet; upstream shows the row only when a newer
  release is known).
- Active profile rows don't open `DiagnosticsProfileView` (OpenVPN server configuration from the tunnel):
  the engine doesn't report it yet.

## Tests

`flutter test test/settings_support_test.dart test/settings_screens_test.dart`: **23 passed, 0 failed**
(5 support: credits JSON vs upstream file, changelog parser vs upstream CHANGELOG.txt, URLs vs constants.json,
version vs pubspec; 18 widget: each screen renders upstream rows in order, toggles and appearance picker change
`PreferencesStore`, report-issue dialog, live log copy/share/clear, credits list/license/notice, version, changelog).
`dart analyze lib`: 0 errors (no issues in lib/ui/settings). Screenshots rendered from widget tests (light and
dark, 390x844) and checked by eye; not yet checked in a full `flutter build linux` / web build.

## Next / blockers

- Tunnel logs (live + saved) depend on the tunnel-log workstream: wire `LiveLogScreen(source: tunnel)` and
  `DiagnosticsScreen(tunnelLogs:)` + removal when it lands.
- Changelog loads nothing: this app has no build number, and upstream's URL is per build tag
  (`refs/tags/builds/<build>/app-apple/CHANGELOG.txt`).

## Requests to lead

1. **pubspec:** add `- assets/credits/` under `flutter: assets:` (`- assets/` does not include subfolders).
   Until then Credits shows empty lists in the app (tests read the file directly).
2. **VpnService:** expose the engine version (`partout_version()` is already in the FFI bindings) as e.g.
   `Future<String> partoutVersion()`; then pass it to `VersionScreen(partoutVersion:)` from the page or let the
   screen read it.
3. **Routes (optional, cleaner than queries):** `/settings/about/credits/[name]`, `/settings/version/changelog`,
   `/settings/diagnostics/profiles/[id]`, `/settings/diagnostics/tunnel-logs/[id]`. Today license/notice/
   changelog are `?license=`, `?notice=`, `?changelog=1` on existing routes and the tunnel log is
   `/settings/diagnostics/log?source=tunnel`.
4. **Report issue recipient:** it mails upstream's `issues@passepartoutvpn.app` with subject
   "Passepartout/Dartvel - Report issue" (1:1 with upstream). Decide whether a fork should send there; the
   constant is `SettingsConstants.issuesEmail`.
5. **Preferences fields** if wanted later: `cryptoBackend` (beta only upstream), `locksInBackground` (iOS).
6. Desktop shell should honour `keepsInMenu`/`launchesOnLogin` (stored here; nothing acts on them yet).
