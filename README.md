# Lambo Clicker

Lambo Clicker is a Flutter app intended to turn a mobile device into a remote
clicker. Pressing the volume-up button on mobile sends a click event over a
WebSocket connection to desktop clients.

## Current status

The app currently displays placeholder mobile and desktop screens. Volume-button
handling, WebSocket communication, click execution, and the architecture below
are not yet implemented.

## Project architecture

The project follows these standards as it is developed:

- Use MVVM, with views for presentation and view models for presentation logic
  and state. Keep one main class per file; related helper classes may share that
  file.
- Use a modern design with a separate, centralized theme. All styles, colors,
  and fonts must come from the theme, not hard-coded values in the app.
- Use `MultiProvider` for dependency and state provisioning. An `AppViewModel`
  owns global state that is not specific to a view.
- Load app configuration from `.env` using `flutter_dotenv`. Persist settings
  configured at runtime using `shared_preferences`.
- Log errors using `logger`.

## Getting started

Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) and
configure a supported development target. From the project root:

```sh
flutter pub get
flutter run
```

Select a device when prompted. The current platform selection treats Android as
mobile and other targets as desktop; this does not imply the remote-clicker
features are supported yet.

The repository includes `.env-example` as a starting point for local
configuration. Copy it to `.env` and adjust the values for your environment
when configuration loading is implemented. `.env` is ignored by Git; do not put
secrets in a Flutter app's bundled assets.
