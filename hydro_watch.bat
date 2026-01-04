@echo off
REM Convenience script to run the dev watcher on Windows.
REM Usage: hydro_watch [entrypoint]
REM Example: hydro_watch           -> runs bin/main.dart
REM          hydro_watch bin/server.dart

if "%~1"=="" (
  set ENTRY=bin/main.dart
) else (
  set ENTRY=%~1
)

echo Running watcher for %ENTRY%

dart run tool/watch.dart %ENTRY%
