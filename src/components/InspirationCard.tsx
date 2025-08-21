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
    }, 800); // 等待卡片弹出动画完成后再启动内部动画

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

  const handleCardClick = () => {
    setIsFlipped(!isFlipped);
    playSound('starClick');
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
        className="absolute inset-0 bg-black bg-opacity-70 backdrop-blur-sm"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={handleDismiss}
      />
      
      <motion.div
        className="star-card-container"
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ type: "spring", damping: 20 }}
      >
        <div className="star-card-wrapper">
          <motion.div
            className="star-card"
            animate={{ rotateY: isFlipped ? 180 : 0 }}
            transition={{ duration: 0.6, type: "spring" }}
            onClick={handleCardClick}
          >
            {/* Front Side - Card Design */}
            <div className="star-card-face star-card-front">
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
                  initial={{ opacity: 0.3 }}
                  animate={isCardReady ? { 
                    opacity: [0.3, 0.8, 0.3]
                  } : { opacity: 0.3 }}
                  transition={{
                    duration: star.duration,
                    repeat: isCardReady ? Infinity : 0,
                    delay: isCardReady ? 2.0 + star.delay : 0  // 在主星星动画完成后(2s)再开始
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
                      transition={{ delay: isCardReady ? 0.3 : 0, type: "spring" }}
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
                          opacity: [0, 0.8, 0],
                        } : { pathLength: 0, opacity: 0 }}
                        transition={{
                          duration: 1.5,
                          delay: isCardReady ? i * 0.1 : 0,
                          repeat: isCardReady ? Infinity : 0,
                          repeatDelay: isCardReady ? 1 : 0,
                        }}
              />
                    ))}
            </svg>
          </div>

                <motion.div
                  className="card-prompt"
                  initial={{ opacity: 0, y: 20 }}
                  animate={isCardReady ? { opacity: 0.7, y: 0 } : { opacity: 0, y: 20 }}
                  transition={{ delay: isCardReady ? 0.5 : 0 }}
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
              animate={isCardReady ? {
                        y: [-5, 5, -5],
                        opacity: [0.3, 0.7, 0.3],
              } : { y: 0, opacity: 0.3 }}
              transition={{
                duration: particle.duration,
                repeat: isCardReady ? Infinity : 0,
                delay: isCardReady ? 2.0 + particle.delay : 0,  // 同样在主星星动画完成后开始
              }}
            />
          ))}
                </div>
              </div>
            </div>

            {/* Back Side - Book of Answers */}
            <div className="star-card-face star-card-back">
              <div className="star-card-content flex flex-col h-full">
                {/* 标题 */}
                <motion.div
                  initial={{ opacity: 0, y: -10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.2 }}
                >
                  <h3 className="answer-label text-xl font-semibold text-cosmic-accent text-center mb-6">来自宇宙的答案</h3>
                </motion.div>
                
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
                  animate={{ opacity: 0.45 }}
                  transition={{ delay: 0.6 }}
                >
                  <p className="reflection-text text-[9px] text-neutral-500 italic text-center leading-tight tracking-wide">{answerReflection}</p>
                </motion.div>
                
                {/* 抽屉式输入框 - 直接显示，无需点击按钮 */}
                <motion.div
                  className="card-footer"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.7 }}
                  onClick={(e) => e.stopPropagation()} // 防止点击输入框时触发卡片翻转
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
                      />
                      <motion.button
                        className={`w-7 h-7 rounded-full flex items-center justify-center transition-colors ${
                          inputValue.trim() ? 'bg-cosmic-accent/80 text-white' : 'bg-transparent text-neutral-400'
                        }`}
                        onClick={handleSendMessage}
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