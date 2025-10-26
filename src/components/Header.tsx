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
          paddingTop: 'calc(3rem + 20px)', // 48px，在原来24px基础上增加24px，避免被灵动岛遮挡
          paddingBottom: '0.5rem', // 8px底部间距
          // 添加背景，让其延伸到屏幕最顶端实现沉浸效果
          background: 'rgba(0, 0, 0, 0.1)',
          backdropFilter: 'blur(10px)',
          zIndex: 2147483646 // 确保始终位于原生浮层之上，方便点击
        }}
      >
        <div className="flex justify-between items-center h-full">
        {/* 左侧菜单按钮 */}
        <button
          className="p-2 rounded-full dialog-transparent-button transition-colors duration-200"
          onClick={onOpenDrawerMenu}
          title="菜单"
        >
          <Menu className="w-4 h-4" />
        </button>

        {/* 中间标题 */}
        <h1 className="stellar-title text-white flex items-center">
          <span>星谕</span>
          <span className="ml-2 text-xs opacity-70">(StarOracle)</span>
        </h1>

        {/* 右侧logo按钮 */}
        <button
          className="dialog-transparent-button stellar-hit-target transition-colors duration-200"
          onClick={onLogoClick}
          title="集星"
          aria-label="打开星星收藏册"
          data-star-collection-trigger
        >
          <StarRayIcon 
            size={18} 
            animated={false} 
            iconColor="#a855f7"
          />
        </button>
      </div>
    </header>
    </>
  );
};

export default Header;
