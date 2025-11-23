precision mediump float;

uniform float pixels;
uniform float rotation;
uniform float time_speed;
uniform float dither_size;
uniform float should_dither;
uniform vec4 colors[7];
uniform float n_colors;
uniform float size;
uniform float OCTAVES;
uniform float seed;
uniform float time;
uniform float tilt;
uniform float n_layers;
uniform float layer_height;
uniform float zoom;
uniform float swirl;

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
    if (float(i) >= OCTAVES) break;
    value += noise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }
  return value;
}

vec2 rotateVec(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

float dither(vec2 uv1, vec2 uv2) {
  return mod(uv1.x + uv2.y, 2.0 / pixels) <= 1.0 / pixels ? 1.0 : 0.0;
}

void main() {
  vec2 pixelUV = floor(vUV * pixels) / pixels;
  float dith = dither(pixelUV, vUV);

  vec2 uv = pixelUV * zoom;
  uv -= (zoom - 1.0) / 2.0;

  uv = rotateVec(uv, rotation);
  vec2 uvCopy = uv;

  uv.y *= tilt;
  uv.y -= (tilt - 1.0) / 2.0;

  float distCenter = distance(uv, vec2(0.5));
  float rot = swirl * pow(distCenter, 0.4);
  vec2 rotated = rotateVec(uv, rot + time * time_speed);

  float f1 = fbm(rotated * size);
  f1 = floor(f1 * n_layers) / n_layers;

  uvCopy.y *= tilt;
  uvCopy.y -= (tilt - 1.0) / 2.0 + f1 * layer_height;

  float distCenter2 = distance(uvCopy, vec2(0.5));
  float rot2 = swirl * pow(distCenter2, 0.4);
  vec2 rotated2 = rotateVec(uvCopy, rot2 + time * time_speed);
  float f2 = fbm(rotated2 * size + vec2(f1) * 10.0);

  float alpha = step(f2 + distCenter2, 0.7);

  f2 *= 2.3;
  if (should_dither > 0.5 && dith > 0.5) {
    f2 *= 0.94;
  }

  float index = floor(f2 * n_colors);
  index = min(index, n_colors);
  int idx = int(index);
  vec4 col = colors[0];
  if (idx <= 0) {
    col = colors[0];
  } else if (idx == 1) {
    col = colors[1];
  } else if (idx == 2) {
    col = colors[2];
  } else if (idx == 3) {
    col = colors[3];
  } else if (idx == 4) {
    col = colors[4];
  } else if (idx == 5) {
    col = colors[5];
  } else {
    col = colors[6];
  }

  gl_FragColor = vec4(col.rgb, alpha * col.a);
}
