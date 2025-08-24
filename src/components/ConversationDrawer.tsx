import React, { useState, useRef, useCallback } from 'react';
import { Mic } from 'lucide-react';
import { playSound } from '../utils/soundUtils';
import { triggerHapticFeedback } from '../utils/hapticUtils';
import StarRayIcon from './StarRayIcon';
import FloatingAwarenessPlanet from './FloatingAwarenessPlanet';
import { Capacitor } from '@capacitor/core';
import { useChatStore } from '../store/useChatStore';
import { useKeyboard } from '../hooks/useKeyboard';

interface ConversationDrawerProps {
  isOpen: boolean;
  onToggle: () => void;
  onSendMessage?: (inputText: string) => void;
  showChatHistory?: boolean;
  followUpQuestion?: string;
  onFollowUpProcessed?: () => void;
  isFloatingAttached?: boolean;
}

const ConversationDrawer: React.FC<ConversationDrawerProps> = ({ 
  onSendMessage,
  isFloatingAttached = false
}) => {
  const [inputValue, setInputValue] = useState('');
  const [isRecording, setIsRecording] = useState(false);
  const [starAnimated, setStarAnimated] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const { conversationAwareness } = useChatStore();
  const { keyboardHeight, isKeyboardOpen } = useKeyboard();

  // 🎯 使用Capacitor键盘数据动态计算位置
  const getBottomPosition = () => {
    if (isKeyboardOpen && keyboardHeight > 0) {
      // 键盘打开时，使用键盘高度 + 少量间距
      return keyboardHeight + 10;
    } else {
      // 键盘关闭时，使用底部安全区域或浮窗间距
      return isFloatingAttached ? 70 : 20;
    }
  };

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

  const handleSend = useCallback(async () => {
    const trimmedInput = inputValue.trim();
    if (!trimmedInput) return;
    
    if (onSendMessage) {
      onSendMessage(trimmedInput);
    }
    
    setInputValue('');
    console.log('🔍 ConversationDrawer: 消息已发送，请求打开ChatOverlay');
  }, [inputValue, onSendMessage]);

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSend();
    }
  };

  return (
    <div 
      className="fixed left-0 right-0 z-50 p-4"
      style={{
        bottom: `${getBottomPosition()}px`, // 🎯 使用Capacitor键盘高度
        transition: 'bottom 0.3s ease-out', // 🎯 平滑过渡动画
        pointerEvents: 'none'
      }}
    >
      <div className="w-full max-w-md mx-auto pointer-events-auto">
        <div className="relative">
          <div className="flex items-center bg-gray-900 rounded-full h-12 shadow-lg border border-gray-800">
            {/* 左侧：觉察动画 */}
            <div className="ml-3 flex-shrink-0">
              <FloatingAwarenessPlanet
                level={conversationAwareness.overallLevel}
                isAnalyzing={conversationAwareness.isAnalyzing}
                conversationDepth={conversationAwareness.conversationDepth}
                onTogglePanel={() => console.log('觉察动画被点击')}
              />
            </div>
            
            {/* Input field */}
            <input
              ref={inputRef}
              type="text"
              value={inputValue}
              onChange={handleInputChange}
              onKeyPress={handleKeyPress}
              placeholder="询问任何问题"
              className="flex-1 bg-transparent text-white placeholder-gray-400 pl-2 pr-4 py-2 focus:outline-none stellar-body"
              inputMode="text"
              autoComplete="off"
              autoCapitalize="sentences"
              spellCheck="false"
            />

            <div className="flex items-center space-x-2 mr-3">
              {/* Mic Button */}
              <button
                type="button"
                onClick={handleMicClick}
                className={`p-2 rounded-full dialog-transparent-button transition-colors duration-200 ${
                  isRecording ? 'recording' : ''
                }`}
              >
                <Mic className="w-4 h-4" strokeWidth={2} />
              </button>

              {/* Star Button */}
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