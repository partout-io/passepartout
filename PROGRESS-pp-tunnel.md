# pp-tunnel progress

## Step 1 — instructions and references
Done: read server rules, repo AGENTS/CLAUDE, common/task briefs and latest lead conversation; branch is agent/pp-tunnel. Only assigned files will be edited. Existing launcher log is unrelated/untracked.
Next: inspect ABI and implement helper, event parser, process lifecycle and private logs.
Tests: none yet.
Blockers: no privileged installation authorized; real networking depends on existing capabilities/user namespaces.
Requests to lead: platform framework gaps will be recorded here because DARTVEL-GAPS.md is outside assigned ownership. Shared STATUS.md is also outside the common brief's permitted writes; this progress file is the handoff.

## Step 2 — native helper
Done: implemented Dart CLI with NativeCallable.listener, pthread daemon execution, copied callback payload ownership, JSON lines, stop command and SIGTERM/SIGINT. Privileged library loads are fixed beside executable (not environment-controlled).
Next: app process controller and tests; compile and inspect runtime behavior.
Tests: pending.
Blockers: pkexec absent; no root actions will be performed.

## Step 3 — app lifecycle
Done: Linux availability detection, pkexec launch, protected profile files removed after ready, stdout/stderr draining, stop command with PID fallback, strict protocol parser, private cache logs and diagnostics reader. Natural process exit releases app ownership.
Next: compile helper and add fake-process tests, then document installation/platform gaps.
Tests: dependency resolution running. A command initially used the app cwd with root-relative paths; no files were changed by that failed command; corrected.
Blockers: privileged networking remains unavailable.

## Step 4 — initial verification
Done: helper compiled as a Dart executable; C bridge compiled with -Wall -Wextra -Werror. Four fake-helper tests pass: strict parsing, profile/parent modes 0600/0700 and deletion, byte events/stderr, duplicate connect, early exit and startup timeout with stop.
Generated ignored Dartvel client artifacts for analysis (not committed).
Next: inspect unprivileged native probe, complete platform/install docs, rerun analysis and tests.
Blockers: `unshare -rn true` fails with uid_map Operation not permitted; `ip tuntap show` has no pre-created interfaces. pkexec absent. Initial analysis without generated client had missing-generated-file errors; rerun after routes generation.

## Step 5 — native smoke and documentation
Done: real daemon probe with dummy localhost WireGuard endpoint reached native `connecting`, attempted ioctl(TUNSETIFF), reported `tunNotAvailable`/`unhandled`, and stopped successfully (native exit 0). This proves attempted connection and callback/log delivery, not a successful VPN handshake. Added root-owned installation/polkit policy, setcap alternative, and precise Android/Windows/Apple plans in docs/TUNNEL.md.
Tests: full lib/tool/test analyzer zero errors; existing generated-binding unused field warning and style infos remain. Four lifecycle tests pass. Helper compile passes.
Next: final reliability checks (startup stop retry and SIGTERM), preserve probe logs, commit.
Requests to lead: import tunnel_logs.dart in Diagnostics; append the Android service-declaration and Apple extension-target repros from TUNNEL.md to shared DARTVEL-GAPS.md. Owner must install pkexec/helper/policy and verify real privileged VPN plus DNS/routes restoration.

## Step 6 — final checks and baseline blocker
Done: added current async native import/key/unavailable-service regression test; preserved control of a helper if startup cleanup cannot stop it. Helper retries early stop requests until native completion.
Tests: full flutter suite attempted; existing test/engine_test.dart does not compile against the lead's already-async VpnService (Future used as profile/module/key, missing required onStatus). This file is outside tunnel_* ownership; left unchanged. Focused tunnel tests and final analysis running.
Requests to lead: update legacy engine_test.dart to await engine calls and pass onStatus. Privileged end-to-end VPN verification remains owner-side.

## Step 7 — final validation results
Done: five focused tunnel tests pass, including async native import/crypto and unavailable helper behavior. Final full-lib/tools/tunnel-tests analysis has zero errors (one pre-existing generated-binding warning and 28 existing/style infos). C/AOT builds pass. Stored real stop-command and SIGTERM probe logs under tool/tunnel_helper/. Added missing-profile startup cleanup protection.
Next: final executable smoke, scope/whitespace review and local commit.
Blockers: full test suite's stale engine_test.dart; privileged handshake and platform implementations remain explicitly unverified/planned.

## Step 8 — review and commit
Done: final compiled helper smoke again reached native connecting, reported tunNotAvailable and exited 0 after stop. Missing-profile executable check exited 1 within five seconds with a structured helper_failure event. Scope and git diff --check pass. Removed local Flutter test build output and temporary compiled helper artifacts after verification.
Next: lead reviews the local branch; owner performs installation/privileged verification.

## Final report
Implemented Linux tunnel helper and app connect/disconnect lifecycle on agent/pp-tunnel. The Dart AOT CLI uses a small FFI C bridge to copy borrowed callback strings, executes Partout in daemon mode on a pthread, emits JSON events/logs, and stops via stdin/SIGTERM. App uses pkexec, private disposable profile files, native TunnelEvents and private cache/AppLog logging. Diagnostics log-reader module, polkit/build assets, recorded unprivileged daemon logs and Android/Windows/Apple implementation plans are included.
Validation: C warnings-as-errors and Dart AOT builds pass; five tunnel tests pass; full-lib/tool/tunnel-test analysis has zero errors (pre-existing generated-binding warning plus 28 infos). Real WireGuard dummy-localhost attempt reaches native connecting; tun creation is denied without CAP_NET_ADMIN; stop and SIGTERM both exit cleanly. No successful VPN handshake or privileged route/DNS restoration claimed.
Lead requests: wire Diagnostics to tunnel_logs.dart; copy platform gap repros into DARTVEL-GAPS.md; fix existing engine_test.dart's stale synchronous API calls (full suite cannot compile it). Owner must install pkexec/trusted helper/policy and test real VPN, prompt cancellation and routing/DNS restoration. Other platforms remain plans, not implemented connections.
No sudo, push, PR merge, publishing, deployment or messages performed. Shared STATUS.md was not edited because the common brief explicitly prohibits writes outside this worktree; this file contains the complete handoff. Existing untracked .agent-pp-tunnel.log belongs to the launcher and is excluded from the commit.
