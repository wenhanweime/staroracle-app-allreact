import React, { useEffect, useRef, useState } from 'react';
import HotspotOverlay from './HotspotOverlay';
import VoronoiOverlay from './VoronoiOverlay';
import GalaxyDOMPulseOverlay from './GalaxyDOMPulseOverlay';
import GalaxyLightweight from './GalaxyLightweight';
import { useGalaxyStore } from '../store/useGalaxyStore';
import { useGalaxyGridStore } from '../store/useGalaxyGridStore';
import { useStarStore } from '../store/useStarStore';

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

// 颜色辅助：HEX ↔ HSL（仅用于显示着色的颜色抖动，不影响算法）
const clamp01 = (v: number) => Math.max(0, Math.min(1, v));
const hexToRgb = (hex: string) => {
  const h = hex.replace('#','');
  const full = h.length === 3 ? h.split('').map(c=>c+c).join('') : h;
  const num = parseInt(full, 16);
  return { r: (num>>16)&255, g: (num>>8)&255, b: num&255 };
};
const rgbToHex = (r:number,g:number,b:number) => '#'+[r,g,b].map(v=>{
  const s = Math.max(0,Math.min(255, Math.round(v))).toString(16).padStart(2,'0');
  return s;
}).join('');
const rgbToHsl = (r:number,g:number,b:number) => {
  r/=255; g/=255; b/=255;
  const max=Math.max(r,g,b), min=Math.min(r,g,b);
  let h=0, s=0; const l=(max+min)/2;
  if (max!==min) {
    const d=max-min; s = l>0.5? d/(2-max-min): d/(max+min);
    switch (max) {
      case r: h=(g-b)/d+(g<b?6:0); break;
      case g: h=(b-r)/d+2; break;
      default: h=(r-g)/d+4;
    }
    h/=6;
  }
  return { h: h*360, s, l };
};
const hslToRgb = (h:number,s:number,l:number) => {
  h/=360;
  const hue2rgb = (p:number,q:number,t:number)=>{
    if (t<0) t+=1; if (t>1) t-=1;
    if (t<1/6) return p+(q-p)*6*t;
    if (t<1/2) return q;
    if (t<2/3) return p+(q-p)*(2/3-t)*6;
    return p;
  };
  let r:number,g:number,b:number;
  if (s===0) { r=g=b=l; }
  else {
    const q = l<0.5? l*(1+s): l+s-l*s;
    const p = 2*l-q;
    r = hue2rgb(p,q,h+1/3);
    g = hue2rgb(p,q,h);
    b = hue2rgb(p,q,h-1/3);
  }
  return { r: Math.round(r*255), g: Math.round(g*255), b: Math.round(b*255) };
};
const hexToHsl = (hex:string) => { const {r,g,b}=hexToRgb(hex); return rgbToHsl(r,g,b); };
const hslToHex = (h:number,s:number,l:number) => { const {r,g,b}=hslToRgb(h,s,l); return rgbToHex(r,g,b); };

// Best visual defaults aligned to 3-arm design
const defaultParams = {
   // 稳定版默认参数（对齐 tag：开始首页galaxy交互完整性之前的确定性版本）
   coreDensity: 0.7,// 核心密度  
   coreRadius: 12,    // 核心半径
   coreSizeMin: 1.0, // 核心星星大小最小
   coreSizeMax: 3.5, // 核心星星大小最大
   armCount: 5, // 旋臂数量
   armDensity: 0.6, // 旋臂密度
   armBaseSizeMin: 0.7, // 旋臂星星大小最小
   armBaseSizeMax: 2.0, // 旋臂星星大小最大
   armHighlightSize: 5.0, // 旋臂星星高亮大小
   armHighlightProb: 0.01, // 旋臂星星高亮概率
   spiralA: 8, // 螺旋基准
   spiralB: 0.29, // 螺旋紧密度
   armWidthInner: 29, // 旋臂宽度内侧
   armWidthOuter: 65, // 旋臂宽度外侧
   armWidthGrowth: 2.5, // 旋臂宽度增长
   armWidthScale: 1.0, // 旋臂整体宽度比例
   armTransitionSoftness: 3.8, // 旋臂过渡平滑度（更宽的臂脊）
   fadeStartRadius: 0.5, // 淡化起始
   fadeEndRadius: 1.3, // 淡化结束
   outerDensityMaintain: 0.10, // 外围密度维持
   interArmDensity: 0.150, // 旋臂间区域密度
   interArmSizeMin: 0.6, // 旋臂间区域星星大小最小
   interArmSizeMax: 1.2, // 旋臂间区域星星大小最大
   radialDecay: 0.0015, // 径向衰减
   backgroundDensity: 0.00024, // 背景星星密度
   backgroundSizeVariation: 2.0, // 背景星星大小变异
   jitterStrength: 10, // 垂直抖动强度
   densityNoiseScale: 0.018, // 密度噪声缩放
   densityNoiseStrength: 0.8, // 密度噪声强度
   // 抖动不规律（稳定版未使用，默认关闭）
   jitterChaos: 0, // 抖动不规律
   jitterChaosScale: 0, // 抖动不规律尺度
   armStarSizeMultiplier: 1.0, // 旋臂星星大小倍数
   interArmStarSizeMultiplier: 1.0, // 旋臂间区域星星大小倍数
   backgroundStarSizeMultiplier: 1.0,
   galaxyScale: 0.88, // 整体缩放（银河占屏比例）
   // 颜色波动（仅显示着色用，DOM 默认不启用）
   colorJitterHue: 10,
   colorJitterSat: 0.06,
   colorJitterLight: 0.04,
   colorNoiseScale: 0.05,
};

// 模块颜色默认值（结构着色用）
// 紫色主题调色板（参考主页右上角 Collection 的紫色：#8A5FBD 为主）
const defaultPalette = {
  core: '#FFF8DC',      // 核心黄白（保持）
  ridge: '#FBFBF3',     // 臂脊近白高亮（保持）
  armBright: '#8A5FBD', // 臂内明亮紫（原蓝 -> 紫）
  armEdge: '#9E7AD7',   // 臂边淡紫
  dust: '#5B3A8E',      // 尘埃带深紫
  outer: '#B79BEA',     // 臂间/外围淡紫
};
// 分层透明度（仅用于显示着色，不影响算法/密度）
const defaultLayerAlpha = {
  core: 1.0,
  ridge: 0.95,
  armBright: 0.9,
  armEdge: 0.85,
  dust: 0.65,
  outer: 0.75,
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
  const setGalaxyCanvasSize = useGalaxyStore(s=>s.setCanvasSize)
  const genHotspots = useGalaxyStore(s=>s.generateHotspots)
  const hoverHs = useGalaxyStore(s=>s.hoverAt)
  const clickHs = useGalaxyStore(s=>s.clickAt)
  const drawInspirationCard = useStarStore(s=>s.drawInspirationCard)
  const setGridSize = useGalaxyGridStore(s=>s.setCanvasSize)
  const genSites = useGalaxyGridStore(s=>s.generateSites)
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
  // DOM 脉冲用：记录可见星点（CSS像素坐标，仅BG层，免读像素）
  const domStarPointsRef = useRef<Array<{x:number;y:number;size:number}>>([]);
  // 记录分层（旋转臂）星点：band 层坐标及其画布尺寸，用于点击时做矩阵变换
  const bandStarPointsRef = useRef<Array<{x:number;y:number;size:number;band:number;bw:number;bh:number}>>([]);
  // 星点掩膜层：与图层对应的掩膜和每帧合成后的掩膜
  const bgMaskRef = useRef<HTMLCanvasElement | null>(null);
  const bandMaskLayersRef = useRef<HTMLCanvasElement[] | null>(null);
  const starMaskCompositeRef = useRef<HTMLCanvasElement | null>(null);
  const domBandPointsRef = useRef<Array<{x:number;y:number;size:number;band:number;bw:number;bh:number}>>([]);
  const isIOS = typeof navigator !== 'undefined' && /iP(ad|hone|od)/.test(navigator.userAgent)
  const initialParams = isIOS ? {
    ...defaultParams,
    armWidthScale: 2.9,
    armWidthInner: 29,
    armWidthOuter: 65,
    armWidthGrowth: 2.5,
    armTransitionSoftness: 7,
    jitterStrength: 25,
  } : defaultParams
  const [params, setParams] = useState(initialParams);
  const paramsRef = useRef(params);
  useEffect(() => { paramsRef.current = params; }, [params]);
  // 星点默认使用偏灰白，避免纯白饱和（为交互提亮留余量）
  const starBaseColor = '#CCCCCC';
  // 闪烁动效配置（用于 ClickGlowOverlay）
  const [glowCfg, setGlowCfg] = useState({
    pickProb: 0.2,
    pulseWidth: 0.25,
    bandFactor: 0.12,
    noiseFactor: 0.08,
    edgeAlphaThresh: 8,
    edgeExponent: 1.1,
    // 点击高亮范围缩小一半（半径减半）
    radiusFactor: 0.00875,
    minRadius: 15,
    durationMs: 1100,
    ease: 'sine' as 'sine' | 'cubic',
  });
  // 闪烁调试参数（用于 ClickGlowOverlay）
  

  const renderAllRef = useRef<() => void>();
  // Rotation toggle: pause during debug by default
  const [rotateEnabled, setRotateEnabled] = useState(true);
  const rotateRef = useRef(rotateEnabled);
  useEffect(() => { rotateRef.current = rotateEnabled; }, [rotateEnabled]);
  // 结构着色开关：按星系结构分类上色（默认关闭，保持白星风格）
  const [structureColoring, setStructureColoring] = useState(true);
  const [palette, setPalette] = useState<typeof defaultPalette>(defaultPalette);
  const paletteRef = useRef(palette);
  useEffect(() => { paletteRef.current = palette; }, [palette]);
  // 每层透明度（仅显示层）
  const [layerAlpha, setLayerAlpha] = useState<typeof defaultLayerAlpha>(defaultLayerAlpha);
  const layerAlphaRef = useRef(layerAlpha);
  useEffect(() => { layerAlphaRef.current = layerAlpha; }, [layerAlpha]);

  useEffect(() => {
    // Coarse pointer (mobile): skip heavy Canvas pipeline, DOM mode will render below
    return;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    ctx.imageSmoothingEnabled = true;
    // Prefer highest quality resampling on iOS/retina
    // @ts-ignore
    ctx.imageSmoothingQuality = 'high';

    const DPR = (window.devicePixelRatio || 1);

    const resize = () => {
      const w = window.innerWidth;
      const h = window.innerHeight;
      canvas.width = Math.floor(w * DPR);
      canvas.height = Math.floor(h * DPR);
      canvas.style.width = `${w}px`;
      canvas.style.height = `${h}px`;
      const cw = Math.floor(w * DPR), ch = Math.floor(h * DPR)
      // 交互层与存储统一使用 CSS 像素尺寸，避免与 DPR 不一致
      setGalaxyCanvasSize(w, h)
      setGridSize(w, h)
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
      // 掩膜：与图层同尺寸
      const bgMask = document.createElement('canvas'); bgMask.width = width; bgMask.height = height;
      const bmctx = bgMask.getContext('2d')!;
      // Prepare band layers for differential rotation (no duplication)
      const BAND_COUNT = 10;
      const bands: HTMLCanvasElement[] = Array.from({ length: BAND_COUNT }, () => {
        const c = document.createElement('canvas');
        c.width = owidth; c.height = oheight;
        return c;
      });
      const bandCtx = bands.map(c => c.getContext('2d')!);
      bandCtx.forEach(ctx => { ctx.save(); ctx.scale(DPR, DPR); });
      // 收集 band 星点（不含旋转，仅记录生成时 band 层坐标）
      const bandPts: Array<Array<{x:number;y:number;size:number}>> = Array.from({length:BAND_COUNT},()=>[]);
      const bandMasks: HTMLCanvasElement[] = Array.from({ length: BAND_COUNT }, () => {
        const c = document.createElement('canvas');
        c.width = owidth; c.height = oheight;
        return c;
      });
      const bandMaskCtx = bandMasks.map(c => c.getContext('2d')!);
      bandMaskCtx.forEach(ctx => { ctx.save(); ctx.scale(DPR, DPR); });

      const qualityScale = getQualityScale();
      const step = getStep();

      // Background small stars -> bg layer (full-screen, no rotation/scale)
      const domPoints: Array<{x:number;y:number;size:number}> = [];
      const bgCount = Math.floor((width / DPR) * (height / DPR) * p.backgroundDensity * (reducedMotion ? 0.6 : 1) * qualityScale);
      bctx.save(); bctx.scale(DPR, DPR); bctx.globalAlpha = 1; bctx.fillStyle = starBaseColor;
      bmctx.save(); bmctx.scale(DPR, DPR); bmctx.fillStyle = '#FFFFFF';
      for (let i = 0; i < bgCount; i++) {
        const x = rng() * (width / DPR);
        const y = rng() * (height / DPR);
        const r1 = rng();
        const r2 = rng();
        let size = r1 < 0.85 ? 0.8 : (r2 < 0.9 ? 1.2 : p.backgroundSizeVariation);
        size *= p.backgroundStarSizeMultiplier;
        bctx.beginPath(); bctx.arc(x, y, size, 0, Math.PI * 2); bctx.fill();
        bmctx.beginPath(); bmctx.arc(x, y, size, 0, Math.PI * 2); bmctx.fill();
        domPoints.push({ x, y, size });
      }
      bctx.restore(); bmctx.restore();

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
            const targetMask = bandMaskCtx[bandIndex];
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
              const al = layerAlphaRef?.current || defaultLayerAlpha;
              let fill = '#FFFFFF';
              let a = 1.0;
              if (rCSS < coreR) {
                fill = pal.core; a = al.core; // 核心黄白
              } else {
                const inDust = armInfo.inArm && Math.abs(d - dustOffset) <= dustHalf;
                if (inDust || noiseLocal < -0.2) {
                  fill = pal.dust; a = al.dust; // 尘埃带红褐
                } else if (result.profile > ridgeT) {
                  fill = pal.ridge; a = al.ridge; // 螺旋臂脊线（最亮）
                } else if (result.profile > mainT) {
                  fill = pal.armBright; a = al.armBright; // 臂内部亮区
                } else if (result.profile > edgeT) {
                  fill = pal.armEdge; a = al.armEdge; // 臂边缘淡蓝
                } else {
                  fill = pal.outer; a = al.outer; // 臂间/外围灰蓝
                }
              }
              // 颜色波动（仅显示）：基于坐标的小幅 HSL 扰动
              const baseHsl = hexToHsl(fill);
              const nh = noise2D(ox * p.colorNoiseScale, oy * p.colorNoiseScale);
              const ns = noise2D(ox * p.colorNoiseScale + 31.7, oy * p.colorNoiseScale + 11.3);
              const nl = noise2D(ox * p.colorNoiseScale + 77.1, oy * p.colorNoiseScale + 59.9);
              const h = (baseHsl.h + nh * p.colorJitterHue + 360) % 360;
              const s = clamp01(baseHsl.s + ns * p.colorJitterSat);
              const l = clamp01(baseHsl.l + nl * p.colorJitterLight);
              fill = hslToHex(h, s, l);
              const prevAlpha = target.globalAlpha;
              target.globalAlpha = prevAlpha * a;
              target.fillStyle = fill;
            } else {
              target.globalAlpha = 1;
              target.fillStyle = starBaseColor;
            }
            target.beginPath();
            // add slight deterministic jitter to break grid alignment
            const jx = (rng() - 0.5) * step;
            const jy = (rng() - 0.5) * step;
            target.arc(ox + jx, oy + jy, size, 0, Math.PI * 2);
            target.fill();
            // 掩膜：同样位置半径写入白色
            targetMask.beginPath();
            targetMask.fillStyle = '#FFFFFF';
            targetMask.arc(ox + jx, oy + jy, size, 0, Math.PI * 2);
            targetMask.fill();
            // 记录 band 星点（生成时坐标）
            bandPts[bandIndex].push({ x: ox + jx, y: oy + jy, size });
            if (structureColoring) { target.globalAlpha = 1; }
          }
        }
      }
      nctx.restore();
      fctx.restore();

      bandCtx.forEach(ctx => ctx.restore && ctx.restore());
      bandMaskCtx.forEach(ctx => ctx.restore && ctx.restore());
      bgLayerRef.current = bg;
      bandLayersRef.current = bands;
      bgMaskRef.current = bgMask;
      bandMaskLayersRef.current = bandMasks;
      nearLayerRef.current = null;
      farLayerRef.current = null;
      domStarPointsRef.current = domPoints;
      // 展平 band 点并附上 band 画布尺寸
      const flattened: Array<{x:number;y:number;size:number;band:number;bw:number;bh:number}> = [];
      for(let i=0;i<BAND_COUNT;i++){
        const bw = bands[i].width; const bh = bands[i].height;
        for(const p of bandPts[i]) flattened.push({ x:p.x, y:p.y, size:p.size, band:i, bw, bh });
      }
      bandStarPointsRef.current = flattened;
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
      const bgMask = bgMaskRef.current;
      if (bg) {
        ctx.save();
        ctx.globalAlpha = 1;
        ctx.drawImage(bg, 0, 0, w, h);
        ctx.restore();
      }

      // 2) Rotating galaxy layers (scaled around center) - differential rotation by radial bands
      const bands = bandLayersRef.current || [];
      const bandMasks = bandMaskLayersRef.current || [];
      const scale = paramsRef.current.galaxyScale ?? 1;
      // Prepare/update screen-space star mask composite
      if (!starMaskCompositeRef.current) {
        const c = document.createElement('canvas'); c.width = w; c.height = h; starMaskCompositeRef.current = c;
      }
      const mctx = starMaskCompositeRef.current!.getContext('2d')!;
      mctx.clearRect(0,0,w,h);
      if (bgMask) mctx.drawImage(bgMask, 0, 0, w, h);

      // Differential rotation: inner faster, outer slower
      const baseDegPerMs = 0.00025; // 内层基础角速度（降为原来的 1/10）
      for (let i = 0; i < bands.length; i++) {
        const band = bands[i];
        const bandMask = bandMasks[i];
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

        // 同步变换叠加掩膜
        if (bandMask) {
          mctx.save();
          mctx.translate(cx, cy);
          mctx.scale(scale, scale);
          mctx.rotate(angle);
          const bw2 = bandMask.width, bh2 = bandMask.height; const bcx2 = bw2/2, bcy2 = bh2/2;
          mctx.drawImage(bandMask, -bcx2, -bcy2, bw2, bh2);
          mctx.restore();
        }
      }

      // 原始风格：无呼吸云层、无区域楔形高亮、无暗角

      // 原始风格：不渲染点击喷发环

      ctx.restore();
    };

    const renderAll = () => { generateLayers(); };
    renderAllRef.current = renderAll;

    resize();
    renderAll();
    // 初始化热点（仅一次）
    genHotspots(36)
    // 单元细化：提高站点数量，单元尺寸约缩小至原来的 1/5
    genSites(600)
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
  }, [quality, reducedMotion, structureColoring]);

  // Re-generate layers when params change
  useEffect(() => {
    renderAllRef.current && renderAllRef.current();
  }, [params]);

  // 调整模块颜色/透明度或开关时重绘（仅影响着色，不改生成参数）
  useEffect(() => {
    renderAllRef.current && renderAllRef.current();
  }, [palette, layerAlpha, structureColoring]);

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
    // 触发热点交互与内容分发（不改主体渲染）
    clickHs(e.clientX, e.clientY)
    drawInspirationCard(region as any)
  };

  const handleMouseMove: React.MouseEventHandler<HTMLCanvasElement> = (e) => {
    const rect = (e.target as HTMLCanvasElement).getBoundingClientRect();
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    const angle = Math.atan2(e.clientY - cy, e.clientX - cx);
    hoverRegionRef.current = angleToRegion(angle);
    hoverHs(e.clientX, e.clientY)
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
      <GalaxyLightweight
          params={params}
          palette={palette}
          structureColoring={structureColoring}
          armCount={defaultParams.armCount}
          scale={params.galaxyScale}
          onBandPointsReady={(pts)=>{ domBandPointsRef.current = pts }}
          onBgPointsReady={(pts)=>{ domStarPointsRef.current = pts }}
        />
      {/* DOM/SVG 脉冲（无需像素读回）：只使用BG层星点位置 */}
      <GalaxyDOMPulseOverlay pointsRef={domStarPointsRef} bandPointsRef={domBandPointsRef} scale={params.galaxyScale} rotateEnabled={rotateEnabled} config={glowCfg} />
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
              <div className="text-xs opacity-80 mb-2">模块颜色与透明度（不影响参数，仅着色）</div>
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
                  <div className="flex items-center gap-1">
                    <span className="text-[10px] opacity-70">α</span>
                    <input type="range" min={0} max={1} step={0.01}
                      value={(layerAlpha as any)[k]}
                      onChange={(e)=>{ const v = Number(e.target.value); setLayerAlpha(prev => ({...prev, [k]: v})); }}
                      className="w-24" />
                    <span className="text-[10px] opacity-70 w-8 text-right">{(layerAlpha as any)[k].toFixed(2)}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
          {/* 闪烁动效调试 */}
          <div className="mt-3 border-b border-white/10 pb-2">
            <div className="text-xs opacity-80 mb-2">闪烁调试（点击星变亮→回灰）</div>
            {([
              {k:'pickProb', min:0, max:0.5, step:0.01, label:'选中比例'},
              {k:'pulseWidth', min:0.1, max:0.5, step:0.01, label:'脉冲宽度'},
              {k:'bandFactor', min:0.05, max:0.3, step:0.005, label:'扩散软边系数'},
              {k:'noiseFactor', min:0, max:0.2, step:0.005, label:'径向形变强度'},
              {k:'edgeAlphaThresh', min:0, max:32, step:1, label:'掩膜边缘阈值'},
              {k:'edgeExponent', min:1.0, max:2.5, step:0.05, label:'掩膜边缘幂'},
              {k:'radiusFactor', min:0.01, max:0.12, step:0.001, label:'点击半径系数'},
              {k:'minRadius', min:5, max:120, step:1, label:'最小点击半径(px)'},
            ] as Array<{k: keyof typeof glowCfg, min:number, max:number, step:number, label:string}>).map(({k,min,max,step,label}) => (
              <div key={k as string} className="mb-2">
                <label className="text-xs flex justify-between">
                  <span>{label}</span>
                  <span className="opacity-80">{(glowCfg as any)[k]}</span>
                </label>
                <input type="range" min={min} max={max} step={step}
                  value={(glowCfg as any)[k] as any}
                  onChange={(e)=>{ const v = Number(e.target.value); setGlowCfg(prev=> ({...prev, [k]: v})); }}
                  className="w-full" />
              </div>
            ))}
          </div>
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
          {structureColoring && (
            <div className="mt-3">
              <div className="text-xs opacity-80 mb-2">颜色波动（仅显示，不改算法）</div>
              {([
                {k:'colorJitterHue', min:0, max:30, step:1, label:'色相抖动(°)'},
                {k:'colorJitterSat', min:0, max:0.3, step:0.01, label:'饱和度抖动'},
                {k:'colorJitterLight', min:0, max:0.3, step:0.01, label:'亮度抖动'},
                {k:'colorNoiseScale', min:0.005, max:0.2, step:0.005, label:'颜色噪声尺度'},
              ] as Array<{k:keyof typeof defaultParams, min:number,max:number,step:number,label:string}>).map(({k,min,max,step,label}) => (
                <div key={k as string} className="mb-2">
                  <label className="text-xs flex justify-between">
                    <span>{label}</span>
                    <span className="opacity-80">{(params as any)[k]}</span>
                  </label>
                  <input type="range" min={min} max={max} step={step}
                    value={(params as any)[k] as any}
                    onChange={(e)=>{ const v=Number(e.target.value); setParams(prev=> ({...prev, [k]: v} as typeof prev)); }}
                    className="w-full" />
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </>
  );
};

export default InteractiveGalaxyBackground;
