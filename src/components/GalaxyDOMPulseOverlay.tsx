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
  bandPointsRef?: React.RefObject<Array<{x:number;y:number;size:number;band:number;bw:number;bh:number;color?:string;litColor?:string}>>
  scale?: number
  rotateEnabled?: boolean
  config?: GlowConfig
  onLight?: ()=>void
}

type Pulse = { id:number; x:number; y:number; size:number; dur:number; delay:number; color?: string }

// Helpers: hex -> rgb and lighten by mixing with white
const hexToRgb = (hex:string)=>{
  const h = hex.replace('#','')
  const full = h.length===3 ? h.split('').map(c=>c+c).join('') : h
  const num = parseInt(full,16)
  return { r:(num>>16)&255, g:(num>>8)&255, b:num&255 }
}
const rgbToHex = (r:number,g:number,b:number)=> '#'+[r,g,b].map(v=>Math.max(0,Math.min(255,v)).toString(16).padStart(2,'0')).join('')
const lighten = (hex:string, t:number)=>{ const {r,g,b}=hexToRgb(hex); return rgbToHex(r + (255-r)*t, g + (255-g)*t, b + (255-b)*t) }

const GalaxyDOMPulseOverlay: React.FC<Props> = ({ pointsRef, bandPointsRef, scale=1, rotateEnabled=true, config, onLight }) => {
  const [pulses, setPulses] = useState<Pulse[]>([])
  const rootRef = useRef<HTMLDivElement|null>(null)

  useEffect(()=>{
    const root = rootRef.current
    if(!root) return
    const handleClick = (e: MouseEvent)=>{
      // 通知父组件触发“点亮”模式（如切换到亮色调色板）
      try { onLight && onLight() } catch {}
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
        return { x: sx, y: sy, size: p.size, color: p.color, litColor: (p as any).litColor }
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
            {/* 超亮高亮点：彩色大光晕 + 白色小核心 */}
            {(()=>{
              const base = ((p as any).litColor || p.color || '#CCCCCC')
              const hi = lighten(base, 0.65) // 显著提亮
              const coreSize = Math.max(2, p.size * 1.4)
              const haloSize = Math.max(coreSize*2.2, p.size * 3.2)
              const haloPx = Math.ceil(haloSize*0.6)
              const haloPx2 = Math.ceil(haloSize*0.9)
              const corePx1 = Math.ceil(coreSize*3)
              const corePx2 = Math.ceil(coreSize*6)
              return (
                <div style={{ position:'relative', left: 0, top: 0 }}>
                  {/* 彩色大光晕 */}
                  <div style={{
                    position:'absolute', left: '50%', top: '50%', transform: 'translate(-50%, -50%)',
                    width: `${haloSize}px`, height: `${haloSize}px`, borderRadius:'50%',
                    background: hi,
                    opacity: 0.9,
                    boxShadow: `0 0 ${haloPx}px ${hi}, 0 0 ${haloPx2}px ${hi}`
                  }}/>
                  {/* 明亮白色核心 */}
                  <div style={{
                    position:'absolute', left: '50%', top: '50%', transform: 'translate(-50%, -50%)',
                    width: `${coreSize}px`, height: `${coreSize}px`, borderRadius:'50%',
                    background: '#FFFFFF',
                    boxShadow: `0 0 ${corePx1}px #FFFFFF, 0 0 ${corePx2}px ${hi}`
                  }}/>
                </div>
              )
            })()}
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  )
}

export default GalaxyDOMPulseOverlay
