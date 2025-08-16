import React from 'react';
import { motion } from 'framer-motion';

interface StarProps {
  x: number;
  y: number;
  size: number;
  brightness: number;
  isSpecial: boolean;
  isActive: boolean;
  isGrowing?: boolean;
  onClick: () => void;
  tags?: string[];
  category?: string;
  connectionCount?: number;
}

const Star: React.FC<StarProps> = ({
  x,
  y,
  size,
  brightness,
  isSpecial,
  isActive,
  isGrowing = false,
  onClick,
  tags = [],
  category = 'existential',
  connectionCount = 0,
}) => {
  return (
    // 1. 外部定位容器：负责精确定位在坐标系中
    <div
      style={{
        position: 'absolute',
        left: `${x}px`,
        top: `${y}px`,
        transform: 'translate(-50%, -50%)',
        // 使用Flexbox确保内部元素完美居中
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        // 设置一个合理的点击区域
        width: `${size * 1.5}px`,
        height: `${size * 1.5}px`,
        cursor: 'pointer',
        zIndex: isGrowing ? 20 : 10,
      }}
      onClick={onClick}
      title={`${category.replace('_', ' ')} • ${tags.slice(0, 3).join(', ')}`}
    >
      {/* 2. 视觉元素容器：负责星星的外观和动画 */}
      <motion.div
        className={`star-container ${isActive ? 'pulse' : ''} ${isSpecial ? 'special twinkle' : ''}`}
        initial={{ opacity: 0, scale: 0 }}
        animate={{ 
          opacity: isGrowing ? 1 : brightness,
          scale: isGrowing ? 2 : 1,
        }}
        whileHover={{ scale: isGrowing ? 2 : 1.5, opacity: 1 }}
        whileTap={{ scale: 0.9 }}
        style={{
          width: `${size}px`,
          height: `${size}px`,
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
        }}
      >
        {/* 3. 星星核心：实际的星星视觉效果 */}
        <motion.div
          className="star-core"
          style={{
            width: '100%',
            height: '100%',
            backgroundColor: '#fff',
            borderRadius: '50%',
            filter: isActive ? 'blur(0)' : 'blur(1px)',
          }}
        />
        
        {/* 4. 星星辐射线：仅在增长状态显示 */}
        {isGrowing && (
          <svg
            className="star-lines"
            style={{
              position: 'absolute',
              top: '50%',
              left: '50%',
              transform: 'translate(-50%, -50%)',
              width: '200%',
              height: '200%',
            }}
          >
            {[0, 1, 2, 3].map((i) => (
              <motion.line
                key={i}
                x1="50%"
                y1="50%"
                x2={`${50 + Math.cos(i * Math.PI / 2) * 40}%`}
                y2={`${50 + Math.sin(i * Math.PI / 2) * 40}%`}
                stroke="#fff"
                strokeWidth="1"
                initial={{ pathLength: 0, opacity: 0 }}
                animate={{ 
                  pathLength: 1,
                  opacity: [0, 0.8, 0],
                }}
                transition={{
                  duration: 1.5,
                  delay: i * 0.2,
                  repeat: Infinity,
                  repeatDelay: 1,
                }}
              />
            ))}
          </svg>
        )}
      </motion.div>
    </div>
  );
};

export default Star;