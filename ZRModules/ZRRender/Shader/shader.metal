//
//  screenShader.metal
//  ZRModules
//
//  Created by Zhou,Rui(ART) on 2020/5/7.
//  Copyright © 2020 Zhou,Rui(ART). All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "ShaderType.h"

typedef struct {
    float4 position [[position]];
    float2 textureCoordinate;
} VertexOut;

vertex VertexOut
vertexShader(uint vertexID [[vertex_id]],
                 constant Vertex *vertices [[buffer(0)]]) {
    VertexOut out;
    out.position = vector_float4(0, 0, 0, 1);
    out.position.xy = vertices[vertexID].position.xy;
    out.textureCoordinate = vertices[vertexID].coordinate;
    return out;
}

fragment float4
fragmentShader(VertexOut in [[stage_in]],
                   constant int *texture_type [[buffer(0)]],
                   texture2d<half> texture [[textuer(0)]],
                   texture2d<half> texture2 [[texturen(1)]]){
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    if (*texture_type == 0) {
        const half4 colorPixel = texture.sample(textureSampler, in.textureCoordinate);
        return float4(colorPixel.r, colorPixel.g, colorPixel.b, 1);
    } else {
        const half4 y_plane = texture.sample(textureSampler, in.textureCoordinate);
        const half4 uv_plane = texture2.sample(textureSampler, in.textureCoordinate);
        
        float3 yuv;
        yuv.x = y_plane.x;
        yuv.yz = float2(uv_plane.xy - half2(0.5));
        
        float3x3 matrix = {
            {1.164, 1.164, 1.164},
            {0, -0.231, 2.112},
            {1.793, -0.533, 0}
        };
        float3 rgb = matrix * yuv;
        return float4(rgb, 1.0);
    }
}
