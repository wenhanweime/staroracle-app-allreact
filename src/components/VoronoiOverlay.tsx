import React, { useEffect, useMemo, useRef } from 'react'
import { useGalaxyGridStore } from '../store/useGalaxyGridStore'

interface Props {
  baseCanvasRef?: React.RefObject<HTMLCanvasElement | null>
}

const VoronoiOverlay: React.FC<Props> = ({ baseCanvasRef }) => {
  const width = useGalaxyGridStore(s=>s.width)
  const height = useGalaxyGridStore(s=>s.height)
  const sites = useGalaxyGridStore(s=>s.sites)
  const neighbors = useGalaxyGridStore(s=>s.neighbors)
  const labelMap = useGalaxyGridStore(s=>s.labelMap)
  const labelRev = useGalaxyGridStore(s=>s.labelMapRev)
  const activeIds = useGalaxyGridStore(s=>s.activeIds)
  const setActive = useGalaxyGridStore(s=>s.setActiveByPoint)
  const rebuild = useGalaxyGridStore(s=>s.rebuildLabelMap)
  const perturb = useGalaxyGridStore(s=>s.perturbActiveSite)
  const computeDistances = useGalaxyGridStore(s=>s.computeGraphDistances)
  const canvasRef = useRef<HTMLCanvasElement|null>(null)
  // 点击焦点（CSS像素坐标）与动画控制
  const focusRef = useRef<{x:number;y:number;start:number;duration:number}|null>(null)
  const waveRef = useRef<{dist:number[]; speed:number; pxPerHop:number; sigma:number; maxHops:number}|null>(null)

  useEffect(()=>{ if(width && height && sites.length && !labelMap) rebuild() }, [width,height,sites,labelMap,rebuild])
  useEffect(()=>{
    const c = canvasRef.current; if(!c||!width||!height) return;
    const DPR = Math.min(window.devicePixelRatio||1,2)
    c.width = Math.floor(width*DPR)
    c.height= Math.floor(height*DPR)
    c.style.width = `${width}px`; c.style.height = `${height}px`
  },[width,height])

  // 渲染循环：基于图邻接的"不规则波纹"（细胞层级扩散），仅增强已有星点
  useEffect(()=>{
    const c = canvasRef.current; if(!c||!width||!height) return;
    const ctx = c.getContext('2d')!; const DPR = Math.min(window.devicePixelRatio||1,2)
    const base = baseCanvasRef?.current || null
    const bctx = base ? base.getContext('2d') : null
    const mctx = labelMap?.getContext('2d') || null
    const mdata = labelMap && mctx ? mctx.getImageData(0,0,labelMap.width, labelMap.height) : null
    let raf = 0
    const render = (now:number)=>{
      // 使用设备像素坐标，不进行 ctx.scale 以便 putImageData 对齐
      ctx.clearRect(0,0,c.width,c.height)

      const focus = focusRef.current
      const wave = waveRef.current
      if(focus && wave && mctx && base && bctx){
        const t = Math.min(1, Math.max(0, (now - focus.start)/focus.duration))
        // 行进阶段占比：先扩散，再衰减，始终不使原图变暗
        const travelPortion = 0.6
        const centerHop = Math.min(wave.maxHops, wave.speed * (now - focus.start))

        // 动态处理的像素范围：跟随波半径增长
        const fx = Math.round(focus.x * DPR)
        const fy = Math.round(focus.y * DPR)
        const frHop = Math.min(wave.maxHops + 1.5, centerHop + 2.0) // 波中心±2跳的包围，最多到 maxHops+1.5
        const fr = Math.max(2, Math.round(frHop * wave.pxPerHop * DPR))
        const sx = Math.max(0, fx - fr)
        const sy = Math.max(0, fy - fr)
        const sw = Math.min(base.width - sx, fr*2)
        const sh = Math.min(base.height - sy, fr*2)
        if (sw>0 && sh>0){
          const src = bctx.getImageData(sx, sy, sw, sh)
          const off = document.createElement('canvas'); off.width = sw; off.height = sh
          const octx = off.getContext('2d')!
          const out = octx.createImageData(sw, sh)
          const data = src.data; const od = out.data
          const threshold = 70 // 仅增强已有较亮像素
          const sigma = wave.sigma // 波带宽度（单位：跳数）
          // 时间包络：扩散阶段保持强度，结束后逐步回到原亮度
          const ampTime = t < travelPortion ? 1 : (1 - (t - travelPortion) / (1 - travelPortion))
          // 额外的“矩形边缘羽化”：离四条边越近，强度越小，消除任何方形印记
          const featherRect = Math.max(2, Math.round(1.5 * wave.pxPerHop * DPR))
          // 软化贴图边界，避免矩形硬边：以本帧处理半径 fr 为上限做径向羽化
          const featherPx = Math.max(1, 1.2 * wave.pxPerHop * DPR)
          for(let j=0;j<sh;j++){
            for(let i=0;i<sw;i++){
              const di = (j*sw + i)*4
              const r = data[di], g=data[di+1], b=data[di+2]
              const a = data[di+3]
              if (a===0) { continue }
              // labelMap 检查：映射到 CSS 像素坐标再到 labelMap
              const rxCSS = (sx + i) / DPR
              const ryCSS = (sy + j) / DPR
              const mx = Math.floor(rxCSS/width * (labelMap!.width))
              const my = Math.floor(ryCSS/height * (labelMap!.height))
              const moff = ((my*labelMap!.width)+mx)*4
              const got = (mdata!.data[moff]) + (mdata!.data[moff+1]<<8) + (mdata!.data[moff+2]<<16)
              const hop = wave.dist[got]
              if(!isFinite(hop)) continue
              // 仅增强已有星点：根据亮度阈值
              const bright = Math.max(r,g,b)
              if (bright < threshold) continue
              // 波形：多环涟漪（多个高斯条带叠加），中心= centerHop，环间距约1跳，外环幅度递减
              let strength = 0
              const ringGap = 1.0
              const rings = 3
              for(let rgi=0;rgi<rings;rgi++){
                const peak = centerHop - rgi*ringGap
                const xh = hop - peak
                const band = Math.exp(-0.5 * (xh*xh) / (sigma*sigma))
                const decay = Math.pow(0.72, rgi) // 外环逐级变弱
                strength += band * decay
              }
              strength *= ampTime
              if (strength < 0.02) continue
              // 边缘羽化：在当前处理半径 fr 附近平滑衰减至 0，消除方形边缘
              const dx = (sx + i) - fx
              const dy = (sy + j) - fy
              const distPx = Math.hypot(dx, dy)
              const edge = Math.max(0, Math.min(1, (fr - distPx) / featherPx))
              strength *= edge
              // 矩形边界羽化（最小到四边的距离）
              const minToEdge = Math.min(i, j, sw-1-i, sh-1-j)
              const edgeRect = Math.max(0, Math.min(1, minToEdge / featherRect))
              strength *= edgeRect
              if (strength < 0.02) continue
              // 输出为“加亮层”像素（白色），配合 lighter 叠加
              const boost = Math.min(255, Math.round(210 * strength))
              od[di] = boost; od[di+1] = boost; od[di+2] = boost; od[di+3] = 220
            }
          }
          // 使用 lighter 叠加：通过 drawImage 保证合成模式生效（putImageData 不参与合成）
          octx.putImageData(out, 0, 0)
          const prevComp = ctx.globalCompositeOperation
          const prevSmooth = ctx.imageSmoothingEnabled
          ctx.imageSmoothingEnabled = false
          ctx.globalCompositeOperation = 'lighter'
          ctx.drawImage(off, sx, sy)
          ctx.globalCompositeOperation = prevComp
          ctx.imageSmoothingEnabled = prevSmooth
        }
      }

      raf = requestAnimationFrame(render)
    }
    raf = requestAnimationFrame(render)
    return ()=> cancelAnimationFrame(raf)
  },[width,height,labelMap,labelRev,activeIds,sites])

  // 选中块的轻微“形变”：在选中后短暂抖动站点坐标并重建labelMap（不影响主体银河）
  useEffect(()=>{
    if(!activeIds || !activeIds.length) return;
    let times = 0
    const id = setInterval(()=>{
      if(times++>10){ clearInterval(id); return }
      perturb(2.0)
    }, 120)
    return ()=> clearInterval(id)
  }, [activeIds, perturb])

  const handleClick: React.MouseEventHandler<HTMLCanvasElement> = (e)=>{
    const rect = (e.target as HTMLCanvasElement).getBoundingClientRect()
    const x = e.clientX - rect.left
    const y = e.clientY - rect.top
    // 记录焦点：波纹从中心按图邻接扩散（不规则），逐步渐隐
    focusRef.current = { x, y, start: performance.now(), duration: 1800 }
    setActive(x,y)
  }

  // activeIds 更新后，计算图距离与像素/跳映射
  useEffect(()=>{
    if(!activeIds || !activeIds.length || !sites.length || !width || !height) return
    const dist = computeDistances(activeIds)
    const approxSpacing = Math.sqrt((width*height)/Math.max(1, sites.length))
    // 单个闪烁块缩小约20倍：将跳→像素的映射缩小20倍
    const pxPerHop = Math.max(1, approxSpacing / 20)
    const maxHops = 5 // 扩散几圈后停止
    const duration = 1800 // ms
    const travelPortion = 0.6
    const speed = maxHops / (duration * travelPortion) // hops per ms，预留尾段做渐隐
    waveRef.current = { dist, speed, pxPerHop, sigma: 0.15, maxHops }
    // 同步更新动画时长以吻合圈数
    if (focusRef.current) focusRef.current = { ...focusRef.current, duration }
  }, [activeIds, sites, width, height, computeDistances])

  if(!width||!height) return null
  return <canvas ref={canvasRef} className="absolute inset-0 z-10 pointer-events-auto" onClick={handleClick} />
}

export default VoronoiOverlay
