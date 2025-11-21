#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float time;
    float2 viewportSizePixels;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float pointSize [[point_size]];
    float type;
    float progress;
};

struct StarVertexIn {
    float2 position [[attribute(0)]];
    float size [[attribute(1)]];
    float type [[attribute(2)]];
    float4 color [[attribute(3)]];
    float progress [[attribute(4)]];
};

vertex VertexOut galaxy_vertex(StarVertexIn in [[stage_in]],
                               constant Uniforms& uniforms [[buffer(1)]]) {
    VertexOut out;
    float2 viewport = max(uniforms.viewportSizePixels, float2(1.0));
    float2 ndc = float2(
        (in.position.x / viewport.x) * 2.0 - 1.0,
        1.0 - (in.position.y / viewport.y) * 2.0
    );
    out.position = float4(ndc, 0.0, 1.0);
    float baseSize = max(in.size, 1.0);
    out.pointSize = (in.type > 0.5 ? baseSize : baseSize);
    out.color = in.color;
    out.type = in.type;
    out.progress = in.progress;
    return out;
}

fragment float4 galaxy_fragment(VertexOut in [[stage_in]],
                                float2 pointCoord [[point_coord]],
                                constant Uniforms& uniforms [[buffer(0)]]) {
    float2 centered = pointCoord - float2(0.5);
    float dist = length(centered);
    if (dist >= 0.5) {
        discard_fragment();
    }

    if (in.type < 0.5) {
        float alpha = smoothstep(0.5, 0.0, dist);
        return float4(in.color.rgb, in.color.a * alpha);
    }

    if (in.type < 1.5) {
        float falloff = smoothstep(0.5, 0.0, dist);
        float core = smoothstep(0.18, 0.0, dist);
        float alpha = saturate(falloff * in.color.a + core * 0.6);
        return float4(in.color.rgb, alpha);
    }

    float progress = clamp(in.progress, 0.0, 1.0);
    float normalizedDist = saturate(dist / 0.5);
    float halo = smoothstep(0.5, 0.0, normalizedDist);
    float core = smoothstep(0.18, 0.0, normalizedDist);
    float pulse = smoothstep(0.35 + progress * 0.2, 0.15, normalizedDist) * (1.0 - progress);
    float alpha = saturate(halo * 0.55 + core * 0.85 + pulse * 0.4) * (1.0 - progress * 0.2);
    float whiteBlend = core * 0.6;
    float3 blended = mix(in.color.rgb, float3(1.0), whiteBlend);
    return float4(blended, alpha);
}
