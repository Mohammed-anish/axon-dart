Developer scripts and tools

Auto-reload watcher

- Script: `tool/watch.dart`
- Purpose: Watches `lib/`, `bin/`, `web/`, `test/`, and `pubspec.yaml` and restarts the server when files change.

Quick start (Windows):
- Open a terminal in the project root and run:
  `hydro_watch` (or `dart run tool/watch.dart`)

Quick start (Unix / other):
- Run:
  `dart run tool/watch.dart` (optionally pass a custom entrypoint: `dart run tool/watch.dart bin/server.dart`)

Notes:
- Debounces rapid file change events to avoid frequent restarts.
- Press Ctrl-C to stop both watcher and server.
- If you want TTL preservation or advanced restart strategy (hot-reload-like), we can extend the watcher to use `dart vm-service` or use more sophisticated build tools.
