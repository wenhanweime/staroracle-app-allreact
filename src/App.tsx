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
// import ConversationDrawer from './components/ConversationDrawer'; // 🚫 临时屏蔽 - 专注调试原生InputDrawer
import ChatOverlay from './components/ChatOverlay'; // React版本（Web端回退）
import OracleInput from './components/OracleInput';
import { startAmbientSound, stopAmbientSound, playSound } from './utils/soundUtils';
import { triggerHapticFeedback } from './utils/hapticUtils';
import { Menu } from 'lucide-react';
import { useStarStore } from './store/useStarStore';
import { useChatStore } from './store/useChatStore';
import { ConstellationTemplate } from './types';
import { checkApiConfiguration, generateAIResponse } from './utils/aiTaggingUtils';
import { defaultSystemPrompt } from '@/utils/systemPrompt';
import { motion, AnimatePresence } from 'framer-motion';
import { useNativeChatOverlay } from './hooks/useNativeChatOverlay';
import { useNativeInputDrawer } from './hooks/useNativeInputDrawer';
import { InputDrawer } from './plugins/InputDrawer';
import { ChatOverlay } from './plugins/ChatOverlay';

function App() {
  const [isCollectionOpen, setIsCollectionOpen] = useState(false);
  const [isConfigOpen, setIsConfigOpen] = useState(false);
  const [isTemplateSelectorOpen, setIsTemplateSelectorOpen] = useState(false);
  const [isDrawerMenuOpen, setIsDrawerMenuOpen] = useState(false);
  const [appReady, setAppReady] = useState(false);
  
  // ✨ 原生ChatOverlay Hook
  const nativeChatOverlay = useNativeChatOverlay();
  
  // ✨ 原生InputDrawer Hook (测试)
  const nativeInputDrawer = useNativeInputDrawer();
  // 取消流式支持
  const abortRef = React.useRef<AbortController | null>(null);
  
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

  // 🚨 【关键修复】添加发送状态管理，防止重复发送
  const [isSending, setIsSending] = useState(false);
  
  // ✨ 重构 handleSendMessage 支持原生和Web模式
  const handleSendMessage = async (inputText: string) => {
    console.log('🔍 App.tsx: 接收到发送请求', inputText, '原生模式:', isNative);
    console.log('🔍 当前nativeChatOverlay.isOpen状态:', nativeChatOverlay.isOpen);

    // 🚨 【关键修复】防止重复发送
    if (isSending) {
      console.log('🚨 [防重复] 正在发送中，忽略重复请求');
      return;
    }
    
    setIsSending(true);

    try {
      if (isNative) {
        // 原生模式：交给原生StreamingClient管理流式
        console.log('📱 原生模式，交给原生StreamingClient发起流式');
        // 打开原生浮窗
        await nativeChatOverlay.showOverlay(true);

        // 先把用户消息写入我们本地store，保持Web端可见（原生端持有自身消息源）
        addUserMessage(inputText);
        // 关键：立刻读取最新的消息列表，避免使用当前渲染周期的旧 messages 变量
        const updated = useChatStore.getState().messages;
        setLoading(true);

        try {
          // 注意：不再在原生路径下调用 updateMessages，避免与原生状态机冲突；
          // 由 startNativeStream 统一初始化并驱动 UI。
          // 读取AI配置
          const cfg = (await import('./utils/aiTaggingUtils')).getAIConfig();
          const endpoint = cfg.endpoint || '';
          const apiKey = cfg.apiKey || '';
          const model = cfg.model || 'gpt-3.5-turbo';
          // 转换对话历史（使用最新列表）
          const conversation = updated.map(m => ({
            role: m.isUser ? 'user' as const : 'assistant' as const,
            content: m.text
          }));
          // 通过原生插件发起流式
          await ChatOverlay.startNativeStream({
            endpoint,
            apiKey,
            model,
            messages: conversation,
            temperature: 0.7
          });
        } catch (e) {
          console.error('❌ 原生流式启动失败:', e);
          // 回退方案：使用JS流式+直接推送到原生
          try {
            console.log('🌐 回退到JS流式 + 原生增量接口');
            // 构造原生消息格式并推送（使用最新列表 + 空AI占位）
            const latest = useChatStore.getState().messages;
            const nativeMessages = latest
              .map(m => ({ id: m.id, text: m.text, isUser: m.isUser, timestamp: m.timestamp.getTime() }))
              .concat([{ id: `ai-${Date.now()}`, text: '', isUser: false, timestamp: Date.now() }]);
            await ChatOverlay.updateMessages({ messages: nativeMessages });

            // 启动JS流式
            const messageId = addStreamingAIMessage('');
            const onStream = async (chunk: string) => {
              updateStreamingMessage(messageId, (useChatStore.getState().messages.find(m => m.id === messageId)?.streamingText || '') + chunk);
              try { await ChatOverlay.appendAIChunk({ id: messageId, delta: chunk }); } catch {}
            };
            const history = latest.map(msg => ({ role: msg.isUser ? 'user' as const : 'assistant' as const, content: msg.text }));
            const full = await generateAIResponse(inputText, undefined, onStream, history);
            updateStreamingMessage(messageId, full);
            finalizeStreamingMessage(messageId);
            try { await ChatOverlay.updateLastAI({ id: messageId, text: full }); } catch {}
          } catch (fallbackErr) {
            console.error('❌ JS回退流式失败:', fallbackErr);
          }
        } finally {
          setLoading(false);
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
    } finally {
      // 🚨 【关键修复】确保发送状态被重置
      setIsSending(false);
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

  // 取消当前流式
  const handleCancelStreaming = async () => {
    try {
      abortRef.current?.abort();
      abortRef.current = null;
      if (isNative) {
        try { await ChatOverlay.cancelStreaming(); } catch {}
      }
    } catch (e) {
      console.warn('Cancel streaming failed', e);
    }
  };

  // 添加原生平台效果（只在原生环境下执行）
  useEffect(() => {
    const setupNative = async () => {
      if (Capacitor.isNativePlatform()) {
        // 设置状态栏为暗色模式，文字为亮色
        try {
          await StatusBar.setStyle({ style: Style.Dark });
        } catch (e) {
          console.warn('StatusBar.setStyle failed', e);
        }
        
        // 标记应用准备就绪
        setAppReady(true);
        
        // 尽快隐藏启动屏，避免遮挡首交互（改为立即隐藏或极短过渡）
        try {
          await SplashScreen.hide({ fadeOutDuration: 120 });
        } catch (e) {
          console.warn('SplashScreen.hide failed', e);
        }

        // 🎯 设置原生InputDrawer事件监听
        let messageSubmittedListener: any;
        let textChangedListener: any;
        try {
          console.log('🎯 尝试注册 InputDrawer messageSubmitted 监听');
          messageSubmittedListener = await InputDrawer.addListener('messageSubmitted', (data: any) => {
            console.log('🎯 收到原生InputDrawer消息提交事件:', data.text);
            handleSendMessage(data.text);
          });
          console.log('✅ InputDrawer messageSubmitted 监听注册成功');
        } catch (e) {
          console.error('❌ 注册 InputDrawer messageSubmitted 监听失败:', e);
        }
        try {
          console.log('🎯 尝试注册 InputDrawer textChanged 监听');
          textChangedListener = await InputDrawer.addListener('textChanged', (data: any) => {
            console.log('🎯 原生InputDrawer文本变化:', data.text);
          });
          console.log('✅ InputDrawer textChanged 监听注册成功');
        } catch (e) {
          console.error('❌ 注册 InputDrawer textChanged 监听失败:', e);
        }

        // 🎯 监听发送动画完成事件：用于解锁逐字流式泵
    const sendAnimCompletedListener = ChatOverlay.addListener('sendAnimationCompleted', () => {
          console.log('📣 原生通知：发送动画完成，解锁逐字渲染');
          // 逐字泵在动画窗口外会自动推进，无需额外操作
        });

        // 🎯 自动显示输入框
        try {
          console.log('🎯 准备显示原生InputDrawer');
          const res = await InputDrawer.show({ animated: true });
          console.log('✅ InputDrawer.show 返回:', res);
        } catch (e) {
          console.error('❌ InputDrawer.show 调用失败:', e);
        }
        // 健康检查：若不可见则重试一次
        try {
          const vis = await InputDrawer.isVisible();
          console.log('👀 InputDrawer 可见性:', vis);
          if (!vis.visible) {
            console.warn('⚠️ InputDrawer 不可见，进行一次重试显示');
            await InputDrawer.show({ animated: false });
          }
        } catch (e) {
          console.warn('InputDrawer.isVisible 检查失败:', e);
        }

        // 清理函数
        return () => {
          try { messageSubmittedListener?.remove?.(); } catch {}
          try { textChangedListener?.remove?.(); } catch {}
          try { (sendAnimCompletedListener as any)?.then?.((l: any) => l.remove()); } catch {}
        };
      } else {
        // Web环境立即设置为准备就绪
        setAppReady(true);
      }
    };
    
    setupNative();
  }, []);

  // 原生环境：设置系统提示到原生插件，确保有完整prompt
  useEffect(() => {
    const applySystemPrompt = async () => {
      if (!isNative) return;
      try {
        const { setSystemPrompt } = await import('@/utils/conversationBridge');
        await setSystemPrompt(defaultSystemPrompt);
        console.log('✅ 已将系统提示注入原生ChatOverlay');
      } catch (e) {
        console.warn('⚠️ 注入系统提示失败（原生）:', e);
      }
    };
    applySystemPrompt();
  }, [isNative]);

  // 🔒 保障（增强版）：原生浮窗状态变化后，集中兜底恢复 InputDrawer 可见与位置
  useEffect(() => {
    if (!isNative) return;
    const ensureVisible = async () => {
      try {
        const vis = await InputDrawer.isVisible();
        if (!vis.visible) {
          console.warn('🔁 ChatOverlay状态变化后，InputDrawer 不可见，尝试强制显示');
          await InputDrawer.show({ animated: false });
        }
        // 位置兜底：复位 bottomSpace，避免停留在负空间或错误预留
        try { await InputDrawer.setBottomSpace({ space: 0 }); } catch {}
      } catch (e) {
        console.warn('ensureVisible 检查失败:', e);
      }
    };
    // 较长延迟，避开原生动画事务；并二次兜底
    const t1 = setTimeout(ensureVisible, 300);
    const t2 = setTimeout(ensureVisible, 600);
    return () => { clearTimeout(t1); clearTimeout(t2); };
  }, [isNative, nativeChatOverlay.isOpen]);

  // 🔒 保障（菜单关闭联动）：菜单从打开→关闭后，统一由 App 兜底恢复 InputDrawer（不再由 DrawerMenu 自行 setTimeout）
  useEffect(() => {
    if (!isNative) return;
    if (!isDrawerMenuOpen) {
      const ensureVisible = async () => {
        try {
          await InputDrawer.show({ animated: true });
          try { await InputDrawer.setBottomSpace({ space: 0 }); } catch {}
        } catch (e) {
          console.warn('ensureVisible(menu-close) 显示失败:', e);
        }
      };
      const t1 = setTimeout(ensureVisible, 200);
      const t2 = setTimeout(ensureVisible, 500);
      return () => { clearTimeout(t1); clearTimeout(t2); };
    }
  }, [isNative, isDrawerMenuOpen]);

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

  // 原生环境：加载历史以填充原生浮窗（调用插件），仅一次
  useEffect(() => {
    const boot = async () => {
      if (!isNative) return;
      try {
        const res = await (await import('@/utils/conversationBridge')).loadHistory();
        console.log('📜 已加载历史到原生浮窗，数量:', res.count);
      } catch (e) {
        console.warn('loadHistory failed', e);
      }
    };
    boot();
  }, [isNative]);

  // 🔧 移除重复的消息同步 - 已在useNativeChatOverlay.ts中处理
  // useEffect(() => {
  //   if (isNative && messages.length > 0) {
  //     console.log('📱 同步消息列表到原生浮窗，消息数量:', messages.length);
  //     // 格式化消息，确保timestamp为number类型
  //     const formattedMessages = messages.map(msg => ({
  //       id: msg.id,
  //       text: msg.text,
  //       isUser: msg.isUser,
  //       timestamp: msg.timestamp instanceof Date ? msg.timestamp.getTime() : msg.timestamp
  //     }));
  //     
  //     console.log('📱 格式化后的消息:', formattedMessages);
  //     nativeChatOverlay.updateMessages(formattedMessages);
  //   }
  // }, [isNative, messages, nativeChatOverlay]);

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
        className="min-h-screen cosmic-bg overflow-hidden relative"
        style={{
          // 🚨 【动画冲突修复】禁用React端3D动画，由Native端统一控制
          // transformStyle: 'preserve-3d',
          // perspective: '1000px', 
          // transform: isChatOverlayOpen ? 'scale(0.92) translateY(-15px) rotateX(4deg)' : 'scale(1) translateY(0px) rotateX(0deg)',
          // filter: isChatOverlayOpen ? 'brightness(0.6)' : 'brightness(1)'
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
          {/* Streaming control: Stop button (native/web) */}
          {isSending && (
            <button
              onClick={handleCancelStreaming}
              className="fixed bottom-24 right-4 z-50 px-3 py-2 rounded-md bg-red-600 text-white text-sm shadow-lg hover:bg-red-500 active:bg-red-700 transition"
            >
              停止生成
            </button>
          )}
          {/* 🚫 临时屏蔽Web版ConversationDrawer - 专注调试原生InputDrawer
          <ConversationDrawer 
            isOpen={true} 
            onToggle={() => {}} 
            onSendMessage={handleSendMessage}
            isFloatingAttached={isNative ? nativeChatOverlay.isOpen : webChatOverlayOpen}
          />
          */}
          
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
