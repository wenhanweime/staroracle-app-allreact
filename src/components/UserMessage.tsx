import React, { useState, useRef } from 'react';
import { motion } from 'framer-motion';
import { Capacitor } from '@capacitor/core';
import { ChatMessage } from '../types/chat';
import MessageContextMenu from './MessageContextMenu';

interface UserMessageProps {
  message: ChatMessage;
}

const UserMessage: React.FC<UserMessageProps> = ({ message }) => {
  const [contextMenu, setContextMenu] = useState({ isVisible: false, x: 0, y: 0 });
  const [longPressTimer, setLongPressTimer] = useState<NodeJS.Timeout | null>(null);
  const messageRef = useRef<HTMLDivElement>(null);
  
  // 检查是否为原生平台
  const isNativePlatform = Capacitor.isNativePlatform();
  
  // 长按处理函数
  const handleLongPress = (event: React.TouchEvent | React.MouseEvent) => {
    event.preventDefault();
    const clientX = 'touches' in event ? event.touches[0].clientX : event.clientX;
    const clientY = 'touches' in event ? event.touches[0].clientY : event.clientY;
    
    setContextMenu({
      isVisible: true,
      x: clientX,
      y: clientY
    });
    
    console.log('显示用户消息上下文菜单', { x: clientX, y: clientY });
  };
  
  // 触摸开始
  const handleTouchStart = (event: React.TouchEvent) => {
    const timer = setTimeout(() => {
      handleLongPress(event);
    }, 500); // 500ms长按
    setLongPressTimer(timer);
  };
  
  // 触摸结束或取消
  const handleTouchEnd = () => {
    if (longPressTimer) {
      clearTimeout(longPressTimer);
      setLongPressTimer(null);
    }
  };
  
  // 鼠标右键点击
  const handleContextMenu = (event: React.MouseEvent) => {
    event.preventDefault();
    handleLongPress(event);
  };
  
  // 关闭上下文菜单
  const handleCloseContextMenu = () => {
    setContextMenu({ isVisible: false, x: 0, y: 0 });
  };
  
  // 复制消息
  const handleContextMenuCopy = () => {
    navigator.clipboard.writeText(message.text);
    console.log('通过上下文菜单复制用户消息');
  };
  return isNativePlatform ? (
    // 原生平台：无动画包装，让原生代码处理
    <div className="flex justify-end mb-4">
      <div className="max-w-[80%]">
        <div className="px-4 py-2 rounded-2xl bg-gray-700 text-white stellar-body">
          <div 
            ref={messageRef}
            className="whitespace-pre-wrap break-words chat-message-content"
            onTouchStart={handleTouchStart}
            onTouchEnd={handleTouchEnd}
            onTouchCancel={handleTouchEnd}
            onContextMenu={handleContextMenu}
          >
            {message.text}
          </div>
        </div>
        <div className="text-xs text-gray-400 mt-1 text-right">
          {message.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
        </div>
        
        {/* 上下文菜单 */}
        <MessageContextMenu
          isVisible={contextMenu.isVisible}
          position={{ x: contextMenu.x, y: contextMenu.y }}
          messageText={message.text}
          onClose={handleCloseContextMenu}
          onCopy={handleContextMenuCopy}
        />
      </div>
    </div>
  ) : (
    // Web平台：使用 framer-motion 动画
    <motion.div
      initial={{ 
        opacity: 0, 
        y: 60,
        scale: 0.95 
      }}
      animate={{ 
        opacity: 1, 
        y: 0,
        scale: 1 
      }}
      transition={{ 
        duration: 0.5,
        ease: "easeOut"
      }}
      className="flex justify-end mb-4"
    >
      <div className="max-w-[80%]">
        <div className="px-4 py-2 rounded-2xl bg-gray-700 text-white stellar-body">
          <div 
            ref={messageRef}
            className="whitespace-pre-wrap break-words chat-message-content"
            onTouchStart={handleTouchStart}
            onTouchEnd={handleTouchEnd}
            onTouchCancel={handleTouchEnd}
            onContextMenu={handleContextMenu}
          >
            {message.text}
          </div>
        </div>
        <div className="text-xs text-gray-400 mt-1 text-right">
          {message.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
        </div>
        
        {/* 上下文菜单 */}
        <MessageContextMenu
          isVisible={contextMenu.isVisible}
          position={{ x: contextMenu.x, y: contextMenu.y }}
          messageText={message.text}
          onClose={handleCloseContextMenu}
          onCopy={handleContextMenuCopy}
        />
      </div>
    </motion.div>
  );
};

export default UserMessage;