precision mediump float;

uniform float pixels;
uniform float rotation;
uniform vec2 light_origin;
uniform float time_speed;
uniform float light_border_1;
uniform float light_border_2;
uniform float ring_width;
uniform float ring_perspective;
uniform float scale_rel_to_planet;
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

vec2 rotateVec(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord *= mat2(vec2(c, -s), vec2(s, c));
  return coord + 0.5;
}

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;

  float lightD = distance(uv, light_origin);
  uv = rotateVec(uv, rotation);

  vec2 uvCenter = uv - vec2(0.0, 0.5);
  uvCenter *= vec2(1.0, ring_perspective);
  float centerDist = distance(uvCenter, vec2(0.5, 0.0));

  float ring = smoothstep(0.5 - ring_width * 2.0, 0.5 - ring_width, centerDist);
  ring *= smoothstep(centerDist - ring_width, centerDist, 0.4);

  if (uv.y < 0.5) {
    ring *= step(1.0 / scale_rel_to_planet, distance(uv, vec2(0.5)));
  }

  uvCenter = rotateVec(uvCenter + vec2(0.0, 0.5), time * time_speed);
  ring *= fbm(uvCenter * size);

  float posterized = floor((ring + pow(lightD, 2.0) * 2.0) * 4.0) / 4.0;
  posterized = min(posterized, 2.0);

  vec4 col;
  if (posterized <= 1.0) {
    float t = posterized * (n_colors - 1.0);
    int idx = int(clamp(t, 0.0, n_colors - 1.0));
    if (idx <= 0) {
      col = colors[0];
    } else if (idx == 1) {
      col = colors[1];
    } else {
      col = colors[2];
    }
  } else {
    float t = (posterized - 1.0) * (n_colors - 1.0);
    int idx = int(clamp(t, 0.0, n_colors - 1.0));
    if (idx <= 0) {
      col = dark_colors[0];
    } else if (idx == 1) {
      col = dark_colors[1];
    } else {
      col = dark_colors[2];
    }
  }

  float ringAlpha = step(0.28, ring);
  gl_FragColor = vec4(col.rgb, ringAlpha * col.a);
}
