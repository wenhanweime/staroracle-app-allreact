import React from 'react';
import { motion } from 'framer-motion';
import { useStarStore } from '../store/useStarStore';

const normalizeHex = (hex: unknown) => {
  if (!hex && hex !== 0) return '#FFFFFF';
  let value = typeof hex === 'string' ? hex.trim() : String(hex).trim();
  if (!value.startsWith('#')) return '#FFFFFF';
  if (value.length === 4) {
    value = `#${value[1]}${value[1]}${value[2]}${value[2]}${value[3]}${value[3]}`;
  }
  if (value.length !== 7) return '#FFFFFF';
  return value.toUpperCase();
};

const hexToRgba = (hex: string, alpha: number) => {
  const normalized = normalizeHex(hex);
  const r = parseInt(normalized.slice(1, 3), 16);
  const g = parseInt(normalized.slice(3, 5), 16);
  const b = parseInt(normalized.slice(5, 7), 16);
  const clamped = Math.max(0, Math.min(1, alpha));
  return `rgba(${r}, ${g}, ${b}, ${clamped})`;
};

interface StarProps {
  id: string;
  x: number;
  y: number;
  size: number;
  brightness: number;
  isSpecial: boolean;
  isActive: boolean;
  isHighlighted?: boolean;
  isGrowing?: boolean;
  onClick: () => void;
  tags?: string[];
  category?: string;
  connectionCount?: number;
}

const Star: React.FC<StarProps> = ({
  id,
  x,
  y,
  size,
  brightness,
  isSpecial,
  isActive,
  isHighlighted = false,
  isGrowing = false,
  onClick,
  tags = [],
  category = 'existential',
  connectionCount = 0,
}) => {
  const highlightColor = useStarStore(React.useCallback(state => state.galaxyHighlights[id]?.color ?? null, [id]));
  const normalizedHighlight = React.useMemo(() => highlightColor ? normalizeHex(highlightColor) : null, [highlightColor]);
  const highlightGlowPrimary = React.useMemo(() => normalizedHighlight ? hexToRgba(normalizedHighlight, 0.6) : null, [normalizedHighlight]);
  const highlightGlowSecondary = React.useMemo(() => normalizedHighlight ? hexToRgba(normalizedHighlight, 0.35) : null, [normalizedHighlight]);
  const isForegroundHighlighted = isActive || isHighlighted || !!normalizedHighlight;
  const targetOpacity = React.useMemo(() => {
    if (isGrowing) return 1;
    if (isForegroundHighlighted) return 1;
    return brightness;
  }, [isGrowing, isForegroundHighlighted, brightness]);

  const containerBoxShadow = normalizedHighlight
    ? `0 0 16px ${highlightGlowPrimary}, 0 0 32px ${highlightGlowSecondary}`
    : isHighlighted
      ? '0 0 8px rgba(255, 255, 255, 0.45)'
      : 'none';

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
        className={`star-container ${isActive ? 'pulse' : ''} ${isSpecial ? 'special twinkle' : ''} ${isHighlighted ? 'highlighted' : ''}`}
        initial={{ opacity: 0, scale: 0 }}
        animate={{ 
          opacity: targetOpacity,
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
          background: normalizedHighlight ? hexToRgba(normalizedHighlight, 0.18) : isHighlighted ? 'transparent' : 'inherit',
          border: normalizedHighlight ? `1px solid ${hexToRgba(normalizedHighlight, 0.6)}` : isHighlighted ? '1px solid rgba(255, 255, 255, 0.35)' : 'none',
          boxShadow: containerBoxShadow,
          transition: 'box-shadow 0.25s ease, border 0.25s ease, transform 0.3s ease, opacity 0.3s ease, background 0.25s ease',
        }}
      >
        {/* 3. 星星核心：实际的星星视觉效果 */}
        <motion.div
          className="star-core"
          style={{
            width: '100%',
            height: '100%',
            background: normalizedHighlight
              ? `radial-gradient(circle, ${hexToRgba(normalizedHighlight, 0.95)} 0%, ${hexToRgba(normalizedHighlight, 0.55)} 55%, ${hexToRgba(normalizedHighlight, 0.15)} 100%)`
              : isHighlighted
                ? 'transparent'
                : 'radial-gradient(circle, rgba(255,255,255,1) 0%, rgba(236,236,255,0.9) 50%, rgba(210,210,255,0.3) 100%)',
            borderRadius: '50%',
            filter: isForegroundHighlighted ? 'blur(0)' : 'blur(1px)',
            boxShadow: normalizedHighlight
              ? `0 0 18px ${hexToRgba(normalizedHighlight, 0.7)}, 0 0 32px ${hexToRgba(normalizedHighlight, 0.4)}`
              : '0 0 8px rgba(255, 255, 255, 0.45)',
            transition: 'box-shadow 0.25s ease, filter 0.25s ease, background 0.25s ease',
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
