export type GalaxyRegion = 'emotion' | 'relation' | 'growth'

export interface GalaxyParams {
  coreDensity: number
  coreRadius: number
  coreSizeMin: number
  coreSizeMax: number
  armCount: number
  armDensity: number
  armBaseSizeMin: number
  armBaseSizeMax: number
  armHighlightSize: number
  armHighlightProb: number
  spiralA: number
  spiralB: number
  armWidthInner: number
  armWidthOuter: number
  armWidthGrowth: number
  armTransitionSoftness: number
  fadeStartRadius: number
  fadeEndRadius: number
  outerDensityMaintain: number
  interArmDensity: number
  interArmSizeMin: number
  interArmSizeMax: number
  radialDecay: number
  backgroundDensity: number
  backgroundSizeVariation: number
  jitterStrength: number
  densityNoiseScale: number
  densityNoiseStrength: number
  jitterChaos: number
  jitterChaosScale: number
  armStarSizeMultiplier: number
  interArmStarSizeMultiplier: number
  backgroundStarSizeMultiplier: number
}

export interface Palette {
  core: string
  ridge: string
  armBright: string
  armEdge: string
  dust: string
  outer: string
}

export interface StarOut { x:number; y:number; r:number; size:number; ring:number; color:string }

// Deterministic RNG
export function seeded(seed: number){
  let t = seed >>> 0
  return ()=>{
    t += 0x6D2B79F5
    let r = Math.imul(t ^ (t>>>15), 1|t)
    r ^= r + Math.imul(r ^ (r>>>7), 61|r)
    return ((r ^ (r>>>14)) >>> 0) / 4294967296
  }
}

const fract = (n:number)=> n - Math.floor(n)
export const noise2D = (x:number,y:number)=>{
  const t = Math.sin(x*12.9898 + y*78.233) * 43758.5453123
  return fract(t) * 2 - 1 // [-1,1]
}

export function getArmWidth(radius:number, maxRadius:number, p:GalaxyParams){
  const progress = Math.min(radius / (maxRadius * 0.8), 1)
  return p.armWidthInner + (p.armWidthOuter - p.armWidthInner) * Math.pow(progress, p.armWidthGrowth)
}

export function getFadeFactor(radius:number, maxRadius:number, p:GalaxyParams){
  const fadeStart = maxRadius * p.fadeStartRadius
  const fadeEnd = maxRadius * p.fadeEndRadius
  if (radius < fadeStart) return 1
  if (radius > fadeEnd) return 0
  const progress = (radius - fadeStart) / (fadeEnd - fadeStart)
  return 0.5 * (1 + Math.cos(progress * Math.PI))
}

export function radialDecayFn(p:GalaxyParams){
  return (radius:number, maxRadius:number)=>{
    const base = Math.exp(-radius * p.radialDecay)
    const fade = getFadeFactor(radius, maxRadius, p)
    const maintain = p.outerDensityMaintain
    return Math.max(base * fade, maintain * fade)
  }
}

export function spiralTheta(r:number, p:GalaxyParams, armOffset:number){
  const a = Math.log(Math.max(r, p.spiralA) / p.spiralA) / p.spiralB
  return armOffset - a // 与 Canvas 保持一致
}

export function buildGalaxyStars(opts:{
  w:number; h:number; scale:number; rings?:number; seed?:number;
  params: GalaxyParams; palette: Palette; structureColoring:boolean
}): StarOut[] {
  const {w,h,scale, params:p, palette:pal, structureColoring} = opts
  const rng = seeded(opts.seed ?? 0xA17C9E3)
  const cx = w/2, cy = h/2
  const maxR = Math.min(w,h) * 0.4 * (scale||1)
  const decay = radialDecayFn(p)
  const rings = Math.max(3, Math.min(8, opts.rings ?? 5))

  // 目标数：与画布面积和密度粗估成正比
  const target = Math.max(600, Math.min(1400, Math.floor((w*h)/3500)))
  const stars: StarOut[] = []
  let attempts = 0, maxAttempts = target * 8
  while(stars.length < target && attempts++ < maxAttempts){
    // 在圆形内均匀采样（面积均匀）
    const u = rng(); const v = rng()
    const r = Math.sqrt(u) * maxR
    const phiArm = (Math.floor(rng()*p.armCount) * 2*Math.PI / p.armCount)
    const theta = spiralTheta(r, p, phiArm)
    let x = cx + r*Math.cos(theta)
    let y = cy + r*Math.sin(theta)

    // 最近臂形状信息（近似）：距臂中心线的距离 ~ 0（已按臂生成），使用臂宽来调 profile
    const armWidth = getArmWidth(r, maxR, p)
    const profile = Math.exp(-0.5 * Math.pow(0 / (armWidth / p.armTransitionSoftness), 2)) // 近似中心线处 ~1
    const baseDecay = decay(r, maxR)

    let density:number, size:number
    if (r < p.coreRadius){
      const coreProfile = Math.exp(-Math.pow(r / p.coreRadius, 1.5))
      density = p.coreDensity * coreProfile * baseDecay
      size = (p.coreSizeMin + rng() * (p.coreSizeMax - p.coreSizeMin)) * p.armStarSizeMultiplier
    } else {
      const n = noise2D(x * p.densityNoiseScale, y * p.densityNoiseScale)
      let modulation = 1.0 - p.densityNoiseStrength * (0.5 * (1.0 - n))
      if (modulation < 0.0) modulation = 0.0
      density = (p.interArmDensity + p.armDensity * profile) * baseDecay * modulation
      if (profile > 0.1){
        size = p.armBaseSizeMin + (p.armBaseSizeMax - p.armBaseSizeMin) * profile
        if (profile > 0.7 && rng() < p.armHighlightProb) size = p.armHighlightSize
        size *= p.armStarSizeMultiplier
      } else {
        size = p.interArmSizeMin + (p.interArmSizeMax - p.interArmSizeMin) * rng()
        size *= p.interArmStarSizeMultiplier
      }
    }
    density *= 0.8 + rng()*0.4
    if (rng() < density){
      // 抖动：沿臂法线方向
      const pitchAngle = Math.atan(1 / p.spiralB)
      const jitterAngle = theta + pitchAngle + Math.PI/2
      const rand1 = rng() || 1e-6
      const rand2 = rng()
      const gaussian = Math.sqrt(-2.0 * Math.log(rand1)) * Math.cos(2.0*Math.PI*rand2)
      const chaos = 1 + (p.jitterChaos||0) * noise2D(x*(p.jitterChaosScale||0.02), y*(p.jitterChaosScale||0.02))
      const randomMix = 0.7 + 0.6*rng()
      const jitterAmount = p.jitterStrength * chaos * randomMix * profile * gaussian
      x += jitterAmount * Math.cos(jitterAngle)
      y += jitterAmount * Math.sin(jitterAngle)

      const ring = Math.min(rings-1, Math.max(0, Math.floor((r/maxR) * rings)))
      let color = '#FFFFFF'
      if (structureColoring){
        if (r < p.coreRadius) color = pal.core
        else if (profile > 0.7) color = pal.ridge
        else if (profile > 0.5) color = pal.armBright
        else if (profile > 0.25) color = pal.armEdge
        else color = pal.dust
      }
      stars.push({ x, y, r, size, ring, color })
    }
  }
  return stars
}
