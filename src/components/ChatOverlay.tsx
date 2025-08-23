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
  followUpQuestion?: string;
  onFollowUpProcessed?: () => void;
  initialInput?: string; // 新增初始输入文本
}

const ChatOverlay: React.FC<ChatOverlayProps> = ({
  isOpen,
  onClose,
  followUpQuestion,
  onFollowUpProcessed,
  initialInput
}) => {
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [starAnimated, setStarAnimated] = useState(false);
  const [keyboardHeight, setKeyboardHeight] = useState(0);
  const [isKeyboardVisible, setIsKeyboardVisible] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  
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

  // 处理初始输入文本
  useEffect(() => {
    if (initialInput && initialInput.trim()) {
      console.log('🔄 ChatOverlay接收到初始输入:', initialInput);
      setInputValue(initialInput);
      
      // 自动发送初始输入
      setTimeout(() => {
        if (!isLoading && !chatIsLoading) {
          sendMessage(initialInput);
          setInputValue('');
        }
      }, 300);
    }
  }, [initialInput, isLoading, chatIsLoading]);

  // 处理外部传入的后续问题
  useEffect(() => {
    if (followUpQuestion && followUpQuestion.trim()) {
      console.log('🔄 ChatOverlay接收到后续问题:', followUpQuestion);
      setInputValue(followUpQuestion);
      
      setTimeout(() => {
        if (!isLoading && !chatIsLoading) {
          sendMessage(followUpQuestion);
          setInputValue('');
          if (onFollowUpProcessed) {
            onFollowUpProcessed();
          }
        }
      }, 200);
    }
  }, [followUpQuestion, isLoading, chatIsLoading, onFollowUpProcessed]);

  // iOS键盘监听
  useEffect(() => {
    if (!isIOS() || !isOpen) return;

    const handleViewportChange = () => {
      const viewport = window.visualViewport;
      if (viewport) {
        const keyboardHeight = window.innerHeight - viewport.height;
        const isVisible = keyboardHeight > 0;
        
        setKeyboardHeight(keyboardHeight);
        setIsKeyboardVisible(isVisible);
      }
    };

    if (window.visualViewport) {
      window.visualViewport.addEventListener('resize', handleViewportChange);
      return () => {
        window.visualViewport?.removeEventListener('resize', handleViewportChange);
      };
    } else {
      let initialHeight = window.innerHeight;
      const handleResize = () => {
        const currentHeight = window.innerHeight;
        const keyboardHeight = Math.max(0, initialHeight - currentHeight);
        const isVisible = keyboardHeight > 100;
        
        setKeyboardHeight(keyboardHeight);
        setIsKeyboardVisible(isVisible);
      };
      
      window.addEventListener('resize', handleResize);
      return () => window.removeEventListener('resize', handleResize);
    }
  }, [isOpen]);

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

  // 发送消息的核心逻辑
  const sendMessage = async (messageText: string) => {
    if (!messageText.trim() || isLoading || chatIsLoading) return;
    
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

  const handleSend = useCallback(async () => {
    if (!inputValue.trim()) return;
    
    const currentInput = inputValue;
    setInputValue('');
    
    await sendMessage(currentInput);
  }, [inputValue]);

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSend();
    }
  };

  const handleInputClick = () => {
    if (isIOS() && inputRef.current) {
      inputRef.current.focus();
      setTimeout(() => {
        if (inputRef.current) {
          const length = inputRef.current.value.length;
          inputRef.current.setSelectionRange(length, length);
        }
      }, 100);
    }
  };

  const getContainerStyle = () => {
    const baseStyle = {
      paddingBottom: `max(1rem, env(safe-area-inset-bottom))`
    };

    if (isIOS() && isKeyboardVisible && keyboardHeight > 0) {
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

  const handleFollowUpQuestion = (question: string) => {
    console.log('📱 ChatOverlay层接收到后续提问:', question);
    setInputValue(question);
    setTimeout(() => {
      if (!isLoading && !chatIsLoading) {
        sendMessage(question);
        setInputValue('');
      }
    }, 200);
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          className="fixed inset-0 z-50 flex flex-col"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          style={{ background: 'rgba(9, 10, 15, 0.95)' }}
        >
          {/* 头部标题栏 */}
          <motion.div
            className="flex items-center justify-between p-4 border-b border-gray-800"
            initial={{ y: -50, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.1 }}
          >
            <h1 className="stellar-title text-white">星谕对话</h1>
            <button
              onClick={onClose}
              className="p-2 rounded-full bg-gray-800 hover:bg-gray-700 transition-colors"
            >
              <X className="w-5 h-5 text-white" />
            </button>
          </motion.div>

          {/* 对话内容区域 */}
          <motion.div
            className="flex-1 overflow-hidden"
            initial={{ y: 50, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.2 }}
          >
            <ChatMessages onAskFollowUp={handleFollowUpQuestion} />
          </motion.div>

          {/* 输入区域 */}
          <motion.div
            ref={containerRef}
            className="p-4 keyboard-aware-container"
            style={getContainerStyle()}
            initial={{ y: 100, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.3 }}
          >
            <div className="w-full max-w-md mx-auto">
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
                      }}
                    />
                  </div>
                  
                  {/* Input field */}
                  <input
                    ref={inputRef}
                    type="text"
                    value={inputValue}
                    onChange={handleInputChange}
                    onKeyPress={handleKeyPress}
                    onClick={handleInputClick}
                    placeholder="继续询问..."
                    className="flex-1 bg-transparent text-white placeholder-gray-400 pl-2 pr-4 py-2 focus:outline-none stellar-body"
                    disabled={isLoading}
                    inputMode="text"
                    autoComplete="off"
                    autoCapitalize="sentences"
                    spellCheck="false"
                  />

                  <div className="flex items-center space-x-2 mr-3">
                    {/* 麦克风按钮 */}
                    <button
                      type="button"
                      onClick={handleMicClick}
                      className={`p-2 rounded-full dialog-transparent-button transition-colors duration-200 ${
                        isRecording ? 'recording' : ''
                      }`}
                      disabled={isLoading}
                    >
                      <Mic className="w-4 h-4" strokeWidth={2} />
                    </button>

                    {/* 星星按钮 */}
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
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};

export default ChatOverlay;