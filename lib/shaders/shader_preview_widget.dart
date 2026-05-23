import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'shader_controller.dart';
import 'shader_application.dart';
import 'base_shader_config.dart';

class ShaderPreviewWidget extends StatefulWidget {
  final Image image;
  final ShaderController shaderController;
  final BoxFit fit;

  const ShaderPreviewWidget({
    super.key,
    required this.image,
    required this.shaderController,
    this.fit = BoxFit.contain,
  });

  @override
  State<ShaderPreviewWidget> createState() => _ShaderPreviewWidgetState();
}

class _ShaderPreviewWidgetState extends State<ShaderPreviewWidget>
    with ShaderApplication {
  ui.Image? _sourceImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
    widget.shaderController.addListener(_handleShaderUpdate);
  }

  @override
  void didUpdateWidget(ShaderPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image) {
      _loadImage();
    }
    if (widget.shaderController != oldWidget.shaderController) {
      oldWidget.shaderController.removeListener(_handleShaderUpdate);
      widget.shaderController.addListener(_handleShaderUpdate);
    }
  }

  void _handleShaderUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadImage() async {
    final completer = Completer<ui.Image>();
    widget.image.image
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((info, _) {
      completer.complete(info.image);
    }));

    _sourceImage = await completer.future;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.shaderController.removeListener(_handleShaderUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_sourceImage == null) return const SizedBox();

    return AspectRatio(
      aspectRatio: _sourceImage!.width / _sourceImage!.height,
      child: CustomPaint(
        painter: _ShaderPainter(
          image: _sourceImage!,
          shaderController: widget.shaderController,
          fit: widget.fit,
          shaderApplication: applyShader,
        ),
      ),
    );
  }
}

class _ShaderPainter extends CustomPainter {
  final ui.Image image;
  final ShaderController shaderController;
  final BoxFit fit;
  final void Function(
          Canvas, Size, ui.Image, BaseShaderConfig, ui.FragmentProgram?)
      shaderApplication;

  _ShaderPainter({
    required this.image,
    required this.shaderController,
    required this.fit,
    required this.shaderApplication,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final activeShader = shaderController.activeShader;
    final program = shaderController.program;

    if (activeShader == null || activeShader.isAtDefaultValue) {
      // Draw original image if no shader or shader at default value
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint(),
      );
      return;
    }

    // Apply shader
    shaderApplication(canvas, size, image, activeShader, program);
  }

  @override
  bool shouldRepaint(covariant _ShaderPainter oldDelegate) {
    return image != oldDelegate.image ||
        shaderController != oldDelegate.shaderController ||
        fit != oldDelegate.fit;
  }
}
