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
