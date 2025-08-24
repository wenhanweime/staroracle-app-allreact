import React, { useState, useRef, useEffect } from 'react';

const FloatingWindow3D = () => {
  const [isFloatingOpen, setIsFloatingOpen] = useState(false);
  const [isDragging, setIsDragging] = useState(false);
  const [dragY, setDragY] = useState(0);
  const [startY, setStartY] = useState(0);
  const [inputMessage, setInputMessage] = useState('');
  const [floatingInputMessage, setFloatingInputMessage] = useState('');
  const [messages, setMessages] = useState([
    {
      id: 1,
      type: 'system',
      content: '防骗提示: 不要点击Telegram顶部的任何广告，都...',
      timestamp: '15:06'
    },
    {
      id: 2,
      type: 'ad',
      content: 'Ad Blum Trading Bot - Trade faster with Blum Trading Bot. One tap on Telegram, Zero hassle.',
      timestamp: '15:07'
    },
    {
      id: 3,
      type: 'bot',
      content: '📁 Solana: 0.6824 SOL\n6e80ZamRADndvyhj7dLUw77PKrzaLyYBNUEXyCC7iv\n(点击复制) 交易 Bot',
      timestamp: '15:07'
    }
  ]);
  
  // 浮窗中的对话消息
  const [floatingMessages, setFloatingMessages] = useState([]);
  
  const floatingRef = useRef(null);

  // 主界面发送消息处理
  const handleSendMessage = () => {
    if (!inputMessage.trim()) return;
    
    const newMessage = {
      id: messages.length + 1,
      type: 'user',
      content: inputMessage,
      timestamp: '15:08'
    };
    
    setMessages(prev => [...prev, newMessage]);
    
    // 同时在浮窗中也显示这条消息
    const floatingMessage = {
      id: floatingMessages.length + 1,
      type: 'user',
      content: inputMessage,
      timestamp: '15:08'
    };
    setFloatingMessages(prev => [...prev, floatingMessage]);
    
    setInputMessage('');
    
    // 延迟一点打开浮窗
    setTimeout(() => {
      setIsFloatingOpen(true);
      setDragY(0);
      // 浮窗打开后模拟一个回复
      setTimeout(() => {
        const botReply = {
          id: floatingMessages.length + 2,
          type: 'bot',
          content: `收到您的消息："${inputMessage}"，正在为您处理相关操作...`,
          timestamp: '15:08'
        };
        setFloatingMessages(prev => [...prev, botReply]);
      }, 1000);
    }, 300);
  };

  // 浮窗内发送消息处理
  const handleFloatingSendMessage = () => {
    if (!floatingInputMessage.trim()) return;
    
    const newMessage = {
      id: floatingMessages.length + 1,
      type: 'user',
      content: floatingInputMessage,
      timestamp: '15:08'
    };
    
    setFloatingMessages(prev => [...prev, newMessage]);
    setFloatingInputMessage('');
    
    // 模拟机器人回复
    setTimeout(() => {
      const botReply = {
        id: floatingMessages.length + 2,
        type: 'bot',
        content: `好的，我理解您说的"${floatingInputMessage}"，让我为您查询相关信息...`,
        timestamp: '15:08'
      };
      setFloatingMessages(prev => [...prev, botReply]);
    }, 1000);
  };

  // 关闭浮窗
  const closeFloating = () => {
    setIsFloatingOpen(false);
    setDragY(0);
  };

  // 处理触摸开始
  const handleTouchStart = (e) => {
    if (!isFloatingOpen) return;
    // 只有点击头部拖拽区域才允许拖拽
    const target = e.target.closest('.drag-handle');
    if (!target) return;
    
    setIsDragging(true);
    setStartY(e.touches[0].clientY);
  };

  // 处理触摸移动
  const handleTouchMove = (e) => {
    if (!isDragging || !isFloatingOpen) return;
    
    const currentY = e.touches[0].clientY;
    const deltaY = currentY - startY;
    
    // 只允许向下拖拽
    if (deltaY > 0) {
      setDragY(Math.min(deltaY, window.innerHeight * 0.8));
    }
  };

  // 处理触摸结束
  const handleTouchEnd = () => {
    if (!isDragging) return;
    setIsDragging(false);
    
    const screenHeight = window.innerHeight;
    
    // 如果拖拽超过屏幕高度的1/2，关闭浮窗
    if (dragY > screenHeight * 0.4) {
      closeFloating();
    } else {
      // 否则回弹到原位置
      setDragY(0);
    }
  };

  // 鼠标事件处理（用于桌面端调试）
  const handleMouseDown = (e) => {
    if (!isFloatingOpen) return;
    const target = e.target.closest('.drag-handle');
    if (!target) return;
    
    setIsDragging(true);
    setStartY(e.clientY);
  };

  const handleMouseMove = (e) => {
    if (!isDragging || !isFloatingOpen) return;
    
    const currentY = e.clientY;
    const deltaY = currentY - startY;
    
    if (deltaY > 0) {
      setDragY(Math.min(deltaY, window.innerHeight * 0.8));
    }
  };

  const handleMouseUp = () => {
    if (!isDragging) return;
    setIsDragging(false);
    
    const screenHeight = window.innerHeight;
    
    if (dragY > screenHeight * 0.4) {
      closeFloating();
    } else {
      setDragY(0);
    }
  };

  // 处理键盘回车发送
  const handleKeyPress = (e, isFloating = false) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      if (isFloating) {
        handleFloatingSendMessage();
      } else {
        handleSendMessage();
      }
    }
  };

  // 添加全局鼠标事件监听
  useEffect(() => {
    if (isDragging) {
      document.addEventListener('mousemove', handleMouseMove);
      document.addEventListener('mouseup', handleMouseUp);
      
      return () => {
        document.removeEventListener('mousemove', handleMouseMove);
        document.removeEventListener('mouseup', handleMouseUp);
      };
    }
  }, [isDragging, startY, dragY]);

  return (
    <div className="h-screen bg-black relative overflow-hidden flex flex-col">
      {/* 对话界面主体 - 保持原位置不动 */}
      <div 
        className={`flex-1 bg-gray-900 flex flex-col transition-all duration-500 ease-out`}
        style={{
          transformStyle: 'preserve-3d',
          perspective: '1000px',
          transform: isFloatingOpen
            ? 'scale(0.92) translateY(-15px) rotateX(4deg)' 
            : 'scale(1) translateY(0px) rotateX(0deg)',
          filter: isFloatingOpen ? 'brightness(0.6)' : 'brightness(1)'
        }}
      >
        {/* 顶部状态栏 */}
        <div className="flex justify-between items-center p-4 text-white bg-gray-800">
          <div className="flex items-center space-x-2">
            <button className="text-blue-400">← 47</button>
          </div>
          <div className="text-center">
            <h1 className="text-white text-lg font-bold">GMGN.AI</h1>
            <p className="text-gray-400 text-xs">68,922 monthly users</p>
          </div>
          <div className="flex items-center space-x-2">
            <span className="text-sm">15:08</span>
            <span className="text-sm">📶</span>
            <span className="text-sm">73%</span>
          </div>
        </div>

        {/* 聊天消息区域 */}
        <div className="flex-1 p-4 space-y-4 overflow-y-auto">
          {messages.map((message) => (
            <div key={message.id} className={`${
              message.type === 'system' ? 'bg-blue-600/20 border-l-4 border-blue-500' :
              message.type === 'ad' ? 'bg-gray-700' :
              message.type === 'bot' ? 'bg-gray-700' :
              'bg-green-600 ml-12'
            } rounded-lg p-3`}>
              {message.type === 'system' && (
                <p className="text-blue-300 text-sm">🛡️ {message.content}</p>
              )}
              {message.type === 'ad' && (
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-white font-medium">Ad Blum Trading Bot</span>
                    <span className="text-blue-400 text-sm cursor-pointer">what's this?</span>
                  </div>
                  <p className="text-gray-300 text-sm">⚡ {message.content}</p>
                </div>
              )}
              {message.type === 'bot' && (
                <div className="text-white">
                  {message.content.split('\n').map((line, index) => (
                    <p key={index} className={`${
                      index === 0 ? 'text-white mb-2' : 
                      index === 1 ? 'text-gray-400 text-xs font-mono break-all mb-2' :
                      'text-blue-400 text-sm'
                    }`}>
                      {line}
                    </p>
                  ))}
                </div>
              )}
              {message.type === 'user' && (
                <div className="text-white">
                  <p className="text-sm">{message.content}</p>
                  <p className="text-xs text-green-200 mt-1">{message.timestamp}</p>
                </div>
              )}
            </div>
          ))}

          {/* 钱包余额信息 */}
          <div className="space-y-3">
            <div className="bg-gray-700 rounded-lg p-3">
              <div className="flex items-center space-x-2 mb-2">
                <span className="text-yellow-400">📁</span>
                <span className="text-white">Base: 0 ETH</span>
                <span className="text-orange-400 text-sm">(余额不足, 请充值 👇)</span>
              </div>
              <p className="text-gray-400 text-xs font-mono break-all mb-2">
                0xbda3499bbe9570381e69a8b76fef87fb8f2cf8a5
              </p>
              <span className="text-blue-400 text-sm">(点击复制) 交易 Bot</span>
            </div>
          </div>
        </div>

        {/* 主界面输入框 - 保持原位置 */}
        <div className="bg-gray-800 p-4 flex items-center space-x-3">
          <button className="text-blue-400 text-xl">≡</button>
          <button className="text-gray-400 text-xl">📎</button>
          <div className="flex-1 bg-gray-700 rounded-full px-4 py-2 flex items-center space-x-2">
            <input 
              type="text" 
              placeholder="Message" 
              value={inputMessage}
              onChange={(e) => setInputMessage(e.target.value)}
              onKeyPress={(e) => handleKeyPress(e, false)}
              className="bg-transparent text-white placeholder-gray-400 w-full outline-none"
            />
            {inputMessage.trim() && (
              <button
                onClick={handleSendMessage}
                className="bg-blue-600 hover:bg-blue-700 text-white rounded-full w-8 h-8 flex items-center justify-center text-sm transition-colors"
              >
                →
              </button>
            )}
          </div>
          <button className="text-gray-400 text-xl">🎤</button>
        </div>
      </div>

      {/* 浮窗组件 */}
      {isFloatingOpen && (
        <>
          {/* 遮罩层 */}
          <div 
            className="fixed inset-0 bg-black bg-opacity-40 z-40"
            onClick={closeFloating}
          />

          {/* 浮窗内容 */}
          <div 
            ref={floatingRef}
            className={`fixed bg-gray-900 rounded-t-2xl shadow-2xl z-50 transition-all duration-300 ease-out ${
              isDragging ? '' : 'transition-transform'
            }`}
            style={{
              top: `${Math.max(80, 80 + dragY)}px`,
              left: '0px',
              right: '0px',
              bottom: '0px',
              transform: `translateY(${dragY * 0.15}px)`,
              opacity: Math.max(0.7, 1 - dragY / 500)
            }}
            onTouchStart={handleTouchStart}
            onTouchMove={handleTouchMove}
            onTouchEnd={handleTouchEnd}
            onMouseDown={handleMouseDown}
          >
            {/* 拖拽指示器和头部 */}
            <div className="drag-handle cursor-grab active:cursor-grabbing">
              <div className="flex justify-center py-4">
                <div className="w-12 h-1.5 bg-gray-600 rounded-full"></div>
              </div>
              
              <div className="px-4 pb-4">
                <div className="flex items-center justify-between">
                  <h2 className="text-white text-xl font-bold">GMGN 智能助手</h2>
                  <button 
                    onClick={closeFloating}
                    className="text-gray-400 hover:text-white text-2xl leading-none w-8 h-8 flex items-center justify-center"
                  >
                    ×
                  </button>
                </div>
                <p className="text-gray-400 text-sm mt-1">在这里继续您的对话</p>
              </div>
            </div>

            {/* 浮窗对话区域 */}
            <div className="flex-1 flex flex-col" style={{ height: 'calc(100% - 140px)' }}>
              {/* 消息列表 */}
              <div className="flex-1 px-4 pb-4 space-y-3 overflow-y-auto">
                {floatingMessages.length === 0 ? (
                  <div className="text-center text-gray-500 py-8">
                    <div className="text-4xl mb-4">🤖</div>
                    <p className="text-lg font-medium mb-2">欢迎使用GMGN智能助手</p>
                    <p className="text-sm">我可以帮您处理交易、查询信息等操作</p>
                  </div>
                ) : (
                  floatingMessages.map((message) => (
                    <div key={message.id} className={`flex ${message.type === 'user' ? 'justify-end' : 'justify-start'}`}>
                      <div className={`max-w-[80%] rounded-2xl px-4 py-3 ${
                        message.type === 'user' 
                          ? 'bg-blue-600 text-white' 
                          : 'bg-gray-700 text-gray-100'
                      }`}>
                        <p className="text-sm">{message.content}</p>
                        <p className="text-xs opacity-70 mt-1">{message.timestamp}</p>
                      </div>
                    </div>
                  ))
                )}
              </div>

              {/* 浮窗输入框 */}
              <div className="px-4 pb-4 bg-gray-900 border-t border-gray-700">
                <div className="flex items-center space-x-3 pt-4">
                  <button className="text-gray-400 text-xl">📎</button>
                  <div className="flex-1 bg-gray-800 rounded-full px-4 py-3 flex items-center space-x-2">
                    <input 
                      type="text" 
                      placeholder="在浮窗中继续对话..." 
                      value={floatingInputMessage}
                      onChange={(e) => setFloatingInputMessage(e.target.value)}
                      onKeyPress={(e) => handleKeyPress(e, true)}
                      className="bg-transparent text-white placeholder-gray-400 w-full outline-none text-sm"
                    />
                    {floatingInputMessage.trim() && (
                      <button
                        onClick={handleFloatingSendMessage}
                        className="bg-blue-600 hover:bg-blue-700 text-white rounded-full w-8 h-8 flex items-center justify-center text-sm transition-colors"
                      >
                        →
                      </button>
                    )}
                  </div>
                  <button className="text-gray-400 text-xl">🎤</button>
                </div>
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
};

export default FloatingWindow3D;