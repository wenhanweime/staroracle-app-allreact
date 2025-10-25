import React, { useEffect, useMemo, useRef, useState } from 'react'
import { generateStarFieldGrid, GalaxyParams, Palette } from '../utils/galaxyModel'
import { UNIFORM_DEG_PER_MS, fullRotationSeconds } from '../utils/rotationConfig'
import { useStableViewportSize } from '../hooks/useStableViewportSize'

interface LayerAlpha { core:number; ridge:number; armBright:number; armEdge:number; dust:number; outer:number }

interface PersistentHighlight {
  id: string
  band: number
  x: number
  y: number
  size: number
  color?: string
  litColor?: string
}

interface Props {
  params: GalaxyParams
  palette: Palette
  litPalette?: Palette
  layerAlpha?: LayerAlpha
  structureColoring?: boolean
  armCount?: number
  scale?: number
  onBandPointsReady?: (pts: Array<{id:string;x:number;y:number;size:number;band:number;bw:number;bh:number;color?:string;litColor?:string}>)=>void
  onBgPointsReady?: (pts: Array<{x:number;y:number;size:number}>)=>void
  persistentHighlights?: PersistentHighlight[]
}

// Simple noise
const noise2D = (x:number,y:number)=>{
  const t = Math.sin(x*12.9898 + y*78.233) * 43758.5453123
  return t - Math.floor(t)
}

// Color helpers for HSL jitter
const clamp01 = (v:number)=> Math.max(0, Math.min(1, v))
const hexToRgb = (hex:string)=>{
  const h = hex.replace('#','')
  const full = h.length===3? h.split('').map(c=>c+c).join('') : h
  const num = parseInt(full,16)
  return { r: (num>>16)&255, g: (num>>8)&255, b: num&255 }
}
const rgbToHsl = (r:number,g:number,b:number)=>{
  r/=255; g/=255; b/=255
  const max = Math.max(r,g,b), min = Math.min(r,g,b)
  let h=0,s=0; const l=(max+min)/2
  if (max!==min){
    const d = max-min
    s = l>0.5? d/(2-max-min) : d/(max+min)
    switch(max){
      case r: h=(g-b)/d+(g<b?6:0); break
      case g: h=(b-r)/d+2; break
      default: h=(r-g)/d+4
    }
    h/=6
  }
  return { h:h*360, s, l }
}
const hslToRgb = (h:number,s:number,l:number)=>{
  h/=360
  const hue2rgb=(p:number,q:number,t:number)=>{
    if(t<0) t+=1; if(t>1) t-=1
    if(t<1/6) return p+(q-p)*6*t
    if(t<1/2) return q
    if(t<2/3) return p+(q-p)*(2/3-t)*6
    return p
  }
  let r:number,g:number,b:number
  if(s===0){ r=g=b=l }
  else{
    const q = l<0.5? l*(1+s) : l+s-l*s
    const p = 2*l - q
    r = hue2rgb(p,q,h+1/3)
    g = hue2rgb(p,q,h)
    b = hue2rgb(p,q,h-1/3)
  }
  return { r:Math.round(r*255), g:Math.round(g*255), b:Math.round(b*255) }
}
const rgbToHex = (r:number,g:number,b:number)=> '#'+[r,g,b].map(v=>Math.max(0,Math.min(255,v)).toString(16).padStart(2,'0')).join('')
const hexToHsl = (hex:string)=>{ const {r,g,b}=hexToRgb(hex); return rgbToHsl(r,g,b) }
const hslToHex = (h:number,s:number,l:number)=>{ const {r,g,b}=hslToRgb(h,s,l); return rgbToHex(r,g,b) }
const normalizeHex = (hex: unknown) => {
  if (!hex && hex !== 0) return '#FFFFFF'
  let value = typeof hex === 'string' ? hex.trim() : String(hex).trim()
  if (!value.startsWith('#')) return '#FFFFFF'
  if (value.length === 4) {
    value = `#${value[1]}${value[1]}${value[2]}${value[2]}${value[3]}${value[3]}`
  }
  if (value.length !== 7) return '#FFFFFF'
  return value.toUpperCase()
}
const GalaxyLightweight: React.FC<Props> = ({ params, palette, litPalette, layerAlpha, structureColoring=true, armCount=5, scale=0.6, onBandPointsReady, onBgPointsReady, persistentHighlights = [] }) => {
  const rootRef = useRef<HTMLDivElement|null>(null)
  const { width: viewportWidth, height: viewportHeight } = useStableViewportSize()
  const dims = { w: viewportWidth, h: viewportHeight }
  const containerHeight = dims.h || (typeof window !== 'undefined' ? window.innerHeight : 0)
  const heightStyle = containerHeight ? `${containerHeight}px` : '100vh'

  const {stars, ringCount, bgStars} = useMemo(()=>{
    const w = dims.w, h = dims.h; if(!w||!h) return {stars:[], ringCount:0, bgStars:[]}
    const p: GalaxyParams = { ...params, armCount: armCount||params.armCount }
    const pal: Palette = palette
    const dpr = (window.devicePixelRatio || 1)
    const isMobile = (typeof window !== 'undefined' && window.matchMedia && window.matchMedia('(pointer: coarse)').matches) || Math.min(w,h) < 820
    // Strict parity mode to match baseline tag semantics (no mobile comfort scaling)
    const strictParity = true
    const sizeScale = strictParity ? 1.0 : (isMobile ? 1.40 : 1.0)
    const densityScale = strictParity ? 1.0 : 2.0
    const densityArmScale = strictParity ? 1.0 : (isMobile ? 1.35 : 1.0)
    const densityInterScale = strictParity ? 1.0 : (isMobile ? 0.80 : 1.0)
    let p2: GalaxyParams = strictParity ? p : {
      ...p,
      armStarSizeMultiplier: (p.armStarSizeMultiplier || 1) * sizeScale,
      interArmStarSizeMultiplier: (p.interArmStarSizeMultiplier || 1) * sizeScale,
      backgroundStarSizeMultiplier: (p.backgroundStarSizeMultiplier || 1) * (isMobile ? 1.20 : 1.0),
      backgroundDensity: (p.backgroundDensity || 0) * (isMobile ? 0.85 : 1.0),
      armWidthInner: isMobile ? Math.round((p.armWidthInner || 29) * 2.0) : p.armWidthInner,
      armWidthOuter: isMobile ? Math.round((p.armWidthOuter || 65) * 2.0) : p.armWidthOuter,
      armTransitionSoftness: isMobile ? Math.max(1, (p.armTransitionSoftness || 5.2) * 1.25) : p.armTransitionSoftness,
      jitterStrength: isMobile ? Math.max(8, Math.round((p.jitterStrength || 10) * 1.4)) : p.jitterStrength,
    }
    // 全端提升旋臂星点尺寸（仅臂区 multiplier），不影响臂间与背景
    p2 = {
      ...p2,
      armStarSizeMultiplier: (p2.armStarSizeMultiplier || 1) * 1.2,
    }
    // iOS 专项提升：增加臂间星点尺寸（更易见）
    const isIOS = typeof navigator !== 'undefined' && /iP(ad|hone|od)/.test(navigator.userAgent)
    if (isIOS) {
      p2 = {
        ...p2,
        interArmStarSizeMultiplier: (p2.interArmStarSizeMultiplier || 1) * 1.35,
        interArmSizeMin: Math.max(0.4, (p2.interArmSizeMin || 0.6) * 1.25),
        interArmSizeMax: Math.max((p2.interArmSizeMin || 0.6), (p2.interArmSizeMax || 1.2) * 1.25),
      }
    }
    const starCap = strictParity ? undefined : (isMobile ? (()=>{ const area=w*h; const baseTarget = Math.max(600, Math.min(1800, Math.floor(area/3500))); return Math.min(4000, Math.max(1800, Math.floor(baseTarget * 3.2))) })() : undefined)
    const fullDensity = strictParity ? true : !isMobile
    const arr = generateStarFieldGrid({ w, h, dpr, scale: scale||1, rings: 10, params: p2, palette: pal, structureColoring, fullDensity, densityScale, starCap, densityArmScale, densityInterScale })
    const rings = (arr.length ? (Math.max(...arr.map(s=>s.ring)) + 1) : 0)
    // Optional HSL jitter to approximate Canvas color variation
    let colored = arr as any
    if (structureColoring && arr.length){
      const scaleC = (params.colorNoiseScale ?? 0.05)
      const jHue = (params.colorJitterHue ?? 0)
      const jSat = (params.colorJitterSat ?? 0)
      const jLig = (params.colorJitterLight ?? 0)
      colored = arr.map(s=>{
        const base = s.color || '#FFFFFF'
        // 对 ridge（近白）不做抖动，保持纯白脊线
        if (base && palette && (base.toLowerCase() === (palette.ridge||'').toLowerCase() || base.toLowerCase() === '#f08cd3')) {
          return s
        }
        const hsl = hexToHsl(base)
        const nh = (noise2D(s.x*scaleC, s.y*scaleC)*2-1)
        const ns = (noise2D(s.x*scaleC+31.7, s.y*scaleC+11.3)*2-1)
        const nl = (noise2D(s.x*scaleC+77.1, s.y*scaleC+59.9)*2-1)
        const h = (hsl.h + nh*jHue + 360) % 360
        const s1 = clamp01(hsl.s + ns*jSat)
        const l1 = clamp01(hsl.l + nl*jLig)
        const hex = hslToHex(h, s1, l1)
        return { ...s, color: hex }
      })
    }
    const entries: Array<[keyof Palette, string]> = [
      ['core', (palette as any).core],
      ['ridge', (palette as any).ridge],
      ['armBright', (palette as any).armBright],
      ['armEdge', (palette as any).armEdge],
      ['hii', (palette as any).hii],
      ['dust', (palette as any).dust],
      ['outer', (palette as any).outer],
    ]
    const palMap: Record<string,string> = {}
    for (const [k, v] of entries){
      const base = normalizeHex(v)
      const lit = normalizeHex((litPalette as any)?.[k] || v)
      if (base && lit) palMap[base] = lit
    }
    const litCore = normalizeHex((litPalette as any)?.core || palette.core || '#FFE2B0')

    const stars = colored.map((s:any, idx:number)=>{
      const original = arr[idx] as any
      const baseOriginal = normalizeHex(original?.color || (s as any).color || '')
      const lit = baseOriginal ? (palMap[baseOriginal] || litCore) : litCore
      return {
        id: `s-${idx}`,
        x: s.x,
        y: s.y,
        size: s.size,
        color: s.color,
        ring: s.ring,
        litColor: lit
      }
    })

    if (onBandPointsReady){
      const out = stars.map(s => ({
        id: s.id,
        x: s.x,
        y: s.y,
        size: s.size,
        band: s.ring,
        bw: w,
        bh: h,
        color: s.color,
        litColor: s.litColor
      }))
      onBandPointsReady(out as any)
    }
    // 背景小星（不旋转）
    // 背景小星（不旋转）：使用种子 RNG + reducedMotion 因子，与稳定版一致
    const reduced = typeof window !== 'undefined' && window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches
    const seed = 0xBADC0DE
    let rand = (function(seed:number){ let t=seed>>>0; return ()=>{ t += 0x6D2B79F5; let r=Math.imul(t^(t>>>15),1|t); r^=r+Math.imul(r^(r>>>7),61|r); return ((r^(r>>>14))>>>0)/4294967296 } })(seed)
    const bgCount = Math.floor((w*h) * (p2.backgroundDensity || 0) * (reduced ? 0.6 : 1) * (strictParity ? 1 : (isMobile ? 0.85 : 1)))
    const bg: Array<{x:number;y:number;size:number}> = []
    for(let i=0;i<bgCount;i++){
      const x = rand()*w
      const y = rand()*h
      const r1 = rand(), r2 = rand()
      let size = r1 < 0.85 ? 0.8 : (r2 < 0.9 ? 1.2 : (p2.backgroundSizeVariation||2.0))
      size *= (p2.backgroundStarSizeMultiplier || 1.0)
      bg.push({ x,y,size })
    }
    onBgPointsReady && onBgPointsReady(bg)
    return { stars, ringCount: rings, bgStars: bg }
  }, [dims.w, dims.h, armCount, scale, structureColoring, onBandPointsReady, onBgPointsReady, params, palette, layerAlpha])

  // CSS 动画：每个 ring 不同速度（与半径相关的差速旋转）
  const ringDur = (_idx:number)=>{
    // 统一速度：所有环相同周期，与 DOM 脉冲叠加保持一致
    return `${fullRotationSeconds()}s`
  }

  const highlightMap = useMemo(() => {
    const map = new Map<string, string>()
    persistentHighlights.forEach(h => {
      const normalized = normalizeHex(h.color || h.litColor || '#FFE2B0')
      if (h.id) {
        map.set(h.id, normalized)
      }
    })
    return map
  }, [persistentHighlights])

  type GalaxyDomStar = (typeof stars)[number]
  const ringGroups = useMemo(() => {
    const groups: Record<number, GalaxyDomStar[]> = {}
    for (let i = 0; i < ringCount; i++) {
      groups[i] = []
    }
    stars.forEach(star => {
      if (!groups[star.ring]) {
        groups[star.ring] = []
      }
      groups[star.ring].push(star)
    })
    return groups
  }, [stars, ringCount])

  return (
    <div
      ref={rootRef}
      className="pointer-events-auto"
      style={{ position: 'fixed', top: 0, left: 0, width: '100%', height: heightStyle, zIndex: 1 }}
    >
      {/* 缩放容器：仅缩放银河环，不缩放背景星 */}
      <div
        style={{ position:'absolute', inset:0, transformOrigin:'50% 50%', transform: `scale(${scale||1})`, zIndex: 1 }}
      >
      {Array.from({length:ringCount}).map((_,ri)=> {
        const ringStars = ringGroups[ri] || []
        const neighborSpan = Math.max(1, Math.min(3, Math.floor(ringStars.length / 8) || 1))
        return (
        <div key={ri}
          style={{
            position:'absolute', inset:0,
            transformOrigin:'50% 50%',
            animation: `glx-rot ${ringDur(ri)} linear infinite`,
            pointerEvents: 'none'
          }}
        >
          {ringStars.map((s, idx, arr)=> {
            const highlightColor = highlightMap.get(s.id)
            const baseColor = highlightColor || s.color
            const zIndex = highlightColor ? 3 : 1
            const bandPoint = {
              id: s.id,
              band: s.ring,
              x: s.x,
              y: s.y,
              size: s.size,
              bw: dims.w,
              bh: dims.h,
              color: s.color,
              litColor: s.litColor
            }
            let neighborIds: string[] = []
            if (arr.length > 1) {
              const maxNeighbors = Math.min(arr.length - 1, neighborSpan * 2)
              for (let offset = 1; offset <= neighborSpan; offset++) {
                const forward = arr[(idx + offset) % arr.length]
                if (forward && neighborIds.length < maxNeighbors) {
                  neighborIds.push(forward.id)
                }
                const backward = arr[(idx - offset + arr.length) % arr.length]
                if (backward && neighborIds.length < maxNeighbors) {
                  neighborIds.push(backward.id)
                }
              }
            }
            const starInfo = {
              id: s.id,
              x: s.x,
              y: s.y,
              size: s.size,
              color: baseColor,
              litColor: s.litColor,
              source: { type: 'band', data: bandPoint }
            }
            const neighborAttr = neighborIds.length ? JSON.stringify(neighborIds) : undefined
            return (
              <div
                key={s.id}
                className="galaxy-star-node"
                data-star-id={s.id}
                data-star-info={JSON.stringify(starInfo)}
                data-star-neighbors={neighborAttr}
                style={{
                  position:'absolute', left: s.x, top: s.y, transform:'translate(-50%,-50%)',
                  width: `${s.size}px`, height: `${s.size}px`, borderRadius:'50%',
                  background: baseColor,
                  boxShadow: `0 0 6px ${baseColor}AA, 0 0 12px ${baseColor}66`,
                  opacity: 0.95,
                  zIndex,
                  pointerEvents: 'auto'
                }}/>
            )
          })}
        </div>
      )})}
      </div>
      {/* 背景小星（不旋转） */}
      {bgStars && bgStars.map((b, i)=> {
        const bgId = `bg-${i}`
        const starInfo = {
          id: bgId,
          x: b.x,
          y: b.y,
          size: b.size,
          color: '#CCCCCC',
          source: { type: 'bg', data: { id: bgId, x: b.x, y: b.y, size: b.size } }
        }
        return (
          <div
            key={bgId}
            className="galaxy-star-node"
            data-star-id={bgId}
            data-star-info={JSON.stringify(starInfo)}
            style={{
              position:'absolute',
              left: b.x,
              top: b.y,
              transform:'translate(-50%,-50%)',
              width:`${b.size}px`,
              height:`${b.size}px`,
              borderRadius:'50%',
              background:'#CCCCCC',
              opacity:0.85,
              zIndex: 0,
              pointerEvents: 'auto'
            }}
          />
        )
      })}
      <style>{`
        @keyframes glx-rot { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
      `}</style>
    </div>
  )
}

export default GalaxyLightweight
