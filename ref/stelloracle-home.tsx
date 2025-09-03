import React, { useState, useEffect, useRef, useLayoutEffect } from 'react';

const StellOracleHome = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isCollectionOpen, setIsCollectionOpen] = useState(false);
  const [stars, setStars] = useState([]);
  const [inputBottomSpace, setInputBottomSpace] = useState(0);
  const chatInputRef = useRef<HTMLDivElement>(null);

  // 创建星空背景
  useEffect(() => {
    const createStars = () => {
      const starArray = [];
      for (let i = 0; i < 100; i++) {
        starArray.push({
          id: i,
          left: Math.random() * 100,
          top: Math.random() * 100,
          delay: Math.random() * 3,
          duration: Math.random() * 3 + 2
        });
      }
      setStars(starArray);
    };
    createStars();
  }, []);

  // 测量输入框位置
  useLayoutEffect(() => {
    if (chatInputRef.current) {
      const rect = chatInputRef.current.getBoundingClientRect();
      const bottomSpace = window.innerHeight - rect.bottom;
      setInputBottomSpace(bottomSpace);
      console.log(`Measured input bottom space: ${bottomSpace}`);
    }
  }, []);

  const toggleMenu = () => {
    setIsMenuOpen(!isMenuOpen);
  };

  const handleLogoClick = () => {
    setIsCollectionOpen(true);
    console.log('打开 Star Collection 页面');
  };

  const MenuIcon = ({ className = "" }) => (
    <svg className={className} width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <line x1="3" y1="6" x2="21" y2="6"></line>
      <line x1="3" y1="12" x2="21" y2="12"></line>
      <line x1="3" y1="18" x2="21" y2="18"></line>
    </svg>
  );

  const SearchIcon = ({ className = "", size = 16 }) => (
    <svg className={className} width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <circle cx="11" cy="11" r="8"></circle>
      <path d="m21 21-4.35-4.35"></path>
    </svg>
  );

  const HashIcon = ({ className = "" }) => (
    <svg className={className} width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <line x1="4" y1="9" x2="20" y2="9"></line>
      <line x1="4" y1="15" x2="20" y2="15"></line>
      <line x1="10" y1="3" x2="8" y2="21"></line>
      <line x1="16" y1="3" x2="14" y2="21"></line>
    </svg>
  );

  const UsersIcon = ({ className = "" }) => (
    <svg className={className} width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path>
      <circle cx="9" cy="7" r="4"></circle>
      <path d="M22 21v-2a4 4 0 0 0-3-3.87"></path>
      <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
    </svg>
  );

  const PackageIcon = ({ className = "" }) => (
    <svg className={className} width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <line x1="16.5" y1="9.4" x2="7.5" y2="4.21"></line>
      <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path>
      <polyline points="3.27,6.96 12,12.01 20.73,6.96"></polyline>
      <line x1="12" y1="22.08" x2="12" y2="12"></line>
    </svg>
  );

  const MapPinIcon = ({ className = "" }) => (
    <svg className={className} width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
      <circle cx="12" cy="10" r="3"></circle>
    </svg>
  );

  const FilterIcon = ({ className = "" }) => (
    <svg className={className} width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <polygon points="22,3 2,3 10,12.46 10,19 14,21 14,12.46"></polygon>
    </svg>
  );

  const DownloadIcon = ({ className = "" }) => (
    <svg className={className} width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
      <polyline points="7,10 12,15 17,10"></polyline>
      <line x1="12" y1="15" x2="12" y2="3"></line>
    </svg>
  );

  const CloseIcon = ({ className = "" }) => (
    <svg className={className} width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <line x1="18" y1="6" x2="6" y2="18"></line>
      <line x1="6" y1="6" x2="18" y2="18"></line>
    </svg>
  );

  const StarIcon = ({ className = "" }) => (
    <svg className={className} width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <polygon points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26"></polygon>
    </svg>
  );

  // 菜单项配置
  const menuItems = [
    { icon: SearchIcon, label: '所有项目', active: true },
    { icon: PackageIcon, label: '记忆', count: 0 },
    { icon: MenuIcon, label: '待办事项', count: 0 },
    { icon: HashIcon, label: '智能标签', count: 9, section: '资料库' },
    { icon: UsersIcon, label: '人物', count: 0 },
    { icon: PackageIcon, label: '事物', count: 0 },
    { icon: MapPinIcon, label: '地点', count: 0 },
    { icon: FilterIcon, label: '类型' },
    { icon: DownloadIcon, label: '导入', hasArrow: true }
  ];

  const ChevronRightIcon = ({ className = "" }) => (
    <svg className={className} width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <polyline points="9,18 15,12 9,6"></polyline>
    </svg>
  );

  // Star Collection 页面的星座收藏数据
  const starCollections = [
    { id: 1, name: '白羊座', date: '3.21 - 4.19', stars: 4, color: 'from-red-400 to-pink-500' },
    { id: 2, name: '金牛座', date: '4.20 - 5.20', stars: 5, color: 'from-green-400 to-emerald-500' },
    { id: 3, name: '双子座', date: '5.21 - 6.21', stars: 3, color: 'from-yellow-400 to-orange-500' },
    { id: 4, name: '巨蟹座', date: '6.22 - 7.22', stars: 5, color: 'from-blue-400 to-cyan-500' },
    { id: 5, name: '狮子座', date: '7.23 - 8.22', stars: 4, color: 'from-purple-400 to-pink-500' },
    { id: 6, name: '处女座', date: '8.23 - 9.22', stars: 3, color: 'from-indigo-400 to-purple-500' }
  ];

  return (
    <div className="relative w-full h-screen bg-gradient-to-br from-blue-900 via-purple-900 to-cyan-400 overflow-hidden text-white font-sans">
      {/* 星空背景 */}
      <div className="fixed inset-0 pointer-events-none">
        {stars.map(star => (
          <div
            key={star.id}
            className="absolute w-0.5 h-0.5 bg-white rounded-full animate-pulse"
            style={{
              left: `${star.left}%`,
              top: `${star.top}%`,
              animationDelay: `${star.delay}s`,
              animationDuration: `${star.duration}s`
            }}
          />
        ))}
      </div>

      {/* 手机框架 */}
      <div className="w-[375px] h-[812px] mx-auto mt-5 bg-black rounded-[40px] p-2 shadow-2xl">
        <div className="w-full h-full bg-gradient-to-br from-gray-900 to-blue-900 rounded-[32px] relative overflow-hidden flex flex-col">
          
          {/* 状态栏 */}
          <div className="flex justify-between items-center px-5 py-3 text-base font-semibold">
            <div className="text-[17px]">03:10</div>
            <div className="flex items-center gap-1.5">
              <div className="flex gap-0.5">
                {[4, 6, 8, 10].map((height, i) => (
                  <div key={i} className={`w-0.5 bg-white rounded-sm`} style={{height: `${height}px`}} />
                ))}
              </div>
              <div className="text-base">📶</div>
              <div className="w-6 h-3 border border-white rounded-sm relative">
                <div className="h-full w-4/5 bg-white rounded-sm" />
                <div className="absolute -right-0.5 top-0.5 w-0.5 h-1.5 bg-white rounded-r-sm" />
              </div>
            </div>
          </div>

          {/* 顶部导航 */}
          <div className="flex justify-between items-center px-6 py-5">
            {/* 左侧菜单按钮 */}
            <button
              onClick={toggleMenu}
              className="w-11 h-11 rounded-full bg-transparent flex items-center justify-center transition-all duration-300 hover:bg-white/10 active:scale-95"
            >
              <MenuIcon className="opacity-80" />
            </button>

            {/* 中间标题 */}
            <div className="text-center">
              <div className="text-[22px] font-semibold tracking-wide">星谕</div>
              <div className="text-[11px] opacity-60 tracking-widest -mt-0.5">STELLORACLE</div>
            </div>

            {/* 右侧Logo按钮 */}
            <button
              onClick={handleLogoClick}
              className="w-11 h-11 rounded-full bg-transparent flex items-center justify-center transition-all duration-300 hover:bg-white/10 active:scale-95"
            >
              <div className="text-3xl bg-gradient-to-r from-blue-400 to-cyan-400 bg-clip-text text-transparent filter drop-shadow-lg hover:rotate-45 transition-transform duration-300">
                ✦
              </div>
            </button>
          </div>

          {/* 主内容区域 */}
          <div className="flex-1 flex items-center justify-center px-6 text-center">
            <div>
              <div className="text-5xl mb-6 opacity-80 animate-bounce">✨</div>
              <div className="text-2xl font-light leading-relaxed opacity-90 max-w-[280px]">
                探索星辰的奥秘<br />
                开启你的占星之旅
              </div>
            </div>
          </div>

          {/* 底部对话抽屉 */}
          <div ref={chatInputRef} className="bg-black/60 backdrop-blur-xl rounded-t-2xl px-5 pt-4 pb-8">
            <div className="w-9 h-1 bg-white/30 rounded-full mx-auto mb-4" />
            <div className="text-[13px] text-white/60 mb-2 font-medium">与星谕对话</div>
            <div className="flex items-center gap-3">
              <button className="w-8 h-8 bg-white/10 rounded-lg flex items-center justify-center text-base hover:bg-white/20 transition-all">
                +
              </button>
              <button className="w-8 h-8 bg-white/10 rounded-lg flex items-center justify-center text-base hover:bg-white/20 transition-all">
                ☰
              </button>
              <div className="flex-1 h-8 px-3 text-[15px] text-white/60 cursor-pointer">
                询问任何问题...
              </div>
              <button className="w-9 h-9 bg-white/15 rounded-full flex items-center justify-center text-base hover:bg-blue-400/30 transition-all">
                🎙
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* 左侧抽屉菜单 */}
      {isMenuOpen && (
        <div className="fixed inset-0 z-50 flex">
          {/* 抽屉内容 */}
          <div className="w-80 bg-gradient-to-b from-gray-100 to-gray-50 h-full shadow-2xl transform transition-transform duration-300 ease-out">
          
          {/* 背景遮罩 */}
          <div 
            className="flex-1 bg-black/50 backdrop-blur-sm"
            onClick={() => setIsMenuOpen(false)}
          />
            {/* 抽屉顶部 */}
            <div className="px-5 py-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <div className="text-xl font-semibold text-gray-800">22:26 📞</div>
                <div className="flex items-center gap-2 text-gray-600">
                  <div className="text-lg">📶</div>
                  <div className="text-lg">📶</div>
                  <div className="bg-gray-800 text-white px-2 py-0.5 rounded text-sm">45</div>
                </div>
              </div>
            </div>

            {/* 搜索栏 */}
            <div className="px-5 py-4 border-b border-gray-200">
              <div className="relative">
                <SearchIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
                <input
                  type="text"
                  placeholder="搜索"
                  className="w-full pl-10 pr-4 py-2 bg-gray-100 rounded-lg text-gray-700 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-400"
                />
              </div>
            </div>

            {/* 菜单项列表 */}
            <div className="flex-1 overflow-y-auto">
              {menuItems.map((item, index) => {
                const IconComponent = item.icon;
                return (
                  <div key={index}>
                    {/* 分组标题 */}
                    {item.section && (
                      <div className="px-5 py-3 text-xs text-gray-400 font-medium tracking-wide uppercase">
                        {item.section}
                      </div>
                    )}
                    
                    {/* 菜单项 */}
                    <div 
                      className={`flex items-center justify-between px-5 py-4 cursor-pointer transition-colors ${
                        item.active 
                          ? 'bg-blue-500 text-white' 
                          : 'text-gray-700 hover:bg-gray-100'
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <div className={item.active ? 'text-white' : 'text-gray-600'}>
                          <IconComponent />
                        </div>
                        <span className="font-medium">{item.label}</span>
                      </div>
                      
                      <div className="flex items-center gap-2">
                        {typeof item.count === 'number' && (
                          <span className={`text-sm ${
                            item.active ? 'text-white/80' : 'text-gray-400'
                          }`}>
                            {item.count}
                          </span>
                        )}
                        {item.hasArrow && (
                          <ChevronRightIcon className="text-gray-400" />
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* 底部用户信息 */}
            <div className="px-5 py-4 border-t border-gray-200 bg-white">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 bg-yellow-200 rounded-full flex items-center justify-center text-sm">
                  &gt;_&lt;
                </div>
                <div className="flex-1">
                  <div className="font-medium text-gray-800">wei wenhan</div>
                </div>
                <button className="p-1">
                  <div className="w-1 h-1 bg-gray-400 rounded-full mb-0.5"></div>
                  <div className="w-1 h-1 bg-gray-400 rounded-full mb-0.5"></div>
                  <div className="w-1 h-1 bg-gray-400 rounded-full"></div>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Star Collection 页面 */}
      {isCollectionOpen && (
        <div className="fixed inset-0 z-50 bg-gradient-to-br from-indigo-900 via-purple-900 to-pink-800">
          {/* 星空背景 */}
          <div className="absolute inset-0 pointer-events-none">
            {stars.map(star => (
              <div
                key={`collection-${star.id}`}
                className="absolute w-0.5 h-0.5 bg-white rounded-full animate-pulse"
                style={{
                  left: `${star.left}%`,
                  top: `${star.top}%`,
                  animationDelay: `${star.delay}s`,
                  animationDuration: `${star.duration}s`
                }}
              />
            ))}
          </div>

          {/* 手机框架 */}
          <div className="w-[375px] h-[812px] mx-auto mt-5 bg-black rounded-[40px] p-2 shadow-2xl">
            <div className="w-full h-full bg-gradient-to-br from-gray-900 to-indigo-900 rounded-[32px] relative overflow-hidden flex flex-col">
              
              {/* 状态栏 */}
              <div className="flex justify-between items-center px-5 py-3 text-base font-semibold">
                <div className="text-[17px]">03:10</div>
                <div className="flex items-center gap-1.5">
                  <div className="flex gap-0.5">
                    {[4, 6, 8, 10].map((height, i) => (
                      <div key={i} className={`w-0.5 bg-white rounded-sm`} style={{height: `${height}px`}} />
                    ))}
                  </div>
                  <div className="text-base">📶</div>
                  <div className="w-6 h-3 border border-white rounded-sm relative">
                    <div className="h-full w-4/5 bg-white rounded-sm" />
                    <div className="absolute -right-0.5 top-0.5 w-0.5 h-1.5 bg-white rounded-r-sm" />
                  </div>
                </div>
              </div>

              {/* 顶部导航 */}
              <div className="flex justify-between items-center px-6 py-5">
                <button
                  onClick={() => setIsCollectionOpen(false)}
                  className="w-11 h-11 rounded-full bg-transparent flex items-center justify-center transition-all duration-300 hover:bg-white/10 active:scale-95"
                >
                  <CloseIcon className="opacity-80" />
                </button>

                <div className="text-center">
                  <div className="text-[22px] font-semibold tracking-wide">星座收藏</div>
                  <div className="text-[11px] opacity-60 tracking-widest -mt-0.5">STAR COLLECTION</div>
                </div>

                <div className="w-11 h-11"></div>
              </div>

              {/* 收藏内容 */}
              <div className="flex-1 px-6 py-4 overflow-y-auto">
                <div className="space-y-4">
                  {starCollections.map(collection => (
                    <div key={collection.id} className="bg-white/5 backdrop-blur-sm rounded-2xl p-4 border border-white/10 hover:bg-white/10 transition-all duration-300">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-4">
                          <div className={`w-12 h-12 rounded-full bg-gradient-to-r ${collection.color} flex items-center justify-center`}>
                            <div className="text-white text-xl">✨</div>
                          </div>
                          <div>
                            <div className="text-lg font-semibold text-white">{collection.name}</div>
                            <div className="text-sm text-white/60">{collection.date}</div>
                          </div>
                        </div>
                        <div className="flex items-center gap-2">
                          <div className="flex">
                            {Array.from({ length: 5 }, (_, i) => (
                              <StarIcon 
                                key={i}
                                className={`w-4 h-4 ${
                                  i < collection.stars 
                                    ? 'text-yellow-400 fill-yellow-400' 
                                    : 'text-white/20'
                                }`}
                              />
                            ))}
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>

                {/* 添加新收藏按钮 */}
                <div className="mt-6">
                  <button className="w-full py-4 border-2 border-dashed border-white/30 rounded-2xl text-white/60 hover:border-white/50 hover:text-white/80 transition-all duration-300 flex items-center justify-center gap-2">
                    <div className="text-2xl">+</div>
                    <span>添加新的星座收藏</span>
                  </button>
                </div>
              </div>

              {/* 底部统计 */}
              <div className="px-6 py-4 border-t border-white/10 bg-black/20">
                <div className="flex justify-between items-center text-sm">
                  <span className="text-white/60">总收藏</span>
                  <span className="text-white font-semibold">{starCollections.length} 个星座</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default StellOracleHome;