import React from 'react';
import { Copy, RotateCcw, ThumbsUp, ThumbsDown, Download } from 'lucide-react';
import { ChatMessage } from '../types/chat';

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
          <div className="whitespace-pre-wrap break-words">
            {message.text}
          </div>
        </div>
        
        {/* AI消息操作按钮 */}
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
        
        <div className="text-xs text-gray-400 mt-1 ml-2">
          {message.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
        </div>
      </div>
    </div>
  );
};

export default AIMessage;