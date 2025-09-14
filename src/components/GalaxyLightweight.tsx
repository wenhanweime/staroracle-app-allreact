import React, { useEffect, useMemo, useRef, useState } from 'react'
import { generateStarFieldGrid, GalaxyParams, Palette } from '../utils/galaxyModel'
import { UNIFORM_DEG_PER_MS, fullRotationSeconds } from '../utils/rotationConfig'

interface LayerAlpha { core:number; ridge:number; armBright:number; armEdge:number; dust:number; outer:number }

interface Props {
  params: GalaxyParams
  palette: Palette
  layerAlpha?: LayerAlpha
  structureColoring?: boolean
  armCount?: number
  scale?: number
  onBandPointsReady?: (pts: Array<{x:number;y:number;size:number;band:number;bw:number;bh:number}>)=>void
  onBgPointsReady?: (pts: Array<{x:number;y:number;size:number}>)=>void
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

const GalaxyLightweight: React.FC<Props> = ({ params, palette, layerAlpha, structureColoring=true, armCount=5, scale=0.6, onBandPointsReady, onBgPointsReady }) => {
  const rootRef = useRef<HTMLDivElement|null>(null)
  const [dims, setDims] = useState({w:0,h:0})
  useEffect(()=>{
    const onResize=()=>{
      setDims({ w: window.innerWidth, h: window.innerHeight })
    }
    onResize(); window.addEventListener('resize', onResize)
    return ()=> window.removeEventListener('resize', onResize)
  },[])

  const {stars, ringCount, bgStars} = useMemo(()=>{
    const w = dims.w, h = dims.h; if(!w||!h) return {stars:[], ringCount:0, bgStars:[]}
    const p: GalaxyParams = { ...params, armCount: armCount||params.armCount }
    const pal: Palette = palette
    const dpr = (window.devicePixelRatio || 1)
    const isMobile = (typeof window !== 'undefined' && window.matchMedia && window.matchMedia('(pointer: coarse)').matches) || Math.min(w,h) < 820
    // Mobile comfort v3: ensure visible spiral arms
    const sizeScale = isMobile ? 1.40 : 1.0
    // Double overall galaxy density; mobile keeps regional scaling to preserve arms
    const densityScale = 2.0
    const densityArmScale = isMobile ? 1.35 : 1.0
    const densityInterScale = isMobile ? 0.80 : 1.0
    const p2: GalaxyParams = {
      ...p,
      armStarSizeMultiplier: (p.armStarSizeMultiplier || 1) * sizeScale,
      interArmStarSizeMultiplier: (p.interArmStarSizeMultiplier || 1) * sizeScale,
      backgroundStarSizeMultiplier: (p.backgroundStarSizeMultiplier || 1) * (isMobile ? 1.20 : 1.0),
      backgroundDensity: (p.backgroundDensity || 0) * (isMobile ? 0.85 : 1.0),
      // thicken arms slightly on mobile (device-pixel widths under DPR)
      armWidthInner: isMobile ? Math.round((p.armWidthInner || 29) * 1.15) : p.armWidthInner,
      armWidthOuter: isMobile ? Math.round((p.armWidthOuter || 65) * 1.22) : p.armWidthOuter,
    }
    // Compute an explicit star cap for mobile to reduce DOM nodes
    const area = w*h
    const baseTarget = Math.max(600, Math.min(1800, Math.floor(area/3500)))
    // Raise mobile cap to allow ~2x stars overall (compared to previous comfort setting)
    const starCap = isMobile ? Math.min(4000, Math.max(1800, Math.floor(baseTarget * 3.2))) : undefined
    const fullDensity = !isMobile
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
    if (onBandPointsReady){
      const out:Array<{x:number;y:number;size:number;band:number;bw:number;bh:number}> = []
      for(const s of arr){ out.push({ x:s.x, y:s.y, size:s.size, band:s.ring, bw: w, bh: h }) }
      onBandPointsReady(out)
    }
    // 背景小星（不旋转）
    // 背景小星（不旋转）：使用种子 RNG + reducedMotion 因子，与稳定版一致
    const reduced = typeof window !== 'undefined' && window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches
    const seed = 0xBADC0DE
    let rand = (function(seed:number){ let t=seed>>>0; return ()=>{ t += 0x6D2B79F5; let r=Math.imul(t^(t>>>15),1|t); r^=r+Math.imul(r^(r>>>7),61|r); return ((r^(r>>>14))>>>0)/4294967296 } })(seed)
    const bgCount = Math.floor((w*h) * (p2.backgroundDensity || 0) * (reduced ? 0.6 : 1) * (isMobile ? 0.85 : 1))
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
    return { stars: colored.map((s:any)=>({x:s.x,y:s.y,size:s.size,color:s.color, ring:s.ring})), ringCount: rings, bgStars: bg }
  }, [dims.w, dims.h, armCount, scale, structureColoring, onBandPointsReady, onBgPointsReady, params, palette, layerAlpha])

  // CSS 动画：每个 ring 不同速度（与半径相关的差速旋转）
  const ringDur = (_idx:number)=>{
    // 统一速度：所有环相同周期，与 DOM 脉冲叠加保持一致
    return `${fullRotationSeconds()}s`
  }

  return (
    <div ref={rootRef} className="absolute inset-0 pointer-events-none" style={{ zIndex: 1 }}>
      {/* 缩放容器：仅缩放银河环，不缩放背景星 */}
      <div
        style={{ position:'absolute', inset:0, transformOrigin:'50% 50%', transform: `scale(${scale||1})` }}
      >
      {Array.from({length:ringCount}).map((_,ri)=> (
        <div key={ri}
          style={{
            position:'absolute', inset:0,
            transformOrigin:'50% 50%',
            animation: `glx-rot ${ringDur(ri)} linear infinite`
          }}
        >
          {stars.filter(s=>s.ring===ri).map((s,idx)=> (
            <div key={ri+'-'+idx}
              style={{
                position:'absolute', left: s.x, top: s.y, transform:'translate(-50%,-50%)',
                width: `${s.size}px`, height: `${s.size}px`, borderRadius:'50%',
                background: s.color,
                boxShadow: `0 0 6px ${s.color}AA, 0 0 12px ${s.color}66`,
                opacity: 0.95
              }}/>
          ))}
        </div>
      ))}
      </div>
      {/* 背景小星（不旋转） */}
      {bgStars && bgStars.map((b, i)=> (
        <div
          key={'bg-'+i}
          style={{
            position:'absolute',
            left: b.x,
            top: b.y,
            transform:'translate(-50%,-50%)',
            width:`${b.size}px`,
            height:`${b.size}px`,
            borderRadius:'50%',
            background:'#CCCCCC',
            opacity:0.85
          }}
        />
      ))}
      <style>{`
        @keyframes glx-rot { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
      `}</style>
    </div>
  )
}

export default GalaxyLightweight
