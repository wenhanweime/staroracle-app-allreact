import React from 'react';
import { motion } from 'framer-motion';

interface AwarenessIconProps {
  level: 'low' | 'medium' | 'high';
  isActive: boolean; // 是否有觉察价值
  isAnalyzing: boolean; // 是否正在分析
  size?: number;
  onClick?: () => void;
}

const AwarenessIcon: React.FC<AwarenessIconProps> = ({ 
  level, 
  isActive, 
  isAnalyzing, 
  size = 20, 
  onClick 
}) => {
  // 根据觉察等级配置不同的星星效果
  const getStarConfig = () => {
    if (!isActive && !isAnalyzing) {
      return { 
        color: 'rgba(255,255,255,0.3)', 
        brightness: 0.3,
        rayCount: 0,
        glowIntensity: 0
      };
    }
    
    switch (level) {
      case 'high':
        return { 
          color: '#FFD700', // 金色超新星
          brightness: 1,
          rayCount: 8, // 8条射线
          glowIntensity: 0.8,
          starType: 'supernova'
        };
      case 'medium':
        return { 
          color: '#87CEEB', // 蓝色启明星
          brightness: 0.8,
          rayCount: 6, // 6条射线
          glowIntensity: 0.6,
          starType: 'bright'
        };
      case 'low':
        return { 
          color: '#98FB98', // 绿色微光星
          brightness: 0.6,
          rayCount: 4, // 4条射线
          glowIntensity: 0.4,
          starType: 'dim'
        };
      default:
        return { 
          color: 'rgba(255,255,255,0.5)', 
          brightness: 0.5,
          rayCount: 4,
          glowIntensity: 0.3
        };
    }
  };

  const config = getStarConfig();

  // 分析中的旋转星星动画
  if (isAnalyzing) {
    return (
      <motion.div
        className="cursor-pointer relative"
        onClick={onClick}
        whileHover={{ scale: 1.1 }}
        whileTap={{ scale: 0.95 }}
        style={{ width: size, height: size }}
      >
        <motion.svg
          width={size}
          height={size}
          viewBox="0 0 24 24"
          fill="none"
          animate={{ rotate: [0, 360] }}
          transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
        >
          {/* 中心星核 */}
          <motion.circle
            cx="12"
            cy="12"
            r="2.5"
            fill="rgba(138, 95, 189, 0.8)"
            animate={{
              scale: [1, 1.2, 1],
              opacity: [0.8, 1, 0.8]
            }}
            transition={{
              duration: 1.5,
              repeat: Infinity,
              ease: "easeInOut"
            }}
          />
          
          {/* 分析射线 - 渐次出现 */}
          {[0, 1, 2, 3, 4, 5].map((i) => {
            const angle = (i * 60) * (Math.PI / 180);
            const startX = 12 + Math.cos(angle) * 3.5;
            const startY = 12 + Math.sin(angle) * 3.5;
            const endX = 12 + Math.cos(angle) * 8;
            const endY = 12 + Math.sin(angle) * 8;
            
            return (
              <motion.line
                key={i}
                x1={startX}
                y1={startY}
                x2={endX}
                y2={endY}
                stroke="rgba(138, 95, 189, 0.6)"
                strokeWidth="1.5"
                strokeLinecap="round"
                initial={{ pathLength: 0, opacity: 0 }}
                animate={{
                  pathLength: [0, 1, 0],
                  opacity: [0, 0.8, 0]
                }}
                transition={{
                  duration: 2,
                  repeat: Infinity,
                  delay: i * 0.2,
                  ease: "easeInOut"
                }}
              />
            );
          })}
        </motion.svg>
      </motion.div>
    );
  }

  // 基于觉察等级的星星图标
  return (
    <motion.div
      className="cursor-pointer relative"
      onClick={onClick}
      whileHover={{ 
        scale: isActive ? 1.3 : 1.1,
        filter: isActive ? `drop-shadow(0 0 8px ${config.color})` : 'none'
      }}
      whileTap={{ scale: 0.9 }}
      style={{ width: size, height: size }}
      initial={{ opacity: 0, scale: 0.5 }}
      animate={{ 
        opacity: isActive ? 1 : 0.4,
        scale: 1,
        filter: isActive ? `drop-shadow(0 0 4px ${config.color})` : 'none'
      }}
      transition={{ duration: 0.5, ease: "easeOut" }}
    >
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        fill="none"
      >
        {/* 星星核心 */}
        <motion.circle
          cx="12"
          cy="12"
          r="2.5"
          fill={config.color}
          animate={isActive ? {
            scale: [1, 1.1, 1],
            opacity: [config.brightness, Math.min(1, config.brightness + 0.2), config.brightness]
          } : {}}
          transition={{
            duration: config.starType === 'supernova' ? 1.5 : 2,
            repeat: isActive ? Infinity : 0,
            ease: "easeInOut"
          }}
        />
        
        {/* 星星射线 - 数量根据等级变化 */}
        {isActive && config.rayCount > 0 && (
          <>
            {Array.from({ length: config.rayCount }, (_, i) => {
              const angle = (i * (360 / config.rayCount)) * (Math.PI / 180);
              const startX = 12 + Math.cos(angle) * 3.5;
              const startY = 12 + Math.sin(angle) * 3.5;
              const endX = 12 + Math.cos(angle) * (config.starType === 'supernova' ? 9 : 7.5);
              const endY = 12 + Math.sin(angle) * (config.starType === 'supernova' ? 9 : 7.5);
              
              return (
                <motion.line
                  key={i}
                  x1={startX}
                  y1={startY}
                  x2={endX}
                  y2={endY}
                  stroke={config.color}
                  strokeWidth={config.starType === 'supernova' ? "2" : "1.5"}
                  strokeLinecap="round"
                  opacity={config.brightness}
                  initial={{ pathLength: 0, opacity: 0 }}
                  animate={{
                    pathLength: [0, 1, 0.8],
                    opacity: [0, config.brightness, config.brightness * 0.7]
                  }}
                  transition={{
                    duration: config.starType === 'supernova' ? 2 : 2.5,
                    repeat: Infinity,
                    delay: i * 0.1,
                    ease: "easeInOut"
                  }}
                />
              );
            })}
          </>
        )}
        
        {/* 超新星额外效果 - 外圈光环 */}
        {isActive && config.starType === 'supernova' && (
          <motion.circle
            cx="12"
            cy="12"
            r="6"
            stroke={config.color}
            strokeWidth="0.5"
            fill="none"
            opacity="0.4"
            animate={{
              scale: [1, 1.2, 1],
              opacity: [0.4, 0.1, 0.4]
            }}
            transition={{
              duration: 3,
              repeat: Infinity,
              ease: "easeInOut"
            }}
          />
        )}
        
        {/* 亮星脉冲效果 */}
        {isActive && config.starType === 'bright' && (
          <>
            {[0, 1, 2, 3].map((i) => {
              const angle = (i * 90) * (Math.PI / 180);
              const x1 = 12 + Math.cos(angle) * 4;
              const y1 = 12 + Math.sin(angle) * 4;
              const x2 = 12 + Math.cos(angle) * 6;
              const y2 = 12 + Math.sin(angle) * 6;
              
              return (
                <motion.line
                  key={`pulse-${i}`}
                  x1={x1}
                  y1={y1}
                  x2={x2}
                  y2={y2}
                  stroke={config.color}
                  strokeWidth="1"
                  strokeLinecap="round"
                  opacity="0.6"
                  animate={{
                    pathLength: [0, 1, 0],
                    opacity: [0, 0.6, 0]
                  }}
                  transition={{
                    duration: 2.5,
                    repeat: Infinity,
                    delay: i * 0.15 + 1,
                    ease: "easeInOut"
                  }}
                />
              );
            })}
          </>
        )}
      </svg>
    </motion.div>
  );
};

export default AwarenessIcon;