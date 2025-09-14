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
  bandPointsRef?: React.RefObject<Array<{x:number;y:number;size:number;band:number;bw:number;bh:number;color?:string}>>
  scale?: number
  rotateEnabled?: boolean
  config?: GlowConfig
}

type Pulse = { id:number; x:number; y:number; size:number; dur:number; delay:number; color?: string }

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
        return { x: sx, y: sy, size: p.size, color: p.color }
      })
      const all = (pts as any[]).concat(transformed)
      if(!all.length) return
      // 选择点击半径内的点
      const inRange = all.filter(p=>{ const dx=p.x - x, dy=p.y - y; return dx*dx+dy*dy <= R*R })
      if(!inRange.length) return
      // 固定数量采样：每次点击固定 30 颗（不超过候选），并保证每种颜色都能被代表
      const target = Math.min(inRange.length, 30)
      // 分组：按颜色（无颜色归类为 '_grey'）
      const groups = new Map<string, any[]>()
      for(const p of inRange){
        const c = ((p as any).color || '#CCCCCC').toLowerCase()
        const key = c || '_grey'
        if(!groups.has(key)) groups.set(key, [])
        groups.get(key)!.push(p)
      }
      // 将每组打乱
      const shuffle = (arr:any[])=>{ for(let i=arr.length-1;i>0;i--){ const j=Math.floor(Math.random()*(i+1)); [arr[i],arr[j]]=[arr[j],arr[i]] } return arr }
      for(const [k,arr] of groups) groups.set(k, shuffle(arr))
      const colorKeys = Array.from(groups.keys()).filter(k=>k!=='_grey')
      const greyKey = '_grey'
      // 至少为每个有色组分配一个名额
      const chosen: Pulse[] = []
      const basePerColor = 1
      for(const key of colorKeys){
        if (chosen.length >= target) break
        const arr = groups.get(key) || []
        if(arr.length){
          const p = arr.shift()!
          const durBase = (config?.durationMs ?? 1100)
          const dur = durBase * (0.7 + 0.8*Math.random())
          chosen.push({ id: Date.now()+Math.random(), x: p.x, y: p.y, size: p.size, dur, delay: 0, color: key })
        }
      }
      // 将剩余名额优先分配给有色组，再分配给灰色组
      const fillFrom = (keys:string[])=>{
        let idx = 0
        while(chosen.length < target){
          if (!keys.length) break
          const key = keys[idx % keys.length]
          const arr = groups.get(key) || []
          if(arr.length){
            const p = arr.shift()!
            const durBase = (config?.durationMs ?? 1100)
            const dur = durBase * (0.7 + 0.8*Math.random())
            const color = key === greyKey ? '#CCCCCC' : key
            chosen.push({ id: Date.now()+Math.random(), x: p.x, y: p.y, size: p.size, dur, delay: 0, color })
          }
          idx++
          // 防止死循环：如果所有数组都空了就退出
          if (keys.every(k=> (groups.get(k)||[]).length===0)) break
        }
      }
      fillFrom(colorKeys)
      if (chosen.length < target && groups.has(greyKey)) fillFrom([greyKey])
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
            {/* 高亮点（颜色跟随被选星点） */}
            <div style={{
              width: `${Math.max(1.5, p.size*2)}px`,
              height: `${Math.max(1.5, p.size*2)}px`,
              borderRadius: '50%',
              background: p.color || '#CCCCCC',
              boxShadow: `0 0 6px ${(p.color||'#CCCCCC')}CC, 0 0 12px ${(p.color||'#CCCCCC')}99`
            }}/>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  )
}

export default GalaxyDOMPulseOverlay
