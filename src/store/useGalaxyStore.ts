import { create } from 'zustand'

export type GalaxyRegion = 'emotion' | 'relation' | 'growth'

export interface Hotspot {
  id: string
  xPct: number // 0-100
  yPct: number // 0-100
  region: GalaxyRegion
  seed: number
  cooldownUntil?: number
}

export interface Ripple {
  id: string
  x: number
  y: number
  startAt: number
  duration: number
}

interface GalaxyState {
  width: number
  height: number
  hotspots: Hotspot[]
  ripples: Ripple[]
  hoveredId?: string
  setCanvasSize: (w: number, h: number) => void
  generateHotspots: (count?: number) => void
  hoverAt: (x: number, y: number) => void
  clickAt: (x: number, y: number) => void
  cleanupFx: () => void
}

const clamp = (v: number, min: number, max: number) => Math.max(min, Math.min(max, v))

const angleToRegion = (angleRad: number): GalaxyRegion => {
  const deg = ((angleRad * 180) / Math.PI + 360) % 360
  if (deg < 120) return 'emotion'
  if (deg < 240) return 'relation'
  return 'growth'
}

export const useGalaxyStore = create<GalaxyState>((set, get) => ({
  width: 0,
  height: 0,
  hotspots: [],
  ripples: [],
  setCanvasSize: (w, h) => set({ width: w, height: h }),
  generateHotspots: (count = 30) => {
    const { width, height } = get()
    if (!width || !height) return
    const centerX = width / 2
    const centerY = height / 2
    const maxR = Math.min(width, height) * 0.4
    const hs: Hotspot[] = []
    for (let i = 0; i < count; i++) {
      // 在半径[0.2,1]*maxR 区间随机生成，避开中心小区域
      const rr = 0.2 + 0.8 * Math.random()
      const r = rr * maxR
      const t = Math.random() * Math.PI * 2
      const x = centerX + r * Math.cos(t)
      const y = centerY + r * Math.sin(t)
      const region = angleToRegion(Math.atan2(y - centerY, x - centerX))
      hs.push({
        id: `hs_${i}_${Date.now()}`,
        xPct: clamp((x / width) * 100, 0, 100),
        yPct: clamp((y / height) * 100, 0, 100),
        region,
        seed: i,
      })
    }
    set({ hotspots: hs })
  },
  hoverAt: (x, y) => {
    const { width, height, hotspots } = get()
    if (!width || !height) return
    const px = clamp((x / width) * 100, 0, 100)
    const py = clamp((y / height) * 100, 0, 100)
    let minD = Infinity
    let id: string | undefined
    for (const h of hotspots) {
      const dx = px - h.xPct
      const dy = py - h.yPct
      const d = Math.hypot(dx, dy)
      if (d < minD && d < 8) { // 近距离 hover
        minD = d
        id = h.id
      }
    }
    set({ hoveredId: id })
  },
  clickAt: (x, y) => {
    const { width, height, hotspots, ripples } = get()
    if (!width || !height) return
    // 记录两圈涟漪
    const now = performance.now()
    const rp: Ripple[] = [
      { id: `rp_${now}`, x, y, startAt: now, duration: 900 },
      { id: `rp_${now}_2`, x, y, startAt: now + 120, duration: 900 },
    ]
    // 命中热点进入冷却
    const px = clamp((x / width) * 100, 0, 100)
    const py = clamp((y / height) * 100, 0, 100)
    const hs = hotspots.map(h => {
      const d = Math.hypot(px - h.xPct, py - h.yPct)
      if (d < 6) return { ...h, cooldownUntil: now + 60000 }
      return h
    })
    set({ ripples: ripples.concat(rp), hotspots: hs })
  },
  cleanupFx: () => {
    const now = performance.now()
    set(state => ({
      ripples: state.ripples.filter(r => now - r.startAt < r.duration),
    }))
  }
}))

