import { create } from 'zustand'

export interface Site { id: string; x: number; y: number; seed: number }

interface GridState {
  width: number
  height: number
  sites: Site[]
  activeIds?: string[]
  neighbors?: number[][]
  labelMap?: HTMLCanvasElement
  labelMapRev?: number
  setCanvasSize: (w:number,h:number)=>void
  generateSites: (count?: number)=>void
  setActiveByPoint: (x:number,y:number)=>void
  rebuildLabelMap: ()=>void
  perturbActiveSite: (strength?: number)=>void
  buildNeighbors: (k?: number)=>void
  computeGraphDistances: (seedIds: string[])=> number[]
}

const rand = (s:number)=>{
  let t = s>>>0
  return ()=>{ t+=0x6D2B79F5; let r = Math.imul(t^(t>>>15), 1|t); r^= r + Math.imul(r^(r>>>7), 61|r); return ((r^(r>>>14))>>>0)/4294967296 }
}

export const useGalaxyGridStore = create<GridState>((set,get)=>({
  width:0,height:0,sites:[],neighbors:undefined,labelMap:undefined,labelMapRev:0,
  setCanvasSize:(w,h)=> set({width:w,height:h}),
  generateSites:(count=600)=>{
    const {width,height} = get(); if(!width||!height) return;
    const r = rand(0xABCDEF)
    const sites: Site[] = Array.from({length:count}, (_,i)=>({
      id: `site_${i}`, x: r()*width, y: r()*height, seed: i
    }))
    set({sites});
    get().buildNeighbors(6)
  },
  setActiveByPoint:(x,y)=>{
    const {sites, width, height} = get(); if(!sites.length||!width||!height) return;
    // 选择点击点附近多个站点（半径与屏幕尺寸相关），上限限定数量
    const shortEdge = Math.min(width, height)
    const pickRadius = Math.max(36, shortEdge * 0.05)
    const pickR2 = pickRadius*pickRadius
    const candidates: {id:string; d2:number}[] = []
    for(const s of sites){ const dx=x-s.x, dy=y-s.y; const d2=dx*dx+dy*dy; if(d2<=pickR2){ candidates.push({id:s.id, d2}) } }
    // 若范围内很少，则补齐最近的若干个
    if(candidates.length<3){
      const arr = sites.map(s=>({id:s.id, d2:(x-s.x)*(x-s.x)+(y-s.y)*(y-s.y)}))
      arr.sort((a,b)=>a.d2-b.d2)
      const extra = arr.slice(0, Math.max(3, Math.min(8, 3-candidates.length)))
      extra.forEach(e=>{ if(!candidates.find(c=>c.id===e.id)) candidates.push(e) })
    }
    candidates.sort((a,b)=>a.d2-b.d2)
    const selected = candidates.slice(0,8).map(c=>c.id)
    set({activeIds: selected})
  },
  perturbActiveSite:(strength=3)=>{
    const {activeIds, sites} = get(); if(!activeIds||!activeIds.length) return;
    const jitter = (range:number)=> (Math.random()*2-1)*range
    const ns = [...sites]
    for(const id of activeIds){
      const idx = ns.findIndex(s=>s.id===id); if(idx<0) continue;
      ns[idx] = { ...ns[idx], x: ns[idx].x + jitter(strength), y: ns[idx].y + jitter(strength) }
    }
    set({ sites: ns })
    get().rebuildLabelMap()
  },
  buildNeighbors:(k=6)=>{
    const {sites} = get(); if(!sites.length) return;
    const n = sites.length
    const neigh: number[][] = Array.from({length:n}, ()=>[])
    for(let i=0;i<n;i++){
      const si = sites[i]
      const arr: {idx:number; d2:number}[] = []
      for(let j=0;j<n;j++){ if(i===j) continue; const sj=sites[j]; const dx=si.x-sj.x, dy=si.y-sj.y; arr.push({idx:j, d2: dx*dx+dy*dy}) }
      arr.sort((a,b)=>a.d2-b.d2)
      neigh[i] = arr.slice(0, Math.min(k, arr.length)).map(o=>o.idx)
    }
    set({neighbors: neigh})
  },
  computeGraphDistances:(seedIds: string[])=>{
    const {sites, neighbors} = get();
    const n = sites.length; const dist = Array(n).fill(Infinity)
    if(n===0) return dist
    const idToIndex = new Map<string, number>()
    for(let i=0;i<n;i++) idToIndex.set(sites[i].id, i)
    const q: number[] = []
    for(const sid of seedIds){ const idx = idToIndex.get(sid); if(idx!=null){ dist[idx]=0; q.push(idx) } }
    const adj = neighbors || []
    let qi=0
    while(qi<q.length){
      const u = q[qi++]
      const du = dist[u]
      const nu = adj[u] || []
      for(const v of nu){ if(dist[v] > du + 1){ dist[v] = du + 1; q.push(v) } }
    }
    return dist
  },
  rebuildLabelMap:()=>{
    const {width,height,sites} = get(); if(!width||!height||!sites.length) return;
    const lw = 220, lh = Math.max(120, Math.round(lw * (height/Math.max(1,width))))
    const c = document.createElement('canvas'); c.width=lw; c.height=lh; const ctx = c.getContext('2d')!
    const img = ctx.createImageData(lw, lh)
    for(let j=0;j<lh;j++){
      for(let i=0;i<lw;i++){
        const x = (i+0.5)* (width/lw)
        const y = (j+0.5)* (height/lh)
        let minD=Infinity, idx=0
        for(let k=0;k<sites.length;k++){
          const s = sites[k]; const dx=x-s.x, dy=y-s.y; const d=dx*dx+dy*dy; if(d<minD){minD=d; idx=k}
        }
        // 将 idx 编码到 RGB，便于查询（低8位到R，中间到G，高到B）
        const off = (j*lw + i)*4
        img.data[off]   = idx & 0xFF
        img.data[off+1] = (idx>>8) & 0xFF
        img.data[off+2] = (idx>>16) & 0xFF
        img.data[off+3] = 255
      }
    }
    ctx.putImageData(img,0,0)
    set({labelMap:c, labelMapRev: (get().labelMapRev||0)+1})
  }
}))
