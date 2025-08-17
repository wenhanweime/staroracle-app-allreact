import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, SlidersHorizontal, Mic, Plus } from 'lucide-react';
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
  const [isRecording, setIsRecording] = useState(false);
  const [starAnimated, setStarAnimated] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
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
    if (isAsking && inputRef.current) {
      inputRef.current.focus();
      console.log("星空点击模式已激活", pendingStarPosition);
    }
  }, [isAsking, pendingStarPosition]);

  const handleAddClick = () => {
    console.log('Add button clicked');
    // 可以用于打开历史对话或其他功能
  };

  const handleMicClick = () => {
    setIsRecording(!isRecording);
    console.log('Microphone clicked, recording:', !isRecording);
    // TODO: 集成语音识别功能
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('light');
    }
    playSound('starClick');
  };

  const handleStarClick = () => {
    setStarAnimated(true);
    console.log('Star ray button clicked');
    
    // 如果有输入内容，直接提交
    if (inputValue.trim()) {
      handleSend();
    }
    
    // Reset animation after completion
    setTimeout(() => {
      setStarAnimated(false);
    }, 1000);
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInputValue(e.target.value);
  };

  const handleInputKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSend();
    }
  };

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
        
        {/* 对话框抽屉 - 完全按照demo的暗色输入框设计，移除灰色背景 */}
        <div className="w-full max-w-md mx-auto px-4 pb-4 pointer-events-auto">
          <div className="relative">
            {/* Main container with dark background - 完全复刻demo设计 */}
            <div className="flex items-center bg-gray-900 rounded-full h-12 shadow-lg border border-gray-800">
              
              {/* Plus button - positioned flush left */}
              <button
                type="button"
                onClick={handleAddClick}
                className="flex-shrink-0 w-10 h-10 bg-gray-700 hover:bg-gray-600 rounded-full flex items-center justify-center ml-1 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 focus:ring-offset-gray-900"
                disabled={isLoading}
              >
                <Plus className="w-5 h-5 text-white" strokeWidth={2} />
              </button>

              {/* Input field */}
              <input
                ref={inputRef}
                type="text"
                value={inputValue}
                onChange={handleInputChange}
                onKeyPress={handleInputKeyPress}
                placeholder={isAsking ? "向星空提出你的问题..." : "询问任何问题"}
                className="flex-1 bg-transparent text-white placeholder-gray-400 px-4 py-2 focus:outline-none text-sm font-normal"
                style={{ fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif' }}
                disabled={isLoading}
              />

              {/* Right side icons container */}
              <div className="flex items-center space-x-2 mr-3">
                
                {/* Microphone button */}
                <button
                  type="button"
                  onClick={handleMicClick}
                  className={`p-2 rounded-full transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-500 ${
                    isRecording 
                      ? 'bg-red-600 hover:bg-red-500 text-white' 
                      : 'hover:bg-gray-700 text-gray-300'
                  }`}
                  disabled={isLoading}
                >
                  <Mic className="w-4 h-4" strokeWidth={2} />
                </button>

                {/* Star ray button - 使用demo的设计和动画逻辑 */}
                <button
                  type="button"
                  onClick={handleStarClick}
                  className="p-2 rounded-full hover:bg-gray-700 text-gray-300 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-500"
                  disabled={isLoading}
                >
                  <StarRayIcon 
                    size={16} 
                    animated={starAnimated || !!inputValue.trim()} 
                    iconColor="#ffffff"
                  />
                </button>
                
              </div>
            </div>

            {/* Recording indicator */}
            {isRecording && (
              <div className="absolute -bottom-8 left-1/2 transform -translate-x-1/2">
                <div className="flex items-center space-x-2 text-red-400 text-xs">
                  <div className="w-2 h-2 bg-red-500 rounded-full animate-pulse"></div>
                  <span>Recording...</span>
                </div>
              </div>
            )}

            {/* Cancel button for asking mode - 单独放置，不影响主输入框设计 */}
            {isAsking && (
              <div className="absolute -top-12 right-0">
                <button
                  type="button"
                  className="flex items-center justify-center w-8 h-8 bg-gray-700 hover:bg-gray-600 rounded-full text-gray-300 hover:text-white transition-colors"
                  onClick={handleCancel}
                  disabled={isLoading}
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            )}
          </div>
        </div>

      </motion.div>
    </>
  );
};

export default ConversationDrawer;