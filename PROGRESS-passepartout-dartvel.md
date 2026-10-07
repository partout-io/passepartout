# Passepartout Dartvel progress

## Step 0 — rules and context
Done: read ~/AGENTS.md, server STATUS, brief, repo addendum and latest handoff. No repository AGENTS.md/CLAUDE.md exists yet. Working on existing isolated agent/passepartout-dartvel branch; user explicitly requests local commits only, overriding brief push instruction. No pushes, PRs, merges, publishing, deployment or messages.
Next: initialize engine submodule, inspect build requirements, install local toolchains and build Linux engine; commit each phase.
Tests: none yet.
Blockers: none yet. All implementation stays in app-dartvel/ plus build scripts; native platform folders must remain ephemeral.

## Step 1 — toolchain in progress
Done: initialized Partout at ae65d639; downloaded SHA256-verified Zig 0.16.0 and Go 1.27.1 tarballs into ~/.local. First Linux CMake attempt failed because system OpenSSL development files are absent. Retrying with upstream prebuilts 0.8.2. Generator running via heavy.sh. Enumerated Apple shared/main Swift sources for parity inventory.
Next: finish engine build, record reproducible commands, commit toolchain documentation; complete generated skeleton.
Tests: CMake configuration now succeeds with prebuilt OpenSSL; compilation pending.
Blockers: no system OpenSSL headers (resolved by supported upstream prebuilts).

## Step 2 — skeleton generated
Done: `heavy.sh dartvel create app-dartvel --project-name passepartout --ssr` succeeded; all six platforms enabled, no native folders created. Read generated AGENTS.md and CLAUDE.md. BUILD.md records exact engine/generator commands. Engine Go bridge built; Zig library compiling.
Next: commit build documentation then skeleton; add logo and parity matrix.
Tests: generator and dependency resolution passed.
Blockers: none new.

## Step 3 — inventory
Done: committed generated six-platform skeleton and upstream logo. PARITY.md inventories 473 Apple sources, including list/grid/card/row, installed header, import flows, module subpages, providers, diagnostics, reports, settings, onboarding and TV pairing. Every source has a proposed route, honest status and platform notes.
Next: engine FFI generation, JSON models and fixture import tests.
Tests: generated rules reviewed; no native folders staged.
Blockers: engine build still running.

## Step 4 — engine implementation
Done: full Linux OpenSSL/WireGuard build passed. ffigen generated C ABI bindings. App platform service owns import/module export/keygen and explicit privileged-helper connect stub. Lossless schema-shaped profile/tagged modules plus typed DNS/proxy wire values added; fixtures taken from upstream ABI tests. Sensitive Dartvel VpnProfile storage model added.
Next: run native import tests, then profile list/import/detail and DNS/proxy UI.
Tests: engine build and ffigen generation passed (enum ABI warning documented; daemon connection disabled).
Blockers: connection requires CAP_NET_ADMIN helper; Android/Apple/Windows engine integration deferred as brief specifies.

## Step 4 validation correction / Step 5 UI
Native tests exposed the ABI's {payload: ...} envelope (the lower-level Zig tests return bare JSON). Corrected wrapper to unwrap payload and reject error envelopes without exposing configuration in errors. UI now has own routes for profile list, import, profile details, DNS and HTTP proxy; loading/error states, Enter submission, file picker through DV.Platform.fileStorage, typed navigation and model.save persistence.
Next: regenerate client, analyze and validate browser/build targets. Screens remain partial pending those checks and exact Apple layout/wording parity.
Tests: first native run 1 pass/4 failed due envelope; corrected rerun pending.
Blockers: none new.
Native import suite passed 5/5 after envelope fix. Generator refused sensitive model without a privacy subject; added DVSubject.self and indefinite retention. Server bound to loopback and app port 3187. No external access or deployment.
