precision mediump float;

uniform float pixels;
uniform float rotation;
uniform vec2 light_origin;
uniform float time_speed;
uniform vec4 colors[3];
uniform float size;
uniform float octaves;
uniform float seed;
uniform float should_dither;

varying vec2 vUV;

float rand(vec2 coord) {
  return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

float noise(vec2 coord) {
  vec2 i = floor(coord);
  vec2 f = fract(coord);

  float a = rand(i);
  float b = rand(i + vec2(1.0, 0.0));
  float c = rand(i + vec2(0.0, 1.0));
  float d = rand(i + vec2(1.0, 1.0));

  vec2 cubic = f * f * (3.0 - 2.0 * f);

  return mix(a, b, cubic.x) +
    (c - a) * cubic.y * (1.0 - cubic.x) +
    (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
  float value = 0.0;
  float scale = 0.5;

  for (int i = 0; i < 12; i++) {
    if (float(i) >= octaves) break;
    value += noise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }
  return value;
}

float dither(vec2 uv1, vec2 uv2) {
  return mod(uv1.x + uv2.y, 2.0 / pixels) <= 1.0 / pixels ? 1.0 : 0.0;
}

vec2 rotate(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

float circleNoise(vec2 uv) {
  float uvY = floor(uv.y);
  uv.x += uvY * 0.31;
  vec2 f = fract(uv);
  float h = rand(vec2(floor(uv.x), floor(uvY)));
  float m = length(f - 0.25 - (h * 0.5));
  float r = h * 0.25;
  return smoothstep(r - 0.10 * r, r, m);
}

float crater(vec2 uv) {
  float c = 1.0;
  for (int i = 0; i < 2; i++) {
    c *= circleNoise((uv * size) + (float(i + 1) + 10.0));
  }
  return 1.0 - c;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;
  float dith = dither(uv, vUV);

  float d = distance(uv, vec2(0.5));
  uv = rotate(uv, rotation);

  float n = fbm(uv * size);
  float n2 = fbm(uv * size + (rotate(light_origin, rotation) - 0.5) * 0.5);

  float nStep = step(0.2, n - d);
  float n2Step = step(0.2, n2 - d);

  float noiseRel = (n2Step + n2) - (nStep + n);

  float c1 = crater(uv);
  float c2 = crater(uv + (light_origin - 0.5) * 0.03);

  vec4 col = colors[1];

  if (noiseRel < -0.06 || (noiseRel < -0.04 && (dith > 0.5 || should_dither < 0.5))) {
    col = colors[0];
  }
  if (noiseRel > 0.05 || (noiseRel > 0.03 && (dith > 0.5 || should_dither < 0.5))) {
    col = colors[2];
  }

  if (c1 > 0.4) {
    col = colors[1];
  }
  if (c2 < c1) {
    col = colors[2];
  }

  gl_FragColor = vec4(col.rgb, nStep * col.a);
}
