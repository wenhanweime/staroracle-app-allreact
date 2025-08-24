import React, { useState, useRef, useEffect } from 'react';

const FloatingWindow3D = () => {
  const [isFloatingOpen, setIsFloatingOpen] = useState(false);
  const [isDragging, setIsDragging] = useState(false);
  const [dragY, setDragY] = useState(0);
  const [startY, setStartY] = useState(0);
  const [isMinimized, setIsMinimized] = useState(false);
  const floatingRef = useRef(null);

  // 打开浮窗
  const openFloating = () => {
    setIsFloatingOpen(true);
    setIsMinimized(false);
    setDragY(0);
  };

  // 关闭浮窗
  const closeFloating = () => {
    setIsFloatingOpen(false);
    setIsMinimized(false);
    setDragY(0);
  };

  // 处理触摸开始
  const handleTouchStart = (e) => {
    if (!isFloatingOpen) return;
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
      setDragY(Math.min(deltaY, window.innerHeight - 150));
    }
  };

  // 处理触摸结束
  const handleTouchEnd = () => {
    if (!isDragging) return;
    setIsDragging(false);
    
    const screenHeight = window.innerHeight;
    
    // 如果拖拽超过屏幕高度的1/3，最小化到输入框下方
    if (dragY > screenHeight * 0.3) {
      setIsMinimized(true);
      setDragY(screenHeight - 200); // 停留在输入框下方
    } else {
      // 否则回弹到原位置
      setDragY(0);
      setIsMinimized(false);
    }
  };

  // 鼠标事件处理（用于桌面端调试）
  const handleMouseDown = (e) => {
    if (!isFloatingOpen) return;
    setIsDragging(true);
    setStartY(e.clientY);
  };

  const handleMouseMove = (e) => {
    if (!isDragging || !isFloatingOpen) return;
    
    const currentY = e.clientY;
    const deltaY = currentY - startY;
    
    if (deltaY > 0) {
      setDragY(Math.min(deltaY, window.innerHeight - 150));
    }
  };

  const handleMouseUp = () => {
    if (!isDragging) return;
    setIsDragging(false);
    
    const screenHeight = window.innerHeight;
    
    if (dragY > screenHeight * 0.3) {
      setIsMinimized(true);
      setDragY(screenHeight - 200);
    } else {
      setDragY(0);
      setIsMinimized(false);
    }
  };

  // 点击最小化的浮窗重新展开
  const handleMinimizedClick = () => {
    setIsMinimized(false);
    setDragY(0);
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
      {/* 对话界面主体 */}
      <div 
        className={`flex-1 bg-gray-900 flex flex-col transition-all duration-500 ease-out ${
          isFloatingOpen && !isMinimized
            ? 'transform scale-90 translate-y-[-10px]' 
            : 'transform scale-100 translate-y-0'
        }`}
        style={{
          transformStyle: 'preserve-3d',
          perspective: '1000px',
          transform: (isFloatingOpen && !isMinimized)
            ? 'scale(0.9) translateY(-10px) rotateX(3deg)' 
            : 'scale(1) translateY(0px) rotateX(0deg)',
          filter: (isFloatingOpen && !isMinimized) ? 'brightness(0.7)' : 'brightness(1)',
          // 当最小化时，给输入框留出空间
          paddingBottom: isMinimized ? '70px' : '0px'
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
            <span className="text-sm">73%</span>
          </div>
        </div>

        {/* 置顶消息 */}
        <div className="bg-blue-600/20 border-l-4 border-blue-500 p-3 mx-4 mt-4">
          <p className="text-blue-300 text-sm">🛡️ 防骗提示: 不要点击Telegram顶部的任何广告，都...</p>
        </div>

        {/* 聊天消息区域 */}
        <div className="flex-1 p-4 space-y-4 overflow-y-auto">
          {/* Blum Trading Bot 广告 */}
          <div className="bg-gray-700 rounded-lg p-3">
            <div className="flex items-center justify-between mb-2">
              <span className="text-white font-medium">Ad Blum Trading Bot</span>
              <span className="text-blue-400 text-sm cursor-pointer">what's this?</span>
            </div>
            <p className="text-gray-300 text-sm">⚡ Trade faster with Blum Trading Bot. One tap on Telegram, Zero hassle.</p>
          </div>

          {/* 触发浮窗的消息 */}
          <div className="bg-purple-600 rounded-lg p-3 cursor-pointer hover:bg-purple-700 transition-colors" onClick={openFloating}>
            <p className="text-white font-medium">🚀 登录 GMGN 体验秒级交易 👆</p>
            <p className="text-purple-200 text-sm mt-1">点击打开 GMGN 应用</p>
          </div>

          {/* 钱包余额信息 */}
          <div className="space-y-3">
            <div className="bg-gray-700 rounded-lg p-3">
              <div className="flex items-center space-x-2 mb-2">
                <span className="text-yellow-400">📁</span>
                <span className="text-white">Solana: 0.6824 SOL</span>
              </div>
              <p className="text-gray-400 text-xs font-mono break-all mb-2">
                6e80ZamRADndvyhj7dLUw77PKrzaLyYBNUEXyCC7iv
              </p>
              <span className="text-blue-400 text-sm">(点击复制) 交易 Bot</span>
            </div>

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

            <div className="bg-gray-700 rounded-lg p-3">
              <div className="flex items-center space-x-2 mb-2">
                <span className="text-yellow-400">📁</span>
                <span className="text-white">Ethereum: 0 ETH</span>
                <span className="text-orange-400 text-sm">(余额不足, 请充值 👇)</span>
              </div>
              <p className="text-gray-400 text-xs font-mono break-all mb-2">
                0xbda3499bbe9570381e69a8b76fef87fb8f2cf8a5
              </p>
              <span className="text-blue-400 text-sm">(点击复制) 交易 Bot</span>
            </div>
          </div>

          {/* 更多消息填充空间 */}
          <div className="text-gray-500 text-center text-sm py-8">
            ··· 更多消息 ···
          </div>
        </div>

        {/* 对话输入框 */}
        <div className="bg-gray-800 p-4 flex items-center space-x-3">
          <button className="text-blue-400 text-xl">≡</button>
          <button className="text-gray-400 text-xl">📎</button>
          <div className="flex-1 bg-gray-700 rounded-full px-4 py-2">
            <input 
              type="text" 
              placeholder="Message" 
              className="bg-transparent text-white placeholder-gray-400 w-full outline-none"
            />
          </div>
          <button className="text-gray-400 text-xl">🎤</button>
        </div>
      </div>

      {/* 浮窗组件 */}
      {isFloatingOpen && (
        <>
          {/* 遮罩层 */}
          {!isMinimized && (
            <div 
              className="absolute inset-0 bg-black bg-opacity-30 z-40"
              onClick={closeFloating}
            />
          )}

          {/* 浮窗内容 */}
          <div 
            ref={floatingRef}
            className={`fixed bg-gray-900 rounded-t-2xl shadow-2xl z-50 transition-all duration-300 ease-out ${
              isDragging ? '' : 'transition-transform'
            }`}
            style={{
              top: isMinimized ? 'auto' : `${60 + dragY}px`,
              bottom: isMinimized ? '0px' : 'auto',
              left: '0px',
              right: '0px',
              height: isMinimized ? '60px' : `${window.innerHeight - 60 - dragY}px`,
              transform: isMinimized ? 'none' : `translateY(${dragY * 0.1}px)`,
              opacity: isMinimized ? 1 : Math.max(0.8, 1 - dragY / 600),
              cursor: isMinimized ? 'pointer' : isDragging ? 'grabbing' : 'grab'
            }}
            onTouchStart={handleTouchStart}
            onTouchMove={handleTouchMove}
            onTouchEnd={handleTouchEnd}
            onMouseDown={handleMouseDown}
            onClick={isMinimized ? handleMinimizedClick : undefined}
          >
            {isMinimized ? (
              /* 最小化状态 - 显示在输入框下方 */
              <div className="h-full flex items-center justify-between px-4 bg-gray-800 rounded-t-2xl border-t border-gray-700">
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 bg-gradient-to-br from-pink-500 to-purple-600 rounded-lg flex items-center justify-center">
                    <span className="text-white text-sm">🚀</span>
                  </div>
                  <span className="text-white font-medium">GMGN App</span>
                </div>
                <div className="flex items-center space-x-2">
                  <span className="text-gray-400 text-sm">点击展开</span>
                  <button 
                    onClick={(e) => {
                      e.stopPropagation();
                      closeFloating();
                    }}
                    className="text-gray-400 hover:text-white text-xl leading-none"
                  >
                    ×
                  </button>
                </div>
              </div>
            ) : (
              /* 完整展开状态 */
              <>
                {/* 拖拽指示器 */}
                <div className="flex justify-center py-3">
                  <div className="w-10 h-1 bg-gray-600 rounded-full"></div>
                </div>

                {/* 浮窗头部 */}
                <div className="px-4 pb-4">
                  <div className="flex items-center justify-between">
                    <h2 className="text-white text-lg font-bold">gmgn.ai</h2>
                    <button 
                      onClick={closeFloating}
                      className="text-gray-400 hover:text-white text-2xl leading-none"
                    >
                      ×
                    </button>
                  </div>
                </div>

                {/* GMGN App 卡片 */}
                <div className="px-4 pb-4">
                  <div className="bg-gray-800 rounded-xl p-4 flex items-center justify-between">
                    <div className="flex items-center space-x-3">
                      <div className="w-12 h-12 bg-gradient-to-br from-pink-500 to-purple-600 rounded-xl flex items-center justify-center">
                        <span className="text-white text-lg">🚀</span>
                      </div>
                      <div>
                        <h3 className="text-white font-semibold">GMGN App</h3>
                        <p className="text-gray-400 text-sm">更快发现...秒级交易</p>
                      </div>
                    </div>
                    <button className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors">
                      立即体验
                    </button>
                  </div>
                </div>

                {/* 账户余额信息 */}
                <div className="px-4 pb-4">
                  <div className="space-y-3">
                    <div className="bg-gray-800 rounded-lg p-3">
                      <div className="flex items-center justify-between">
                        <span className="text-white">📊 SOL</span>
                        <span className="text-white">0.6824</span>
                      </div>
                    </div>
                  </div>
                </div>

                {/* 返回链接 */}
                <div className="px-4 pb-4">
                  <div className="bg-gray-800 rounded-lg p-3">
                    <p className="text-blue-400 text-sm mb-2">🔗 返回链接</p>
                    <p className="text-gray-400 text-xs break-all">
                      https://t.me/gmgnaibot?start=i_LHcdiHkh (点击复制)
                    </p>
                    <p className="text-gray-400 text-xs break-all mt-1">
                      https://gmgn.ai/?ref=LHcdiHkh (点击复制)
                    </p>
                  </div>
                </div>

                {/* 安全提示 */}
                <div className="px-4 pb-6">
                  <div className="bg-green-900/20 border border-green-700 rounded-lg p-4">
                    <div className="flex items-start space-x-2">
                      <span className="text-green-400 mt-1">🛡️</span>
                      <div>
                        <h4 className="text-green-400 font-medium mb-1">Telegram账号存在被盗风险</h4>
                        <p className="text-gray-300 text-sm">
                          Telegram登录存在被盗和封号风险，请立即绑定邮箱或钱包，为您的资金安全添加防护
                        </p>
                      </div>
                    </div>
                  </div>
                </div>

                {/* 底部按钮 */}
                <div className="px-4 pb-8">
                  <button className="w-full bg-white text-black py-4 rounded-xl font-semibold text-lg hover:bg-gray-100 transition-colors">
                    立即绑定
                  </button>
                </div>
              </>
            )}
          </div>
        </>
      )}
    </div>
  );
};

export default FloatingWindow3D;