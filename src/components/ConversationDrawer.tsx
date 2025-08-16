import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, SlidersHorizontal, Mic } from 'lucide-react';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import { triggerHapticFeedback } from '../utils/hapticUtils';
import StarRayIcon from './StarRayIcon';
import { Capacitor } from '@capacitor/core';

// 接口和数据保持不变
interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

// 我们将使用这些数据来生成提示问题胶囊
const SUGGESTION_CARDS = [
  { title: '探索内心', subtitle: '我真正想要的是什么？' },
  { title: '关系思考', subtitle: '如何建立更深的连接？' },
  { title: '人生方向', subtitle: '我的下一步应该是什么？' },
  { title: '情感觉察', subtitle: '现在的感受想告诉我什么？' },
  { title: '创意灵感', subtitle: '如何表达真实的自己？' },
  { title: '智慧寻求', subtitle: '生命的意义在哪里？' },
];

interface ConversationDrawerProps {
  isOpen: boolean;
  onToggle: () => void;
}

const ConversationDrawer: React.FC<ConversationDrawerProps> = () => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [showConversationCard, setShowConversationCard] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const { addStar, isAsking, setIsAsking, pendingStarPosition } = useStarStore();

  // 滚动到底部
  const scrollToBottom = () => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  };
  
  // 当有新消息时滚动到底部
  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  // 监听isAsking状态变化，当用户在星空中点击时自动聚焦输入框
  useEffect(() => {
    if (isAsking && textareaRef.current) {
      textareaRef.current.focus();
      console.log("星空点击模式已激活", pendingStarPosition);
    }
  }, [isAsking, pendingStarPosition]);

  const handleSend = async () => {
    if (!inputValue.trim() || isLoading) return;
    
    setIsLoading(true);
    const trimmedQuestion = inputValue.trim();
    
    // 保存用户问题到消息历史
    const newUserMessage: Message = {
      id: `user-${Date.now()}`,
      role: 'user',
      content: trimmedQuestion,
      timestamp: new Date()
    };
    
    setMessages(prev => [...prev, newUserMessage]);
    setInputValue('');
    
    try {
      // 在星空中创建星星 - pendingStarPosition由useStarStore提供
      const newStar = await addStar(trimmedQuestion);
      console.log("✨ 新星星已创建:", newStar.id);
      
      // 添加AI回复到消息历史
      const newAssistantMessage: Message = {
        id: `assistant-${Date.now()}`,
        role: 'assistant',
        content: newStar.answer,
        timestamp: new Date()
      };
      
      setMessages(prev => [...prev, newAssistantMessage]);
      playSound('starReveal'); // 修改为已有的声音类型
    } catch (error) {
      console.error('Error creating star:', error);
      // 错误处理...
    } finally {
      setIsLoading(false);
    }
  };
  
  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  // 点击提示问题胶囊的事件处理
  const handleSuggestionClick = (suggestionText: string) => {
    setInputValue(suggestionText);
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('light');
    }
    playSound('starClick');
    textareaRef.current?.focus();
  };

  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.style.height = '24px';
      textareaRef.current.style.height = `${Math.min(textareaRef.current.scrollHeight, 96)}px`;
    }
  }, [inputValue]);

  // 关闭提问模式
  const handleCancel = () => {
    if (isAsking) {
      setIsAsking(false);
      // 添加触感反馈（仅原生环境）
      if (Capacitor.isNativePlatform()) {
        triggerHapticFeedback('light');
      }
      playSound('starClick'); // 修改为已有的声音类型
    }
  };

  return (
    <>
      {/* 中央对话卡片 (保持不变) */}
      <AnimatePresence>{showConversationCard && <></> /* 省略 */}</AnimatePresence>

      {/* ============== 底部输入区域 (重点修改区域) ============== */}
      {/* 
        改动1: 创建一个新的父容器。
        这个容器是透明的，负责整体定位和入场动画。
        它将包含"提示问题胶囊"和"对话框"这两个兄弟元素。
      */}
      <motion.div
        className="fixed bottom-0 left-0 right-0 z-40 flex flex-col items-center pointer-events-none"
        style={{
          paddingBottom: `var(--safe-area-inset-bottom)`
        }}
        initial={{ y: "100%" }}
        animate={{ y: "0%" }}
        exit={{ y: "100%" }}
        transition={{ 
          type: 'spring', 
          damping: 30, 
          stiffness: 400,
          mass: 0.8
        }}
      >
        {/* 
          提示问题胶囊区域
        */}
        <AnimatePresence>
          {messages.length === 0 && !inputValue.trim() && !isAsking && (
            <motion.div
              className="w-full max-w-4xl mb-2 px-4 pointer-events-auto"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0, transition: { delay: 0.2 } }}
              exit={{ opacity: 0, y: 10 }}
            >
              {/* 横向滚动容器，并隐藏滚动条 */}
              <div className="flex gap-2 overflow-x-auto pb-1 [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden">
                {SUGGESTION_CARDS.map((suggestion, index) => (
                  <motion.button
                    key={index}
                    className="flex-shrink-0 rounded-full bg-neutral-800/80 backdrop-blur-sm px-4 py-2 text-sm text-neutral-200 hover:bg-neutral-700 transition-colors whitespace-nowrap"
                    onClick={() => handleSuggestionClick(suggestion.subtitle)}
                    initial={{ opacity: 0, scale: 0.8 }}
                    animate={{ opacity: 1, scale: 1, transition: { delay: 0.3 + index * 0.03 } }}
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                  >
                    {suggestion.subtitle}
                  </motion.button>
                ))}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
        
        {/* 对话框抽屉 */}
        <div className="w-full max-w-4xl px-4 pb-4 sm:pb-0 pointer-events-auto">
            <div
              className="drawer-container bg-neutral-800/70 backdrop-blur-sm border-t border-neutral-600/30 rounded-t-xl shadow-[0_-4px_12px_rgba(0,0,0,0.05)]"
            >
              {/* 小横杠指示器 */}
              <div className="flex justify-center pt-2 pb-1">
                <div className="w-12 h-1 bg-neutral-600/30 rounded-full"></div>
              </div>
              
              <div className="flex items-center gap-3 p-3">
                {/* 左侧图标按钮 - 只保留取消按钮（在isAsking状态下） */}
                {isAsking && (
                <motion.button 
                    className="flex-shrink-0 h-10 w-10 flex items-center justify-center text-neutral-400 hover:text-white transition-colors rounded-full"
                    whileHover={{ scale: 1.1 }} 
                    whileTap={{ scale: 0.9 }}
                    onClick={handleCancel}
                >
                    <X className="w-5 h-5" />
                </motion.button>
                )}
                
                {/* 左侧语音按钮 */}
                <motion.button 
                  className="flex-shrink-0 h-10 w-10 flex items-center justify-center text-neutral-400 hover:text-white transition-colors rounded-full"
                  whileHover={{ scale: 1.1 }}
                  whileTap={{ scale: 0.9 }}
                >
                  <Mic className="w-5 h-5" />
                </motion.button>

                {/* 中间输入框 */}
                <div className="flex-1 mx-1">
                  <textarea
                    ref={textareaRef}
                    className="w-full bg-transparent text-white placeholder-neutral-400 resize-none outline-none leading-relaxed py-2 px-1"
                    style={{ height: '24px', minHeight: '24px' }}
                    placeholder={isAsking ? "向星空提出你的问题..." : "询问任何问题"}
                    value={inputValue}
                    onChange={(e) => setInputValue(e.target.value)}
                    onKeyPress={handleKeyPress}
                    rows={1}
                  />
                </div>
                
                {/* 右侧发送/星星按钮 - 更大尺寸 */}
                <AnimatePresence mode="wait">
                  {inputValue.trim() ? (
                    <motion.button
                      key="send"
                      className="flex-shrink-0 h-12 w-12 flex items-center justify-center rounded-full bg-cosmic-accent text-white shadow-lg"
                      onClick={handleSend}
                      disabled={isLoading}
                      initial={{ scale: 0.5, opacity: 0 }}
                      animate={{ scale: 1, opacity: 1 }}
                      exit={{ scale: 0.5, opacity: 0 }}
                      transition={{ type: 'spring', damping: 15, stiffness: 400 }}
                      whileHover={{ scale: 1.1, backgroundColor: '#8A5FBD' }}
                      whileTap={{ scale: 0.95 }}
                    >
                      <StarRayIcon size={22} animated={true} />
                    </motion.button>
                  ) : (
                    <motion.button
                      key="star"
                      className="flex-shrink-0 h-12 w-12 flex items-center justify-center text-neutral-400 hover:text-white transition-colors rounded-full"
                      initial={{ scale: 0.5, opacity: 0 }}
                      animate={{ scale: 1, opacity: 1 }}
                      exit={{ scale: 0.5, opacity: 0 }}
                      transition={{ type: 'spring', damping: 15, stiffness: 400 }}
                      whileHover={{ scale: 1.1 }}
                      whileTap={{ scale: 0.9 }}
                    >
                      <StarRayIcon size={22} />
                    </motion.button>
                  )}
                </AnimatePresence>
              </div>
            </div>
        </div>

      </motion.div>
    </>
  );
};

export default ConversationDrawer;