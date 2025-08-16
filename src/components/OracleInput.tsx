import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { createPortal } from 'react-dom';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import StarRayIcon from './StarRayIcon';

const OracleInput: React.FC = () => {
  const { isAsking, setIsAsking, addStar, pendingStarPosition, isLoading } = useStarStore();
  const [question, setQuestion] = useState('');
  
  const handleCloseInput = () => {
    if (!isLoading) {
      setIsAsking(false);
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
      {/* Question input modal - 只保留这部分，移除底部按钮 */}
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
              className="cosmic-input rounded-lg p-6 w-full max-w-md mx-4 z-10"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 20 }}
            >
              <h2 className="text-2xl font-heading text-white mb-4 text-center">Ask the Stars</h2>
              
              <form onSubmit={handleSubmit}>
                <div className="mb-4">
                  <textarea
                    className="w-full p-3 bg-cosmic-navy bg-opacity-50 border border-cosmic-purple border-opacity-30 rounded-md text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-cosmic-accent"
                    placeholder="What wisdom do you seek from the cosmos?"
                    rows={3}
                    value={question}
                    onChange={(e) => setQuestion(e.target.value)}
                    autoFocus
                    disabled={isLoading}
                  />
                </div>
                
                <div className="flex justify-between">
                  <button
                    type="button"
                    className="cosmic-button px-4 py-2 rounded-md text-white"
                    onClick={handleCloseInput}
                    disabled={isLoading}
                  >
                    Cancel
                  </button>
                  
                  <motion.button
                    type="submit"
                    className={`cosmic-button rounded-full p-4 flex items-center justify-center ${isLoading ? 'opacity-50 cursor-not-allowed' : ''}`}
                    disabled={isLoading || !question.trim()}
                    whileHover={!isLoading ? { scale: 1.1 } : {}}
                  >
                    {isLoading ? (
                      <StarRayIcon size={24} animated={true} className="text-white animate-pulse" />
                    ) : (
                      <StarRayIcon size={24} animated={!!question.trim()} className="text-white" />
                    )}
                  </motion.button>
                </div>
              </form>
            </motion.div>
          </motion.div>
        )}
        </AnimatePresence>,
        document.body
      )}
      
      {/* Loading animation where the star will appear */}
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