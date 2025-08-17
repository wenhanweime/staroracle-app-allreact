import React from 'react';

// StarRayIcon组件接口 - 按照demo版本设计
interface StarRayIconProps {
  size?: number;
  animated?: boolean;
  iconColor?: string;
  className?: string;
  color?: string; // 保持向后兼容
  isSpecial?: boolean; // 保持向后兼容
}

const StarRayIcon: React.FC<StarRayIconProps> = ({ 
  size = 20, 
  animated = false, 
  iconColor = "#ffffff",
  className = "",
  color, // 向后兼容参数
  isSpecial = false // 向后兼容参数
}) => {
  // 优先使用iconColor参数，然后是color参数，最后是默认值
  const finalColor = iconColor || color || (isSpecial ? "#FFD700" : "#ffffff");
  
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={`star-ray-icon ${className}`}
    >
      {/* Center circle */}
      {animated ? (
        <circle
          cx="12"
          cy="12"
          r="2"
          fill={finalColor}
          className="animate-pulse"
        />
      ) : (
        <circle cx="12" cy="12" r="2" fill={finalColor} />
      )}
      
      {/* Eight rays */}
      {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => {
        const angle = (i * 45) * (Math.PI / 180); // Convert to radians
        const startX = 12 + Math.cos(angle) * 3;
        const startY = 12 + Math.sin(angle) * 3;
        const endX = 12 + Math.cos(angle) * 8;
        const endY = 12 + Math.sin(angle) * 8;
        
        return animated ? (
          <line
            key={i}
            x1={startX}
            y1={startY}
            x2={endX}
            y2={endY}
            stroke={finalColor}
            strokeWidth="2"
            strokeLinecap="round"
            className="animate-ray"
            style={{
              animation: `rayExpand 0.5s ease-out ${0.1 + i * 0.05}s both`,
              transformOrigin: '12px 12px'
            }}
          />
        ) : (
          <line
            key={i}
            x1={startX}
            y1={startY}
            x2={endX}
            y2={endY}
            stroke={finalColor}
            strokeWidth="2"
            strokeLinecap="round"
          />
        );
      })}
      
      {/* CSS Animation styles - 内联样式来确保动画正常工作 */}
      <style jsx>{`
        @keyframes rayExpand {
          0% {
            stroke-dasharray: 5;
            stroke-dashoffset: 5;
          }
          100% {
            stroke-dasharray: 5;
            stroke-dashoffset: 0;
          }
        }
        .animate-ray {
          stroke-dasharray: 5;
          stroke-dashoffset: 0;
        }
      `}</style>
    </svg>
  );
};

export default StarRayIcon; 