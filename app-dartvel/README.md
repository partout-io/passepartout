# passepartout

A new Dartvel project.

## Getting Started

### Prerequisites

- Flutter SDK >= 3.47.0
- Dart SDK >= 3.13.0

### Installation

```bash
flutter pub get
```

### Development

```bash
dartvel dev
```

This will:
- Generate the client in `lib/dartvel_client/`
- Start the backend server on http://localhost:3000
- Run your Flutter app with hot reload

### Generating

`dartvel dev` and `dartvel build` generate before they run, so most of the
time there is nothing to do. To generate on its own — after adding a page,
model or backend function, or on a fresh clone before opening the project in
an editor:

```bash
dart run dartvel_cli:dartvel routes
```

That writes everything under `lib/dartvel_client/`: the barrel your pages
import, the router, models, backend function clients and config. It is
gitignored and never edited by hand: a fresh clone generates it.

### Project Structure

```
lib/
├── pages/              # Page components (file-based routing)
├── models/             # @DVModel classes
├── backend/
│   └── functions/      # API endpoints
├── components/         # Shared UI widgets
├── styles/             # Shared DVModifier styles
├── services/           # Business logic and integrations
└── main.dart

.env                    # Environment variables (gitignored)
pubspec.yaml           # Dependencies and Dartvel config
```

### Adding Pages

Create a new file in `lib/pages/`:

```dart
// lib/pages/about.dart
import '../dartvel_client/dartvel_client.dart';
import 'package:flutter/material.dart';


@DVPage(
  title: 'About',
  showAppBar: true,
)
@pragma('vm:entry-point')
Widget _aboutPage(BuildContext context) => buildAboutPage(context);

Widget buildAboutPage(BuildContext context) => DVBox.list([
    const DVText('About'),
    const DVText('About page'),
  ]).modifier(const DVModifier().padding(16));
```

Route is automatically available at `/about`.

### Adding API Endpoints

Create a new file in `lib/backend/functions/`:

```dart
// lib/backend/functions/hello.get.dart
import 'package:dartvel_core/dartvel.dart';

@DVBackendFunction()
Map<String, Object?> _hello() => <String, Object?>{'message': 'Hello World!'};
```

Endpoint is automatically available at `GET /api/hello`, and pages call it as `hello()`.

### Building for Production

```bash
dartvel build
```

## Learn More

- [Dartvel Documentation](https://dartvel.dev)
- [Flutter Documentation](https://flutter.dev)

## License

MIT
