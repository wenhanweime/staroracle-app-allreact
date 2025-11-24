#!/usr/bin/env python3
import re
from pathlib import Path

orig_dir = Path('ref/pixelplanet_final/PixelPlanetsSwift/Sources/PixelPlanetsCore/Planets')
ours_dir = Path('StarO/StarO/PixelPlanets/Core/Planets')
planet_files = sorted({p.name for p in orig_dir.glob('*.swift')} | {p.name for p in ours_dir.glob('*.swift')})

layer_def_re = re.compile(r'LayerDefinition\(\s*name:\s*"([^"]+)",\s*\n\s*shaderPath:\s*"([^"]+)",\s*\n\s*uniforms:\s*([^,\)]+?),\s*\n\s*colors:\s*\[(.*?)\]\s*\)', re.S)
let_dict_re = re.compile(r'let\s+([A-Za-z0-9_]+)\s*:\s*\[String:\s*UniformValue\]\s*=\s*\[(.*?)\]\s*\n', re.S)
let_dict_re2 = re.compile(r'let\s+([A-Za-z0-9_]+)\s*=\s*\[(.*?)\]\s*\n', re.S)
color_binding_re = re.compile(r'ColorBinding\(layer:\s*"([^"]+)",\s*uniform:\s*"([^"]+)",\s*slots:\s*(\d+)\)')
rs_rels = re.compile(r'relativeScale:\s*([0-9]+(?:\.[0-9]+)?)\s*,')
rs_gui = re.compile(r'guiZoom:\s*([0-9]+(?:\.[0-9]+)?)\s*,')
func_re = re.compile(r'public\s+override\s+func\s+([A-Za-z0-9_]+)\s*\(')
uc_re = re.compile(r'UniformControl\(layer:\s*"([^"]+)",\s*uniform:\s*"([^"]+)",[^\)]*?min:\s*([-0-9\.]+)\s*,\s*max:\s*([-0-9\.]+)\s*,\s*step:\s*([-0-9\.]+)\)', re.S)

def read(p:Path):
    try:
        return p.read_text(encoding='utf-8')
    except: return ''

def strip_comments(s:str)->str:
    out=[]
    for line in s.splitlines():
        if '//' in line: line=line.split('//',1)[0]
        out.append(line)
    return '\n'.join(out)

def parse_uniforms_dict(text:str):
    s=strip_comments(text.strip())
    if s.startswith('[') and s.endswith(']'):
        s=s[1:-1]
    pairs=[]; i=0; n=len(s)
    while i<n:
        while i<n and s[i] in ' \n\t,': i+=1
        if i>=n: break
        if s[i] != '"':
            j=s.find(',', i)
            if j==-1: break
            i=j+1
            continue
        i+=1; kstart=i
        while i<n and s[i] != '"': i+=1
        key=s[kstart:i]; i+=1
        while i<n and s[i] in ' \t\n': i+=1
        if i<n and s[i]==':': i+=1
        while i<n and s[i] in ' \t\n': i+=1
        depth_par=0; depth_sq=0; in_str=False
        vstart=i
        while i<n:
            ch=s[i]
            if ch=='"': in_str=not in_str; i+=1; continue
            if not in_str:
                if ch=='(': depth_par+=1
                elif ch==')': depth_par=max(0,depth_par-1)
                elif ch=='[': depth_sq+=1
                elif ch==']': depth_sq=max(0,depth_sq-1)
                elif ch==',' and depth_par==0 and depth_sq==0:
                    break
            i+=1
        val=s[vstart:i].strip()
        val=' '.join(val.split())
        if val.startswith('.buffer('): val='.buffer(...)'
        pairs.append((key,val))
        if i<n and s[i]==',': i+=1
    return dict(pairs)


def parse_planet(src:str):
    data={'relativeScale':None,'guiZoom':None,'layers':{},'functions':set(),'uniformControls':[]}
    if not src: return data
    m=rs_rels.search(src)
    if m: data['relativeScale']=m.group(1)
    m=rs_gui.search(src)
    if m: data['guiZoom']=m.group(1)
    data['functions']=set(func_re.findall(src))
    for m in uc_re.finditer(src):
        data['uniformControls'].append({'layer':m.group(1),'uniform':m.group(2),'min':m.group(3),'max':m.group(4),'step':m.group(5)})
    dicts={}
    for m in let_dict_re.finditer(src):
        dicts[m.group(1)]=parse_uniforms_dict('['+m.group(2)+']')
    for m in let_dict_re2.finditer(src):
        if m.group(1) not in dicts:
            d=parse_uniforms_dict('['+m.group(2)+']')
            if d: dicts[m.group(1)]=d
    for m in layer_def_re.finditer(src):
        lname=m.group(1); spath=m.group(2); uexpr=m.group(3).strip(); colors_body=m.group(4)
        if uexpr.startswith('['): uniforms=parse_uniforms_dict(uexpr)
        else: uniforms=dicts.get(uexpr,{})
        colors=[{'uniform':cm.group(2),'slots':cm.group(3)} for cm in color_binding_re.finditer(colors_body)]
        data['layers'][lname]={'shaderPath':spath,'uniforms':uniforms,'colors':colors}
    return data


def cmp(a,b): return 'SAME' if a==b else 'DIFF'

def md_escape(s):
    if s is None: return 'None'
    return str(s).replace('|','\\|')

lines=["# PixelPlanets 原版 vs 当前版本 代码级对比（函数/参数）\n\n说明：脚本自动生成，包含：\n- 概要（relativeScale、guiZoom）\n- 函数覆写（是否存在）\n- UniformControls（min/max/step）\n- 每个 Layer 的 shaderPath、ColorBindings、uniform 默认值\n\n"]

for fname in planet_files:
    o=parse_planet(read(orig_dir/fname))
    n=parse_planet(read(ours_dir/fname))
    lines.append(f"## {fname}\n")
    lines.append("| 项 | 原版 | 当前 | 状态 |\n|---|---|---|---|")
    lines.append(f"| relativeScale | {md_escape(o['relativeScale'])} | {md_escape(n['relativeScale'])} | {cmp(o['relativeScale'],n['relativeScale'])} |")
    lines.append(f"| guiZoom | {md_escape(o['guiZoom'])} | {md_escape(n['guiZoom'])} | {cmp(o['guiZoom'],n['guiZoom'])} |\n")
    lines.append("- 函数覆写\n")
    lines.append("| 函数 | 原版 | 当前 | 状态 |\n|---|---|---|---|")
    allf=sorted(set(o['functions'])|set(n['functions']))
    for f in allf:
        lines.append(f"| {f} | {'Y' if f in o['functions'] else 'N'} | {'Y' if f in n['functions'] else 'N'} | {cmp(f in o['functions'], f in n['functions'])} |")
    lines.append("\n- UniformControls\n")
    lines.append("| layer.uniform | 原版(min,max,step) | 当前(min,max,step) | 状态 |\n|---|---|---|---|")
    o_uc={(uc['layer'],uc['uniform']):(uc['min'],uc['max'],uc['step']) for uc in o['uniformControls']}
    n_uc={(uc['layer'],uc['uniform']):(uc['min'],uc['max'],uc['step']) for uc in n['uniformControls']}
    for key in sorted(set(o_uc)|set(n_uc)):
        lines.append(f"| {key[0]}.{key[1]} | {md_escape(o_uc.get(key))} | {md_escape(n_uc.get(key))} | {cmp(o_uc.get(key),n_uc.get(key))} |")
    lines.append("\n- Layers\n")
    for lname in sorted(set(o['layers'])|set(n['layers'])):
        ol=o['layers'].get(lname); nl=n['layers'].get(lname)
        lines.append(f"### Layer: {lname}\n")
        if not ol or not nl:
            lines.append(f"(存在性对比) 原版={bool(ol)} 当前={bool(nl)} 状态=DIFF\n")
            continue
        lines.append("| 项 | 原版 | 当前 | 状态 |\n|---|---|---|---|")
        lines.append(f"| shaderPath | {md_escape(ol['shaderPath'])} | {md_escape(nl['shaderPath'])} | {cmp(ol['shaderPath'],nl['shaderPath'])} |")
        o_cs=[(c['uniform'],c['slots']) for c in ol['colors']]
        n_cs=[(c['uniform'],c['slots']) for c in nl['colors']]
        lines.append(f"| ColorBindings | {md_escape(o_cs)} | {md_escape(n_cs)} | {cmp(o_cs,n_cs)} |\n")
        lines.append("| uniform | 原版默认值 | 当前默认值 | 状态 |\n|---|---|---|---|")
        keys=sorted(set(ol['uniforms'])|set(nl['uniforms']))
        for k in keys:
            lines.append(f"| {k} | {md_escape(ol['uniforms'].get(k))} | {md_escape(nl['uniforms'].get(k))} | {cmp(ol['uniforms'].get(k),nl['uniforms'].get(k))} |")
    lines.append("\n")

Path('docs').mkdir(exist_ok=True)
Path('docs/pixelplanets_diff.md').write_text('\n'.join(lines), encoding='utf-8')
print('Wrote docs/pixelplanets_diff.md')
