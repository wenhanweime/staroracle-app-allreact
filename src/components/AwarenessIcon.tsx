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
  // 不同等级的颜色配置
  const getColorConfig = () => {
    if (!isActive) return { primary: 'rgba(255,255,255,0.3)', secondary: 'rgba(255,255,255,0.1)' };
    
    switch (level) {
      case 'high':
        return { primary: '#FFD700', secondary: '#FFA500' }; // 金色 - 高价值
      case 'medium':
        return { primary: '#87CEEB', secondary: '#4169E1' }; // 天蓝色 - 中等价值
      case 'low':
        return { primary: '#98FB98', secondary: '#32CD32' }; // 浅绿色 - 低价值
      default:
        return { primary: 'rgba(255,255,255,0.3)', secondary: 'rgba(255,255,255,0.1)' };
    }
  };

  const colors = getColorConfig();

  // 如果正在分析，显示加载动画
  if (isAnalyzing) {
    return (
      <motion.div
        className="cursor-pointer"
        onClick={onClick}
        whileHover={{ scale: 1.1 }}
        whileTap={{ scale: 0.95 }}
      >
        <motion.svg
          width={size}
          height={size}
          viewBox="0 0 24 24"
          fill="none"
          animate={{ rotate: 360 }}
          transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
        >
          {/* 分析中的旋转圆环 */}
          <circle
            cx="12"
            cy="12"
            r="8"
            stroke="rgba(138, 95, 189, 0.6)"
            strokeWidth="2"
            strokeDasharray="20 10"
            fill="none"
          />
          {/* 中心圆点 */}
          <circle
            cx="12"
            cy="12"
            r="3"
            fill="rgba(138, 95, 189, 0.8)"
          />
        </motion.svg>
      </motion.div>
    );
  }

  // 觉察图标 - 类似眼睛或洞察符号
  return (
    <motion.div
      className="cursor-pointer"
      onClick={onClick}
      whileHover={{ scale: isActive ? 1.2 : 1.1 }}
      whileTap={{ scale: 0.9 }}
      initial={{ opacity: 0.6 }}
      animate={{ 
        opacity: isActive ? 1 : 0.6,
        filter: isActive ? 'drop-shadow(0 0 8px rgba(255,255,255,0.6))' : 'none'
      }}
      transition={{ duration: 0.3 }}
    >
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        fill="none"
      >
        {/* 外圆 - 代表觉察的边界 */}
        <motion.circle
          cx="12"
          cy="12"
          r="9"
          stroke={colors.primary}
          strokeWidth="1.5"
          fill="none"
          initial={{ pathLength: 0 }}
          animate={{ pathLength: isActive ? 1 : 0.3 }}
          transition={{ duration: 1, ease: "easeInOut" }}
        />
        
        {/* 内圆 - 代表内在洞察 */}
        <motion.circle
          cx="12"
          cy="12"
          r="5"
          fill={isActive ? colors.primary : colors.secondary}
          opacity={isActive ? 0.8 : 0.4}
          animate={{ 
            scale: isActive ? [1, 1.1, 1] : 1,
            opacity: isActive ? [0.8, 1, 0.8] : 0.4 
          }}
          transition={{ 
            duration: 2, 
            repeat: isActive ? Infinity : 0, 
            ease: "easeInOut" 
          }}
        />
        
        {/* 中心点 - 代表觉察的核心 */}
        <motion.circle
          cx="12"
          cy="12"
          r="2"
          fill={isActive ? "#FFFFFF" : colors.secondary}
          animate={{ 
            opacity: isActive ? [1, 0.6, 1] : 0.6 
          }}
          transition={{ 
            duration: 1.5, 
            repeat: isActive ? Infinity : 0,
            ease: "easeInOut" 
          }}
        />
        
        {/* 觉察射线 - 只在有价值时显示 */}
        {isActive && (
          <>
            {[0, 45, 90, 135, 180, 225, 270, 315].map((angle, index) => (
              <motion.line
                key={angle}
                x1="12"
                y1="12"
                x2={12 + Math.cos(angle * Math.PI / 180) * 12}
                y2={12 + Math.sin(angle * Math.PI / 180) * 12}
                stroke={colors.secondary}
                strokeWidth="1"
                opacity="0.6"
                initial={{ pathLength: 0, opacity: 0 }}
                animate={{ 
                  pathLength: [0, 1, 0],
                  opacity: [0, 0.6, 0]
                }}
                transition={{ 
                  duration: 2,
                  repeat: Infinity,
                  delay: index * 0.1,
                  ease: "easeInOut"
                }}
              />
            ))}
          </>
        )}
      </svg>
      
      {/* 等级指示器 - 小圆点显示觉察等级 */}
      {isActive && (
        <motion.div
          className="absolute -top-1 -right-1"
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ duration: 0.3, delay: 0.2 }}
        >
          <div 
            className="w-2 h-2 rounded-full"
            style={{
              backgroundColor: colors.primary,
              boxShadow: `0 0 4px ${colors.primary}`
            }}
          />
        </motion.div>
      )}
    </motion.div>
  );
};

export default AwarenessIcon;