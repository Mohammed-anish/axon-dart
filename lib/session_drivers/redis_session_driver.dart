import 'dart:async';
import 'dart:convert';

import 'package:redis/redis.dart';

import 'session_driver.dart';

/// Redis-backed session driver.
///
/// Stores session data as a JSON string under `prefix + id`.
class RedisSessionDriver implements SessionDriver {
  final String host;
  final int port;
  final String prefix;

  Command? _cmd;

  RedisSessionDriver({
    this.host = '127.0.0.1',
    this.port = 6379,
    this.prefix = 'session:',
  });

  Future<void> _ensureConnected() async {
    if (_cmd != null) return;
    _cmd = await RedisConnection().connect(host, port);
  }

  String _key(String id) => '$prefix$id';

  @override
  Future<void> set(
    String id,
    Map<String, dynamic> data, [
    Duration? ttl,
  ]) async {
    await _ensureConnected();
    final jsonStr = jsonEncode(data);
    await _cmd!.set(_key(id), jsonStr);
    if (ttl != null) {
      await _cmd!.send_object(['EXPIRE', _key(id), ttl.inSeconds.toString()]);
    }
  }

  @override
  Future<Map<String, dynamic>?> get(String id) async {
    await _ensureConnected();
    final val = await _cmd!.get(_key(id));
    if (val == null) return null;
    try {
      return jsonDecode(val) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> destroy(String id) async {
    await _ensureConnected();
    await _cmd!.send_object(['DEL', _key(id)]);
  }

  @override
  Future<void> expire(String id, Duration ttl) async {
    await _ensureConnected();
    await _cmd!.send_object(['EXPIRE', _key(id), ttl.inSeconds.toString()]);
  }

  /// Close the underlying connection.
  Future<void> close() async {
    if (_cmd == null) return;
    final conn = _cmd!.get_connection();
    await conn.close();
    _cmd = null;
  }

  @override
  Future<void> put(
    String id,
    Map<String, dynamic> data, [
    Duration? ttl,
  ]) async {
    // Merge incoming data into existing session map (if any), then save.
    await _ensureConnected();

    final existing = await get(id);
    final merged = <String, dynamic>{};
    if (existing != null) {
      merged.addAll(existing);
    }
    merged.addAll(data);

    final jsonStr = jsonEncode(merged);
    await _cmd!.set(_key(id), jsonStr);

    if (ttl != null) {
      await _cmd!.send_object(['EXPIRE', _key(id), ttl.inSeconds.toString()]);
    }
  }
}
