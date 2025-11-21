import React, { useEffect, useRef, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { UNIFORM_DEG_PER_MS } from '../utils/rotationConfig'
import { useStableViewportSize } from '../hooks/useStableViewportSize'

interface GlowConfig {
  pickProb?: number
  pulseWidth?: number // not used in DOM pulse, use per-star durations instead
  radiusFactor?: number
  minRadius?: number
  durationMs?: number
}

interface Props {
  pointsRef: React.RefObject<Array<{x:number;y:number;size:number}>>
  bandPointsRef?: React.RefObject<Array<{id:string;x:number;y:number;size:number;band:number;bw:number;bh:number;color?:string;litColor?:string}>>
  scale?: number
  rotateEnabled?: boolean
  config?: GlowConfig
  onLight?: ()=>void
  onPersistHighlights?: (points: Array<{id:string;band:number;x:number;y:number;size:number;color?:string;litColor?:string}>) => void
  resolveHighlightColor?: (bandId?: string, source?: { color?: string; litColor?: string }) => string | null
  resolveClickMeta?: (coords: { clientX: number; clientY: number }) => { xPct: number; yPct: number; xPx: number; yPx: number; region: 'emotion' | 'relation' | 'growth' } | null
  onBackgroundClick?: (meta: { xPct: number; yPct: number; xPx: number; yPx: number; region: 'emotion' | 'relation' | 'growth' }) => void
}

type Pulse = { id:number; x:number; y:number; size:number; dur:number; delay:number; color?: string; litColor?: string; source?: { type:'band' | 'bg'; data: any } }
type Candidate = {
  x:number
  y:number
  size:number
  color?: string
  litColor?: string
  __source: { type:'band' | 'bg'; data: any }
}

const normalizeHex = (hex: unknown): string | null => {
  if (!hex && hex !== 0) return null
  let value = typeof hex === 'string' ? hex.trim() : String(hex).trim()
  if (!value.startsWith('#')) return null
  if (value.length === 4) {
    value = `#${value[1]}${value[1]}${value[2]}${value[2]}${value[3]}${value[3]}`
  }
  if (value.length !== 7) return null
  return value.toUpperCase()
}

const GalaxyDOMPulseOverlay: React.FC<Props> = ({ pointsRef, bandPointsRef, scale=1, rotateEnabled=true, config, onLight, onPersistHighlights, resolveHighlightColor, resolveClickMeta, onBackgroundClick }) => {
  const [pulses, setPulses] = useState<Pulse[]>([])
  const rootRef = useRef<HTMLDivElement|null>(null)
  const highlightTimerRef = useRef<number | null>(null)
  const rotationStartRef = useRef<number>(typeof performance !== 'undefined' ? performance.now() : Date.now())
  const { height: viewportHeight } = useStableViewportSize()
  const containerHeight = viewportHeight || (typeof window !== 'undefined' ? window.innerHeight : 0)
  const heightStyle = containerHeight ? `${containerHeight}px` : '100vh'

  useEffect(() => {
    rotationStartRef.current = typeof performance !== 'undefined' ? performance.now() : Date.now()
  }, [])

  useEffect(() => {
    return () => {
      if (highlightTimerRef.current) {
        clearTimeout(highlightTimerRef.current)
        highlightTimerRef.current = null
      }
    }
  }, [])

  // 将触发逻辑抽为函数，供多种事件源复用
  const fireAt = React.useCallback((clientX: number, clientY: number) => {
    const root = rootRef.current
    if(!root) return
    try { onLight && onLight() } catch {}
    const rect = root.getBoundingClientRect()
    const x = clientX - rect.left
    const y = clientY - rect.top
    const w = rect.width, h = rect.height
    const clickMeta = resolveClickMeta?.({ clientX, clientY })
    if (clickMeta) {
      try { onBackgroundClick && onBackgroundClick(clickMeta) } catch (err) {
        console.warn('[GalaxyDOMPulseOverlay] onBackgroundClick failed:', err)
      }
    }
    const factor = config?.radiusFactor ?? 0.0175
    const minR = config?.minRadius ?? 30
    const R = Math.max(minR, Math.min(w,h) * factor)
    const pts = pointsRef.current || []
    const bpts = bandPointsRef?.current || []
    const cx = w/2, cy = h/2
    const now = typeof performance !== 'undefined' ? performance.now() : Date.now()
    const rotationElapsed = Math.max(0, now - rotationStartRef.current)
    const getPulseColor = (candidate: Candidate): string => {
      const bandId = candidate.__source?.type === 'band' ? candidate.__source.data?.id : undefined
      const resolved = resolveHighlightColor?.(bandId, candidate.__source?.data ?? candidate)
      const normalizedHighlight = normalizeHex(resolved)
      if (normalizedHighlight) return normalizedHighlight
      return '#FFE2B0'
    }
    const bgCandidates: Candidate[] = (pts as any[]).map((p:any)=>({
      x: p.x,
      y: p.y,
      size: p.size,
      color: p.color || '#CCCCCC',
      litColor: p.litColor,
      __source: { type: 'bg', data: p }
    }))
    const transformed: Candidate[] = (bpts || []).map((p:any)=>{
      const omegaDegPerMs = rotateEnabled ? UNIFORM_DEG_PER_MS : 0
      const angle = omegaDegPerMs * rotationElapsed * (Math.PI/180)
      const bcx = p.bw/2, bcy = p.bh/2
      const rx = p.x - bcx
      const ry = p.y - bcy
      const sx = cx + (rx*Math.cos(angle) - ry*Math.sin(angle)) * (scale||1)
      const sy = cy + (rx*Math.sin(angle) + ry*Math.cos(angle)) * (scale||1)
      return { x: sx, y: sy, size: p.size, color: p.color, litColor: p.litColor, __source: { type: 'band', data: p } }
    })
    const all: Candidate[] = bgCandidates.concat(transformed)
    if(!all.length) return
    const inRange = all.filter(p=>{ const dx=p.x - x, dy=p.y - y; return dx*dx+dy*dy <= R*R })
    if(!inRange.length) return
    const target = Math.min(inRange.length, 30)
    const groups = new Map<string, any[]>()
    for(const p of inRange){
      const c = ((p as any).color || '#CCCCCC').toLowerCase()
      const key = c || '_grey'
      if(!groups.has(key)) groups.set(key, [])
      groups.get(key)!.push(p)
    }
    const shuffle = (arr:any[])=>{ for(let i=arr.length-1;i>0;i--){ const j=Math.floor(Math.random()*(i+1)); [arr[i],arr[j]]=[arr[j],arr[i]] } return arr }
    for(const [k,arr] of groups) groups.set(k, shuffle(arr))
    const colorKeys = Array.from(groups.keys()).filter(k=>k!=='_grey')
    const greyKey = '_grey'
    const chosen: Pulse[] = []
    for(const key of colorKeys){
      if (chosen.length >= target) break
      const arr = groups.get(key) || []
      if(arr.length){
        const p = arr.shift()!
        const dur = config?.durationMs ?? 850
        const pulseColor = getPulseColor(p)
        chosen.push({ id: Date.now()+Math.random(), x: p.x, y: p.y, size: p.size, dur, delay: 0, color: pulseColor, litColor: pulseColor, source: p.__source })
      }
    }
    const fillFrom = (keys:string[])=>{
      let idx = 0
      while(chosen.length < target){
        if (!keys.length) break
        const key = keys[idx % keys.length]
        const arr = groups.get(key) || []
        if(arr.length){
          const p = arr.shift()!
          const dur = config?.durationMs ?? 850
          const pulseColor = getPulseColor(p)
          chosen.push({ id: Date.now()+Math.random(), x: p.x, y: p.y, size: p.size, dur, delay: 0, color: pulseColor, litColor: pulseColor, source: p.__source })
        }
        idx++
        if (keys.every(k=> (groups.get(k)||[]).length===0)) break
      }
    }
    fillFrom(colorKeys)
    if (chosen.length < target && groups.has(greyKey)) fillFrom([greyKey])
    setPulses(prev => prev.concat(chosen))
    if (onPersistHighlights) {
      const bandSelected = chosen
        .map(c => c.source)
        .filter((src): src is { type:'band'; data:any } => !!src && (src as any).type === 'band')
        .map(src => (src as any).data)
        .filter(Boolean)
      const uniqueById = new Map<string, any>()
      for (const pt of bandSelected) {
        if (pt && pt.id && !uniqueById.has(pt.id)) {
          uniqueById.set(pt.id, pt)
        }
      }
      let toPersist = Array.from(uniqueById.values())
      if (!toPersist.length) {
        toPersist = transformed.slice(0, 12).map((p, idx) => {
          const color = getPulseColor(p)
          return { id: `fallback-${Date.now()}-${idx}`, band: 0, x: p.x, y: p.y, size: p.size, color, litColor: color }
        })
      } else {
        toPersist = toPersist.map((p:any) => { const color = getPulseColor(p); return { ...p, color, litColor: color } })
      }
      if (highlightTimerRef.current) { clearTimeout(highlightTimerRef.current); highlightTimerRef.current = null }
      if (toPersist.length) {
        const payload = toPersist.map((p:any) => ({ id: p.id, band: p.band, x: p.x, y: p.y, size: p.size, color: p.color, litColor: p.litColor }))
        if (typeof window !== 'undefined') { (window as any).__galaxyOverlayPayload = payload }
        const longestDur = Math.max(...chosen.map(c => c.dur), 0)
        const delay = Math.min(240, Math.max(120, longestDur * 0.35 || 0))
        highlightTimerRef.current = window.setTimeout(() => { try { onPersistHighlights(payload) } finally { highlightTimerRef.current = null } }, delay)
      }
    }
    const maxDur = Math.max(...chosen.map(c=>c.dur)) + 200
    setTimeout(()=>{ setPulses(prev => prev.filter(p => !chosen.find(c=>c.id===p.id))) }, maxDur+50)
  }, [onLight, resolveClickMeta, onBackgroundClick, config?.radiusFactor, config?.minRadius, pointsRef, bandPointsRef, rotateEnabled, scale, resolveHighlightColor, onPersistHighlights])

  // 保留根元素点击（用于常规 DOM 冒泡路径）
  useEffect(()=>{
    const root = rootRef.current
    if(!root) return
    const handleClick = (e: MouseEvent)=>{
      fireAt(e.clientX, e.clientY)
    }
    root.addEventListener('click', handleClick)
    return ()=> root.removeEventListener('click', handleClick)
  }, [fireAt])

  // 兜底：全局捕获指针按下，避免被更高层 DOM 遮挡导致“点不亮”
  useEffect(()=>{
    const shouldIgnore = (el: Element | null): boolean => {
      let node: Element | null = el
      while (node) {
        const tag = node.tagName
        if (tag === 'BUTTON' || tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT' || tag === 'A') return true
        if ((node as HTMLElement).getAttribute('role') === 'button') return true
        if ((node as HTMLElement).dataset && (node as HTMLElement).dataset.noGalaxy) return true
        const cn = (node as HTMLElement).className || ''
        if (typeof cn === 'string' && /oracle-input|drawer|modal|overlay|card|button|link/.test(cn)) return true
        node = node.parentElement
      }
      return false
    }
    const onPointerDown = (e: PointerEvent) => {
      if (shouldIgnore(e.target as Element)) return
      fireAt(e.clientX, e.clientY)
    }
    window.addEventListener('pointerdown', onPointerDown, true)
    return () => window.removeEventListener('pointerdown', onPointerDown, true)
  }, [fireAt])

  return (
    <div
      ref={rootRef}
      className="pointer-events-auto"
      style={{ position: 'fixed', top: 0, left: 0, width: '100%', height: heightStyle, zIndex: 10 }}
    >
      <AnimatePresence>
        {pulses.map(p => {
          const base = normalizeHex(p.litColor || p.color) || '#FFE2B0'
          const size = Math.max(3, p.size * 1.2)
          return (
            <motion.div
              key={p.id}
              initial={{ opacity: 1 }}
              animate={{ opacity: 0 }}
              transition={{ duration: p.dur/1000, delay: p.delay/1000, ease: 'easeOut' }}
              style={{ position:'absolute', left: p.x, top: p.y, transform: 'translate(-50%, -50%)' }}
            >
              <div
                style={{
                  width: `${size}px`,
                  height: `${size}px`,
                  borderRadius: '50%',
                  background: base,
                  opacity: 0.9
                }}
              />
            </motion.div>
          )
        })}
      </AnimatePresence>
    </div>
  )
}

export default GalaxyDOMPulseOverlay
