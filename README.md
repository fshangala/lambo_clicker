# Lambo Clicker

Lambo Clicker is a Flutter app intended to turn a mobile device into a remote
clicker. Pressing the volume-up button on mobile sends a click event over a
WebSocket connection to desktop clients.

## Current status

Android can connect to a LAMBO Server room and send a click event when volume up
is pressed while the app is in the foreground. The desktop screen remains a
placeholder and does not yet receive events or execute mouse clicks.

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
configure an Android device or emulator. Copy `.env-example` to `.env` in the
project root and set `HOST` to the server's reachable hostname or IP address
and `PORT` to its port. On an Android emulator, `localhost` refers to the
emulator rather than your development machine; use an address reachable from
the emulator or device. Then, from the project root:

```sh
flutter pub get
flutter run
```

Select an Android device when prompted. Enter the same room code used by the
other client, then tap **Connect**. The room code is saved locally, but the
connection must be started manually each time; use **Retry connection** after a
connection failure or **Connect** after a disconnect. The status indicator
shows whether the socket is connecting, connected, disconnected, or in error.
While connected and the app is foregrounded, each volume-up press sends one
`click` event with an empty payload. The button does not change volume, holding
it does not repeat clicks, and presses made while disconnected are discarded
with feedback. A socket send does not guarantee delivery or a desktop click.

The app connects as `master` to
`ws://HOST:PORT/ws/pcautomation/ROOM?role=master`; room codes may contain only
letters, digits, hyphens, and underscores. See the
[server integration guide](https://raw.githubusercontent.com/fshangala/lambo_server/refs/heads/main/INTEGRATION.md)
for the protocol. Android permits cleartext networking for this `ws://`
connection, which is not encrypted. Use a trusted network.

The `.env` file is ignored by Git but bundled into the application at build
time, not read from the developer's current directory at runtime. Anyone with
the app can extract it, so do not put secrets in it. Create this file before
running or building the app. The current platform selection treats Android as
mobile and other targets as desktop.
