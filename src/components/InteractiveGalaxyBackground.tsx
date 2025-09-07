import React, { useEffect, useRef, useState } from 'react';

type Quality = 'low' | 'mid' | 'high' | 'auto';

interface InteractiveGalaxyBackgroundProps {
  quality?: Quality;
  reducedMotion?: boolean;
  className?: string;
  onCanvasClick?: (payload: { x: number; y: number; region: 'emotion' | 'relation' | 'growth' }) => void;
  debugControls?: boolean;
}

// Lightweight pseudo-noise (deterministic) to avoid extra dependencies
const fract = (n: number) => n - Math.floor(n);
const noise2D = (x: number, y: number) => {
  const t = Math.sin(x * 12.9898 + y * 78.233) * 43758.5453123;
  return fract(t) * 2 - 1; // [-1, 1]
};

// Best visual defaults aligned to 3-arm design
const defaultParams = {
  // 对齐你提供的默认参数（与 ref/galaxy_claude 初始配置一致）
  coreDensity: 0.7,
  coreRadius: 25,
  coreSizeMin: 1.0,
  coreSizeMax: 3.5,
  armCount: 5,
  armDensity: 0.6,
  armBaseSizeMin: 0.7,
  armBaseSizeMax: 2.0,
  armHighlightSize: 5.0,
  armHighlightProb: 0.01,
  spiralA: 8,
  spiralB: 0.29,
  armWidthInner: 29,
  armWidthOuter: 113,
  armWidthGrowth: 2.5,
  armTransitionSoftness: 3,
  fadeStartRadius: 0.5,
  fadeEndRadius: 1.54,
  outerDensityMaintain: 0.10,
  interArmDensity: 0.08,
  interArmSizeMin: 0.6,
  interArmSizeMax: 1.2,
  radialDecay: 0.0015,
  backgroundDensity: 0.00045,
  backgroundSizeVariation: 2.0,
  jitterStrength: 17,
  densityNoiseScale: 0.09,
  densityNoiseStrength: 0.95,
  // 抖动不规律性（新增）
  jitterChaos: 7,            // 为抖动引入低频噪声调制，提升不规律
  jitterChaosScale: 1,       // 低频噪声的尺度（越小越大团）
  armStarSizeMultiplier: 0.8,
  interArmStarSizeMultiplier: 1,
  backgroundStarSizeMultiplier: 0.7,
  // 视图层整体缩放（围绕屏幕中心），用于控制银河占屏比例
  galaxyScale: 0.68,
};

// 模块颜色默认值（结构着色用）
const defaultPalette = {
  core: '#FFF8DC',      // 核心黄白
  ridge: '#E6F3FF',     // 螺旋臂脊线（最亮）
  armBright: '#ADD8E6', // 螺旋臂内部亮区
  armEdge: '#87CEEB',   // 螺旋臂边缘
  dust: '#8B4513',      // 尘埃带
  outer: '#B0C4DE',     // 臂间/外围
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
  // 反向旋臂方向：仅改变角度符号，其余参数保持不变
  const angle = Math.log(Math.max(radius, p.spiralA) / p.spiralA) / p.spiralB;
  for (let arm = 0; arm < p.armCount; arm++) {
    const armOffset = (arm * 2 * Math.PI) / p.armCount;
    const theta = armOffset - angle;
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
  debugControls = false,
}) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const currentQualityRef = useRef<Exclude<Quality, 'auto'>>('mid');
  const fpsSamplesRef = useRef<number[]>([]);
  const lastFpsSampleTimeRef = useRef<number>(performance.now());
  const lastFrameTimeRef = useRef<number>(performance.now());
  const lastQualityChangeRef = useRef<number>(0);
  const hoverRegionRef = useRef<'emotion' | 'relation' | 'growth' | null>(null);
  const bgLayerRef = useRef<HTMLCanvasElement | null>(null); // 背景层：不缩放/不旋转，覆盖全屏
  const nearLayerRef = useRef<HTMLCanvasElement | null>(null); // legacy
  const farLayerRef = useRef<HTMLCanvasElement | null>(null);  // legacy
  const bandLayersRef = useRef<HTMLCanvasElement[] | null>(null); // 差速旋转分层
  const [params, setParams] = useState(defaultParams);
  const paramsRef = useRef(params);
  useEffect(() => { paramsRef.current = params; }, [params]);

  const renderAllRef = useRef<() => void>();
  // Rotation toggle: pause during debug by default
  const [rotateEnabled, setRotateEnabled] = useState(!debugControls);
  const rotateRef = useRef(rotateEnabled);
  useEffect(() => { rotateRef.current = rotateEnabled; }, [rotateEnabled]);
  // 结构着色开关：按星系结构分类上色（默认关闭，保持白星风格）
  const [structureColoring, setStructureColoring] = useState(false);
  const [palette, setPalette] = useState<typeof defaultPalette>(defaultPalette);
  const paletteRef = useRef(palette);
  useEffect(() => { paletteRef.current = palette; }, [palette]);

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
    };

    // 为确保静止与旋转形态一致，锁定采样为“高质量”
    const getQualityScale = () => 1;
    const getStep = () => 1.0;
    // 原始样式：白色星点，不做额外着色/辉光

    // Generate pre-rendered layers
    const generateLayers = () => {
      // Deterministic RNG to ensure same morphology for same params across regenerations
      const seeded = (seed: number) => {
        let t = seed >>> 0;
        return () => {
          t += 0x6D2B79F5;
          let r = Math.imul(t ^ (t >>> 15), 1 | t);
          r ^= r + Math.imul(r ^ (r >>> 7), 61 | r);
          return ((r ^ (r >>> 14)) >>> 0) / 4294967296;
        };
      };
      const rng = seeded(0xA17C9E3); // fixed seed for stable output

      const p = paramsRef.current;
      const width = canvas.width;
      const height = canvas.height;
      const centerX = width / 2;
      const centerY = height / 2;
      const maxRadius = Math.min(width, height) * 0.4;
      // 动态 overscan：保证旋转+缩放后不裁切（不改变主体尺寸）
      const scaleLocal = Math.max(0.01, paramsRef.current.galaxyScale ?? 1);
      const minOV = Math.max(Math.SQRT2 + 0.1, (1 / scaleLocal) + 0.2);
      const OV = Math.max(1, p.overscan || 1.0, minOV);
      const owidth = Math.floor(width * OV);
      const oheight = Math.floor(height * OV);
      const oCenterX = owidth / 2;
      const oCenterY = oheight / 2;
      const radialDecay = getRadialDecayFn(p);

      // init offscreen layers
      const bg = document.createElement('canvas'); // 背景层（不受缩放/旋转影响）
      const near = document.createElement('canvas');
      const far = document.createElement('canvas');
      bg.width = width; bg.height = height;
      near.width = width; near.height = height;
      far.width = width; far.height = height;
      const bctx = bg.getContext('2d')!;
      const nctx = near.getContext('2d')!;
      const fctx = far.getContext('2d')!;
      // Prepare band layers for differential rotation (no duplication)
      const BAND_COUNT = 10;
      const bands: HTMLCanvasElement[] = Array.from({ length: BAND_COUNT }, () => {
        const c = document.createElement('canvas');
        c.width = owidth; c.height = oheight;
        return c;
      });
      const bandCtx = bands.map(c => c.getContext('2d')!);
      bandCtx.forEach(ctx => { ctx.save(); ctx.scale(DPR, DPR); });

      const qualityScale = getQualityScale();
      const step = getStep();

      // Background small stars -> bg layer (full-screen, no rotation/scale)
      const bgCount = Math.floor((width / DPR) * (height / DPR) * p.backgroundDensity * (reducedMotion ? 0.6 : 1) * qualityScale);
      bctx.save(); bctx.scale(DPR, DPR); bctx.fillStyle = 'rgba(255,255,255,0.9)';
      for (let i = 0; i < bgCount; i++) {
        const x = rng() * (width / DPR);
        const y = rng() * (height / DPR);
        const r1 = rng();
        const r2 = rng();
        let size = r1 < 0.85 ? 0.8 : (r2 < 0.9 ? 1.2 : p.backgroundSizeVariation);
        size *= p.backgroundStarSizeMultiplier;
        bctx.beginPath();
        bctx.arc(x, y, size, 0, Math.PI * 2);
        bctx.fill();
      }
      bctx.restore();

      // galaxy field: raster grid to allocate points into near/far
      nctx.save(); nctx.scale(DPR, DPR);
      fctx.save(); fctx.scale(DPR, DPR);
      for (let x = 0; x < owidth / DPR; x += step) {
        for (let y = 0; y < oheight / DPR; y += step) {
          const dx = x - oCenterX / DPR;
          const dy = y - oCenterY / DPR;
          const radius = Math.sqrt(dx * dx + dy * dy);
          if (radius < 3) continue;

          const decay = radialDecay(radius, maxRadius / DPR);
          const armInfo = getArmInfo(x * DPR, y * DPR, oCenterX, oCenterY, maxRadius, p);
          const result = calculateArmDensityProfile(armInfo, p);

          let density: number;
          let size: number;
          if (radius < p.coreRadius) {
            const coreProfile = Math.exp(-Math.pow(radius / p.coreRadius, 1.5));
            density = p.coreDensity * coreProfile * decay;
            size = (p.coreSizeMin + Math.random() * (p.coreSizeMax - p.coreSizeMin)) * p.armStarSizeMultiplier;
          } else {
            const n = noise2D(x * p.densityNoiseScale, y * p.densityNoiseScale);
            // 放大可调上限：允许 densityNoiseStrength > 1，但对调制进行下限夹紧，避免负值
            let modulation = 1.0 - p.densityNoiseStrength * (0.5 * (1.0 - n));
            if (modulation < 0.0) modulation = 0.0;
            density = result.density * decay * modulation;
            size = result.size;
          }
          density *= 0.8 + rng() * 0.4;
          if (rng() < density) {
            let ox = x; let oy = y;
            if (!reducedMotion && result.profile > 0.001) {
              const pitchAngle = Math.atan(1 / p.spiralB);
              const jitterAngle = armInfo.theta + pitchAngle + Math.PI / 2;
              const rand1 = rng() || 1e-6;
              const rand2 = rng();
              const gaussian = Math.sqrt(-2.0 * Math.log(rand1)) * Math.cos(2.0 * Math.PI * rand2);
              // 为抖动引入低频噪声混合，使之更不规律
              const chaos = 1 + (p.jitterChaos || 0) * noise2D(x * (p.jitterChaosScale || 0.02), y * (p.jitterChaosScale || 0.02));
              const randomMix = 0.7 + 0.6 * rng();
              const jitterAmount = p.jitterStrength * chaos * randomMix * result.profile * gaussian;
              ox += (jitterAmount * Math.cos(jitterAngle)) / DPR;
              oy += (jitterAmount * Math.sin(jitterAngle)) / DPR;
            }
            // assign to radial band for differential rotation
            const dxC = (ox * DPR) - oCenterX;
            const dyC = (oy * DPR) - oCenterY;
            const r = Math.sqrt(dxC * dxC + dyC * dyC);
            const rFrac = Math.max(0, Math.min(0.999, r / maxRadius));
            const bandIndex = Math.min(BAND_COUNT - 1, Math.floor(rFrac * BAND_COUNT));
            const target = bandCtx[bandIndex];
            // 结构着色分类（核心/脊线/臂内/臂边/尘埃/外围），可通过开关启用
            if (structureColoring) {
              const cxCSS = oCenterX / DPR;
              const cyCSS = oCenterY / DPR;
              const rCSS = Math.sqrt((ox - cxCSS) ** 2 + (oy - cyCSS) ** 2);
              const aw = (armInfo.armWidth || 1) / DPR;
              const d = armInfo.distance / DPR;
              const noiseLocal = noise2D(x * 0.05, y * 0.05);
              // 简单阈值（可后续透出）：
              const coreR = p.coreRadius;
              const ridgeT = 0.7;   // 脊线
              const mainT = 0.5;    // 臂内
              const edgeT = 0.25;   // 臂边
              const dustOffset = 0.35 * aw;
              const dustHalf = 0.10 * aw * 0.5;
              const pal = paletteRef.current;
              let fill = '#FFFFFF';
              if (rCSS < coreR) {
                fill = pal.core; // 核心黄白
              } else {
                const inDust = armInfo.inArm && Math.abs(d - dustOffset) <= dustHalf;
                if (inDust || noiseLocal < -0.2) {
                  fill = pal.dust; // 尘埃带红褐
                } else if (result.profile > ridgeT) {
                  fill = pal.ridge; // 螺旋臂脊线（最亮）
                } else if (result.profile > mainT) {
                  fill = pal.armBright; // 臂内部亮区
                } else if (result.profile > edgeT) {
                  fill = pal.armEdge; // 臂边缘淡蓝
                } else {
                  fill = pal.outer; // 臂间/外围灰蓝
                }
              }
              target.fillStyle = fill;
            } else {
              target.fillStyle = '#FFFFFF';
            }
            target.beginPath();
            // add slight deterministic jitter to break grid alignment
            const jx = (rng() - 0.5) * step;
            const jy = (rng() - 0.5) * step;
            target.arc(ox + jx, oy + jy, size, 0, Math.PI * 2);
            target.fill();
          }
        }
      }
      nctx.restore();
      fctx.restore();

      bandCtx.forEach(ctx => ctx.restore && ctx.restore());
      bgLayerRef.current = bg;
      bandLayersRef.current = bands;
      nearLayerRef.current = null;
      farLayerRef.current = null;
    };

    const drawFrame = (time: number) => {
      const width = canvas.width;
      const height = canvas.height;
      const w = width; const h = height;
      const cx = w / 2; const cy = h / 2;
      const doRotate = rotateRef.current && !reducedMotion;
      const rotNear = doRotate ? (time * 0.002) * (Math.PI / 180) : 0; // ~0.12deg/s
      const rotFar = doRotate ? (time * 0.0015) * (Math.PI / 180) : 0;

      ctx.save();
      ctx.clearRect(0, 0, w, h);

      // 1) Background layer (fills the whole screen, not scaled/rotated)
      const bg = bgLayerRef.current;
      if (bg) {
        ctx.save();
        ctx.globalAlpha = 1;
        ctx.drawImage(bg, 0, 0, w, h);
        ctx.restore();
      }

      // 2) Rotating galaxy layers (scaled around center) - differential rotation by radial bands
      const bands = bandLayersRef.current || [];
      const scale = paramsRef.current.galaxyScale ?? 1;
      // Differential rotation: inner faster, outer slower
      const baseDegPerMs = 0.00025; // 内层基础角速度（降为原来的 1/10）
      for (let i = 0; i < bands.length; i++) {
        const band = bands[i];
        const rMid = (i + 0.5) / Math.max(1, bands.length); // 0..1
        const omegaDegPerMs = doRotate ? (baseDegPerMs / (0.25 + rMid)) : 0; // ω ~ 1/(0.25+r)
        const angle = omegaDegPerMs * time * (Math.PI / 180);
        ctx.save();
        ctx.translate(cx, cy);
        ctx.scale(scale, scale);
        ctx.rotate(angle);
        ctx.globalAlpha = 1;
        const bw = band.width, bh = band.height; const bcx = bw / 2, bcy = bh / 2;
        ctx.drawImage(band, -bcx, -bcy, bw, bh);
        ctx.restore();
      }

      // 原始风格：无呼吸云层、无区域楔形高亮、无暗角

      // 原始风格：不渲染点击喷发环

      ctx.restore();
    };

    const renderAll = () => { generateLayers(); };
    renderAllRef.current = renderAll;

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
        // 仍然采样 FPS，但不再自动降质，保持形态一致
        fpsSamplesRef.current = [];
        lastFpsSampleTimeRef.current = now;
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

  // Re-generate layers when params change
  useEffect(() => {
    renderAllRef.current && renderAllRef.current();
  }, [params]);

  // 调整模块颜色时也需要重绘
  useEffect(() => {
    renderAllRef.current && renderAllRef.current();
  }, [palette, structureColoring]);

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
    <>
      <canvas
        ref={canvasRef}
        className={
          className || 'fixed top-0 left-0 w-full h-full -z-10'
        }
        onClick={handleClick}
        onMouseMove={handleMouseMove}
      />
      {debugControls && (
        <div className="fixed top-28 right-4 z-40 w-80 max-h-[70vh] overflow-y-auto rounded-lg bg-black/70 backdrop-blur p-3 text-white border border-white/10">
          <div className="flex items-center justify-between mb-2">
            <strong className="text-sm">银河参数（临时）</strong>
            <div className="flex items-center gap-2">
              <label className="text-xs flex items-center gap-1">
                <input type="checkbox" checked={rotateEnabled} onChange={(e)=>setRotateEnabled(e.target.checked)} />
                旋转
              </label>
              <label className="text-xs flex items-center gap-1">
                <input type="checkbox" checked={structureColoring} onChange={(e)=>setStructureColoring(e.target.checked)} />
                结构着色
              </label>
              <button className="text-xs opacity-70 hover:opacity-100" onClick={() => setParams(defaultParams)}>重置</button>
            </div>
          </div>
          {structureColoring && (
            <div className="mb-3 border-b border-white/10 pb-2">
              <div className="text-xs opacity-80 mb-2">模块颜色</div>
              {([
                {k:'core', label:'核心'},
                {k:'ridge', label:'臂脊'},
                {k:'armBright', label:'臂内'},
                {k:'armEdge', label:'臂边'},
                {k:'dust', label:'尘埃'},
                {k:'outer', label:'外围'},
              ] as Array<{k:keyof typeof defaultPalette,label:string}>).map(({k,label}) => (
                <div key={k as string} className="mb-2 flex items-center justify-between gap-2">
                  <span className="text-xs">{label}</span>
                  <input type="color" value={(palette as any)[k]}
                    onChange={(e)=>{ const v = e.target.value; setPalette(prev => ({...prev, [k]: v})); }} />
                  <input type="text" value={(palette as any)[k]}
                    onChange={(e)=>{ const v = e.target.value; setPalette(prev => ({...prev, [k]: v})); }}
                    className="w-24 bg-transparent border border-white/10 rounded px-1 text-xs" />
                </div>
              ))}
            </div>
          )}
          {(
            [
              {k:'coreDensity',min:0,max:1,step:0.01,label:'核心密度'},
              {k:'coreRadius',min:5,max:100,step:1,label:'核心半径'},
              {k:'galaxyScale',min:0.3,max:1.2,step:0.01,label:'整体缩放（银河占屏比例）'},
              {k:'armCount',min:1,max:7,step:1,label:'旋臂数量'},
              {k:'armDensity',min:0,max:1,step:0.01,label:'旋臂密度'},
              {k:'spiralB',min:0.1,max:0.5,step:0.01,label:'螺旋紧密度'},
              {k:'armWidthInner',min:5,max:80,step:1,label:'内侧宽度'},
              {k:'armWidthOuter',min:20,max:140,step:1,label:'外侧宽度'},
              {k:'armWidthGrowth',min:1,max:3,step:0.1,label:'宽度增长'},
              {k:'interArmDensity',min:0,max:0.5,step:0.01,label:'臂间基础密度'},
              {k:'armTransitionSoftness',min:1,max:100,step:0.5,label:'山坡平缓度'},
              {k:'fadeStartRadius',min:0.2,max:1,step:0.01,label:'淡化起始'},
              {k:'fadeEndRadius',min:1,max:1.8,step:0.01,label:'淡化结束'},
              {k:'backgroundDensity',min:0,max:0.0006,step:0.00001,label:'背景密度'},
              {k:'jitterStrength',min:0,max:40,step:1,label:'垂直抖动强度'},
              {k:'jitterChaos',min:0,max:10,step:0.1,label:'抖动不规律度(Chaos)'},
              {k:'jitterChaosScale',min:0.001,max:2,step:0.001,label:'抖动噪声尺度'},
              {k:'densityNoiseScale',min:0.005,max:0.2,step:0.001,label:'密度噪声缩放(上限提升)'},
              {k:'densityNoiseStrength',min:0,max:2,step:0.05,label:'密度噪声强度(上限提升)'},
              {k:'armStarSizeMultiplier',min:0.5,max:2,step:0.1,label:'旋臂星星大小'},
              {k:'interArmStarSizeMultiplier',min:0.5,max:2,step:0.1,label:'臂间星星大小'},
              {k:'backgroundStarSizeMultiplier',min:0.5,max:2,step:0.1,label:'背景星星大小'},
              {k:'backgroundSizeVariation',min:0.5,max:4,step:0.1,label:'背景星星大小变化'},
              {k:'spiralA',min:2,max:20,step:1,label:'螺旋基准A'},
            ] as Array<{k: keyof typeof defaultParams, min:number,max:number,step:number,label:string}>
          ).map(({k,min,max,step,label}) => (
            <div key={k as string} className="mb-2">
              <label className="text-xs flex justify-between">
                <span>{label}</span>
                <span className="opacity-80">{(params as any)[k]}</span>
              </label>
              <input
                type="range"
                min={min}
                max={max}
                step={step}
                value={(params as any)[k] as any}
                onChange={(e) => {
                  const v = Number(e.target.value);
                  setParams(prev => ({ ...prev, [k]: (k==='armCount'||k==='spiralA') ? Math.round(v) : v } as typeof prev));
                }}
                className="w-full"
              />
            </div>
          ))}
        </div>
      )}
    </>
  );
};

export default InteractiveGalaxyBackground;
