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
                justifyContent: 'center', // 确保内容垂直居中
                alignItems: 'center', // 确保内容水平居中
                position: 'relative'
              }}
            >
              <div className="star-card-constellation" style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                position: 'relative',
                flex: '1', // 改为占据剩余空间
                height: '200px', // 固定高度
                width: '100%',
                minHeight: '200px' // 确保最小高度
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