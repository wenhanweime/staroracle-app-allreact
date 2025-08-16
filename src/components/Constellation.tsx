import React, { useEffect, useState, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import Star from './Star';
import StarRayIcon from './StarRayIcon';

const Constellation: React.FC = () => {
  const { 
    constellation, 
    activeStarId, 
    viewStar, 
    setIsAsking,
    drawInspirationCard,
    pendingStarPosition,
    isLoading
  } = useStarStore();
  const { stars, connections } = constellation;
  const [dimensions, setDimensions] = useState({ width: 0, height: 0 });
  const [mousePos, setMousePos] = useState({ x: 0, y: 0 });
  const [sparkles, setSparkles] = useState<Array<{ id: number; x: number; y: number }>>([]);
  const [lastClickTime, setLastClickTime] = useState(0);
  
  useEffect(() => {
    const updateDimensions = () => {
      setDimensions({
        width: window.innerWidth,
        height: window.innerHeight,
      });
    };
    
    window.addEventListener('resize', updateDimensions);
    updateDimensions();
    
    return () => window.removeEventListener('resize', updateDimensions);
  }, []);
  
  const handleMouseMove = useCallback((e: React.MouseEvent) => {
    setMousePos({ x: e.clientX, y: e.clientY });
  }, []);
  
  const handleStarClick = (id: string) => {
    playSound('starClick');
    viewStar(id);
  };
  
  const createSparkle = (x: number, y: number) => {
    const id = Date.now();
    setSparkles(current => [...current, { id, x, y }]);
    setTimeout(() => {
      setSparkles(current => current.filter(sparkle => sparkle.id !== id));
    }, 1000);
  };
  
  const handleBackgroundClick = (e: React.MouseEvent) => {
    console.log('🌌 Constellation clicked at:', e.clientX, e.clientY);
    console.log('🎯 Click target:', e.target);
    
    // 检查点击是否在按钮区域 - 排除左上角和右上角按钮区域
    const isInButtonArea = (clientX: number, clientY: number) => {
      // 左侧按钮区域 (Collection + Template)
      if (clientX < 200 && clientY < 200) return true;
      // 右侧按钮区域 (Settings)  
      if (clientX > window.innerWidth - 200 && clientY < 200) return true;
      return false;
    };
    
    if (isInButtonArea(e.clientX, e.clientY)) {
      console.log('🚫 Click in button area, ignoring');
      return; // 不处理按钮区域的点击
    }
    
    // If we're currently loading a star, don't allow new interactions
    if (isLoading) return;
    
    if ((e.target as HTMLElement).classList.contains('constellation-area')) {
      console.log('✅ Valid constellation area click');
      const currentTime = Date.now();
      const timeDiff = currentTime - lastClickTime;
      
      const rect = (e.target as HTMLElement).getBoundingClientRect();
      const x = ((e.clientX - rect.left) / rect.width) * 100;
      const y = ((e.clientY - rect.top) / rect.height) * 100;
      
      createSparkle(e.clientX, e.clientY);
      playSound('starClick');
      
      // 检测双击 (300ms内的两次点击)
      if (timeDiff < 300) {
        console.log('🌟 Double click detected - drawing inspiration card');
        // 双击：摘星模式
        drawInspirationCard();
        playSound('starReveal');
      } else {
        // 单击：普通提问模式
        setIsAsking(true, { x, y });
      }
      
      setLastClickTime(currentTime);
    } else {
      console.log('❌ Click not on constellation area');
    }
  };
  
  // 右键点击事件处理 - 显示灵感卡片
  const handleContextMenu = (e: React.MouseEvent) => {
    // If we're currently loading a star, don't allow new interactions
    if (isLoading) return;
    
    e.preventDefault(); // 阻止默认的右键菜单
    console.log('🔍 右键点击事件触发');
    
    if ((e.target as HTMLElement).classList.contains('constellation-area')) {
      const rect = (e.target as HTMLElement).getBoundingClientRect();
      const x = ((e.clientX - rect.left) / rect.width) * 100;
      const y = ((e.clientY - rect.top) / rect.height) * 100;
      
      createSparkle(e.clientX, e.clientY);
      playSound('starReveal');
      
      console.log('🌟 右键点击 - 显示灵感卡片');
      const card = drawInspirationCard();
      console.log('📇 灵感卡片已生成:', card.question);
    }
  };
  
  return (
    <div 
      className="absolute inset-0 overflow-hidden constellation-area"
      onClick={handleBackgroundClick}
      onContextMenu={handleContextMenu}
      onMouseMove={handleMouseMove}
    >
      {/* Hover indicator */}
      <div 
        className="hover-indicator"
        style={{
          left: `${mousePos.x}px`,
          top: `${mousePos.y}px`,
        }}
      />
      
      {/* Loading animation for pending star */}
      {isLoading && pendingStarPosition && (
        <div 
          className="absolute pointer-events-none z-20"
          style={{
            left: `${pendingStarPosition.x}%`,
            top: `${pendingStarPosition.y}%`,
            transform: 'translate(-50%, -50%)'
          }}
        >
          <motion.div
            initial={{ scale: 0, opacity: 0 }}
            animate={{ 
              scale: [0.8, 1.2, 0.8],
              opacity: [0.4, 0.8, 0.4]
            }}
            transition={{
              duration: 2,
              repeat: Infinity,
              ease: "easeInOut"
            }}
            className="flex items-center justify-center"
          >
            <StarRayIcon size={48} animated={true} className="text-cosmic-accent" />
          </motion.div>
        </div>
      )}
      
      {/* Sparkle effects */}
      <AnimatePresence>
        {sparkles.map(sparkle => (
          <motion.div
            key={sparkle.id}
            className="star-sparkle"
            style={{
              left: sparkle.x - 10,
              top: sparkle.y - 10,
            }}
            initial={{ scale: 0, rotate: 0, opacity: 0 }}
            animate={{ scale: 1, rotate: 180, opacity: 1 }}
            exit={{ scale: 0, rotate: 360, opacity: 0 }}
          />
        ))}
      </AnimatePresence>
      
      {/* Star connections - 使用绝对定位的SVG，确保与星星在同一坐标系统 */}
      {dimensions.width > 0 && dimensions.height > 0 && (
        <div className="absolute inset-0 pointer-events-none" style={{ zIndex: 5, overflow: 'visible' }}>
        <svg
          width={dimensions.width}
          height={dimensions.height}
            style={{ 
              position: 'absolute', 
              top: 0, 
              left: 0,
              overflow: 'visible'
            }}
        >
          <defs>
              {connections.map(connection => {
                const fromStar = stars.find(s => s.id === connection.fromStarId);
                const toStar = stars.find(s => s.id === connection.toStarId);
                
                if (!fromStar || !toStar) return null;
                
                // 根据连线标签选择颜色
                const baseColor = (() => {
                  // If the connection belongs to a specific constellation (tag-based), use that tag to determine color
                  if (connection.constellationName) {
                    const tag = connection.constellationName.toLowerCase();
                    
                    // Core Life Areas
                    if (['love', 'romance', 'heart', 'relationship', 'intimacy'].includes(tag)) {
                      return '255, 105, 180'; // Hot Pink
                    }
                    if (['family', 'parents', 'children', 'home', 'roots'].includes(tag)) {
                      return '255, 165, 0'; // Orange
                    }
                    if (['friendship', 'social', 'trust', 'loyalty'].includes(tag)) {
                      return '124, 252, 0'; // Lawn Green
                    }
                    if (['career', 'work', 'profession', 'vocation'].includes(tag)) {
                      return '255, 215, 0'; // Gold
                    }
                    if (['education', 'learning', 'knowledge', 'skills'].includes(tag)) {
                      return '30, 144, 255'; // Dodger Blue
                    }
                    if (['health', 'wellness', 'fitness', 'balance'].includes(tag)) {
                      return '50, 205, 50'; // Lime Green
                    }
                    if (['finance', 'money', 'wealth', 'abundance'].includes(tag)) {
                      return '218, 165, 32'; // Golden Rod
                    }
                    if (['spirituality', 'faith', 'soul', 'divine'].includes(tag)) {
                      return '147, 112, 219'; // Medium Purple
                    }
                    
                    // Inner Experience
                    if (['emotions', 'feelings', 'expression', 'awareness'].includes(tag)) {
                      return '255, 99, 71'; // Tomato
                    }
                    if (['happiness', 'joy', 'fulfillment', 'contentment'].includes(tag)) {
                      return '255, 255, 0'; // Yellow
                    }
                    if (['anxiety', 'fear', 'worry', 'stress'].includes(tag)) {
                      return '70, 130, 180'; // Steel Blue
                    }
                    if (['grief', 'loss', 'sadness', 'mourning'].includes(tag)) {
                      return '75, 0, 130'; // Indigo
                    }
                    
                    // Self Development
                    if (['identity', 'self', 'authenticity', 'values'].includes(tag)) {
                      return '0, 206, 209'; // Dark Turquoise
                    }
                    if (['purpose', 'meaning', 'calling', 'mission'].includes(tag)) {
                      return '138, 43, 226'; // Blue Violet
                    }
                    if (['growth', 'development', 'evolution', 'improvement'].includes(tag)) {
                      return '60, 179, 113'; // Medium Sea Green
                    }
                    if (['resilience', 'strength', 'adaptation', 'recovery'].includes(tag)) {
                      return '178, 34, 34'; // Firebrick
                    }
                    if (['creativity', 'expression', 'imagination', 'innovation'].includes(tag)) {
                      return '255, 140, 0'; // Dark Orange
                    }
                    if (['wisdom', 'insight', 'perspective', 'understanding'].includes(tag)) {
                      return '186, 85, 211'; // Medium Orchid
                    }
                    
                    // Default colors for other tags
                    if (['mindfulness', 'presence', 'awareness'].includes(tag)) {
                      return '240, 230, 140'; // Khaki
                    }
                    if (['change', 'transition', 'transformation'].includes(tag)) {
                      return '0, 191, 255'; // Deep Sky Blue
                    }
                    
                    // If no specific match, use a hash-based color to ensure consistent colors for same tag
                    const hash = tag.split('').reduce((acc, char) => {
                      return acc + char.charCodeAt(0);
                    }, 0);
                    
                    // Generate a pastel color based on the hash
                    const h = hash % 360;
                    const s = 70 + (hash % 20); // 70-90%
                    const l = 65 + (hash % 15); // 65-80%
                    
                    // Convert HSL to RGB
                    const c = (1 - Math.abs(2 * l / 100 - 1)) * s / 100;
                    const x = c * (1 - Math.abs((h / 60) % 2 - 1));
                    const m = l / 100 - c / 2;
                    
                    let r, g, b;
                    if (h < 60) { r = c; g = x; b = 0; }
                    else if (h < 120) { r = x; g = c; b = 0; }
                    else if (h < 180) { r = 0; g = c; b = x; }
                    else if (h < 240) { r = 0; g = x; b = c; }
                    else if (h < 300) { r = x; g = 0; b = c; }
                    else { r = c; g = 0; b = x; }
                    
                    r = Math.round((r + m) * 255);
                    g = Math.round((g + m) * 255);
                    b = Math.round((b + m) * 255);
                    
                    return `${r}, ${g}, ${b}`;
                  }
                  
                  // Fall back to original logic for connections not based on specific constellation
                  if (connection.sharedTags?.includes('love') || connection.sharedTags?.includes('romance')) {
                    return '255, 182, 193'; // 粉色
                  }
                  if (connection.sharedTags?.includes('wisdom') || connection.sharedTags?.includes('purpose')) {
                    return '138, 95, 189'; // 紫色
                  }
                  if (connection.sharedTags?.includes('success') || connection.sharedTags?.includes('career')) {
                    return '255, 215, 0'; // 金色
                  }
                  return '255, 255, 255'; // 白色
                })();
                
                // 计算星星中心的像素坐标
                const fromX = (fromStar.x / 100) * dimensions.width;
                const fromY = (fromStar.y / 100) * dimensions.height;
                const toX = (toStar.x / 100) * dimensions.width;
                const toY = (toStar.y / 100) * dimensions.height;
              
              return (
                  <linearGradient
                    key={connection.id}
                    id={`gradient-${connection.id}`}
                    gradientUnits="userSpaceOnUse"
                    x1={fromX}
                    y1={fromY}
                    x2={toX}
                    y2={toY}
                  >
                  <stop offset="0%" stopColor={`rgba(${baseColor}, 0)`} />
                  <stop offset="25%" stopColor={`rgba(${baseColor}, 0.2)`} />
                  <stop offset="50%" stopColor={`rgba(${baseColor}, 0.6)`} />
                  <stop offset="75%" stopColor={`rgba(${baseColor}, 0.2)`} />
                  <stop offset="100%" stopColor={`rgba(${baseColor}, 0)`} />
                </linearGradient>
              );
            })}
          </defs>
          
          {connections.map((connection, index) => {
            const fromStar = stars.find(s => s.id === connection.fromStarId);
            const toStar = stars.find(s => s.id === connection.toStarId);
            
            if (!fromStar || !toStar) return null;
            
              // 计算星星中心的像素坐标
            const fromX = (fromStar.x / 100) * dimensions.width;
            const fromY = (fromStar.y / 100) * dimensions.height;
            const toX = (toStar.x / 100) * dimensions.width;
            const toY = (toStar.y / 100) * dimensions.height;
            
            const isActive = fromStar.id === activeStarId || toStar.id === activeStarId;
            const connectionStrength = connection.strength || 0.3;
            
            return (
              <g key={connection.id}>
                {/* 背景光晕层 - 最粗，营造氛围 */}
                <motion.line
                  x1={fromX}
                  y1={fromY}
                  x2={toX}
                  y2={toY}
                  stroke={`url(#gradient-${connection.id})`}
                  strokeWidth={isActive ? 6 : Math.max(3, connectionStrength * 5)}
                  filter="blur(3px)"
                  initial={{ 
                    pathLength: 0,
                    opacity: 0 
                  }}
                  animate={{ 
                    pathLength: 1,
                    opacity: isActive 
                      ? [0.2, 0.5, 0.2] 
                      : [0.05, Math.max(0.15, connectionStrength * 0.3), 0.05]
                  }}
                  transition={{ 
                    pathLength: { duration: 2, ease: "easeInOut", delay: index * 0.1 },
                    opacity: { 
                      duration: 4 + Math.random() * 2, 
                      repeat: Infinity, 
                      ease: "easeInOut",
                      delay: index * 0.3
                    }
                  }}
                />
                
                {/* 中间层 - 中等粗细，主要呼吸效果 */}
                <motion.line
                  x1={fromX}
                  y1={fromY}
                  x2={toX}
                  y2={toY}
                  stroke={`url(#gradient-${connection.id})`}
                  strokeWidth={isActive ? 3 : Math.max(1.5, connectionStrength * 2.5)}
                  filter="blur(1px)"
                  initial={{ 
                    pathLength: 0,
                    opacity: 0 
                  }}
                  animate={{ 
                    pathLength: 1,
                    opacity: isActive 
                      ? [0.3, 0.7, 0.3] 
                      : [0.1, Math.max(0.25, connectionStrength * 0.5), 0.1]
                  }}
                  transition={{ 
                    pathLength: { duration: 2.5, ease: "easeInOut", delay: index * 0.15 },
                    opacity: { 
                      duration: 5 + Math.random() * 3, 
                      repeat: Infinity, 
                      ease: "easeInOut",
                      delay: index * 0.4 + 0.5
                    }
                  }}
                />
                
                {/* 核心层 - 最细最亮，精确连接 */}
                <motion.line
                  x1={fromX}
                  y1={fromY}
                  x2={toX}
                  y2={toY}
                  stroke={`url(#gradient-${connection.id})`}
                  strokeWidth={isActive ? 1 : Math.max(0.5, connectionStrength)}
                  initial={{ 
                    pathLength: 0,
                    opacity: 0 
                  }}
                  animate={{ 
                    pathLength: 1,
                    opacity: isActive 
                      ? [0.5, 1, 0.5] 
                      : [0.2, Math.max(0.4, connectionStrength * 0.8), 0.2]
                  }}
                  transition={{ 
                    pathLength: { duration: 3, ease: "easeInOut", delay: index * 0.2 },
                    opacity: { 
                      duration: 6 + Math.random() * 4, 
                      repeat: Infinity, 
                      ease: "easeInOut",
                      delay: index * 0.5 + 1
                    }
                  }}
                />
                
                {/* 激活时的流动光点 */}
                {isActive && (
                  <motion.circle
                    cx={fromX}
                    cy={fromY}
                    r="1.5"
                    fill="rgba(255, 255, 255, 0.9)"
                    initial={{ opacity: 0 }}
                    animate={{ 
                      cx: [fromX, toX, fromX],
                      cy: [fromY, toY, fromY],
                      opacity: [0, 1, 0]
                    }}
                    transition={{
                      duration: 3,
                      repeat: Infinity,
                      ease: "easeInOut"
                    }}
                  />
                )}
              </g>
            );
          })}
        </svg>
        </div>
      )}
      
      {/* Stars */}
      {stars.map(star => {
        const pixelX = (star.x / 100) * dimensions.width;
        const pixelY = (star.y / 100) * dimensions.height;
        const isActive = star.id === activeStarId;
        
        // Find connected stars
        const connectedStars = connections
          .filter(conn => conn.fromStarId === star.id || conn.toStarId === star.id)
          .map(conn => conn.fromStarId === star.id ? conn.toStarId : conn.fromStarId);
        
        const hasStrongConnections = connections.some(
          conn => (conn.fromStarId === star.id || conn.toStarId === star.id) && conn.strength > 0.4
        );
        
        return (
          <Star
            key={star.id}
            x={pixelX}
            y={pixelY}
            size={star.size * (hasStrongConnections ? 1.2 : 1)}
            brightness={star.brightness}
            isSpecial={star.isSpecial || hasStrongConnections}
            isActive={isActive}
            onClick={() => handleStarClick(star.id)}
            tags={star.tags}
            category={star.primary_category} // Updated to use primary_category
            connectionCount={connectedStars.length}
          />
        );
      })}
    </div>
  );
};

export default Constellation;