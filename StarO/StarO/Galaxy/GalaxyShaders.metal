#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float time;
    float2 viewportSizePixels;
    float scale;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float pointSize [[point_size]];
    float type;
    float progress;
};

struct StarVertexIn {
    float2 initialPosition [[attribute(0)]];
    float size [[attribute(1)]];
    float type [[attribute(2)]];
    float4 color [[attribute(3)]];
    float highlightStartTime [[attribute(4)]]; // Replaces 'progress'
    float ringIndex [[attribute(5)]];
    float highlightDuration [[attribute(6)]];
};

vertex VertexOut galaxy_vertex(StarVertexIn in [[stage_in]],
                               constant Uniforms& uniforms [[buffer(1)]]) {
    VertexOut out;
    
    float2 center = uniforms.viewportSizePixels * 0.5;
    float2 pos = in.initialPosition;
    float2 finalPos = pos;
    
    // Rotation Logic
    if (in.type < 1.5) { // Type 0 (Normal) and 1 (Lit) rotate
        if (in.ringIndex >= 0.0) {
            float angle = 0.0087266 * uniforms.time; 
            float s = sin(angle);
            float c = cos(angle);
            float rx = pos.x * c - pos.y * s;
            float ry = pos.x * s + pos.y * c;
            finalPos = center + float2(rx, ry) * uniforms.scale;
        } else {
            finalPos = center + pos * uniforms.scale;
        }
    } else { // Type 2 (Pulse) does not rotate
        finalPos = center + pos * uniforms.scale;
    }

    float2 viewport = max(uniforms.viewportSizePixels, float2(1.0));
    float2 ndc = float2(
        (finalPos.x / viewport.x) * 2.0 - 1.0,
        1.0 - (finalPos.y / viewport.y) * 2.0
    );
    
    out.position = float4(ndc, 0.0, 1.0);
    
    // Animation Logic
    float baseSize = max(in.size * uniforms.scale, 1.0);
    float4 baseColor = in.color;
    
    if (in.type > 0.5 && in.type < 1.5) { // Type 1: Lit Star
        float elapsed = uniforms.time - in.highlightStartTime;
        float p = clamp(elapsed / in.highlightDuration, 0.0, 1.0);
        float intensity = sin(p * 3.14159); // PI
        
        float animScale = 1.0 + intensity * 0.8;
        out.pointSize = baseSize * animScale;
        
        // Alpha animation: 0.06 + 0.90 * intensity
        // We assume baseColor passed in has alpha=1 or whatever, we override it?
        // Swift passed: litColor with alpha calculated.
        // Now we pass litColor with alpha=1 (or base), and modulate here.
        float alpha = 0.06 + 0.90 * intensity;
        out.color = float4(baseColor.rgb, alpha);
        out.progress = p;
    } else if (in.type > 1.5) { // Type 2: Pulse
        float elapsed = uniforms.time - in.highlightStartTime;
        float p = clamp(elapsed / in.highlightDuration, 0.0, 1.0);
        
        float animScale = 1.15 + p * 1.7;
        out.pointSize = baseSize * animScale;
        
        float alpha = max(0.0, 1.0 - p) * 0.9;
        out.color = float4(baseColor.rgb, alpha);
        out.progress = p;
    } else {
        out.pointSize = baseSize;
        out.color = baseColor;
        out.progress = 0.0;
    }
    
    out.type = in.type;
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
