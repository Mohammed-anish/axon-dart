import 'dart:async';

/// Generic session driver interface.
abstract class SessionDriver {
  /// Store session data for [id]. If [ttl] is provided, set an expiration.
  Future<void> set(String id, Map<String, dynamic> data, [Duration? ttl]);
  Future<void> put(String id, Map<String, dynamic> data, [Duration? ttl]);

  /// Retrieve session data for [id], or `null` if not found.
  Future<Map<String, dynamic>?> get(String id);

  /// Remove a session by [id].
  Future<void> destroy(String id);

  /// Set expiration for a session [id].
  Future<void> expire(String id, Duration ttl);
}
