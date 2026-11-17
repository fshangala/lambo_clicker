# Copilot instructions

## Architecture

- Follow MVVM: keep presentation in views and presentation logic and state in
  view models.
- Define one main class per file. Closely related helper classes may live in the
  same file as their main class.
- Use `MultiProvider` for providers. Put global state that is not specific to a
  view in an `AppViewModel`; keep view-specific state in its own view model.

## Design

- Use a modern, consistent design and define the app theme in a separate file.
- Obtain all styles, colors, and fonts from the centralized theme. Do not
  hard-code them in views or other parts of the app; extend the theme when
  additional design values are needed.

## Configuration and logging

- Load app configuration from `.env` with `flutter_dotenv`.
- Persist configuration set at runtime with `shared_preferences`.
- Log errors using `logger`; do not silently suppress failures.
- Do not commit `.env` or embed secrets in Flutter assets.

## Product intent

- A mobile volume-up press should send a click event to desktop clients over a
  WebSocket connection. The current screens are placeholders; do not assume the
  click flow or the architecture above is already implemented.
