precision highp float;
precision highp int;

uniform float time;
uniform float time_speed;
uniform float spark_scale;
uniform float spark_sharpness;
uniform float flicker_strength;
uniform float star_radius;
uniform float branch_count;
uniform float rotation_speed;
uniform float halo_softness;
uniform vec4 colors[2];

varying vec2 vUV;

float hash(vec2 p) {
  p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
  return fract(sin(p.x + p.y) * 43758.5453123);
}

void main() {
  vec2 center = vec2(0.5);
  vec2 offset = vUV - center;
  float dist = length(offset);
  if (dist > 0.5) {
    discard;
  }

  float phase = fract(time * time_speed);
  float grow = smoothstep(0.0, 0.3, phase);
  float shrink = smoothstep(1.0, 0.7, phase);
  float envelope = min(grow, shrink);
  float radius = mix(0.02, star_radius, envelope);

  float halo = smoothstep(radius + halo_softness, radius, dist);

  float arms = clamp(branch_count, 2.0, 8.0);
  float rot = rotation_speed * phase * 6.28318;
  float angle = atan(offset.y, offset.x) + rot;
  float spikes = pow(max(0.0, cos(angle * arms)), spark_sharpness);
  float spikeFalloff = smoothstep(radius, radius + spark_scale, dist);
  float starburst = spikes * (1.0 - spikeFalloff);

  float swirl = sin((dist * 10.0 - angle * 3.0) + phase * 6.28318) * (1.0 - dist * 2.0);
  float swirlMask = smoothstep(-0.2, 0.4, swirl);

  float flicker = 0.5 + 0.5 * sin(time * time_speed * 3.5 + hash(floor(vUV * 12.0)) * 6.28318);

  float intensity = halo + starburst * (0.8 + flicker * flicker_strength) + swirlMask * 0.25;
  intensity = clamp(intensity, 0.0, 1.0);

  vec4 col = mix(colors[0], colors[1], intensity);
  vec3 highlight = mix(col.rgb, vec3(1.0), starburst * 0.5);
  gl_FragColor = vec4(highlight, col.a * intensity);
}
