
# Follow-up: pp-tests (domain and stores)
- Merged agent/passepartout-dartvel.
- `test/domain_profile_test.dart` (21): decode/encode lossless (unknown fields), empty, renamed, withBehavior,
  savingModule (adds active, replaces in place, activate flag), toggling keeps both connections active (upstream
  ProfileEditor), activeModulesIds in module order, removing, moving, duplicated (fresh ids, active by position,
  config kept), moduleSummary/activeConnection, withField(null), TaggedModule.empty vs openapi.yaml for every
  addable type, validate() order (emptyName, noActiveModules, incompatibleModules ids, incompleteModule), and
  real .ovpn/.conf imported by the engine, edited, schema-checked as `Profile`, round-tripped through export/import.
- `test/state_stores_test.dart` (11): ProfilesState.filtered/search/byId/firstUniqueName, Preferences defaults and
  round trip, ProfileStore save/load (skips unreadable files)/remove/duplicate/search, importText through Partout
  with real fixtures, PreferencesStore round trip, over `DVDeviceStorage.useAdapters(DVMemoryFileStorageAdapter())`.
- Full `flutter test`: 104 passed, 1 skipped (wireguard screenshot, not mine), 0 failed. No lib bugs found.
- Note: `TaggedModule.empty('Custom')` would not match `CustomModule` (needs innerType/json, no id); Custom is not
  addable, so harmless today.
