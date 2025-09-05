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

const defaultParams = {
  coreDensity: 0.7,
  coreRadius: 25,
  coreSizeMin: 1,
  coreSizeMax: 3.5,
  armCount: 5,
  armDensity: 0.6,
  armBaseSizeMin: 0.7,
  armBaseSizeMax: 2.0,
  armHighlightSize: 5,
  armHighlightProb: 0.01,
  spiralA: 8,
  spiralB: 0.29,
  armWidthInner: 29,
  armWidthOuter: 65,
  armWidthGrowth: 2.5,
  armTransitionSoftness: 5.2,
  fadeStartRadius: 0.5,
  fadeEndRadius: 1.3,
  outerDensityMaintain: 0.1,
  interArmDensity: 0.15,
  interArmSizeMin: 0.6,
  interArmSizeMax: 1.2,
  radialDecay: 0.0015,
  backgroundDensity: 0.00024,
  backgroundSizeVariation: 2.0,
  jitterStrength: 10,
  densityNoiseScale: 0.018,
  densityNoiseStrength: 0.8,
  armStarSizeMultiplier: 1.0,
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
  const hoverRegionRef = useRef<'emotion' | 'relation' | 'growth' | null>(null);

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
    const draw = () => {
      const p = defaultParams;
      const width = canvas.width;
      const height = canvas.height;
      const centerX = width / 2;
      const centerY = height / 2;
      const maxRadius = Math.min(width, height) * 0.4;
      const radialDecay = getRadialDecayFn(p);

      ctx.save();
      ctx.scale(DPR, DPR); // ensure crisp in CSS pixels
      ctx.fillStyle = '#000000';
      ctx.fillRect(0, 0, width, height);
      ctx.fillStyle = '#FFFFFF';

      // Background stars
      const qualityScale = getQualityScale();
      const bgCount = Math.floor((width / DPR) * (height / DPR) * p.backgroundDensity * (reducedMotion ? 0.7 : 1) * qualityScale);
      for (let i = 0; i < bgCount; i++) {
        const x = Math.random() * (width / DPR);
        const y = Math.random() * (height / DPR);
        let size: number;
        const r = Math.random();
        if (r < 0.85) size = 0.8;
        else if (r < 0.97) size = 1.2;
        else size = p.backgroundSizeVariation;
        size *= p.backgroundStarSizeMultiplier;
        ctx.beginPath();
        ctx.arc(x, y, size, 0, Math.PI * 2);
        ctx.fill();
      }

      // Galaxy grid
      const step = getStep();
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
            let ox = x;
            let oy = y;
            if (!reducedMotion && result.profile > 0.001) {
              const pitchAngle = Math.atan(1 / p.spiralB);
              const jitterAngle = armInfo.theta + pitchAngle + Math.PI / 2;
              const rand1 = Math.random() || 1e-6;
              const rand2 = Math.random();
              const gaussian = Math.sqrt(-2.0 * Math.log(rand1)) * Math.cos(2.0 * Math.PI * rand2);
              const jitterAmount = p.jitterStrength * result.profile * gaussian;
              const dxj = jitterAmount * Math.cos(jitterAngle);
              const dyj = jitterAmount * Math.sin(jitterAngle);
              ox += dxj / DPR;
              oy += dyj / DPR;
            }
            ctx.beginPath();
            ox += (Math.random() - 0.5) * step;
            oy += (Math.random() - 0.5) * step;
            ctx.arc(ox, oy, size, 0, Math.PI * 2);
            ctx.fill();
          }
        }
      }
      
      // Hover region soft highlight overlay
      const region = hoverRegionRef.current;
      if (region && !reducedMotion) {
        ctx.save();
        const w = width / DPR;
        const h = height / DPR;
        const cx = w / 2;
        const cy = h / 2;
        const gradient = ctx.createRadialGradient(cx, cy, 0, cx, cy, Math.min(w, h) * 0.6);
        const color = region === 'emotion' ? '255,80,160' : region === 'relation' ? '80,160,255' : '160,140,255';
        gradient.addColorStop(0, `rgba(${color}, 0.10)`);
        gradient.addColorStop(1, 'rgba(0,0,0,0)');
        ctx.globalCompositeOperation = 'lighter';
        ctx.fillStyle = gradient;
        // Draw wedge
        const startDeg = region === 'emotion' ? 0 : region === 'relation' ? 120 : 240;
        const endDeg = startDeg + 120;
        const start = (startDeg * Math.PI) / 180;
        const end = (endDeg * Math.PI) / 180;
        ctx.beginPath();
        ctx.moveTo(cx, cy);
        ctx.arc(cx, cy, Math.min(w, h), start, end);
        ctx.closePath();
        ctx.fill();
        ctx.restore();
      }

      ctx.restore();
    };

    resize();
    window.addEventListener('resize', resize);
    
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
          if (avg < 45 && q !== 'low') {
            currentQualityRef.current = q === 'high' ? 'mid' : 'low';
            draw();
          } else if (avg > 58 && q !== 'high') {
            currentQualityRef.current = q === 'low' ? 'mid' : 'high';
            draw();
          }
        }
      }
      rafId = requestAnimationFrame(tick);
    };
    rafId = requestAnimationFrame(tick);

    return () => {
      window.removeEventListener('resize', resize);
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
    if (!onCanvasClick) return;
    const rect = (e.target as HTMLCanvasElement).getBoundingClientRect();
    const x = ((e.clientX - rect.left) / rect.width) * 100;
    const y = ((e.clientY - rect.top) / rect.height) * 100;
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    const angle = Math.atan2(e.clientY - cy, e.clientX - cx);
    const region = angleToRegion(angle);
    onCanvasClick({ x, y, region });
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
