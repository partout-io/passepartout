<!-- dartvel:begin architecture -->
# HTTP

Server code is a private `@DVBackendFunction`; the generator writes the public client function every target calls. A first parameter of type `DVContext` is injected on the server and is not a client argument. Raw HTTP exposure uses `rawPath` or `rawPathSuffix` on the same annotation (never both). Navigate with the generated `DVRoutes` members, never literal paths; a query is `DVRoutes.signin.withQuery({...})`.
<!-- dartvel:end architecture -->
