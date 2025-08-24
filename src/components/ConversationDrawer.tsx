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
  onInputFocus?: (inputText?: string) => void; // 修改为可接收输入文本
  showChatHistory?: boolean; // 新增是否显示聊天历史的开关
  followUpQuestion?: string; // 外部传入的后续问题
  onFollowUpProcessed?: () => void; // 后续问题处理完成的回调
  isFloatingAttached?: boolean; // 新增：是否有浮窗吸附状态
}

const ConversationDrawer: React.FC<ConversationDrawerProps> = ({ 
  isOpen, 
  onToggle, 
  onInputFocus,
  showChatHistory = true,
  followUpQuestion, 
  onFollowUpProcessed,
  isFloatingAttached = false // 新增参数
}) => {
  const [inputValue, setInputValue] = useState('');
  const [isRecording, setIsRecording] = useState(false);
  const [starAnimated, setStarAnimated] = useState(false);
  const [keyboardHeight, setKeyboardHeight] = useState(0);
  const [isKeyboardVisible, setIsKeyboardVisible] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  
  const { conversationAwareness } = useChatStore();

  // 移除外部传入后续问题的处理，因为这现在在ChatOverlay中处理
  // useEffect for followUpQuestion removed

  // iOS键盘监听和视口调整
  useEffect(() => {
    if (!isIOS()) return;

    const handleViewportChange = () => {
      const viewport = window.visualViewport;
      if (viewport) {
        const keyboardHeight = window.innerHeight - viewport.height;
        const isVisible = keyboardHeight > 0;
        
        setKeyboardHeight(keyboardHeight);
        setIsKeyboardVisible(isVisible);
        
        // 调试信息
        console.log('Viewport change:', {
          windowHeight: window.innerHeight,
          viewportHeight: viewport.height,
          keyboardHeight,
          isVisible
        });
      }
    };

    // 监听视口变化
    if (window.visualViewport) {
      window.visualViewport.addEventListener('resize', handleViewportChange);
      return () => {
        window.visualViewport?.removeEventListener('resize', handleViewportChange);
      };
    } else {
      // 备用方案：监听窗口resize
      let initialHeight = window.innerHeight;
      const handleResize = () => {
        const currentHeight = window.innerHeight;
        const keyboardHeight = Math.max(0, initialHeight - currentHeight);
        const isVisible = keyboardHeight > 100; // 阈值100px
        
        setKeyboardHeight(keyboardHeight);
        setIsKeyboardVisible(isVisible);
      };
      
      window.addEventListener('resize', handleResize);
      return () => window.removeEventListener('resize', handleResize);
    }
  }, []);

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

  // 发送处理 - 打开对话浮层
  const handleSend = useCallback(async () => {
    if (!inputValue.trim()) return;
    
    // 如果有输入聚焦回调，调用它来打开对话浮层，并传递输入文本
    if (onInputFocus) {
      onInputFocus(inputValue.trim());
    }
    
    // 保持输入框内容，不清空历史输入
    // setInputValue(''); // 移除这行，保持输入内容
    
    console.log('🔍 ConversationDrawer: 准备在ChatOverlay中发送消息');
  }, [inputValue, onInputFocus]);

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSend();
    }
  };

  // iOS专用的输入框点击处理
  const handleInputClick = () => {
    // 移除立即打开浮层的逻辑，只处理iOS键盘聚焦
    if (isIOS() && inputRef.current) {
      // 确保iOS键盘弹起
      inputRef.current.focus();
      // 设置光标到末尾
      setTimeout(() => {
        if (inputRef.current) {
          const length = inputRef.current.value.length;
          inputRef.current.setSelectionRange(length, length);
        }
      }, 100);
    }
  };

  // 计算容器的动态样式
  const getContainerStyle = () => {
    // 根据浮窗吸附状态调整底部空间
    const bottomSpace = isFloatingAttached ? '70px' : `max(1rem, env(safe-area-inset-bottom))`;
    
    const baseStyle = {
      paddingBottom: bottomSpace
    };

    if (isIOS() && isKeyboardVisible && keyboardHeight > 0) {
      // 键盘弹起时，将输入框移动到键盘上方
      return {
        ...baseStyle,
        transform: `translateY(-${keyboardHeight}px)`,
        transition: 'transform 0.25s ease-out'
      };
    }

    return {
      ...baseStyle,
      transform: 'translateY(0)',
      transition: 'transform 0.25s ease-out, padding-bottom 0.25s ease-out' // 添加padding过渡动画
    };
  };

  return (
    <div 
      ref={containerRef}
      className="fixed bottom-0 left-0 right-0 z-50 p-4 keyboard-aware-container pointer-events-none" // 容器本身不接收点击事件
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
              onClick={handleInputClick}
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