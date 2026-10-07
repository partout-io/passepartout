# Dartvel gaps

Things this port needed that Dartvel does not provide, with a repro each.

## settings

### No `DV.Platform` API to open an external URL

Settings rows open web pages (FAQ, Links, license sources) and `mailto:` (Report issue).
`DV.Platform` has share, clipboard, files and so on, but nothing like `openUrl(url)`.

Repro:

```dart
DV.Platform.openUrl('https://partout.io/passepartout/faq'); // no such member
```

What exists: `DVNavLink.external(url, child: ...)` (a link widget) and `DVLinkOpener.open(url)`, the
funnel those links use, installed by the generated router. The port calls `DVLinkOpener.open(url, newTab: true)`.
It returns nothing, so the app cannot tell when no handler opened the URL (upstream shows
"unable to email" when `mailto:` cannot be opened). Wanted: `Future<bool> DV.Platform.openUrl(String url)`.

### No generated app version constant

pubspec `version:` is not available at runtime without a plugin (package_info). Settings > Version repeats
it as a constant (`SettingsBundle.versionNumber`), checked against pubspec by a test.
Wanted: a generated `DV.app.version` / build number.

### No language display names

Credits > Translations names each language. Upstream uses Foundation's localized language names; Dartvel's
`DVI18n` has no display-name table, so the port names each language in itself (Deutsch, Français...).

## lead

### Web-server build rejects some dot shorthands that `dart analyze` and Flutter accept

`dartvel build web-server` failed with `The static getter or field 'w600' isn't defined for the type 'invalid-type'`
for `theme.textTheme.titleMedium?.copyWith(fontWeight: .w600)` and for `Text(..., textAlign: .center)`, while
the same shorthands compile for web and pass `dart analyze`. The server compile resolves those parameter types
to an invalid type, so a shorthand has no context. Repro: any page using `Text('x', textAlign: .center)`, then
`dartvel build web-server`. Workaround in the app: spell the type (`TextAlign.center`). Fix belongs in the
server-side compile of pages (the shorthand rule in the generated CLAUDE.md promises they work).

### Backend functions silently lose imports that reach Flutter

A backend function importing `../../platform/vpn_service.dart` failed with `Undefined name 'VpnService'`,
because that file (transitively) imported Flutter and the generator drops such imports without a word.
Wanted: a build error naming the import chain that reaches Flutter.
