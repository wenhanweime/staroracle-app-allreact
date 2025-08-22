import React from 'react';
import { motion } from 'framer-motion';

interface StarLoadingAnimationProps {
  size?: number;
  className?: string;
}

const StarLoadingAnimation: React.FC<StarLoadingAnimationProps> = ({ 
  size = 16,
  className = "" 
}) => {
  return (
    <div className={`inline-flex items-center justify-center ${className}`}>
      <motion.div
        className="flex items-center justify-center"
        animate={{
          rotate: [0, 360],
          scale: [1, 1.1, 1],
        }}
        transition={{
          rotate: { duration: 2, repeat: Infinity, ease: "linear" },
          scale: { duration: 1, repeat: Infinity, ease: "easeInOut" }
        }}
      >
        <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
          <circle cx="12" cy="12" r="2" fill="#ffffff" />
          {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => {
            const angle = (i * 45) * (Math.PI / 180);
            const startX = 12 + Math.cos(angle) * 3;
            const startY = 12 + Math.sin(angle) * 3;
            const endX = 12 + Math.cos(angle) * 8;
            const endY = 12 + Math.sin(angle) * 8;
            
            return (
              <line
                key={i}
                x1={startX}
                y1={startY}
                x2={endX}
                y2={endY}
                stroke="#ffffff"
                strokeWidth="1.5"
                strokeLinecap="round"
                opacity={0.8}
              />
            );
          })}
        </svg>
      </motion.div>
    </div>
  );
};

export default StarLoadingAnimation;