import React, { useState, useRef, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Mic } from 'lucide-react';
import { useChatStore } from '../store/useChatStore';
import { playSound } from '../utils/soundUtils';
import { triggerHapticFeedback } from '../utils/hapticUtils';
import StarRayIcon from './StarRayIcon';
import ChatMessages from './ChatMessages';
import FloatingAwarenessPlanet from './FloatingAwarenessPlanet';
import { Capacitor } from '@capacitor/core';
import { generateAIResponse } from '../utils/aiTaggingUtils';

// iOS设备检测
const isIOS = () => {
  return /iPad|iPhone|iPod/.test(navigator.userAgent) || 
         (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
};

interface ChatOverlayProps {
  isOpen: boolean;
  onClose: () => void;
  onReopen?: () => void; // 新增重新打开的回调
  followUpQuestion?: string;
  onFollowUpProcessed?: () => void;
  initialInput?: string;
  inputBottomSpace?: number; // 新增：输入框底部空间，用于计算吸附位置
}

const ChatOverlay: React.FC<ChatOverlayProps> = ({
  isOpen,
  onClose,
  onReopen,
  followUpQuestion,
  onFollowUpProcessed,
  initialInput,
  inputBottomSpace = 70 // 默认70px
}) => {
  const [isDragging, setIsDragging] = useState(false);
  const [dragY, setDragY] = useState(0);
  const [startY, setStartY] = useState(0);
  
  const floatingRef = useRef<HTMLDivElement>(null);
  const hasProcessedInitialInput = useRef(false);
  
  const { 
    addUserMessage, 
    addStreamingAIMessage, 
    updateStreamingMessage, 
    finalizeStreamingMessage, 
    setLoading, 
    isLoading: chatIsLoading, 
    messages,
    conversationAwareness
  } = useChatStore();

  // 计算吸附位置：浮窗顶部 = 输入框底部 - 5px
  const getAttachedBottomPosition = () => {
    const gap = 5; // 浮窗顶部与输入框底部的间隙
    const floatingHeight = 65; // 浮窗关闭时高度65px
    
    // 浮窗顶部绝对位置 = 屏幕高度 - (inputBottomSpace - gap)
    // CSS bottom值 = 浮窗顶部距离屏幕底部的距离 - 浮窗高度
    // bottom = (inputBottomSpace - gap) - floatingHeight
    const bottomValue = (inputBottomSpace - gap) - floatingHeight;
    
    return bottomValue;
  };

  // 获取最后一条消息用于预览
  const getLastMessagePreview = () => {
    if (messages.length === 0) return '';
    const lastMessage = messages[messages.length - 1];
    const maxLength = 15; // 最大显示长度
    
    if (lastMessage.text.length <= maxLength) {
      return lastMessage.text;
    }
    return lastMessage.text.substring(0, maxLength) + '...';
  };

  // 处理初始输入文本 - 自动发送初始输入
  useEffect(() => {
    if (initialInput && initialInput.trim() && !hasProcessedInitialInput.current) {
      console.log('🔄 ChatOverlay接收到初始输入:', initialInput);
      hasProcessedInitialInput.current = true;
      
      // 自动发送初始输入
      setTimeout(() => {
        sendMessage(initialInput);
      }, 300);
    }
  }, [initialInput]);

  // 重置标记当组件关闭时
  useEffect(() => {
    if (!isOpen) {
      hasProcessedInitialInput.current = false;
      setDragY(0);
    }
  }, [isOpen]);

  // 处理外部传入的后续问题
  useEffect(() => {
    if (followUpQuestion && followUpQuestion.trim()) {
      console.log('🔄 ChatOverlay接收到后续问题:', followUpQuestion);
      setTimeout(() => {
        sendMessage(followUpQuestion);
        if (onFollowUpProcessed) {
          onFollowUpProcessed();
        }
      }, 200);
    }
  }, [followUpQuestion, onFollowUpProcessed]);

  // 拖拽处理逻辑
  const handleTouchStart = (e: React.TouchEvent) => {
    if (!isOpen) return;
    // 只有点击头部拖拽区域才允许拖拽
    const target = (e.target as HTMLElement).closest('.drag-handle');
    if (!target) return;
    
    setIsDragging(true);
    setStartY(e.touches[0].clientY);
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    if (!isDragging || !isOpen) return;
    
    const currentY = e.touches[0].clientY;
    const deltaY = currentY - startY;
    
    // 只允许向下拖拽
    if (deltaY > 0) {
      setDragY(Math.min(deltaY, window.innerHeight * 0.8));
    }
  };

  const handleTouchEnd = () => {
    if (!isDragging) return;
    setIsDragging(false);
    
    const screenHeight = window.innerHeight;
    
    // 如果拖拽超过屏幕高度的1/2，关闭浮窗
    if (dragY > screenHeight * 0.4) {
      onClose();
    } else {
      // 否则回弹到原位置
      setDragY(0);
    }
  };

  // 鼠标事件处理（用于桌面端调试）
  const handleMouseDown = (e: React.MouseEvent) => {
    if (!isOpen) return;
    const target = (e.target as HTMLElement).closest('.drag-handle');
    if (!target) return;
    
    setIsDragging(true);
    setStartY(e.clientY);
  };

  const handleMouseMove = (e: MouseEvent) => {
    if (!isDragging || !isOpen) return;
    
    const currentY = e.clientY;
    const deltaY = currentY - startY;
    
    if (deltaY > 0) {
      setDragY(Math.min(deltaY, window.innerHeight * 0.8));
    }
  };

  const handleMouseUp = () => {
    if (!isDragging) return;
    setIsDragging(false);
    
    const screenHeight = window.innerHeight;
    
    if (dragY > screenHeight * 0.4) {
      onClose();
    } else {
      setDragY(0);
    }
  };

  // 添加全局鼠标事件监听
  useEffect(() => {
    if (isDragging) {
      document.addEventListener('mousemove', handleMouseMove);
      document.addEventListener('mouseup', handleMouseUp);
      
      return () => {
        document.removeEventListener('mousemove', handleMouseMove);
        document.removeEventListener('mouseup', handleMouseUp);
      };
    }
  }, [isDragging, startY, dragY]);

  // 发送消息的核心逻辑
  const sendMessage = async (messageText: string) => {
    if (!messageText.trim() || chatIsLoading) return;
    
    const trimmedQuestion = messageText.trim();
    
    addUserMessage(trimmedQuestion);
    playSound('starClick');
    setLoading(true);
    
    try {
      console.log('🤖 开始生成AI回复...');
      
      const messageId = addStreamingAIMessage('');
      let streamingText = '';
      
      const onStream = (chunk: string) => {
        streamingText += chunk;
        updateStreamingMessage(messageId, streamingText);
      };
      
      const conversationHistory = messages.map(msg => ({
        role: msg.isUser ? 'user' as const : 'assistant' as const,
        content: msg.text
      }));
      
      console.log('📚 Conversation history:', conversationHistory.length, 'messages');
      
      const aiResponse = await generateAIResponse(
        trimmedQuestion, 
        undefined, 
        onStream, 
        conversationHistory
      );
      
      if (streamingText !== aiResponse) {
        updateStreamingMessage(messageId, aiResponse);
      }
      
      finalizeStreamingMessage(messageId);
      setLoading(false);
      playSound('starReveal');
      
      console.log('✅ AI回复生成成功:', aiResponse);
      
    } catch (error) {
      console.error('❌ AI回复生成失败:', error);
      
      const fallbackResponses = [
        "抱歉，星辰暂时无法为您提供指引。请稍后再试。",
        "宇宙的连接似乎暂时中断了，请稍后重新提问。",
        "星谕正在重新校准，请耐心等待片刻再询问。",
      ];
      
      const fallbackResponse = fallbackResponses[Math.floor(Math.random() * fallbackResponses.length)];
      
      const messageId = addStreamingAIMessage(fallbackResponse);
      finalizeStreamingMessage(messageId);
      setLoading(false);
      playSound('starClick');
    }
  };

  const handleFollowUpQuestion = (question: string) => {
    console.log('📱 ChatOverlay层接收到后续提问:', question);
    sendMessage(question);
  };

  return (
    <>
      {/* 遮罩层 - 只在完全展开时显示 */}
      <div 
        className={`fixed inset-0 bg-black transition-opacity duration-300 ${
          isOpen ? 'bg-opacity-40 pointer-events-auto z-45' : 'bg-opacity-0 pointer-events-none z-10'
        }`}
        onClick={isOpen ? onClose : undefined}
      />

      {/* 浮窗内容 - 关闭时吸附在底部，展开时全屏 */}
      <motion.div 
        ref={floatingRef}
        className={`fixed rounded-t-2xl shadow-2xl z-45 bg-gray-900 ${!isOpen ? 'cursor-pointer' : ''}`}
        initial={false}
        animate={{
          top: isOpen ? Math.max(80, 80 + dragY) : 'auto',
          left: isOpen ? 0 : '50%',
          right: isOpen ? 0 : 'auto',
          bottom: isOpen ? 0 : getAttachedBottomPosition(),
          width: isOpen ? '100vw' : 448, // 展开时全屏，收起时固定宽度
          height: isOpen ? 'auto' : 65,
          x: isOpen ? 0 : '-50%', // 收起时居中偏移
          y: dragY * 0.15,
          opacity: Math.max(0.9, 1 - dragY / 500)
        }}
        transition={{
          type: 'spring',
          damping: 25,
          stiffness: 300,
          duration: 0.3
        }}
        style={{
          pointerEvents: 'auto'
        }}
        onTouchStart={!isOpen ? undefined : handleTouchStart}
        onTouchMove={!isOpen ? undefined : handleTouchMove}
        onTouchEnd={!isOpen ? undefined : handleTouchEnd}
        onMouseDown={!isOpen ? undefined : handleMouseDown}
        onClick={!isOpen ? (e) => {
          e.stopPropagation();
          console.log('🔄 点击收缩的浮窗，重新展开');
          if (onReopen) {
            onReopen();
          }
        } : undefined}
      >
        {/* 浮窗内容：关闭时显示简洁的吸附状态，展开时显示完整内容 */}
        {!isOpen && (
          <div className="flex items-start justify-between px-4 pt-2 pb-1 h-full">
            {/* 左侧：对话标题 */}
            <div className="flex-1 text-left">
              <span className="text-gray-300 text-sm font-medium">
                {getLastMessagePreview()}
              </span>
            </div>
            
            {/* 中间：iOS风格的横条指示器 */}
            <div className="flex-1 flex justify-center">
              <div className="w-8 h-1 bg-gray-500 rounded-full mt-2"></div>
            </div>
            
            {/* 右侧：关闭按钮 */}
            <div className="flex-1 flex justify-end">
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onClose();
                }}
                className="p-2 rounded-full dialog-transparent-button transition-colors duration-200"
              >
                <X className="w-4 h-4" strokeWidth={2} />
              </button>
            </div>
          </div>
        )}

        {/* 展开状态的正常内容 */}
        {isOpen && (
          <>
            {/* 拖拽指示器和头部 */}
            <div className="drag-handle cursor-grab active:cursor-grabbing">
              <div className="flex justify-center py-4">
                <div className="w-12 h-1.5 bg-gray-600 rounded-full"></div>
              </div>
              
              <div className="px-4 pb-4">
                <div className="flex items-center justify-between">
                  <h1 className="stellar-title text-white">星谕对话</h1>
                  <button
                    onClick={onClose}
                    className="text-gray-400 hover:text-white text-2xl leading-none w-8 h-8 flex items-center justify-center"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>
                <p className="text-gray-400 text-sm mt-1">在这里继续您的对话</p>
              </div>
            </div>

            {/* 浮窗对话区域 - 只在展开时显示 */}
            <div className="flex-1 flex flex-col" style={{ height: 'calc(100% - 140px)' }}>
              {/* 消息列表 */}
              <div className="flex-1 overflow-hidden">
                <ChatMessages onAskFollowUp={handleFollowUpQuestion} />
              </div>

              {/* 底部留空，让主界面的输入框显示在这里 */}
              <div className="h-20"></div>
            </div>
          </>
        )}
      </motion.div>
    </>
  );
};

export default ChatOverlay;