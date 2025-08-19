import React, { useState, useRef, useEffect } from 'react';
import { Mic, Plus } from 'lucide-react';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import { triggerHapticFeedback } from '../utils/hapticUtils';
import StarRayIcon from './StarRayIcon';
import { Capacitor } from '@capacitor/core';

interface ConversationDrawerProps {
  isOpen: boolean;
  onToggle: () => void;
}

const ConversationDrawer: React.FC<ConversationDrawerProps> = () => {
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [starAnimated, setStarAnimated] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const { addStar, isAsking } = useStarStore();

  useEffect(() => {
    if (isAsking && inputRef.current) {
      inputRef.current.focus();
    }
  }, [isAsking]);

  const handleAddClick = () => {
    console.log('Add button clicked');
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

  return (
    <div className="fixed bottom-0 left-0 right-0 z-40 p-4" style={{ paddingBottom: `max(1rem, env(safe-area-inset-bottom))` }}>
      <div className="w-full max-w-md mx-auto">
        <div className="relative">
          <div className="flex items-center bg-gray-900 rounded-full h-12 shadow-lg border border-gray-800">
            {/* Plus button - 与目标样式完全对齐 */}
            <button
              type="button"
              onClick={handleAddClick}
              className="flex-shrink-0 w-10 h-10 bg-gray-700 hover:bg-gray-600 rounded-full flex items-center justify-center ml-1 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 focus:ring-offset-gray-900"
              disabled={isLoading}
            >
              <Plus className="w-5 h-5 text-white" strokeWidth={2} />
            </button>

            {/* Input field - 与目标样式完全对齐 */}
            <input
              ref={inputRef}
              type="text"
              value={inputValue}
              onChange={handleInputChange}
              onKeyPress={handleKeyPress}
              placeholder="询问任何问题"
              className="flex-1 bg-transparent text-white placeholder-gray-400 px-4 py-2 focus:outline-none text-sm font-normal"
              style={{ fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif' }}
              disabled={isLoading}
            />

            <div className="flex items-center space-x-2 mr-3">
              {/* 修正点 1: 麦克风按钮 - 使用新的CSS类解决iOS问题 */}
              <button
                type="button"
                onClick={handleMicClick}
                className={`p-2 rounded-full dialog-transparent-button transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-500 ${
                  isRecording 
                    ? 'recording text-white' 
                    : 'text-gray-300'
                }`}
                disabled={isLoading}
              >
                <Mic className="w-4 h-4" strokeWidth={2} />
              </button>

              {/* 修正点 2: 星星按钮 - 使用新的CSS类解决iOS问题 */}
              <button
                type="button"
                onClick={handleStarClick}
                className="p-2 rounded-full dialog-transparent-button text-gray-300 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-500"
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
        </div>
      </div>
    </div>
  );
};

export default ConversationDrawer;