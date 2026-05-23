import 'package:flutter/foundation.dart';

class ShaderParameter<T extends Object> {
  final String name;
  final T value;
  final T defaultValue;
  final T? min;
  final T? max;
  final List<T>? allowedValues;

  const ShaderParameter({
    required this.name,
    required this.value,
    required this.defaultValue,
    this.min,
    this.max,
    this.allowedValues,
  });

  /// Create a static parameter definition without a current value
  const ShaderParameter.definition({
    required this.name,
    required this.defaultValue,
    this.min,
    this.max,
    this.allowedValues,
  }) : value = defaultValue;

  /// Create a parameter instance from a definition with a new value
  ShaderParameter<T> withValue(T newValue) => ShaderParameter(
        name: name,
        value: newValue,
        defaultValue: defaultValue,
        min: min,
        max: max,
        allowedValues: allowedValues,
      );

  /// Get the default value for this parameter
  T get defaultVal => defaultValue;

  /// Get the minimum value for this parameter
  T? get minVal => min;

  /// Get the maximum value for this parameter
  T? get maxVal => max;

  bool get isAtDefault => value == defaultValue;

  bool validate() {
    if (allowedValues != null && !allowedValues!.contains(value)) {
      debugPrint(
          '❌ Invalid value for $name: $value. Allowed values: $allowedValues');
      return false;
    }

    if (value is num) {
      final numValue = value as num;
      final numMin = min as num?;
      final numMax = max as num?;

      if (numMin != null && numValue < numMin) {
        debugPrint('❌ Value $value for $name is less than minimum: $numMin');
        return false;
      }

      if (numMax != null && numValue > numMax) {
        debugPrint('❌ Value $value for $name is greater than maximum: $numMax');
        return false;
      }
    }

    return true;
  }

  @override
  String toString() =>
      '$name: $value (default: $defaultValue${min != null ? ', min: $min' : ''}${max != null ? ', max: $max' : ''})';
}

abstract class BaseShaderConfig {
  /// Automatically derives shader ID from the class name
  String get shaderId => runtimeType.toString().toLowerCase();

  /// List of parameters for this shader
  List<ShaderParameter> get parameters;

  /// Priority determines the order in which shaders are applied.
  /// Lower numbers are applied first.
  int get priority => 0;

  /// Returns true if all parameters are at their default values
  bool get isAtDefaultValue => parameters.every((p) => p.isAtDefault);

  /// Current uniform values for the shader
  Map<String, dynamic> get uniforms {
    final Map<String, dynamic> map = {
      'inputImageTexture': 0
    }; // Common for all shaders
    for (final param in parameters) {
      if (param.value is num || param.value is bool) {
        map[param.name] = param.value;
      }
    }
    return map;
  }

  /// Validate all parameters
  bool validateParameters() {
    final invalidParams = parameters.where((p) => !p.validate()).toList();
    if (invalidParams.isNotEmpty) {
      debugPrint('❌ Invalid parameters for shader $shaderId:');
      for (final param in invalidParams) {
        debugPrint('  - $param');
      }
      return false;
    }
    return true;
  }

  @override
  String toString() {
    return '$shaderId(${parameters.map((p) => p.toString()).join(", ")})';
  }
}

class ValidationRule {
  final dynamic min;
  final dynamic max;
  final List<dynamic>? allowedValues;
  final Type expectedType;

  const ValidationRule({
    this.min,
    this.max,
    this.allowedValues,
    required this.expectedType,
  });

  bool validate(dynamic value) {
    if (value.runtimeType != expectedType) return false;
    if (min != null && value < min) return false;
    if (max != null && value > max) return false;
    if (allowedValues != null && !allowedValues!.contains(value)) return false;
    return true;
  }
}
