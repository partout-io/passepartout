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
## modules (sub-page routes)

### `DV.Navigation.push` does not put the pushed page's URL in the address bar

Module sub-pages are real routes (`/profiles/<id>/modules/<moduleId>/<section>`), open from their
URL on a reload, and are pushed over the module page so back pops to it:

```dart
DV.Navigation.push<void>(DVRoutes.profilesmodulesIdModuleIdSection(id: id, moduleId: moduleId, section: 'ca'));
DV.Navigation.currentPath; // still '/profiles/<id>/modules/<moduleId>'
```

`DV.Navigation.push` is go_router's `push`, and go_router leaves the URL at the page underneath unless
`GoRouter.optionURLReflectsImperativeAPIs` is true (default false). On the web the address bar,
copy-link and reload therefore show the module page, not the sub-page. Every `DV.Navigation.push`
in the app has this (profile list → profile, settings → sub-pages). Wanted: Dartvel's push
reflects the pushed page's URL (the generated router setting the option, or `push` doing it
itself) so that every page has its own URL in the address bar. The app does not set the
go_router flag itself; the fix belongs in the framework.

### Only one generated-router app per test file

In a widget test, a second `createDartvelApp()` in the same file (a new `testWidgets`) renders an
empty page at any URL after the first test's app; the first renders fine. Probably the router's
once-per-process setup (`_dartvelSetUp`, deferred page loaders) keeps state from the first app.
`test/module_subpages_test.dart` works around it by opening every URL from one app.

### `dartvel build linux` rewrites tracked project files

Every Linux build modifies `.metadata` and `analysis_options.yaml` (and touches `pubspec.lock`), so a clean
worktree is dirty after a build. Repro: `git status` clean, `dartvel build linux`, `git status`. Wanted: a
build leaves committed project files alone.
