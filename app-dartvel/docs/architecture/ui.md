<!-- dartvel:begin architecture -->
# UI

Pages are private `@DVPage` functions or `DVClassWidget` classes and import the generated barrel `dartvel_client/dartvel_client.dart`. Children go in `DVBox.list([...])`, `DVBox.row([...])` or `DVBox.grid([...])`; `DVBox(widget)` is for one child. Every page is selectable, keyboard-navigable and readable by screen readers with nothing added, and forms submit with Enter.
<!-- dartvel:end architecture -->
