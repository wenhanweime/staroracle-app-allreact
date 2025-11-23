precision mediump float;

uniform float pixels;
uniform float rotation;
uniform vec2 light_origin;
uniform float time_speed;
uniform float dither_size;
uniform float light_border_1;
uniform float light_border_2;
uniform vec4 colors[3];
uniform float size;
uniform float OCTAVES;
uniform float seed;
uniform float time;
uniform float should_dither;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(1.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
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
    if (float(i) >= OCTAVES) break;
    value += noise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }
  return value;
}

float dither(vec2 uvPixel, vec2 uvReal) {
  float stepSize = 2.0 / pixels;
  return mod(uvPixel.x + uvReal.y, stepSize) <= (1.0 / pixels) ? 1.0 : 0.0;
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
  float dith = dither(uv, vUV);

  float dLight = distance(uv, light_origin);

  uv = rotate(uv, rotation);
  uv = spherify(uv);

  float combined = fbm(uv * size + vec2(time * time_speed, 0.0));
  dLight += combined * 0.3;

  float ditherBorder = (1.0 / pixels) * dither_size;

  vec4 col = colors[0];
  if (dLight > light_border_1) {
    col = colors[1];
    if (dLight < light_border_1 + ditherBorder && (dith > 0.5 || should_dither < 0.5)) {
      col = colors[0];
    }
  }
  if (dLight > light_border_2) {
    col = colors[2];
    if (dLight < light_border_2 + ditherBorder && (dith > 0.5 || should_dither < 0.5)) {
      col = colors[1];
    }
  }

  gl_FragColor = vec4(col.rgb, alpha * col.a);
}
