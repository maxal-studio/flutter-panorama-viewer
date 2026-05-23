import 'package:panorama_viewer/shaders/base_shader_config.dart';

class BrightnessShaderConfig extends BaseShaderConfig {
  static const parameter = ShaderParameter<double>.definition(
    name: 'inputBrightness',
    defaultValue: 0.0,
    min: -1.0,
    max: 1.0,
  );

  final ShaderParameter<double> brightness;

  BrightnessShaderConfig({required double value})
      : brightness = parameter.withValue(value);

  @override
  List<ShaderParameter> get parameters => [brightness];
}
