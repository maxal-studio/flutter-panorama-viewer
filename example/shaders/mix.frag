#include <flutter/runtime_effect.glsl>
precision mediump float;

out vec4 fragColor;

uniform sampler2D inputImageTexture;

layout(location = 0) uniform lowp float inputBrightness;
layout(location = 1) uniform lowp float inputContrast;
layout(location = 2) uniform lowp float inputGamma;
layout(location = 3) uniform highp float inputExposure;
layout(location = 4) uniform float inputSharpen;
layout(location = 5) uniform float inputVibrance;
layout(location = 6) uniform float inputSepia;  
layout(location = 7) uniform float inputInvert;
layout(location = 8) uniform float inputSaturation;
layout(location = 9) uniform float inputHueAdjust;
layout(location = 10) uniform vec2 screenSize;

vec4 processColorBrightness(vec4 sourceColor){
    return vec4((sourceColor.rgb + vec3(inputBrightness * sourceColor.a)), sourceColor.a);
}
vec4 processColorContrast(vec4 sourceColor){
    return vec4(((sourceColor.rgb - vec3(0.5)) * inputContrast + vec3(0.5)), sourceColor.w);
}
vec4 processColorGamma(vec4 sourceColor){
     return vec4(pow(sourceColor.rgb, vec3(inputGamma)), sourceColor.w);
}
vec4 processColorExposure(vec4 sourceColor){
    return vec4(sourceColor.rgb * pow(2.0, inputExposure), sourceColor.w);
}

vec4 processColorSharpen(vec4 sourceColor, vec2 textureCoordinate) {
    if (inputSharpen <= 0.0) {
        return texture(inputImageTexture, textureCoordinate);
    }

    vec2 texelSize = 1.0 / screenSize;

    vec4 center = texture(inputImageTexture, textureCoordinate);
    vec4 north = texture(inputImageTexture, textureCoordinate + vec2(0.0, texelSize.y));
    vec4 south = texture(inputImageTexture, textureCoordinate - vec2(0.0, texelSize.y));
    vec4 east = texture(inputImageTexture, textureCoordinate + vec2(texelSize.x, 0.0));
    vec4 west = texture(inputImageTexture, textureCoordinate - vec2(texelSize.x, 0.0));

    // Scale the sharpening effect to match the web version
    float scaledSharpen = inputSharpen * 0.15;

    // Apply sharpening kernel
    vec3 sharpenedColor = center.rgb * (1.0 + 4.0 * scaledSharpen) 
                         - (north.rgb + south.rgb + east.rgb + west.rgb) * scaledSharpen;

    return vec4(clamp(sharpenedColor, 0.0, 1.0), center.a);
}

vec4 processColorVibrance(vec4 sourceColor) {
    float maxChannel = max(sourceColor.r, max(sourceColor.g, sourceColor.b));
    float avg = (sourceColor.r + sourceColor.g + sourceColor.b) / 3.0;
    float intensity = (maxChannel - avg) * 2.0;

    vec3 vibranceColor = mix(vec3(avg), sourceColor.rgb, 1.0 + inputVibrance * intensity);

    return vec4(clamp(vibranceColor, 0.0, 1.0), sourceColor.a);
}

vec4 processColorSepia(vec4 sourceColor) {
    vec3 sepiaColor = vec3(
        dot(sourceColor.rgb, vec3(0.393, 0.769, 0.189)),
        dot(sourceColor.rgb, vec3(0.349, 0.686, 0.168)),
        dot(sourceColor.rgb, vec3(0.272, 0.534, 0.131))
    );
    
    vec3 finalColor = mix(sourceColor.rgb, sepiaColor, inputSepia);
    return vec4(finalColor, sourceColor.a);
}

vec4 processColorInvert(vec4 sourceColor) {
    vec3 invertedColor = mix(sourceColor.rgb, 1.0 - sourceColor.rgb, inputInvert);
    return vec4(invertedColor, sourceColor.a);
}

// Values from \Graphics Shaders: Theory and Practice\ by Bailey and Cunningham
const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

vec4 processColorSaturation(vec4 sourceColor){
   lowp float luminance = dot(sourceColor.rgb, luminanceWeighting);
   lowp vec3 greyScaleColor = vec3(luminance);

   return vec4(mix(greyScaleColor, sourceColor.rgb, inputSaturation), sourceColor.w);
}

const highp vec4 kRGBToYPrime = vec4 (0.299, 0.587, 0.114, 0.0);
const highp vec4 kRGBToI = vec4 (0.595716, -0.274453, -0.321263, 0.0);
const highp vec4 kRGBToQ = vec4 (0.211456, -0.522591, 0.31135, 0.0);

const highp vec4 kYIQToR = vec4 (1.0, 0.9563, 0.6210, 0.0);
const highp vec4 kYIQToG = vec4 (1.0, -0.2721, -0.6474, 0.0);
const highp vec4 kYIQToB = vec4 (1.0, -1.1070, 1.7046, 0.0);

vec4 processColorHue(vec4 sourceColor, vec2 textureCoordinate){
    highp vec4 color = sourceColor;

    // Convert to YIQ
    highp float YPrime = dot(color, kRGBToYPrime);
    highp float I = dot(color, kRGBToI);
    highp float Q = dot(color, kRGBToQ);

    // Calculate the hue and chroma
    highp float hue = atan(Q, I);
    highp float chroma = sqrt(I * I + Q * Q);

    // Make the user's adjustments
    hue = hue -inputHueAdjust; //why negative rotation?

    // Convert back to YIQ
    Q = chroma * sin(hue);
    I = chroma * cos(hue);

    // Convert back to RGB
    highp vec4 yIQ = vec4 (YPrime, I, Q, 0.0);
    color.r = dot(yIQ, kYIQToR);
    color.g = dot(yIQ, kYIQToG);
    color.b = dot(yIQ, kYIQToB);

    return color;
}

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / screenSize;
    vec4 textureColor = texture(inputImageTexture, textureCoordinate);
    
    // Apply filters in the same order as tridiar_filters.js
    vec4 processedColorSharpen = processColorSharpen(textureColor, textureCoordinate);
    vec4 processedColorGamma = processColorGamma(processedColorSharpen);
    vec4 processedColorExposure = processColorExposure(processedColorGamma);
    vec4 processedColorBrightness = processColorBrightness(processedColorExposure);
    vec4 processedColorContrast = processColorContrast(processedColorBrightness);
    vec4 processedColorSaturation = processColorSaturation(processedColorContrast);
    vec4 processedColorHue = processColorHue(processedColorSaturation, textureCoordinate);
    vec4 processedColorVibrance = processColorVibrance(processedColorHue);
    vec4 processedColorSepia = processColorSepia(processedColorVibrance);
    vec4 processedColorInvert = processColorInvert(processedColorSepia);
    
    fragColor = processedColorInvert;
}