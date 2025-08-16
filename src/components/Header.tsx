import React from 'react';
import StarRayIcon from './StarRayIcon';

const Header: React.FC = () => {
  return (
    <header 
      className="fixed top-0 left-0 right-0 z-30"
      style={{
        paddingTop: `calc(1rem + var(--safe-area-inset-top, 0px))`,
        paddingLeft: `calc(1rem + var(--safe-area-inset-left, 0px))`,
        paddingRight: `calc(1rem + var(--safe-area-inset-right, 0px))`,
        paddingBottom: '1rem',
        height: `calc(4rem + var(--safe-area-inset-top, 0px))` // 固定头部高度
      }}
    >
      <div className="flex justify-center h-full items-center">
        <h1 className="text-xl font-heading text-white flex items-center">
          <StarRayIcon size={18} className="mr-2 text-cosmic-accent" animated={true} />
          <span>星谕</span>
          <span className="ml-2 text-sm opacity-70">(StellOracle)</span>
        </h1>
      </div>
    </header>
  );
};

export default Header;