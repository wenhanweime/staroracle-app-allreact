import React, { useEffect, useMemo, useRef, useState } from 'react'

type Star = { x:number; y:number; size:number; color:string; ring:number }

interface Props {
  structureColoring?: boolean
  armCount?: number
  scale?: number
  onBandPointsReady?: (pts: Array<{x:number;y:number;size:number;band:number;bw:number;bh:number}>)=>void
}

// Simple noise
const noise2D = (x:number,y:number)=>{
  const t = Math.sin(x*12.9898 + y*78.233) * 43758.5453123
  return t - Math.floor(t)
}

const GalaxyLightweight: React.FC<Props> = ({ structureColoring=true, armCount=5, scale=0.6, onBandPointsReady }) => {
  const rootRef = useRef<HTMLDivElement|null>(null)
  const [dims, setDims] = useState({w:0,h:0})
  useEffect(()=>{
    const onResize=()=>{
      setDims({ w: window.innerWidth, h: window.innerHeight })
    }
    onResize(); window.addEventListener('resize', onResize)
    return ()=> window.removeEventListener('resize', onResize)
  },[])

  const {stars, ringCount} = useMemo(()=>{
    const w = dims.w, h = dims.h; if(!w||!h) return {stars:[], ringCount:0}
    const cx = w/2, cy = h/2
    const maxR = Math.min(w,h) * 0.4 * (scale||1)
    const count = Math.max(600, Math.min(1200, Math.floor((w*h)/3500)))
    const rings = 5
    const arr: Star[] = []
    for(let i=0;i<count;i++){
      const arm = i % armCount
      const t = i / count
      // radius biased towards center
      const r = Math.pow(Math.random(), 0.6) * maxR
      const a = Math.log(Math.max(r, 8)/8) / 0.29
      const theta = (arm * 2*Math.PI/armCount) - a
      const jitter = (noise2D(i*0.37, i*0.91)-0.5) * 12
      const x = cx + (r*Math.cos(theta) + jitter)
      const y = cy + (r*Math.sin(theta) + jitter)
      const ring = Math.min(rings-1, Math.max(0, Math.floor((r/maxR) * rings)))
      const profile = Math.exp(-0.5 * Math.pow((r/maxR)/0.8, 2))
      const baseSize = 0.7 + Math.random()*1.3
      const size = baseSize * (1 + 1.2*profile)
      let color = '#FFFFFF'
      if (structureColoring){
        // simple palette by radius/profile
        if (r < maxR*0.12) color = '#FFF8DC' // core
        else if (profile > 0.65) color = '#FBFBF3' // ridge
        else if (profile > 0.4) color = '#ADD8E6' // armBright
        else if (profile > 0.22) color = '#87CEEB' // armEdge
        else color = '#13318B' // dust/outer
      }
      arr.push({ x, y, size, color, ring })
    }
    // 输出 band 点给脉冲层：band=rings，画布尺寸=w,h
    if (onBandPointsReady){
      const out:Array<{x:number;y:number;size:number;band:number;bw:number;bh:number}> = []
      for(const s of arr){ out.push({ x:s.x, y:s.y, size:s.size, band:s.ring, bw: w, bh: h }) }
      onBandPointsReady(out)
    }
    return { stars: arr, ringCount: rings }
  }, [dims.w, dims.h, armCount, scale, structureColoring, onBandPointsReady])

  // CSS 动画：每个 ring 不同速度
  const ringDur = (idx:number)=>{
    const base = 80 // 秒
    return `${Math.max(12, base*(0.25 + idx/(Math.max(1, ringCount))))}s`
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
      <style>{`
        @keyframes glx-rot { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
      `}</style>
    </div>
  )
}

export default GalaxyLightweight
