import 'dart:mirrors';

/// A utility class for handling reflection operations using dart:mirrors.
class Reflector {
  /// Reflects on the given [instance] and invokes the method named [methodName].
  ///
  /// [positionalArguments] are passed as positional arguments.
  /// [namedArguments] are passed as named arguments.
  static dynamic invokeMethod(
    Object instance,
    String methodName, {
    List<dynamic>? positionalArguments,
    Map<Symbol, dynamic>? namedArguments,
  }) {
    final mirror = reflect(instance);
    final symbol = Symbol(methodName);
    return mirror
        .invoke(symbol, positionalArguments ?? [], namedArguments ?? {})
        .reflectee;
  }

  /// Finds all classes in the current isolate that have the specified [annotation].
  static List<ClassMirror> findClassesWithAnnotation(Type annotation) {
    final classes = <ClassMirror>[];
    final mirrorSystem = currentMirrorSystem();

    for (var library in mirrorSystem.libraries.values) {
      for (var declaration in library.declarations.values) {
        if (declaration is ClassMirror) {
          for (var meta in declaration.metadata) {
            if (meta.reflectee.runtimeType == annotation) {
              classes.add(declaration);
              break;
            }
          }
        }
      }
    }
    return classes;
  }

  /// Finds all classes that are subclasses of [baseClass].
  static List<ClassMirror> findSubclassesOf(Type baseClass) {
    final classes = <ClassMirror>[];
    final mirrorSystem = currentMirrorSystem();
    final baseMirror = reflectClass(baseClass);

    for (var library in mirrorSystem.libraries.values) {
      for (var declaration in library.declarations.values) {
        if (declaration is ClassMirror &&
            declaration.isSubclassOf(baseMirror) &&
            declaration != baseMirror) {
          classes.add(declaration);
        }
      }
    }
    return classes;
  }

  /// Creates an instance of the class represented by [classMirror].
  static dynamic createInstance(
    ClassMirror classMirror, [
    Symbol constructorName = const Symbol(''),
    List<dynamic>? positionalArguments,
    Map<Symbol, dynamic>? namedArguments,
  ]) {
    return classMirror
        .newInstance(
          constructorName,
          positionalArguments ?? [],
          namedArguments ?? {},
        )
        .reflectee;
  }

  /// Returns a list of types required by the default constructor of [classMirror].
  static List<Type> getConstructorParameterTypes(ClassMirror classMirror) {
    DeclarationMirror? constructor;

    try {
      // Try to find default constructor
      constructor =
          classMirror.declarations[const Symbol('')] ??
          classMirror.declarations[Symbol(
            MirrorSystem.getName(classMirror.simpleName),
          )];
    } catch (_) {}

    if (constructor == null) {
      // Fallback: search for any constructor with name '' or class name
      for (var entry in classMirror.declarations.entries) {
        if (entry.value is MethodMirror &&
            (entry.value as MethodMirror).isConstructor) {
          if (MirrorSystem.getName(entry.key) == '' ||
              MirrorSystem.getName(entry.key) ==
                  MirrorSystem.getName(classMirror.simpleName)) {
            constructor = entry.value;
            break;
          }
        }
      }
    }

    if (constructor is MethodMirror) {
      return constructor.parameters.map((p) {
        if (p.type is ClassMirror) {
          return (p.type as ClassMirror).reflectedType;
        }
        return dynamic;
      }).toList();
    }
    return [];
  }
}
