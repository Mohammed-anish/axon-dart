import 'session_driver.dart';

/// A simple in-memory session driver.
/// Not suitable for production with multiple instances, but great for dev/testing.
class MemorySessionDriver implements SessionDriver {
  final Map<String, Map<String, dynamic>> _storage = {};

  // TODO: Implement actual TTL cleanup if needed

  @override
  Future<void> destroy(String id) async {
    _storage.remove(id);
  }

  @override
  Future<void> expire(String id, Duration ttl) async {
    // No-op for simple memory driver, or implement timer
  }

  @override
  Future<Map<String, dynamic>?> get(String id) async {
    return _storage[id];
  }

  @override
  Future<void> put(
    String id,
    Map<String, dynamic> data, [
    Duration? ttl,
  ]) async {
    if (_storage.containsKey(id)) {
      _storage[id]!.addAll(data);
    } else {
      _storage[id] = data;
    }
  }

  @override
  Future<void> set(
    String id,
    Map<String, dynamic> data, [
    Duration? ttl,
  ]) async {
    _storage[id] = data;
  }
}
