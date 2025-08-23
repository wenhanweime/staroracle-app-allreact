import React from 'react';
import { motion } from 'framer-motion';

interface FloatingAwarenessPlanetProps {
  level: 'none' | 'low' | 'medium' | 'high';
  isAnalyzing: boolean;
  conversationDepth: number; // 0-100 的对话深度百分比
  onTogglePanel?: () => void;
}

const FloatingAwarenessPlanet: React.FC<FloatingAwarenessPlanetProps> = ({
  level,
  isAnalyzing,
  conversationDepth,
  onTogglePanel
}) => {
  // 根据觉察等级配置星星颜色，从灰色到明亮紫色
  const getStarColor = () => {
    if (isAnalyzing) {
      return '#8A5FBD'; // 明亮紫色
    }
    
    // 计算从灰色到紫色的渐变
    const progress = 
      level === 'none' ? 0 :
      level === 'low' ? 0.33 :
      level === 'medium' ? 0.66 :
      level === 'high' ? 1 : 0;
    
    // 从灰色 #888888 到明亮紫色 #8A5FBD
    const gray = { r: 136, g: 136, b: 136 };
    const purple = { r: 138, g: 95, b: 189 };
    
    const r = Math.round(gray.r + (purple.r - gray.r) * progress);
    const g = Math.round(gray.g + (purple.g - gray.g) * progress);
    const b = Math.round(gray.b + (purple.b - gray.b) * progress);
    
    return `rgb(${r}, ${g}, ${b})`;
  };

  const starColor = getStarColor();
  const isActive = level !== 'none' || isAnalyzing;

  return (
    <motion.div
      className="cursor-pointer" // 移除fixed定位，适应输入框内部
      style={{ 
        width: '32px', // 缩小尺寸适应输入框
        height: '32px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center'
      }}
      initial={{ scale: 0, opacity: 0 }}
      animate={{ 
        scale: 1, 
        opacity: 1
      }}
      whileHover={{ scale: 1.1 }}
      whileTap={{ scale: 0.9 }}
      onClick={onTogglePanel}
      transition={{ duration: 0.3, ease: "easeOut" }}
    >
      {/* BURST 动画：使用原版参数，调整尺寸适应输入框 */}
      <svg width="32" height="32" viewBox="0 0 32 32">
        {/* 中心点 */}
        <motion.circle
          cx="16" // 调整中心点到32px容器的中心
          cy="16"
          r="1.5" // 缩小中心点
          fill={starColor}
          animate={isActive ? {
            scale: [1, 1.2, 1],
            opacity: [0.8, 1, 0.8]
          } : {}}
          transition={{
            duration: 2,
            repeat: isActive ? Infinity : 0,
            ease: "easeInOut"
          }}
        />
        
        {/* 12条随机长度射线 - 缩放适应32px容器 */}
        {Array.from({ length: 12 }).map((_, i) => {
          const angle = (i * Math.PI * 2) / 12;
          const seedRandom = (seed: number) => {
            const x = Math.sin(seed) * 10000;
            return x - Math.floor(x);
          };
          const length = 5 + seedRandom(i) * 8; // 缩小长度适应32px容器
          const strokeWidth = seedRandom(i + 12) * 1.2 + 0.3; // 缩小线宽
          
          return (
            <motion.line
              key={`burst-${i}`}
              x1="16" // 调整到32px容器的中心
              y1="16"
              x2={16 + Math.cos(angle) * length}
              y2={16 + Math.sin(angle) * length}
              stroke={starColor}
              strokeWidth={strokeWidth}
              strokeLinecap="round"
              initial={{ pathLength: 0, opacity: 0 }}
              animate={isActive ? { 
                pathLength: [0, 1, 0],
                opacity: [0, 0.7, 0],
              } : { pathLength: 0, opacity: 0.2 }}
              transition={{
                duration: 2 + seedRandom(i + 24),
                delay: i * 0.05,
                repeat: isActive ? Infinity : 0,
                repeatDelay: seedRandom(i + 36),
              }}
            />
          );
        })}
      </svg>
    </motion.div>
  );
};

export default FloatingAwarenessPlanet;