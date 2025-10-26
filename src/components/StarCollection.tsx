import React, { useState, useMemo, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { createPortal } from 'react-dom';
import { X, Search, Filter, Star as StarIcon } from 'lucide-react';
import { useStarStore } from '../store/useStarStore';
import { Capacitor } from '@capacitor/core';
import { InputDrawer } from '@/plugins/InputDrawer';
import { playSound } from '../utils/soundUtils';
import { getMobileModalStyles, getMobileModalClasses, fixIOSZIndex, createTopLevelContainer, hideOtherElements } from '../utils/mobileUtils';
import StarCard from './StarCard';

// 星星样式类型 - 与StarCard组件中的定义保持一致
const STAR_STYLES = {
  STANDARD: 'standard', // 标准8条光芒
  CROSS: 'cross',       // 十字形
  BURST: 'burst',       // 爆发式
  SPARKLE: 'sparkle',   // 闪烁式
  RINGED: 'ringed',     // 带环星
  // 行星样式
  PLANET_SMOOTH: 'planet_smooth',   // 平滑行星
  PLANET_CRATERS: 'planet_craters', // 陨石坑行星
  PLANET_SEAS: 'planet_seas',       // 海洋行星
  PLANET_DUST: 'planet_dust',       // 尘埃行星
  PLANET_RINGS: 'planet_rings'      // 带环行星
};

interface StarCollectionProps {
  isOpen: boolean;
  onClose: () => void;
}

const StarCollection: React.FC<StarCollectionProps> = ({ isOpen, onClose }) => {
  const { constellation, drawInspirationCard } = useStarStore();
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState<'all' | 'special' | 'recent'>('all');
  const [flippedCards, setFlippedCards] = useState<Set<string>>(new Set());
  const [restoreElements, setRestoreElements] = useState<(() => void) | null>(null);

  // 初始化iOS层级修复
  useEffect(() => {
    fixIOSZIndex();
  }, []);

  useEffect(() => {
    if (!Capacitor.isNativePlatform()) return;
    const toggle = async () => {
      try {
        if (isOpen) {
          await InputDrawer.hide({ animated: false });
        } else {
          await InputDrawer.show({ animated: true });
        }
      } catch (error) {
        console.warn('[StarCollection] 切换 InputDrawer 失败:', error);
      }
    };
    toggle();
  }, [isOpen]);

  // 当模态框打开时隐藏其他元素
  useEffect(() => {
    if (isOpen) {
      document.body.classList.add('modal-open');
      const restore = hideOtherElements();
      setRestoreElements(() => restore);
    } else {
      document.body.classList.remove('modal-open');
      if (restoreElements) {
        restoreElements();
        setRestoreElements(null);
      }
    }
    
    return () => {
      document.body.classList.remove('modal-open');
      if (restoreElements) {
        restoreElements();
      }
    };
  }, [isOpen]);

  // 为每个星星生成样式映射
  const resolveSeed = (star: typeof constellation.stars[number]) => {
    const parts = star.id.split('-').filter(Boolean);
    for (const part of parts) {
      const numeric = Number(part);
      if (Number.isFinite(numeric)) {
        return numeric;
      }
    }
    const createdAt = star.createdAt instanceof Date ? star.createdAt : new Date(star.createdAt);
    return createdAt.getTime() || Date.now();
  };

  const starStyleMap = useMemo(() => {
    const map = new Map();
    constellation.stars.forEach(star => {
      const seed = resolveSeed(star);
      const seedRandom = (min: number, max: number) => {
        const x = Math.sin(seed) * 10000;
        const r = x - Math.floor(x);
        return Math.floor(r * (max - min + 1)) + min;
      };
      
      // 获取所有可能的样式
      const allStyles = Object.values(STAR_STYLES);
      // 随机选择样式和颜色主题
      const styleIndex = seedRandom(0, allStyles.length - 1);
      const colorTheme = seedRandom(0, 3);
      
      map.set(star.id, {
        style: allStyles[styleIndex],
        theme: colorTheme
      });
    });
    return map;
  }, [constellation.stars]);

  const handleClose = () => {
    playSound('starClick');
    onClose();
  };

  const handleCardFlip = (starId: string) => {
    console.log('[StarCollection] handleCardFlip', starId, 'currently flipped:', flippedCards.has(starId));
    playSound('starClick');
    setFlippedCards(prev => {
      const next = new Set(prev);
      if (next.has(starId)) {
        next.delete(starId);
      } else {
        next.add(starId);
      }
      return next;
    });
  };

  // 处理右键点击，显示灵感卡片
  const handleContextMenu = (e: React.MouseEvent) => {
    e.preventDefault();
    playSound('starReveal');
    const card = drawInspirationCard();
    console.log('📇 灵感卡片已生成:', card.question);
  };

  // Filter stars based on search and filter criteria
  const filteredStars = constellation.stars.filter(star => {
    const matchesSearch = star.question.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         star.answer.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesFilter = filterType === 'all' || 
                         (filterType === 'special' && star.isSpecial) ||
                         (filterType === 'recent' && 
                          (Date.now() - star.createdAt.getTime()) < 7 * 24 * 60 * 60 * 1000);
    
    return matchesSearch && matchesFilter;
  });

  return createPortal(
    <AnimatePresence>
      {isOpen && (
        <motion.div
          className={getMobileModalClasses()}
          style={getMobileModalStyles()}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onContextMenu={handleContextMenu}
        >
          {/* Backdrop */}
          <motion.div
            className="absolute inset-0 bg-black bg-opacity-90 backdrop-blur-md"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={handleClose}
          />

          {/* Collection Panel */}
          <motion.div
            className="star-collection-panel"
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            transition={{ type: 'spring', damping: 25 }}
          >
            {/* Header */}
            <div className="collection-header">
              <div className="header-left">
                {/* English: Star Collection - for future internationalization */}
                <h2 className="stellar-title text-white">集星</h2>
                <span className="star-count">{filteredStars.length} stars</span>
              </div>
              
              <button
                className="p-2 rounded-full dialog-transparent-button transition-colors duration-200"
                onClick={handleClose}
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Controls */}
            <div className="collection-controls">
              <div className="search-bar">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search your stars..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="stellar-body w-full bg-transparent text-white placeholder-gray-400 pl-10 pr-4 py-2 focus:outline-none"
                />
              </div>
              
              <div className="control-buttons">
                <select
                  value={filterType}
                  onChange={(e) => setFilterType(e.target.value as any)}
                  className="stellar-body bg-transparent text-white focus:outline-none p-2 rounded-full dialog-transparent-button"
                >
                  <option value="all">All Stars</option>
                  <option value="special">Special Stars</option>
                  <option value="recent">Recent (7 days)</option>
                </select>
              </div>
            </div>

            {/* Star Cards */}
            <div className="collection-content grid">
              <AnimatePresence>
                {filteredStars.map((star, index) => {
                  const styleConfig = starStyleMap.get(star.id) || { style: 'standard', theme: 0 };
                  return (
                    <motion.div
                      key={star.id}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -20 }}
                      transition={{ delay: index * 0.1 }}
                    >
                      <StarCard
                        star={star}
                        isFlipped={flippedCards.has(star.id)}
                        onFlip={() => handleCardFlip(star.id)}
                        starStyle={styleConfig.style}
                        colorTheme={styleConfig.theme}
                        onContextMenu={handleContextMenu}
                      />
                    </motion.div>
                  );
                })}
              </AnimatePresence>
              
              {filteredStars.length === 0 && (
                <motion.div
                  className="empty-state"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                >
                  <StarIcon className="w-12 h-12 text-gray-400 mb-4" />
                  <p className="text-gray-400">No stars found matching your criteria</p>
                </motion.div>
              )}
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>,
    createTopLevelContainer()
  );
};

export default StarCollection;
