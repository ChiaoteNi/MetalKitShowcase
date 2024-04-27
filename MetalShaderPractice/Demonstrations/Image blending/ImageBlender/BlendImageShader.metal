//
//  BlendImageShader.metal
//  MetalShaderPractice
//
//  Created by Chiaote Ni on 2024/4/16.
//

// https://en.wikipedia.org/wiki/Blend_modes

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 textureCoordinate [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 textureCoordinate;
    float opacity;
};

vertex VertexOut screen_blend_vertex_func(constant VertexIn *vertexIn [[ buffer(0) ]],
                                          constant float &opacity [[ buffer(1) ]],
                                          uint vertexID [[vertex_id]]) {
    VertexOut vertexOut;
    vertexOut.position = float4(vertexIn[vertexID].position, 0.0, 1.0);
    vertexOut.textureCoordinate = vertexIn[vertexID].textureCoordinate;
    vertexOut.opacity = opacity;
    return vertexOut;
}

// Case 1: Simply perform blending using an alpha value
fragment float4 simple_blend_fragment_func(VertexOut fragmentIn [[stage_in]],
                                           texture2d<float, access::sample> sourceTexture [[ texture(0) ]],
                                           texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                           sampler textureSampler [[ sampler(0) ]]) {

    float4 sourceColor = sourceTexture.sample(textureSampler, fragmentIn.textureCoordinate);
    float4 overlayColor = overlayTexture.sample(textureSampler, fragmentIn.textureCoordinate);

    sourceColor.rgb *= (1 - fragmentIn.opacity);
    overlayColor.rgb *= fragmentIn.opacity;

    float4 resultColor;
    resultColor = sourceColor + overlayColor;
    return resultColor;
}

// Case 2: ScreenBlend
fragment float4 screen_blend_fragment_func(VertexOut fragmentIn [[stage_in]],
                                           texture2d<float, access::sample> sourceTexture [[ texture(0) ]],
                                           texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                                           sampler textureSampler [[ sampler(0) ]]) {

    float4 sourceColor = sourceTexture.sample(textureSampler, fragmentIn.textureCoordinate);
    float4 overlayColor = overlayTexture.sample(textureSampler, fragmentIn.textureCoordinate);

    overlayColor.rgb *= fragmentIn.opacity;

    float4 resultColor;
    resultColor.r = 1.0 - (1.0 - sourceColor.r) * (1.0 - overlayColor.r);
    resultColor.g = 1.0 - (1.0 - sourceColor.g) * (1.0 - overlayColor.g);
    resultColor.b = 1.0 - (1.0 - sourceColor.b) * (1.0 - overlayColor.b);
    resultColor.a = sourceColor.a;

    return resultColor;
}
