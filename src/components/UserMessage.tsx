import React from 'react';
import { ChatMessage } from '../types/chat';

interface UserMessageProps {
  message: ChatMessage;
}

const UserMessage: React.FC<UserMessageProps> = ({ message }) => {
  return (
    <div className="flex justify-end mb-4">
      <div className="max-w-[80%]">
        <div className="px-4 py-2 rounded-2xl bg-gray-700 text-white stellar-body">
          <div className="whitespace-pre-wrap break-words">
            {message.text}
          </div>
        </div>
        <div className="text-xs text-gray-400 mt-1 text-right">
          {message.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
        </div>
      </div>
    </div>
  );
};

export default UserMessage;