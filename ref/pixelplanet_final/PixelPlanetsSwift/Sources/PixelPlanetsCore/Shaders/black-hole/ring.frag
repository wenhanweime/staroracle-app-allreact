precision mediump float;

uniform float pixels;
uniform float rotation;
uniform vec2 light_origin;
uniform float time_speed;
uniform float disk_width;
uniform float ring_perspective;
uniform float should_dither;
uniform vec4 colors[5];
uniform float n_colors;
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

float dither(vec2 uvPixel, vec2 uvReal) {
  return mod(uvPixel.x + uvReal.y, 2.0 / pixels) <= 1.0 / pixels ? 1.0 : 0.0;
}

vec2 rotateVec(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;
  float dith = dither(uv, vUV);

  uv = rotateVec(uv, rotation);
  vec2 uvOriginal = uv;

  uv.x = (uv.x - 0.5) * 1.3 + 0.5;
  uv = rotateVec(uv, sin(time * time_speed * 2.0) * 0.01);

  vec2 lOrigin = vec2(0.5);
  float width = disk_width;

  if (uv.y < 0.5) {
    float dist = distance(vec2(0.5), uv);
    uv.y += smoothstep(dist, 0.5, 0.2);
    width += smoothstep(dist, 0.5, 0.3);
    lOrigin.y -= smoothstep(dist, 0.5, 0.2);
  } else if (uv.y > 0.53) {
    float dist = distance(vec2(0.5), uv);
    uv.y -= smoothstep(dist, 0.4, 0.17);
    width += smoothstep(dist, 0.5, 0.2);
    lOrigin.y += smoothstep(dist, 0.5, 0.2);
  }

  float lightD = distance(uvOriginal * vec2(1.0, ring_perspective), lOrigin * vec2(1.0, ring_perspective)) * 0.3;

  vec2 uvCenter = uv - vec2(0.0, 0.5);
  uvCenter *= vec2(1.0, ring_perspective);
  float centerDist = distance(uvCenter, vec2(0.5, 0.0));

  float disk = smoothstep(0.1 - width * 2.0, 0.5 - width, centerDist);
  disk *= smoothstep(centerDist - width, centerDist, 0.4);

  uvCenter = rotateVec(uvCenter + vec2(0.0, 0.5), time * time_speed * 3.0);
  disk *= pow(fbm(uvCenter * size), 0.5);

  if (dith > 0.5 || should_dither < 0.5) {
    disk *= 1.2;
  }

  float posterized = floor((disk + lightD) * (n_colors - 1.0));
  posterized = min(posterized, n_colors - 1.0);
  int idx = int(posterized);
  vec4 col = colors[0];
  if (idx <= 0) {
    col = colors[0];
  } else if (idx == 1) {
    col = colors[1];
  } else if (idx == 2) {
    col = colors[2];
  } else if (idx == 3) {
    col = colors[3];
  } else {
    col = colors[4];
  }

  float diskAlpha = step(0.15, disk);
  gl_FragColor = vec4(col.rgb, diskAlpha * col.a);
}
