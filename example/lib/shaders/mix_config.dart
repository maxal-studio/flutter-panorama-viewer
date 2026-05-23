import 'package:panorama_viewer/shaders/base_shader_config.dart';

class MixShaderConfig extends BaseShaderConfig {
  // Static parameter definitions
  static const brightnessParam = ShaderParameter<double>.definition(
    name: 'inputBrightness',
    defaultValue: 0.0,
    min: -1.0,
    max: 1.0,
  );

  static const contrastParam = ShaderParameter<double>.definition(
    name: 'inputContrast',
    defaultValue: 1.0,
    min: 0.0,
    max: 4.0,
  );

  static const gammaParam = ShaderParameter<double>.definition(
    name: 'inputGamma',
    defaultValue: 1.0,
    min: 0.0,
    max: 3.0,
  );

  static const exposureParam = ShaderParameter<double>.definition(
    name: 'inputExposure',
    defaultValue: 0.0,
    min: -10.0,
    max: 10.0,
  );

  static const sharpenParam = ShaderParameter<double>.definition(
    name: 'inputSharpen',
    defaultValue: 0.0,
    min: 0.0,
    max: 5.0,
  );

  static const vibranceParam = ShaderParameter<double>.definition(
    name: 'inputVibrance',
    defaultValue: 0.0,
    min: -1.0,
    max: 1.0,
  );

  static const sepiaParam = ShaderParameter<double>.definition(
    name: 'inputSepia',
    defaultValue: 0.0,
    min: 0.0,
    max: 1.0,
  );

  static const invertParam = ShaderParameter<double>.definition(
    name: 'inputInvert',
    defaultValue: 0.0,
    min: 0.0,
    max: 1.0,
  );

  static const saturationParam = ShaderParameter<double>.definition(
    name: 'inputSaturation',
    defaultValue: 1.0,
    min: 0.0,
    max: 2.0,
  );

  static const hueParam = ShaderParameter<double>.definition(
    name: 'inputHueAdjust',
    defaultValue: 0.0,
    min: 0.0,
    max: 360.0,
  );

  final ShaderParameter<double> brightness;
  final ShaderParameter<double> contrast;
  final ShaderParameter<double> gamma;
  final ShaderParameter<double> exposure;
  final ShaderParameter<double> sharpen;
  final ShaderParameter<double> vibrance;
  final ShaderParameter<double> sepia;
  final ShaderParameter<double> invert;
  final ShaderParameter<double> saturation;
  final ShaderParameter<double> hue;

  MixShaderConfig({
    double? brightnessValue,
    double? contrastValue,
    double? gammaValue,
    double? exposureValue,
    double? sharpenValue,
    double? vibranceValue,
    double? sepiaValue,
    double? invertValue,
    double? saturationValue,
    double? hueValue,
  })  : brightness = brightnessParam
            .withValue(brightnessValue ?? brightnessParam.defaultValue),
        contrast = contrastParam
            .withValue(contrastValue ?? contrastParam.defaultValue),
        gamma = gammaParam.withValue(gammaValue ?? gammaParam.defaultValue),
        exposure = exposureParam
            .withValue(exposureValue ?? exposureParam.defaultValue),
        sharpen =
            sharpenParam.withValue(sharpenValue ?? sharpenParam.defaultValue),
        vibrance = vibranceParam
            .withValue(vibranceValue ?? vibranceParam.defaultValue),
        sepia = sepiaParam.withValue(sepiaValue ?? sepiaParam.defaultValue),
        invert = invertParam.withValue(invertValue ?? invertParam.defaultValue),
        saturation = saturationParam
            .withValue(saturationValue ?? saturationParam.defaultValue),
        hue = hueParam.withValue(hueValue ?? hueParam.defaultValue) {
    assert(validateParameters(), 'Invalid parameter values');
  }

  @override
  List<ShaderParameter> get parameters => [
        brightness, // location 0
        contrast, // location 1
        gamma, // location 2
        exposure, // location 3
        sharpen, // location 4
        vibrance, // location 5
        sepia, // location 6
        invert, // location 7
        saturation, // location 8
        hue, // location 9
        // screenSize is handled automatically by ShaderApplication mixin at location 10
      ];
}
