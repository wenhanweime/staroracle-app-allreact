import React, { useState } from 'react';
import { Plus, Mic } from 'lucide-react';

// Star Ray Icon Component with animation
const StarRayIcon = ({ size = 20, animated = false, iconColor = "#ffffff" }) => {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className="star-ray-icon"
    >
      {/* Center circle */}
      {animated ? (
        <circle
          cx="12"
          cy="12"
          r="2"
          fill={iconColor}
          className="animate-pulse"
        />
      ) : (
        <circle cx="12" cy="12" r="2" fill={iconColor} />
      )}
      
      {/* Eight rays */}
      {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => {
        const angle = (i * 45) * (Math.PI / 180); // Convert to radians
        const startX = 12 + Math.cos(angle) * 3;
        const startY = 12 + Math.sin(angle) * 3;
        const endX = 12 + Math.cos(angle) * 8;
        const endY = 12 + Math.sin(angle) * 8;
        
        return animated ? (
          <line
            key={i}
            x1={startX}
            y1={startY}
            x2={endX}
            y2={endY}
            stroke={iconColor}
            strokeWidth="2"
            strokeLinecap="round"
            className="animate-ray"
            style={{
              animation: `rayExpand 0.5s ease-out ${0.1 + i * 0.05}s both`,
              transformOrigin: '12px 12px'
            }}
          />
        ) : (
          <line
            key={i}
            x1={startX}
            y1={startY}
            x2={endX}
            y2={endY}
            stroke={iconColor}
            strokeWidth="2"
            strokeLinecap="round"
          />
        );
      })}
      
      {/* CSS Animation styles */}
      <style jsx>{`
        @keyframes rayExpand {
          0% {
            stroke-dasharray: 5;
            stroke-dashoffset: 5;
          }
          100% {
            stroke-dasharray: 5;
            stroke-dashoffset: 0;
          }
        }
        .animate-ray {
          stroke-dasharray: 5;
          stroke-dashoffset: 0;
        }
      `}</style>
    </svg>
  );
};

const DarkInputBar = () => {
  const [inputValue, setInputValue] = useState('');
  const [isRecording, setIsRecording] = useState(false);
  const [starAnimated, setStarAnimated] = useState(false);

  const handleAddClick = () => {
    console.log('Add button clicked');
  };

  const handleMicClick = () => {
    setIsRecording(!isRecording);
    console.log('Microphone clicked, recording:', !isRecording);
  };

  const handleStarClick = () => {
    setStarAnimated(true);
    console.log('Star ray button clicked');
    
    // Reset animation after completion
    setTimeout(() => {
      setStarAnimated(false);
    }, 1000);
  };

  const handleInputChange = (e) => {
    setInputValue(e.target.value);
  };

  const handleSubmit = () => {
    if (inputValue.trim()) {
      console.log('Submitted:', inputValue);
      setInputValue('');
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter') {
      handleSubmit();
    }
  };

  return (
    <div className="w-full max-w-md mx-auto p-4">
      <div className="relative">
        {/* Main container with dark background */}
        <div className="flex items-center bg-gray-900 rounded-full h-12 shadow-lg border border-gray-800">
          
          {/* Plus button - positioned flush left */}
          <button
            type="button"
            onClick={handleAddClick}
            className="flex-shrink-0 w-10 h-10 bg-gray-700 hover:bg-gray-600 rounded-full flex items-center justify-center ml-1 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 focus:ring-offset-gray-900"
          >
            <Plus className="w-5 h-5 text-white" strokeWidth={2} />
          </button>

          {/* Input field */}
          <input
            type="text"
            value={inputValue}
            onChange={handleInputChange}
            onKeyPress={handleKeyPress}
            placeholder="询问任何问题"
            className="flex-1 bg-transparent text-white placeholder-gray-400 px-4 py-2 focus:outline-none text-sm font-normal"
            style={{ fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif' }}
          />

          {/* Right side icons container */}
          <div className="flex items-center space-x-2 mr-3">
            
            {/* Microphone button */}
            <button
              type="button"
              onClick={handleMicClick}
              className={`p-2 rounded-full transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-500 ${
                isRecording 
                  ? 'bg-red-600 hover:bg-red-500 text-white' 
                  : 'hover:bg-gray-700 text-gray-300'
              }`}
            >
              <Mic className="w-4 h-4" strokeWidth={2} />
            </button>

            {/* Star ray button */}
            <button
              type="button"
              onClick={handleStarClick}
              className="p-2 rounded-full hover:bg-gray-700 text-gray-300 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-500"
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
      </form>

      {/* Demo instructions */}
      <div className="mt-8 text-gray-400 text-sm space-y-2">
        <p className="font-medium">Interactive Features:</p>
        <ul className="space-y-1 text-xs">
          <li>• Plus button: Add new conversation</li>
          <li>• Microphone: Toggle voice recording (red when active)</li>
          <li>• Star rays: Animated star with expanding rays on click/input</li>
          <li>• Enter to submit text input</li>
          <li>• Star animates when typing or clicking</li>
        </ul>
      </div>
    </div>
  );
};

export default DarkInputBar;