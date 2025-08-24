import React, { useState, useEffect, useRef } from 'react';
import { Copy, RotateCcw, ThumbsUp, ThumbsDown, Download } from 'lucide-react';
import { ChatMessage } from '../types/chat';
import StarLoadingAnimation from './StarLoadingAnimation';
import AwarenessIcon from './AwarenessIcon';
import AwarenessDetailModal from './AwarenessDetailModal';
import MessageContextMenu from './MessageContextMenu';
import { analyzeAwarenessValue } from '../utils/aiTaggingUtils';
import { useChatStore } from '../store/useChatStore';

interface AIMessageProps {
  message: ChatMessage;
  userQuestion?: string; // 对应的用户问题，用于觉察分析
  onAskFollowUp?: (question: string) => void; // 后续提问回调
}

const AIMessage: React.FC<AIMessageProps> = ({ message, userQuestion, onAskFollowUp }) => {
  const [showAwarenessModal, setShowAwarenessModal] = useState(false);
  const [contextMenu, setContextMenu] = useState({ isVisible: false, x: 0, y: 0 });
  const [longPressTimer, setLongPressTimer] = useState<NodeJS.Timeout | null>(null);
  const messageRef = useRef<HTMLDivElement>(null);
  const { startAwarenessAnalysis, completeAwarenessAnalysis } = useChatStore();
  
  // 在消息完成流式输出后，自动进行觉察分析
  useEffect(() => {
    if (!message.isStreaming && 
        message.text && 
        userQuestion && 
        !message.awarenessInsight && 
        !message.isAnalyzingAwareness) {
      
      console.log('🧠 开始对完成的对话进行觉察分析...');
      handleAwarenessAnalysis();
    }
  }, [message.isStreaming, message.text, userQuestion, message.awarenessInsight, message.isAnalyzingAwareness]);
  
  // 执行觉察分析
  const handleAwarenessAnalysis = async () => {
    if (!userQuestion || !message.text) return;
    
    console.log('🔍 触发觉察分析:', { userQuestion, aiResponse: message.text });
    
    // 标记为正在分析
    startAwarenessAnalysis(message.id);
    
    try {
      const insight = await analyzeAwarenessValue(userQuestion, message.text);
      console.log('✅ 觉察分析结果:', insight);
      
      // 完成分析，保存结果
      completeAwarenessAnalysis(message.id, insight);
    } catch (error) {
      console.error('❌ 觉察分析失败:', error);
      // 分析失败时也要取消加载状态
      completeAwarenessAnalysis(message.id, {
        hasInsight: false,
        insightLevel: 'low',
        insightType: '一般对话',
        keyInsights: [],
        emotionalPattern: '无特殊模式',
        suggestedReflection: '可以继续探索其他话题',
        followUpQuestions: []
      });
    }
  };

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
  
  // 长按处理函数
  const handleLongPress = (event: React.TouchEvent | React.MouseEvent) => {
    event.preventDefault();
    const clientX = 'touches' in event ? event.touches[0].clientX : event.clientX;
    const clientY = 'touches' in event ? event.touches[0].clientY : event.clientY;
    
    setContextMenu({
      isVisible: true,
      x: clientX,
      y: clientY
    });
    
    console.log('显示AI消息上下文菜单', { x: clientX, y: clientY });
  };
  
  // 触摸开始
  const handleTouchStart = (event: React.TouchEvent) => {
    const timer = setTimeout(() => {
      handleLongPress(event);
    }, 500); // 500ms长按
    setLongPressTimer(timer);
  };
  
  // 触摸结束或取消
  const handleTouchEnd = () => {
    if (longPressTimer) {
      clearTimeout(longPressTimer);
      setLongPressTimer(null);
    }
  };
  
  // 鼠标右键点击
  const handleContextMenu = (event: React.MouseEvent) => {
    event.preventDefault();
    handleLongPress(event);
  };
  
  // 关闭上下文菜单
  const handleCloseContextMenu = () => {
    setContextMenu({ isVisible: false, x: 0, y: 0 });
  };
  
  // 复制消息
  const handleContextMenuCopy = () => {
    navigator.clipboard.writeText(message.text);
    console.log('通过上下文菜单复制消息');
  };
  
  // 标准化文本格式，统一换行符和段落间距
  const normalizeText = (text: string): string => {
    if (!text) return '';
    
    return text
      // 统一换行符为 \n
      .replace(/\r\n/g, '\n')
      .replace(/\r/g, '\n')
      // 将连续的多个换行符（2个或以上）替换为单个段落分隔符
      .replace(/\n{2,}/g, '\n\n')
      // 移除行首行尾的空白字符，但保留换行结构
      .split('\n')
      .map(line => line.trim())
      .join('\n')
      // 最后清理开头结尾的多余换行
      .replace(/^\n+|\n+$/g, '');
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
            <div 
              ref={messageRef}
              className="whitespace-pre-wrap break-words chat-message-content"
              onTouchStart={handleTouchStart}
              onTouchEnd={handleTouchEnd}
              onTouchCancel={handleTouchEnd}
              onContextMenu={handleContextMenu}
            >
              {normalizeText(message.text)}
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
            {/* 觉察图标 - 显示在所有按钮最前面 */}
            <AwarenessIcon
              level={message.awarenessInsight?.insightLevel || 'low'}
              isActive={message.awarenessInsight?.hasInsight || false}
              isAnalyzing={message.isAnalyzingAwareness || false}
              size={18}
              onClick={() => {
                if (message.awarenessInsight) {
                  setShowAwarenessModal(true);
                }
              }}
            />
            
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
        
        {/* 觉察详情弹窗 */}
        {message.awarenessInsight && (
          <AwarenessDetailModal
            isOpen={showAwarenessModal}
            onClose={() => setShowAwarenessModal(false)}
            insight={message.awarenessInsight}
            onAskFollowUp={(question) => {
              if (onAskFollowUp) {
                onAskFollowUp(question);
              }
            }}
          />
        )}
        
        {/* 时间戳 - 只在非流式状态下显示 */}
        {!message.isStreaming && (
          <div className="text-xs text-gray-400 mt-1 ml-2">
            {message.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
          </div>
        )}
        
        {/* 上下文菜单 */}
        <MessageContextMenu
          isVisible={contextMenu.isVisible}
          position={{ x: contextMenu.x, y: contextMenu.y }}
          messageText={message.text}
          onClose={handleCloseContextMenu}
          onCopy={handleContextMenuCopy}
        />
      </div>
    </div>
  );
};

export default AIMessage;