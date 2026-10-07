<!-- dartvel:begin architecture -->
# Data

Data models are `@DVModel` classes declared with primary constructors, for example `@DVModel() class const _Order({required final String id, final int total = 0});`. Create, update and delete through the generated model: `Order(...).save()`, `order.delete()`, `Order.find(id)`. Forms are `Order.Form()` to create and `order.Form()` to edit; they take no callback and policies decide who may do what. Search is `Article.search(text)`, import is `Article.importCsv(...)`, `importNdjson(...)` or `importExcel(...)`, export is `Article.exportCsv(items)`. Never write through record operations, table or column names, or SQL strings.
<!-- dartvel:end architecture -->
