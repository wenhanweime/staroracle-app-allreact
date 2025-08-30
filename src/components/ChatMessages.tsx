import React, { useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Capacitor } from '@capacitor/core';
import { ChatMessage } from '../store/useChatStore';
import UserMessage from './UserMessage';
import AIMessage from './AIMessage';
import LoadingMessage from './LoadingMessage';

// iOS设备检测
const isIOS = () => {
  return /iPad|iPhone|iPod/.test(navigator.userAgent) || 
         (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
};

interface ChatMessagesProps {
  messages: ChatMessage[];
  onAskFollowUp?: (question: string) => void; // 后续提问回调
}

const ChatMessages: React.FC<ChatMessagesProps> = ({ messages, onAskFollowUp }) => {
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  
  // 检查是否为原生平台
  const isNativePlatform = Capacitor.isNativePlatform();

  const scrollToBottom = () => {
    if (messagesEndRef.current) {
      // 使用更精确的滚动方式
      const scrollContainer = messagesEndRef.current.closest('.overflow-y-auto');
      if (scrollContainer) {
        scrollContainer.scrollTop = scrollContainer.scrollHeight;
      } else {
        messagesEndRef.current.scrollIntoView({ behavior: 'smooth' });
      }
    }
  };

  useEffect(() => {
    // 延迟滚动，确保DOM更新完成
    const timer = setTimeout(() => {
      scrollToBottom();
    }, 100);

    return () => clearTimeout(timer);
  }, [messages.length]); // 🔧 优化：只在消息数量变化时滚动，避免流式更新导致的频繁滚动

  // 根据设备类型计算不同的顶部间距
  const getTopPadding = () => {
    if (isIOS()) {
      // iOS端：较小的间距，因为之前已经有额外的安全区域处理
      return 'calc(90px + env(safe-area-inset-top, 0px))';
    } else {
      // Web端：保持当前的120px间距
      return 'calc(120px + env(safe-area-inset-top, 0px))';
    }
  };

  // 找到对应的用户问题
  const getUserQuestionForMessage = (messageIndex: number) => {
    // 往前查找最近的用户消息
    for (let i = messageIndex - 1; i >= 0; i--) {
      if (messages[i].isUser) {
        return messages[i].text;
      }
    }
    return undefined;
  };

  return (
    <div 
      className="p-4 space-y-0"
      style={{
        paddingTop: getTopPadding(),
        paddingBottom: '100px' // 避免被底部输入框遮挡
      }}
    >
      {/* 渲染所有消息 - 根据平台选择动画策略 */}
      {isNativePlatform ? (
        // 原生平台：不使用 framer-motion 动画，让原生 Swift 代码处理动画
        messages.map((message, index) => (
          <div key={message.id}>
            {message.isUser ? (
              <UserMessage message={message} />
            ) : (
              <AIMessage 
                message={message}
                userQuestion={getUserQuestionForMessage(index)}
                onAskFollowUp={onAskFollowUp}
              />
            )}
          </div>
        ))
      ) : (
        // Web平台：使用 framer-motion 动画，但将 motion.div 放在组件内部
        <AnimatePresence>
          {messages.map((message, index) => (
            <div key={message.id}>
              {message.isUser ? (
                <UserMessage message={message} />
              ) : (
                <AIMessage 
                  message={message}
                  userQuestion={getUserQuestionForMessage(index)}
                  onAskFollowUp={onAskFollowUp}
                />
              )}
            </div>
          ))}
        </AnimatePresence>
      )}
      
      {/* 加载状态现在由 AIMessage 组件内部处理 */}
      
      {/* 自动滚动锚点 */}
      <div ref={messagesEndRef} />
    </div>
  );
};

export default ChatMessages;