precision mediump float;

uniform float pixels;
uniform vec4 colors[3];
uniform float radius;
uniform float light_width;

varying vec2 vUV;

void main() {
  vec2 uv = floor(vUV * pixels) / pixels;
  float distCenter = distance(uv, vec2(0.5));

  vec4 col = colors[0];
  if (distCenter > radius - light_width) {
    col = colors[1];
  }
  if (distCenter > radius - light_width * 0.5) {
    col = colors[2];
  }

  float alpha = step(distCenter, radius);
  gl_FragColor = vec4(col.rgb, alpha * col.a);
}
