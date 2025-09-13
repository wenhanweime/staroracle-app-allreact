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
    // Mobile comfort v2: increase visibility of arms while keeping total lighter
    const sizeScale = isMobile ? 1.32 : 1.0
    const densityScale = isMobile ? 0.85 : 1.0
    const densityArmScale = isMobile ? 1.15 : 1.0
    const densityInterScale = isMobile ? 0.70 : 1.0
    const p2: GalaxyParams = {
      ...p,
      armStarSizeMultiplier: (p.armStarSizeMultiplier || 1) * sizeScale,
      interArmStarSizeMultiplier: (p.interArmStarSizeMultiplier || 1) * sizeScale,
      backgroundStarSizeMultiplier: (p.backgroundStarSizeMultiplier || 1) * (isMobile ? 1.18 : 1.0),
      backgroundDensity: (p.backgroundDensity || 0) * (isMobile ? 0.80 : 1.0),
    }
    // Compute an explicit star cap for mobile to reduce DOM nodes
    const area = w*h
    const baseTarget = Math.max(600, Math.min(1800, Math.floor(area/3500)))
    const starCap = isMobile ? Math.max(500, Math.floor(baseTarget * 0.80)) : undefined
    const fullDensity = !isMobile
    const arr = generateStarFieldGrid({ w, h, dpr, scale: scale||1, rings: 10, params: p2, palette: pal, structureColoring, fullDensity, densityScale, starCap, densityArmScale, densityInterScale })
    const rings = (arr.length ? (Math.max(...arr.map(s=>s.ring)) + 1) : 0)
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
    return { stars: arr.map(s=>({x:s.x,y:s.y,size:s.size,color:s.color, ring:s.ring} as any)), ringCount: rings, bgStars: bg }
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
