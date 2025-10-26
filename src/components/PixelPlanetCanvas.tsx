import React, { useEffect, useRef } from 'react';

type LayerConfig = {
  pixels: number;
  cloudCover: number;
  lightOrigin: [number, number];
  timeSpeed: number;
  stretch: number;
  cloudCurve: number;
  lightBorder1: number;
  lightBorder2: number;
  rotation: number;
  colors: [number, number, number, number][];
  size: number;
  octaves: number;
  seed: number;
};

interface PixelPlanetCanvasProps {
  seed: number;
  size?: number;
}

const VERT_SHADER = `
attribute vec2 a_position;
void main() {
  gl_Position = vec4(a_position, 0.0, 1.0);
}
`;

const FRAG_SHADER = `
precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_pixels;
uniform float u_cloud_cover;
uniform vec2 u_light_origin;
uniform float u_time_speed;
uniform float u_stretch;
uniform float u_cloud_curve;
uniform float u_light_border1;
uniform float u_light_border2;
uniform float u_rotation;
uniform vec4 u_colors[4];
uniform float u_size;
uniform float u_octaves;
uniform float u_seed;

float rand(vec2 coord) {
  coord = mod(coord, vec2(1.0, 1.0) * floor(u_size + 0.5));
  return fract(sin(dot(coord.xy , vec2(12.9898, 78.233))) * 15.5453 * u_seed);
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

  for (int i = 0; i < 8; i++) {
    if (float(i) >= u_octaves) {
      break;
    }
    value += noise(coord) * scale;
    coord *= 2.0;
    scale *= 0.5;
  }

  return value;
}

float circleNoise(vec2 uv) {
  float uv_y = floor(uv.y);
  uv.x += uv_y * 0.31;
  vec2 f = fract(uv);
  float h = rand(vec2(floor(uv.x), floor(uv_y)));
  float m = length(f - 0.25 - (h * 0.5));
  float r = h * 0.25;
  return smoothstep(0.0, r, m * 0.75);
}

float cloud_alpha(vec2 uv) {
  float c_noise = 0.0;
  for (int i = 0; i < 9; i++) {
    c_noise += circleNoise((uv * u_size * 0.3) + float(i + 11) + vec2(u_time * u_time_speed, 0.0));
  }
  float turbulence = fbm(uv * u_size + c_noise + vec2(u_time * u_time_speed, 0.0));
  return turbulence;
}

vec2 rotate2D(vec2 coord, float angle) {
  coord -= 0.5;
  float c = cos(angle);
  float s = sin(angle);
  coord = mat2(c, -s, s, c) * coord;
  return coord + 0.5;
}

vec2 spherify(vec2 uv) {
  vec2 centered = uv * 2.0 - 1.0;
  float z = sqrt(max(0.0001, 1.0 - dot(centered.xy, centered.xy)));
  vec2 sphere = centered / (z + 1.0);
  return sphere * 0.5 + 0.5;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  vec2 pixelUv = floor(uv * u_pixels) / u_pixels;

  float d_light = distance(pixelUv, u_light_origin);
  float d_circle = distance(pixelUv, vec2(0.5));
  float alpha = step(d_circle, 0.49999);

  pixelUv = rotate2D(pixelUv, u_rotation);
  pixelUv = spherify(pixelUv);
  pixelUv.y += smoothstep(0.0, u_cloud_curve, abs(pixelUv.x - 0.4));

  float clouds = cloud_alpha(pixelUv * vec2(1.0, u_stretch));

  vec4 col = u_colors[0];
  if (clouds < u_cloud_cover + 0.03) {
    col = u_colors[1];
  }
  if (d_light + clouds * 0.2 > u_light_border1) {
    col = u_colors[2];
  }
  if (d_light + clouds * 0.2 > u_light_border2) {
    col = u_colors[3];
  }

  float finalAlpha = step(u_cloud_cover, clouds) * alpha * col.a;
  gl_FragColor = vec4(col.rgb, finalAlpha);

  if (finalAlpha <= 0.001) {
    discard;
  }
}
`;

const clamp = (value: number, min = 0, max = 1) => Math.min(max, Math.max(min, value));

const mulberry32 = (seed: number) => {
  let t = seed >>> 0;
  return () => {
    t += 0x6d2b79f5;
    t = Math.imul(t ^ (t >>> 15), 1 | t);
    t ^= t + Math.imul(t ^ (t >>> 7), 61 | t);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
};

const randRange = (rng: () => number, min: number, max: number) => min + rng() * (max - min);

type RGBA = [number, number, number, number];

const darken = (color: RGBA, amount: number): RGBA => {
  const factor = clamp(1 - amount, 0, 1);
  return [
    clamp(color[0] * factor),
    clamp(color[1] * factor),
    clamp(color[2] * factor),
    color[3]
  ];
};

const lighten = (color: RGBA, amount: number): RGBA => {
  const a = clamp(amount, 0, 1);
  return [
    clamp(color[0] + (1 - color[0]) * a),
    clamp(color[1] + (1 - color[1]) * a),
    clamp(color[2] + (1 - color[2]) * a),
    color[3]
  ];
};

const generateColorScheme = (rng: () => number, count: number, hueDiff: number, saturation: number): RGBA[] => {
  const a = [0.5, 0.5, 0.5];
  const b = [0.5 * saturation, 0.5 * saturation, 0.5 * saturation];
  const c = [
    randRange(rng, 0.5, 1.5) * hueDiff,
    randRange(rng, 0.5, 1.5) * hueDiff,
    randRange(rng, 0.5, 1.5) * hueDiff
  ];
  const dScalar = randRange(rng, 1.0, 3.0);
  const d = [
    randRange(rng, 0.0, 1.0) * dScalar,
    randRange(rng, 0.0, 1.0) * dScalar,
    randRange(rng, 0.0, 1.0) * dScalar
  ];

  const colors: RGBA[] = [];
  const denom = Math.max(1, count - 1);
  for (let i = 0; i < count; i++) {
    const t = i / denom;
    const r = clamp(a[0] + b[0] * Math.cos(6.28318 * (c[0] * t + d[0])));
    const g = clamp(a[1] + b[1] * Math.cos(6.28318 * (c[1] * t + d[1])));
    const bVal = clamp(a[2] + b[2] * Math.cos(6.28318 * (c[2] * t + d[2])));
    colors.push([r, g, bVal, 1]);
  }
  return colors;
};

const createGasPlanetLayers = (seed: number): LayerConfig[] => {
  const rng = mulberry32(seed || 1);
  const shaderSeed = ((seed % 1000) + 1000) % 1000;
  const convertedSeed = shaderSeed / 100;

  const totalColors = 8 + Math.floor(rng() * 4);
  const scheme = generateColorScheme(rng, totalColors, randRange(rng, 0.3, 0.8), 1.0);

  const layer1Colors: RGBA[] = [];
  const layer2Colors: RGBA[] = [];

  for (let i = 0; i < 4; i++) {
    let col = scheme[i] ?? scheme[i % scheme.length];
    col = darken(col, i / 6);
    col = darken(col, 0.7);
    layer1Colors.push(col);
  }

  for (let i = 0; i < 4; i++) {
    let col = scheme[i + 4] ?? scheme[(i + 4) % scheme.length];
    col = darken(col, i / 4);
    col = lighten(col, (1 - i / 4) * 0.5);
    layer2Colors.push(col);
  }

  const lightOrigin: [number, number] = [
    clamp(0.25 + (rng() - 0.5) * 0.15, 0.15, 0.35),
    clamp(0.25 + (rng() - 0.5) * 0.15, 0.15, 0.35)
  ];
  const baseRotation = (rng() - 0.5) * 0.4;

  const layer1: LayerConfig = {
    pixels: randRange(rng, 80, 110),
    cloudCover: 0.0,
    lightOrigin,
    timeSpeed: randRange(rng, 0.6, 0.8),
    stretch: randRange(rng, 0.9, 1.3),
    cloudCurve: randRange(rng, 1.15, 1.45),
    lightBorder1: randRange(rng, 0.52, 0.72),
    lightBorder2: randRange(rng, 0.62, 0.82),
    rotation: baseRotation,
    colors: layer1Colors,
    size: randRange(rng, 8.5, 10.5),
    octaves: 5,
    seed: convertedSeed || 1.23
  };

  const layer2: LayerConfig = {
    pixels: layer1.pixels,
    cloudCover: randRange(rng, 0.28, 0.5),
    lightOrigin,
    timeSpeed: randRange(rng, 0.4, 0.55),
    stretch: randRange(rng, 0.95, 1.35),
    cloudCurve: randRange(rng, 1.2, 1.5),
    lightBorder1: randRange(rng, 0.38, 0.52),
    lightBorder2: randRange(rng, 0.68, 0.82),
    rotation: baseRotation,
    colors: layer2Colors,
    size: randRange(rng, 8.5, 10.5),
    octaves: 5,
    seed: convertedSeed || 1.23
  };

  if (layer2.lightBorder2 <= layer2.lightBorder1) {
    layer2.lightBorder2 = layer2.lightBorder1 + 0.12;
  }
  if (layer1.lightBorder2 <= layer1.lightBorder1) {
    layer1.lightBorder2 = layer1.lightBorder1 + 0.1;
  }

  return [layer1, layer2];
};

const createShader = (gl: WebGLRenderingContext, type: number, source: string) => {
  const shader = gl.createShader(type);
  if (!shader) {
    throw new Error('无法创建 WebGL Shader');
  }
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    const info = gl.getShaderInfoLog(shader);
    gl.deleteShader(shader);
    throw new Error(info || 'WebGL Shader 编译失败');
  }
  return shader;
};

const createProgram = (gl: WebGLRenderingContext, vertexSrc: string, fragmentSrc: string) => {
  const vertexShader = createShader(gl, gl.VERTEX_SHADER, vertexSrc);
  const fragmentShader = createShader(gl, gl.FRAGMENT_SHADER, fragmentSrc);
  const program = gl.createProgram();
  if (!program) {
    throw new Error('无法创建 WebGL 程序');
  }
  gl.attachShader(program, vertexShader);
  gl.attachShader(program, fragmentShader);
  gl.linkProgram(program);
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
    const info = gl.getProgramInfoLog(program);
    gl.deleteProgram(program);
    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);
    throw new Error(info || 'WebGL 程序链接失败');
  }
  gl.detachShader(program, vertexShader);
  gl.detachShader(program, fragmentShader);
  gl.deleteShader(vertexShader);
  gl.deleteShader(fragmentShader);
  return program;
};

const PixelPlanetCanvas: React.FC<PixelPlanetCanvasProps> = ({ seed, size = 220 }) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const dpr = window.devicePixelRatio || 1;
    canvas.width = size * dpr;
    canvas.height = size * dpr;
    canvas.style.width = `${size}px`;
    canvas.style.height = `${size}px`;

    const gl = canvas.getContext('webgl', { premultipliedAlpha: false, alpha: true });
    if (!gl) {
      const ctx = canvas.getContext('2d');
      if (ctx) {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        const gradient = ctx.createRadialGradient(
          canvas.width * 0.45,
          canvas.height * 0.4,
          10,
          canvas.width * 0.5,
          canvas.height * 0.5,
          canvas.width * 0.5
        );
        gradient.addColorStop(0, '#f1c27d');
        gradient.addColorStop(0.6, '#b36b3c');
        gradient.addColorStop(1, '#3b1c1c');
        ctx.fillStyle = gradient;
        ctx.beginPath();
        ctx.arc(canvas.width * 0.5, canvas.height * 0.5, canvas.width * 0.45, 0, Math.PI * 2);
        ctx.fill();
      }
      return;
    }

    const program = createProgram(gl, VERT_SHADER, FRAG_SHADER);
    gl.useProgram(program);

    const buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(
      gl.ARRAY_BUFFER,
      new Float32Array([
        -1, -1,
        1, -1,
        -1, 1,
        -1, 1,
        1, -1,
        1, 1,
      ]),
      gl.STATIC_DRAW
    );

    const positionLocation = gl.getAttribLocation(program, 'a_position');
    gl.enableVertexAttribArray(positionLocation);
    gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);

    const resolutionLocation = gl.getUniformLocation(program, 'u_resolution');
    const timeLocation = gl.getUniformLocation(program, 'u_time');
    const pixelsLocation = gl.getUniformLocation(program, 'u_pixels');
    const cloudCoverLocation = gl.getUniformLocation(program, 'u_cloud_cover');
    const lightOriginLocation = gl.getUniformLocation(program, 'u_light_origin');
    const timeSpeedLocation = gl.getUniformLocation(program, 'u_time_speed');
    const stretchLocation = gl.getUniformLocation(program, 'u_stretch');
    const cloudCurveLocation = gl.getUniformLocation(program, 'u_cloud_curve');
    const lightBorder1Location = gl.getUniformLocation(program, 'u_light_border1');
    const lightBorder2Location = gl.getUniformLocation(program, 'u_light_border2');
    const rotationLocation = gl.getUniformLocation(program, 'u_rotation');
    const colorsLocation = gl.getUniformLocation(program, 'u_colors');
    const sizeLocation = gl.getUniformLocation(program, 'u_size');
    const octavesLocation = gl.getUniformLocation(program, 'u_octaves');
    const seedLocation = gl.getUniformLocation(program, 'u_seed');

    gl.uniform2f(resolutionLocation, canvas.width, canvas.height);

    const layers = createGasPlanetLayers(seed);
    const colorsBuffer = new Float32Array(16);

    gl.enable(gl.BLEND);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    let animationFrame = 0;
    const startTime = performance.now();

    const render = () => {
      animationFrame = requestAnimationFrame(render);
      const elapsed = (performance.now() - startTime) / 1000;

      if (timeLocation) {
        gl.uniform1f(timeLocation, elapsed);
      }

      gl.viewport(0, 0, canvas.width, canvas.height);
      gl.clearColor(0, 0, 0, 0);
      gl.clear(gl.COLOR_BUFFER_BIT);

      layers.forEach((layer) => {
        gl.uniform1f(pixelsLocation, layer.pixels);
        gl.uniform1f(cloudCoverLocation, layer.cloudCover);
        gl.uniform2f(lightOriginLocation, layer.lightOrigin[0], layer.lightOrigin[1]);
        gl.uniform1f(timeSpeedLocation, layer.timeSpeed);
        gl.uniform1f(stretchLocation, layer.stretch);
        gl.uniform1f(cloudCurveLocation, layer.cloudCurve);
        gl.uniform1f(lightBorder1Location, layer.lightBorder1);
        gl.uniform1f(lightBorder2Location, layer.lightBorder2);
        gl.uniform1f(rotationLocation, layer.rotation);
        gl.uniform1f(sizeLocation, layer.size);
        gl.uniform1f(octavesLocation, layer.octaves);
        gl.uniform1f(seedLocation, layer.seed);

        for (let i = 0; i < 4; i++) {
          const color = layer.colors[i] ?? [1, 1, 1, 1];
          colorsBuffer[i * 4 + 0] = color[0];
          colorsBuffer[i * 4 + 1] = color[1];
          colorsBuffer[i * 4 + 2] = color[2];
          colorsBuffer[i * 4 + 3] = color[3];
        }
        gl.uniform4fv(colorsLocation, colorsBuffer);

        gl.drawArrays(gl.TRIANGLES, 0, 6);
      });
    };

    render();

    return () => {
      cancelAnimationFrame(animationFrame);
      gl.deleteBuffer(buffer);
      gl.deleteProgram(program);
    };
  }, [seed, size]);

  return (
    <canvas
      ref={canvasRef}
      width={size}
      height={size}
      style={{ display: 'block', imageRendering: 'pixelated' as const }}
    />
  );
};

export default PixelPlanetCanvas;
