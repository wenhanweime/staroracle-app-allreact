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
    float progress [[attribute(4)]];
    float ringIndex [[attribute(5)]];
};

vertex VertexOut galaxy_vertex(StarVertexIn in [[stage_in]],
                               constant Uniforms& uniforms [[buffer(1)]]) {
    VertexOut out;
    
    // GPU Animation Logic
    float2 center = uniforms.viewportSizePixels * 0.5;
    float2 pos = in.initialPosition;
    
    // Only rotate if it's a star (type 0 or 1), not background (type < 0 check if needed, but here background is type 0)
    // Actually background stars also rotate in original logic? 
    // Original logic: background stars are static relative to container, but container might move?
    // Wait, original logic: 
    // Rings: rotate based on ringIndex.
    // Background: static.
    
    // Let's assume type 0=background, type 1=normal star, type 2=highlight/pulse
    // But wait, existing code uses type < 0.5 for background/normal? 
    // Let's check GalaxyMetalView.swift buildVertices.
    // Background stars: type 0.0
    // Normal stars: type 0.0
    // Highlighted base: type 0.0
    // Lit layer: type 1.0
    // Pulses: type 1.0
    
    // We need a way to distinguish background from ring stars if they have different behavior.
    // In original ViewModel: 
    // Background stars are in `backgroundStars` array, rendered first.
    // Ring stars are in `rings` array, rendered next.
    // We can use ringIndex. If ringIndex < 0, it's background (static).
    
    float2 finalPos = pos;
    
    if (in.ringIndex >= 0.0) {
        // It's a ring star, apply rotation
        // baseDegPerMs = 0.0005 -> 0.5 deg/sec -> 0.00872 rad/sec
        // angle = baseDegPerMs * elapsed * 1000 * (pi/180)
        //       = 0.0005 * 1000 * (pi/180) * elapsed
        //       = 0.5 * 0.017453 * elapsed
        //       = 0.008726 * elapsed
        
        // But wait, rotation depends on ringIndex?
        // ViewModel: let rotation = ringRotationCache[index]
        // ringRotationCache is same for all rings?
        // updateRotationCache:
        // let angle = baseDegPerMs * elapsed * 1000.0 * (.pi / 180.0)
        // let cacheEntry = RotationCache(sin: sin(angle), cos: cos(angle))
        // ringRotationCache = Array(repeating: cacheEntry, count: ringCount)
        //
        // Wait, ALL rings rotate at the SAME speed in the original code?
        // Yes: `ringRotationCache = Array(repeating: cacheEntry, count: ringCount)`
        // So it's a rigid body rotation for the whole galaxy rings?
        // Yes.
        
        float angle = 0.0087266 * uniforms.time; 
        float s = sin(angle);
        float c = cos(angle);
        
        // Rotate around (0,0) - initialPosition is relative to center?
        // In ViewModel:
        // let bandCenter = CGPoint(x: star.bandSize.width / 2.0, y: star.bandSize.height / 2.0)
        // let dx = Double(star.position.x - bandCenter.x)
        // let dy = Double(star.position.y - bandCenter.y)
        // let rx = dx * cos - dy * sin ...
        //
        // So initialPosition passed to GPU should be (dx, dy).
        
        float rx = pos.x * c - pos.y * s;
        float ry = pos.x * s + pos.y * c;
        
        // Apply scale and offset to screen center
        finalPos = center + float2(rx, ry) * uniforms.scale;
    } else {
        // Background star or pulse
        // Background stars in ViewModel:
        // let position = SIMD2<Float>(Float(star.position.x - offsetX) * scaleFloat ...)
        // They seem to scale but not rotate?
        // Actually background stars in ViewModel are just appended to vertices.
        // In `buildVertices`:
        // let offsetX = (viewModel.bandSize.width - size.width) * 0.5
        // star.position.x - offsetX
        // This handles the "centering" or "crop" logic.
        
        // For GPU migration, we should pass the "centered" coordinate for background too, 
        // or handle the offset in shader.
        // Simpler: Pass pre-calculated (centered but unscaled) position for background.
        // And apply scale here.
        
        // If ringIndex < -1.0, it's a pulse (already world space? no, pulses also scale)
        
        finalPos = center + pos * uniforms.scale;
    }

    float2 viewport = max(uniforms.viewportSizePixels, float2(1.0));
    float2 ndc = float2(
        (finalPos.x / viewport.x) * 2.0 - 1.0,
        1.0 - (finalPos.y / viewport.y) * 2.0
    );
    
    out.position = float4(ndc, 0.0, 1.0);
    float baseSize = max(in.size * uniforms.scale, 1.0);
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
