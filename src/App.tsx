import React, { useEffect, useState } from 'react';
import ReactDOM from 'react-dom'; // ✨ 1. 导入 ReactDOM 用于 Portal
import { Capacitor } from '@capacitor/core';
import { StatusBar, Style } from '@capacitor/status-bar';
import { SplashScreen } from '@capacitor/splash-screen';
import { Keyboard } from '@capacitor/keyboard';
import StarryBackground from './components/StarryBackground';
import Constellation from './components/Constellation';
import ChatMessages from './components/ChatMessages';
import InspirationCard from './components/InspirationCard';
import StarDetail from './components/StarDetail';
import StarCollection from './components/StarCollection';
import ConstellationSelector from './components/ConstellationSelector';
import AIConfigPanel from './components/AIConfigPanel';
import DrawerMenu from './components/DrawerMenu';
import Header from './components/Header';
import ConversationDrawer from './components/ConversationDrawer';
import ChatOverlay from './components/ChatOverlay'; // 新增对话浮层
import OracleInput from './components/OracleInput';
import { startAmbientSound, stopAmbientSound, playSound } from './utils/soundUtils';
import { triggerHapticFeedback } from './utils/hapticUtils';
import { Menu } from 'lucide-react';
import { useStarStore } from './store/useStarStore';
import { useChatStore } from './store/useChatStore';
import { ConstellationTemplate } from './types';
import { checkApiConfiguration } from './utils/aiTaggingUtils';
import { motion, AnimatePresence } from 'framer-motion';

function App() {
  const [isCollectionOpen, setIsCollectionOpen] = useState(false);
  const [isConfigOpen, setIsConfigOpen] = useState(false);
  const [isTemplateSelectorOpen, setIsTemplateSelectorOpen] = useState(false);
  const [isDrawerMenuOpen, setIsDrawerMenuOpen] = useState(false);
  const [appReady, setAppReady] = useState(false);
  const [pendingFollowUpQuestion, setPendingFollowUpQuestion] = useState<string>(''); // 待处理的后续问题
  const [isChatOverlayOpen, setIsChatOverlayOpen] = useState(false); // 新增对话浮层状态
  const [initialChatInput, setInitialChatInput] = useState<string>(''); // 初始输入内容
  
  const { 
    applyTemplate, 
    currentInspirationCard, 
    dismissInspirationCard 
  } = useStarStore();
  
  const { messages } = useChatStore(); // 获取聊天消息以判断是否有对话历史
  // 处理后续提问的回调
  const handleFollowUpQuestion = (question: string) => {
    console.log('📱 App层接收到后续提问:', question);
    setPendingFollowUpQuestion(question);
    // 如果收到后续问题，打开对话浮层
    if (!isChatOverlayOpen) {
      setIsChatOverlayOpen(true);
    }
  };
  
  // 后续问题处理完成的回调
  const handleFollowUpProcessed = () => {
    console.log('📱 后续问题处理完成，清空pending状态');
    setPendingFollowUpQuestion('');
  };

  // 处理输入框聚焦，打开对话浮层
  const handleInputFocus = (inputText?: string) => {
    console.log('🔍 输入框被聚焦，打开对话浮层', inputText, 'isChatOverlayOpen:', isChatOverlayOpen);
    
    if (inputText) {
      if (isChatOverlayOpen) {
        // 如果浮窗已经打开，直接作为后续问题发送
        console.log('🔄 浮窗已打开，直接发送后续问题:', inputText);
        setPendingFollowUpQuestion(inputText);
      } else {
        // 如果浮窗未打开，设置为初始输入并打开浮窗
        console.log('🔄 浮窗未打开，设置初始输入并打开:', inputText);
        setInitialChatInput(inputText);
        setIsChatOverlayOpen(true);
      }
    } else {
      // 没有输入文本，只是打开浮窗
      setIsChatOverlayOpen(true);
    }
    
    // 立即清空初始输入，确保不重复处理
    setTimeout(() => {
      setInitialChatInput('');
    }, 500);
  };

  // ✨ 新增 handleSendMessage 函数
  // 当用户在输入框中按下发送时，此函数被调用
  const handleSendMessage = (inputText: string) => {
    console.log('🔍 App.tsx: 接收到发送请求，准备打开浮窗', inputText);

    // 只有在发送消息时才设置初始输入并打开浮窗
    if (isChatOverlayOpen) {
      // 如果浮窗已打开，直接作为后续问题发送
      console.log('🔄 浮窗已打开，直接发送后续问题:', inputText);
      setPendingFollowUpQuestion(inputText);
    } else {
      // 如果浮窗未打开，设置为初始输入并打开浮窗
      console.log('🔄 浮窗未打开，设置初始输入并打开:', inputText);
      setInitialChatInput(inputText);
      setIsChatOverlayOpen(true);
    }
  };

  // 关闭对话浮层
  const handleCloseChatOverlay = () => {
    console.log('❌ 关闭对话浮层');
    setIsChatOverlayOpen(false);
    setInitialChatInput(''); // 清空初始输入
  };

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
    // ✨ 2. 添加根容器 div，创建稳定的布局基础
    <div className="w-screen h-screen overflow-hidden bg-black text-gray-100">
      <div 
        className="min-h-screen cosmic-bg overflow-hidden relative transition-all duration-500 ease-out"
        style={{
          transformStyle: 'preserve-3d',
          perspective: '1000px',
          transform: isChatOverlayOpen
            ? 'scale(0.92) translateY(-15px) rotateX(4deg)' 
            : 'scale(1) translateY(0px) rotateX(0deg)',
          filter: isChatOverlayOpen ? 'brightness(0.6)' : 'brightness(1)'
        }}
      >
        {/* Background with stars - 已屏蔽 */}
        {/* {appReady && <StarryBackground starCount={75} />} */}
        
        {/* Header - 现在包含三个元素在一行 */}
        <Header 
          onOpenDrawerMenu={handleOpenDrawerMenu}
          onLogoClick={handleLogoClick}
        />

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
      </div>
      
      {/* ✨ 3. 使用 Portal 将 UI 组件渲染到 body 顶层，完全避免 transform 影响 */}
      {ReactDOM.createPortal(
        <>
          {/* Conversation Drawer - 通过 Portal 直接渲染到 body */}
          <ConversationDrawer 
            isOpen={true} 
            onToggle={() => {}} 
            onSendMessage={handleSendMessage} // ✨ 使用新的回调
            showChatHistory={false}
            isFloatingAttached={!isChatOverlayOpen} // 浮窗关闭时为吸附状态
          />
          
          {/* Chat Overlay - 通过 Portal 直接渲染到 body */}
          <ChatOverlay
            isOpen={isChatOverlayOpen}
            onClose={handleCloseChatOverlay}
            onReopen={() => setIsChatOverlayOpen(true)}
            followUpQuestion={pendingFollowUpQuestion}
            onFollowUpProcessed={handleFollowUpProcessed}
            initialInput={initialChatInput}
            inputBottomSpace={isChatOverlayOpen ? 34 : 70} // 根据浮窗状态传递不同的底部空间
          />
        </>,
        document.body // ✨ 4. 指定渲染目标为 document.body
      )}
    </div>
  );
}

export default App;