/// A simple event bus for publishing and subscribing to events.
class EventBus {
  static final Map<String, List<Function>> _listeners = {};

  /// Subscribes a [callback] to an [event].
  static void on(String event, Function callback) {
    if (!_listeners.containsKey(event)) {
      _listeners[event] = [];
    }
    _listeners[event]!.add(callback);
    print('[EventBus] Subscribed to "$event"');
  }

  /// Publishes an [event] with optional [data].
  static void publish(String event, [dynamic data]) {
    if (_listeners.containsKey(event)) {
      for (var callback in _listeners[event]!) {
        // Handle callbacks with 0 or 1 argument
        try {
          if (data != null) {
            callback(data);
          } else {
            callback();
          }
        } catch (e) {
          // Fallback for arity mismatch if needed, or just let it throw in dev
          print('[EventBus] Error executing callback for $event: $e');
        }
      }
    }
  }
}

/// Annotation to mark a method as an event listener.
class On {
  final String event;
  const On(this.event);
}
