import React, { useState, useEffect, useRef, memo, useMemo } from 'react';
import { motion } from 'framer-motion';
import { Copy, RotateCcw, ThumbsUp, ThumbsDown, Download } from 'lucide-react';
import { Capacitor } from '@capacitor/core';
import { ChatMessage } from '../types/chat';
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

// 将文本内容分离为独立组件，避免动画冲突
const AIMessageContent: React.FC<{ 
  message: ChatMessage;
  onTouchStart: (event: React.TouchEvent) => void;
  onTouchEnd: () => void;
  onTouchCancel: () => void;
  onContextMenu: (event: React.MouseEvent) => void;
}> = memo(({ message, onTouchStart, onTouchEnd, onTouchCancel, onContextMenu }) => {
  console.log(`%c[AIMessageContent] 渲染文本内容`, 'color: #81A1C1', { 
    messageId: message.id,
    isStreaming: message.isStreaming,
    textLength: message.text.length
  });

  const messageRef = useRef<HTMLDivElement>(null);
  
  // 🚀 基于iChatGPT设计的文本处理：优先使用streamingText
  const displayText = useMemo(() => {
    const text = message.streamingText || message.text || '';
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
  }, [message.streamingText, message.text]);
  
  // 🚀 基于iChatGPT的流式状态判断
  const isStreaming = message.isStreaming && !message.isResponse;

  return (
    <div className="py-2 text-white stellar-body">
      {!message.isResponse && !displayText ? (
        // 🚀 基于iChatGPT设计：显示加载状态
        <div className="flex items-center gap-2">
          <div className="flex space-x-1">
            <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0ms' }}></div>
            <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '150ms' }}></div>
            <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '300ms' }}></div>
          </div>
          <span className="text-gray-400 text-sm">Loading...</span>
        </div>
      ) : (
        // 🚀 基于iChatGPT设计：显示消息内容
        <div 
          ref={messageRef}
          className="whitespace-pre-wrap break-words chat-message-content"
          onTouchStart={onTouchStart}
          onTouchEnd={onTouchEnd}
          onTouchCancel={onTouchCancel}
          onContextMenu={onContextMenu}
        >
          {displayText}
          {isStreaming && (
            // 🚀 流式输出时在文字后显示光标（类似iChatGPT）
            <span className="inline-block w-2 h-4 bg-white ml-1 animate-pulse"></span>
          )}
        </div>
      )}
    </div>
  );
}, (prevProps, nextProps) => {
  // 🔧 关键优化：在流式更新过程中，只有在真正需要时才重新渲染文本内容
  const prev = prevProps.message;
  const next = nextProps.message;
  
  // 如果是不同的消息，必须重新渲染
  if (prev.id !== next.id) {
    console.log(`%c[AIMessageContent] 不同消息ID，重新渲染`, 'color: #BF616A');
    return false;
  }
  
  // 如果流式状态变化，需要重新渲染
  if (prev.isStreaming !== next.isStreaming) {
    console.log(`%c[AIMessageContent] 流式状态变化，重新渲染`, 'color: #A3BE8C');
    return false;
  }
  
  // 🔧 关键点：对于流式更新中的消息，允许文本更新但不触发父组件动画
  if (next.isStreaming) {
    const textChanged = prev.text !== next.text;
    if (textChanged) {
      console.log(`%c[AIMessageContent] 流式文本更新，仅更新内容`, 'color: #5E81AC', {
        prevLength: prev.text.length,
        nextLength: next.text.length
      });
      return false; // 允许文本内容更新
    } else {
      console.log(`%c[AIMessageContent] 流式更新中但文本未变化，跳过渲染`, 'color: #5E81AC');
      return true; // 文本没变化，跳过渲染
    }
  }
  
  // 对于已完成的消息，文本相同则跳过渲染
  const textEqual = prev.text === next.text;
  console.log(`%c[AIMessageContent] 完成消息比较`, 'color: #EBCB8B', { textEqual });
  return textEqual;
});

const AIMessage: React.FC<AIMessageProps> = ({ message, userQuestion, onAskFollowUp }) => {
  console.log(`%c[Render] AIMessage ${message.id}`, 'color: #88C0D0', { 
    isStreaming: message.isStreaming, 
    textLength: message.text.length 
  });
  
  const [showAwarenessModal, setShowAwarenessModal] = useState(false);
  const [contextMenu, setContextMenu] = useState({ isVisible: false, x: 0, y: 0 });
  const [longPressTimer, setLongPressTimer] = useState<NodeJS.Timeout | null>(null);
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

  return (
    <div className="flex justify-start mb-4">
      <div className="max-w-[80%]">
        {/* 使用分离的内容组件 */}
        <AIMessageContent
          message={message}
          onTouchStart={handleTouchStart}
          onTouchEnd={handleTouchEnd}
          onTouchCancel={handleTouchEnd}
          onContextMenu={handleContextMenu}
        />
        
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

// 自定义比较函数，用于 React.memo
const areEqual = (prevProps: AIMessageProps, nextProps: AIMessageProps) => {
  // 🔧 修复：在流式更新过程中避免重新渲染，防止重复动画
  
  // 如果是不同的消息，必须重新渲染
  if (prevProps.message.id !== nextProps.message.id) {
    console.log(`%c[AIMessage] 不同消息ID，重新渲染`, 'color: #D08770', {
      prevId: prevProps.message.id,
      nextId: nextProps.message.id
    });
    return false;
  }
  
  // 如果流式状态发生变化（从streaming变为完成），需要重新渲染
  if (prevProps.message.isStreaming !== nextProps.message.isStreaming) {
    console.log(`%c[AIMessage] 流式状态变化，重新渲染`, 'color: #A3BE8C', {
      prevStreaming: prevProps.message.isStreaming,
      nextStreaming: nextProps.message.isStreaming
    });
    return false;
  }
  
  // 如果觉察分析状态变化，需要重新渲染
  if (prevProps.message.awarenessInsight !== nextProps.message.awarenessInsight ||
      prevProps.message.isAnalyzingAwareness !== nextProps.message.isAnalyzingAwareness) {
    console.log(`%c[AIMessage] 觉察状态变化，重新渲染`, 'color: #B48EAD');
    return false;
  }
  
  // 🔧 关键修复：如果消息正在流式输出，不要因为文本内容变化而重新渲染
  // 这可以避免在流式更新过程中触发重复的入场动画
  if (nextProps.message.isStreaming) {
    console.log(`%c[AIMessage] 流式更新中，跳过重新渲染以避免重复动画`, 'color: #5E81AC', {
      messageId: nextProps.message.id,
      textLength: nextProps.message.text.length
    });
    return true; // 不重新渲染
  }
  
  // 对于已完成的消息，如果文本内容完全相同，不重新渲染
  const textEqual = prevProps.message.text === nextProps.message.text;
  console.log(`%c[AIMessage] 完成消息文本比较`, 'color: #EBCB8B', {
    messageId: nextProps.message.id,
    textEqual,
    prevLength: prevProps.message.text.length,
    nextLength: nextProps.message.text.length
  });
  
  return textEqual;
};

const MemoizedAIMessage = memo(AIMessage, areEqual);

// 最终导出的组件，包含动画逻辑
const AnimatedAIMessage: React.FC<AIMessageProps> = (props) => {
  const isNativePlatform = Capacitor.isNativePlatform();

  if (isNativePlatform) {
    return <MemoizedAIMessage {...props} />;
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3, ease: "easeOut" }}
    >
      <MemoizedAIMessage {...props} />
    </motion.div>
  );
};

export default AnimatedAIMessage;