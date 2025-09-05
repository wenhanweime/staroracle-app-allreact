import React, { useEffect, useRef } from 'react';

type Quality = 'low' | 'mid' | 'high' | 'auto';

interface InteractiveGalaxyBackgroundProps {
  quality?: Quality;
  reducedMotion?: boolean;
  className?: string;
  onCanvasClick?: (payload: { x: number; y: number; region: 'emotion' | 'relation' | 'growth' }) => void;
}

// Lightweight pseudo-noise (deterministic) to avoid extra dependencies
const fract = (n: number) => n - Math.floor(n);
const noise2D = (x: number, y: number) => {
  const t = Math.sin(x * 12.9898 + y * 78.233) * 43758.5453123;
  return fract(t) * 2 - 1; // [-1, 1]
};

// Best visual defaults aligned to 3-arm design
const defaultParams = {
  coreDensity: 0.75,
  coreRadius: 28,
  coreSizeMin: 1.2,
  coreSizeMax: 3.8,
  armCount: 3,
  armDensity: 0.8,
  armBaseSizeMin: 0.8,
  armBaseSizeMax: 2.2,
  armHighlightSize: 5.5,
  armHighlightProb: 0.02,
  spiralA: 8,
  spiralB: 0.26,
  armWidthInner: 24,
  armWidthOuter: 72,
  armWidthGrowth: 2.2,
  armTransitionSoftness: 5.0,
  fadeStartRadius: 0.52,
  fadeEndRadius: 1.25,
  outerDensityMaintain: 0.08,
  interArmDensity: 0.08,
  interArmSizeMin: 0.5,
  interArmSizeMax: 1.2,
  radialDecay: 0.0014,
  backgroundDensity: 0.00018,
  backgroundSizeVariation: 2.2,
  jitterStrength: 8,
  densityNoiseScale: 0.014,
  densityNoiseStrength: 0.7,
  armStarSizeMultiplier: 1.2,
  interArmStarSizeMultiplier: 1.0,
  backgroundStarSizeMultiplier: 1.0,
};

const getArmWidth = (radius: number, maxRadius: number, p = defaultParams) => {
  const progress = Math.min(radius / (maxRadius * 0.8), 1);
  return p.armWidthInner + (p.armWidthOuter - p.armWidthInner) * Math.pow(progress, p.armWidthGrowth);
};

const getFadeFactor = (radius: number, maxRadius: number, p = defaultParams) => {
  const fadeStart = maxRadius * p.fadeStartRadius;
  const fadeEnd = maxRadius * p.fadeEndRadius;
  if (radius < fadeStart) return 1;
  if (radius > fadeEnd) return 0;
  const progress = (radius - fadeStart) / (fadeEnd - fadeStart);
  return 0.5 * (1 + Math.cos(progress * Math.PI));
};

const getRadialDecayFn = (p = defaultParams) => (radius: number, maxRadius: number) => {
  const baseFactor = Math.exp(-radius * p.radialDecay);
  const fadeFactor = getFadeFactor(radius, maxRadius, p);
  const maintainFactor = p.outerDensityMaintain;
  return Math.max(baseFactor * fadeFactor, maintainFactor * fadeFactor);
};

const getArmPositions = (radius: number, centerX: number, centerY: number, p = defaultParams) => {
  const positions: Array<{ x: number; y: number; theta: number; armIndex: number }> = [];
  const angle = Math.log(Math.max(radius, p.spiralA) / p.spiralA) / p.spiralB;
  for (let arm = 0; arm < p.armCount; arm++) {
    const armOffset = (arm * 2 * Math.PI) / p.armCount;
    const theta = armOffset + angle;
    positions.push({ x: centerX + radius * Math.cos(theta), y: centerY + radius * Math.sin(theta), theta, armIndex: arm });
  }
  return positions;
};

const getArmInfo = (x: number, y: number, centerX: number, centerY: number, maxRadius: number, p = defaultParams) => {
  const dx = x - centerX;
  const dy = y - centerY;
  const radius = Math.sqrt(dx * dx + dy * dy);
  if (radius < 3) return { distance: 0, armIndex: 0, radius, inArm: true, armWidth: 0, theta: 0 };
  const armPositions = getArmPositions(radius, centerX, centerY, p);
  let minDistance = Infinity;
  let nearestArmIndex = 0;
  let nearestArmTheta = 0;
  armPositions.forEach((pos, index) => {
    const distance = Math.sqrt((x - pos.x) ** 2 + (y - pos.y) ** 2);
    if (distance < minDistance) {
      minDistance = distance;
      nearestArmIndex = index;
      nearestArmTheta = pos.theta;
    }
  });
  const armWidth = getArmWidth(radius, maxRadius, p);
  const inArm = minDistance < armWidth;
  return { distance: minDistance, armIndex: nearestArmIndex, radius, inArm, armWidth, theta: nearestArmTheta };
};

const calculateArmDensityProfile = (armInfo: ReturnType<typeof getArmInfo>, p = defaultParams) => {
  const { distance, armWidth } = armInfo;
  const profile = Math.exp(-0.5 * Math.pow(distance / (armWidth / p.armTransitionSoftness), 2));
  const totalDensity = p.interArmDensity + p.armDensity * profile;
  let size: number;
  if (profile > 0.1) {
    size = p.armBaseSizeMin + (p.armBaseSizeMax - p.armBaseSizeMin) * profile;
    if (profile > 0.7 && Math.random() < p.armHighlightProb) size = p.armHighlightSize;
    size *= p.armStarSizeMultiplier;
  } else {
    size = p.interArmSizeMin + (p.interArmSizeMax - p.interArmSizeMin) * Math.random();
    size *= p.interArmStarSizeMultiplier;
  }
  return { density: totalDensity, size, profile };
};

const InteractiveGalaxyBackground: React.FC<InteractiveGalaxyBackgroundProps> = ({
  quality = 'auto',
  reducedMotion = false,
  className,
  onCanvasClick,
}) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const currentQualityRef = useRef<Exclude<Quality, 'auto'>>('mid');
  const fpsSamplesRef = useRef<number[]>([]);
  const lastFpsSampleTimeRef = useRef<number>(performance.now());
  const lastFrameTimeRef = useRef<number>(performance.now());
  const lastQualityChangeRef = useRef<number>(0);
  const hoverRegionRef = useRef<'emotion' | 'relation' | 'growth' | null>(null);
  const nearLayerRef = useRef<HTMLCanvasElement | null>(null);
  const farLayerRef = useRef<HTMLCanvasElement | null>(null);
  const burstsRef = useRef<Array<{x:number;y:number;start:number;life:number}>>([]);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const DPR = Math.min(window.devicePixelRatio || 1, 2);

    const resize = () => {
      const w = window.innerWidth;
      const h = window.innerHeight;
      canvas.width = Math.floor(w * DPR);
      canvas.height = Math.floor(h * DPR);
      canvas.style.width = `${w}px`;
      canvas.style.height = `${h}px`;
      draw();
    };

    const getQualityScale = () => {
      const q = quality === 'auto' ? currentQualityRef.current : (quality as Exclude<Quality, 'auto'>);
      return q === 'high' ? 1 : q === 'mid' ? 0.8 : 0.6;
    };
    const getStep = () => {
      const q = quality === 'auto' ? currentQualityRef.current : (quality as Exclude<Quality, 'auto'>);
      return q === 'high' ? 1.0 : q === 'mid' ? 1.1 : 1.4;
    };
    // Color helpers for region hues
    const regionHue = (deg: number) => {
      // emotion: 330°, relation: 210°, growth: 240°/260° mix
      if (deg < 120) return 330; // emotion
      if (deg < 240) return 210; // relation
      return 250; // growth
    };
    const hslToRgba = (h: number, s: number, l: number, a: number) => {
      // h in [0,360], s/l in [0,1]
      const c = (1 - Math.abs(2 * l - 1)) * s;
      const hp = h / 60;
      const x = c * (1 - Math.abs((hp % 2) - 1));
      let [r1, g1, b1] = [0, 0, 0];
      if (hp >= 0 && hp < 1) [r1, g1, b1] = [c, x, 0];
      else if (hp < 2) [r1, g1, b1] = [x, c, 0];
      else if (hp < 3) [r1, g1, b1] = [0, c, x];
      else if (hp < 4) [r1, g1, b1] = [0, x, c];
      else if (hp < 5) [r1, g1, b1] = [x, 0, c];
      else [r1, g1, b1] = [c, 0, x];
      const m = l - c / 2;
      const r = Math.round((r1 + m) * 255);
      const g = Math.round((g1 + m) * 255);
      const b = Math.round((b1 + m) * 255);
      return `rgba(${r},${g},${b},${a})`;
    };

    // Generate pre-rendered layers
    const generateLayers = () => {
      const p = defaultParams;
      const width = canvas.width;
      const height = canvas.height;
      const centerX = width / 2;
      const centerY = height / 2;
      const maxRadius = Math.min(width, height) * 0.4;
      const radialDecay = getRadialDecayFn(p);

      // init offscreen layers
      const near = document.createElement('canvas');
      const far = document.createElement('canvas');
      near.width = width; near.height = height;
      far.width = width; far.height = height;
      const nctx = near.getContext('2d')!;
      const fctx = far.getContext('2d')!;

      const qualityScale = getQualityScale();
      const step = getStep();

      // background small stars to far layer
      const bgCount = Math.floor((width / DPR) * (height / DPR) * p.backgroundDensity * (reducedMotion ? 0.6 : 1) * qualityScale);
      fctx.save(); fctx.scale(DPR, DPR); fctx.fillStyle = 'rgba(255,255,255,0.7)';
      for (let i = 0; i < bgCount; i++) {
        const x = Math.random() * (width / DPR);
        const y = Math.random() * (height / DPR);
        let size = Math.random() < 0.85 ? 0.8 : (Math.random() < 0.9 ? 1.2 : p.backgroundSizeVariation);
        size *= p.backgroundStarSizeMultiplier;
        fctx.beginPath();
        fctx.arc(x, y, size, 0, Math.PI * 2);
        fctx.fill();
      }
      fctx.restore();

      // galaxy field: raster grid to allocate points into near/far
      nctx.save(); nctx.scale(DPR, DPR);
      fctx.save(); fctx.scale(DPR, DPR);
      for (let x = 0; x < width / DPR; x += step) {
        for (let y = 0; y < height / DPR; y += step) {
          const dx = x - centerX / DPR;
          const dy = y - centerY / DPR;
          const radius = Math.sqrt(dx * dx + dy * dy);
          if (radius < 3) continue;

          const decay = radialDecay(radius, maxRadius / DPR);
          const armInfo = getArmInfo(x * DPR, y * DPR, centerX, centerY, maxRadius, p);
          const result = calculateArmDensityProfile(armInfo, p);

          let density: number;
          let size: number;
          if (radius < p.coreRadius) {
            const coreProfile = Math.exp(-Math.pow(radius / p.coreRadius, 1.5));
            density = p.coreDensity * coreProfile * decay;
            size = (p.coreSizeMin + Math.random() * (p.coreSizeMax - p.coreSizeMin)) * p.armStarSizeMultiplier;
          } else {
            const n = noise2D(x * p.densityNoiseScale, y * p.densityNoiseScale);
            const modulation = 1.0 - p.densityNoiseStrength * (0.5 * (1.0 - n));
            density = result.density * decay * modulation;
            size = result.size;
          }
          density *= 0.8 + Math.random() * 0.4;
          if (Math.random() < density) {
            let ox = x; let oy = y;
            if (!reducedMotion && result.profile > 0.001) {
              const pitchAngle = Math.atan(1 / p.spiralB);
              const jitterAngle = armInfo.theta + pitchAngle + Math.PI / 2;
              const rand1 = Math.random() || 1e-6;
              const rand2 = Math.random();
              const gaussian = Math.sqrt(-2.0 * Math.log(rand1)) * Math.cos(2.0 * Math.PI * rand2);
              const jitterAmount = p.jitterStrength * result.profile * gaussian;
              ox += (jitterAmount * Math.cos(jitterAngle)) / DPR;
              oy += (jitterAmount * Math.sin(jitterAngle)) / DPR;
            }

            // Color by region hue with subtle variance
            const angle = (Math.atan2(oy - centerY / DPR, ox - centerX / DPR) * 180) / Math.PI + 360;
            const hue = regionHue(angle % 360) + (Math.random() - 0.5) * 8;
            const sat = 0.65 + Math.random() * 0.1;
            const lum = 0.65 - Math.min(0.25, radius / (maxRadius / DPR) * 0.25);
            const color = hslToRgba(hue, sat, lum, 0.9);

            const target = (Math.random() < 0.4) ? fctx : nctx; // split to far/near
            target.fillStyle = color;
            target.beginPath();
            target.arc(ox, oy, size, 0, Math.PI * 2);
            target.fill();

            // Glow for highlight stars
            if (size > 2.4 || (result.profile > 0.7 && Math.random() < p.armHighlightProb * 0.5)) {
              const glow = hslToRgba(hue, sat, lum, 0.18);
              target.fillStyle = glow;
              target.beginPath();
              target.arc(ox, oy, size * 3.2, 0, Math.PI * 2);
              target.fill();
            }
          }
        }
      }
      nctx.restore();
      fctx.restore();

      nearLayerRef.current = near;
      farLayerRef.current = far;
    };

    const drawFrame = (time: number) => {
      const width = canvas.width;
      const height = canvas.height;
      const w = width; const h = height;
      const cx = w / 2; const cy = h / 2;
      const basePeriod = 7000; // 7s breath
      const t = time % basePeriod;
      const breath = reducedMotion ? 1 : 0.95 + 0.15 * Math.sin((2 * Math.PI * t) / basePeriod);
      const rotNear = reducedMotion ? 0 : (time * 0.002) * (Math.PI / 180); // ~0.002 deg/ms => 0.12deg/s
      const rotFar = reducedMotion ? 0 : (time * 0.0015) * (Math.PI / 180);

      ctx.save();
      ctx.clearRect(0, 0, w, h);

      // Draw rotating layers
      const near = nearLayerRef.current;
      const far = farLayerRef.current;
      if (far) {
        ctx.save();
        ctx.translate(cx, cy);
        ctx.rotate(rotFar);
        ctx.globalAlpha = 1;
        ctx.drawImage(far, -cx, -cy, w, h);
        ctx.restore();
      }
      if (near) {
        ctx.save();
        ctx.translate(cx, cy);
        ctx.rotate(rotNear);
        ctx.globalAlpha = 1;
        ctx.drawImage(near, -cx, -cy, w, h);
        ctx.restore();
      }

      // Breathing nebula overlay (soft radial)
      if (!reducedMotion) {
        const g = ctx.createRadialGradient(cx, cy, 0, cx, cy, Math.min(w, h) * 0.6);
        g.addColorStop(0, `rgba(120,120,160,${0.1 * breath})`);
        g.addColorStop(1, 'rgba(0,0,0,0)');
        ctx.globalCompositeOperation = 'lighter';
        ctx.fillStyle = g;
        ctx.beginPath(); ctx.arc(cx, cy, Math.min(w, h) * 0.6, 0, Math.PI * 2); ctx.fill();
        ctx.globalCompositeOperation = 'source-over';
      }

      // Hover region wedge highlight
      const region = hoverRegionRef.current;
      if (region && !reducedMotion) {
        ctx.save();
        const color = region === 'emotion' ? '255,80,160' : region === 'relation' ? '80,160,255' : '160,140,255';
        const gradient = ctx.createRadialGradient(cx, cy, 0, cx, cy, Math.min(w, h) * 0.7);
        gradient.addColorStop(0, `rgba(${color}, 0.10)`);
        gradient.addColorStop(1, 'rgba(0,0,0,0)');
        ctx.globalCompositeOperation = 'lighter';
        ctx.fillStyle = gradient;
        const startDeg = region === 'emotion' ? 0 : region === 'relation' ? 120 : 240;
        const endDeg = startDeg + 120;
        const start = (startDeg * Math.PI) / 180 + rotNear;
        const end = (endDeg * Math.PI) / 180 + rotNear;
        ctx.beginPath();
        ctx.moveTo(cx, cy);
        ctx.arc(cx, cy, Math.min(w, h), start, end);
        ctx.closePath();
        ctx.fill();
        ctx.restore();
        ctx.globalCompositeOperation = 'source-over';
      }

      // Vignette
      const vignette = ctx.createRadialGradient(cx, cy, Math.min(w, h) * 0.6, cx, cy, Math.min(w, h) * 0.9);
      vignette.addColorStop(0, 'rgba(0,0,0,0)');
      vignette.addColorStop(1, 'rgba(0,0,0,0.25)');
      ctx.fillStyle = vignette;
      ctx.beginPath(); ctx.rect(0, 0, w, h); ctx.fill();

      // Click bursts
      if (burstsRef.current.length > 0) {
        const now = performance.now();
        burstsRef.current = burstsRef.current.filter(b => now - b.start < b.life);
        burstsRef.current.forEach((b, i) => {
          const progress = (now - b.start) / b.life;
          const r = (40 + 120 * progress) * (currentQualityRef.current === 'low' ? 0.8 : 1);
          const alpha = 0.35 * (1 - progress);
          ctx.strokeStyle = `rgba(255,255,255,${alpha})`;
          ctx.lineWidth = 1.2;
          ctx.beginPath();
          ctx.arc((b.x / 100) * w, (b.y / 100) * h, r, 0, Math.PI * 2);
          ctx.stroke();
        });
      }

      ctx.restore();
    };

    const renderAll = () => { generateLayers(); };

    resize();
    renderAll();
    const handleResize = () => { resize(); renderAll(); };
    window.addEventListener('resize', handleResize);
    
    // FPS sampling loop for auto quality
    let rafId: number;
    const tick = (now: number) => {
      const dt = now - lastFrameTimeRef.current;
      lastFrameTimeRef.current = now;
      const fps = dt > 0 ? 1000 / dt : 60;
      const t = now - lastFpsSampleTimeRef.current;
      fpsSamplesRef.current.push(fps);
      if (t > 1000) {
        // compute average
        const samples = fpsSamplesRef.current;
        const avg = samples.reduce((a, b) => a + b, 0) / Math.max(1, samples.length);
        fpsSamplesRef.current = [];
        lastFpsSampleTimeRef.current = now;
        // Auto adjust quality if needed
        if (quality === 'auto') {
          const q = currentQualityRef.current;
          const since = now - lastQualityChangeRef.current;
          if (avg < 45 && q !== 'low' && since > 3000) {
            currentQualityRef.current = q === 'high' ? 'mid' : 'low';
            lastQualityChangeRef.current = now;
            renderAll();
          } else if (avg > 58 && q !== 'high' && since > 3000) {
            currentQualityRef.current = q === 'low' ? 'mid' : 'high';
            lastQualityChangeRef.current = now;
            renderAll();
          }
        }
      }
      // frame draw
      drawFrame(now);
      rafId = requestAnimationFrame(tick);
    };
    rafId = requestAnimationFrame(tick);

    return () => {
      window.removeEventListener('resize', handleResize);
      cancelAnimationFrame(rafId);
    };
  }, [quality, reducedMotion]);

  // Angle→区域映射：将360°切为三等份
  const angleToRegion = (angleRad: number): 'emotion' | 'relation' | 'growth' => {
    const deg = ((angleRad * 180) / Math.PI + 360) % 360;
    if (deg < 120) return 'emotion';
    if (deg < 240) return 'relation';
    return 'growth';
  };

  const handleClick: React.MouseEventHandler<HTMLCanvasElement> = (e) => {
    const rect = (e.target as HTMLCanvasElement).getBoundingClientRect();
    const x = ((e.clientX - rect.left) / rect.width) * 100;
    const y = ((e.clientY - rect.top) / rect.height) * 100;
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    const angle = Math.atan2(e.clientY - cy, e.clientX - cx);
    const region = angleToRegion(angle);
    // burst
    const life = reducedMotion ? 600 : 1000;
    burstsRef.current.push({ x, y, start: performance.now(), life });
    if (onCanvasClick) onCanvasClick({ x, y, region });
  };

  const handleMouseMove: React.MouseEventHandler<HTMLCanvasElement> = (e) => {
    const rect = (e.target as HTMLCanvasElement).getBoundingClientRect();
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    const angle = Math.atan2(e.clientY - cy, e.clientX - cx);
    hoverRegionRef.current = angleToRegion(angle);
  };

  return (
    <canvas
      ref={canvasRef}
      className={
        className || 'fixed top-0 left-0 w-full h-full -z-10'
      }
      onClick={handleClick}
      onMouseMove={handleMouseMove}
    />
  );
};

export default InteractiveGalaxyBackground;
