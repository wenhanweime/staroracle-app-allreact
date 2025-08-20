import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Settings, 
  X, 
  Search, 
  Package, 
  Hash, 
  Users, 
  MapPin, 
  Filter, 
  Download, 
  ChevronRight 
} from 'lucide-react';

interface DrawerMenuProps {
  isOpen: boolean;
  onClose: () => void;
  onOpenSettings: () => void;
}

const DrawerMenu: React.FC<DrawerMenuProps> = ({ isOpen, onClose, onOpenSettings }) => {
  // 菜单项配置（基于demo的设计）
  const menuItems = [
    { icon: Search, label: '所有项目', active: true },
    { icon: Package, label: '记忆', count: 0 },
    { icon: Hash, label: '智能标签', count: 9, section: '资料库' },
    { icon: Users, label: '人物', count: 0 },
    { icon: Package, label: '事物', count: 0 },
    { icon: MapPin, label: '地点', count: 0 },
    { icon: Filter, label: '类型' },
    { 
      icon: Settings, 
      label: 'AI配置', 
      hasArrow: true,
      onClick: () => {
        onOpenSettings();
        onClose();
      }
    },
    { icon: Download, label: '导入', hasArrow: true }
  ];

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-50 flex">
          {/* 抽屉内容 */}
          <motion.div
            initial={{ x: -320 }}
            animate={{ x: 0 }}
            exit={{ x: -320 }}
            transition={{ type: "spring", damping: 25, stiffness: 200 }}
            className="w-80 bg-gradient-to-b from-gray-100 to-gray-50 h-full shadow-2xl"
          >
            {/* 抽屉顶部 */}
            <div className="px-5 py-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <div className="text-xl font-semibold text-gray-800">星谕菜单</div>
                <button
                  onClick={onClose}
                  className="w-8 h-8 rounded-full bg-gray-200 flex items-center justify-center hover:bg-gray-300 transition-colors"
                >
                  <X className="w-5 h-5 text-gray-600" />
                </button>
              </div>
            </div>

            {/* 搜索栏 */}
            <div className="px-5 py-4 border-b border-gray-200">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
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
                      onClick={item.onClick}
                    >
                      <div className="flex items-center gap-3">
                        <div className={item.active ? 'text-white' : 'text-gray-600'}>
                          <IconComponent className="w-5 h-5" />
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
                          <ChevronRight className="w-4 h-4 text-gray-400" />
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
                <div className="w-8 h-8 bg-gradient-to-r from-blue-400 to-cyan-400 rounded-full flex items-center justify-center text-white text-sm font-bold">
                  ✦
                </div>
                <div className="flex-1">
                  <div className="font-medium text-gray-800">星谕用户</div>
                  <div className="text-xs text-gray-500">探索星辰的奥秘</div>
                </div>
              </div>
            </div>
          </motion.div>

          {/* 背景遮罩 */}
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="flex-1 bg-black/50 backdrop-blur-sm"
            onClick={onClose}
          />
        </div>
      )}
    </AnimatePresence>
  );
};

export default DrawerMenu;