import React, { useRef, useEffect } from 'react';
import { useChatStore } from '../store/useChatStore';
import UserMessage from './UserMessage';
import AIMessage from './AIMessage';
import LoadingMessage from './LoadingMessage';

// iOS设备检测
const isIOS = () => {
  return /iPad|iPhone|iPod/.test(navigator.userAgent) || 
         (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
};

const ChatMessages: React.FC = () => {
  const { messages, isLoading } = useChatStore();
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages, isLoading]);

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

  return (
    <div 
      className="flex-1 overflow-y-auto p-4 space-y-0"
      style={{
        paddingTop: getTopPadding(),
        paddingBottom: '100px' // 避免被底部输入框遮挡
      }}
    >
      {/* 渲染所有消息 */}
      {messages.map((message) => (
        message.isUser ? (
          <UserMessage key={message.id} message={message} />
        ) : (
          <AIMessage key={message.id} message={message} />
        )
      ))}
      
      {/* 加载状态 */}
      {isLoading && <LoadingMessage />}
      
      {/* 自动滚动锚点 */}
      <div ref={messagesEndRef} />
    </div>
  );
};

export default ChatMessages;