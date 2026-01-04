/// Base class for definitions that can be dynamically discovered and used.
abstract class Ability {
  /// Executes the ability.
  void execute();
}

/// Annotation to mark a class as a discoverable Ability.
class EnableAbility {
  final String? name;
  const EnableAbility([this.name]);
}
