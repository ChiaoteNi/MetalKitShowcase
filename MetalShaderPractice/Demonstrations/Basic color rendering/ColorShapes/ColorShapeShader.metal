//
//  ColorShapeShader.metal
//  MetalShaderPractice
//
//  Created by Chiaote Ni on 2024/4/14.
//

#include <metal_stdlib>
using namespace metal;

struct Point {
    float4 position [[position]]; // xyzw
    float4 color; // rgba
};

vertex Point color_shape_vertex_point_func(constant Point *points [[ buffer(0) ]],
                                           uint vertex_id [[vertex_id]]) {
    Point out;
    out.position = points[vertex_id].position;
    out.color = points[vertex_id].color;
    return out;
}

fragment float4 color_shape_fragment_color_func(Point input [[stage_in]]) {
    // uncomment the following code to see the difference in the results
    //    input.color *= 0.5;
    return input.color;
}
