# Image Filters and Shaders

The Panorama Viewer supports custom image filters and shaders that can be applied to your panoramic images in real-time using GLSL shaders and GPU image processing.

# Also check out the example_screen_7 for a complete example of how to use image filters.

## Basic Usage

To use image filters, you need to:

1. Create a shader controller
2. Create a shader configuration
3. Apply the shader to your PanoramaViewer

```dart
final ShaderController _shaderController = ShaderController();

_shaderController.addShader(MixShaderConfig(
  brightnessValue: 0.0,
  contrastValue: 0.0,
  gammaValue: 0.0,
  exposureValue: 0.0,
  sharpenValue: 0.0,
));

// In your widget
PanoramaViewer(
  shaderController: _shaderController,
  child: Image.asset('your_panorama.jpg'),
)
```

## Available Filters

In the example app, you can find the a `mix.frag` shader file that applies the following filters:  
You can use this as a starting point to create your own shaders.

- Brightness (Range: -1.0 to 1.0)
- Contrast (Range: 0.0 to 4.0)
- Gamma (Range: 0.0 to 4.0)
- Exposure (Range: -1.0 to 1.0)
- Sharpen (Range: 0.0 to 1.0)
- Vibrance (Range: -1.0 to 1.0)
- Sepia (Range: 0.0 to 1.0)
- Invert (Range: 0.0 to 1.0)
- Saturation (Range: 0.0 to 2.0)
- Hue (Range: -π to π)

## Creating a Shader Configuration

To create a shader configuration, extend the base shader configuration class.  
Here is an example of the `MixShaderConfig` class: 

```dart
class MixShaderConfig extends ShaderConfig {
  static const ShaderParameter brightnessParam = ShaderParameter(
    name: 'brightness',
    defaultValue: 0.0,
    min: -1.0,
    max: 1.0,
  );
  
  // Add other parameters...

  final double brightnessValue;
  
  MixShaderConfig({
    this.brightnessValue = 0.0,
    // Add other values...
  });

  @override
  Map<String, double> get parameters => {
    brightnessParam.name: brightnessValue,
    // Add other parameters...
  };
}
```

## Updating Shaders

You can update shader values in real-time:

```dart
void updateShader() {
  _shaderController.updateShader(MixShaderConfig(
    brightnessValue: _brightness,
    contrastValue: _contrast,
    gammaValue: _gamma,
    // Add other values...
  ));
}
```

## Initializing Shaders

Register your shader in your app's initialization:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  ShaderProgramManager.instance.registerProvider<MixShaderConfig>(
    () => FragmentProgram.fromAsset('shaders/mix.frag')
  );

  runApp(const MyApp());
}
```

## Creating Custom Shaders

To create a custom shader:

1. Create a .frag file in your shaders directory
2. Create a shader configuration class
3. Register the shader with ShaderProgramManager
4. Use the shader controller in your PanoramaViewer

Example shader file (mix.frag):
```glsl
#include <flutter/runtime_effect.glsl>
precision mediump float;

layout(location = 0) uniform lowp float inputBrightness;
layout(location = 1) uniform vec2 screenSize;

uniform lowp sampler2D inputImageTexture;

out vec4 fragColor;

vec4 processColor(vec4 sourceColor){
    return vec4((sourceColor.rgb + vec3(inputBrightness * sourceColor.a)), sourceColor.a);
}

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / screenSize;
    vec4 textureColor = texture(inputImageTexture, textureCoordinate);

    fragColor = processColor(textureColor);
}
```

Remember to declare your shader files in pubspec.yaml:
```yaml
flutter:
  assets:
    - assets/

  shaders:
    - shaders/mix.frag
``` 