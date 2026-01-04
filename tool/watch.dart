#!/usr/bin/env dart
// Simple file watcher to autorestart the Dart server for development.
// Usage:
//  dart run tool/watch.dart [<entrypoint>]
// Example:
//  dart run tool/watch.dart            # watches and runs bin/main.dart
//  dart run tool/watch.dart bin/server.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

final watchPaths = [
  'lib',
  'bin',
  'web',
  'test',
  'pubspec.yaml',
  'analysis_options.yaml',
];

void main(List<String> args) async {
  final entrypoint = args.isNotEmpty ? args[0] : 'bin/main.dart';
  print('Watcher: watching ${watchPaths.join(', ')}');
  print('Watcher: running entrypoint: $entrypoint');

  Process? server;
  Timer? debounceTimer;
  var restarting = false;
  var freeingPort = false;
  late Future<void> Function() restartServer;

  Future<void> killProcessUsingPort(int port) async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('netstat', ['-ano', '-p', 'tcp']);
        if (result.exitCode == 0) {
          final out = result.stdout as String;
          final lines = out.split(RegExp(r'\r?\n'));
          final regex = RegExp(
            r"\s*TCP\s+[^:]+:(\d+)\s+[^\s]+\s+LISTENING\s+(\d+)",
            caseSensitive: false,
          );
          for (final line in lines) {
            final m = regex.firstMatch(line);
            if (m != null) {
              final p = int.tryParse(m.group(1)!);
              final pid = int.tryParse(m.group(2)!);
              if (p == port && pid != null) {
                print(
                  'Found process $pid listening on port $port; killing it (taskkill) ...',
                );
                await Process.run('taskkill', [
                  '/F',
                  '/T',
                  '/PID',
                  pid.toString(),
                ]);
                return;
              }
            }
          }
        }
      } else {
        // try lsof
        try {
          final r = await Process.run('lsof', ['-i', ':$port', '-t']);
          if (r.exitCode == 0 && (r.stdout as String).trim().isNotEmpty) {
            final pidStr = (r.stdout as String).trim().split('\n').first;
            final pid = int.tryParse(pidStr);
            if (pid != null) {
              print(
                'Found process $pid listening on port $port; killing it with kill -9',
              );
              await Process.run('kill', ['-9', pid.toString()]);
              return;
            }
          }
        } catch (_) {}

        // fallback to fuser
        try {
          await Process.run('fuser', ['-k', '$port/tcp']);
        } catch (_) {}
      }
    } catch (e) {
      print('Error while attempting to find/kill process using port $port: $e');
    }
  }

  Future<void> startServer() async {
    if (server != null) return;
    print('--- Starting server ($entrypoint) ---');
    try {
      // Start without detached mode so we can observe exitCode and forward stdio
      server = await Process.start('dart', ['run', entrypoint]);
    } catch (e) {
      print('Failed to start server: $e');
      server = null;
      return;
    }

    // Forward stdout/stderr
    if (server != null) {
      server!.stdout.transform(utf8.decoder).listen((s) => stdout.write(s));
      server!.stderr.transform(utf8.decoder).listen((s) {
        stderr.write(s);
        try {
          if (s.contains('Failed to create server socket') ||
              s.contains('Only one usage of each socket address')) {
            final m =
                RegExp(r'port\s*=\s*(\d+)').firstMatch(s) ??
                RegExp(r'port\s*(\d+)').firstMatch(s);
            final port = m != null ? int.tryParse(m.group(1)!) : null;
            if (port != null && !freeingPort) {
              freeingPort = true;
              // Free the port, then retry starting
              killProcessUsingPort(port)
                  .then((_) async {
                    await Future.delayed(Duration(milliseconds: 400));
                    print('Retrying to start server after freeing port');
                    await restartServer();
                  })
                  .whenComplete(() => freeingPort = false);
            }
          }
        } catch (_) {}
      });

      server!.exitCode
          .then((code) {
            print('--- Server exited with code $code ---');
            server = null;
          })
          .catchError((_) {
            // ignore errors from exitCode
          });
    }
  }

  Future<void> stopServer() async {
    if (server == null) return;
    final pid = server!.pid;
    print('--- Stopping server (pid $pid) ---');
    try {
      // Try a graceful kill first
      var ok = false;
      try {
        ok = server!.kill(ProcessSignal.sigterm);
      } catch (_) {
        // ignore
      }
      if (!ok) {
        try {
          Process.killPid(pid);
        } catch (_) {}
      }
    } catch (e) {
      print('Error stopping server: $e');
    }

    // Wait for process to exit. If it doesn't, attempt a force kill (Windows: taskkill)
    try {
      await server!.exitCode.timeout(Duration(seconds: 5));
    } catch (_) {
      // Not exited yet, try forceful measures
      try {
        if (Platform.isWindows) {
          print('Process did not exit; attempting taskkill /F /T /PID $pid');
          await Process.run('taskkill', ['/F', '/T', '/PID', pid.toString()]);
        } else {
          try {
            Process.killPid(pid);
          } catch (_) {}
        }
      } catch (e) {
        print('Error forcing kill: $e');
      }

      try {
        await server!.exitCode.timeout(Duration(seconds: 3));
      } catch (_) {
        // Final attempt
        try {
          if (Platform.isWindows) {
            await Process.run('taskkill', ['/F', '/T', '/PID', pid.toString()]);
          } else {
            Process.killPid(pid);
          }
        } catch (_) {}
      }
    }

    // Give the OS a small moment to release sockets bound by the process
    await Future.delayed(Duration(milliseconds: 300));

    server = null;
  }

  restartServer = () async {
    if (restarting) return;
    restarting = true;
    await stopServer();
    await startServer();
    restarting = false;
  };

  // Setup watchers
  for (final p in watchPaths) {
    final entity = FileSystemEntity.typeSync(p);
    if (entity == FileSystemEntityType.notFound) continue;
    if (entity == FileSystemEntityType.directory) {
      final dir = Directory(p);
      dir.watch(recursive: true).listen((event) {
        // Debounce bursty events
        debounceTimer?.cancel();
        debounceTimer = Timer(Duration(milliseconds: 300), () {
          print('Change detected: ${event.path}');
          restartServer();
        });
      });
    } else {
      // it's a file e.g. pubspec.yaml
      File(p).watch().listen((event) {
        debounceTimer?.cancel();
        debounceTimer = Timer(Duration(milliseconds: 300), () {
          print('Change detected: $p');
          restartServer();
        });
      });
    }
  }

  // Start initially
  await startServer();

  // Handle Ctrl-C / graceful shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    print('Interrupted, shutting down...');
    await stopServer();
    exit(0);
  });

  // Keep the process alive
  await Completer<void>().future;
}
