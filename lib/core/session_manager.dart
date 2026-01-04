import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:axon/session_drivers/memory_session_driver.dart';
import 'package:axon/session_drivers/session_driver.dart';

class Session {
  final Map<String, dynamic> _values;
  SessionManager? _manager;
  Session(this._values);
  String id() {
    return _values[SessionManager.sessionIdLable];
  }

  dynamic get(String key) {
    return _values[key];
  }

  void put(String key, dynamic value) async {
    await _manager?.driver.put(id(), {key: value});
  }

  Map<String, dynamic> get values => {
    ..._values..remove(SessionManager.sessionIdLable),
  };
}

class SessionManager {
  static const String sessionIdLable = 'sessionId';

  static const Duration sessionExpiry = Duration(hours: 2);
  SessionDriver driver = MemorySessionDriver(); // Defaulting to Memory for dev
  static SessionManager? _instance;
  static SessionManager get instance => _instance ??= SessionManager();

  Future<Session> handle(HttpRequest request) async {
    var session = request.cookies.where((element) {
      return element.name == SessionManager.sessionIdLable;
    }).firstOrNull;
    if (session == null) {
      String sessionId = generateSessionId();
      request.response.cookies.add(Cookie(sessionIdLable, sessionId));
      await driver.set(sessionId, {}, sessionExpiry);
      return Session({SessionManager.sessionIdLable: sessionId})
        .._manager = this;
    } else {
      Map<String, dynamic>? sessionData = await driver.get(session.value);

      // Fix: If sessionData is null (expired/missing on server), start empty or new
      if (sessionData == null) {
        // Alternative: could regenerate ID, but for now just empty map
        sessionData = {};
      }

      return Session(
        sessionData..addAll({SessionManager.sessionIdLable: session.value}),
      ).._manager = this;
    }
  }

  String generateSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
