import React, { useEffect, useRef, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { UNIFORM_DEG_PER_MS } from '../utils/rotationConfig'

interface GlowConfig {
  pickProb?: number
  pulseWidth?: number // not used in DOM pulse, use per-star durations instead
  radiusFactor?: number
  minRadius?: number
  durationMs?: number
}

interface Props {
  pointsRef: React.RefObject<Array<{x:number;y:number;size:number}>>
  bandPointsRef?: React.RefObject<Array<{x:number;y:number;size:number;band:number;bw:number;bh:number}>>
  scale?: number
  rotateEnabled?: boolean
  config?: GlowConfig
}

type Pulse = { id:number; x:number; y:number; size:number; dur:number; delay:number }

const GalaxyDOMPulseOverlay: React.FC<Props> = ({ pointsRef, bandPointsRef, scale=1, rotateEnabled=true, config }) => {
  const [pulses, setPulses] = useState<Pulse[]>([])
  const rootRef = useRef<HTMLDivElement|null>(null)

  useEffect(()=>{
    const root = rootRef.current
    if(!root) return
    const handleClick = (e: MouseEvent)=>{
      const rect = root.getBoundingClientRect()
      const x = e.clientX - rect.left
      const y = e.clientY - rect.top
      const w = rect.width, h = rect.height
      const factor = config?.radiusFactor ?? 0.0175
      const minR = config?.minRadius ?? 30
      const R = Math.max(minR, Math.min(w,h) * factor)
      const pts = pointsRef.current || []
      const bpts = bandPointsRef?.current || []
      const BAND_COUNT = Math.max(1, bpts.reduce((m,p)=> Math.max(m, p.band+1), 1))
      const cx = w/2, cy = h/2
      const now = performance.now()
      const transformed = bpts.map(p=>{
        // 统一旋转速度：所有环使用相同角速度，与 CSS 动画保持一致
        const omegaDegPerMs = rotateEnabled ? UNIFORM_DEG_PER_MS : 0
        const angle = omegaDegPerMs * now * (Math.PI/180)
        const bcx = p.bw/2, bcy = p.bh/2
        const rx = p.x - bcx
        const ry = p.y - bcy
        const sx = cx + (rx*Math.cos(angle) - ry*Math.sin(angle)) * (scale||1)
        const sy = cy + (rx*Math.sin(angle) + ry*Math.cos(angle)) * (scale||1)
        return { x: sx, y: sy, size: p.size }
      })
      const all = pts.concat(transformed)
      if(!all.length) return
      // 选择点击半径内的点
      const inRange = all.filter(p=>{ const dx=p.x - x, dy=p.y - y; return dx*dx+dy*dy <= R*R })
      if(!inRange.length) return
      // 固定数量采样：每次点击固定 30 颗（不超过候选）
      const target = Math.min(inRange.length, 30)
      // Fisher-Yates 部分洗牌，获取前 target 个随机索引
      const idxs = Array.from({length: inRange.length}, (_,i)=>i)
      for(let i=0;i<target;i++){
        const j = i + Math.floor(Math.random() * (inRange.length - i))
        const tmp = idxs[i]; idxs[i] = idxs[j]; idxs[j] = tmp
      }
      const chosen: Pulse[] = []
      for(let k=0;k<target;k++){
        const p = inRange[idxs[k]]
        const durBase = (config?.durationMs ?? 1100)
        const dur = durBase * (0.7 + 0.8*Math.random())
        const delay = 0
        chosen.push({ id: Date.now()+Math.random(), x: p.x, y: p.y, size: p.size, dur, delay })
      }
      setPulses(prev => prev.concat(chosen))
      // 清理：在最长 dur 后移除这些 pulses
      const maxDur = Math.max(...chosen.map(c=>c.dur)) + 200
      setTimeout(()=>{
        setPulses(prev => prev.filter(p => !chosen.find(c=>c.id===p.id)))
      }, maxDur+50)
    }
    root.addEventListener('click', handleClick)
    return ()=> root.removeEventListener('click', handleClick)
  }, [pointsRef, bandPointsRef, rotateEnabled, scale, config])

  return (
    <div ref={rootRef} className="absolute inset-0 pointer-events-auto z-10">
      <AnimatePresence>
        {pulses.map(p => (
          <motion.div
            key={p.id}
            initial={{ opacity: 1 }}
            animate={{ opacity: 0 }}
            transition={{ duration: p.dur/1000, delay: p.delay/1000, ease: 'easeOut' }}
            style={{ position:'absolute', left: p.x, top: p.y, transform: 'translate(-50%, -50%)' }}
          >
            {/* 核心白点 */}
            <div style={{
              width: `${Math.max(1.5, p.size*2)}px`,
              height: `${Math.max(1.5, p.size*2)}px`,
              borderRadius: '50%',
              background: 'white',
              boxShadow: '0 0 6px rgba(255,255,255,0.9), 0 0 12px rgba(255,255,255,0.6)'
            }}/>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  )
}

export default GalaxyDOMPulseOverlay
