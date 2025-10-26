import React, { useState, useEffect, useRef, useMemo } from 'react';
import { motion, useAnimationControls, useMotionValue, PanInfo } from 'framer-motion';
import { createPortal } from 'react-dom';
import { InspirationCard as IInspirationCard } from '../utils/inspirationCards';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import { getBookAnswer, getAnswerReflection } from '../utils/bookOfAnswers';
import ConversationDrawer from './ConversationDrawer';
import StarRayIcon from './StarRayIcon';

interface InspirationCardProps {
  card: IInspirationCard;
  onDismiss: (id: string) => void;
}

const InspirationCard: React.FC<InspirationCardProps> = ({ card, onDismiss }) => {
  const { addStar } = useStarStore();
  const [isFlipped, setIsFlipped] = useState(false);
  const [bookAnswer, setBookAnswer] = useState('');
  const [answerReflection, setAnswerReflection] = useState('');
  const [inputValue, setInputValue] = useState('');
  const [isCardReady, setIsCardReady] = useState(false); // 控制内部动画何时开始
  const [isClosing, setIsClosing] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const cardContainerRef = useRef<HTMLDivElement | null>(null);
  const cardControls = useAnimationControls();
  const overlayControls = useAnimationControls();
  const rotate = useMotionValue(0);
  const hasDraggedRef = useRef(false);
  
  // 预生成固定的星星位置，避免重新渲染时跳变
  const [starPositions] = useState(() => 
    Array.from({ length: 12 }).map((_, i) => ({
      cx: 20 + (i % 4) * 40 + Math.random() * 20,
      cy: 20 + Math.floor(i / 4) * 40 + Math.random() * 20,
      r: Math.random() * 1.5 + 0.5,
      duration: 2 + Math.random() * 2,
      delay: Math.random() * 2
    }))
  );
  
  // 预生成固定的装饰粒子位置
  const [particlePositions] = useState(() => 
    Array.from({ length: 6 }).map(() => ({
      left: `${20 + Math.random() * 60}%`,
      top: `${20 + Math.random() * 60}%`,
      duration: 3 + Math.random() * 2,
      delay: Math.random() * 2
    }))
  );
  
  const spawnMarker = useMemo(() => card.spawnedAt ?? Date.now(), [card.spawnedAt, card.id]);

  useEffect(() => {
    const answer = getBookAnswer();
    const reflection = getAnswerReflection(answer);
    setBookAnswer(answer);
    setAnswerReflection(reflection);
    setInputValue('');
    setIsFlipped(false);
  }, [spawnMarker]);

  useEffect(() => {
    let readyTimer: ReturnType<typeof setTimeout> | null = null;
    setIsClosing(false);
    setIsFlipped(false);
    setIsCardReady(false);
    hasDraggedRef.current = false;

    cardControls.stop();
    overlayControls.stop();
    overlayControls.set({ opacity: 0 });
    cardControls.set({
      opacity: 0,
      scale: 0.9,
      x: 0,
      y: 16,
    });
    rotate.set(0);

    overlayControls.start({
      opacity: 0.6,
      transition: { duration: 0.18, ease: 'easeOut' },
    }).catch(() => {});
    cardControls.start({
      opacity: 1,
      scale: 1,
      x: 0,
      y: 0,
      rotate: 0,
      transition: {
        type: 'spring',
        stiffness: 220,
        damping: 20,
        mass: 0.6,
      },
    }).catch(() => {});

    readyTimer = setTimeout(() => {
      setIsCardReady(true);
    }, 0);

    return () => {
      if (readyTimer) {
        clearTimeout(readyTimer);
      }
    };
  }, [spawnMarker, cardControls, overlayControls, rotate]);
    
  // 移除自动聚焦功能 - 只有用户手动点击输入框时才触发键盘
  // useEffect(() => {
  //   if (isFlipped && inputRef.current) {
  //     setTimeout(() => {
  //       inputRef.current?.focus();
  //     }, 600); // 等待卡片翻转动画完成
  //   }
  // }, [isFlipped]);

  const computeDismissTarget = () => {
    const cardEl = cardContainerRef.current;
    const targetEl = typeof document !== 'undefined'
      ? (document.querySelector('[data-star-collection-trigger]') as HTMLElement | null)
      : null;

    if (cardEl && targetEl) {
      const cardRect = cardEl.getBoundingClientRect();
      const triggerRect = targetEl.getBoundingClientRect();
      const deltaX =
        triggerRect.left + triggerRect.width / 2 - (cardRect.left + cardRect.width / 2);
      const deltaY =
        triggerRect.top + triggerRect.height / 2 - (cardRect.top + cardRect.height / 2);
      return { x: deltaX, y: deltaY };
    }

    const fallbackWidth = typeof window !== 'undefined' ? window.innerWidth : 0;
    const fallbackHeight = typeof window !== 'undefined' ? window.innerHeight : 0;
    return {
      x: fallbackWidth * 0.35,
      y: -fallbackHeight * 0.3,
    };
  };

  const handleDismiss = async () => {
    if (isClosing) return;
    setIsClosing(true);
    playSound('starClick');
    overlayControls.start({ opacity: 0, transition: { duration: 0.24, ease: 'easeIn' } }).catch(() => {});
    const target = computeDismissTarget();
    try {
      await cardControls.start({
        x: target.x,
        y: target.y,
        scale: 0.35,
        rotate: -12,
        opacity: 0,
        transition: {
          type: 'spring',
          stiffness: 260,
          damping: 26,
          restDelta: 0.5,
          restSpeed: 0.5,
        },
      });
    } finally {
      onDismiss(card.id);
    }
  };

  const computeLeftDismissTarget = () => {
    const cardRect = cardContainerRef.current?.getBoundingClientRect();
    const width = typeof window !== 'undefined' ? window.innerWidth : 0;
    const offscreenX = -((width || 0) + (cardRect?.width ?? 320) * 1.1);
    const lift = cardRect ? -Math.min(cardRect.height * 0.18, 120) : -90;
    return { x: offscreenX, y: lift };
  };

  const computeRightDismissTarget = () => {
    const cardRect = cardContainerRef.current?.getBoundingClientRect();
    const width = typeof window !== 'undefined' ? window.innerWidth : 0;
    const offscreenX = (width || 0) + (cardRect?.width ?? 320) * 1.1;
    const lift = cardRect ? -Math.min(cardRect.height * 0.16, 110) : -80;
    return { x: offscreenX, y: lift };
  };

  const handleLinearSwipeDismiss = async (direction: 'left' | 'right', velocityX: number) => {
    if (isClosing) return;
    setIsClosing(true);
    playSound('starClick');
    const target =
      direction === 'left' ? computeLeftDismissTarget() : computeRightDismissTarget();
    overlayControls.start({ opacity: 0, transition: { duration: 0.24, ease: 'easeIn' } }).catch(() => {});
    rotate.set(direction === 'left' ? -14 : 14);
    try {
      await cardControls.start({
        x: target.x,
        y: target.y,
        rotate: direction === 'left' ? -18 : 18,
        transition: direction === 'left'
          ? {
              type: 'spring',
              stiffness: 150,
              damping: 18,
              velocity: Math.max(velocityX / 75, -10),
            }
          : {
              type: 'spring',
              stiffness: 160,
              damping: 18,
              velocity: Math.min(Math.max(velocityX / 70, -10), 12),
            },
      });
      if (direction === 'left') {
        rotate.set(-20);
        await cardControls.start({
          x: target.x - 160,
          transition: {
            type: 'tween',
            duration: 0.18,
            ease: [0.05, 0.8, 0.2, 1],
          },
        });
      } else {
        rotate.set(22);
        await cardControls.start({
          x: target.x + 160,
          transition: {
            type: 'tween',
            duration: 0.18,
            ease: [0.05, 0.8, 0.2, 1],
          },
        });
      }
    } finally {
      onDismiss(card.id);
    }
  };

  const toggleCardFlip = (target?: boolean) => {
    setIsFlipped(prev => {
      const next = typeof target === 'boolean' ? target : !prev;
      console.log('[InspirationCard] toggleCardFlip', { prev, next, target });
      if (prev !== next) {
        playSound('starClick');
      }
      return next;
    });
  };

  const handleCardClick = () => {
    if (isClosing || hasDraggedRef.current) {
      hasDraggedRef.current = false;
      return;
    }
    console.log('[InspirationCard] card wrapper clicked');
    toggleCardFlip();
  };

  const handleFlipBack = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (isClosing || hasDraggedRef.current) {
      hasDraggedRef.current = false;
      return;
    }
    console.log('[InspirationCard] flip back button clicked');
    toggleCardFlip(false);
  };
  
  const handleSendMessage = () => {
    if (inputValue.trim()) {
      // 这里可以处理发送消息的逻辑
      console.log("发送消息:", inputValue);
      // 示例：创建一个新的星星
      addStar(inputValue);
      setInputValue('');
      playSound('starClick');
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  // 为卡片生成稳定的唯一ID，用于渐变效果
  const cardId = useMemo(() => `insp-${spawnMarker}`, [spawnMarker]);

  return createPortal(
    <motion.div
      className="fixed inset-0 flex items-center justify-center"
      style={{ zIndex: 999999, pointerEvents: isClosing ? 'none' : 'auto' }}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      <motion.div
        className="absolute inset-0 bg-black"
        initial={{ opacity: 0 }}
        animate={overlayControls}
        exit={{ opacity: 0 }}
        onClick={handleDismiss}
      />

      <motion.div
        ref={cardContainerRef}
        className="star-card-container"
        initial={{ opacity: 0, scale: 0.9, y: 16 }}
        animate={cardControls}
        exit={{ opacity: 0, scale: 0.9 }}
        style={{ rotate }}
        drag={isClosing ? false : 'x'}
        dragConstraints={{ left: 0, right: 0 }}
        dragElastic={0.28}
        onDragStart={() => {
          if (isClosing) return;
          hasDraggedRef.current = false;
          cardControls.stop();
          rotate.set(0);
        }}
        onDrag={(event, info) => {
          if (isClosing) return;
          if (Math.abs(info.offset.x) > 4) {
            hasDraggedRef.current = true;
          }
          const limited = Math.max(Math.min(info.offset.x / 10, 18), -18);
          rotate.set(limited);
        }}
        onDragEnd={(event, info: PanInfo) => {
          if (isClosing) return;
          const { offset, velocity } = info;
          rotate.set(0);
          const shouldDismiss =
            offset.x < -140 || velocity.x < -900 || offset.x > 140 || velocity.x > 900;
          if (shouldDismiss) {
            handleLinearSwipeDismiss(offset.x > 0 || velocity.x > 0 ? 'right' : 'left', velocity.x);
            return;
          }
          hasDraggedRef.current = false;
          cardControls.start({
            x: 0,
            y: 0,
            rotate: 0,
            transition: {
              type: 'spring',
              stiffness: 320,
              damping: 28,
            },
          });
        }}
      >
        <div
          className="star-card-wrapper"
          onClick={(e) => {
            e.stopPropagation();
            console.log('[InspirationCard] wrapper clicked');
            toggleCardFlip();
          }}
          onPointerDown={(e) => {
            console.log('[InspirationCard] wrapper pointer down');
            e.stopPropagation();
          }}
        >
          <motion.div
            className={`star-card ${isFlipped ? 'is-flipped' : ''}`}
            animate={{ rotateY: isFlipped ? 180 : 0 }}
            transition={{ duration: 0.6, type: "spring" }}
          >
            {/* Front Side - Card Design */}
            <div
              className="star-card-face star-card-front"
              onClick={(e) => {
                e.stopPropagation();
                console.log('[InspirationCard] front face clicked');
                toggleCardFlip(true);
              }}
              onPointerDown={(e) => {
                console.log('[InspirationCard] front face pointer down');
                e.stopPropagation();
              }}
            >
              <div className="star-card-bg">
                <div className="star-card-constellation">
                  {/* Star pattern */}
                  <svg className="constellation-svg" viewBox="0 0 200 200">
              <defs>
                      <radialGradient id={`starGlow-${cardId}`} cx="50%" cy="50%" r="50%">
                        <stop offset="0%" stopColor="#ffffff" stopOpacity="0.8"/>
                        <stop offset="100%" stopColor="#ffffff" stopOpacity="0"/>
                </radialGradient>
              </defs>
              
              {/* Background stars */}
                    {starPositions.map((star, i) => (
                <motion.circle
                  key={i}
                        cx={star.cx}
                        cy={star.cy}
                  r={star.r}
                  fill="rgba(255,255,255,0.6)"
                  initial={{ opacity: 0 }}
                  animate={isCardReady ? {
                    opacity: [0.3, 0.8, 0.3]
                  } : {
                    opacity: 0
                  }}
                  transition={{
                    duration: Math.max(1.2, star.duration * 0.75),
                    repeat: isCardReady ? Infinity : 0,
                    delay: isCardReady ? 1.4 + star.delay * 0.6 : 0
                  }}
                />
              ))}
              
                    {/* Main star */}
                    <motion.circle
                      cx="100"
                cy="100"
                      r="8"
                      fill={`url(#starGlow-${cardId})`}
                      initial={{ scale: 0 }}
                      animate={isCardReady ? { scale: 1 } : { scale: 0 }}
                      transition={{ delay: isCardReady ? 0.1 : 0, type: "spring", damping: 15 }}
                    />
                    
                    {/* Star rays - 使用星星动画阶段的动画效果 */}
                    {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => (
                      <motion.line
                        key={i}
                        x1="100"
                        y1="100"
                        x2={100 + Math.cos(i * Math.PI / 4) * 40}
                        y2={100 + Math.sin(i * Math.PI / 4) * 40}
                        stroke="#ffffff"
                        strokeWidth="2"
                        initial={{ pathLength: 0, opacity: 0 }}
                        animate={isCardReady ? {
                          pathLength: 1,
                          opacity: [0, 0.8, 0]
                        } : {
                          pathLength: 0,
                          opacity: 0
                        }}
                        transition={{
                          duration: 1.1,
                          delay: isCardReady ? i * 0.08 : 0,
                          repeat: isCardReady ? Infinity : 0,
                          repeatDelay: isCardReady ? 0.8 : 0
                        }}
              />
                    ))}
            </svg>
          </div>

                <motion.div
                  className="card-prompt"
                  initial={{ opacity: 0, y: 20 }}
                  animate={isCardReady ? {
                    opacity: 0.7,
                    y: 0
                  } : {
                    opacity: 0,
                    y: 20
                  }}
                  transition={{ 
                    delay: isCardReady ? 0.35 : 0,
                    duration: 0.25
                  }}
                >
                  <p className="text-center text-base text-neutral-300 font-normal">
                    翻开卡片，宇宙会回答你
                  </p>
                </motion.div>

                {/* Decorative elements */}
                <div className="star-card-decorations">
                  {particlePositions.map((particle, i) => (
            <motion.div
              key={i}
              className="floating-particle"
              style={{
                left: particle.left,
                top: particle.top,
              }}
              initial={{ y: 0, opacity: 0.3 }}
              animate={isCardReady ? {
                y: [-5, 5, -5],
                opacity: [0.3, 0.7, 0.3]
              } : {
                y: 0,
                opacity: 0
              }}
              transition={{
                duration: particle.duration,
                repeat: isCardReady ? Infinity : 0,
                delay: isCardReady ? 2.0 + particle.delay : 0
              }}
            />
          ))}
                </div>
              </div>
            </div>

            {/* Back Side - Book of Answers */}
            <div
              className="star-card-face star-card-back"
              onClick={(e) => {
                e.stopPropagation();
                console.log('[InspirationCard] back face clicked');
                toggleCardFlip(false);
              }}
              onPointerDown={(e) => {
                console.log('[InspirationCard] back face pointer down');
                e.stopPropagation();
              }}
            >
              <div className="star-card-content flex flex-col h-full">
                {/* 标题与返回按钮 */}
                <div className="flex items-center justify-between mb-6 px-1">
                  <motion.div
                    className="flex-1"
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.2 }}
                  >
                    <h3 className="answer-label text-xl font-semibold text-cosmic-accent text-center">来自宇宙的答案</h3>
                  </motion.div>
                  <motion.button
                    className="text-xs px-3 py-1 rounded-full border border-white/20 text-white/80 hover:text-white hover:border-white/40 transition-colors ml-3"
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.35 }}
                    onClick={handleFlipBack}
                  >
                    返回正面
                  </motion.button>
                </div>

                {/* 答案部分 - 居中显示 */}
                <div className="answer-section flex-grow flex items-center justify-center px-6">
                  <motion.div
                    className="answer-reveal text-center"
                    initial={{ opacity: 0, scale: 0.9 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: 0.4, type: "spring", damping: 20 }}
                  >
                    <p className="answer-text text-3xl font-bold text-white mb-2 drop-shadow-[0_0_8px_rgba(255,255,255,0.3)]">{bookAnswer}</p>
                  </motion.div>
                </div>
                
                {/* 附言部分 - 放在底部，进一步降低视觉重要性 */}
                <motion.div
                  className="reflection-section mt-auto mb-3 px-4"
                  initial={{ opacity: 0 }}
                  animate={{ 
                    opacity: 1 
                  }}
                  transition={{ delay: 0.6 }}
                >
                  <p className="reflection-text text-[9px] text-neutral-400 italic text-center leading-tight tracking-wide">{answerReflection}</p>
                </motion.div>
                
                {/* 抽屉式输入框 - 直接显示，无需点击按钮 */}
                <motion.div
                  className="card-footer"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.7 }}
                >
                  <motion.div 
                    className="input-ghost-wrapper w-full"
                    initial={{ y: 20, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    transition={{ type: "spring", damping: 20, delay: 0.7 }}
                  >
                    <div className="flex items-center gap-3 relative py-2 px-1">
                      <input
                        ref={inputRef}
                        type="text"
                        className="flex-1 bg-transparent text-white placeholder-neutral-400 outline-none text-sm leading-relaxed border-0 border-b border-neutral-600/50 focus:border-cosmic-accent transition-colors duration-300"
                        placeholder="说说你的困惑吧"
                        value={inputValue}
                        onChange={(e) => setInputValue(e.target.value)}
                        onKeyPress={handleKeyPress}
                        onClick={(e) => e.stopPropagation()} // 只有输入框本身阻止传播
                      />
                      <motion.button
                        className={`w-7 h-7 rounded-full flex items-center justify-center transition-colors ${
                          inputValue.trim() ? 'bg-cosmic-accent/80 text-white' : 'bg-transparent text-neutral-400'
                        }`}
                        onClick={(e) => {
                          e.stopPropagation(); // 只有按钮本身阻止传播
                          handleSendMessage();
                        }}
                        disabled={!inputValue.trim()}
                        whileHover={inputValue.trim() ? { scale: 1.1 } : {}}
                        whileTap={inputValue.trim() ? { scale: 0.95 } : {}}
                      >
                        <StarRayIcon size={14} animated={!!inputValue.trim()} />
                      </motion.button>
                    </div>
                  </motion.div>
                </motion.div>
              </div>
            </div>
          </motion.div>
          
          {/* Hover glow effect */}
          <motion.div
            className="star-card-glow"
            animate={{
              opacity: 0.4,
              scale: 1.05,
            }}
            transition={{ duration: 0.3 }}
          />
        </div>
      </motion.div>
    </motion.div>,
    document.body
  );
};

export default InspirationCard;
