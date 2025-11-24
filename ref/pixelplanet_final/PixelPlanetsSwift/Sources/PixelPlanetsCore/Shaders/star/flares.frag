precision mediump float;

uniform float pixels;
uniform vec4 colors[2];
uniform float time_speed;
uniform float time;
uniform float rotation;
uniform float should_dither;
uniform float storm_width;
uniform float storm_dither_width;
uniform float scale;
uniform float seed;
uniform float circle_amount;
uniform float circle_scale;
uniform float size;
uniform float OCTAVES;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(1.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

vec2 rotateVec(vec2 vec, float angle) {
  vec -= vec2(0.5);
  float c = cos(angle);
  float s = sin(angle);
  vec *= mat2(vec2(c, -s), vec2(s, c));
  vec += vec2(0.5);
  return vec;
}

float circle(vec2 uv) {
  float invert = 1.0 / circle_amount;
  if (mod(uv.y, invert * 2.0) < invert) {
    uv.x += invert * 0.5;
  }
  vec2 randCo = floor(uv * circle_amount) / circle_amount;
  uv = mod(uv, invert) * circle_amount;

  float r = rand(randCo);
  r = clamp(r, invert, 1.0 - invert);
  float dist = distance(uv, vec2(r));
  return smoothstep(dist, dist + 0.5, invert * circle_scale * rand(randCo * 1.5));
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
  float scl = 0.5;
  for (int i = 0; i < 12; i++) {
    if (float(i) >= OCTAVES) break;
    value += noise(coord) * scl;
    coord *= 2.0;
    scl *= 0.5;
  }
  return value;
}

float dither(vec2 uv1, vec2 uv2) {
  return mod(uv1.x + uv2.y, 2.0 / pixels) <= 1.0 / pixels ? 1.0 : 0.0;
}

vec2 spherify(vec2 uv) {
  vec2 centered = uv * 2.0 - 1.0;
  float z = sqrt(max(0.0, 1.0 - dot(centered.xy, centered.xy)));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

void main() {
  vec2 pixelized = floor(vUV * pixels) / pixels;
  float dith = dither(vUV, pixelized);

  pixelized = rotateVec(pixelized, rotation);
  vec2 uv = pixelized;

  float angle = atan(uv.x - 0.5, uv.y - 0.5) * 0.4;
  float d = distance(pixelized, vec2(0.5));

  vec2 circleUV = vec2(d, angle);

  float n = fbm(circleUV * size - time * time_speed);
  float nc = circle(circleUV * scale - time * time_speed + n);

  nc *= 1.5;
  float n2 = fbm(circleUV * size - time + vec2(100.0, 100.0));
  nc -= n2 * 0.1;

  float alpha = 0.0;
  if (1.0 - d > nc) {
    if (nc > storm_width - storm_dither_width + d && (dith > 0.5 || should_dither < 0.5)) {
      alpha = 1.0;
    } else if (nc > storm_width + d) {
      alpha = 1.0;
    }
  }

  float interpolate = floor(n2 + nc);
  int idx = int(clamp(interpolate, 0.0, 1.0));
  vec4 col = idx <= 0 ? colors[0] : colors[1];

  alpha *= step(n2 * 0.25, d);
  gl_FragColor = vec4(col.rgb, alpha * col.a);
}
