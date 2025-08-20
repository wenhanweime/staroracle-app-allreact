import React from 'react';
import StarRayIcon from './StarRayIcon';
import { Menu } from 'lucide-react';

interface HeaderProps {
  onOpenDrawerMenu: () => void;
  onLogoClick: () => void;
}

const Header: React.FC<HeaderProps> = ({ onOpenDrawerMenu, onLogoClick }) => {
  return (
    <>      
      <header 
        className="fixed top-0 left-0 right-0 z-50"
        style={{
          paddingLeft: `calc(1rem + var(--safe-area-inset-left, 0px))`,
          paddingRight: `calc(1rem + var(--safe-area-inset-right, 0px))`,
          // 使用与DrawerMenu相同的简单padding策略，但增加一个标题高度的距离
          paddingTop: '3rem', // 48px，在原来24px基础上增加24px，避免被灵动岛遮挡
          paddingBottom: '0.5rem', // 8px底部间距
          // 添加背景，让其延伸到屏幕最顶端实现沉浸效果
          background: 'rgba(0, 0, 0, 0.1)',
          backdropFilter: 'blur(10px)'
        }}
      >
        <div className="flex justify-between items-center h-full">
        {/* 左侧菜单按钮 */}
        <button
          className="cosmic-button rounded-full p-2 flex items-center justify-center"
          onClick={onOpenDrawerMenu}
          title="菜单"
        >
          <Menu className="w-4 h-4 text-white" />
        </button>

        {/* 中间标题 */}
        <h1 className="text-lg font-heading text-white flex items-center">
          <StarRayIcon size={16} className="mr-2 text-cosmic-accent" animated={true} />
          <span>星谕</span>
          <span className="ml-2 text-xs opacity-70">(StellOracle)</span>
        </h1>

        {/* 右侧logo按钮 */}
        <button
          className="cosmic-button rounded-full p-2 flex items-center justify-center"
          onClick={onLogoClick}
          title="星座收藏"
        >
          <div className="text-lg bg-gradient-to-r from-blue-400 to-cyan-400 bg-clip-text text-transparent filter drop-shadow-lg hover:rotate-45 transition-transform duration-300">
            ✦
          </div>
        </button>
      </div>
    </header>
    </>
  );
};

export default Header;