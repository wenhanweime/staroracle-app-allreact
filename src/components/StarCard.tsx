import React, { useMemo, useState } from 'react';
import { motion } from 'framer-motion';
import { Calendar, Heart } from 'lucide-react';
import PixelPlanetCanvas from './PixelPlanetCanvas';
import { Star as IStar } from '../types';
import { playSound } from '../utils/soundUtils';

interface StarCardProps {
  star: IStar;
  isFlipped?: boolean;
  onFlip?: () => void;
  showActions?: boolean;
  starStyle?: string;
  colorTheme?: number;
  onContextMenu?: (e: React.MouseEvent) => void;
}

type PixelTheme = {
  name: string;
  frame: string;
  background: string;
  border: string;
  accent: string;
  text: string;
};

const PIXEL_THEMES: PixelTheme[] = [
  {
    name: '银河紫',
    frame: '#231136',
    background: '#120720',
    border: '#f07dea',
    accent: '#ffa9ff',
    text: '#f7f2ff',
  },
  {
    name: '晨曦蓝',
    frame: '#0f1f38',
    background: '#060a17',
    border: '#6dd6ff',
    accent: '#aef1ff',
    text: '#dff7ff',
  },
  {
    name: '熔岩橙',
    frame: '#2d1208',
    background: '#150603',
    border: '#ff975a',
    accent: '#ffc38a',
    text: '#ffe7cc',
  },
  {
    name: '霜雪青',
    frame: '#102330',
    background: '#040b11',
    border: '#7dd1ff',
    accent: '#c6f3ff',
    text: '#e4feff',
  },
];

const extractSeed = (star: IStar) => {
  if (!star.id) return 1;
  const parts = star.id.split('-');
  if (parts[1]) {
    const parsed = parseInt(parts[1], 10);
    if (!Number.isNaN(parsed)) return Math.abs(parsed) || 1;
  }
  const numeric = parseInt(star.id.replace(/\D/g, ''), 10);
  if (!Number.isNaN(numeric)) return Math.abs(numeric) || 1;
  let hash = 0;
  for (let i = 0; i < star.id.length; i += 1) {
    hash = (hash * 31 + star.id.charCodeAt(i)) >>> 0;
  }
  return hash || 1;
};

const shorten = (text: string, max = 48) => {
  if (!text) return '';
  if (text.length <= max) return text;
  return `${text.slice(0, max)}…`;
};

const StarCard: React.FC<StarCardProps> = ({
  star,
  isFlipped = false,
  onFlip,
  showActions = true,
  colorTheme,
  onContextMenu,
}) => {
  const [hovered, setHovered] = useState(false);
  const seed = useMemo(() => extractSeed(star), [star.id]);

  const theme = useMemo(() => {
    if (typeof colorTheme === 'number' && PIXEL_THEMES[colorTheme]) {
      return PIXEL_THEMES[colorTheme];
    }
    const index = seed % PIXEL_THEMES.length;
    return PIXEL_THEMES[index];
  }, [seed, colorTheme]);

  const questionPreview = useMemo(() => shorten(star.question, 64), [star.question]);
  const answerText = star.answer || '星辰尚未低语答案。';

  const handleFlip = (e?: React.MouseEvent) => {
    e?.stopPropagation();
    playSound('starClick');
    onFlip?.();
  };

  const handleContextMenu = (e: React.MouseEvent) => {
    onContextMenu?.(e);
  };

  return (
    <motion.div
      className="pixel-star-card-container"
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      whileHover={{ y: -4 }}
      onHoverStart={() => setHovered(true)}
      onHoverEnd={() => setHovered(false)}
      onContextMenu={handleContextMenu}
    >
      <motion.div
        className={`pixel-star-card ${isFlipped ? 'is-flipped' : ''}`}
        style={{
          background: theme.background,
          borderColor: theme.border,
        }}
        animate={{ rotateY: isFlipped ? 180 : 0 }}
        transition={{ duration: 0.5, ease: [0.26, 0.8, 0.32, 1] }}
        onClick={handleFlip}
      >
        <div className="pixel-card-face pixel-card-front">
          <div className="pixel-card-frame" style={{ background: theme.frame }}>
            <div className="pixel-card-frame-inner" />
            <PixelPlanetCanvas seed={seed} size={188} />
            <div className="pixel-card-scanlines" />
          </div>

          <div className="pixel-card-meta">
            <div className="pixel-card-tag" style={{ color: theme.accent, borderColor: theme.accent }}>
              #{theme.name}
            </div>
            <div className="pixel-card-question" style={{ color: theme.text }}>
              “{questionPreview}”
            </div>
            <div className="pixel-card-footer" style={{ color: `${theme.text}cc` }}>
              <span className="pixel-card-id">{star.id}</span>
              <span className="pixel-card-date">
                <Calendar className="w-3 h-3" />
                {star.createdAt.toLocaleDateString()}
              </span>
            </div>
          </div>
        </div>

        <div className="pixel-card-face pixel-card-back">
          <div className="pixel-card-back-frame" style={{ borderColor: theme.border }}>
            <div className="pixel-card-back-title" style={{ color: theme.accent }}>
              星辰启示
            </div>

            <div className="pixel-card-back-body" style={{ color: theme.text }}>
              <p className="pixel-card-back-question">Q: {star.question}</p>
              <div className="pixel-card-back-answer">
                <span className="pixel-card-back-label">A:</span>
                <p>{answerText}</p>
              </div>
            </div>

            <div className="pixel-card-back-hint" style={{ color: `${theme.accent}cc` }}>
              点击卡片返回，继续星际旅程
            </div>
          </div>
        </div>
      </motion.div>

      {showActions && (
        <motion.div
          className="pixel-card-actions"
          initial={{ opacity: 0 }}
          animate={{ opacity: hovered ? 1 : 0 }}
        >
          <button
            className="pixel-card-action"
            style={{ borderColor: theme.accent, color: theme.text }}
            onClick={(e) => {
              e.stopPropagation();
              playSound('starClick');
            }}
          >
            <Heart className="w-4 h-4" />
          </button>
          <button
            className="pixel-card-action"
            style={{ borderColor: theme.accent, color: theme.text }}
            onClick={(e) => {
              e.stopPropagation();
              handleFlip();
            }}
          >
            翻转
          </button>
        </motion.div>
      )}
    </motion.div>
  );
};

export default StarCard;
