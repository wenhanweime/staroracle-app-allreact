precision mediump float;

uniform float pixels;
uniform float rotation;
uniform float cloud_cover;
uniform vec2 light_origin;
uniform float time_speed;
uniform float stretch;
uniform float cloud_curve;
uniform float light_border_1;
uniform float light_border_2;
uniform float bands;
uniform float should_dither;
uniform float n_colors;
uniform vec4 colors[3];
uniform vec4 dark_colors[3];
uniform float size;
uniform float OCTAVES;
uniform float seed;
uniform float time;

varying vec2 vUV;

float rand(vec2 coord) {
  vec2 wrapped = mod(coord, vec2(2.0, 1.0) * floor(size + 0.5));
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

float circleNoise(vec2 uv) {
  float uvY = floor(uv.y);
  uv.x += uvY * 0.31;
  vec2 f = fract(uv);
  float h = rand(vec2(floor(uv.x), floor(uvY)));
  float m = length(f - 0.25 - (h * 0.5));
  float r = h * 0.25;
  return smoothstep(0.0, r, m * 0.75);
}

float turbulence(vec2 uv) {
  float cNoise = 0.0;
  for (int i = 0; i < 10; i++) {
    cNoise += circleNoise((uv * size * 0.3) + (float(i + 1) + 10.0) + vec2(time * time_speed, 0.0));
  }
  return cNoise;
}

float dither(vec2 uvPixel, vec2 uvReal) {
  return mod(uvPixel.x + uvReal.y, 2.0 / pixels) <= 1.0 / pixels ? 1.0 : 0.0;
}

vec2 spherify(vec2 uv) {
  vec2 centered = uv * 2.0 - 1.0;
  float z = sqrt(max(0.0, 1.0 - dot(centered.xy, centered.xy)));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

vec2 rotate(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;
  float lightD = distance(uv, light_origin);
  float dith = dither(uv, vUV);
  float alphaCircle = step(length(uv - vec2(0.5)), 0.49999);

  uv = rotate(uv, rotation);
  uv = spherify(uv);

  float band = fbm(vec2(0.0, uv.y * size * bands));
  float turb = turbulence(uv);

  float fbm1 = fbm(uv * size);
  float fbm2 = fbm(uv * vec2(1.0, 2.0) * size + fbm1 + vec2(-time * time_speed, 0.0) + turb);

  fbm2 *= pow(band, 2.0) * 7.0;
  float lightVal = fbm2 + lightD * 1.8;
  fbm2 += pow(lightD, 1.0) - 0.3;
  fbm2 = smoothstep(-0.2, 4.0 - fbm2, lightVal);

  if (dith > 0.5 && should_dither > 0.5) {
    fbm2 *= 1.1;
  }

  float posterized = floor(fbm2 * 4.0) / 2.0;
  float threshold = 0.625;
  int idx;
  vec4 col;

  if (fbm2 < threshold) {
    float t = posterized * (n_colors - 1.0);
    idx = int(clamp(t, 0.0, n_colors - 1.0));
    if (idx <= 0) {
      col = colors[0];
    } else if (idx == 1) {
      col = colors[1];
    } else {
      col = colors[2];
    }
  } else {
    float t = (posterized - 1.0) * (n_colors - 1.0);
    idx = int(clamp(t, 0.0, n_colors - 1.0));
    if (idx <= 0) {
      col = dark_colors[0];
    } else if (idx == 1) {
      col = dark_colors[1];
    } else {
      col = dark_colors[2];
    }
  }

  gl_FragColor = vec4(col.rgb, alphaCircle * col.a);
}
