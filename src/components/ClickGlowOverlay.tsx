import React, { useEffect, useRef } from 'react'

interface GlowConfig {
  pickProb?: number;         // 选中比例（~0.2）
  pulseWidth?: number;       // 单像素脉冲宽度占比（~0.25）
  bandFactor?: number;       // 扩散软边相对半径比例（~0.12）
  noiseFactor?: number;      // 径向随机形变相对半径比例（~0.08）
  edgeAlphaThresh?: number;  // 掩膜边缘阈值（~8）
  edgeExponent?: number;     // 掩膜边缘权重幂（~1.1）
  radiusFactor?: number;     // 点击区域半径占短边比例（~0.035）
  minRadius?: number;        // 最小半径像素（~30）
  ease?: 'sine' | 'cubic';   // 呼吸曲线
  durationMs?: number;       // 总动画时长（毫秒，~1100）
}

interface Props {
  baseCanvasRef: React.RefObject<HTMLCanvasElement | null>
  starMaskRef?: React.RefObject<HTMLCanvasElement | null>
  config?: GlowConfig
}

// 简化版点击高亮：仅在点击附近让“已有星点”先变亮后回到原亮度
// 仅对小范围像素操作，基于底层画布采样，采用 screen 叠加，只会变亮
const ClickGlowOverlay: React.FC<Props> = ({ baseCanvasRef, starMaskRef, config }) => {
  const canvasRef = useRef<HTMLCanvasElement|null>(null)
  type Anim = { x:number;y:number;start:number;duration:number;radius:number; seed:number; sel?: { map: Uint8Array; jitter: Float32Array; gain: Float32Array; sw:number; sh:number; sx:number; sy:number } }
  const animRef = useRef<Anim|null>(null)
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
          const t01 = Math.max(0, Math.min(1, t))
          const ampGlobal = Math.sin(Math.PI * t01)
          // 抽取底层小块
          const bx = Math.round(x*DPR), by = Math.round(y*DPR)
          const br = Math.max(4, Math.round(radius*DPR))
          const sx = Math.max(0, bx-br), sy = Math.max(0, by-br)
          const sw = Math.min(base.width - sx, br*2)
          const sh = Math.min(base.height - sy, br*2)
          if(sw>0 && sh>0){
            const bctx = base.getContext('2d')!
            const src = bctx.getImageData(sx, sy, sw, sh)
            // 读取星点掩膜（若存在），用以限定“只对星点像素”操作
            let maskData: ImageData | null = null
            const mask = starMaskRef?.current || null
            if(mask){ const mctx = mask.getContext('2d')!; maskData = mctx.getImageData(sx, sy, sw, sh) }
            const off = document.createElement('canvas'); off.width=sw; off.height=sh
            const octx = off.getContext('2d')!
            const out = octx.createImageData(sw, sh)
            const sd = src.data; const od = out.data
            const cx = bx - sx, cy = by - sy
            // 基础中心→外扩参数
            const brPix = br
            const R = brPix * Math.min(1, t01)
            const band = Math.max(2, Math.round((config?.bandFactor ?? 0.12) * brPix))
            // 星点判定：优先使用掩膜，其次回退到阈值+局部极大
            const thr = 180 // 回退阈值
            const delta = 24 // 回退相对优势

            // 构建“仅1/5星点参与”的选择掩码（每次点击固定随机种子，保持一致）
            const ensureSelection = () => {
              const sel = new Uint8Array(sw*sh)
              const seed = anim.seed >>> 0
              const rand01 = (ix:number,iy:number)=>{
                let h = (ix+sx)|0; h ^= (iy+sy)<<13; h ^= seed
                h = (h ^ (h>>>17)) * 0x85ebca6b; h ^= h>>>13; h = (h*0xc2b2ae35) ^ (h>>>16)
                return ((h>>>0) % 10000) / 10000
              }
              const pickProb = config?.pickProb ?? 0.2
              const jitter = new Float32Array(sw*sh)
              const gain = new Float32Array(sw*sh)
              const rshift = new Float32Array(sw*sh)
              const noisePx = Math.max(0.5, (config?.noiseFactor ?? 0.08) * br)
              for(let j=1;j<sh-1;j++){
                for(let i=1;i<sw-1;i++){
                  const dx = i - cx, dy = j - cy
                  if (dx*dx + dy*dy > br*br) continue
                  // 候选中心：用掩膜高Alpha或亮度+局部极大
                  let isCore = false
                  if (maskData){
                    const mk = (j*sw + i)*4; const ma = maskData.data[mk+3]
                    if (ma >= 200) isCore = true
                  } else {
                    const di = (j*sw + i)*4
                    const bright = Math.max(sd[di],sd[di+1],sd[di+2])
                    if (bright >= thr){
                      const nb = [
                        (j-1)*sw + (i-1), (j-1)*sw + i, (j-1)*sw + (i+1),
                        j*sw + (i-1),                    j*sw + (i+1),
                        (j+1)*sw + (i-1), (j+1)*sw + i, (j+1)*sw + (i+1)
                      ]
                      let maxN = 0
                      for(const idx of nb){ const k = idx*4; maxN = Math.max(maxN, sd[k], sd[k+1], sd[k+2]) }
                      if (bright >= maxN + delta) isCore = true
                    }
                  }
                  if (!isCore) continue
                  if (rand01(i,j) > pickProb) continue
                  // 用掩膜/亮度做小区域泛洪，选择整颗星形状（含抗锯齿边缘）
                  const stackI:number[] = [i];
                  const stackJ:number[] = [j];
                  // 为整颗星分配统一的时序与强度，让“大星整颗一起亮”，而不是像素散点
                  const compJ = rand01(i,j) * 0.8; // 触发时刻 0..0.8
                  const compG = 0.8 + 0.4 * rand01(i*3+7, j*5+11); // 强度增益 0.8..1.2
                  const compRS = (rand01(i*11+5, j*13+9) - 0.5) * 2 * noisePx; // 局部径向形变
                  while(stackI.length){
                    const ci = stackI.pop()!; const cj = stackJ.pop()!
                    if (ci<0||ci>=sw||cj<0||cj>=sh) continue
                    const dx2 = ci - cx, dy2 = cj - cy
                    if (dx2*dx2 + dy2*dy2 > br*br) continue
                    const idp = cj*sw + ci
                    if (sel[idp]===1) continue
                    if (maskData){
                      const mk = idp*4; const ma = maskData.data[mk+3]
                      if (ma <= (config?.edgeAlphaThresh ?? 8)) continue
                    } else {
                      const kd = idp*4
                      const bmax = Math.max(sd[kd],sd[kd+1],sd[kd+2])
                      if (bmax < thr) continue
                    }
                    sel[idp] = 1
                    jitter[idp] = compJ
                    gain[idp] = compG
                    rshift[idp] = compRS
                    // 4-连通
                    stackI.push(ci+1, ci-1, ci,   ci)
                    stackJ.push(cj,   cj,   cj+1, cj-1)
                  }
                }
              }
              anim.sel = { map: sel, jitter, gain, rshift, sw, sh, sx, sy }
            }
            ensureSelection();
            for(let j=1;j<sh-1;j++){
              for(let i=1;i<sw-1;i++){
                const di = (j*sw + i)*4
                const r = sd[di], g=sd[di+1], b=sd[di+2]
                const a = sd[di+3]
                if(a===0) continue
                // 半径限制：只在点击圆内考虑，但不对边缘做任何渐变，避免可见圆圈
                const dx = i - cx, dy = j - cy
                const d2 = dx*dx + dy*dy
                const rr = br*br
                if(d2>rr) continue
                // 仅对选中子集进行处理
                if (!anim.sel || anim.sel.sw!==sw || anim.sel.sh!==sh || anim.sel.sx!==sx || anim.sel.sy!==sy) continue
                if (anim.sel.map[j*sw + i] !== 1) continue
                let isStar = false
                let maskEdgeWeight = 1
                if(maskData){
                  const mk = (j*sw + i)*4; const ma = maskData.data[mk+3]
                  const thresh = config?.edgeAlphaThresh ?? 8
                  const exp = config?.edgeExponent ?? 1.1
                  if (ma <= thresh) { continue }
                  isStar = true
                  maskEdgeWeight = Math.pow(ma/255, exp)
                } else {
                  const bright = Math.max(r,g,b)
                  if(bright < thr) continue
                  // 局部极大（3x3）：与 8 邻域比较
                  const nb = [
                    (j-1)*sw + (i-1), (j-1)*sw + i, (j-1)*sw + (i+1),
                    j*sw + (i-1),                    j*sw + (i+1),
                    (j+1)*sw + (i-1), (j+1)*sw + i, (j+1)*sw + (i+1)
                  ]
                  let maxN = 0
                  for(const idx of nb){ const k = idx*4; maxN = Math.max(maxN, sd[k], sd[k+1], sd[k+2]) }
                  if (bright >= maxN + delta) isStar = true
                }
                if(!isStar) continue
                // 立即亮起 + 缓慢不规律熄灭：去除到达延迟与呼吸等待
                const idp = j*sw + i
                const gainLocal = anim.sel.gain ? anim.sel.gain[idp] : 1
                // 指数衰减（不规律）：速率基于像素与种子
                const h1 = ((i*73856093) ^ (j*19349663) ^ anim.seed) >>> 0
                const rand01 = (h:number)=> ((h ^ (h>>>16)) & 0xFFFF)/65535
                const lambda = 0.8 + 1.6 * rand01(h1)
                let amp = Math.exp(-lambda * t01)
                // 轻微闪烁（不规律）：低幅度正弦调制
                const h2 = ((i*83492791) ^ (j*2971215073) ^ (anim.seed>>>1)) >>> 0
                const freq = 0.6 + 1.4 * rand01(h2)
                const phaseN = 2*Math.PI*rand01(h2>>>1)
                const flick = 0.9 + 0.1*Math.sin(2*Math.PI*freq*t01 + phaseN)
                if (t01 < 0.05) amp = 1 // 点击瞬间立刻满亮
                const localAmp = Math.max(0, Math.min(1, amp * flick * gainLocal))
                if (localAmp <= 0.01) continue
                const aOut = Math.max(0, Math.min(255, Math.round(255 * localAmp * maskEdgeWeight)))
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
    const factor = config?.radiusFactor ?? 0.035
    const minR = config?.minRadius ?? 30
    const radius = Math.max(minR, Math.min(sizeRef.current.w, sizeRef.current.h) * factor)
    // 固定种子：使同一次点击动画期间选择的星点一致
    const seed = Math.floor(x*911 + y*613 + performance.now()) >>> 0
    const duration = config?.durationMs ?? 1100
    animRef.current = { x, y, start: performance.now(), duration, radius, seed }
  }

  const {w,h} = sizeRef.current
  return <canvas ref={canvasRef} className="absolute inset-0 z-10 pointer-events-auto" onClick={handleClick} />
}

export default ClickGlowOverlay
