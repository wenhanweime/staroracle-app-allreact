import React from 'react';
import { motion } from 'framer-motion';

interface StarRayIconProps {
  size?: number;
  color?: string;
  animated?: boolean;
  className?: string;
  isSpecial?: boolean;
}

const StarRayIcon: React.FC<StarRayIconProps> = ({ 
  size = 24, 
  color,
  animated = false,
  className = "",
  isSpecial = false
}) => {
  // 为图标生成唯一ID，用于渐变效果
  const iconId = `star-ray-${React.useId()}`;
  
  // Special stars get a gold color by default, regular stars get white/current
  const iconColor = color || (isSpecial ? "#FFD700" : "currentColor");
  
  return (
    <svg 
      className={className}
      width={size} 
      height={size} 
      viewBox="0 0 24 24" 
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      style={{ pointerEvents: 'none' }}
    >
      <defs>
        <radialGradient id={iconId} cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor={iconColor} stopOpacity="0.8"/>
          <stop offset="100%" stopColor={iconColor} stopOpacity="0"/>
        </radialGradient>
      </defs>
      
      {/* 中心星点 */}
      {animated ? (
        <motion.circle
          cx="12"
          cy="12"
          r={isSpecial ? "3" : "2"}
          fill={`url(#${iconId})`}
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ delay: 0.1, type: "spring" }}
        />
      ) : (
        <circle cx="12" cy="12" r={isSpecial ? "3" : "2"} fill={iconColor} />
      )}
      
      {/* 八条星芒 */}
      {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => (
        animated ? (
          <motion.line
            key={i}
            x1="12"
            y1="12"
            x2={12 + Math.cos(i * Math.PI / 4) * (isSpecial ? 11 : 10)}
            y2={12 + Math.sin(i * Math.PI / 4) * (isSpecial ? 11 : 10)}
            stroke={iconColor}
            strokeWidth={isSpecial ? "2" : "1.5"}
            initial={{ pathLength: 0, opacity: 0 }}
            animate={{ 
              pathLength: 1,
              opacity: 1
            }}
            transition={{
              duration: 0.5,
              delay: 0.1 + i * 0.05,
            }}
          />
        ) : (
          <line
            key={i}
            x1="12"
            y1="12"
            x2={12 + Math.cos(i * Math.PI / 4) * (isSpecial ? 11 : 10)}
            y2={12 + Math.sin(i * Math.PI / 4) * (isSpecial ? 11 : 10)}
            stroke={iconColor}
            strokeWidth={isSpecial ? "2" : "1.5"}
          />
        )
      ))}
    </svg>
  );
};

export default StarRayIcon; 