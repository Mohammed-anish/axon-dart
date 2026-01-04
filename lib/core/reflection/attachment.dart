import 'dart:mirrors';
import 'package:axon/core/reflection/reflector.dart';

/// Annotation to attach a class to a target class.
class AttachTo {
  final Type target;
  const AttachTo(this.target);
}

/// Registry to manage attachments.
class AttachmentRegistry {
  static final Map<Type, List<dynamic>> _attachments = {};

  /// Scans for classes annotated with @AttachTo and registers them.
  static void scan() {
    print('[AttachmentRegistry] Scanning for attachments...');
    final mirrorSystem = currentMirrorSystem();

    for (var library in mirrorSystem.libraries.values) {
      for (var declaration in library.declarations.values) {
        if (declaration is ClassMirror) {
          for (var meta in declaration.metadata) {
            if (meta.reflectee is AttachTo) {
              final target = (meta.reflectee as AttachTo).target;
              final instance = Reflector.createInstance(declaration);
              register(target, instance);
              print(
                '[AttachmentRegistry] Attached ${declaration.simpleName} to $target',
              );
            }
          }
        }
      }
    }
  }

  static void register(Type target, dynamic attachment) {
    if (!_attachments.containsKey(target)) {
      _attachments[target] = [];
    }
    _attachments[target]!.add(attachment);
  }

  /// Returns attachments of type [T] for the [target] type.
  static List<T> get<T>(Type target) {
    if (_attachments.containsKey(target)) {
      return _attachments[target]!.whereType<T>().toList();
    }
    return [];
  }
}

/// Mixin to easily access attachments from the target class.
mixin WithAttachments {
  List<T> getAttachments<T>() {
    return AttachmentRegistry.get<T>(this.runtimeType);
  }

  T? use<T>() {
    final list = getAttachments<T>();
    return list.isNotEmpty ? list.first : null;
  }
}
