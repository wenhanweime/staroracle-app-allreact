import React, { useState, useRef, useEffect, useCallback } from 'react';
import { Mic } from 'lucide-react';
import { playSound } from '../utils/soundUtils';
import { triggerHapticFeedback } from '../utils/hapticUtils';
import StarRayIcon from './StarRayIcon';
import FloatingAwarenessPlanet from './FloatingAwarenessPlanet';
import { Capacitor } from '@capacitor/core';
import { useChatStore } from '../store/useChatStore';

// iOS设备检测
const isIOS = () => {
  return /iPad|iPhone|iPod/.test(navigator.userAgent) || 
         (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
};

interface ConversationDrawerProps {
  isOpen: boolean;
  onToggle: () => void;
  onSendMessage?: (inputText: string) => void; // ✨ 新增：发送消息的回调
  showChatHistory?: boolean; // 新增是否显示聊天历史的开关
  followUpQuestion?: string; // 外部传入的后续问题
  onFollowUpProcessed?: () => void; // 后续问题处理完成的回调
  isFloatingAttached?: boolean; // 新增：是否有浮窗吸附状态
}

const ConversationDrawer: React.FC<ConversationDrawerProps> = ({ 
  isOpen, 
  onToggle, 
  onSendMessage, // ✨ 使用新 prop
  showChatHistory = true,
  followUpQuestion, 
  onFollowUpProcessed,
  isFloatingAttached = false // 新增参数
}) => {
  const [inputValue, setInputValue] = useState('');
  const [isRecording, setIsRecording] = useState(false);
  const [starAnimated, setStarAnimated] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  
  const { conversationAwareness } = useChatStore();

  // 移除所有键盘监听逻辑，让系统原生处理键盘行为

  const handleMicClick = () => {
    setIsRecording(!isRecording);
    console.log('Microphone clicked, recording:', !isRecording);
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('light');
    }
    playSound('starClick');
  };

  const handleStarClick = () => {
    setStarAnimated(true);
    console.log('Star ray button clicked');
    if (inputValue.trim()) {
      handleSend();
    }
    setTimeout(() => {
      setStarAnimated(false);
    }, 1000);
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInputValue(e.target.value);
  };

  // 发送处理 - 调用新的 onSendMessage
  const handleSend = useCallback(async () => {
    const trimmedInput = inputValue.trim();
    if (!trimmedInput) return;
    
    // ✨ 调用新的 onSendMessage 回调
    if (onSendMessage) {
      onSendMessage(trimmedInput);
    }
    
    // 发送后立即清空输入框
    setInputValue('');
    
    console.log('🔍 ConversationDrawer: 消息已发送，请求打开ChatOverlay');
  }, [inputValue, onSendMessage]); // ✨ 更新依赖

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSend();
    }
  };

  // 移除所有输入框点击控制，让系统原生处理

  // 完全移除样式计算，让系统原生处理所有定位
  const getContainerStyle = () => {
    // 只保留最基本的底部空间，移除所有动态计算
    return isFloatingAttached 
      ? { paddingBottom: '70px' } 
      : { paddingBottom: '1rem' }; // 使用固定值而不是env()
  };

  return (
    <div 
      ref={containerRef}
      className="fixed bottom-0 left-0 right-0 z-50 p-4 pointer-events-none" // 移除keyboard-aware-container，让系统原生处理
      style={getContainerStyle()}
    >
      <div className="w-full max-w-md mx-auto pointer-events-auto"> {/* 只有内容区域可点击 */}
        <div className="relative">
          <div className="flex items-center bg-gray-900 rounded-full h-12 shadow-lg border border-gray-800">
            {/* 左侧：觉察动画 */}
            <div className="ml-3 flex-shrink-0">
              <FloatingAwarenessPlanet
                level={conversationAwareness.overallLevel}
                isAnalyzing={conversationAwareness.isAnalyzing}
                conversationDepth={conversationAwareness.conversationDepth}
                onTogglePanel={() => {
                  console.log('觉察动画被点击');
                  // TODO: 实现觉察详情面板
                }}
              />
            </div>
            
            {/* Input field - 调整padding避免与左侧动画重叠 */}
            <input
              ref={inputRef}
              type="text"
              value={inputValue}
              onChange={handleInputChange}
              onKeyPress={handleKeyPress}
              // 🚨 关键：移除所有 onClick 和 onFocus 事件处理器，让其行为原生化
              placeholder="询问任何问题"
              className="flex-1 bg-transparent text-white placeholder-gray-400 pl-2 pr-4 py-2 focus:outline-none stellar-body"
              // iOS专用属性确保键盘弹起
              inputMode="text"
              autoComplete="off"
              autoCapitalize="sentences"
              spellCheck="false"
            />

            <div className="flex items-center space-x-2 mr-3">
              {/* 修正点 1: 麦克风按钮 - 使用新的CSS类解决iOS问题 */}
              <button
                type="button"
                onClick={handleMicClick}
                className={`p-2 rounded-full dialog-transparent-button transition-colors duration-200 ${
                  isRecording 
                    ? 'recording' 
                    : ''
                }`}
              >
                <Mic className="w-4 h-4" strokeWidth={2} />
              </button>

              {/* 修正点 2: 星星按钮 - 使用新的CSS类解决iOS问题 */}
              <button
                type="button"
                onClick={handleStarClick}
                className="p-2 rounded-full dialog-transparent-button transition-colors duration-200"
              >
                <StarRayIcon 
                  size={16} 
                  animated={starAnimated || !!inputValue.trim()} 
                  iconColor="currentColor"
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
        </div>
      </div>
    </div>
  );
};

export default ConversationDrawer;