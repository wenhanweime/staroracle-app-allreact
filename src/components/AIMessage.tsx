import React from 'react';
import { Copy, RotateCcw, ThumbsUp, ThumbsDown, Download } from 'lucide-react';
import { ChatMessage } from '../types/chat';
import StarLoadingAnimation from './StarLoadingAnimation';

interface AIMessageProps {
  message: ChatMessage;
}

const AIMessage: React.FC<AIMessageProps> = ({ message }) => {
  const handleCopy = () => {
    navigator.clipboard.writeText(message.text);
    console.log('Message copied to clipboard');
  };

  const handleRegenerate = () => {
    console.log('Regenerate message');
  };

  const handleThumbsUp = () => {
    console.log('Message liked');
  };

  const handleThumbsDown = () => {
    console.log('Message disliked');
  };

  const handleDownload = () => {
    console.log('Download message');
  };

  return (
    <div className="flex justify-start mb-4">
      <div className="max-w-[80%]">
        <div className="py-2 text-white stellar-body">
          {message.isStreaming && !message.text ? (
            // 显示星星加载动画（当消息为空且正在流式加载时）
            <StarLoadingAnimation size={20} className="py-1" />
          ) : (
            // 显示消息内容
            <div className="whitespace-pre-wrap break-words chat-message-content">
              {message.text}
              {message.isStreaming && message.text && (
                // 流式输出时在文字后显示光标
                <span className="inline-block w-2 h-4 bg-white ml-1 animate-pulse"></span>
              )}
            </div>
          )}
        </div>
        
        {/* AI消息操作按钮 - 只在非流式状态下显示 */}
        {!message.isStreaming && (
          <div className="flex items-center gap-2 mt-2 ml-2">
            <button 
              onClick={handleCopy}
              className="p-1.5 text-gray-400 hover:text-white hover:bg-gray-700 rounded dialog-transparent-button"
              title="复制"
            >
              <Copy className="w-4 h-4" />
            </button>
            
            <button 
              onClick={handleRegenerate}
              className="p-1.5 text-gray-400 hover:text-white hover:bg-gray-700 rounded dialog-transparent-button"
              title="重新生成"
            >
              <RotateCcw className="w-4 h-4" />
            </button>
            
            <button 
              onClick={handleThumbsUp}
              className="p-1.5 text-gray-400 hover:text-white hover:bg-gray-700 rounded dialog-transparent-button"
              title="赞"
            >
              <ThumbsUp className="w-4 h-4" />
            </button>
            
            <button 
              onClick={handleThumbsDown}
              className="p-1.5 text-gray-400 hover:text-white hover:bg-gray-700 rounded dialog-transparent-button"
              title="踩"
            >
              <ThumbsDown className="w-4 h-4" />
            </button>
            
            <button 
              onClick={handleDownload}
              className="p-1.5 text-gray-400 hover:text-white hover:bg-gray-700 rounded dialog-transparent-button"
              title="下载"
            >
              <Download className="w-4 h-4" />
            </button>
          </div>
        )}
        
        {/* 时间戳 - 只在非流式状态下显示 */}
        {!message.isStreaming && (
          <div className="text-xs text-gray-400 mt-1 ml-2">
            {message.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
          </div>
        )}
      </div>
    </div>
  );
};

export default AIMessage;