import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

class ShaderProgramManager {
  static final ShaderProgramManager instance = ShaderProgramManager._();
  ShaderProgramManager._();

  final Map<Type, ui.FragmentProgram> _programs = {};
  final Map<Type, Future<ui.FragmentProgram> Function()> _programProviders = {};

  void registerProvider<T>(Future<ui.FragmentProgram> Function() provider) {
    debugPrint('📝 Registering shader provider for type: $T');
    _programProviders[T] = provider;
  }

  Future<ui.FragmentProgram?> getProgram<T>([Type? type]) async {
    final targetType = type ?? T;

    // Return existing program if already compiled
    if (_programs.containsKey(targetType)) {
      return _programs[targetType];
    }

    // Get provider and compile program
    final provider = _programProviders[targetType];
    if (provider == null) {
      debugPrint('❌ No shader provider found for type: $targetType');
      return null;
    }

    try {
      debugPrint('🔄 Compiling shader program for: $targetType');
      final program = await provider();
      _programs[targetType] = program;
      debugPrint('✅ Shader program ready for: $targetType');
      return program;
    } catch (e) {
      debugPrint('❌ Failed to compile shader program for $targetType: $e');
      return null;
    }
  }

  void clearPrograms() {
    final count = _programs.length;
    _programs.clear();
    _programProviders.clear();
    debugPrint('🧹 Cleared $count shader programs');
  }

  // Debug helpers
  int get totalPrograms => _programs.length;
  int get totalProviders => _programProviders.length;
  Set<Type> get registeredTypes => _programProviders.keys.toSet();

  void printStatus() {
    debugPrint('\n📊 Shader Program Status:');
    debugPrint('Registered Providers: ${_programProviders.length}');
    debugPrint('Compiled Programs: ${_programs.length}');
    debugPrint('Available Shaders:');
    for (final type in _programProviders.keys) {
      final isCompiled = _programs.containsKey(type);
      debugPrint('  - $type: ${isCompiled ? '✅ Ready' : '⏳ Not Compiled'}');
    }
    debugPrint('');
  }
}
