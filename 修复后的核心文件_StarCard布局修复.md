Project Path: staroracle-app_v1

Source Tree:

```txt
staroracle-app_v1
└── src
    ├── components
    │   ├── StarCard.tsx
    │   └── StarCollection.tsx
    └── index.css

```

`staroracle-app_v1/src/components/StarCard.tsx`:

```tsx
import React, { useState, useMemo, useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import { Calendar, Heart } from 'lucide-react';
import { Star as IStar } from '../types';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import StarRayIcon from './StarRayIcon';

// 星星样式类型
const STAR_STYLES = {
  STANDARD: 'standard', // 标准8条光芒
  CROSS: 'cross',       // 十字形
  BURST: 'burst',       // 爆发式
  SPARKLE: 'sparkle',   // 闪烁式
  RINGED: 'ringed',     // 带环星
  // 行星样式
  PLANET_SMOOTH: 'planet_smooth',   // 平滑行星
  PLANET_CRATERS: 'planet_craters', // 陨石坑行星
  PLANET_SEAS: 'planet_seas',       // 海洋行星
  PLANET_DUST: 'planet_dust',       // 尘埃行星
  PLANET_RINGS: 'planet_rings'      // 带环行星
};

// 宇宙色彩主题
const COSMIC_PALETTES = [
  { 
    name: '深空蓝', 
    inner: 'hsl(250, 40%, 20%)', 
    outer: 'hsl(230, 50%, 5%)',
    star: 'hsl(220, 100%, 85%)',
    accent: 'hsl(240, 70%, 70%)'
  },
  { 
    name: '星云紫', 
    inner: 'hsl(280, 50%, 18%)', 
    outer: 'hsl(260, 60%, 4%)',
    star: 'hsl(290, 100%, 85%)',
    accent: 'hsl(280, 70%, 70%)'
  },
  { 
    name: '远古红', 
    inner: 'hsl(340, 45%, 15%)', 
    outer: 'hsl(320, 50%, 5%)',
    star: 'hsl(350, 100%, 85%)',
    accent: 'hsl(340, 70%, 70%)'
  },
  { 
    name: '冰晶蓝', 
    inner: 'hsl(200, 50%, 15%)', 
    outer: 'hsl(220, 60%, 6%)',
    star: 'hsl(190, 100%, 85%)',
    accent: 'hsl(200, 70%, 70%)'
  }
];

interface StarCardProps {
  star: IStar;
  isFlipped?: boolean;
  onFlip?: () => void;
  showActions?: boolean;
  starStyle?: string; // 可选的星星样式
  colorTheme?: number; // 可选的颜色主题索引
  onContextMenu?: (e: React.MouseEvent) => void; // 右键菜单回调
}

const StarCard: React.FC<StarCardProps> = ({ 
  star, 
  isFlipped = false, 
  onFlip,
  showActions = true,
  starStyle,
  colorTheme,
  onContextMenu
}) => {
  const [isHovered, setIsHovered] = useState(false);
  const planetCanvasRef = useRef<HTMLCanvasElement>(null);
  
  // 为每个星星确定一个稳定的样式和颜色主题
  const { style, theme, hasRing, dustCount } = useMemo(() => {
    // 使用星星ID作为随机种子，确保同一个星星总是有相同的样式
    const seed = star.id.split('-')[1] ? parseInt(star.id.split('-')[1]) : Date.now();
    const seedRandom = (min: number, max: number) => {
      const x = Math.sin(seed) * 10000;
      const r = x - Math.floor(x);
      return Math.floor(r * (max - min + 1)) + min;
    };
    
    // 获取所有可能的样式
    const allStyles = Object.values(STAR_STYLES);
    const randomStyle = starStyle || allStyles[seedRandom(0, allStyles.length - 1)];
    const randomTheme = colorTheme !== undefined ? colorTheme : seedRandom(0, 3);
    const randomHasRing = star.isSpecial ? (seedRandom(0, 10) > 6) : false;
    const randomDustCount = seedRandom(5, star.isSpecial ? 20 : 10);
    
    return {
      style: randomStyle,
      theme: randomTheme,
      hasRing: randomHasRing,
      dustCount: randomDustCount
    };
  }, [star.id, star.isSpecial, starStyle, colorTheme]);
  
  // 获取当前颜色主题
  const currentTheme = COSMIC_PALETTES[theme];
  
  // 星星基本颜色（特殊星星使用主题色，普通星星使用白色）
  const starColor = star.isSpecial ? currentTheme.accent : currentTheme.star;
  
  // 随机生成尘埃粒子
  const dustParticles = useMemo(() => {
    return Array.from({ length: dustCount }).map((_, i) => {
      const angle = Math.random() * Math.PI * 2;
      const distance = 30 + Math.random() * 40;
      return {
        id: i,
        x: 100 + Math.cos(angle) * distance,
        y: 100 + Math.sin(angle) * distance,
        size: Math.random() * 1.5 + 0.5,
        opacity: Math.random() * 0.7 + 0.3,
        animationDuration: 2 + Math.random() * 3
      };
    });
  }, [dustCount]);
  
  // 生成星环配置（如果有）
  const ringConfig = useMemo(() => {
    if (!hasRing) return null;
    
    const ringTilt = (Math.random() - 0.5) * 0.8;
    return {
      tilt: ringTilt,
      radiusX: 25,
      radiusY: 25 * 0.35,
      color: starColor,
      lineWidth: 1.5
    };
  }, [hasRing, starColor]);

  // 处理右键点击，显示灵感卡片
  const handleContextMenu = (e: React.MouseEvent) => {
    e.preventDefault();
    if (onContextMenu) {
      onContextMenu(e);
    }
  };

  // 行星绘制函数 - 从star-plantegenerate.html移植
  useEffect(() => {
    // 只有当样式是行星类型且canvas存在时绘制行星
    if (!style.startsWith('planet_') || !planetCanvasRef.current) return;
    
    const canvas = planetCanvasRef.current;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    
    // 设置canvas尺寸 - 提高分辨率，解决模糊和锯齿问题
    const scale = window.devicePixelRatio || 2; // 使用设备像素比或至少2倍
    canvas.width = 200 * scale;
    canvas.height = 200 * scale;
    ctx.scale(scale, scale); // 缩放上下文以匹配更高的分辨率
    
    // 启用抗锯齿
    ctx.imageSmoothingEnabled = true;
    ctx.imageSmoothingQuality = 'high';
    
    // 使用星星ID作为随机种子
    const seed = star.id.split('-')[1] ? parseInt(star.id.split('-')[1]) : Date.now();
    const seedRandom = (min: number, max: number) => {
      const x = Math.sin(seed) * 10000;
      const r = x - Math.floor(x);
      return Math.floor(r * (max - min + 1)) + min;
    };
    
    // 星球绘制工具函数
    const drawPlanet = () => {
      try {
        // 清空画布
        ctx.clearRect(0, 0, 200, 200); // 注意：这里使用逻辑尺寸200x200
        
        // 背景为透明
        ctx.fillStyle = 'rgba(0,0,0,0)';
        ctx.fillRect(0, 0, 200, 200);
        
        // 使用与星星相同的色系逻辑
        // 星星基本颜色（特殊星星使用主题色，普通星星使用白色）
        const planetBaseColor = star.isSpecial ? currentTheme.accent : currentTheme.star;
        
        // 解析HSL颜色值以获取色相、饱和度和亮度
        let hue = 0, saturation = 0, lightness = 70;
        
        try {
          const hslMatch = planetBaseColor.match(/hsl\((\d+),\s*(\d+)%,\s*(\d+)%\)/);
          if (hslMatch && hslMatch.length >= 4) {
            hue = parseInt(hslMatch[1]);
            saturation = parseInt(hslMatch[2]);
            lightness = parseInt(hslMatch[3]);
          }
        } catch (e) {
          console.error('HSL解析错误:', e);
          // 使用默认值
          hue = 0;
          saturation = 0;
          lightness = 70;
        }
        
        // 为行星创建自己的色系，基于星星的颜色
        const baseLightness = Math.max(40, lightness - 20); // 比星星暗一些
        const lightRange = 25 + seedRandom(0, 20);
        const darkL = baseLightness - lightRange / 2;
        const lightL = baseLightness + lightRange / 2;
        
        const palette = { 
          base: `hsl(${hue}, ${saturation * 0.7}%, ${baseLightness}%)`, 
          shadow: `hsl(${hue}, ${saturation * 0.5}%, ${darkL}%)`, 
          highlight: `hsl(${hue}, ${saturation * 0.9}%, ${lightL}%)`,
          glow: planetBaseColor
        };
        
        // 星球半径（canvas中心点为100,100）- 缩小到原来的一半
        const planetRadius = (15 + seedRandom(0, 5)); // 原来是30+seedRandom(0,10)
        const planetX = 100; // 保持在中心位置
        const planetY = 100;
        
        // 星球配置
        const planet = {
          x: planetX,
          y: planetY,
          radius: planetRadius,
          palette: palette,
          shading: {
            lightAngle: seedRandom(0, 628) / 100, // 0 to 2π
            numBands: 5 + seedRandom(0, 5),
            darkL: darkL,
            lightL: lightL
          }
        };
        
        // 是否有行星环
        const hasPlanetRings = style === 'planet_rings' || (style.startsWith('planet_') && seedRandom(0, 10) > 7);
        const ringConfig = hasPlanetRings ? {
          tilt: (seedRandom(0, 100) - 50) / 100 * 0.8,
          radius: planetRadius * 1.6,
          color: palette.base,
          lineWidth: 1 + seedRandom(0, 1) // 减小线宽
        } : null;
        
        // 绘制小星星
        const drawStars = () => {
          ctx.save();
          for (let i = 0; i < 30; i++) {
            const x = Math.random() * 200;
            const y = Math.random() * 200;
            const size = Math.random() * 1.2 + 0.3; // 稍微减小星星大小
            ctx.fillStyle = '#ffffff';
            ctx.globalAlpha = Math.random() * 0.7 + 0.1;
            ctx.fillRect(x, y, size, size);
          }
          ctx.restore();
        };
        
        // 绘制行星光晕 - 参考放射状星星的中心光晕
        const drawPlanetGlow = () => {
          try {
            ctx.save();
            
            // 创建径向渐变
            const gradient = ctx.createRadialGradient(
              planet.x, planet.y, planet.radius * 0.8,
              planet.x, planet.y, planet.radius * 3
            );
            
            // 设置渐变颜色 - 修复可能的颜色格式问题
            const safeGlowColor = palette.glow || 'rgba(255,255,255,0.7)';
            gradient.addColorStop(0, safeGlowColor.replace(')', ', 0.7)').replace('rgb', 'rgba')); // 半透明
            gradient.addColorStop(0.5, safeGlowColor.replace(')', ', 0.3)').replace('rgb', 'rgba')); // 更透明
            gradient.addColorStop(1, 'rgba(0,0,0,0)'); // 完全透明
            
            // 绘制光晕
            ctx.globalCompositeOperation = 'screen'; // 使用screen混合模式增强发光效果
            ctx.fillStyle = gradient;
            ctx.beginPath();
            ctx.arc(planet.x, planet.y, planet.radius * 3, 0, Math.PI * 2);
            ctx.fill();
            
            ctx.restore();
          } catch (e) {
            console.error('绘制光晕错误:', e);
            ctx.restore();
          }
        };
        
        // 绘制星球阴影
        const drawShadow = () => {
          const lightAngle = planet.shading.lightAngle;
          const numBands = planet.shading.numBands;
          const darkL = planet.shading.darkL;
          const lightL = planet.shading.lightL;
          const lightVec = { x: Math.cos(lightAngle), y: Math.sin(lightAngle) };
          const totalOffset = planet.radius * 0.8;
          
          for (let i = 0; i < numBands; i++) {
            const t = i / (numBands - 1);
            const currentL = darkL + t * (lightL - darkL);
            const currentColor = `hsl(${hue}, ${Math.max(0, saturation - 20 + t * 20)}%, ${currentL}%)`;
            const offsetFactor = -1 + 2 * t;
            const offsetX = lightVec.x * totalOffset * offsetFactor * -0.5;
            const offsetY = lightVec.y * totalOffset * offsetFactor * -0.5;
            
            ctx.beginPath();
            ctx.arc(planet.x - offsetX, planet.y - offsetY, planet.radius, 0, Math.PI * 2);
            ctx.fillStyle = currentColor;
            ctx.fill();
          }
        };
        
        // 绘制行星环背面 - 修复椭圆比例问题
        const drawRingBack = () => {
          if (!hasPlanetRings || !ringConfig) return;
          
          ctx.save();
          ctx.translate(planet.x, planet.y);
          ctx.rotate(ringConfig.tilt);
          const radiusX = ringConfig.radius;
          const radiusY = ringConfig.radius * 0.3; // 调整Y轴半径以修复椭圆比例
          
          ctx.beginPath();
          ctx.ellipse(0, 0, radiusX, radiusY, 0, Math.PI, Math.PI * 2);
          ctx.strokeStyle = palette.base;
          ctx.lineWidth = ringConfig.lineWidth;
          ctx.globalAlpha = 0.6;
          ctx.stroke();
          ctx.restore();
        };
        
        // 绘制行星环前面 - 修复椭圆比例问题
        const drawRingFront = () => {
          if (!hasPlanetRings || !ringConfig) return;
          
          ctx.save();
          ctx.translate(planet.x, planet.y);
          ctx.rotate(ringConfig.tilt);
          const radiusX = ringConfig.radius;
          const radiusY = ringConfig.radius * 0.3; // 调整Y轴半径以修复椭圆比例
          
          ctx.beginPath();
          ctx.ellipse(0, 0, radiusX, radiusY, 0, 0, Math.PI);
          ctx.strokeStyle = palette.base;
          ctx.lineWidth = ringConfig.lineWidth;
          ctx.globalAlpha = 0.8;
          ctx.stroke();
          ctx.restore();
        };
        
        // 绘制尘埃
        const drawDust = () => {
          ctx.save();
          ctx.translate(planet.x, planet.y);
          ctx.beginPath();
          ctx.arc(0, 0, planet.radius, 0, 2 * Math.PI);
          ctx.clip();
          
          const numDust = 10 + seedRandom(0, 10); // 减少尘埃数量
          for (let i = 0; i < numDust; i++) {
            const angle = seedRandom(0, 628) / 100;
            const distance = seedRandom(0, Math.floor(planet.radius * 100)) / 100;
            const x = Math.cos(angle) * distance;
            const y = Math.sin(angle) * distance;
            const radius = seedRandom(0, 10) / 10 + 0.3; // 减小尘埃大小
            
            ctx.beginPath();
            ctx.arc(x, y, radius, 0, 2 * Math.PI);
            ctx.fillStyle = palette.highlight;
            ctx.globalAlpha = 0.8;
            ctx.fill();
          }
          ctx.restore();
        };
        
        // 绘制陨石坑
        const drawCraters = () => {
          ctx.save();
          ctx.translate(planet.x, planet.y);
          ctx.beginPath();
          ctx.arc(0, 0, planet.radius, 0, 2 * Math.PI);
          ctx.clip();
          
          const craterCount = 5 + seedRandom(0, 10); // 减少陨石坑数量
          
          for (let i = 0; i < craterCount; i++) {
            const angle = seedRandom(0, 628) / 100;
            const distance = seedRandom(0, Math.floor(planet.radius * 80)) / 100;
            const x = Math.cos(angle) * distance;
            const y = Math.sin(angle) * distance;
            const radius = (seedRandom(0, 6) / 100 + 0.01) * planet.radius;
            
            // 计算陨石坑透视效果
            const distFromPlanetCenter = Math.sqrt(x * x + y * y);
            const MIN_SQUASH = 0.1;
            const relativeDist = Math.min(distFromPlanetCenter / planet.radius, 1.0);
            const squashFactor = Math.max(MIN_SQUASH, Math.sqrt(1.0 - Math.pow(relativeDist, 2)));
            const radiusMajor = radius;
            const radiusMinor = radius * squashFactor;
            const radialAngle = Math.atan2(y, x);
            const rotation = radialAngle + Math.PI / 2;
            
            ctx.beginPath();
            ctx.ellipse(x, y, radiusMajor, radiusMinor, rotation, 0, 2 * Math.PI);
            ctx.fillStyle = seedRandom(0, 10) > 5 ? palette.shadow : palette.highlight;
            ctx.globalAlpha = 0.6;
            ctx.fill();
          }
          
          ctx.restore();
        };
        
        // 添加一些光晕射线效果
        const drawGlowRays = () => {
          if (!star.isSpecial) return; // 只为特殊星星添加射线
          
          try {
            ctx.save();
            ctx.translate(planet.x, planet.y);
            
            const rayCount = 4 + seedRandom(0, 4);
            const baseAngle = seedRandom(0, 100) / 100 * Math.PI;
            
            for (let i = 0; i < rayCount; i++) {
              const angle = baseAngle + (i * Math.PI * 2) / rayCount;
              const length = planet.radius * (2 + seedRandom(0, 20) / 10);
              
              ctx.beginPath();
              ctx.moveTo(0, 0);
              ctx.lineTo(Math.cos(angle) * length, Math.sin(angle) * length);
              
              // 创建线性渐变
              const gradient = ctx.createLinearGradient(0, 0, Math.cos(angle) * length, Math.sin(angle) * length);
              const safeGlowColor = palette.glow || 'rgba(255,255,255,0.9)';
              gradient.addColorStop(0, safeGlowColor.replace(')', ', 0.9)').replace('rgb', 'rgba'));
              gradient.addColorStop(1, 'rgba(0,0,0,0)');
              
              ctx.strokeStyle = gradient;
              ctx.lineWidth = 1 + seedRandom(0, 10) / 10;
              ctx.globalAlpha = 0.3 + seedRandom(0, 5) / 10;
              ctx.stroke();
            }
            
            ctx.restore();
          } catch (e) {
            console.error('绘制光晕射线错误:', e);
            ctx.restore();
          }
        };
        
        // 绘制流程
        // 1. 首先绘制光晕
        drawPlanetGlow();
        
        // 2. 绘制背景星星
        drawStars();
        
        // 3. 如果有行星环，绘制背面部分
        if (hasPlanetRings) {
          drawRingBack();
        }
        
        // 4. 绘制主星球
        ctx.save();
        ctx.beginPath();
        ctx.arc(planet.x, planet.y, planet.radius, 0, 2 * Math.PI);
        ctx.clip();
        drawShadow();
        ctx.restore();
        
        // 5. 根据星球类型绘制不同特征
        if (style === STAR_STYLES.PLANET_CRATERS) {
          drawCraters();
        } else if (style === STAR_STYLES.PLANET_DUST) {
          drawDust();
        }
        
        // 6. 如果有行星环，绘制前部
        if (hasPlanetRings) {
          drawRingFront();
        }
        
        // 7. 为特殊星球添加光晕射线
        drawGlowRays();
      } catch (error) {
        console.error('行星绘制错误:', error);
      }
    };
    
    drawPlanet();
    
  }, [style, star.id, currentTheme, starColor]);

  return (
    <motion.div
      className="star-card-container"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      whileHover={{ y: -5 }}
      onHoverStart={() => setIsHovered(true)}
      onHoverEnd={() => setIsHovered(false)}
      onContextMenu={handleContextMenu}
    >
      <div className="star-card-wrapper">
        <motion.div
          className="star-card"
          animate={{ rotateY: isFlipped ? 180 : 0 }}
          transition={{ duration: 0.6, type: "spring" }}
          onClick={onFlip}
        >
          {/* Front Side - Star Design */}
          <div className="star-card-face star-card-front">
            <div className="star-card-bg"
              style={{
                background: `radial-gradient(circle, ${currentTheme.inner} 0%, ${currentTheme.outer} 100%)`,
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'space-between', // 修改为 space-between
                position: 'relative'
              }}
            >
              <div className="star-card-constellation" style={{
                flex: '1', // 让它自由伸缩，占据剩余空间
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                position: 'relative',
                width: '100%'
              }}>
                {/* 渲染行星类型星星 */}
                {style.startsWith('planet_') && (
                  <canvas 
                    ref={planetCanvasRef} 
                    width="200" 
                    height="200" 
                    className="planet-canvas"
                    style={{
                      width: '160px',
                      height: '160px',
                      maxWidth: '160px',
                      maxHeight: '160px',
                      display: 'block', // 确保canvas是块级元素
                      margin: '0 auto' // 水平居中
                    }}
                  />
                )}
                
                {/* 星星模式 - 仅在非行星样式时显示 */}
                {!style.startsWith('planet_') && (
                  <svg className="constellation-svg" viewBox="0 0 200 200">
                    <defs>
                      <radialGradient id={`starGlow-${star.id}`} cx="50%" cy="50%" r="50%">
                        <stop offset="0%" stopColor={starColor} stopOpacity="0.8"/>
                        <stop offset="100%" stopColor={starColor} stopOpacity="0"/>
                      </radialGradient>
                      
                      {/* 添加星环滤镜 */}
                      <filter id={`glow-${star.id}`} x="-50%" y="-50%" width="200%" height="200%">
                        <feGaussianBlur stdDeviation="2" result="blur" />
                        <feComposite in="SourceGraphic" in2="blur" operator="over" />
                      </filter>
                    </defs>
                    
                    {/* 背景星星 */}
                    {Array.from({ length: 20 }).map((_, i) => (
                      <motion.circle
                        key={`bg-star-${i}`}
                        cx={20 + (i % 5) * 40 + Math.random() * 20}
                        cy={20 + Math.floor(i / 5) * 40 + Math.random() * 20}
                        r={Math.random() * 1.5 + 0.5}
                        fill="rgba(255,255,255,0.6)"
                        initial={{ opacity: 0.3 }}
                        animate={{ 
                          opacity: [0.3, 0.8, 0.3],
                          scale: [1, 1.2, 1]
                        }}
                        transition={{
                          duration: 2 + Math.random() * 2,
                          repeat: Infinity,
                          delay: Math.random() * 2
                        }}
                      />
                    ))}
                    
                    {/* 尘埃粒子 */}
                    {dustParticles.map(particle => (
                      <motion.circle
                        key={`dust-${particle.id}`}
                        cx={particle.x}
                        cy={particle.y}
                        r={particle.size}
                        fill={starColor}
                        initial={{ opacity: 0 }}
                        animate={{ 
                          opacity: [0, particle.opacity, 0],
                          cx: [particle.x - 2, particle.x + 2, particle.x - 2],
                          cy: [particle.y - 2, particle.y + 2, particle.y - 2]
                        }}
                        transition={{
                          duration: particle.animationDuration,
                          repeat: Infinity,
                          ease: "easeInOut"
                        }}
                      />
                    ))}
                    
                    {/* 星环（如果有） */}
                    {hasRing && ringConfig && (
                      <>
                        {/* 背面星环 */}
                        <motion.ellipse
                          cx="100"
                          cy="100"
                          rx={ringConfig.radiusX}
                          ry={ringConfig.radiusY}
                          transform={`rotate(${ringConfig.tilt * 180 / Math.PI} 100 100)`}
                          fill="none"
                          stroke={ringConfig.color}
                          strokeWidth={ringConfig.lineWidth}
                          strokeDasharray="1,2"
                          initial={{ opacity: 0 }}
                          animate={{ 
                            opacity: [0.2, 0.5, 0.2],
                            strokeWidth: [ringConfig.lineWidth, ringConfig.lineWidth * 1.5, ringConfig.lineWidth]
                          }}
                          transition={{
                            duration: 4,
                            repeat: Infinity,
                            ease: "easeInOut"
                          }}
                        />
                        
                        {/* 前面星环 */}
                        <motion.path
                          d={`M ${100 - ringConfig.radiusX} ${100} A ${ringConfig.radiusX} ${ringConfig.radiusY} ${ringConfig.tilt * 180 / Math.PI} 0 1 ${100 + ringConfig.radiusX} ${100}`}
                          fill="none"
                          stroke={ringConfig.color}
                          strokeWidth={ringConfig.lineWidth}
                          initial={{ opacity: 0 }}
                          animate={{ 
                            opacity: [0.5, 0.8, 0.5],
                            strokeWidth: [ringConfig.lineWidth, ringConfig.lineWidth * 1.5, ringConfig.lineWidth]
                          }}
                          transition={{
                            duration: 3,
                            repeat: Infinity,
                            ease: "easeInOut"
                          }}
                        />
                      </>
                    )}
                    
                    {/* 主星 */}
                    <motion.circle
                      cx="100"
                      cy="100"
                      r="8"
                      fill={`url(#starGlow-${star.id})`}
                      filter={`url(#glow-${star.id})`}
                      initial={{ scale: 0 }}
                      animate={{ 
                        scale: [1, 1.1, 1],
                        opacity: [0.8, 1, 0.8]
                      }}
                      transition={{ 
                        scale: {
                          duration: 3,
                          repeat: Infinity,
                          ease: "easeInOut"
                        },
                        opacity: {
                          duration: 2,
                          repeat: Infinity,
                          ease: "easeInOut"
                        }
                      }}
                    />
                    
                    {/* 星星光芒 - 根据样式渲染不同类型 */}
                    {style === STAR_STYLES.STANDARD && (
                      // 标准8条光芒
                      [0, 1, 2, 3, 4, 5, 6, 7].map((i) => (
                        <motion.line
                          key={`ray-${i}`}
                          x1="100"
                          y1="100"
                          x2={100 + Math.cos(i * Math.PI / 4) * 40}
                          y2={100 + Math.sin(i * Math.PI / 4) * 40}
                          stroke={starColor}
                          strokeWidth="2"
                          initial={{ pathLength: 0, opacity: 0 }}
                          animate={{ 
                            pathLength: 1,
                            opacity: [0, 0.8, 0],
                          }}
                          transition={{
                            duration: 1.5,
                            delay: i * 0.1,
                            repeat: Infinity,
                            repeatDelay: 1,
                          }}
                        />
                      ))
                    )}
                    
                    {style === STAR_STYLES.CROSS && (
                      // 十字形光芒
                      [0, 1, 2, 3].map((i) => (
                        <motion.rect
                          key={`cross-${i}`}
                          x={100 - (i % 2 === 0 ? 1 : 15)}
                          y={100 - (i % 2 === 1 ? 1 : 15)}
                          width={i % 2 === 0 ? 2 : 30}
                          height={i % 2 === 1 ? 2 : 30}
                          fill={starColor}
                          initial={{ opacity: 0, scale: 0 }}
                          animate={{ 
                            opacity: [0, 0.8, 0],
                            scale: [0, 1, 0],
                            rotate: [0, 90, 180]
                          }}
                          transition={{
                            duration: 2,
                            delay: i * 0.2,
                            repeat: Infinity,
                            repeatDelay: 0.5,
                          }}
                        />
                      ))
                    )}
                    
                    {style === STAR_STYLES.BURST && (
                      // 爆发式光芒
                      Array.from({ length: 12 }).map((_, i) => {
                        const angle = (i * Math.PI * 2) / 12;
                        const length = 20 + Math.random() * 30;
                        return (
                          <motion.line
                            key={`burst-${i}`}
                            x1="100"
                            y1="100"
                            x2={100 + Math.cos(angle) * length}
                            y2={100 + Math.sin(angle) * length}
                            stroke={starColor}
                            strokeWidth={Math.random() * 1.5 + 0.5}
                            initial={{ pathLength: 0, opacity: 0 }}
                            animate={{ 
                              pathLength: [0, 1, 0],
                              opacity: [0, 0.7, 0],
                            }}
                            transition={{
                              duration: 2 + Math.random(),
                              delay: i * 0.05,
                              repeat: Infinity,
                              repeatDelay: Math.random(),
                            }}
                          />
                        );
                      })
                    )}
                    
                    {style === STAR_STYLES.SPARKLE && (
                      // 闪烁式
                      Array.from({ length: 8 }).map((_, i) => {
                        const angle = (i * Math.PI * 2) / 8;
                        const distance = 15 + Math.random() * 20;
                        return (
                          <motion.circle
                            key={`sparkle-${i}`}
                            cx={100 + Math.cos(angle) * distance}
                            cy={100 + Math.sin(angle) * distance}
                            r={Math.random() * 2 + 1}
                            fill={starColor}
                            initial={{ opacity: 0, scale: 0 }}
                            animate={{ 
                              opacity: [0, 0.9, 0],
                              scale: [0, 1, 0]
                            }}
                            transition={{
                              duration: 1 + Math.random(),
                              delay: i * 0.1,
                              repeat: Infinity,
                              repeatDelay: Math.random() * 2,
                            }}
                          />
                        );
                      })
                    )}
                    
                    {style === STAR_STYLES.RINGED && !hasRing && (
                      // 带环星（如果没有实际环）
                      <motion.circle
                        cx="100"
                        cy="100"
                        r="15"
                        fill="none"
                        stroke={starColor}
                        strokeWidth="1"
                        strokeDasharray="1,2"
                        initial={{ opacity: 0 }}
                        animate={{ 
                          opacity: [0.3, 0.6, 0.3],
                          r: [15, 18, 15]
                        }}
                        transition={{
                          duration: 3,
                          repeat: Infinity,
                          ease: "easeInOut"
                        }}
                      />
                    )}
                  </svg>
                )}
              </div>
              
              {/* Card title */}
              <div className="star-card-title">
                <motion.div
                  className="star-type-badge"
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.8 }}
                  style={{
                    backgroundColor: star.isSpecial ? `${currentTheme.accent}30` : 'rgba(255,255,255,0.1)'
                  }}
                >
                  {star.isSpecial ? (
                    <>
                      <StarRayIcon className="w-3 h-3" color={currentTheme.accent} />
                      <span style={{ color: currentTheme.accent }}>Rare Celestial</span>
                    </>
                  ) : (
                    <>
                      <div className="w-3 h-3 rounded-full bg-white opacity-80" />
                      <span>Inner Star</span>
                    </>
                  )}
                </motion.div>
                
                <motion.div
                  className="star-date"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 1 }}
                >
                  <Calendar className="w-3 h-3" />
                  <span>{star.createdAt.toLocaleDateString()}</span>
                </motion.div>
              </div>
              
              {/* Decorative elements */}
              <div className="star-card-decorations">
                {Array.from({ length: 6 }).map((_, i) => (
                  <motion.div
                    key={i}
                    className="floating-particle"
                    style={{
                      left: `${20 + Math.random() * 60}%`,
                      top: `${20 + Math.random() * 60}%`,
                      backgroundColor: starColor,
                    }}
                    animate={{
                      y: [-5, 5, -5],
                      opacity: [0.3, 0.7, 0.3],
                    }}
                    transition={{
                      duration: 3 + Math.random() * 2,
                      repeat: Infinity,
                      delay: Math.random() * 2,
                    }}
                  />
                ))}
              </div>
            </div>
          </div>

          {/* Back Side - Answer */}
          <div className="star-card-face star-card-back">
            <div className="star-card-content">
              <div className="question-section">
                <h3 className="question-label">Your Question</h3>
                <p className="question-text">"{star.question}"</p>
              </div>
              
              <div className="divider">
                <StarRayIcon className="w-4 h-4 text-cosmic-accent" />
              </div>
              
              <div className="answer-section">
                <motion.div
                  className="answer-reveal"
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.3 }}
                >
                  <h3 className="answer-label">星辰的启示</h3>
                <p className="answer-text">{star.answer}</p>
                </motion.div>
              </div>
              
              <motion.div
                className="card-footer"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.6 }}
              >
                <div className="star-stats">
                  <span className="stat">
                    Brightness: {Math.round(star.brightness * 100)}%
                  </span>
                  <span className="stat">
                    Size: {star.size.toFixed(1)}px
                  </span>
                </div>
                <p className="text-center text-sm text-cosmic-accent mt-3">
                  再次点击卡片继续探索星空
                </p>
              </motion.div>
            </div>
          </div>
        </motion.div>
        
        {/* Hover glow effect */}
        <motion.div
          className="star-card-glow"
          animate={{
            opacity: isHovered ? 0.6 : 0,
            scale: isHovered ? 1.05 : 1,
          }}
          transition={{ duration: 0.3 }}
          style={{
            background: isHovered 
              ? `radial-gradient(circle, ${currentTheme.accent}40 0%, transparent 70%)` 
              : 'none'
          }}
        />
      </div>
      
      {/* Action buttons - only shown in collection view */}
      {showActions && (
        <motion.div
          className="star-card-actions"
          initial={{ opacity: 0 }}
          animate={{ opacity: isHovered ? 1 : 0 }}
          transition={{ duration: 0.2 }}
        >
          <button className="action-btn favorite">
            <Heart className="w-4 h-4" />
          </button>
          <button className="action-btn flip" onClick={onFlip}>
            <StarRayIcon className="w-4 h-4" />
          </button>
        </motion.div>
      )}
    </motion.div>
  );
};

export default StarCard;
```

`staroracle-app_v1/src/components/StarCollection.tsx`:

```tsx
import React, { useState, useMemo, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { createPortal } from 'react-dom';
import { X, Search, Filter, Star as StarIcon } from 'lucide-react';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import { getMobileModalStyles, getMobileModalClasses, fixIOSZIndex, createTopLevelContainer, hideOtherElements } from '../utils/mobileUtils';
import StarCard from './StarCard';

// 星星样式类型 - 与StarCard组件中的定义保持一致
const STAR_STYLES = {
  STANDARD: 'standard', // 标准8条光芒
  CROSS: 'cross',       // 十字形
  BURST: 'burst',       // 爆发式
  SPARKLE: 'sparkle',   // 闪烁式
  RINGED: 'ringed',     // 带环星
  // 行星样式
  PLANET_SMOOTH: 'planet_smooth',   // 平滑行星
  PLANET_CRATERS: 'planet_craters', // 陨石坑行星
  PLANET_SEAS: 'planet_seas',       // 海洋行星
  PLANET_DUST: 'planet_dust',       // 尘埃行星
  PLANET_RINGS: 'planet_rings'      // 带环行星
};

interface StarCollectionProps {
  isOpen: boolean;
  onClose: () => void;
}

const StarCollection: React.FC<StarCollectionProps> = ({ isOpen, onClose }) => {
  const { constellation, drawInspirationCard } = useStarStore();
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState<'all' | 'special' | 'recent'>('all');
  const [flippedCards, setFlippedCards] = useState<Set<string>>(new Set());
  const [restoreElements, setRestoreElements] = useState<(() => void) | null>(null);

  // 初始化iOS层级修复
  useEffect(() => {
    fixIOSZIndex();
  }, []);

  // 当模态框打开时隐藏其他元素
  useEffect(() => {
    if (isOpen) {
      document.body.classList.add('modal-open');
      const restore = hideOtherElements();
      setRestoreElements(() => restore);
    } else {
      document.body.classList.remove('modal-open');
      if (restoreElements) {
        restoreElements();
        setRestoreElements(null);
      }
    }
    
    return () => {
      document.body.classList.remove('modal-open');
      if (restoreElements) {
        restoreElements();
      }
    };
  }, [isOpen]);

  // 为每个星星生成样式映射
  const starStyleMap = useMemo(() => {
    const map = new Map();
    constellation.stars.forEach(star => {
      // 使用星星ID作为随机种子
      const seed = star.id.split('-')[1] ? parseInt(star.id.split('-')[1]) : Date.now();
      const seedRandom = (min: number, max: number) => {
        const x = Math.sin(seed) * 10000;
        const r = x - Math.floor(x);
        return Math.floor(r * (max - min + 1)) + min;
      };
      
      // 获取所有可能的样式
      const allStyles = Object.values(STAR_STYLES);
      // 随机选择样式和颜色主题
      const styleIndex = seedRandom(0, allStyles.length - 1);
      const colorTheme = seedRandom(0, 3);
      
      map.set(star.id, {
        style: allStyles[styleIndex],
        theme: colorTheme
      });
    });
    return map;
  }, [constellation.stars]);

  const handleClose = () => {
    playSound('starClick');
    onClose();
  };

  const handleCardFlip = (starId: string) => {
    playSound('starClick');
    setFlippedCards(prev => {
      const newSet = new Set(prev);
      if (newSet.has(starId)) {
        newSet.delete(starId);
      } else {
        newSet.add(starId);
      }
      return newSet;
    });
  };

  // 处理右键点击，显示灵感卡片
  const handleContextMenu = (e: React.MouseEvent) => {
    e.preventDefault();
    playSound('starReveal');
    const card = drawInspirationCard();
    console.log('📇 灵感卡片已生成:', card.question);
  };

  // Filter stars based on search and filter criteria
  const filteredStars = constellation.stars.filter(star => {
    const matchesSearch = star.question.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         star.answer.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesFilter = filterType === 'all' || 
                         (filterType === 'special' && star.isSpecial) ||
                         (filterType === 'recent' && 
                          (Date.now() - star.createdAt.getTime()) < 7 * 24 * 60 * 60 * 1000);
    
    return matchesSearch && matchesFilter;
  });

  return createPortal(
    <AnimatePresence>
      {isOpen && (
        <motion.div
          className={getMobileModalClasses()}
          style={getMobileModalStyles()}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onContextMenu={handleContextMenu}
        >
          {/* Backdrop */}
          <motion.div
            className="absolute inset-0 bg-black bg-opacity-90 backdrop-blur-md"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={handleClose}
          />

          {/* Collection Panel */}
          <motion.div
            className="star-collection-panel"
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            transition={{ type: 'spring', damping: 25 }}
          >
            {/* Header */}
            <div className="collection-header">
              <div className="header-left">
                <StarIcon className="w-6 h-6 text-cosmic-accent" />
                <h2 className="collection-title">Star Collection</h2>
                <span className="star-count">{filteredStars.length} stars</span>
              </div>
              
              <button
                className="close-btn"
                onClick={handleClose}
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Controls */}
            <div className="collection-controls">
              <div className="search-bar">
                <Search className="w-4 h-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search your stars..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="search-input"
                />
              </div>
              
              <div className="control-buttons">
                <select
                  value={filterType}
                  onChange={(e) => setFilterType(e.target.value as any)}
                  className="filter-select"
                >
                  <option value="all">All Stars</option>
                  <option value="special">Special Stars</option>
                  <option value="recent">Recent (7 days)</option>
                </select>
              </div>
            </div>

            {/* Star Cards */}
            <div className="collection-content grid">
              <AnimatePresence>
                {filteredStars.map((star, index) => {
                  const styleConfig = starStyleMap.get(star.id) || { style: 'standard', theme: 0 };
                  return (
                    <motion.div
                      key={star.id}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -20 }}
                      transition={{ delay: index * 0.1 }}
                    >
                      <StarCard
                        star={star}
                        isFlipped={flippedCards.has(star.id)}
                        onFlip={() => handleCardFlip(star.id)}
                        starStyle={styleConfig.style}
                        colorTheme={styleConfig.theme}
                        onContextMenu={handleContextMenu}
                      />
                    </motion.div>
                  );
                })}
              </AnimatePresence>
              
              {filteredStars.length === 0 && (
                <motion.div
                  className="empty-state"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                >
                  <StarIcon className="w-12 h-12 text-gray-400 mb-4" />
                  <p className="text-gray-400">No stars found matching your criteria</p>
                </motion.div>
              )}
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>,
    createTopLevelContainer()
  );
};

export default StarCollection;
```

`staroracle-app_v1/src/index.css`:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --font-heading: 'Cinzel', serif;
  --font-body: 'Cormorant Garamond', serif;
  /* iOS安全区域变量 */
  --safe-area-inset-top: env(safe-area-inset-top, 0px);
  --safe-area-inset-right: env(safe-area-inset-right, 0px);
  --safe-area-inset-bottom: env(safe-area-inset-bottom, 0px);
  --safe-area-inset-left: env(safe-area-inset-left, 0px);
}

/* 移动端触摸优化 */
* {
  -webkit-tap-highlight-color: transparent;
  -webkit-touch-callout: none;
  /* -webkit-user-select: none;  暂时移除，可能影响点击 */
  /* user-select: none; 暂时移除，可能影响点击 */
}

/* 禁用双击缩放 */
input, textarea, button, select {
  touch-action: manipulation;
}

/* 全局禁用缩放和滚动 */
html {
  overflow: hidden;
  position: fixed;
  width: 100%;
  height: 100%;
}

body {
  overflow: hidden;
  position: fixed;
  width: 100%;
  height: 100%;
  /* touch-action: pan-x pan-y; 移除触摸限制进行调试 */
}

html, body, #root {
  height: 100%;
  width: 100%;
  margin: 0;
  padding: 0;
  overflow: hidden;
}

/* 移动端特有的层级修复 */
@supports (-webkit-touch-callout: none) {
  /* iOS专用修复 */
  .mobile-modal-fix {
    position: fixed !important;
    z-index: 999999 !important;
    top: 0 !important;
    left: 0 !important;
    right: 0 !important;
    bottom: 0 !important;
    -webkit-transform: translateZ(0);
    transform: translateZ(0);
    -webkit-backface-visibility: hidden;
    backface-visibility: hidden;
  }
  
  /* 强制硬件加速 */
  .modal-hardware-acceleration {
    -webkit-transform: translate3d(0, 0, 0);
    transform: translate3d(0, 0, 0);
    -webkit-perspective: 1000px;
    perspective: 1000px;
  }
}

/* 最高优先级的模态框容器 */
#top-level-modals {
  position: fixed !important;
  top: 0 !important;
  left: 0 !important;
  right: 0 !important;
  bottom: 0 !important;
  z-index: 2147483647 !important;
  pointer-events: none !important;
}

#top-level-modals > * {
  pointer-events: auto !important;
}

/* iOS WebView特殊修复 */
@media screen and (max-width: 768px) {
  /* 移除过于激进的全局隐藏规则，改为更精确的控制 */
  body.modal-open #top-level-modals,
  body.modal-open #top-level-modals * {
    visibility: visible !important;
  }
}

body {
  font-family: var(--font-body);
  color: #f8f9fa;
  background-color: #000;
}

h1, h2, h3, h4, h5, h6 {
  font-family: var(--font-heading);
}

.cosmic-bg {
  background: radial-gradient(ellipse at bottom, #1B2735 0%, #090A0F 100%);
}

.star {
  position: absolute;
  background-color: #fff;
  border-radius: 50%;
  filter: blur(1px);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.star:hover {
  filter: blur(0);
  box-shadow: 0 0 15px rgba(255, 255, 255, 0.8),
              0 0 30px rgba(255, 255, 255, 0.6),
              0 0 45px rgba(255, 255, 255, 0.4);
}

.star.special:hover {
  box-shadow: 0 0 15px rgba(138, 95, 189, 0.8),
              0 0 30px rgba(138, 95, 189, 0.6),
              0 0 45px rgba(138, 95, 189, 0.4);
}

.cosmic-input {
  background: rgba(13, 18, 30, 0.7);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.cosmic-button {
  background: rgba(88, 101, 242, 0.2);
  backdrop-filter: blur(4px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  min-height: 48px;
  min-width: 48px;
}

.cosmic-button:hover {
  background: rgba(88, 101, 242, 0.4);
  border: 1px solid rgba(255, 255, 255, 0.2);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(88, 101, 242, 0.3);
}

.cosmic-button:active {
  transform: translateY(0);
}

.oracle-card {
  background: rgba(13, 18, 30, 0.7);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 4px 30px rgba(0, 0, 0, 0.1);
}

.star-image {
  border-radius: 50%;
  overflow: hidden;
  box-shadow: 0 0 20px rgba(255, 255, 255, 0.3);
}

/* Star Card Styles */
.star-card-container {
  position: relative;
  width: 280px;
  height: 400px;
  margin: 16px;
}

.star-card-wrapper {
  position: relative;
  width: 100%;
  height: 100%;
  perspective: 1000px;
}

.star-card {
  position: relative;
  width: 100%;
  height: 100%;
  transform-style: preserve-3d;
  cursor: pointer;
}

.star-card-face {
  position: absolute;
  width: 100%;
  height: 100%;
  backface-visibility: hidden;
  border-radius: 16px;
  overflow: hidden;
}

.star-card-front {
  background: linear-gradient(135deg, 
    rgba(13, 18, 30, 0.9) 0%, 
    rgba(27, 39, 53, 0.9) 50%, 
    rgba(44, 83, 100, 0.9) 100%
  );
  border: 1px solid rgba(138, 95, 189, 0.3);
}

.star-card-back {
  background: linear-gradient(135deg, 
    rgba(27, 39, 53, 0.95) 0%, 
    rgba(13, 18, 30, 0.95) 100%
  );
  border: 1px solid rgba(255, 255, 255, 0.2);
  transform: rotateY(180deg);
}

.star-card-bg {
  position: relative;
  width: 100%;
  height: 100%;
  padding: 24px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.star-card-constellation {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

.constellation-svg {
  width: 160px;
  height: 160px;
  filter: drop-shadow(0 0 10px rgba(255, 255, 255, 0.3));
}

.star-card-title {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.star-type-badge {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background: rgba(138, 95, 189, 0.2);
  border: 1px solid rgba(138, 95, 189, 0.3);
  border-radius: 20px;
  font-size: 12px;
  color: #fff;
  width: fit-content;
}

.star-date {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: rgba(255, 255, 255, 0.6);
}

.star-card-decorations {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.floating-particle {
  position: absolute;
  width: 4px;
  height: 4px;
  background: rgba(255, 255, 255, 0.6);
  border-radius: 50%;
  filter: blur(0.5px);
}

.star-card-content {
  padding: 24px;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.question-section, .answer-section {
  flex: 1;
}

.question-label, .answer-label {
  font-family: var(--font-heading);
  font-size: 14px;
  color: rgba(138, 95, 189, 1);
  margin-bottom: 8px;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.question-text {
  font-size: 16px;
  color: rgba(255, 255, 255, 0.9);
  line-height: 1.4;
  font-style: italic;
}

.answer-text {
  font-size: 15px;
  color: #fff;
  line-height: 1.5;
  font-family: var(--font-body);
}

.divider {
  display: flex;
  justify-content: center;
  align-items: center;
  margin: 16px 0;
  opacity: 0.6;
}

.card-footer {
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.star-stats {
  display: flex;
  justify-content: space-between;
  font-size: 11px;
  color: rgba(255, 255, 255, 0.5);
}

.star-card-glow {
  position: absolute;
  inset: -4px;
  background: linear-gradient(135deg, 
    rgba(138, 95, 189, 0.3) 0%, 
    rgba(88, 101, 242, 0.3) 100%
  );
  border-radius: 20px;
  filter: blur(8px);
  z-index: -1;
}

.star-card-actions {
  position: absolute;
  top: 12px;
  right: 12px;
  display: flex;
  gap: 8px;
  z-index: 10;
}

.action-btn {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.action-btn:hover {
  background: rgba(138, 95, 189, 0.3);
  transform: scale(1.1);
}

/* Collection Panel Styles */
.star-collection-panel {
  width: 90vw;
  max-width: 1200px;
  height: 85vh;
  background: rgba(13, 18, 30, 0.95);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 20px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.collection-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24px 32px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(27, 39, 53, 0.5);
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.collection-title {
  font-family: var(--font-heading);
  font-size: 24px;
  color: #fff;
  margin: 0;
}

.star-count {
  padding: 4px 12px;
  background: rgba(138, 95, 189, 0.2);
  border: 1px solid rgba(138, 95, 189, 0.3);
  border-radius: 12px;
  font-size: 12px;
  color: rgba(255, 255, 255, 0.8);
}

.close-btn {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.close-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  transform: scale(1.05);
}

.collection-controls {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 32px;
  gap: 16px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.search-bar {
  position: relative;
  flex: 1;
  max-width: 300px;
}

.search-bar svg {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
}

.search-input {
  width: 100%;
  padding: 10px 12px 10px 40px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  color: #fff;
  font-size: 14px;
}

.search-input::placeholder {
  color: rgba(255, 255, 255, 0.4);
}

.search-input:focus {
  outline: none;
  border-color: rgba(138, 95, 189, 0.5);
  box-shadow: 0 0 0 2px rgba(138, 95, 189, 0.2);
}

.control-buttons {
  display: flex;
  align-items: center;
  gap: 12px;
}

.filter-select {
  padding: 8px 12px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 6px;
  color: #fff;
  font-size: 14px;
}

.filter-select:focus {
  outline: none;
  border-color: rgba(138, 95, 189, 0.5);
}

.view-toggle {
  display: flex;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 6px;
  overflow: hidden;
}

.view-btn {
  padding: 8px 12px;
  background: rgba(255, 255, 255, 0.05);
  border: none;
  color: rgba(255, 255, 255, 0.6);
  transition: all 0.2s ease;
}

.view-btn.active {
  background: rgba(138, 95, 189, 0.3);
  color: #fff;
}

.view-btn:hover {
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
}

.collection-content {
  flex: 1;
  overflow-y: auto;
  padding: 24px 32px;
}

.collection-content.grid {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 24px;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 200px;
  text-align: center;
}

/* Collection Button Styles */
.collection-trigger-btn {
  position: relative;
  padding: 16px 24px;
  min-height: 48px;
  min-width: 48px;
  background: rgba(13, 18, 30, 0.8);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(138, 95, 189, 0.3);
  border-radius: 12px;
  color: #fff;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  overflow: hidden;
}

.collection-trigger-btn:hover {
  background: rgba(138, 95, 189, 0.2);
  border-color: rgba(138, 95, 189, 0.5);
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(138, 95, 189, 0.3);
}

.btn-content {
  display: flex;
  align-items: center;
  gap: 8px;
  position: relative;
  z-index: 2;
}

.btn-icon {
  position: relative;
}

.star-count-badge {
  position: absolute;
  top: -8px;
  right: -8px;
  width: 18px;
  height: 18px;
  background: rgba(138, 95, 189, 0.9);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 10px;
  font-weight: bold;
  color: #fff;
}

.btn-text {
  font-size: 14px;
  font-weight: 500;
}

.floating-stars {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 1;
}

.floating-star {
  position: absolute;
  color: rgba(138, 95, 189, 0.6);
}

.floating-star:nth-child(1) { top: 20%; left: 15%; }
.floating-star:nth-child(2) { top: 60%; right: 20%; }
.floating-star:nth-child(3) { bottom: 25%; left: 50%; }

/* Template Button Styles */
.template-trigger-btn {
  position: relative;
  padding: 16px 24px;
  min-height: 48px;
  min-width: 48px;
  background: rgba(13, 18, 30, 0.8);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 215, 0, 0.3);
  border-radius: 12px;
  color: #fff;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  overflow: hidden;
  min-width: 160px;
}

.template-trigger-btn:hover {
  background: rgba(255, 215, 0, 0.2);
  border-color: rgba(255, 215, 0, 0.5);
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(255, 215, 0, 0.3);
}

.template-badge {
  position: absolute;
  top: -8px;
  right: -8px;
  width: 18px;
  height: 18px;
  background: rgba(255, 215, 0, 0.9);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 10px;
  color: #000;
}

.btn-text-container {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.template-name {
  font-size: 11px;
  color: rgba(255, 215, 0, 0.8);
  font-weight: 400;
}

/* Constellation Template Card Styles */
.constellation-template-card {
  background: rgba(13, 18, 30, 0.8);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 16px;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.constellation-template-card:hover {
  background: rgba(138, 95, 189, 0.1);
  border-color: rgba(138, 95, 189, 0.3);
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(138, 95, 189, 0.2);
}

.template-preview {
  background: rgba(0, 0, 0, 0.3);
  border-radius: 8px;
  padding: 12px;
  margin-bottom: 12px;
}

.template-info h3 {
  margin: 0 0 8px 0;
}

.template-info p {
  margin: 0 0 12px 0;
}

@keyframes twinkle {
  0% { opacity: 0.3; transform: scale(1); }
  50% { opacity: 1; transform: scale(1.2); }
  100% { opacity: 0.3; transform: scale(1); }
}

@keyframes pulse {
  0% { transform: scale(1); opacity: 1; }
  50% { transform: scale(1.1); opacity: 0.8; }
  100% { transform: scale(1); opacity: 1; }
}

@keyframes float {
  0% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
  100% { transform: translateY(0); }
}

@keyframes sparkle {
  0% { transform: scale(0) rotate(0deg); opacity: 0; }
  50% { transform: scale(1) rotate(180deg); opacity: 1; }
  100% { transform: scale(0) rotate(360deg); opacity: 0; }
}

.pulse {
  animation: pulse 2s infinite ease-in-out;
}

.twinkle {
  animation: twinkle 3s infinite ease-in-out;
}

.float {
  animation: float 6s infinite ease-in-out;
}

.constellation-area {
  cursor: crosshair;
}

.constellation-area::before {
  content: '';
  position: fixed;
  width: 300px;
  height: 300px;
  border-radius: 50%;
  background: radial-gradient(circle, 
    rgba(138, 95, 189, 0.15) 0%,
    rgba(138, 95, 189, 0.1) 30%,
    transparent 70%
  );
  transform: translate(-50%, -50%);
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.3s ease;
  z-index: 1;
}

.constellation-area:hover::before {
  opacity: 1;
}

.star-sparkle {
  position: absolute;
  width: 20px;
  height: 20px;
  background: rgba(255, 255, 255, 0.8);
  clip-path: polygon(50% 0%, 61% 35%, 98% 35%, 68% 57%, 79% 91%, 50% 70%, 21% 91%, 32% 57%, 2% 35%, 39% 35%);
  animation: sparkle 1s ease-in-out forwards;
  pointer-events: none;
}

.hover-indicator {
  position: fixed;
  width: 300px;
  height: 300px;
  border-radius: 50%;
  background: radial-gradient(circle,
    rgba(138, 95, 189, 0.15) 0%,
    rgba(138, 95, 189, 0.1) 30%,
    transparent 70%
  );
  transform: translate(-50%, -50%);
  pointer-events: none;
  z-index: 1;
  opacity: 0;
  transition: opacity 0.3s ease;
}

.constellation-area:hover .hover-indicator {
  opacity: 1;
}

/* Conversation Dialog Styles */
.conversation-dialog {
  width: 90vw;
  max-width: 600px;
  height: 70vh;
  max-height: 600px;
  background: rgba(13, 18, 30, 0.95);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.conversation-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(27, 39, 53, 0.5);
}

.conversation-messages {
  flex: 1;
  overflow-y: auto;
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.message {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.message.user {
  align-items: flex-end;
}

.message.assistant {
  align-items: flex-start;
}

.message-content {
  max-width: 80%;
}

.user-message {
  background: rgba(138, 95, 189, 0.2);
  border: 1px solid rgba(138, 95, 189, 0.3);
  border-radius: 16px 16px 4px 16px;
  padding: 12px 16px;
}

.user-message p {
  color: #fff;
  margin: 0;
  line-height: 1.4;
}

.assistant-message {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px 16px 16px 4px;
  padding: 12px 16px;
  display: flex;
  align-items: flex-start;
  gap: 8px;
}

.message-icon {
  color: rgba(138, 95, 189, 1);
  margin-top: 2px;
  flex-shrink: 0;
}

.assistant-message p {
  color: #fff;
  margin: 0;
  line-height: 1.4;
  flex: 1;
}

.message-time {
  font-size: 11px;
  color: rgba(255, 255, 255, 0.4);
  margin: 0 16px;
}

.conversation-input {
  padding: 20px 24px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(27, 39, 53, 0.3);
}

.conversation-textarea {
  width: 100%;
  padding: 12px 16px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  color: #fff;
  font-size: 14px;
  line-height: 1.4;
  resize: none;
  font-family: inherit;
}

.conversation-textarea::placeholder {
  color: rgba(255, 255, 255, 0.4);
}

.conversation-textarea:focus {
  outline: none;
  border-color: rgba(138, 95, 189, 0.5);
  box-shadow: 0 0 0 2px rgba(138, 95, 189, 0.2);
}

.conversation-textarea {
  overflow-y: auto;
  scrollbar-width: thin;
  scrollbar-color: rgba(138, 95, 189, 0.3) transparent;
}

.conversation-textarea::-webkit-scrollbar {
  width: 4px;
}

.conversation-textarea::-webkit-scrollbar-track {
  background: transparent;
}

.conversation-textarea::-webkit-scrollbar-thumb {
  background: rgba(138, 95, 189, 0.3);
  border-radius: 2px;
}

.conversation-btn {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  color: #fff;
}

.conversation-btn.primary {
  background: rgba(138, 95, 189, 0.3);
  border-color: rgba(138, 95, 189, 0.5);
}

.conversation-btn.primary:hover:not(:disabled) {
  background: rgba(138, 95, 189, 0.5);
  transform: scale(1.05);
}

.conversation-btn.secondary {
  background: rgba(255, 215, 0, 0.2);
  border-color: rgba(255, 215, 0, 0.4);
}

.conversation-btn.secondary:hover:not(:disabled) {
  background: rgba(255, 215, 0, 0.3);
  transform: scale(1.05);
}

.conversation-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.conversation-hint {
  margin-top: 8px;
  text-align: center;
}

/* Inspiration Card Styles */
.inspiration-card {
  width: 90vw;
  max-width: 480px;
  background: rgba(13, 18, 30, 0.95);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(138, 95, 189, 0.3);
  border-radius: 20px;
  overflow: hidden;
  position: relative;
}

.inspiration-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.category-badge {
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.inspiration-card-content {
  position: relative;
  padding: 32px 24px;
  min-height: 300px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 24px;
}

.inspiration-bg {
  position: absolute;
  inset: 0;
  opacity: 0.6;
  pointer-events: none;
}

.inspiration-question {
  position: relative;
  z-index: 2;
}

.question-text {
  font-family: var(--font-heading);
  font-size: 20px;
  color: #fff;
  text-align: center;
  line-height: 1.3;
  margin: 0;
}

.inspiration-reflection {
  position: relative;
  z-index: 2;
}

.reflection-text {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.8);
  text-align: center;
  line-height: 1.5;
  margin: 0;
  font-style: italic;
}

.inspiration-tags {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 8px;
  position: relative;
  z-index: 2;
}

.inspiration-tag {
  padding: 4px 12px;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 12px;
  font-size: 11px;
  color: rgba(255, 255, 255, 0.8);
  text-transform: lowercase;
}

.inspiration-card-actions {
  display: flex;
  justify-content: space-between;
  padding: 20px 24px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(27, 39, 53, 0.3);
}

.inspiration-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s ease;
  border: 1px solid;
}

.inspiration-btn.dismiss {
  background: rgba(255, 255, 255, 0.05);
  border-color: rgba(255, 255, 255, 0.2);
  color: rgba(255, 255, 255, 0.8);
}

.inspiration-btn.dismiss:hover {
  background: rgba(255, 255, 255, 0.1);
  transform: translateY(-1px);
}

.inspiration-btn.explore {
  background: rgba(138, 95, 189, 0.2);
  border-color: rgba(138, 95, 189, 0.4);
  color: #fff;
}

.inspiration-btn.explore:hover {
  background: rgba(138, 95, 189, 0.3);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(138, 95, 189, 0.3);
}

.inspiration-particles {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 1;
}

.inspiration-particles .floating-particle {
  position: absolute;
  width: 3px;
  height: 3px;
  background: rgba(138, 95, 189, 0.6);
  border-radius: 50%;
  filter: blur(0.5px);
}

/* Bottom Chat Input Styles */
.bottom-input-container {
  background: rgba(0, 0, 0, 0.95);
  backdrop-filter: blur(20px);
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  padding: 16px 20px 20px;
}

.suggestion-scroll-container {
  margin-bottom: 16px;
}

.suggestion-scroll {
  display: flex;
  gap: 12px;
  overflow-x: auto;
  padding: 8px 0;
  scrollbar-width: none;
  -ms-overflow-style: none;
}

.suggestion-scroll::-webkit-scrollbar {
  display: none;
}

.suggestion-card {
  flex-shrink: 0;
  background: rgba(28, 28, 30, 0.8);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  padding: 12px 16px;
  min-width: 180px;
  text-align: left;
  transition: all 0.2s ease;
}

.suggestion-card:hover {
  background: rgba(138, 95, 189, 0.2);
  border-color: rgba(138, 95, 189, 0.3);
  transform: translateY(-1px);
}

.suggestion-title {
  color: #fff;
  font-weight: 600;
  font-size: 14px;
  margin-bottom: 4px;
}

.suggestion-subtitle {
  color: rgba(255, 255, 255, 0.6);
  font-size: 13px;
  line-height: 1.3;
}

.input-bar-container {
  display: flex;
  align-items: flex-end;
  gap: 8px;
}

.input-icon-btn {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: rgba(255, 255, 255, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  flex-shrink: 0;
}

.input-icon-btn:hover {
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
  transform: scale(1.05);
}

.text-input-wrapper {
  flex: 1;
  background: rgba(28, 28, 30, 0.8);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 20px;
  overflow: hidden;
}

.text-input {
  width: 100%;
  background: transparent;
  border: none;
  outline: none;
  color: #fff;
  font-size: 16px;
  line-height: 1.4;
  padding: 12px 16px;
  resize: none;
  font-family: inherit;
  min-height: 44px;
  max-height: 120px;
}

.text-input::placeholder {
  color: rgba(255, 255, 255, 0.4);
}

.text-input:focus {
  outline: none;
}

.text-input-wrapper:focus-within {
  border-color: rgba(138, 95, 189, 0.5);
  box-shadow: 0 0 0 2px rgba(138, 95, 189, 0.2);
}

.send-btn {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  background: rgba(138, 95, 189, 0.3);
  border: 1px solid rgba(138, 95, 189, 0.5);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  flex-shrink: 0;
}

.send-btn:hover:not(:disabled) {
  background: rgba(138, 95, 189, 0.5);
  transform: scale(1.05);
}

.send-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Modern Conversation Styles */
.close-conversation-btn {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.close-conversation-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  transform: scale(1.1);
}

.modern-input-container {
  display: flex;
  align-items: flex-end;
  gap: 12px;
  padding: 16px 20px;
  background: rgba(28, 28, 30, 0.95);
  border-radius: 24px;
  border: 2px solid transparent;
  border-top: 2px solid rgba(0, 191, 255, 0.6);
  backdrop-filter: blur(20px);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}

.modern-input-wrapper {
  flex: 1;
  position: relative;
}

.modern-textarea {
  width: 100%;
  background: transparent;
  border: none;
  outline: none;
  color: #ffffff;
  font-size: 16px;
  line-height: 1.4;
  resize: none;
  font-family: inherit;
  min-height: 24px;
  max-height: 120px;
  padding: 0;
}

.modern-textarea::placeholder {
  color: rgba(142, 142, 147, 1);
}

.modern-button-group {
  display: flex;
  align-items: center;
  gap: 8px;
}

.modern-btn {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  cursor: pointer;
  position: relative;
  overflow: hidden;
}

.modern-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none !important;
}

.voice-btn {
  background: rgba(142, 142, 147, 0.3);
  color: rgba(142, 142, 147, 1);
}

.voice-btn:hover:not(:disabled) {
  background: rgba(142, 142, 147, 0.5);
  color: #ffffff;
}

.send-btn.active {
  background: rgba(138, 95, 189, 0.8);
  color: #ffffff;
  box-shadow: 0 4px 15px rgba(138, 95, 189, 0.4);
}

.send-btn:not(.active) {
  background: rgba(142, 142, 147, 0.3);
  color: rgba(142, 142, 147, 1);
}

.star-btn {
  background: linear-gradient(135deg, rgba(138, 95, 189, 0.8), rgba(255, 215, 0, 0.6));
  color: #ffffff;
  box-shadow: 0 4px 20px rgba(138, 95, 189, 0.5);
}

.star-btn:hover:not(:disabled) {
  box-shadow: 0 6px 25px rgba(138, 95, 189, 0.7);
}

.star-hint {
  text-align: center;
  margin-top: 12px;
}

.star-hint-text {
  font-size: 12px;
  font-weight: 500;
  margin: 0;
}

/* Enhanced Message Styles */
.user-message {
  background: linear-gradient(135deg, rgba(138, 95, 189, 0.3), rgba(138, 95, 189, 0.2));
  border: 1px solid rgba(138, 95, 189, 0.4);
  border-radius: 20px 20px 6px 20px;
  padding: 14px 18px;
  backdrop-filter: blur(10px);
  box-shadow: 0 4px 15px rgba(138, 95, 189, 0.2);
}

.assistant-message {
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.08), rgba(255, 255, 255, 0.05));
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 20px 20px 20px 6px;
  padding: 14px 18px;
  display: flex;
  align-items: flex-start;
  gap: 12px;
  backdrop-filter: blur(10px);
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
}

/* Enhanced Input Styles */
.text-input-wrapper {
  flex: 1;
  background: linear-gradient(135deg, rgba(28, 28, 30, 0.9), rgba(28, 28, 30, 0.8));
  border: 2px solid rgba(255, 255, 255, 0.1);
  border-radius: 22px;
  overflow: hidden;
  backdrop-filter: blur(20px);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.text-input-wrapper:focus-within {
  border-color: rgba(138, 95, 189, 0.6);
  box-shadow: 0 0 0 4px rgba(138, 95, 189, 0.2);
  background: linear-gradient(135deg, rgba(28, 28, 30, 0.95), rgba(28, 28, 30, 0.9));
}

.input-icon-btn {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.08), rgba(255, 255, 255, 0.05));
  border: 1px solid rgba(255, 255, 255, 0.15);
  color: rgba(255, 255, 255, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  flex-shrink: 0;
  backdrop-filter: blur(10px);
}

.input-icon-btn:hover {
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.15), rgba(255, 255, 255, 0.1));
  color: #fff;
  border-color: rgba(255, 255, 255, 0.3);
  box-shadow: 0 4px 15px rgba(255, 255, 255, 0.1);
}

.send-btn {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  border: 2px solid;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  flex-shrink: 0;
  backdrop-filter: blur(10px);
}

/* Enhanced Suggestion Cards */
.suggestion-card {
  flex-shrink: 0;
  background: linear-gradient(135deg, rgba(28, 28, 30, 0.9), rgba(28, 28, 30, 0.8));
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 18px;
  padding: 16px 20px;
  min-width: 200px;
  text-align: left;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  backdrop-filter: blur(20px);
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
}

.suggestion-card:hover {
  background: linear-gradient(135deg, rgba(138, 95, 189, 0.3), rgba(138, 95, 189, 0.2));
  border-color: rgba(138, 95, 189, 0.5);
  box-shadow: 0 8px 25px rgba(138, 95, 189, 0.3);
}

/* Enhanced Bottom Container */
.bottom-input-container {
  background: linear-gradient(180deg, 
    rgba(0, 0, 0, 0.8) 0%, 
    rgba(0, 0, 0, 0.95) 100%
  );
  backdrop-filter: blur(30px);
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  padding: 20px 24px 24px;
  box-shadow: 0 -8px 32px rgba(0, 0, 0, 0.3);
}

/* 星星和卡片动画样式 */
.inspiration-card {
  @apply bg-cosmic-navy/90 backdrop-blur-sm rounded-lg overflow-hidden;
  width: 400px;
  min-height: 300px;
  perspective: 1000px;
  transform-style: preserve-3d;
  cursor: pointer;
}

.backface-hidden {
  backface-visibility: hidden;
  transform-style: preserve-3d;
}

.star-container {
  position: relative;
  transform-style: preserve-3d;
  perspective: 1000px;
}

.star-core {
  box-shadow: 0 0 20px rgba(255, 255, 255, 0.8);
}

.star-lines {
  pointer-events: none;
}

/* 卡片翻转效果 */
.card-front,
.card-back {
  position: absolute;
  width: 100%;
  height: 100%;
  backface-visibility: hidden;
}

.card-back {
  transform: rotateY(180deg);
}

/* 装饰性粒子 */
.floating-particle {
  @apply absolute w-1 h-1 rounded-full bg-white opacity-30;
  pointer-events: none;
}
```