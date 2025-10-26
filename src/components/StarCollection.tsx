import React, { 
  useState, 
  useMemo, 
  useEffect, 
  useDeferredValue, 
  useRef
} from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { createPortal } from 'react-dom';
import { X, Search, Filter, Star as StarIcon } from 'lucide-react';
import { useStarStore } from '../store/useStarStore';
import { Capacitor } from '@capacitor/core';
import { InputDrawer } from '@/plugins/InputDrawer';
import { playSound } from '../utils/soundUtils';
import { getMobileModalStyles, getMobileModalClasses, fixIOSZIndex, createTopLevelContainer, hideOtherElements } from '../utils/mobileUtils';
import StarCard from './StarCard';
import { Star } from '../types';
import { useShallow } from 'zustand/react/shallow';

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

const INITIAL_VISIBLE_COUNT = 18;
const BATCH_SIZE = 12;

type IdleHandle = number | ReturnType<typeof setTimeout>;
const scheduleIdleTask = (cb: () => void): IdleHandle => {
  if (typeof window !== 'undefined') {
    const win = window as typeof window & {
      requestIdleCallback?: (callback: () => void, options?: { timeout: number }) => number;
    };
    if (typeof win.requestIdleCallback === 'function') {
      return win.requestIdleCallback(cb, { timeout: 120 });
    }
    return window.setTimeout(cb, 16);
  }
  return setTimeout(cb, 16);
};

const cancelIdleTask = (handle: IdleHandle) => {
  if (typeof window !== 'undefined') {
    const win = window as typeof window & {
      cancelIdleCallback?: (handle: IdleHandle) => void;
    };
    if (typeof win.cancelIdleCallback === 'function') {
      win.cancelIdleCallback(handle);
      return;
    }
  }
  clearTimeout(handle as ReturnType<typeof setTimeout>);
};

interface StarCollectionProps {
  isOpen: boolean;
  onClose: () => void;
}

const StarCollection: React.FC<StarCollectionProps> = ({ isOpen, onClose }) => {
  const { constellationStars, inspirationStars, drawInspirationCard } = useStarStore(
    useShallow(state => ({
      constellationStars: state.constellation.stars,
      inspirationStars: state.inspirationStars,
      drawInspirationCard: state.drawInspirationCard,
    }))
  );
  const [searchInput, setSearchInput] = useState('');
  const deferredSearchTerm = useDeferredValue(searchInput);
  const [filterType, setFilterType] = useState<'all' | 'special' | 'recent'>('all');
  const [flippedCards, setFlippedCards] = useState<Set<string>>(new Set());
  const [restoreElements, setRestoreElements] = useState<(() => void) | null>(null);
  const [visibleCount, setVisibleCount] = useState(INITIAL_VISIBLE_COUNT);
  const loadFrameRef = useRef<number | null>(null);
  const readyCardIdsRef = useRef<Set<string>>(new Set());
  const [, forceReadyRender] = useState(0);

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

  const getCreatedAtDate = (star: Star) => (
    star.createdAt instanceof Date ? star.createdAt : new Date(star.createdAt)
  );

  const resolveSeed = (star: Star) => {
    const parts = star.id.split('-').filter(Boolean);
    for (const part of parts) {
      const numeric = Number(part);
      if (Number.isFinite(numeric)) {
        return numeric;
      }
    }
    const createdAt = getCreatedAtDate(star);
    return createdAt.getTime() || Date.now();
  };

  const mergedStars = useMemo(() => {
    const unique = new Map<string, Star>();
    [...inspirationStars, ...constellationStars].forEach(star => {
      unique.set(star.id, star);
    });
    return Array.from(unique.values()).sort(
      (a, b) => getCreatedAtDate(b).getTime() - getCreatedAtDate(a).getTime()
    );
  }, [constellationStars, inspirationStars]);

  const resolvedStars = useMemo(
    () => (isOpen ? mergedStars : []),
    [isOpen, mergedStars]
  );

  const starStyleMap = useMemo(() => {
    const map = new Map<string, { style: string; theme: number }>();
    resolvedStars.forEach(star => {
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
  }, [resolvedStars]);
  const fallbackStyleConfig = useMemo(() => ({ style: 'standard', theme: 0 }), []);

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

  const filteredStars = useMemo(() => {
    if (!resolvedStars.length) return [];
    const searchText = deferredSearchTerm.trim().toLowerCase();
    const recentThreshold = Date.now() - 7 * 24 * 60 * 60 * 1000;
    
    return resolvedStars.filter(star => {
      const matchesFilter =
        filterType === 'all' ||
        (filterType === 'special' && star.isSpecial) ||
        (filterType === 'recent' && getCreatedAtDate(star).getTime() >= recentThreshold);

      if (!matchesFilter) return false;
      if (!searchText) return true;

      const question = star.question?.toLowerCase?.() ?? '';
      const answer = star.answer?.toLowerCase?.() ?? '';
      return question.includes(searchText) || answer.includes(searchText);
    });
  }, [resolvedStars, filterType, deferredSearchTerm]);

  const totalStarCount = constellationStars.length + inspirationStars.length;
  const isStarListLoading = isOpen && mergedStars.length > 0 && resolvedStars.length === 0;

  // 初始化或过滤时重置可见数量
  useEffect(() => {
    if (!isOpen) return;
    setVisibleCount(Math.min(INITIAL_VISIBLE_COUNT, filteredStars.length));
    return () => {
      if (loadFrameRef.current) {
        cancelAnimationFrame(loadFrameRef.current);
        loadFrameRef.current = null;
      }
    };
  }, [filteredStars.length, isOpen]);

  // 平滑提升可见卡片数量，避免初次渲染压力
  useEffect(() => {
    if (!isOpen) return;
    if (filteredStars.length <= INITIAL_VISIBLE_COUNT) return;

    let cancelled = false;

    const step = () => {
      loadFrameRef.current = requestAnimationFrame(() => {
        if (cancelled) return;
        let shouldContinue = false;
        setVisibleCount(prev => {
          if (prev >= filteredStars.length) {
            shouldContinue = false;
            return prev;
          }
          const next = Math.min(filteredStars.length, prev + BATCH_SIZE);
          shouldContinue = next < filteredStars.length;
          return next;
        });
        if (!cancelled && shouldContinue) {
          step();
        }
      });
    };

    step();

    return () => {
      cancelled = true;
      if (loadFrameRef.current) {
        cancelAnimationFrame(loadFrameRef.current);
        loadFrameRef.current = null;
      }
    };
  }, [filteredStars.length, isOpen]);

  const visibleStars = filteredStars.slice(0, visibleCount || INITIAL_VISIBLE_COUNT);

  useEffect(() => {
    if (isOpen) return;
    readyCardIdsRef.current = new Set();
    forceReadyRender(v => v + 1);
  }, [isOpen, forceReadyRender]);

  useEffect(() => {
    if (!isOpen) return;
    if (!visibleStars.length) return;

    let cancelled = false;
    const handles: IdleHandle[] = [];

    const schedule = (index: number) => {
      if (cancelled || index >= visibleStars.length) return;
      const star = visibleStars[index];
      if (readyCardIdsRef.current.has(star.id)) {
        schedule(index + 1);
        return;
      }
      const handle = scheduleIdleTask(() => {
        if (cancelled) return;
        if (!readyCardIdsRef.current.has(star.id)) {
          readyCardIdsRef.current.add(star.id);
          forceReadyRender(v => v + 1);
        }
        schedule(index + 1);
      });
      handles.push(handle);
    };

    schedule(0);

    return () => {
      cancelled = true;
      handles.forEach(cancelIdleTask);
    };
  }, [visibleStars, isOpen, forceReadyRender]);

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
                  value={searchInput}
                  onChange={(e) => setSearchInput(e.target.value)}
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
              {isStarListLoading && (
                <motion.div
                  className="w-full text-center text-gray-300 py-8"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                >
                  正在唤醒你的星卡...
                </motion.div>
              )}

              <AnimatePresence>
                {visibleStars.map((star, index) => {
                  const styleConfig = starStyleMap.get(star.id) || fallbackStyleConfig;
                  const ready = readyCardIdsRef.current.has(star.id);
                  return (
                    <motion.div
                      key={star.id}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -20 }}
                      transition={{ delay: Math.min(index, 6) * 0.05 }}
                    >
                      <StarCard
                        star={star}
                        isFlipped={flippedCards.has(star.id)}
                        onFlip={() => handleCardFlip(star.id)}
                        starStyle={styleConfig.style}
                        colorTheme={styleConfig.theme}
                        onContextMenu={handleContextMenu}
                        isLoading={!ready}
                      />
                    </motion.div>
                  );
                })}
              </AnimatePresence>
              
              {filteredStars.length === 0 && !isStarListLoading && (
                <motion.div
                  className="empty-state"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                >
                  <StarIcon className="w-12 h-12 text-gray-400 mb-4" />
                  <p className="text-gray-400">No stars found matching your criteria</p>
                </motion.div>
              )}

              {/* 底部加载指示 */}
              {!isStarListLoading && visibleStars.length < filteredStars.length && (
                <div className="w-full text-center text-gray-400 text-sm py-4 opacity-70">
                  正在载入更多星卡...
                </div>
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
