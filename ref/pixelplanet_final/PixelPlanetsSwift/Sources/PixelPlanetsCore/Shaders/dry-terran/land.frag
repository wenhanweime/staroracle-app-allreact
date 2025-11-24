precision highp float;
precision highp int;

uniform float pixels;
uniform float rotation;
uniform vec2 light_origin;
uniform float light_distance1;
uniform float light_distance2;
uniform float time_speed;
uniform float dither_size;
uniform vec4 colors[5];
uniform float n_colors;
uniform float size;
uniform float OCTAVES;
uniform float seed;
uniform float time;
uniform float should_dither;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(2.0, 1.0) * floor(size + 0.5));
  return fract(sin(dot(wrapped.xy, vec2(12.9898, 78.233))) * 43758.5453 * seed);
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

vec2 spherify(vec2 uv) {
  vec2 centered = uv * 2.0 - 1.0;
  float z = sqrt(max(0.0, 1.0 - dot(centered.xy, centered.xy)));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;
  float dith = dither(uv, vUV);

  float dCircle = distance(uv, vec2(0.5));
  float alpha = step(dCircle, 0.49999);

  uv = spherify(uv);
  float dLight = distance(uv, light_origin);

  uv = rotate(uv, rotation);

  float f = fbm(uv * size + vec2(time * time_speed, 0.0));

  dLight = smoothstep(-0.3, 1.2, dLight);

  if (dLight < light_distance1) {
    dLight *= 0.9;
  }
  if (dLight < light_distance2) {
    dLight *= 0.9;
  }

  float c = dLight * pow(f, 0.8) * 3.5;

  if (dith > 0.5 || should_dither < 0.5) {
    c += 0.02;
    c *= 1.05;
  }

  float posterize = floor(c * 4.0) / 4.0;
  posterize = min(posterize, 1.0);
  int index = int(posterize * (n_colors - 1.0));
  vec4 col = colors[0];
  if (index <= 0) {
    col = colors[0];
  } else if (index == 1) {
    col = colors[1];
  } else if (index == 2) {
    col = colors[2];
  } else if (index == 3) {
    col = colors[3];
  } else {
    col = colors[4];
  }

  gl_FragColor = vec4(col.rgb, alpha * col.a);
}
