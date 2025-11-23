precision mediump float;

uniform float pixels;
uniform float rotation;
uniform vec2 light_origin;
uniform float time_speed;
uniform float light_border;
uniform vec4 colors[2];
uniform float size;
uniform float seed;
uniform float time;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(1.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

float circleNoise(vec2 uv) {
  float uvY = floor(uv.y);
  uv.x += uvY * 0.31;
  vec2 f = fract(uv);
  float h = rand(vec2(floor(uv.x), floor(uvY)));
  float m = length(f - 0.25 - (h * 0.5));
  float r = h * 0.25;
  return smoothstep(r - 0.10 * r, r, m * 0.75);
}

float crater(vec2 uv) {
  float c = 1.0;
  for (int i = 0; i < 2; i++) {
    c *= circleNoise((uv * size) + (float(i + 1) + 10.0) + vec2(time * time_speed, 0.0));
  }
  return 1.0 - c;
}

vec2 rotate(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

vec2 spherify(vec2 uv) {
  vec2 centered = uv * 2.0 - 1.0;
  float z = sqrt(max(0.0, 1.0 - dot(centered.xy, centered.xy)));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;

  float alpha = step(distance(uv, vec2(0.5)), 0.49999);
  float dLight = distance(uv, light_origin);

  uv = rotate(uv, rotation);
  uv = spherify(uv);

  float c1 = crater(uv);
  float c2 = crater(uv + (light_origin - 0.5) * 0.03);

  vec4 col = colors[0];
  alpha *= step(0.5, c1);

  if (c2 < c1 - (0.5 - dLight) * 2.0) {
    col = colors[1];
  }
  if (dLight > light_border) {
    col = colors[1];
  }

  gl_FragColor = vec4(col.rgb, alpha * col.a);
}
