import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { createPortal } from 'react-dom';
import { Mic } from 'lucide-react';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import StarRayIcon from './StarRayIcon';

const OracleInput: React.FC = () => {
  const { isAsking, setIsAsking, addStar, pendingStarPosition, isLoading } = useStarStore();
  const [question, setQuestion] = useState('');
  const [isRecording, setIsRecording] = useState(false);
  const [starAnimated, setStarAnimated] = useState(false);
  
  const handleCloseInput = () => {
    if (!isLoading) {
      setIsAsking(false);
    }
  };
  
  const handleMicClick = () => {
    setIsRecording(!isRecording);
    console.log('Microphone clicked, recording:', !isRecording);
    // TODO: 集成语音识别功能
  };

  const handleStarClick = () => {
    setStarAnimated(true);
    console.log('Star ray button clicked');
    
    // 如果有输入内容，直接提交
    if (question.trim()) {
      // 创建一个模拟的表单事件
      const fakeEvent = {
        preventDefault: () => {},
      } as React.FormEvent;
      handleSubmit(fakeEvent);
    }
    
    // Reset animation after completion
    setTimeout(() => {
      setStarAnimated(false);
    }, 1000);
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setQuestion(e.target.value);
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSubmit(e as any);
    }
  };
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!question.trim() || isLoading) return;
    
    playSound('starLight');
    
    try {
      // Close the input modal immediately
      setIsAsking(false);
      
      // Add the star (this will trigger the loading animation)
      await addStar(question);
      
      setQuestion('');
      setTimeout(() => {
        playSound('starReveal');
      }, 1000);
    } catch (error) {
      console.error('Error creating star:', error);
    }
  };
  
  return (
    <>
      {/* Question input modal with new dark input bar design */}
      {createPortal(
        <AnimatePresence>
          {isAsking && (
            <motion.div
              className="fixed inset-0 flex items-center justify-center"
              style={{ zIndex: 999999 }}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            >
              <motion.div
                className="absolute inset-0 bg-black bg-opacity-50 backdrop-blur-sm"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                onClick={handleCloseInput}
              />
              
              <motion.div
                className="w-full max-w-md mx-4 z-10"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: 20 }}
              >
                {/* Title */}
                <h2 className="text-2xl font-heading text-white mb-6 text-center">Ask the Stars</h2>
                
                {/* Dark Input Bar */}
                <form onSubmit={handleSubmit}>
                  <div className="relative">
                    {/* Main container with dark background */}
                    <div className="flex items-center bg-gray-900 rounded-full h-12 shadow-lg border border-gray-800">
                      
                      {/* Input field */}
                      <input
                        type="text"
                        value={question}
                        onChange={handleInputChange}
                        onKeyPress={handleKeyPress}
                        placeholder="What wisdom do you seek from the cosmos?"
                        className="flex-1 bg-transparent text-white placeholder-gray-400 px-4 py-2 focus:outline-none text-sm font-normal"
                        style={{ fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif' }}
                        autoFocus
                        disabled={isLoading}
                      />

                      {/* Right side icons container */}
                      <div className="flex items-center space-x-2 mr-3 oracle-input-buttons">
                        
                        {/* Microphone button - 使用新的CSS类解决iOS灰色背景 */}
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

                        {/* Star ray submit button - 使用新的CSS类解决iOS灰色背景 */}
                        <motion.button
                          type="button"
                          onClick={handleStarClick}
                          className={`p-2 rounded-full dialog-transparent-button transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-500 ${
                            question.trim() 
                              ? 'text-cosmic-accent' 
                              : 'text-gray-300'
                          }`}
                          disabled={isLoading}
                          whileHover={!isLoading ? { scale: 1.1 } : {}}
                        >
                          {isLoading ? (
                            <StarRayIcon 
                              size={16} 
                              animated={true} 
                              iconColor="#ffffff"
                            />
                          ) : (
                            <StarRayIcon 
                              size={16} 
                              animated={starAnimated || !!question.trim()} 
                              iconColor={question.trim() ? "#9333ea" : "#ffffff"}
                            />
                          )}
                        </motion.button>
                        
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
                </form>

                {/* Cancel button */}
                <div className="flex justify-center mt-6">
                  <button
                    type="button"
                    className="cosmic-button px-6 py-2 rounded-full text-white text-sm"
                    onClick={handleCloseInput}
                    disabled={isLoading}
                  >
                    Cancel
                  </button>
                </div>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>,
        document.body
      )}
      
      {/* Loading animation where the star will appear - keep original */}
      <AnimatePresence>
        {isLoading && pendingStarPosition && (
          <motion.div 
            className="absolute z-20 pointer-events-none"
            style={{ 
              left: `${pendingStarPosition.x}%`, 
              top: `${pendingStarPosition.y}%`,
              transform: 'translate(-50%, -50%)'
            }}
            initial={{ opacity: 0, scale: 0.5 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0 }}
          >
            <div className="w-12 h-12 flex items-center justify-center">
              <StarRayIcon size={48} animated={true} className="text-cosmic-accent animate-pulse" />
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
};

export default OracleInput;