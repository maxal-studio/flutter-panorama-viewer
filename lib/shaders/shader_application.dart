import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'base_shader_config.dart';

mixin ShaderApplication {
  void applyShader(Canvas canvas, Size size, ui.Image sourceImage,
      BaseShaderConfig config, ui.FragmentProgram? program) {
    if (program == null) return;

    final shader = program.fragmentShader();
    shader.setImageSampler(0, sourceImage);

    // Set shader uniforms
    final List<double> uniforms = [];
    for (final entry in config.uniforms.entries) {
      if (entry.key != 'inputImageTexture') {
        uniforms.add(entry.value as double);
      }
    }
    // Add screen size uniforms last
    uniforms.add(size.width);
    uniforms.add(size.height);

    // Set all uniforms
    for (int i = 0; i < uniforms.length; i++) {
      shader.setFloat(i, uniforms[i]);
    }

    // Apply shader
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = shader
        ..blendMode = BlendMode.srcOver,
    );
  }
}
