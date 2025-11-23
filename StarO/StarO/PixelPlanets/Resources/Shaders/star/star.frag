precision mediump float;

uniform float pixels;
uniform float time_speed;
uniform float time;
uniform float rotation;
uniform vec4 colors[4];
uniform float n_colors;
uniform float should_dither;
uniform float seed;
uniform float size;
uniform float OCTAVES;
uniform float TILES;

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

vec2 hash2(vec2 p) {
  float r = 523.0 * sin(dot(p, vec2(53.3158, 43.6143)));
  return vec2(fract(15.32354 * r), fract(17.25865 * r));
}

float cells(vec2 p, float numCells) {
  p *= numCells;
  float d = 1.0e10;
  for (int xo = -1; xo <= 1; xo++) {
    for (int yo = -1; yo <= 1; yo++) {
      vec2 tp = floor(p) + vec2(float(xo), float(yo));
      tp = p - tp - hash2(mod(tp, numCells / TILES));
      d = min(d, dot(tp, tp));
    }
  }
  return sqrt(d);
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
  float alpha = step(distance(pixelized, vec2(0.5)), 0.49999);
  float dith = dither(vUV, pixelized);

  pixelized = rotateVec(pixelized, rotation);
  pixelized = spherify(pixelized);

  float n = cells(pixelized - vec2(time * time_speed * 2.0, 0.0), 10.0);
  n *= cells(pixelized - vec2(time * time_speed, 0.0), 20.0);

  n *= 2.0;
  n = clamp(n, 0.0, 1.0);
  if (dith > 0.5 || should_dither < 0.5) {
    n *= 1.3;
  }

  float interpolate = floor(n * (n_colors - 1.0)) / (n_colors - 1.0);
  int index = int(interpolate * (n_colors - 1.0));
  vec4 col = colors[0];
  if (index <= 0) {
    col = colors[0];
  } else if (index == 1) {
    col = colors[1];
  } else if (index == 2) {
    col = colors[2];
  } else {
    col = colors[3];
  }

  gl_FragColor = vec4(col.rgb, alpha * col.a);
}
