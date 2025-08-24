import React, { useState, useEffect, useRef } from 'react';
import { Copy, Download, Share } from 'lucide-react';

interface MessageContextMenuProps {
  isVisible: boolean;
  position: { x: number; y: number };
  messageText: string;
  onClose: () => void;
  onCopy: () => void;
}

const MessageContextMenu: React.FC<MessageContextMenuProps> = ({
  isVisible,
  position,
  messageText,
  onClose,
  onCopy
}) => {
  const menuRef = useRef<HTMLDivElement>(null);

  // 点击外部关闭菜单
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        onClose();
      }
    };

    if (isVisible) {
      document.addEventListener('mousedown', handleClickOutside);
      document.addEventListener('touchstart', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      document.removeEventListener('touchstart', handleClickOutside);
    };
  }, [isVisible, onClose]);

  if (!isVisible) return null;

  const handleCopyClick = () => {
    onCopy();
    onClose();
  };

  const handleSelectText = () => {
    // 临时创建一个可选择的元素来复制文本
    const textArea = document.createElement('textarea');
    textArea.value = messageText;
    document.body.appendChild(textArea);
    textArea.select();
    document.execCommand('copy');
    document.body.removeChild(textArea);
    onClose();
  };

  return (
    <>
      {/* 背景遮罩 */}
      <div className="fixed inset-0 z-[9999] bg-black bg-opacity-20" />
      
      {/* 菜单内容 */}
      <div
        ref={menuRef}
        className="fixed z-[10000] bg-gray-800 rounded-lg shadow-2xl border border-gray-600 py-2 min-w-[180px]"
        style={{
          left: Math.min(position.x, window.innerWidth - 200),
          top: Math.max(20, Math.min(position.y, window.innerHeight - 150)),
        }}
      >
        <button
          onClick={handleSelectText}
          className="flex items-center gap-3 w-full px-4 py-3 text-left text-white hover:bg-gray-700 transition-colors stellar-body"
        >
          <Copy className="w-4 h-4" />
          复制文本
        </button>
        
        <button
          onClick={handleCopyClick}
          className="flex items-center gap-3 w-full px-4 py-3 text-left text-white hover:bg-gray-700 transition-colors stellar-body"
        >
          <Download className="w-4 h-4" />
          复制消息
        </button>
        
        <button
          onClick={() => {
            // TODO: 实现分享功能
            onClose();
          }}
          className="flex items-center gap-3 w-full px-4 py-3 text-left text-gray-400 hover:bg-gray-700 transition-colors stellar-body"
        >
          <Share className="w-4 h-4" />
          分享 (待实现)
        </button>
      </div>
    </>
  );
};

export default MessageContextMenu;