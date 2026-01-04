/// Defines a single validation rule constraint.
class RuleConstraint {
  final bool Function(dynamic value) validator;
  final String message;

  RuleConstraint(this.validator, this.message);
}

/// Fluent API for defining validation rules.
class Rule {
  final List<RuleConstraint> constraints = [];
  bool isRequired = false;

  /// Marks the field as required.
  Rule required([String? message]) {
    isRequired = true;
    constraints.add(
      RuleConstraint(
        (v) => v != null && v.toString().trim().isNotEmpty,
        message ?? 'Field is required',
      ),
    );
    return this;
  }

  /// Validates that the value is a valid email.
  Rule email([String? message]) {
    constraints.add(
      RuleConstraint((v) {
        if (v == null) return true; // Let required() handle nulls
        final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        return regex.hasMatch(v.toString());
      }, message ?? 'Invalid email address'),
    );
    return this;
  }

  /// Validates minimum length.
  Rule min(int length, [String? message]) {
    constraints.add(
      RuleConstraint(
        (v) => v != null && v.toString().length >= length,
        message ?? 'Must be at least $length characters',
      ),
    );
    return this;
  }

  // File validations
  Rule file() {
    // Placeholder: In a real implementation, check if value is a File object
    return this;
  }

  Rule maxSize(int bytes) {
    // Placeholder
    return this;
  }

  Rule type(List<String> extensions) {
    // Placeholder
    return this;
  }

  /// execution logic
  String? validate(dynamic value) {
    if (!isRequired && (value == null || value == '')) return null;

    for (var constraint in constraints) {
      if (!constraint.validator(value)) {
        return constraint.message;
      }
    }
    return null;
  }
}
