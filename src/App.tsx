import React, { useEffect, useState } from 'react';
import { Capacitor } from '@capacitor/core';
import { StatusBar, Style } from '@capacitor/status-bar';
import { SplashScreen } from '@capacitor/splash-screen';
import { Keyboard } from '@capacitor/keyboard';
import StarryBackground from './components/StarryBackground';
import Constellation from './components/Constellation';
import InspirationCard from './components/InspirationCard';
import StarDetail from './components/StarDetail';
import StarCollection from './components/StarCollection';
import ConstellationSelector from './components/ConstellationSelector';
import AIConfigPanel from './components/AIConfigPanel';
import DrawerMenu from './components/DrawerMenu';
import Header from './components/Header';
import ConversationDrawer from './components/ConversationDrawer';
import OracleInput from './components/OracleInput';
import { startAmbientSound, stopAmbientSound, playSound } from './utils/soundUtils';
import { triggerHapticFeedback } from './utils/hapticUtils';
import { Menu } from 'lucide-react';
import { useStarStore } from './store/useStarStore';
import { ConstellationTemplate } from './types';
import { checkApiConfiguration } from './utils/aiTaggingUtils';
import { motion, AnimatePresence } from 'framer-motion';

function App() {
  const [isCollectionOpen, setIsCollectionOpen] = useState(false);
  const [isConfigOpen, setIsConfigOpen] = useState(false);
  const [isTemplateSelectorOpen, setIsTemplateSelectorOpen] = useState(false);
  const [isDrawerMenuOpen, setIsDrawerMenuOpen] = useState(false);
  const [appReady, setAppReady] = useState(false);
  const { 
    applyTemplate, 
    currentInspirationCard, 
    dismissInspirationCard 
  } = useStarStore();

  // 添加原生平台效果（只在原生环境下执行）
  useEffect(() => {
    const setupNative = async () => {
      if (Capacitor.isNativePlatform()) {
        // 设置状态栏为暗色模式，文字为亮色
        await StatusBar.setStyle({ style: Style.Dark });
        
        // 标记应用准备就绪
        setAppReady(true);
        
        // 延迟隐藏启动屏，让应用完全加载
        setTimeout(async () => {
          await SplashScreen.hide({
            fadeOutDuration: 300
          });
        }, 500);
      } else {
        // Web环境立即设置为准备就绪
        setAppReady(true);
      }
    };
    setupNative();
  }, []);

  // 检查API配置（静默模式 - 只在控制台提示）
  useEffect(() => {
    // 延迟检查，确保应用已完全加载
    const timer = setTimeout(() => {
      const isConfigValid = checkApiConfiguration();
      // 移除UI警告，改为静默模式
      // setShowApiWarning(!isConfigValid);
      
      if (!isConfigValid) {
        console.warn('⚠️ API配置无效或不完整，请配置API以使用完整功能');
        console.info('💡 点击右上角设置图标进行API配置');
      } else {
        console.log('✅ API配置正常');
      }
    }, 2000);
    
    return () => clearTimeout(timer);
  }, []);

  // 监控灵感卡片状态变化（保持Web版本逻辑）
  useEffect(() => {
    console.log('🃏 灵感卡片状态变化:', currentInspirationCard ? '显示' : '隐藏');
    if (currentInspirationCard) {
      console.log('📝 当前卡片问题:', currentInspirationCard.question);
    }
  }, [currentInspirationCard]);

  // Start ambient sound when user interacts（延迟到用户交互后）
  useEffect(() => {
    const handleFirstInteraction = () => {
      startAmbientSound();
      document.removeEventListener('touchstart', handleFirstInteraction);
      document.removeEventListener('click', handleFirstInteraction);
    };
    
    document.addEventListener('touchstart', handleFirstInteraction);
    document.addEventListener('click', handleFirstInteraction);
    
    return () => {
      document.removeEventListener('touchstart', handleFirstInteraction);
      document.removeEventListener('click', handleFirstInteraction);
      stopAmbientSound();
    };
  }, []);

  const handleOpenCollection = () => {
    console.log('🔍 Collection button clicked - handleOpenCollection triggered!');
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('light');
    }
    playSound('starLight');
    setIsCollectionOpen(true);
  };

  const handleCloseCollection = () => {
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('light');
    }
    setIsCollectionOpen(false);
  };

  const handleOpenConfig = () => {
    console.log('⚙️ Settings button clicked - handleOpenConfig triggered!');
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('medium');
    }
    playSound('starClick');
    setIsConfigOpen(true);
  };

  const handleCloseConfig = () => {
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('light');
    }
    setIsConfigOpen(false);
    // 静默模式：移除配置检查和UI提示
  };

  const handleOpenDrawerMenu = () => {
    console.log('🍔 Menu button clicked - handleOpenDrawerMenu triggered!');
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('light');
    }
    playSound('starClick');
    setIsDrawerMenuOpen(true);
  };

  const handleCloseDrawerMenu = () => {
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('light');
    }
    setIsDrawerMenuOpen(false);
  };

  const handleLogoClick = () => {
    console.log('✦ Logo button clicked - opening StarCollection!');
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('light');
    }
    playSound('starLight');
    setIsCollectionOpen(true);
  };

  const handleOpenTemplateSelector = () => {
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('light');
    }
    playSound('starClick');
    setIsTemplateSelectorOpen(true);
  };

  const handleCloseTemplateSelector = () => {
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('light');
    }
    setIsTemplateSelectorOpen(false);
  };

  const handleSelectTemplate = (template: ConstellationTemplate) => {
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('success');
    }
    applyTemplate(template);
    playSound('starReveal');
  };
  
  return (
    <div className="min-h-screen cosmic-bg overflow-hidden relative">
      {/* Background with stars - 延迟渲染 */}
      {appReady && <StarryBackground starCount={75} />}
      
      {/* Header */}
      <Header />
      
      {/* Left side menu button - 避免与Header重叠 */}
      <div 
        className="fixed z-50"
        style={{
          top: `calc(5rem + var(--safe-area-inset-top, 0px))`, // Header高度4rem + 1rem间距
          left: `calc(1rem + var(--safe-area-inset-left, 0px))`
        }}
      >
        <button
          className="cosmic-button rounded-full p-3 flex items-center justify-center"
          onClick={handleOpenDrawerMenu}
          title="菜单"
        >
          <Menu className="w-5 h-5 text-white" />
        </button>
      </div>

      {/* Right side logo button - 避免与Header重叠 */}
      <div 
        className="fixed z-50"
        style={{
          top: `calc(5rem + var(--safe-area-inset-top, 0px))`, // Header高度4rem + 1rem间距
          right: `calc(1rem + var(--safe-area-inset-right, 0px))`
        }}
      >
        <button
          className="cosmic-button rounded-full p-3 flex items-center justify-center"
          onClick={handleLogoClick}
          title="星座收藏"
        >
          <div className="text-xl bg-gradient-to-r from-blue-400 to-cyan-400 bg-clip-text text-transparent filter drop-shadow-lg hover:rotate-45 transition-transform duration-300">
            ✦
          </div>
        </button>
      </div>

      {/* User's constellation - 延迟渲染 */}
      {appReady && <Constellation />}
      
      {/* Inspiration card */}
      {currentInspirationCard && (
        <InspirationCard
          card={currentInspirationCard}
          onDismiss={dismissInspirationCard}
        />
      )}
      
      {/* Star detail modal */}
      {appReady && <StarDetail />}
      
      {/* Star collection modal */}
      <StarCollection 
        isOpen={isCollectionOpen} 
        onClose={handleCloseCollection} 
      />

      {/* Template selector modal */}
      <ConstellationSelector
        isOpen={isTemplateSelectorOpen}
        onClose={handleCloseTemplateSelector}
        onSelectTemplate={handleSelectTemplate}
      />

      {/* AI Configuration Panel */}
      <AIConfigPanel
        isOpen={isConfigOpen}
        onClose={handleCloseConfig}
      />

      {/* Drawer Menu */}
      <DrawerMenu
        isOpen={isDrawerMenuOpen}
        onClose={handleCloseDrawerMenu}
        onOpenSettings={handleOpenConfig}
        onOpenTemplateSelector={handleOpenTemplateSelector}
      />

      {/* Oracle Input for star creation */}
      <OracleInput />

      {/* Conversation Drawer */}
      <ConversationDrawer isOpen={true} onToggle={() => {}} />
    </div>
  );
}

export default App;