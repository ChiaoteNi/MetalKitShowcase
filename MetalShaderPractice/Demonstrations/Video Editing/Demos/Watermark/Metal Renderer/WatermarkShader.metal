//
//  PassthroughShader.metal
//  VideoCompositionDemo
//
//  Created by Chiaote Ni on 2022/11/28.
//

#include <metal_stdlib>
using namespace metal;

// More detail about the Metal Shading Language, you can see here:
// https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf

/*
 Vertex input/output structure for passing results
 from a vertex shader to a fragment shader.
 */
struct VertexInOut
{
    float4 position [[position]];
    float2 textureCoordinate [[user(textureCoordinates)]];
    float2 watermarkCoordinate [[user(textureCoordinates2)]];
};

// Vertex shader
vertex VertexInOut watermark_vertex_point_func(uint vid [[ vertex_id ]],
                                               constant float4* position [[ buffer(0) ]],
                                               constant float2* textureCoordinates [[ buffer(1) ]],
                                               constant float2* watermarkCoordinates [[ buffer(2) ]])
{
    VertexInOut outVertex;
    outVertex.position = position[vid];
    outVertex.textureCoordinate = textureCoordinates[vid];
    outVertex.watermarkCoordinate = watermarkCoordinates[vid];
    return outVertex;
};

// Fragment shader
fragment half4 watermark_fragment_point_func(VertexInOut fragmentInput [[ stage_in ]],
                                             texture2d<half> texture [[ texture(0) ]],
                                             texture2d<half> watermark [[ texture(1) ]],
                                             constant float& opacity [[ buffer(0) ]])
{
    constexpr sampler sampler;
    half4 color = texture.sample(sampler, fragmentInput.textureCoordinate);
    half4 watermarkColor = watermark.sample(sampler, fragmentInput.watermarkCoordinate);
    return watermarkColor * opacity + color * (1-opacity);
}
