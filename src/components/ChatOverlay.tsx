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
  onComplete?: () => void; // 完成觉察：由按钮触发
}

const ChatOverlay: React.FC<ChatOverlayProps> = ({
  isOpen,
  onClose,
  onReopen,
  followUpQuestion,
  onFollowUpProcessed,
  initialInput,
  inputBottomSpace = 70, // 默认70px
  onComplete
}) => {
  const [isDragging, setIsDragging] = useState(false);
  const [dragY, setDragY] = useState(0);
  const [startY, setStartY] = useState(0);
  
  // iOS键盘监听和视口调整
  const [viewportHeight, setViewportHeight] = useState(window.innerHeight);
  
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
    conversationAwareness,
    conversationTitle,
    generateConversationTitle
  } = useChatStore();

  // 视口高度监听（仅用于修复iOS浮窗显示问题，不干预键盘行为）
  useEffect(() => {
    const handleViewportChange = () => {
      if (window.visualViewport) {
        setViewportHeight(window.visualViewport.height);
      } else {
        setViewportHeight(window.innerHeight);
      }
    };

    // 监听视口变化 - 仅用于浮窗高度计算
    if (window.visualViewport) {
      window.visualViewport.addEventListener('resize', handleViewportChange);
      return () => {
        window.visualViewport?.removeEventListener('resize', handleViewportChange);
      };
    }
  }, []);
  
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

  // 拖拽处理逻辑 - 优化为全局拖拽检测
  const handleTouchStart = (e: React.TouchEvent) => {
    if (!isOpen) return;
    
    setIsDragging(true);
    setStartY(e.touches[0].clientY);
    
    // 检查对话滚动容器是否已滚动到顶部
    const scrollContainer = floatingRef.current?.querySelector('.overflow-y-auto');
    const isAtTop = !scrollContainer || scrollContainer.scrollTop <= 1; // 1px容差
    
    console.log('🖱️ 开始拖拽，对话是否在顶部:', isAtTop);
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    if (!isDragging || !isOpen) return;
    
    const currentY = e.touches[0].clientY;
    const deltaY = currentY - startY;
    
    // 先检查是否是微小下拉动作（优先级最高）
    if (deltaY > 0 && deltaY <= 20) {
      console.log(`📱 检测到微小下拉: ${deltaY}px，在整个浮窗范围内允许收起`);
      setDragY(Math.min(deltaY, window.innerHeight * 0.8));
      return;
    }
    
    // 检查对话滚动容器的状态
    const scrollContainer = floatingRef.current?.querySelector('.overflow-y-auto') as HTMLElement;
    const isAtTop = !scrollContainer || scrollContainer.scrollTop <= 1; // 1px容差
    
    // 大于20px的下拉动作才需要考虑滚动状态
    if (deltaY > 20) {
      // 情况1：在头部拖拽区域 - 始终允许拖拽
      const target = (e.target as HTMLElement).closest('.drag-handle');
      if (target) {
        console.log('📱 在头部拖拽区域，允许拖拽');
        setDragY(Math.min(deltaY, window.innerHeight * 0.8));
        return;
      }
      
      // 情况2：对话区域已滚动到顶部 - 允许拖拽收起浮窗
      if (isAtTop) {
        console.log('📱 对话在顶部，允许拖拽浮窗');
        setDragY(Math.min(deltaY, window.innerHeight * 0.8));
        return;
      }
      
      // 情况3：对话区域还有内容可滚动且下拉距离较大 - 让对话自由滚动
      console.log('📱 对话还可滚动，不处理浮窗拖拽');
    }
  };

  const handleTouchEnd = () => {
    if (!isDragging) return;
    setIsDragging(false);
    
    console.log(`📱 手指抬起，当前dragY: ${dragY}px`);
    
    // 微小拖拽更敏感的阈值 - 只要5px就能关闭浮窗
    if (dragY > 5) { 
      console.log('🔽 拖拽距离足够，关闭浮窗');
      onClose();
    } else {
      // 否则回弹到原位置
      console.log('↩️ 拖拽距离不够，回弹');
      setDragY(0);
    }
  };

  // 鼠标事件处理（用于桌面端调试）- 保持与触摸事件一致
  const handleMouseDown = (e: React.MouseEvent) => {
    if (!isOpen) return;
    
    setIsDragging(true);
    setStartY(e.clientY);
  };

  const handleMouseMove = (e: MouseEvent) => {
    if (!isDragging || !isOpen) return;
    
    const currentY = e.clientY;
    const deltaY = currentY - startY;
    
    // 先检查是否是微小下拉动作（优先级最高）
    if (deltaY > 0 && deltaY <= 20) {
      console.log(`📱 检测到微小下拉: ${deltaY}px，在整个浮窗范围内允许收起`);
      setDragY(Math.min(deltaY, window.innerHeight * 0.8));
      return;
    }
    
    // 检查对话滚动容器的状态
    const scrollContainer = floatingRef.current?.querySelector('.overflow-y-auto') as HTMLElement;
    const isAtTop = !scrollContainer || scrollContainer.scrollTop <= 1;
    
    if (deltaY > 20) {
      // 情况1：在头部拖拽区域 - 始终允许拖拽
      const target = (e.target as HTMLElement).closest('.drag-handle');
      if (target) {
        setDragY(Math.min(deltaY, window.innerHeight * 0.8));
        return;
      }
      
      // 情况2：对话区域已滚动到顶部 - 继续下拉直接收起浮窗
      if (isAtTop) {
        setDragY(Math.min(deltaY, window.innerHeight * 0.8));
        return;
      }
    }
  };

  const handleMouseUp = () => {
    if (!isDragging) return;
    setIsDragging(false);
    
    console.log(`📱 鼠标抬起，当前dragY: ${dragY}px`);
    
    // 使用相同的敏感阈值
    if (dragY > 5) {
      console.log('🔽 拖拽距离足够，关闭浮窗');
      onClose();
    } else {
      console.log('↩️ 拖拽距离不够，回弹');
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

  // 发送消息的核心逻辑（带重试机制）
  const sendMessage = async (messageText: string, retryCount = 0) => {
    if (!messageText.trim() || chatIsLoading) return;
    
    const trimmedQuestion = messageText.trim();
    const maxRetries = 3; // 最大重试次数
    
    // 只在第一次尝试时添加用户消息
    if (retryCount === 0) {
      addUserMessage(trimmedQuestion);
      playSound('starClick');
    }
    
    setLoading(true);
    
    try {
      console.log(`🤖 开始生成AI回复... (尝试 ${retryCount + 1}/${maxRetries + 1})`);
      
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
      
      // 在第一次AI回复后，尝试生成对话标题
      setTimeout(() => {
        generateConversationTitle();
      }, 1000);
      
    } catch (error) {
      console.error(`❌ AI回复生成失败 (尝试 ${retryCount + 1}/${maxRetries + 1}):`, error);
      
      if (retryCount < maxRetries) {
        // 还有重试机会，等待后重试
        console.log(`🔄 将在2秒后重试...`);
        setTimeout(() => {
          sendMessage(messageText, retryCount + 1);
        }, 2000);
      } else {
        // 重试次数用完，直接结束加载状态
        console.error('❌ 重试次数用完，AI回复失败');
        setLoading(false);
        
        // 移除可能创建的空消息
        const lastMessage = messages[messages.length - 1];
        if (lastMessage && !lastMessage.isUser && !lastMessage.text.trim()) {
          // 这里可以选择移除空消息，或者什么都不做
          console.log('🗑️ 移除空的AI消息');
        }
      }
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
        className={`fixed shadow-2xl z-45 bg-gray-900 ${!isOpen ? 'cursor-pointer' : ''} ${
          isOpen ? 'rounded-t-2xl' : 'rounded-full'
        }`}
        initial={false}
        animate={{          
          // 修复动画：使用一致的定位方式
          top: isOpen ? Math.max(80, 80 + dragY) : window.innerHeight - getAttachedBottomPosition() - 65,
          left: isOpen ? 0 : '50%',
          right: isOpen ? 0 : 'auto',
          // 移除bottom定位，只使用top定位
          width: isOpen ? '100vw' : 'min(28rem, calc(100vw - 2rem))',
          // 修复iOS键盘问题：使用实际视口高度
          height: isOpen ? `${viewportHeight - Math.max(80, 80 + dragY)}px` : 65,
          x: isOpen ? 0 : '-50%',
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
        onTouchStart={isOpen ? handleTouchStart : undefined}
        onTouchMove={isOpen ? handleTouchMove : undefined}
        onTouchEnd={isOpen ? handleTouchEnd : undefined}
        onMouseDown={isOpen ? handleMouseDown : undefined}
      >
        {/* 浮窗内容：关闭时显示简洁的吸附状态，展开时显示完整内容 */}
        {!isOpen && (
          <div 
            className="relative w-full h-full cursor-pointer"
            onClick={(e) => {
              // 点击浮窗任意位置都弹出（除了按钮）
              e.stopPropagation();
              console.log('🔄 点击收缩的浮窗，重新展开');
              if (onReopen) {
                onReopen();
              }
            }}
          >
            {/* 精确定位的控制栏 - 距离浮窗上边缘6px */}
            <div 
              className="absolute left-0 right-0 flex items-center justify-between px-4"
              style={{ top: '6px' }}
            >
              {/* 左侧：完成按钮 */}
              <div className="flex-1 text-left">
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    if (onComplete) {
                      onComplete();
                    } else {
                      onClose();
                    }
                  }}
                  className="px-3 py-1 rounded-full dialog-transparent-button transition-colors duration-200 text-blue-400 text-sm font-medium stellar-body"
                >
                  完成
                </button>
              </div>
              
              {/* 中间：当前对话标题 */}
              <div className="flex-1 flex justify-center">
                <span className="text-gray-400 text-sm font-medium stellar-body">
                  当前对话
                </span>
              </div>
              
              {/* 右侧：关闭按钮 */}
              <div className="flex-1 flex justify-end">
                <button
                  onClick={(e) => {
                    e.stopPropagation(); // 阻止冒泡到父元素的展开事件
                    onClose();
                  }}
                  className="p-2 rounded-full dialog-transparent-button transition-colors duration-200"
                >
                  <X className="w-4 h-4" strokeWidth={2} />
                </button>
              </div>
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
                  {conversationTitle && (
                    <h1 className="stellar-title text-white">
                      {conversationTitle}
                    </h1>
                  )}
                  <button
                    onClick={onClose}
                    className={`p-2 rounded-full dialog-transparent-button transition-colors duration-200 ${
                      !conversationTitle ? 'ml-auto' : ''
                    }`}
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>
              </div>
            </div>

            {/* 浮窗对话区域 - 只在展开时显示 */}
            <div className="flex-1 flex flex-col" style={{ height: 'calc(100% - 140px)' }}>
              {/* 消息列表 - 允许滚动 */}
              <div 
                className="flex-1 overflow-y-auto scrollbar-hidden"
                style={{
                  WebkitOverflowScrolling: 'touch', // iOS平滑滚动
                  overscrollBehavior: 'contain', // 防止滚动传播
                }}
              >
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
