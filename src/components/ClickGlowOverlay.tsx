import React, { useEffect, useRef } from 'react'

interface Props {
  baseCanvasRef: React.RefObject<HTMLCanvasElement | null>
}

// 简化版点击高亮：仅在点击附近让“已有星点”先变亮后回到原亮度
// 仅对小范围像素操作，基于底层画布采样，采用 screen 叠加，只会变亮
const ClickGlowOverlay: React.FC<Props> = ({ baseCanvasRef }) => {
  const canvasRef = useRef<HTMLCanvasElement|null>(null)
  const animRef = useRef<{x:number;y:number;start:number;duration:number;radius:number}|null>(null)
  const sizeRef = useRef<{w:number;h:number}>({w:0,h:0})

  // resize to match window
  useEffect(()=>{
    const c = canvasRef.current; if(!c) return
    const onResize = ()=>{
      const DPR = Math.min(window.devicePixelRatio||1,2)
      const w = window.innerWidth, h = window.innerHeight
      c.width = Math.floor(w*DPR); c.height = Math.floor(h*DPR)
      c.style.width = w+'px'; c.style.height = h+'px'
      sizeRef.current = {w, h}
    }
    onResize()
    window.addEventListener('resize', onResize)
    return ()=> window.removeEventListener('resize', onResize)
  },[])

  // render loop
  useEffect(()=>{
    const c = canvasRef.current; const base = baseCanvasRef.current
    if(!c || !base) return
    const ctx = c.getContext('2d')!
    const DPR = Math.min(window.devicePixelRatio||1,2)
    let raf = 0

    const render = (now:number)=>{
      ctx.clearRect(0,0,c.width,c.height)
      const anim = animRef.current
      if(anim){
        const {x,y,start,duration,radius} = anim
        const t = (now-start)/duration
        if(t>=1){ animRef.current=null }
        else {
          // 先亮后回原：时间包络（0→1→0），不产生任何变暗
          const amp = Math.sin(Math.PI * Math.max(0, Math.min(1, t)))
          // 抽取底层小块
          const bx = Math.round(x*DPR), by = Math.round(y*DPR)
          const br = Math.max(4, Math.round(radius*DPR))
          const sx = Math.max(0, bx-br), sy = Math.max(0, by-br)
          const sw = Math.min(base.width - sx, br*2)
          const sh = Math.min(base.height - sy, br*2)
          if(sw>0 && sh>0){
            const bctx = base.getContext('2d')!
            const src = bctx.getImageData(sx, sy, sw, sh)
            const off = document.createElement('canvas'); off.width=sw; off.height=sh
            const octx = off.getContext('2d')!
            const out = octx.createImageData(sw, sh)
            const sd = src.data; const od = out.data
            const cx = bx - sx, cy = by - sy
            // 严格只增强“星点”：高阈值 + 3x3 局部极大 + 相对优势
            const thr = 180 // 绝对亮度阈值（偏灰白基线下，星点核心仍显著）
            const delta = 24 // 相对邻域优势
            for(let j=1;j<sh-1;j++){
              for(let i=1;i<sw-1;i++){
                const di = (j*sw + i)*4
                const r = sd[di], g=sd[di+1], b=sd[di+2]
                const a = sd[di+3]
                if(a===0) continue
                const bright = Math.max(r,g,b)
                if(bright < thr) continue
                // 半径限制：只在点击圆内考虑，但不对边缘做任何渐变，避免可见圆圈
                const dx = i - cx, dy = j - cy
                const d2 = dx*dx + dy*dy
                const rr = br*br
                if(d2>rr) continue
                // 局部极大（3x3）：与 8 邻域比较
                const nb = [
                  (j-1)*sw + (i-1), (j-1)*sw + i, (j-1)*sw + (i+1),
                  j*sw + (i-1),                    j*sw + (i+1),
                  (j+1)*sw + (i-1), (j+1)*sw + i, (j+1)*sw + (i+1)
                ]
                let maxN = 0
                for(const idx of nb){
                  const k = idx*4
                  maxN = Math.max(maxN, sd[k], sd[k+1], sd[k+2])
                }
                if (bright < maxN + delta) continue
                // 仅对通过筛选的“星点像素”增亮：使用纯白 + 动态Alpha，实现灰→白→灰
                const aOut = Math.max(0, Math.min(255, Math.round(255 * amp)))
                od[di] = 255; od[di+1] = 255; od[di+2] = 255; od[di+3] = aOut
              }
            }
            octx.putImageData(out,0,0)
            const prevComp = ctx.globalCompositeOperation
            const prevSmooth = ctx.imageSmoothingEnabled
            ctx.imageSmoothingEnabled = false
            ctx.globalCompositeOperation = 'lighter' // 只会变亮，不影响背景
            ctx.drawImage(off, sx, sy)
            ctx.globalCompositeOperation = prevComp
            ctx.imageSmoothingEnabled = prevSmooth
          }
        }
      }
      raf = requestAnimationFrame(render)
    }
    raf = requestAnimationFrame(render)
    return ()=> cancelAnimationFrame(raf)
  },[baseCanvasRef])

  const handleClick: React.MouseEventHandler<HTMLCanvasElement> = (e)=>{
    const rect = (e.target as HTMLCanvasElement).getBoundingClientRect()
    const x = e.clientX - rect.left
    const y = e.clientY - rect.top
    const radius = Math.max(30, Math.min(sizeRef.current.w, sizeRef.current.h) * 0.035)
    animRef.current = { x, y, start: performance.now(), duration: 1100, radius }
  }

  const {w,h} = sizeRef.current
  return <canvas ref={canvasRef} className="absolute inset-0 z-10 pointer-events-auto" onClick={handleClick} />
}

export default ClickGlowOverlay
