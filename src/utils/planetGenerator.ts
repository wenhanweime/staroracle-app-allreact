import { PlanetRecord, PlanetVariant } from '@/types';

type PlanetPalette = {
  base: string;
  mid: string;
  highlight: string;
  shadow: string;
  ring?: string;
  glow?: string;
};

const VARIANT_PALETTES: Record<PlanetVariant, PlanetPalette[]> = {
  gas: [
    { base: '#5c1f5d', mid: '#a83c7b', highlight: '#f1c1ff', shadow: '#2a0c2b', ring: '#ffbed9', glow: '#a33dd6' },
    { base: '#114c7f', mid: '#1b8fbe', highlight: '#c0efff', shadow: '#08253c', ring: '#62d0ff', glow: '#2e7fbd' }
  ],
  ocean: [
    { base: '#0a2c4a', mid: '#126f7d', highlight: '#9df9ff', shadow: '#050f1b', glow: '#3ac3db' },
    { base: '#0c2633', mid: '#0d6ea2', highlight: '#e4f9ff', shadow: '#04101b', glow: '#5fadeb' }
  ],
  lava: [
    { base: '#391010', mid: '#c23325', highlight: '#ffd278', shadow: '#1a0300', glow: '#f05d2f' },
    { base: '#4b1a09', mid: '#d0491a', highlight: '#ffe1a8', shadow: '#180500', glow: '#ff944d' }
  ],
  ice: [
    { base: '#082747', mid: '#3c7f99', highlight: '#e3fbff', shadow: '#03101d', glow: '#75ddff' },
    { base: '#0d2336', mid: '#4d9ab7', highlight: '#f2ffff', shadow: '#000d1a', glow: '#64cef5' }
  ],
  desert: [
    { base: '#402b15', mid: '#b48232', highlight: '#ffe4b3', shadow: '#1b1309', ring: '#f2c57c', glow: '#e3a450' },
    { base: '#2f1f0f', mid: '#c17324', highlight: '#ffdca8', shadow: '#120902', ring: '#f2b56b', glow: '#f0a146' }
  ]
};

const mulberry32 = (seed: number) => {
  return () => {
    let t = (seed += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), 1 | t);
    t ^= t + Math.imul(t ^ (t >>> 7), 61 | t);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
};

const pickPalette = (variant: PlanetVariant, rng: () => number): PlanetPalette => {
  const palettes = VARIANT_PALETTES[variant] ?? VARIANT_PALETTES.gas;
  const index = Math.floor(rng() * palettes.length) % palettes.length;
  return palettes[index];
};

const drawBackground = (ctx: CanvasRenderingContext2D, width: number, height: number, palette: PlanetPalette, rng: () => number) => {
  const gradient = ctx.createLinearGradient(0, 0, width, height);
  gradient.addColorStop(0, palette.glow ?? '#080313');
  gradient.addColorStop(1, '#020109');
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, width, height);

  ctx.globalAlpha = 0.4;
  for (let i = 0; i < 120; i++) {
    const size = rng() * 1.8 + 0.4;
    ctx.fillStyle = `rgba(255,255,255,${0.3 + rng() * 0.6})`;
    ctx.beginPath();
    ctx.arc(rng() * width, rng() * height, size, 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.globalAlpha = 1;
};

const drawPlanetBody = (
  ctx: CanvasRenderingContext2D,
  radius: number,
  palette: PlanetPalette,
  variant: PlanetVariant,
  rng: () => number
) => {
  const gradient = ctx.createRadialGradient(-radius * 0.35, -radius * 0.35, radius * 0.25, 0, 0, radius);
  gradient.addColorStop(0, palette.highlight);
  gradient.addColorStop(0.4, palette.mid);
  gradient.addColorStop(1, palette.base);

  ctx.fillStyle = gradient;
  ctx.beginPath();
  ctx.arc(0, 0, radius, 0, Math.PI * 2);
  ctx.fill();

  ctx.strokeStyle = palette.shadow;
  ctx.lineWidth = radius * 0.08;
  ctx.beginPath();
  ctx.arc(0, 0, radius * 0.92, Math.PI * 0.35, Math.PI * 1.6);
  ctx.stroke();

  const bandCount = variant === 'gas' ? 7 : variant === 'lava' ? 4 : 5;
  for (let i = 0; i < bandCount; i++) {
    const bandY = -radius * 0.9 + (2 * radius * i) / bandCount;
    const bandHeight = radius * 0.05 + rng() * radius * 0.03;
    ctx.fillStyle = i % 2 === 0 ? palette.mid : palette.shadow;
    ctx.globalAlpha = variant === 'gas' ? 0.5 : 0.25;
    ctx.beginPath();
    ctx.ellipse(0, bandY * 0.4, radius * (0.7 + rng() * 0.2), bandHeight, 0, 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.globalAlpha = 1;

  if (variant === 'lava') {
    ctx.strokeStyle = palette.highlight;
    ctx.lineWidth = radius * 0.05;
    for (let i = 0; i < 5; i++) {
      ctx.beginPath();
      ctx.moveTo(-radius * 0.6, -radius * 0.2 + i * radius * 0.2);
      ctx.bezierCurveTo(
        -radius * 0.2,
        -radius * 0.4 + i * radius * 0.2,
        radius * 0.4,
        radius * 0.1 + i * radius * 0.2,
        radius * 0.6,
        radius * 0.3 + i * radius * 0.15
      );
      ctx.stroke();
    }
  }

  if (variant === 'ocean') {
    ctx.strokeStyle = `${palette.highlight}88`;
    ctx.lineWidth = radius * 0.03;
    for (let i = 0; i < 3; i++) {
      ctx.beginPath();
      ctx.arc(0, 0, radius * (0.4 + i * 0.15), rng() * Math.PI, rng() * Math.PI + Math.PI * 1.2);
      ctx.stroke();
    }
  }
};

const drawPlanetRing = (ctx: CanvasRenderingContext2D, radius: number, palette: PlanetPalette, rng: () => number) => {
  ctx.save();
  ctx.rotate(-0.35 + rng() * 0.2);
  ctx.strokeStyle = palette.ring ?? '#ffffff';
  ctx.lineWidth = radius * 0.12;
  ctx.globalAlpha = 0.85;
  ctx.beginPath();
  ctx.ellipse(0, 0, radius * 1.4, radius * 0.6, 0, 0, Math.PI * 2);
  ctx.stroke();
  ctx.globalAlpha = 0.45;
  ctx.lineWidth = radius * 0.2;
  ctx.strokeStyle = `${palette.ring ?? '#ffffff'}55`;
  ctx.beginPath();
  ctx.ellipse(0, 0, radius * 1.55, radius * 0.7, 0, 0, Math.PI * 2);
  ctx.stroke();
  ctx.restore();
  ctx.globalAlpha = 1;
};

const drawAtmosphere = (ctx: CanvasRenderingContext2D, radius: number, palette: PlanetPalette) => {
  const halo = ctx.createRadialGradient(0, 0, radius * 0.9, 0, 0, radius * 1.4);
  halo.addColorStop(0, `${palette.highlight}55`);
  halo.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = halo;
  ctx.beginPath();
  ctx.arc(0, 0, radius * 1.35, 0, Math.PI * 2);
  ctx.fill();
};

export const drawPlanetScene = (canvas: HTMLCanvasElement, planet: PlanetRecord) => {
  const ctx = canvas.getContext('2d');
  if (!ctx) return;

  const width = canvas.width;
  const height = canvas.height;
  ctx.clearRect(0, 0, width, height);

  const rng = mulberry32(planet.seed);
  const palette = pickPalette(planet.variant, rng);

  drawBackground(ctx, width, height, palette, rng);

  const radius = Math.min(width, height) * (0.28 + rng() * 0.06);

  ctx.save();
  ctx.translate(width / 2, height / 2);
  ctx.rotate(-0.15 + rng() * 0.3);
  drawPlanetBody(ctx, radius, palette, planet.variant, rng);

  if ((planet.variant === 'gas' || planet.variant === 'desert') && palette.ring) {
    drawPlanetRing(ctx, radius, palette, rng);
  }

  drawAtmosphere(ctx, radius, palette);
  ctx.restore();
};
