<!-- dartvel:begin architecture -->
# Data models in depth

Sensitive fields are `@DVModel.sensitiveField()`: kept out of logs, AI context, search and public pages unless a policy allows. Field roles live under the model annotation (`@DVModel.searchableField()`, `@DVModel.featuredImage()`, `@DVModel.pageTitle()`). Every data model gets a public page per record unless it opts out with `@DVModel(generatePublicPages: false)`.
<!-- dartvel:end architecture -->
