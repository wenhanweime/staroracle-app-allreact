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
import ChatOverlay from './components/ChatOverlay'; // React版本（Web端回退）
import OracleInput from './components/OracleInput';
import { startAmbientSound, stopAmbientSound, playSound } from './utils/soundUtils';
import { triggerHapticFeedback } from './utils/hapticUtils';
import { Menu } from 'lucide-react';
import { useStarStore } from './store/useStarStore';
import { useChatStore } from './store/useChatStore';
import { ConstellationTemplate } from './types';
import { checkApiConfiguration, generateAIResponse } from './utils/aiTaggingUtils';
import { motion, AnimatePresence } from 'framer-motion';
import { useNativeChatOverlay } from './hooks/useNativeChatOverlay';

function App() {
  const [isCollectionOpen, setIsCollectionOpen] = useState(false);
  const [isConfigOpen, setIsConfigOpen] = useState(false);
  const [isTemplateSelectorOpen, setIsTemplateSelectorOpen] = useState(false);
  const [isDrawerMenuOpen, setIsDrawerMenuOpen] = useState(false);
  const [appReady, setAppReady] = useState(false);
  
  // ✨ 原生ChatOverlay Hook
  const nativeChatOverlay = useNativeChatOverlay();
  
  // 兼容性：Web端仍使用React状态
  const [webChatOverlayOpen, setWebChatOverlayOpen] = useState(false);
  const [pendingFollowUpQuestion, setPendingFollowUpQuestion] = useState<string>('');
  const [initialChatInput, setInitialChatInput] = useState<string>('');
  
  // 🔧 现在开启原生模式，ChatOverlay插件已修复
  const forceWebMode = false; // 设为false开启原生模式
  const isNative = forceWebMode ? false : Capacitor.isNativePlatform();
  const isChatOverlayOpen = isNative ? nativeChatOverlay.isOpen : webChatOverlayOpen;
  
  const { 
    applyTemplate, 
    currentInspirationCard, 
    dismissInspirationCard 
  } = useStarStore();
  
  const { messages, addUserMessage, addStreamingAIMessage, updateStreamingMessage, finalizeStreamingMessage, setLoading, generateConversationTitle } = useChatStore(); // 获取聊天消息以判断是否有对话历史
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
        if (isNative) {
          nativeChatOverlay.showOverlay(true);
        } else {
          setWebChatOverlayOpen(true);
        }
      }
    } else {
      // 没有输入文本，只是打开浮窗
      if (isNative) {
        nativeChatOverlay.showOverlay(true);
      } else {
        setWebChatOverlayOpen(true);
      }
    }
    
    // 立即清空初始输入，确保不重复处理
    setTimeout(() => {
      setInitialChatInput('');
    }, 500);
  };

  // ✨ 重构 handleSendMessage 支持原生和Web模式
  const handleSendMessage = async (inputText: string) => {
    console.log('🔍 App.tsx: 接收到发送请求', inputText, '原生模式:', isNative);

    if (isNative) {
      // 原生模式：直接使用ChatStore处理消息，然后同步到原生浮窗
      console.log('📱 原生模式，使用ChatStore处理消息');
      
      // 先确保浮窗打开
      if (!nativeChatOverlay.isOpen) {
        console.log('📱 原生浮窗未打开，先打开浮窗');
        await nativeChatOverlay.showOverlay(true);
        await new Promise(resolve => setTimeout(resolve, 300)); // 等待浮窗完全打开
      }
      
      // 添加用户消息到store
      addUserMessage(inputText);
      setLoading(true);
      
      try {
        // 调用AI API
        const messageId = addStreamingAIMessage('');
        let streamingText = '';
        
        const onStream = (chunk: string) => {
          streamingText += chunk;
          updateStreamingMessage(messageId, streamingText);
        };

        // 获取对话历史（需要获取最新的messages）
        const conversationHistory = messages.map(msg => ({
          role: msg.isUser ? 'user' as const : 'assistant' as const,
          content: msg.text
        }));

        const aiResponse = await generateAIResponse(
          inputText, 
          undefined, 
          onStream,
          conversationHistory
        );
        
        if (streamingText !== aiResponse) {
          updateStreamingMessage(messageId, aiResponse);
        }
        
        finalizeStreamingMessage(messageId);
        
        // 在第一次AI回复后，尝试生成对话标题
        setTimeout(() => {
          generateConversationTitle();
        }, 1000);
        
      } catch (error) {
        console.error('❌ AI回复失败:', error);
      } finally {
        setLoading(false);
        await nativeChatOverlay.setLoading(false);
      }
    } else {
      // Web模式：使用React ChatOverlay
      console.log('🌐 Web模式，使用React ChatOverlay');
      if (webChatOverlayOpen) {
        setPendingFollowUpQuestion(inputText);
      } else {
        setInitialChatInput(inputText);
        setWebChatOverlayOpen(true);
      }
    }
  };

  // Web模式的浮窗关闭处理
  const handleCloseChatOverlay = () => {
    if (isNative) {
      nativeChatOverlay.hideOverlay();
    } else {
      console.log('❌ 关闭Web对话浮层');
      setWebChatOverlayOpen(false);
      setInitialChatInput('');
    }
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

  // 原生模式：同步消息列表到原生浮窗
  useEffect(() => {
    if (isNative && messages.length > 0) {
      console.log('📱 同步消息列表到原生浮窗，消息数量:', messages.length);
      // 格式化消息，确保timestamp为number类型
      const formattedMessages = messages.map(msg => ({
        id: msg.id,
        text: msg.text,
        isUser: msg.isUser,
        timestamp: msg.timestamp instanceof Date ? msg.timestamp.getTime() : msg.timestamp
      }));
      
      console.log('📱 格式化后的消息:', formattedMessages);
      nativeChatOverlay.updateMessages(formattedMessages);
    }
  }, [isNative, messages, nativeChatOverlay]);

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
          
          {/* Chat Overlay - 根据环境条件渲染 */}
          {!isNative && (
            <ChatOverlay
              isOpen={webChatOverlayOpen}
              onClose={handleCloseChatOverlay}
              onReopen={() => setWebChatOverlayOpen(true)}
              followUpQuestion={pendingFollowUpQuestion}
              onFollowUpProcessed={handleFollowUpProcessed}
              initialInput={initialChatInput}
              inputBottomSpace={webChatOverlayOpen ? 34 : 70}
            />
          )}
        </>,
        document.body // ✨ 4. 指定渲染目标为 document.body
      )}
    </div>
  );
}

export default App;