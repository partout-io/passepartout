# PROGRESS: pp-wireguard

## Done (round 2: module sub-pages as routes)
- New page `lib/pages/profiles/[id]/modules/[moduleId]/[section].dart` → `ModuleSectionScreen`
  (`DVRoutes.profilesmodulesIdModuleIdSection`). It reads the module from the profile draft like
  `ModuleScreen` (shared `_resolve`, `DraftStore.open` on a deep link) and dispatches by type through
  `moduleSubpageFor` → `wireGuardSubpage` / `openVPNSubpage`. Edits go to `DraftStore.saveModule`.
  An unknown section shows "No content".
- `module_view.dart`: `ModuleSubpage` typedef, `pushModuleSection(args, section)` (DV.Navigation.push), targets.
- Kit: `PSLongContentRow`, `PSLongContentPage` (editable with `onChanged`, else read-only + copy) and
  `PSBackTarget`. A page opened by URL with nothing under it gets a back button to its parent (the
  module page); otherwise back pops.
- WireGuard sections: `private-key`, `addresses`, `dns-servers`, `dns-domains`,
  `peer-<n>-{public-key,preshared-key,endpoint,allowed-ips}`. OpenVPN: `remotes`, `credentials`,
  `data-ciphers`, `xor`, `ca`, `certificate`, `key`, `tls-wrap`. No `Navigator.push`/`MaterialPageRoute`
  left in lib/ui. `OpenVPNContentScreen` now wraps `PSLongContentPage`.

## Tests
- Full `flutter test`: 73 passed, 1 skipped (WireGuard screenshot, needs WG_SHOT_DIR). `dart analyze lib`: 0 errors.
- `test/module_subpages_test.dart`: real app router; every WireGuard and OpenVPN section renders from its URL
  as a deep link, deep-link back button opens the module page, unknown section, tap row → pushed sub-page →
  edit reaches the draft → back pops to the module showing the edit.

## Requests to lead
1. Dartvel gap (in docs/DARTVEL-GAPS.md): `DV.Navigation.push` leaves the browser URL at the page underneath
   (go_router `optionURLReflectsImperativeAPIs` is false), so on the web a pushed sub-page's URL is not
   shown in the address bar. Affects every push in the app. Fix belongs in Dartvel.
2. Dartvel gap: a second `createDartvelApp()` in the same test file renders nothing, so the route test
   uses one app for all URLs.
