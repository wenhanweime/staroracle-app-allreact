import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { createPortal } from 'react-dom';
import { Sparkles, MessageCircle } from 'lucide-react';
import { InspirationCard as IInspirationCard } from '../utils/inspirationCards';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import { getBookAnswer, getAnswerReflection } from '../utils/bookOfAnswers';
import ConversationDrawer from './ConversationDrawer';
import StarRayIcon from './StarRayIcon';

interface InspirationCardProps {
  card: IInspirationCard;
  onDismiss: () => void;
}

const InspirationCard: React.FC<InspirationCardProps> = ({ card, onDismiss }) => {
  const { addStar } = useStarStore();
  const [isFlipped, setIsFlipped] = useState(false);
  const [bookAnswer, setBookAnswer] = useState('');
  const [answerReflection, setAnswerReflection] = useState('');
  const [inputValue, setInputValue] = useState('');
  const [isCardReady, setIsCardReady] = useState(false); // 控制内部动画何时开始
  const inputRef = useRef<HTMLInputElement>(null);
  
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
  
  // 在组件挂载时生成答案，确保答案在整个卡片生命周期内保持不变
  useEffect(() => {
    const answer = getBookAnswer();
    const reflection = getAnswerReflection(answer);
    setBookAnswer(answer);
    setAnswerReflection(reflection);
  }, []);

  // 延迟启动内部动画，等待卡片容器动画完成
  useEffect(() => {
    const timer = setTimeout(() => {
      setIsCardReady(true);
    }, 0); // 减少延迟时间，加快主星星出现

    return () => clearTimeout(timer);
  }, []);
    
  // 移除自动聚焦功能 - 只有用户手动点击输入框时才触发键盘
  // useEffect(() => {
  //   if (isFlipped && inputRef.current) {
  //     setTimeout(() => {
  //       inputRef.current?.focus();
  //     }, 600); // 等待卡片翻转动画完成
  //   }
  // }, [isFlipped]);

  const handleDismiss = () => {
    playSound('starClick');
    onDismiss();
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
    if (isClosing) return;
    console.log('[InspirationCard] card wrapper clicked');
    toggleCardFlip();
  };

  const handleFlipBack = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (isClosing) return;
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

  // 为卡片生成唯一ID，用于渐变效果
  const cardId = `insp-${Date.now()}`;

  return createPortal(
    <motion.div
      className="fixed inset-0 flex items-center justify-center"
      style={{ zIndex: 999999 }}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      <motion.div
        className="absolute inset-0 bg-black"
        style={{ opacity: 0.6 }}
        initial={{ opacity: 0 }}
        animate={{ opacity: 0.6 }}
        exit={{ opacity: 0 }}
        transition={{ duration: 0.18 }}
        onClick={handleDismiss}
      />

      <motion.div
        className="star-card-container"
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.92 }}
        transition={{ type: "spring", stiffness: 220, damping: 20, duration: 0.18 }}
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
