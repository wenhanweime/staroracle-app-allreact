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

// 计算在给定半径下各臂中心点位置（用于最近臂距离估计）
export function getArmPositions(radius:number, cx:number, cy:number, p:GalaxyParams){
  const positions: Array<{ x:number; y:number; theta:number; armIndex:number }> = []
  const a = Math.log(Math.max(radius, p.spiralA) / p.spiralA) / p.spiralB
  for (let arm = 0; arm < p.armCount; arm++) {
    const armOffset = (arm * 2 * Math.PI) / p.armCount
    const theta = armOffset - a
    positions.push({ x: cx + radius * Math.cos(theta), y: cy + radius * Math.sin(theta), theta, armIndex: arm })
  }
  return positions
}

// 计算点到最近旋臂的信息（距离/是否在臂上/臂宽/臂角度）
export function getArmInfo(x:number, y:number, cx:number, cy:number, maxRadius:number, p:GalaxyParams){
  const dx = x - cx
  const dy = y - cy
  const radius = Math.sqrt(dx*dx + dy*dy)
  if (radius < 3) return { distance: 0, armIndex: 0, radius, inArm: true, armWidth: 0, theta: 0 }
  const positions = getArmPositions(radius, cx, cy, p)
  let minDistance = Infinity
  let nearestArmIndex = 0
  let nearestArmTheta = 0
  for (let i=0;i<positions.length;i++){
    const pos = positions[i]
    const d = Math.hypot(x - pos.x, y - pos.y)
    if (d < minDistance){ minDistance = d; nearestArmIndex = i; nearestArmTheta = pos.theta }
  }
  const armWidth = getArmWidth(radius, maxRadius, p)
  const inArm = minDistance < armWidth
  return { distance: minDistance, armIndex: nearestArmIndex, radius, inArm, armWidth, theta: nearestArmTheta }
}

// 臂密度剖面与大小（返回 profile 以便抖动/着色）
export function calculateArmDensityProfile(armInfo: ReturnType<typeof getArmInfo>, p:GalaxyParams){
  const { distance, armWidth } = armInfo
  const profile = Math.exp(-0.5 * Math.pow(distance / (armWidth / p.armTransitionSoftness), 2))
  const totalDensity = p.interArmDensity + p.armDensity * profile
  let size:number
  if (profile > 0.1){
    size = p.armBaseSizeMin + (p.armBaseSizeMax - p.armBaseSizeMin) * profile
    if (profile > 0.7 && Math.random() < p.armHighlightProb) size = p.armHighlightSize
    size *= p.armStarSizeMultiplier
  } else {
    size = p.interArmSizeMin + (p.interArmSizeMax - p.interArmSizeMin) * Math.random()
    size *= p.interArmStarSizeMultiplier
  }
  return { density: totalDensity, size, profile }
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

// 新的数据层：基于蒙特卡洛接受-拒绝采样的星场生成（与原 Canvas 形态更接近）
export function generateStarField(opts:{
  w:number; h:number; scale:number; rings?:number; seed?:number;
  params: GalaxyParams; palette: Palette; structureColoring:boolean
}): StarOut[] {
  const { w, h, scale, params: p, palette: pal, structureColoring } = opts
  const rng = seeded(opts.seed ?? 0xA17C9E3)
  const cx = w/2, cy = h/2
  const maxR = Math.min(w,h) * 0.4 * (scale||1)
  const decay = radialDecayFn(p)
  const rings = Math.max(3, Math.min(16, opts.rings ?? 10))

  const target = Math.max(800, Math.min(2200, Math.floor((w*h)/2800)))
  const stars: StarOut[] = []
  let attempts = 0, maxAttempts = target * 10
  while(stars.length < target && attempts++ < maxAttempts){
    // 盘内均匀采样
    const u = rng(); const v = rng()
    const r = Math.sqrt(u) * maxR
    const t = v * 2*Math.PI
    let x = cx + r*Math.cos(t)
    let y = cy + r*Math.sin(t)

    const baseDecay = decay(r, maxR)
    const armInfo = getArmInfo(x, y, cx, cy, maxR, p)
    const { density: armDensity, size: baseSize, profile } = calculateArmDensityProfile(armInfo, p)

    let density:number
    let size:number
    if (r < p.coreRadius){
      const coreProfile = Math.exp(-Math.pow(r / p.coreRadius, 1.5))
      density = p.coreDensity * coreProfile * baseDecay
      size = (p.coreSizeMin + rng() * (p.coreSizeMax - p.coreSizeMin)) * p.armStarSizeMultiplier
    } else {
      const n = noise2D(x * p.densityNoiseScale, y * p.densityNoiseScale)
      let modulation = 1.0 - p.densityNoiseStrength * (0.5 * (1.0 - n))
      if (modulation < 0.0) modulation = 0.0
      density = armDensity * baseDecay * modulation
      size = baseSize
    }
    density *= 0.8 + rng()*0.4
    if (rng() < density){
      // 与 Canvas 同向的沿臂法线抖动（高斯）
      const pitchAngle = Math.atan(1 / p.spiralB)
      const jitterAngle = armInfo.theta + pitchAngle + Math.PI/2
      const r1 = rng() || 1e-6
      const r2 = rng()
      const gaussian = Math.sqrt(-2.0 * Math.log(r1)) * Math.cos(2.0*Math.PI*r2)
      const chaos = 1 + (p.jitterChaos||0) * noise2D(x*(p.jitterChaosScale||0.02), y*(p.jitterChaosScale||0.02))
      const randomMix = 0.7 + 0.6*rng()
      const jitterAmount = p.jitterStrength * chaos * randomMix * profile * gaussian
      x += jitterAmount * Math.cos(jitterAngle)
      y += jitterAmount * Math.sin(jitterAngle)

      // 环分配（差速旋转用）
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

// 网格法（接近最早 Canvas 管线的结构分布，力求 1:1 形态）
export function generateStarFieldGrid(opts:{
  w:number; h:number; scale:number; rings?:number; seed?:number;
  params: GalaxyParams; palette: Palette; structureColoring:boolean
}): StarOut[] {
  const { w, h, scale, params: p, palette: pal, structureColoring } = opts
  const rng = seeded(opts.seed ?? 0xA17C9E3)
  const cx = w/2, cy = h/2
  const maxR = Math.min(w,h) * 0.4 // 与旧版保持一致
  const decay = radialDecayFn(p)
  const rings = Math.max(3, Math.min(16, opts.rings ?? 10))
  const step = 1.0 // 与旧版 getStep() 对齐

  // 目标星数：与早期实现一致的数量级，避免 DOM 节点爆炸
  const target = Math.max(600, Math.min(1800, Math.floor((w*h)/3500)))
  const reservoir: StarOut[] = []
  let accepted = 0
  for (let x = 0; x < w; x += step){
    for (let y = 0; y < h; y += step){
      const dx = x - cx
      const dy = y - cy
      const radius = Math.hypot(dx, dy)
      if (radius < 3) continue

      const baseDecay = decay(radius, maxR)
      const armInfo = getArmInfo(x, y, cx, cy, maxR, p)
      const { density: armDensity, size: baseSize, profile } = calculateArmDensityProfile(armInfo, p)

      let density:number
      let size:number
      if (radius < p.coreRadius){
        const coreProfile = Math.exp(-Math.pow(radius / p.coreRadius, 1.5))
        density = p.coreDensity * coreProfile * baseDecay
        size = (p.coreSizeMin + rng() * (p.coreSizeMax - p.coreSizeMin)) * p.armStarSizeMultiplier
      } else {
        const n = noise2D(x * p.densityNoiseScale, y * p.densityNoiseScale)
        let modulation = 1.0 - p.densityNoiseStrength * (0.5 * (1.0 - n))
        if (modulation < 0.0) modulation = 0.0
        density = armDensity * baseDecay * modulation
        size = baseSize
      }

      density *= 0.8 + rng()*0.4 // 旧版的随机浮动
      if (rng() < density){
        let ox = x, oy = y
        if (profile > 0.001){
          const pitchAngle = Math.atan(1 / p.spiralB)
          const jitterAngle = armInfo.theta + pitchAngle + Math.PI/2
          const r1 = rng() || 1e-6
          const r2 = rng()
          const gaussian = Math.sqrt(-2.0 * Math.log(r1)) * Math.cos(2.0*Math.PI*r2)
          const chaos = 1 + (p.jitterChaos||0) * noise2D(x*(p.jitterChaosScale||0.02), y*(p.jitterChaosScale||0.02))
          const randomMix = 0.7 + 0.6*rng()
          const jitterAmount = p.jitterStrength * chaos * randomMix * profile * gaussian
          ox += jitterAmount * Math.cos(jitterAngle)
          oy += jitterAmount * Math.sin(jitterAngle)
        }
        // 轻微破格抖动以打破网格感
        ox += (rng() - 0.5) * step
        oy += (rng() - 0.5) * step

        const rNow = Math.hypot(ox - cx, oy - cy)
        const ring = Math.min(rings-1, Math.max(0, Math.floor((rNow/maxR) * rings)))
        let color = '#FFFFFF'
        if (structureColoring){
          if (radius < p.coreRadius) color = pal.core
          else if (profile > 0.7) color = pal.ridge
          else if (profile > 0.5) color = pal.armBright
          else if (profile > 0.25) color = pal.armEdge
          else color = pal.dust
        }
        const cand: StarOut = { x: ox, y: oy, r: rNow, size, ring, color }
        accepted++
        if (reservoir.length < target){
          reservoir.push(cand)
        } else {
          const j = Math.floor(rng() * accepted)
          if (j < target) reservoir[j] = cand
        }
      }
    }
  }
  return reservoir
}
