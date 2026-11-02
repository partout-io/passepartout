# Programming conventions

Follow the general and applicable language-specific programming conventions in
[Partout's AGENTS.md](partout/AGENTS.md) when working on Passepartout.
Read that file before making code changes; it is the shared source of truth for
these conventions. Rules concerning Partout's internal module layout remain
scoped to Partout.

Apply these rules to new or changed code. Existing deviations do not authorize
unrelated refactoring; keep changes within the task's scope.

## Application architecture

- Use the same domain names and meanings across frontends. The shared application
  schema is `scripts/openapi.yaml`; update generated models through the generation
  workflow rather than editing them manually.
- Keep responsibilities separated: domain models define contracts; managers own
  business rules; repositories and strategies provide replaceable mechanisms;
  observables expose UI state and actions; context assembles dependencies; Theme
  supplies native presentation components; views render state and handle input.
- Views must use observables or injected presentation helpers, never managers,
  repositories, or tunnel implementations directly.
- `PassepartoutApp` is the root application composition on every platform.
  Its framework role may differ (for example, SwiftUI `App` or an Android
  composable). Supply its application dependencies through the context.
- Name components by responsibility (`Manager`, `Repository`, `Strategy`,
  `Observable`, `Context`). Preserve established names such as `VersionChecker`;
  do not introduce empty manager layers merely for naming symmetry.
- Assemble dependencies in `AppContext` or explicit factories. Share relevant
  state across application surfaces and support fake dependencies for tests and
  previews, including tunnel control through `TunnelObservable`.
- Distinguish observed state, pending actions, and failures. Make initial state
  available to subscribers, prevent stale asynchronous results from superseding
  newer actions, and give subscriptions and cross-domain effects clear owners.
- Keep platform integration behind explicit boundaries. Adapt navigation to the
  form factor while keeping business rules independent of the UI toolkit.
- Build Theme from stock native controls, supporting dynamic palettes,
  accessibility, and localization. Keep business logic out of Theme.
- Keep Partout external to the application logic. Delegate VPN implementation
  and VPN configuration import/export to it rather than duplicating that logic
  in Passepartout.
- Test application state transitions independently of the UI with replaceable
  dependencies. Verify native integration on the affected platform when a change
  affects that integration.

Keep platform implementation plans separate from these shared conventions.
