import React, { useEffect, useRef } from 'react'
import { useGalaxyStore } from '../store/useGalaxyStore'

interface Props {
  className?: string
}

const HotspotOverlay: React.FC<Props> = ({ className }) => {
  const width = useGalaxyStore(s => s.width)
  const height = useGalaxyStore(s => s.height)
  const hotspots = useGalaxyStore(s => s.hotspots)
  const hoveredId = useGalaxyStore(s => s.hoveredId)
  const ripples = useGalaxyStore(s => s.ripples)
  const cleanupFx = useGalaxyStore(s => s.cleanupFx)
  const canvasRef = useRef<HTMLCanvasElement | null>(null)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const DPR = (window.devicePixelRatio || 1)
    canvas.width = Math.floor(width * DPR)
    canvas.height = Math.floor(height * DPR)
    canvas.style.width = `${width}px`
    canvas.style.height = `${height}px`
  }, [width, height])

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')!
    const DPR = (window.devicePixelRatio || 1)

    let raf = 0
    const render = () => {
      ctx.save()
      ctx.scale(DPR, DPR)
      ctx.clearRect(0, 0, width, height)

      // Hotspots: 脉冲
      const now = performance.now()
      hotspots.forEach(h => {
        const x = (h.xPct / 100) * width
        const y = (h.yPct / 100) * height
        const t = (now / 1000 + h.seed) % 2
        const pulse = 0.6 + 0.4 * Math.sin(t * Math.PI)
        const r = 3 + 2 * pulse
        const isHover = hoveredId === h.id
        const inCd = h.cooldownUntil && h.cooldownUntil > now
        ctx.beginPath()
        ctx.globalAlpha = inCd ? 0.2 : (isHover ? 0.9 : 0.6)
        ctx.fillStyle = isHover ? '#FFE08A' : '#FFFFFF'
        ctx.arc(x, y, r, 0, Math.PI * 2)
        ctx.fill()
        // 外环光晕
        ctx.beginPath()
        ctx.globalAlpha = inCd ? 0.1 : 0.2
        ctx.strokeStyle = isHover ? '#FFE08A' : '#FFFFFF'
        ctx.lineWidth = 1
        ctx.arc(x, y, r + 3, 0, Math.PI * 2)
        ctx.stroke()
      })

      // Ripples: 扩散波
      ripples.forEach(rp => {
        const e = (now - rp.startAt) / rp.duration
        if (e < 0 || e > 1) return
        const radius = 10 + e * 140
        const alpha = Math.exp(-1.2 * e)
        ctx.beginPath()
        ctx.globalAlpha = alpha * 0.6
        ctx.strokeStyle = '#FFFFFF'
        ctx.lineWidth = 1
        ctx.arc(rp.x, rp.y, radius, 0, Math.PI * 2)
        ctx.stroke()
      })

      ctx.restore()
      cleanupFx()
      raf = requestAnimationFrame(render)
    }
    raf = requestAnimationFrame(render)
    return () => cancelAnimationFrame(raf)
  }, [width, height, hotspots, ripples, hoveredId, cleanupFx])

  if (!width || !height) return null
  return <canvas ref={canvasRef} className={className || 'pointer-events-none absolute inset-0 z-10'} />
}

export default HotspotOverlay

