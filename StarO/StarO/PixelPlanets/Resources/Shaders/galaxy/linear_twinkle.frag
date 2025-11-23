precision highp float;
precision highp int;

uniform float pixels;
uniform float time;
uniform float time_speed;
uniform float morph_speed;
uniform float branch_count;
uniform float branch_sharpness;
uniform float halo_softness;
uniform float spark_scale;
uniform float rotation_speed;
uniform float flicker_strength;
uniform vec4 colors[7];
uniform float n_colors;

varying vec2 vUV;

float hash(vec2 coord) {
  return fract(sin(dot(coord, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec4 fetchColor(float index) {
  int idx = int(clamp(index, 0.0, n_colors - 1.0));
  vec4 col = colors[0];
  if (idx == 1) col = colors[1];
  else if (idx == 2) col = colors[2];
  else if (idx == 3) col = colors[3];
  else if (idx == 4) col = colors[4];
  else if (idx == 5) col = colors[5];
  else if (idx >= 6) col = colors[6];
  return col;
}

void main() {
  vec2 center = vec2(0.5);
  vec2 offset = vUV - center;
  float dist = length(offset);
  if (dist > 0.5) discard;

  float phase = fract(time * morph_speed);
  float grow = smoothstep(0.0, 0.3, phase);
  float shrink = smoothstep(1.0, 0.7, phase);
  float envelope = min(grow, shrink);

  float coreRadius = mix(0.02, spark_scale * 0.15, envelope);
  float halo = smoothstep(coreRadius + halo_softness, coreRadius, dist);

  float arms = clamp(branch_count, 2.0, 10.0);
  float angle = atan(offset.y, offset.x) + rotation_speed * phase * 6.28318;
  float ray = pow(max(0.0, cos(angle * arms)), branch_sharpness);
  ray *= smoothstep(0.5, coreRadius * 0.6, dist);

  float flicker = 0.5 + 0.5 * sin(time * time_speed * 2.5 + hash(floor(vUV * pixels * 2.0)) * 6.28318);
  float intensity = clamp(halo + ray * (0.6 + flicker * flicker_strength), 0.0, 1.0);

  vec4 col = fetchColor(intensity * (n_colors - 1.0));
  gl_FragColor = vec4(col.rgb, col.a * intensity);
}
