import React, { useState, useRef, useEffect } from 'react';
import { Mic } from 'lucide-react';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import { triggerHapticFeedback } from '../utils/hapticUtils';
import StarRayIcon from './StarRayIcon';
import { Capacitor } from '@capacitor/core';

// iOS设备检测
const isIOS = () => {
  return /iPad|iPhone|iPod/.test(navigator.userAgent) || 
         (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
};

interface ConversationDrawerProps {
  isOpen: boolean;
  onToggle: () => void;
}

const ConversationDrawer: React.FC<ConversationDrawerProps> = () => {
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [starAnimated, setStarAnimated] = useState(false);
  const [keyboardHeight, setKeyboardHeight] = useState(0);
  const [isKeyboardVisible, setIsKeyboardVisible] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const { addStar, isAsking } = useStarStore();

  useEffect(() => {
    if (isAsking && inputRef.current) {
      inputRef.current.focus();
    }
  }, [isAsking]);

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

  const handleSend = async () => {
    if (!inputValue.trim() || isLoading) return;
    setIsLoading(true);
    const trimmedQuestion = inputValue.trim();
    setInputValue('');
    try {
      const newStar = await addStar(trimmedQuestion);
      console.log("✨ 新星星已创建:", newStar.id);
      playSound('starReveal');
    } catch (error) {
      console.error('Error creating star:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSend();
    }
  };

  // iOS专用的输入框点击处理
  const handleInputClick = () => {
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
    const baseStyle = {
      paddingBottom: `max(1rem, env(safe-area-inset-bottom))`
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
      transition: 'transform 0.25s ease-out'
    };
  };

  return (
    <div 
      ref={containerRef}
      className="fixed bottom-0 left-0 right-0 z-40 p-4 keyboard-aware-container" 
      style={getContainerStyle()}
    >
      <div className="w-full max-w-md mx-auto">
        <div className="relative">
          <div className="flex items-center bg-gray-900 rounded-full h-12 shadow-lg border border-gray-800">
            {/* Input field - 与目标样式完全对齐 */}
            <input
              ref={inputRef}
              type="text"
              value={inputValue}
              onChange={handleInputChange}
              onKeyPress={handleKeyPress}
              onClick={handleInputClick}
              placeholder="询问任何问题"
              className="flex-1 bg-transparent text-white placeholder-gray-400 px-4 py-2 focus:outline-none stellar-body"
              disabled={isLoading}
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
                disabled={isLoading}
              >
                <Mic className="w-4 h-4" strokeWidth={2} />
              </button>

              {/* 修正点 2: 星星按钮 - 使用新的CSS类解决iOS问题 */}
              <button
                type="button"
                onClick={handleStarClick}
                className="p-2 rounded-full dialog-transparent-button transition-colors duration-200"
                disabled={isLoading}
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