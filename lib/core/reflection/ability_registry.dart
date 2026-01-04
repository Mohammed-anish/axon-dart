import 'package:axon/core/events/event_bus.dart';
import 'package:axon/core/context.dart';
import 'package:axon/core/reflection/ability.dart';
import 'package:axon/core/reflection/reflector.dart';
import 'dart:mirrors';

/// Registry for managing discoverable abilities.
class AbilityRegistry {
  static final Map<String, Ability> _abilities = {};

  /// Scans for classes annotated with [EnableAbility] and registers them.
  static void scanAndRegister() {
    print('[AbilityRegistry] Scanning for abilities...');
    final classes = Reflector.findSubclassesOf(Ability);

    for (final cls in classes) {
      bool isEnabled = false;
      String? name;

      for (var meta in cls.metadata) {
        if (meta.reflectee is EnableAbility) {
          isEnabled = true;
          name = (meta.reflectee as EnableAbility).name;
          break;
        }
      }

      if (isEnabled) {
        // DI: Resolve constructor parameters
        final paramTypes = Reflector.getConstructorParameterTypes(cls);

        final args = paramTypes.map((type) {
          return Context().getDependencyByType(type);
        }).toList();

        final instance = Reflector.createInstance(cls, const Symbol(''), args);

        if (instance is Ability) {
          final abilityName = name ?? cls.simpleName.toString();
          _abilities[abilityName] = instance;
          print('[AbilityRegistry] Registered ability: $abilityName');

          // Event Bus: Scan for @On annotations
          final instanceMirror = reflect(instance);
          for (var declaration in instanceMirror.type.declarations.values) {
            if (declaration is MethodMirror && declaration.isRegularMethod) {
              for (var meta in declaration.metadata) {
                if (meta.reflectee is On) {
                  final eventName = (meta.reflectee as On).event;
                  EventBus.on(eventName, () {
                    instanceMirror.invoke(declaration.simpleName, []);
                  });
                }
              }
            }
          }
        }
      }
    }
  }

  /// Retrieves a registered ability by name.
  static Ability? getAbility(String name) => _abilities[name];

  /// Returns all registered abilities.
  static Map<String, Ability> get abilities => _abilities;
}
