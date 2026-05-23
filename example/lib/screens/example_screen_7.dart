import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:panorama_viewer/shaders/shader_controller.dart';
import '../shaders/mix_config.dart';

class ExampleScreen7 extends StatefulWidget {
  const ExampleScreen7({super.key});

  @override
  State<ExampleScreen7> createState() => _ExampleScreen7State();
}

class _ExampleScreen7State extends State<ExampleScreen7> {
  final ShaderController _shaderController = ShaderController();
  late double _brightness;
  late double _contrast;
  late double _gamma;
  late double _exposure;
  late double _sharpen;
  late double _vibrance;
  late double _sepia;
  late double _invert;
  late double _saturation;
  late double _hue;
  String? _errorMessage;
  bool _showFilters = true; // Add state for filters visibility

  // Add image list and current image index
  final List<String> _images = [
    'assets/panorama1.webp',
    'assets/panorama2.webp',
  ];
  int _currentImage = 0;

  @override
  void initState() {
    super.initState();
    _resetAllValues();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initShaders();
    });
  }

  void _resetAllValues() {
    _brightness = MixShaderConfig.brightnessParam.defaultValue;
    _contrast = MixShaderConfig.contrastParam.defaultValue;
    _gamma = MixShaderConfig.gammaParam.defaultValue;
    _exposure = MixShaderConfig.exposureParam.defaultValue;
    _sharpen = MixShaderConfig.sharpenParam.defaultValue;
    _vibrance = MixShaderConfig.vibranceParam.defaultValue;
    _sepia = MixShaderConfig.sepiaParam.defaultValue;
    _invert = MixShaderConfig.invertParam.defaultValue;
    _saturation = MixShaderConfig.saturationParam.defaultValue;
    _hue = MixShaderConfig.hueParam.defaultValue;
  }

  void _initShaders() async {
    try {
      await _shaderController.setShader(MixShaderConfig());
      setState(() => _errorMessage = null);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to initialize shaders: $e');
    }
  }

  void _resetAllShaders() {
    setState(() {
      _resetAllValues();
      _updateShader();
    });
  }

  void _updateShader() {
    _shaderController.updateShader(MixShaderConfig(
      brightnessValue: _brightness,
      contrastValue: _contrast,
      gammaValue: _gamma,
      exposureValue: _exposure,
      sharpenValue: _sharpen,
      vibranceValue: _vibrance,
      sepiaValue: _sepia,
      invertValue: _invert,
      saturationValue: _saturation,
      hueValue: _hue,
    ));
  }

  void _updateValue(String param, double value) {
    setState(() {
      switch (param) {
        case 'brightness':
          _brightness = value;
          break;
        case 'contrast':
          _contrast = value;
          break;
        case 'gamma':
          _gamma = value;
          break;
        case 'exposure':
          _exposure = value;
          break;
        case 'sharpen':
          _sharpen = value;
          break;
        case 'vibrance':
          _vibrance = value;
          break;
        case 'sepia':
          _sepia = value;
          break;
        case 'invert':
          _invert = value;
          break;
        case 'saturation':
          _saturation = value;
          break;
        case 'hue':
          _hue = value;
          break;
      }
      _updateShader();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _showFilters
          ? AppBar(
              title: const Text('Mix Shader Example'),
              actions: [
                TextButton.icon(
                  onPressed: _resetAllShaders,
                  icon: const Icon(Icons.restart_alt, color: Colors.white),
                  label: const Text('Reset All',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          if (_errorMessage != null && _showFilters)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            flex: _showFilters
                ? 1
                : 999, // Take full space when filters are hidden
            child: Stack(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height:
                      _showFilters ? 500 : MediaQuery.of(context).size.height,
                  child: ClipRRect(
                    child: PanoramaViewer(
                      shaderController: _shaderController,
                      child: Image.asset(_images[_currentImage]),
                    ),
                  ),
                ),
                // Toogle filtres button
                Positioned(
                  top: 60,
                  right: 10,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                    ),
                    onPressed: () =>
                        setState(() => _showFilters = !_showFilters),
                    icon: Icon(_showFilters
                        ? Icons.fullscreen
                        : Icons.fullscreen_exit),
                  ),
                ),
                // Navigation buttons
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _currentImage = (_currentImage - 1) % _images.length;
                        if (_currentImage < 0) {
                          _currentImage = _images.length - 1;
                        }
                      });
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _currentImage = (_currentImage + 1) % _images.length;
                      });
                    },
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showFilters)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSliderWithReset(
                        'Sharpen',
                        MixShaderConfig.sharpenParam.min!,
                        MixShaderConfig.sharpenParam.max!,
                        _sharpen,
                        (value) => _updateValue('sharpen', value),
                        () => _updateValue('sharpen',
                            MixShaderConfig.sharpenParam.defaultValue),
                      ),
                      _buildSliderWithReset(
                        'Brightness',
                        MixShaderConfig.brightnessParam.min!,
                        MixShaderConfig.brightnessParam.max!,
                        _brightness,
                        (value) => _updateValue('brightness', value),
                        () => _updateValue('brightness',
                            MixShaderConfig.brightnessParam.defaultValue),
                      ),
                      _buildSliderWithReset(
                        'Contrast',
                        MixShaderConfig.contrastParam.min!,
                        MixShaderConfig.contrastParam.max!,
                        _contrast,
                        (value) => _updateValue('contrast', value),
                        () => _updateValue('contrast',
                            MixShaderConfig.contrastParam.defaultValue),
                      ),
                      _buildSliderWithReset(
                        'Gamma',
                        MixShaderConfig.gammaParam.min!,
                        MixShaderConfig.gammaParam.max!,
                        _gamma,
                        (value) => _updateValue('gamma', value),
                        () => _updateValue(
                            'gamma', MixShaderConfig.gammaParam.defaultValue),
                      ),
                      _buildSliderWithReset(
                        'Exposure',
                        MixShaderConfig.exposureParam.min!,
                        MixShaderConfig.exposureParam.max!,
                        _exposure,
                        (value) => _updateValue('exposure', value),
                        () => _updateValue('exposure',
                            MixShaderConfig.exposureParam.defaultValue),
                      ),
                      _buildSliderWithReset(
                        'Vibrance',
                        MixShaderConfig.vibranceParam.min!,
                        MixShaderConfig.vibranceParam.max!,
                        _vibrance,
                        (value) => _updateValue('vibrance', value),
                        () => _updateValue('vibrance',
                            MixShaderConfig.vibranceParam.defaultValue),
                      ),
                      _buildSliderWithReset(
                        'Sepia',
                        MixShaderConfig.sepiaParam.min!,
                        MixShaderConfig.sepiaParam.max!,
                        _sepia,
                        (value) => _updateValue('sepia', value),
                        () => _updateValue(
                            'sepia', MixShaderConfig.sepiaParam.defaultValue),
                      ),
                      _buildSliderWithReset(
                        'Invert',
                        MixShaderConfig.invertParam.min!,
                        MixShaderConfig.invertParam.max!,
                        _invert,
                        (value) => _updateValue('invert', value),
                        () => _updateValue(
                            'invert', MixShaderConfig.invertParam.defaultValue),
                      ),
                      _buildSliderWithReset(
                        'Saturation',
                        MixShaderConfig.saturationParam.min!,
                        MixShaderConfig.saturationParam.max!,
                        _saturation,
                        (value) => _updateValue('saturation', value),
                        () => _updateValue('saturation',
                            MixShaderConfig.saturationParam.defaultValue),
                      ),
                      _buildSliderWithReset(
                        'Hue',
                        MixShaderConfig.hueParam.min!,
                        MixShaderConfig.hueParam.max!,
                        _hue,
                        (value) => _updateValue('hue', value),
                        () => _updateValue(
                            'hue', MixShaderConfig.hueParam.defaultValue),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliderWithReset(
    String label,
    double min,
    double max,
    double value,
    void Function(double) onChanged,
    void Function() onReset,
  ) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label)),
        Expanded(
          child: Slider(
            min: min,
            max: max,
            value: value,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 50, child: Text(value.toStringAsFixed(2))),
        IconButton(
          icon: const Icon(Icons.restart_alt, size: 20),
          onPressed: onReset,
          tooltip: 'Reset $label',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _shaderController.dispose();
    super.dispose();
  }
}
