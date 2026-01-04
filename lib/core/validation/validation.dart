import 'package:axon/core/validation/rules.dart';
import 'package:axon/blueprints/blueprint.dart';

/// Base class for defining validations.
/// Extend this and annotate with @AttachTo(Target) to bind it.
abstract class Validation {
  /// Define global rules (applied to any method).
  Map<String, Rule> rules(Request request) => {};

  /// Define method-specific rules.
  /// Keys are HTTP methods ('POST', 'GET').
  /// Values are maps of 'FieldName' -> Rule.
  Map<String, Map<String, Rule>> methodRules(Request request) => {};

  Map<String, String> validate(Request request) {
    final errors = <String, String>{};
    final data = request.body.values
        .cast<String, dynamic>(); // Assuming body map
    final method = request.method;

    // 1. Merge global rules and method-specific rules
    final allRules = {...rules(request)};
    // 2. Fetch specific rules case-insensitively
    final methodRulesMap = methodRules(request);
    Map<String, Rule>? specificRules;

    // Exact match first
    if (methodRulesMap.containsKey(method)) {
      specificRules = methodRulesMap[method];
    } else {
      // Case-insensitive fallback
      final upperMethod = method.toUpperCase();
      for (final key in methodRulesMap.keys) {
        if (key.toUpperCase() == upperMethod) {
          specificRules = methodRulesMap[key];
          break;
        }
      }
    }

    if (specificRules != null) {
      allRules.addAll(specificRules);
    }

    // 2. Validate each field
    allRules.forEach((field, rule) {
      final value = data[field];
      final error = rule.validate(value);
      if (error != null) {
        errors[field] = error;
      }
    });

    return errors;
  }
}
