import React, { useEffect, useMemo, useRef, useState } from 'react'
import { generateStarField, GalaxyParams, Palette } from '../utils/galaxyModel'

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
    const arr = generateStarField({ w, h, scale: scale||1, rings: 10, params: p, palette: pal, structureColoring })
    const rings = (arr.length ? (Math.max(...arr.map(s=>s.ring)) + 1) : 0)
    if (onBandPointsReady){
      const out:Array<{x:number;y:number;size:number;band:number;bw:number;bh:number}> = []
      for(const s of arr){ out.push({ x:s.x, y:s.y, size:s.size, band:s.ring, bw: w, bh: h }) }
      onBandPointsReady(out)
    }
    // 背景小星（不旋转）
    const bgCount = Math.floor((w*h) * (p.backgroundDensity || 0))
    const bg: Array<{x:number;y:number;size:number}> = []
    for(let i=0;i<bgCount;i++){
      const x = Math.random()*w
      const y = Math.random()*h
      const r1 = Math.random(), r2 = Math.random()
      let size = r1 < 0.85 ? 0.8 : (r2 < 0.9 ? 1.2 : (p.backgroundSizeVariation||2.0))
      size *= (p.backgroundStarSizeMultiplier || 0.7)
      bg.push({ x,y,size })
    }
    onBgPointsReady && onBgPointsReady(bg)
    return { stars: arr.map(s=>({x:s.x,y:s.y,size:s.size,color:s.color, ring:s.ring} as any)), ringCount: rings, bgStars: bg }
  }, [dims.w, dims.h, armCount, scale, structureColoring, onBandPointsReady, onBgPointsReady, params, palette, layerAlpha])

  // CSS 动画：每个 ring 不同速度（与半径相关的差速旋转）
  const ringDur = (idx:number)=>{
    const base = 80 // 秒，外圈更慢，内圈更快
    const rc = Math.max(1, ringCount)
    return `${Math.max(12, base*(0.25 + idx/rc))}s`
  }

  return (
    <div ref={rootRef} className="absolute inset-0 pointer-events-none" style={{ zIndex: 1 }}>
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
