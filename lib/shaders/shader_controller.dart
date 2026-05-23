import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'base_shader_config.dart';
import 'shader_program_manager.dart';
import 'shader_application.dart';

class ShaderController extends ChangeNotifier with ShaderApplication {
  BaseShaderConfig? _activeShader;
  ui.FragmentProgram? _program;
  bool _isDisposed = false;

  ShaderController();

  BaseShaderConfig? get activeShader => _activeShader;
  ui.FragmentProgram? get program => _program;

  Future<void> setShader(BaseShaderConfig config) async {
    if (_isDisposed) return;

    try {
      // Get shader program from manager
      final program =
          await ShaderProgramManager.instance.getProgram(config.runtimeType);
      if (program == null) {
        throw Exception(
            'Failed to get shader program for ${config.runtimeType}');
      }

      _activeShader = config;
      _program = program;

      debugPrint(
          '✅ Set shader: ${config.shaderId} with uniforms: ${config.uniforms}');

      if (!_isDisposed) {
        notifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('🚫 Failed to set shader: ${config.shaderId}');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateShader(BaseShaderConfig config) async {
    if (_isDisposed) return;

    if (_activeShader?.shaderId != config.shaderId) {
      // Different shader type, need to load new program
      await setShader(config);
    } else {
      // Same shader type, just update values
      _activeShader = config;
      debugPrint(
          '✅ Updated shader: ${config.shaderId} with uniforms: ${config.uniforms}');
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  void clearShader() {
    if (_isDisposed) return;

    _activeShader = null;
    _program = null;
    debugPrint('🧹 Cleared shader');
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Exports the image with current shader effects applied.
  /// Returns the processed image, or the original image if no shader is active.
  /// The caller is responsible for disposing the returned image when no longer needed.
  Future<ui.Image> exportProcessedImage(ui.Image sourceImage, Size size) async {
    if (_isDisposed) {
      throw StateError('ShaderController is disposed');
    }

    // If no shader is active or shader is at default values, return a copy of the original
    if (_activeShader == null ||
        _program == null ||
        _activeShader!.isAtDefaultValue) {
      return sourceImage.clone();
    }

    // Create a recorder and canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Apply the shader
    applyShader(canvas, size, sourceImage, _activeShader!, _program!);

    // Convert to image
    final picture = recorder.endRecording();
    final processedImage = await picture.toImage(
      size.width.round(),
      size.height.round(),
    );

    return processedImage;
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _activeShader = null;
    _program = null;
    debugPrint('🗑️ Disposed ShaderController');
    super.dispose();
  }
}
