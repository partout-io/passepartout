<!-- dartvel:begin architecture -->
# Backend functions and jobs

Request work is a backend function; durable or background work is a `@DVJob` with a `@DVJob.handler()`, run through `DV.Jobs` and `DVQueues`. Reversible operations use `DV.transaction((DVContext context) async { ... })` with `context.afterCommit(...)` and `context.compensate(...)`.
<!-- dartvel:end architecture -->
