#include <metal_stdlib>
using namespace metal;

struct FoldParameters {
    float progress;
    float opacity;
    float blurInset;
    float blurSpan;
    float taper;
    float crop;
    float depth;
    float velocity;
    float ripple;
    float time;
    float mode;
};

struct FoldVertex {
    float4 position [[position]];
    float2 uv;
};

vertex FoldVertex foldVertex(uint id [[vertex_id]], constant FoldParameters &p [[buffer(0)]]) {
    constexpr float2 coordinates[] = { float2(0, 1), float2(1, 1), float2(0, 0), float2(1, 0) };
    float2 uv = coordinates[id];
    FoldVertex out;
    out.position = float4(uv.x * 2.0 - 1.0, 1.0 - 2.0 * uv.y, 0.0, 1.0);
    out.uv = uv;
    return out;
}

fragment float4 foldFragment(FoldVertex in [[stage_in]],
    texture2d<float> source [[texture(0)]],
    texture2d<float> soft [[texture(1)]],
    texture2d<float> medium [[texture(2)]],
    texture2d<float> broad [[texture(3)]],
    texture2d<float> sides [[texture(4)]],
    constant FoldParameters &p [[buffer(0)]]) {
    constexpr sampler sampleMode(coord::normalized, address::clamp_to_edge, filter::linear);
    if (p.mode >= 0.5) {
        float2 uv = in.uv;
        float entrance = smoothstep(0.0, 0.045, p.progress);
        float edgeProgress = smoothstep(0.0, 0.45, p.progress);
        float depth = mix(0.035, 0.42, edgeProgress);
        float lensWidth = 0.044 + p.ripple * 0.030;
        float distanceToFront = abs(uv.y - depth);
        float front = 1.0 - smoothstep(0.0, lensWidth, distanceToFront);
        float body = 1.0 - smoothstep(depth - 0.025, depth + 0.025, uv.y);

        float wavePhase = p.time * (8.0 + abs(p.velocity) * 4.0);
        float settledWave = sin(uv.x * 20.0 + p.progress * 5.0);
        float movingWave = sin(uv.x * 34.0 + wavePhase) * p.ripple;
        float edgeSafety = smoothstep(0.0, 0.025, min(uv.x, 1.0 - uv.x));
        float influence = max(front, body * 0.32) * entrance * edgeSafety;
        float2 normal = float2(
            settledWave * 0.32 + movingWave * 0.70 + (uv.x - 0.5) * 0.16,
            -0.18 + cos(uv.x * 17.0 - wavePhase) * p.ripple * 0.30);
        float2 offset = normal * influence * (0.0045 + p.ripple * 0.0065);
        float2 glassUV = clamp(uv + offset, float2(0.0), float2(1.0));
        float2 dispersion = normal * influence * (0.0007 + p.ripple * 0.0008);

        float3 color;
        color.r = source.sample(
            sampleMode, clamp(glassUV + dispersion, float2(0.0), float2(1.0))).r;
        color.g = source.sample(sampleMode, glassUV).g;
        color.b = source.sample(
            sampleMode, clamp(glassUV - dispersion, float2(0.0), float2(1.0))).b;

        float2 blurUV = float2(p.blurInset + uv.x * p.blurSpan, uv.y);
        float3 blurred = soft.sample(sampleMode, blurUV).rgb;
        color = mix(color, blurred, influence * (0.10 + p.progress * 0.16));

        float caustic = 0.5 + 0.5 * sin(uv.x * 25.0 + settledWave * 1.4);
        float highlight = front * (0.16 + caustic * 0.13 + p.ripple * 0.12);
        float3 glassTint = float3(0.76, 0.91, 1.0);
        color += glassTint * highlight * entrance;

        float bodyAlpha = body * (0.28 + edgeProgress * 0.32);
        float alpha = p.opacity * entrance * max(bodyAlpha, front * 0.94);
        return float4(color * alpha, alpha);
    }

    float turn = p.progress * 1.5707964;
    float taper = p.taper * p.progress;
    float q = (1.0 + taper) / (1.0 + taper * in.uv.y);
    float2 fold = float2((in.uv.x - 0.5) * q + 0.5, in.uv.y * q);
    float2 uv = float2(fold.x, 1.0 - mix(1.0, cos(turn * 0.65), p.crop) * (1.0 - fold.y));
    float edge = min(uv.x, 1.0 - uv.x);
    float2 blurUV = float2(p.blurInset + uv.x * p.blurSpan, uv.y);
    float feather = smoothstep(0.0, max(0.0001, p.progress * 0.012 * (1.0 - fold.y)), edge);
    float3 sharp = mix(sides.sample(sampleMode, blurUV).rgb, source.sample(sampleMode, uv).rgb, feather);
    float falloff = p.progress * (1.0 - smoothstep(0.0, 0.9, fold.y));
    float amount = 36.0 * mix(falloff, sin(turn) * (1.0 - in.uv.y), p.depth);
    float3 color;
    if (amount < 6.0) {
        color = mix(sharp, soft.sample(sampleMode, blurUV).rgb, amount / 6.0);
    } else if (amount < 16.0) {
        color = mix(soft.sample(sampleMode, blurUV).rgb, medium.sample(sampleMode, blurUV).rgb, (amount - 6.0) / 10.0);
    } else {
        color = mix(medium.sample(sampleMode, blurUV).rgb, broad.sample(sampleMode, blurUV).rgb, (amount - 16.0) / 20.0);
    }
    float upper = 1.0 - smoothstep(0.0, 0.85, fold.y);
    float corners = (1.0 - smoothstep(0.0, 0.19, edge)) * upper;
    color *= 1.0 - p.progress * (0.50 * corners + 0.10 * upper);
    return float4(color * p.opacity, p.opacity);
}
