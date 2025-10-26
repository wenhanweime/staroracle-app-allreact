Project Path: staroracle-app_allreact

Summary:

1. `src/components/InteractiveGalaxyBackground.tsx` 负责星系画布交互，点击时通过 `computeClickMeta → handleBackgroundMeta` 记录坐标、触发 `useGalaxyStore.clickAt` 的涟漪动画，并在 `GalaxyDOMPulseOverlay` 的 `onPersistHighlights` 回调里高亮命中的星点与映射的星卡。闪烁完成后它调用 `useStarStore.drawInspirationCard`，进入灵感卡片生成流程。
2. `src/store/useGalaxyStore.ts` 提供 `clickAt`、`hoverAt` 等动效状态，维护涟漪与热点冷却，是高亮动画的状态源。
3. `src/store/useStarStore.ts` 在 `drawInspirationCard` 中挑选灵感卡，`currentInspirationCard` 控制卡片展示；在 `addStar`/`setIsAsking` 等方法里衔接星卡生成与用户输入。
4. `src/App.tsx` 监听 `currentInspirationCard` 渲染 `<InspirationCard>`，并把 `handleGalaxyCanvasClick` 传给背景组件，串起点击→状态→UI 的链路。
5. `src/components/InspirationCard.tsx` 渲染灵感卡，处理翻转、拖拽、关闭等交互；`handleDismiss` 与 `handleLinearSwipeDismiss` 动画结束后调用 `dismissInspirationCard`，完成“卡片消失”的终点。

下面附录按文件顺序展开上述流程的完整实现细节，便于逐段定位与比对。


Source Tree:

```txt
staroracle-app_allreact
└── src
    ├── App.tsx
    ├── components
    │   ├── InspirationCard.tsx
    │   └── InteractiveGalaxyBackground.tsx
    └── store
        ├── useGalaxyStore.ts
        └── useStarStore.ts

```

`staroracle-app_allreact/src/App.tsx`:

```tsx
import React, { useCallback, useEffect, useState } from 'react';
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
import InteractiveGalaxyBackground from './components/InteractiveGalaxyBackground';
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

const DRAWER_WIDTH = 320;

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
  const prefersReducedMotion = typeof window !== 'undefined'
    ? window.matchMedia('(prefers-reduced-motion: reduce)').matches
    : false;
  
  const {
    applyTemplate,
    currentInspirationCard,
    dismissInspirationCard,
    setIsAsking
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
        } catch (e) {
          console.warn('ensureVisible(menu-close) 显示失败:', e);
        }
      };
      const t1 = setTimeout(ensureVisible, 200);
      const t2 = setTimeout(ensureVisible, 500);
      return () => { clearTimeout(t1); clearTimeout(t2); };
    }
  }, [isNative, isDrawerMenuOpen]);

  useEffect(() => {
    if (!isNative) return;
    const offset = isDrawerMenuOpen ? DRAWER_WIDTH : 0;
    const applyOffset = async () => {
      try {
        await InputDrawer.setHorizontalOffset({ offset, animated: true });
      } catch (e) {
        console.warn('InputDrawer.setHorizontalOffset 调用失败:', e);
      }
      try {
        await ChatOverlay.setHorizontalOffset({ offset, animated: true });
      } catch (e) {
        console.warn('ChatOverlay.setHorizontalOffset 调用失败:', e);
      }
    };
    applyOffset();
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

  const handleGalaxyCanvasClick = useCallback(
    ({ x, y }: { x: number; y: number; region: 'emotion' | 'relation' | 'growth' }) => {
      try {
        setIsAsking(false, { x, y });
        playSound('starReveal');
        if (isNative) {
          triggerHapticFeedback('light');
        }
      } catch (error) {
        console.warn('处理银河点击事件失败:', error);
      }
    },
    [setIsAsking, isNative]
  );
  
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
        {appReady && (
          <InteractiveGalaxyBackground
            quality={isNative ? 'mid' : 'auto'}
            reducedMotion={prefersReducedMotion}
            onCanvasClick={handleGalaxyCanvasClick}
          />
        )}
        
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
              drawerOffset={isDrawerMenuOpen ? DRAWER_WIDTH : 0}
            />
          )}
        </>,
        document.body // ✨ 4. 指定渲染目标为 document.body
      )}
    </div>
  );
}
export default App;

```

`staroracle-app_allreact/src/components/InspirationCard.tsx`:

```tsx
import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence, useAnimationControls, useMotionValue, PanInfo } from 'framer-motion';
import { createPortal } from 'react-dom';
import { Sparkles, MessageCircle } from 'lucide-react';
import { InspirationCard as IInspirationCard } from '../utils/inspirationCards';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import { getBookAnswer, getAnswerReflection } from '../utils/bookOfAnswers';
import ConversationDrawer from './ConversationDrawer';
import StarRayIcon from './StarRayIcon';

interface InspirationCardProps {
  card: IInspirationCard;
  onDismiss: () => void;
}

const InspirationCard: React.FC<InspirationCardProps> = ({ card, onDismiss }) => {
  const { addStar } = useStarStore();
  const [isFlipped, setIsFlipped] = useState(false);
  const [bookAnswer, setBookAnswer] = useState('');
  const [answerReflection, setAnswerReflection] = useState('');
  const [inputValue, setInputValue] = useState('');
  const [isCardReady, setIsCardReady] = useState(false); // 控制内部动画何时开始
  const [isClosing, setIsClosing] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const cardContainerRef = useRef<HTMLDivElement | null>(null);
  const cardControls = useAnimationControls();
  const overlayControls = useAnimationControls();
  const rotate = useMotionValue(0);
  const hasDraggedRef = useRef(false);
  
  // 预生成固定的星星位置，避免重新渲染时跳变
  const [starPositions] = useState(() => 
    Array.from({ length: 12 }).map((_, i) => ({
      cx: 20 + (i % 4) * 40 + Math.random() * 20,
      cy: 20 + Math.floor(i / 4) * 40 + Math.random() * 20,
      r: Math.random() * 1.5 + 0.5,
      duration: 2 + Math.random() * 2,
      delay: Math.random() * 2
    }))
  );
  
  // 预生成固定的装饰粒子位置
  const [particlePositions] = useState(() => 
    Array.from({ length: 6 }).map(() => ({
      left: `${20 + Math.random() * 60}%`,
      top: `${20 + Math.random() * 60}%`,
      duration: 3 + Math.random() * 2,
      delay: Math.random() * 2
    }))
  );
  
  // 在组件挂载时生成答案，确保答案在整个卡片生命周期内保持不变
  useEffect(() => {
    const answer = getBookAnswer();
    const reflection = getAnswerReflection(answer);
    setBookAnswer(answer);
    setAnswerReflection(reflection);
  }, []);

  // 延迟启动内部动画，等待卡片容器动画完成
  useEffect(() => {
    const timer = setTimeout(() => {
      setIsCardReady(true);
    }, 0); // 减少延迟时间，加快主星星出现

    return () => clearTimeout(timer);
  }, []);

  useEffect(() => {
    overlayControls.start({
      opacity: 0.6,
      transition: { duration: 0.18, ease: 'easeOut' },
    });
    cardControls.start({
      opacity: 1,
      scale: 1,
      x: 0,
      y: 0,
      rotate: 0,
      transition: {
        type: 'spring',
        stiffness: 220,
        damping: 20,
        mass: 0.6,
      },
    });
    rotate.set(0);
  }, [cardControls, overlayControls]);
    
  // 移除自动聚焦功能 - 只有用户手动点击输入框时才触发键盘
  // useEffect(() => {
  //   if (isFlipped && inputRef.current) {
  //     setTimeout(() => {
  //       inputRef.current?.focus();
  //     }, 600); // 等待卡片翻转动画完成
  //   }
  // }, [isFlipped]);

  const computeDismissTarget = () => {
    const cardEl = cardContainerRef.current;
    const targetEl = typeof document !== 'undefined'
      ? (document.querySelector('[data-star-collection-trigger]') as HTMLElement | null)
      : null;

    if (cardEl && targetEl) {
      const cardRect = cardEl.getBoundingClientRect();
      const triggerRect = targetEl.getBoundingClientRect();
      const deltaX =
        triggerRect.left + triggerRect.width / 2 - (cardRect.left + cardRect.width / 2);
      const deltaY =
        triggerRect.top + triggerRect.height / 2 - (cardRect.top + cardRect.height / 2);
      return { x: deltaX, y: deltaY };
    }

    const fallbackWidth = typeof window !== 'undefined' ? window.innerWidth : 0;
    const fallbackHeight = typeof window !== 'undefined' ? window.innerHeight : 0;
    return {
      x: fallbackWidth * 0.35,
      y: -fallbackHeight * 0.3,
    };
  };

  const handleDismiss = async () => {
    if (isClosing) return;
    setIsClosing(true);
    playSound('starClick');
    overlayControls.start({ opacity: 0, transition: { duration: 0.24, ease: 'easeIn' } }).catch(() => {});
    const target = computeDismissTarget();
    try {
      await cardControls.start({
        x: target.x,
        y: target.y,
        scale: 0.35,
        rotate: -12,
        opacity: 0,
        transition: {
          type: 'spring',
          stiffness: 260,
          damping: 26,
          restDelta: 0.5,
          restSpeed: 0.5,
        },
      });
    } finally {
      onDismiss();
    }
  };

  const computeLeftDismissTarget = () => {
    const cardRect = cardContainerRef.current?.getBoundingClientRect();
    const width = typeof window !== 'undefined' ? window.innerWidth : 0;
    const offscreenX = -((width || 0) + (cardRect?.width ?? 320) * 1.1);
    const lift = cardRect ? -Math.min(cardRect.height * 0.18, 120) : -90;
    return { x: offscreenX, y: lift };
  };

  const computeRightDismissTarget = () => {
    const cardRect = cardContainerRef.current?.getBoundingClientRect();
    const width = typeof window !== 'undefined' ? window.innerWidth : 0;
    const offscreenX = (width || 0) + (cardRect?.width ?? 320) * 1.1;
    const lift = cardRect ? -Math.min(cardRect.height * 0.16, 110) : -80;
    return { x: offscreenX, y: lift };
  };

  const handleLinearSwipeDismiss = async (direction: 'left' | 'right', velocityX: number) => {
    if (isClosing) return;
    setIsClosing(true);
    playSound('starClick');
    const target =
      direction === 'left' ? computeLeftDismissTarget() : computeRightDismissTarget();
    overlayControls.start({ opacity: 0, transition: { duration: 0.24, ease: 'easeIn' } }).catch(() => {});
    rotate.set(direction === 'left' ? -14 : 14);
    try {
      await cardControls.start({
        x: target.x,
        y: target.y,
        rotate: direction === 'left' ? -18 : 18,
        transition: direction === 'left'
          ? {
              type: 'spring',
              stiffness: 150,
              damping: 18,
              velocity: Math.max(velocityX / 75, -10),
            }
          : {
              type: 'spring',
              stiffness: 160,
              damping: 18,
              velocity: Math.min(Math.max(velocityX / 70, -10), 12),
            },
      });
      if (direction === 'left') {
        rotate.set(-20);
        await cardControls.start({
          x: target.x - 160,
          transition: {
            type: 'tween',
            duration: 0.18,
            ease: [0.05, 0.8, 0.2, 1],
          },
        });
      } else {
        rotate.set(22);
        await cardControls.start({
          x: target.x + 160,
          transition: {
            type: 'tween',
            duration: 0.18,
            ease: [0.05, 0.8, 0.2, 1],
          },
        });
      }
    } finally {
      onDismiss();
    }
  };

  const toggleCardFlip = (target?: boolean) => {
    setIsFlipped(prev => {
      const next = typeof target === 'boolean' ? target : !prev;
      console.log('[InspirationCard] toggleCardFlip', { prev, next, target });
      if (prev !== next) {
        playSound('starClick');
      }
      return next;
    });
  };

  const handleCardClick = () => {
    if (isClosing || hasDraggedRef.current) {
      hasDraggedRef.current = false;
      return;
    }
    console.log('[InspirationCard] card wrapper clicked');
    toggleCardFlip();
  };

  const handleFlipBack = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (isClosing || hasDraggedRef.current) {
      hasDraggedRef.current = false;
      return;
    }
    console.log('[InspirationCard] flip back button clicked');
    toggleCardFlip(false);
  };
  
  const handleSendMessage = () => {
    if (inputValue.trim()) {
      // 这里可以处理发送消息的逻辑
      console.log("发送消息:", inputValue);
      // 示例：创建一个新的星星
      addStar(inputValue);
      setInputValue('');
      playSound('starClick');
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  // 为卡片生成唯一ID，用于渐变效果
  const cardId = `insp-${Date.now()}`;

  return createPortal(
    <motion.div
      className="fixed inset-0 flex items-center justify-center"
      style={{ zIndex: 999999 }}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      <motion.div
        className="absolute inset-0 bg-black"
        initial={{ opacity: 0 }}
        animate={overlayControls}
        exit={{ opacity: 0 }}
        onClick={handleDismiss}
      />

      <motion.div
        ref={cardContainerRef}
        className="star-card-container"
        initial={{ opacity: 0, scale: 0.9, y: 16 }}
        animate={cardControls}
        exit={{ opacity: 0, scale: 0.9 }}
        style={{ rotate }}
        drag={isClosing ? false : 'x'}
        dragConstraints={{ left: 0, right: 0 }}
        dragElastic={0.28}
        onDragStart={() => {
          if (isClosing) return;
          hasDraggedRef.current = false;
          cardControls.stop();
          rotate.set(0);
        }}
        onDrag={(event, info) => {
          if (isClosing) return;
          if (Math.abs(info.offset.x) > 4) {
            hasDraggedRef.current = true;
          }
          const limited = Math.max(Math.min(info.offset.x / 10, 18), -18);
          rotate.set(limited);
        }}
        onDragEnd={(event, info: PanInfo) => {
          if (isClosing) return;
          const { offset, velocity } = info;
          rotate.set(0);
          const shouldDismiss =
            offset.x < -140 || velocity.x < -900 || offset.x > 140 || velocity.x > 900;
          if (shouldDismiss) {
            handleLinearSwipeDismiss(offset.x > 0 || velocity.x > 0 ? 'right' : 'left', velocity.x);
            return;
          }
          hasDraggedRef.current = false;
          cardControls.start({
            x: 0,
            y: 0,
            rotate: 0,
            transition: {
              type: 'spring',
              stiffness: 320,
              damping: 28,
            },
          });
        }}
      >
        <div
          className="star-card-wrapper"
          onClick={(e) => {
            e.stopPropagation();
            console.log('[InspirationCard] wrapper clicked');
            toggleCardFlip();
          }}
          onPointerDown={(e) => {
            console.log('[InspirationCard] wrapper pointer down');
            e.stopPropagation();
          }}
        >
          <motion.div
            className={`star-card ${isFlipped ? 'is-flipped' : ''}`}
            animate={{ rotateY: isFlipped ? 180 : 0 }}
            transition={{ duration: 0.6, type: "spring" }}
          >
            {/* Front Side - Card Design */}
            <div
              className="star-card-face star-card-front"
              onClick={(e) => {
                e.stopPropagation();
                console.log('[InspirationCard] front face clicked');
                toggleCardFlip(true);
              }}
              onPointerDown={(e) => {
                console.log('[InspirationCard] front face pointer down');
                e.stopPropagation();
              }}
            >
              <div className="star-card-bg">
                <div className="star-card-constellation">
                  {/* Star pattern */}
                  <svg className="constellation-svg" viewBox="0 0 200 200">
              <defs>
                      <radialGradient id={`starGlow-${cardId}`} cx="50%" cy="50%" r="50%">
                        <stop offset="0%" stopColor="#ffffff" stopOpacity="0.8"/>
                        <stop offset="100%" stopColor="#ffffff" stopOpacity="0"/>
                </radialGradient>
              </defs>
              
              {/* Background stars */}
                    {starPositions.map((star, i) => (
                <motion.circle
                  key={i}
                        cx={star.cx}
                        cy={star.cy}
                  r={star.r}
                  fill="rgba(255,255,255,0.6)"
                  initial={{ opacity: 0 }}
                  animate={isCardReady ? {
                    opacity: [0.3, 0.8, 0.3]
                  } : {
                    opacity: 0
                  }}
                  transition={{
                    duration: Math.max(1.2, star.duration * 0.75),
                    repeat: isCardReady ? Infinity : 0,
                    delay: isCardReady ? 1.4 + star.delay * 0.6 : 0
                  }}
                />
              ))}
              
                    {/* Main star */}
                    <motion.circle
                      cx="100"
                cy="100"
                      r="8"
                      fill={`url(#starGlow-${cardId})`}
                      initial={{ scale: 0 }}
                      animate={isCardReady ? { scale: 1 } : { scale: 0 }}
                      transition={{ delay: isCardReady ? 0.1 : 0, type: "spring", damping: 15 }}
                    />
                    
                    {/* Star rays - 使用星星动画阶段的动画效果 */}
                    {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => (
                      <motion.line
                        key={i}
                        x1="100"
                        y1="100"
                        x2={100 + Math.cos(i * Math.PI / 4) * 40}
                        y2={100 + Math.sin(i * Math.PI / 4) * 40}
                        stroke="#ffffff"
                        strokeWidth="2"
                        initial={{ pathLength: 0, opacity: 0 }}
                        animate={isCardReady ? {
                          pathLength: 1,
                          opacity: [0, 0.8, 0]
                        } : {
                          pathLength: 0,
                          opacity: 0
                        }}
                        transition={{
                          duration: 1.1,
                          delay: isCardReady ? i * 0.08 : 0,
                          repeat: isCardReady ? Infinity : 0,
                          repeatDelay: isCardReady ? 0.8 : 0
                        }}
              />
                    ))}
            </svg>
          </div>

                <motion.div
                  className="card-prompt"
                  initial={{ opacity: 0, y: 20 }}
                  animate={isCardReady ? {
                    opacity: 0.7,
                    y: 0
                  } : {
                    opacity: 0,
                    y: 20
                  }}
                  transition={{ 
                    delay: isCardReady ? 0.35 : 0,
                    duration: 0.25
                  }}
                >
                  <p className="text-center text-base text-neutral-300 font-normal">
                    翻开卡片，宇宙会回答你
                  </p>
                </motion.div>

                {/* Decorative elements */}
                <div className="star-card-decorations">
                  {particlePositions.map((particle, i) => (
            <motion.div
              key={i}
              className="floating-particle"
              style={{
                left: particle.left,
                top: particle.top,
              }}
              initial={{ y: 0, opacity: 0.3 }}
              animate={isCardReady ? {
                y: [-5, 5, -5],
                opacity: [0.3, 0.7, 0.3]
              } : {
                y: 0,
                opacity: 0
              }}
              transition={{
                duration: particle.duration,
                repeat: isCardReady ? Infinity : 0,
                delay: isCardReady ? 2.0 + particle.delay : 0
              }}
            />
          ))}
                </div>
              </div>
            </div>

            {/* Back Side - Book of Answers */}
            <div
              className="star-card-face star-card-back"
              onClick={(e) => {
                e.stopPropagation();
                console.log('[InspirationCard] back face clicked');
                toggleCardFlip(false);
              }}
              onPointerDown={(e) => {
                console.log('[InspirationCard] back face pointer down');
                e.stopPropagation();
              }}
            >
              <div className="star-card-content flex flex-col h-full">
                {/* 标题与返回按钮 */}
                <div className="flex items-center justify-between mb-6 px-1">
                  <motion.div
                    className="flex-1"
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.2 }}
                  >
                    <h3 className="answer-label text-xl font-semibold text-cosmic-accent text-center">来自宇宙的答案</h3>
                  </motion.div>
                  <motion.button
                    className="text-xs px-3 py-1 rounded-full border border-white/20 text-white/80 hover:text-white hover:border-white/40 transition-colors ml-3"
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.35 }}
                    onClick={handleFlipBack}
                  >
                    返回正面
                  </motion.button>
                </div>

                {/* 答案部分 - 居中显示 */}
                <div className="answer-section flex-grow flex items-center justify-center px-6">
                  <motion.div
                    className="answer-reveal text-center"
                    initial={{ opacity: 0, scale: 0.9 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: 0.4, type: "spring", damping: 20 }}
                  >
                    <p className="answer-text text-3xl font-bold text-white mb-2 drop-shadow-[0_0_8px_rgba(255,255,255,0.3)]">{bookAnswer}</p>
                  </motion.div>
                </div>
                
                {/* 附言部分 - 放在底部，进一步降低视觉重要性 */}
                <motion.div
                  className="reflection-section mt-auto mb-3 px-4"
                  initial={{ opacity: 0 }}
                  animate={{ 
                    opacity: 1 
                  }}
                  transition={{ delay: 0.6 }}
                >
                  <p className="reflection-text text-[9px] text-neutral-400 italic text-center leading-tight tracking-wide">{answerReflection}</p>
                </motion.div>
                
                {/* 抽屉式输入框 - 直接显示，无需点击按钮 */}
                <motion.div
                  className="card-footer"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.7 }}
                >
                  <motion.div 
                    className="input-ghost-wrapper w-full"
                    initial={{ y: 20, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    transition={{ type: "spring", damping: 20, delay: 0.7 }}
                  >
                    <div className="flex items-center gap-3 relative py-2 px-1">
                      <input
                        ref={inputRef}
                        type="text"
                        className="flex-1 bg-transparent text-white placeholder-neutral-400 outline-none text-sm leading-relaxed border-0 border-b border-neutral-600/50 focus:border-cosmic-accent transition-colors duration-300"
                        placeholder="说说你的困惑吧"
                        value={inputValue}
                        onChange={(e) => setInputValue(e.target.value)}
                        onKeyPress={handleKeyPress}
                        onClick={(e) => e.stopPropagation()} // 只有输入框本身阻止传播
                      />
                      <motion.button
                        className={`w-7 h-7 rounded-full flex items-center justify-center transition-colors ${
                          inputValue.trim() ? 'bg-cosmic-accent/80 text-white' : 'bg-transparent text-neutral-400'
                        }`}
                        onClick={(e) => {
                          e.stopPropagation(); // 只有按钮本身阻止传播
                          handleSendMessage();
                        }}
                        disabled={!inputValue.trim()}
                        whileHover={inputValue.trim() ? { scale: 1.1 } : {}}
                        whileTap={inputValue.trim() ? { scale: 0.95 } : {}}
                      >
                        <StarRayIcon size={14} animated={!!inputValue.trim()} />
                      </motion.button>
                    </div>
                  </motion.div>
                </motion.div>
              </div>
            </div>
          </motion.div>
          
          {/* Hover glow effect */}
          <motion.div
            className="star-card-glow"
            animate={{
              opacity: 0.4,
              scale: 1.05,
            }}
            transition={{ duration: 0.3 }}
          />
        </div>
      </motion.div>
    </motion.div>,
    document.body
  );
};

export default InspirationCard;

```

`staroracle-app_allreact/src/components/InteractiveGalaxyBackground.tsx`:

```tsx
import React, { useEffect, useRef, useState } from 'react';
import GalaxyDOMPulseOverlay from './GalaxyDOMPulseOverlay';
import GalaxyLightweight from './GalaxyLightweight';
import { useGalaxyStore } from '../store/useGalaxyStore';
import { useGalaxyGridStore } from '../store/useGalaxyGridStore';
import { useStarStore } from '../store/useStarStore';

type Quality = 'low' | 'mid' | 'high' | 'auto';

interface InteractiveGalaxyBackgroundProps {
  quality?: Quality;
  reducedMotion?: boolean;
  className?: string;
  onCanvasClick?: (payload: { x: number; y: number; region: 'emotion' | 'relation' | 'growth' }) => void;
}

// Lightweight pseudo-noise (deterministic) to avoid extra dependencies
const fract = (n: number) => n - Math.floor(n);
const noise2D = (x: number, y: number) => {
  const t = Math.sin(x * 12.9898 + y * 78.233) * 43758.5453123;
  return fract(t) * 2 - 1; // [-1, 1]
};

const normalizeHex = (hex: unknown) => {
  if (!hex && hex !== 0) return '#FFFFFF';
  let value = typeof hex === 'string' ? hex.trim() : String(hex).trim();
  if (!value.startsWith('#')) return '#FFFFFF';
  if (value.length === 4) {
    value = `#${value[1]}${value[1]}${value[2]}${value[2]}${value[3]}${value[3]}`;
  }
  if (value.length !== 7) return '#FFFFFF';
  return value.toUpperCase();
};

// 颜色辅助：HEX ↔ HSL（仅用于显示着色的颜色抖动，不影响算法）
const clamp01 = (v: number) => Math.max(0, Math.min(1, v));
const hexToRgb = (hex: string) => {
  const h = hex.replace('#','');
  const full = h.length === 3 ? h.split('').map(c=>c+c).join('') : h;
  const num = parseInt(full, 16);
  return { r: (num>>16)&255, g: (num>>8)&255, b: num&255 };
};
const rgbToHex = (r:number,g:number,b:number) => '#'+[r,g,b].map(v=>{
  const s = Math.max(0,Math.min(255, Math.round(v))).toString(16).padStart(2,'0');
  return s;
}).join('');
const rgbToHsl = (r:number,g:number,b:number) => {
  r/=255; g/=255; b/=255;
  const max=Math.max(r,g,b), min=Math.min(r,g,b);
  let h=0, s=0; const l=(max+min)/2;
  if (max!==min) {
    const d=max-min; s = l>0.5? d/(2-max-min): d/(max+min);
    switch (max) {
      case r: h=(g-b)/d+(g<b?6:0); break;
      case g: h=(b-r)/d+2; break;
      default: h=(r-g)/d+4;
    }
    h/=6;
  }
  return { h: h*360, s, l };
};
const hslToRgb = (h:number,s:number,l:number) => {
  h/=360;
  const hue2rgb = (p:number,q:number,t:number)=>{
    if (t<0) t+=1; if (t>1) t-=1;
    if (t<1/6) return p+(q-p)*6*t;
    if (t<1/2) return q;
    if (t<2/3) return p+(q-p)*(2/3-t)*6;
    return p;
  };
  let r:number,g:number,b:number;
  if (s===0) { r=g=b=l; }
  else {
    const q = l<0.5? l*(1+s): l+s-l*s;
    const p = 2*l-q;
    r = hue2rgb(p,q,h+1/3);
    g = hue2rgb(p,q,h);
    b = hue2rgb(p,q,h-1/3);
  }
  return { r: Math.round(r*255), g: Math.round(g*255), b: Math.round(b*255) };
};
const hexToHsl = (hex:string) => { const {r,g,b}=hexToRgb(hex); return rgbToHsl(r,g,b); };
const hslToHex = (h:number,s:number,l:number) => { const {r,g,b}=hslToRgb(h,s,l); return rgbToHex(r,g,b); };

// Best visual defaults aligned to 3-arm design
const defaultParams = {
   // 稳定版默认参数（对齐 tag：开始首页galaxy交互完整性之前的确定性版本）
   coreDensity: 0.7,// 核心密度  
   coreRadius: 12,    // 核心半径
   coreSizeMin: 1.0, // 核心星星大小最小
   coreSizeMax: 3.5, // 核心星星大小最大
   armCount: 5, // 旋臂数量
   armDensity: 0.6, // 旋臂密度
   armBaseSizeMin: 0.7, // 旋臂星星大小最小
   armBaseSizeMax: 2.0, // 旋臂星星大小最大
   armHighlightSize: 5.0, // 旋臂星星高亮大小
   armHighlightProb: 0.01, // 旋臂星星高亮概率
   spiralA: 8, // 螺旋基准
   spiralB: 0.29, // 螺旋紧密度
   armWidthInner: 29, // 旋臂宽度内侧
   armWidthOuter: 65, // 旋臂宽度外侧
   armWidthGrowth: 2.5, // 旋臂宽度增长
   armWidthScale: 1.0, // 旋臂整体宽度比例
   armTransitionSoftness: 3.8, // 旋臂过渡平滑度（更宽的臂脊）
   fadeStartRadius: 0.5, // 淡化起始
   fadeEndRadius: 1.3, // 淡化结束
   outerDensityMaintain: 0.10, // 外围密度维持
   interArmDensity: 0.150, // 旋臂间区域密度
   interArmSizeMin: 0.6, // 旋臂间区域星星大小最小
   interArmSizeMax: 1.2, // 旋臂间区域星星大小最大
   radialDecay: 0.0015, // 径向衰减
   backgroundDensity: 0.00024, // 背景星星密度
   backgroundSizeVariation: 2.0, // 背景星星大小变异
   jitterStrength: 10, // 垂直抖动强度
   densityNoiseScale: 0.018, // 密度噪声缩放
   densityNoiseStrength: 0.8, // 密度噪声强度
   // 抖动不规律（稳定版未使用，默认关闭）
   jitterChaos: 0, // 抖动不规律
   jitterChaosScale: 0, // 抖动不规律尺度
   armStarSizeMultiplier: 1.0, // 旋臂星星大小倍数
   interArmStarSizeMultiplier: 1.0, // 旋臂间区域星星大小倍数
   backgroundStarSizeMultiplier: 1.0,
   galaxyScale: 0.88, // 整体缩放（银河占屏比例）
  // 颜色波动（为保持结构颜色一致，默认关闭）
  colorJitterHue: 0,
  colorJitterSat: 0,
  colorJitterLight: 0,
  colorNoiseScale: 0,
};

// 模块颜色默认值（结构着色用）
// 天体物理写实配色（白脊+蓝臂+紫红HII+黑尘+暖核+灰蓝臂间）
const defaultPalette = {
  core: '#5A4E41',     // 暖核：偏灰的暖棕
  ridge: '#5B5E66',    // 臂脊：更暗的冷灰脊线
  armBright: '#28457B',// 臂内：再降亮度的蓝调
  armEdge: '#245B88',  // 臂边：更深的青蓝
  hii: '#3C194E',      // HII：暗紫色发光区
  dust: '#0E0A14',     // 尘埃：近乎黑的紫灰
  outer: '#415069',    // 臂间/外围：暗冷灰蓝
};
// 分层透明度（仅用于显示着色，不影响算法/密度）
const defaultLayerAlpha = {
  core: 1.0,
  ridge: 0.98,
  armBright: 0.90,
  armEdge: 0.85,
  hii: 0.88,
  dust: 0.45,
  outer: 0.78,
};

const getArmWidth = (radius: number, maxRadius: number, p = defaultParams) => {
  const progress = Math.min(radius / (maxRadius * 0.8), 1);
  return p.armWidthInner + (p.armWidthOuter - p.armWidthInner) * Math.pow(progress, p.armWidthGrowth);
};

const getFadeFactor = (radius: number, maxRadius: number, p = defaultParams) => {
  const fadeStart = maxRadius * p.fadeStartRadius;
  const fadeEnd = maxRadius * p.fadeEndRadius;
  if (radius < fadeStart) return 1;
  if (radius > fadeEnd) return 0;
  const progress = (radius - fadeStart) / (fadeEnd - fadeStart);
  return 0.5 * (1 + Math.cos(progress * Math.PI));
};

const getRadialDecayFn = (p = defaultParams) => (radius: number, maxRadius: number) => {
  const baseFactor = Math.exp(-radius * p.radialDecay);
  const fadeFactor = getFadeFactor(radius, maxRadius, p);
  const maintainFactor = p.outerDensityMaintain;
  return Math.max(baseFactor * fadeFactor, maintainFactor * fadeFactor);
};

const getArmPositions = (radius: number, centerX: number, centerY: number, p = defaultParams) => {
  const positions: Array<{ x: number; y: number; theta: number; armIndex: number }> = [];
  // 反向旋臂方向：仅改变角度符号，其余参数保持不变
  const angle = Math.log(Math.max(radius, p.spiralA) / p.spiralA) / p.spiralB;
  for (let arm = 0; arm < p.armCount; arm++) {
    const armOffset = (arm * 2 * Math.PI) / p.armCount;
    const theta = armOffset - angle;
    positions.push({ x: centerX + radius * Math.cos(theta), y: centerY + radius * Math.sin(theta), theta, armIndex: arm });
  }
  return positions;
};

const getArmInfo = (x: number, y: number, centerX: number, centerY: number, maxRadius: number, p = defaultParams) => {
  const dx = x - centerX;
  const dy = y - centerY;
  const radius = Math.sqrt(dx * dx + dy * dy);
  if (radius < 3) return { distance: 0, armIndex: 0, radius, inArm: true, armWidth: 0, theta: 0 };
  const armPositions = getArmPositions(radius, centerX, centerY, p);
  let minDistance = Infinity;
  let nearestArmIndex = 0;
  let nearestArmTheta = 0;
  armPositions.forEach((pos, index) => {
    const distance = Math.sqrt((x - pos.x) ** 2 + (y - pos.y) ** 2);
    if (distance < minDistance) {
      minDistance = distance;
      nearestArmIndex = index;
      nearestArmTheta = pos.theta;
    }
  });
  const armWidth = getArmWidth(radius, maxRadius, p);
  const inArm = minDistance < armWidth;
  return { distance: minDistance, armIndex: nearestArmIndex, radius, inArm, armWidth, theta: nearestArmTheta };
};

const calculateArmDensityProfile = (armInfo: ReturnType<typeof getArmInfo>, p = defaultParams) => {
  const { distance, armWidth } = armInfo;
  const profile = Math.exp(-0.5 * Math.pow(distance / (armWidth / p.armTransitionSoftness), 2));
  const totalDensity = p.interArmDensity + p.armDensity * profile;
  let size: number;
  if (profile > 0.1) {
    size = p.armBaseSizeMin + (p.armBaseSizeMax - p.armBaseSizeMin) * profile;
    if (profile > 0.7 && Math.random() < p.armHighlightProb) size = p.armHighlightSize;
    size *= p.armStarSizeMultiplier;
  } else {
    size = p.interArmSizeMin + (p.interArmSizeMax - p.interArmSizeMin) * Math.random();
    size *= p.interArmStarSizeMultiplier;
  }
  return { density: totalDensity, size, profile };
};

const areHighlightListsEqual = (
  a: Array<{id:string;band:number;x:number;y:number;size:number;color?:string;litColor?:string}>,
  b: Array<{id:string;band:number;x:number;y:number;size:number;color?:string;litColor?:string}>
) => {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) {
    const pa = a[i];
    const pb = b[i];
    if (pa.id !== pb.id || pa.band !== pb.band) return false;
    if (pa.x !== pb.x || pa.y !== pb.y || pa.size !== pb.size) return false;
    if (pa.color !== pb.color || pa.litColor !== pb.litColor) return false;
  }
  return true;
};

const InteractiveGalaxyBackground: React.FC<InteractiveGalaxyBackgroundProps> = ({
  quality = 'auto',
  reducedMotion = false,
  className,
  onCanvasClick,
}) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const baseViewportHeightRef = useRef<number>(typeof window !== 'undefined' ? window.innerHeight : 0);
  const baseViewportWidthRef = useRef<number>(typeof window !== 'undefined' ? window.innerWidth : 0);
  const KEYBOARD_HEIGHT_DROP = 160;
  const ORIENTATION_WIDTH_DELTA = 120;
  const setGalaxyCanvasSize = useGalaxyStore(s=>s.setCanvasSize)
  const genHotspots = useGalaxyStore(s=>s.generateHotspots)
  const hoverHs = useGalaxyStore(s=>s.hoverAt)
  const clickHs = useGalaxyStore(s=>s.clickAt)
  const drawInspirationCard = useStarStore(s=>s.drawInspirationCard)
  const addPlanetCard = useStarStore(state => state.addPlanetCard);
  const constellationStars = useStarStore(state => state.constellation.stars);
  const constellationHighlights = useStarStore(state => state.galaxyHighlights);
  const setGalaxyHighlights = useStarStore(state => state.setGalaxyHighlights);
  const setGalaxyHighlightColor = useStarStore(state => state.setGalaxyHighlightColor);
  const setGridSize = useGalaxyGridStore(s=>s.setCanvasSize)
  const genSites = useGalaxyGridStore(s=>s.generateSites)
  const currentQualityRef = useRef<Exclude<Quality, 'auto'>>('mid');
  const fpsSamplesRef = useRef<number[]>([]);
  const lastFpsSampleTimeRef = useRef<number>(performance.now());
  const lastFrameTimeRef = useRef<number>(performance.now());
  const lastQualityChangeRef = useRef<number>(0);
  const hoverRegionRef = useRef<'emotion' | 'relation' | 'growth' | null>(null);
  const bgLayerRef = useRef<HTMLCanvasElement | null>(null); // 背景层：不缩放/不旋转，覆盖全屏
  const nearLayerRef = useRef<HTMLCanvasElement | null>(null); // legacy
  const farLayerRef = useRef<HTMLCanvasElement | null>(null);  // legacy
  const bandLayersRef = useRef<HTMLCanvasElement[] | null>(null); // 差速旋转分层
  // DOM 脉冲用：记录可见星点（CSS像素坐标，仅BG层，免读像素）
  const domStarPointsRef = useRef<Array<{x:number;y:number;size:number}>>([]);
  // 记录分层（旋转臂）星点：band 层坐标及其画布尺寸，用于点击时做矩阵变换
  const bandStarPointsRef = useRef<Array<{x:number;y:number;size:number;band:number;bw:number;bh:number}>>([]);
  // 星点掩膜层：与图层对应的掩膜和每帧合成后的掩膜
  const bgMaskRef = useRef<HTMLCanvasElement | null>(null);
  const bandMaskLayersRef = useRef<HTMLCanvasElement[] | null>(null);
  const starMaskCompositeRef = useRef<HTMLCanvasElement | null>(null);
  const domBandPointsRef = useRef<Array<{id:string;x:number;y:number;size:number;band:number;bw:number;bh:number;color?:string;litColor?:string}>>([]);
  const isIOS = typeof navigator !== 'undefined' && /iP(ad|hone|od)/.test(navigator.userAgent)
  const initialParams = isIOS ? {
    ...defaultParams,
    armWidthScale: 2.9,
    armWidthInner: 29,
    armWidthOuter: 65,
    armWidthGrowth: 2.5,
    armTransitionSoftness: 7,
    jitterStrength: 25,
  } : defaultParams
  const [params] = useState(initialParams);
  const paramsRef = useRef(params);
  useEffect(() => { paramsRef.current = params; }, [params]);
  // 星点默认使用偏灰白，避免纯白饱和（为交互提亮留余量）
  const starBaseColor = '#CCCCCC';
  // 闪烁动效配置（用于 ClickGlowOverlay）
  const [glowCfg] = useState({
    pickProb: 0.2,
    pulseWidth: 0.25,
    bandFactor: 0.12,
    noiseFactor: 0.08,
    edgeAlphaThresh: 8,
    edgeExponent: 1.1,
    // 点击高亮范围缩小一半（半径减半）
    radiusFactor: 0.00875,
    minRadius: 15,
    durationMs: 850,
    ease: 'sine' as 'sine' | 'cubic',
  });
  // 闪烁调试参数（用于 ClickGlowOverlay）
  

  const renderAllRef = useRef<() => void>();
  // Rotation toggle: pause during debug by default
  const [rotateEnabled] = useState(true);
  const rotateRef = useRef(rotateEnabled);
  useEffect(() => { rotateRef.current = rotateEnabled; }, [rotateEnabled]);
  // 结构着色常量：默认开启
  const structureColoring = true;
  const palette = defaultPalette;
  // Lit palette（点亮时的高亮配色，可独立调节与保存）
  const litPaletteDefault: typeof defaultPalette = {
    core: '#E3B787',     // 暖核：暗色对应的高亮暖金
    ridge: '#C7C9CE',    // 臂脊：提亮的冷灰
    armBright: '#92ADE0',// 臂内：浅蓝高亮
    armEdge: '#95C2E8',  // 臂边：浅青蓝高亮
    hii: '#D88AC9',      // HII：高亮紫色
    dust: '#3F3264',     // 尘埃：压暗后的紫灰
    outer: '#ACB9CF',    // 臂间/外围：淡灰蓝
  }
  const litPalette = litPaletteDefault;
  const [persistentHighlights, setPersistentHighlights] = useState<Array<{id:string;band:number;x:number;y:number;size:number;color?:string;litColor?:string}>>([])
  // 不再从 localStorage 读取，保持默认配置
  // 每层透明度（仅显示层）
  const [layerAlpha] = useState<typeof defaultLayerAlpha>(defaultLayerAlpha);
  const layerAlphaRef = useRef(layerAlpha);
  useEffect(() => { layerAlphaRef.current = layerAlpha; }, [layerAlpha]);

  useEffect(() => {
    // Coarse pointer (mobile): skip heavy Canvas pipeline, DOM mode will render below
    return;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    ctx.imageSmoothingEnabled = true;
    // Prefer highest quality resampling on iOS/retina
    // @ts-ignore
    ctx.imageSmoothingQuality = 'high';

    const DPR = (window.devicePixelRatio || 1);

    const resize = () => {
      const viewportWidth = window.innerWidth;
      const viewportHeight = window.innerHeight;
      const widthDelta = Math.abs(viewportWidth - baseViewportWidthRef.current);

      if (widthDelta > ORIENTATION_WIDTH_DELTA) {
        baseViewportWidthRef.current = viewportWidth;
        baseViewportHeightRef.current = viewportHeight;
      } else if (viewportHeight > baseViewportHeightRef.current) {
        baseViewportHeightRef.current = viewportHeight;
      }

      const targetHeightBase = baseViewportHeightRef.current || viewportHeight;
      const heightDrop = targetHeightBase - viewportHeight;
      const effectiveHeight = heightDrop > KEYBOARD_HEIGHT_DROP ? targetHeightBase : viewportHeight;

      const w = viewportWidth;
      const h = effectiveHeight;
      canvas.width = Math.floor(w * DPR);
      canvas.height = Math.floor(h * DPR);
      canvas.style.width = `${w}px`;
      canvas.style.height = `${h}px`;
      // 交互层与存储统一使用 CSS 像素尺寸，避免与 DPR 不一致
      setGalaxyCanvasSize(w, h)
      setGridSize(w, h)
    };

    // 为确保静止与旋转形态一致，锁定采样为“高质量”
    const getQualityScale = () => 1;
    const getStep = () => 1.0;
    // 原始样式：白色星点，不做额外着色/辉光

    // Generate pre-rendered layers
    const generateLayers = () => {
      // Deterministic RNG to ensure same morphology for same params across regenerations
      const seeded = (seed: number) => {
        let t = seed >>> 0;
        return () => {
          t += 0x6D2B79F5;
          let r = Math.imul(t ^ (t >>> 15), 1 | t);
          r ^= r + Math.imul(r ^ (r >>> 7), 61 | r);
          return ((r ^ (r >>> 14)) >>> 0) / 4294967296;
        };
      };
      const rng = seeded(0xA17C9E3); // fixed seed for stable output

      const p = paramsRef.current;
      const width = canvas.width;
      const height = canvas.height;
      const centerX = width / 2;
      const centerY = height / 2;
      const maxRadius = Math.min(width, height) * 0.4;
      // 动态 overscan：保证旋转+缩放后不裁切（不改变主体尺寸）
      const scaleLocal = Math.max(0.01, paramsRef.current.galaxyScale ?? 1);
      const minOV = Math.max(Math.SQRT2 + 0.1, (1 / scaleLocal) + 0.2);
      const OV = Math.max(1, p.overscan || 1.0, minOV);
      const owidth = Math.floor(width * OV);
      const oheight = Math.floor(height * OV);
      const oCenterX = owidth / 2;
      const oCenterY = oheight / 2;
      const radialDecay = getRadialDecayFn(p);

      // init offscreen layers
      const bg = document.createElement('canvas'); // 背景层（不受缩放/旋转影响）
      const near = document.createElement('canvas');
      const far = document.createElement('canvas');
      bg.width = width; bg.height = height;
      near.width = width; near.height = height;
      far.width = width; far.height = height;
      const bctx = bg.getContext('2d')!;
      const nctx = near.getContext('2d')!;
      const fctx = far.getContext('2d')!;
      // 掩膜：与图层同尺寸
      const bgMask = document.createElement('canvas'); bgMask.width = width; bgMask.height = height;
      const bmctx = bgMask.getContext('2d')!;
      // Prepare band layers for differential rotation (no duplication)
      const BAND_COUNT = 10;
      const bands: HTMLCanvasElement[] = Array.from({ length: BAND_COUNT }, () => {
        const c = document.createElement('canvas');
        c.width = owidth; c.height = oheight;
        return c;
      });
      const bandCtx = bands.map(c => c.getContext('2d')!);
      bandCtx.forEach(ctx => { ctx.save(); ctx.scale(DPR, DPR); });
      // 收集 band 星点（不含旋转，仅记录生成时 band 层坐标）
      const bandPts: Array<Array<{x:number;y:number;size:number}>> = Array.from({length:BAND_COUNT},()=>[]);
      const bandMasks: HTMLCanvasElement[] = Array.from({ length: BAND_COUNT }, () => {
        const c = document.createElement('canvas');
        c.width = owidth; c.height = oheight;
        return c;
      });
      const bandMaskCtx = bandMasks.map(c => c.getContext('2d')!);
      bandMaskCtx.forEach(ctx => { ctx.save(); ctx.scale(DPR, DPR); });

      const qualityScale = getQualityScale();
      const step = getStep();

      // Background small stars -> bg layer (full-screen, no rotation/scale)
      const domPoints: Array<{x:number;y:number;size:number}> = [];
      const bgCount = Math.floor((width / DPR) * (height / DPR) * p.backgroundDensity * (reducedMotion ? 0.6 : 1) * qualityScale);
      bctx.save(); bctx.scale(DPR, DPR); bctx.globalAlpha = 1; bctx.fillStyle = starBaseColor;
      bmctx.save(); bmctx.scale(DPR, DPR); bmctx.fillStyle = '#FFFFFF';
      for (let i = 0; i < bgCount; i++) {
        const x = rng() * (width / DPR);
        const y = rng() * (height / DPR);
        const r1 = rng();
        const r2 = rng();
        let size = r1 < 0.85 ? 0.8 : (r2 < 0.9 ? 1.2 : p.backgroundSizeVariation);
        size *= p.backgroundStarSizeMultiplier;
        bctx.beginPath(); bctx.arc(x, y, size, 0, Math.PI * 2); bctx.fill();
        bmctx.beginPath(); bmctx.arc(x, y, size, 0, Math.PI * 2); bmctx.fill();
        domPoints.push({ x, y, size });
      }
      bctx.restore(); bmctx.restore();

      // galaxy field: raster grid to allocate points into near/far
      nctx.save(); nctx.scale(DPR, DPR);
      fctx.save(); fctx.scale(DPR, DPR);
      for (let x = 0; x < owidth / DPR; x += step) {
        for (let y = 0; y < oheight / DPR; y += step) {
          const dx = x - oCenterX / DPR;
          const dy = y - oCenterY / DPR;
          const radius = Math.sqrt(dx * dx + dy * dy);
          if (radius < 3) continue;

          const decay = radialDecay(radius, maxRadius / DPR);
          const armInfo = getArmInfo(x * DPR, y * DPR, oCenterX, oCenterY, maxRadius, p);
          const result = calculateArmDensityProfile(armInfo, p);

          let density: number;
          let size: number;
          if (radius < p.coreRadius) {
            const coreProfile = Math.exp(-Math.pow(radius / p.coreRadius, 1.5));
            density = p.coreDensity * coreProfile * decay;
            size = (p.coreSizeMin + Math.random() * (p.coreSizeMax - p.coreSizeMin)) * p.armStarSizeMultiplier;
          } else {
            const n = noise2D(x * p.densityNoiseScale, y * p.densityNoiseScale);
            // 放大可调上限：允许 densityNoiseStrength > 1，但对调制进行下限夹紧，避免负值
            let modulation = 1.0 - p.densityNoiseStrength * (0.5 * (1.0 - n));
            if (modulation < 0.0) modulation = 0.0;
            density = result.density * decay * modulation;
            size = result.size;
          }
          density *= 0.8 + rng() * 0.4;
          if (rng() < density) {
            let ox = x; let oy = y;
            if (!reducedMotion && result.profile > 0.001) {
              const pitchAngle = Math.atan(1 / p.spiralB);
              const jitterAngle = armInfo.theta + pitchAngle + Math.PI / 2;
              const rand1 = rng() || 1e-6;
              const rand2 = rng();
              const gaussian = Math.sqrt(-2.0 * Math.log(rand1)) * Math.cos(2.0 * Math.PI * rand2);
              // 为抖动引入低频噪声混合，使之更不规律
              const chaos = 1 + (p.jitterChaos || 0) * noise2D(x * (p.jitterChaosScale || 0.02), y * (p.jitterChaosScale || 0.02));
              const randomMix = 0.7 + 0.6 * rng();
              const jitterAmount = p.jitterStrength * chaos * randomMix * result.profile * gaussian;
              ox += (jitterAmount * Math.cos(jitterAngle)) / DPR;
              oy += (jitterAmount * Math.sin(jitterAngle)) / DPR;
            }
            // assign to radial band for differential rotation
            const dxC = (ox * DPR) - oCenterX;
            const dyC = (oy * DPR) - oCenterY;
            const r = Math.sqrt(dxC * dxC + dyC * dyC);
            const rFrac = Math.max(0, Math.min(0.999, r / maxRadius));
            const bandIndex = Math.min(BAND_COUNT - 1, Math.floor(rFrac * BAND_COUNT));
            const target = bandCtx[bandIndex];
            const targetMask = bandMaskCtx[bandIndex];
            // 结构着色分类（核心/脊线/臂内/臂边/尘埃/外围），可通过开关启用
            if (structureColoring) {
              const cxCSS = oCenterX / DPR;
              const cyCSS = oCenterY / DPR;
              const rCSS = Math.sqrt((ox - cxCSS) ** 2 + (oy - cyCSS) ** 2);
              const aw = (armInfo.armWidth || 1) / DPR;
              const d = armInfo.distance / DPR;
              const noiseLocal = noise2D(x * 0.05, y * 0.05);
              // 简单阈值（可后续透出）：
              const coreR = p.coreRadius;
              const ridgeT = 0.7;   // 脊线
              const mainT = 0.5;    // 臂内
              const edgeT = 0.25;   // 臂边
              const dustOffset = 0.35 * aw;
              const dustHalf = 0.10 * aw * 0.5;
              const pal = palette;
              const al = layerAlphaRef?.current || defaultLayerAlpha;
              let fill = '#FFFFFF';
              let a = 1.0;
              if (rCSS < coreR) {
                fill = pal.core; a = al.core; // 核心黄白
              } else {
                const inDust = armInfo.inArm && Math.abs(d - dustOffset) <= dustHalf;
                if (inDust || noiseLocal < -0.2) {
                  fill = pal.dust; a = al.dust; // 尘埃带红褐
                } else if (result.profile > ridgeT) {
                  fill = pal.ridge; a = al.ridge; // 螺旋臂脊线（最亮）
                } else if (result.profile > mainT) {
                  fill = pal.armBright; a = al.armBright; // 臂内部亮区
                } else if (result.profile > edgeT) {
                  fill = pal.armEdge; a = al.armEdge; // 臂边缘淡蓝
                } else {
                  fill = pal.outer; a = al.outer; // 臂间/外围灰蓝
                }
              }
              // 颜色波动（仅显示）：基于坐标的小幅 HSL 扰动
              const baseHsl = hexToHsl(fill);
              const nh = noise2D(ox * p.colorNoiseScale, oy * p.colorNoiseScale);
              const ns = noise2D(ox * p.colorNoiseScale + 31.7, oy * p.colorNoiseScale + 11.3);
              const nl = noise2D(ox * p.colorNoiseScale + 77.1, oy * p.colorNoiseScale + 59.9);
              const h = (baseHsl.h + nh * p.colorJitterHue + 360) % 360;
              const s = clamp01(baseHsl.s + ns * p.colorJitterSat);
              const l = clamp01(baseHsl.l + nl * p.colorJitterLight);
              fill = hslToHex(h, s, l);
              const prevAlpha = target.globalAlpha;
              target.globalAlpha = prevAlpha * a;
              target.fillStyle = fill;
            } else {
              target.globalAlpha = 1;
              target.fillStyle = starBaseColor;
            }
            target.beginPath();
            // add slight deterministic jitter to break grid alignment
            const jx = (rng() - 0.5) * step;
            const jy = (rng() - 0.5) * step;
            target.arc(ox + jx, oy + jy, size, 0, Math.PI * 2);
            target.fill();
            // 掩膜：同样位置半径写入白色
            targetMask.beginPath();
            targetMask.fillStyle = '#FFFFFF';
            targetMask.arc(ox + jx, oy + jy, size, 0, Math.PI * 2);
            targetMask.fill();
            // 记录 band 星点（生成时坐标）
            bandPts[bandIndex].push({ x: ox + jx, y: oy + jy, size });
            if (structureColoring) { target.globalAlpha = 1; }
          }
        }
      }
      nctx.restore();
      fctx.restore();

      bandCtx.forEach(ctx => ctx.restore && ctx.restore());
      bandMaskCtx.forEach(ctx => ctx.restore && ctx.restore());
      bgLayerRef.current = bg;
      bandLayersRef.current = bands;
      bgMaskRef.current = bgMask;
      bandMaskLayersRef.current = bandMasks;
      nearLayerRef.current = null;
      farLayerRef.current = null;
      domStarPointsRef.current = domPoints;
      // 展平 band 点并附上 band 画布尺寸
      const flattened: Array<{x:number;y:number;size:number;band:number;bw:number;bh:number}> = [];
      for(let i=0;i<BAND_COUNT;i++){
        const bw = bands[i].width; const bh = bands[i].height;
        for(const p of bandPts[i]) flattened.push({ x:p.x, y:p.y, size:p.size, band:i, bw, bh });
      }
      bandStarPointsRef.current = flattened;
    };

    const drawFrame = (time: number) => {
      const width = canvas.width;
      const height = canvas.height;
      const w = width; const h = height;
      const cx = w / 2; const cy = h / 2;
      const doRotate = rotateRef.current && !reducedMotion;
      const rotNear = doRotate ? (time * 0.002) * (Math.PI / 180) : 0; // ~0.12deg/s
      const rotFar = doRotate ? (time * 0.0015) * (Math.PI / 180) : 0;

      ctx.save();
      ctx.clearRect(0, 0, w, h);

      // 1) Background layer (fills the whole screen, not scaled/rotated)
      const bg = bgLayerRef.current;
      const bgMask = bgMaskRef.current;
      if (bg) {
        ctx.save();
        ctx.globalAlpha = 1;
        ctx.drawImage(bg, 0, 0, w, h);
        ctx.restore();
      }

      // 2) Rotating galaxy layers (scaled around center) - differential rotation by radial bands
      const bands = bandLayersRef.current || [];
      const bandMasks = bandMaskLayersRef.current || [];
      const scale = paramsRef.current.galaxyScale ?? 1;
      // Prepare/update screen-space star mask composite
      if (!starMaskCompositeRef.current) {
        const c = document.createElement('canvas'); c.width = w; c.height = h; starMaskCompositeRef.current = c;
      }
      const mctx = starMaskCompositeRef.current!.getContext('2d')!;
      mctx.clearRect(0,0,w,h);
      if (bgMask) mctx.drawImage(bgMask, 0, 0, w, h);

      // Differential rotation: inner faster, outer slower
      const baseDegPerMs = 0.00025; // 内层基础角速度（降为原来的 1/10）
      for (let i = 0; i < bands.length; i++) {
        const band = bands[i];
        const bandMask = bandMasks[i];
        const rMid = (i + 0.5) / Math.max(1, bands.length); // 0..1
        const omegaDegPerMs = doRotate ? (baseDegPerMs / (0.25 + rMid)) : 0; // ω ~ 1/(0.25+r)
        const angle = omegaDegPerMs * time * (Math.PI / 180);
        ctx.save();
        ctx.translate(cx, cy);
        ctx.scale(scale, scale);
        ctx.rotate(angle);
        ctx.globalAlpha = 1;
        const bw = band.width, bh = band.height; const bcx = bw / 2, bcy = bh / 2;
        ctx.drawImage(band, -bcx, -bcy, bw, bh);
        ctx.restore();

        // 同步变换叠加掩膜
        if (bandMask) {
          mctx.save();
          mctx.translate(cx, cy);
          mctx.scale(scale, scale);
          mctx.rotate(angle);
          const bw2 = bandMask.width, bh2 = bandMask.height; const bcx2 = bw2/2, bcy2 = bh2/2;
          mctx.drawImage(bandMask, -bcx2, -bcy2, bw2, bh2);
          mctx.restore();
        }
      }

      // 原始风格：无呼吸云层、无区域楔形高亮、无暗角

      // 原始风格：不渲染点击喷发环

      ctx.restore();
    };

    const renderAll = () => { generateLayers(); };
    renderAllRef.current = renderAll;

    resize();
    renderAll();
    // 初始化热点（仅一次）
    genHotspots(36)
    // 单元细化：提高站点数量，单元尺寸约缩小至原来的 1/5
    genSites(600)
    const handleResize = () => { resize(); renderAll(); };
    window.addEventListener('resize', handleResize);
    
    // FPS sampling loop for auto quality
    let rafId: number;
    const tick = (now: number) => {
      const dt = now - lastFrameTimeRef.current;
      lastFrameTimeRef.current = now;
      const fps = dt > 0 ? 1000 / dt : 60;
      const t = now - lastFpsSampleTimeRef.current;
      fpsSamplesRef.current.push(fps);
      if (t > 1000) {
        // 仍然采样 FPS，但不再自动降质，保持形态一致
        fpsSamplesRef.current = [];
        lastFpsSampleTimeRef.current = now;
      }
      // frame draw
      drawFrame(now);
      rafId = requestAnimationFrame(tick);
    };
    rafId = requestAnimationFrame(tick);

    return () => {
      window.removeEventListener('resize', handleResize);
      cancelAnimationFrame(rafId);
    };
  }, [quality, reducedMotion, structureColoring]);

  // Re-generate layers when params change
  useEffect(() => {
    renderAllRef.current && renderAllRef.current();
  }, [params]);

  // 调整模块颜色/透明度或开关时重绘（仅影响着色，不改生成参数）
  useEffect(() => {
    renderAllRef.current && renderAllRef.current();
  }, [palette, layerAlpha, structureColoring]);

  // Angle→区域映射：将360°切为三等份
  const angleToRegion = React.useCallback((angleRad: number): 'emotion' | 'relation' | 'growth' => {
    const deg = ((angleRad * 180) / Math.PI + 360) % 360;
    if (deg < 120) return 'emotion';
    if (deg < 240) return 'relation';
    return 'growth';
  }, []);

  const pendingCardRegionRef = React.useRef<'emotion' | 'relation' | 'growth' | null>(null);

  const computeClickMeta = React.useCallback(({ clientX, clientY }: { clientX: number; clientY: number }) => {
    const canvas = canvasRef.current;
    if (!canvas) return null;
    const rect = canvas.getBoundingClientRect();
    if (rect.width === 0 || rect.height === 0) return null;
    const xPx = clientX - rect.left;
    const yPx = clientY - rect.top;
    const xPct = (xPx / rect.width) * 100;
    const yPct = (yPx / rect.height) * 100;
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    const angle = Math.atan2(clientY - cy, clientX - cx);
    const region = angleToRegion(angle);
    return { xPct, yPct, xPx, yPx, region };
  }, [angleToRegion]);

  const handleBackgroundMeta = React.useCallback((meta: { xPct: number; yPct: number; xPx: number; yPx: number; region: 'emotion' | 'relation' | 'growth' }) => {
    pendingCardRegionRef.current = meta.region;
    if (onCanvasClick) onCanvasClick({ x: meta.xPct, y: meta.yPct, region: meta.region });
    clickHs(meta.xPx, meta.yPx);
    try {
      addPlanetCard({ region: meta.region });
    } catch (error) {
      console.warn('[InteractiveGalaxyBackground] 生成星球失败:', error);
    }
  }, [addPlanetCard, clickHs, onCanvasClick]);

  const handleClick: React.MouseEventHandler<HTMLCanvasElement> = (e) => {
    const meta = computeClickMeta({ clientX: e.clientX, clientY: e.clientY });
    if (!meta) return;
    handleBackgroundMeta(meta);
  };

  const handleMouseMove: React.MouseEventHandler<HTMLCanvasElement> = (e) => {
    const rect = (e.target as HTMLCanvasElement).getBoundingClientRect();
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    const angle = Math.atan2(e.clientY - cy, e.clientX - cx);
    hoverRegionRef.current = angleToRegion(angle);
    hoverHs(e.clientX, e.clientY)
  };

  const backgroundIdToStarIdRef = React.useRef<Record<string, string>>({});

  const handleBandPointsReady = React.useCallback((pts: Array<{id:string;x:number;y:number;size:number;band:number;bw:number;bh:number;color?:string;litColor?:string}>) => {
    domBandPointsRef.current = pts;
    if (typeof window === 'undefined') return;
    if (!constellationStars.length) return;
    const width = window.innerWidth || 1;
    const height = window.innerHeight || 1;
    const mapping: Record<string, string> = {};
    const used = new Set<string>();
    pts.forEach(pt => {
      let nearest: string | null = null;
      let nearestDist = Infinity;
      for (const star of constellationStars) {
        const sx = (star.x / 100) * width;
        const sy = (star.y / 100) * height;
        const dx = sx - pt.x;
        const dy = sy - pt.y;
        const dist = dx * dx + dy * dy;
        if (dist < nearestDist) {
          nearestDist = dist;
          nearest = star.id;
        }
      }
      if (nearest && !used.has(pt.id)) {
        mapping[pt.id] = nearest;
        used.add(pt.id);
      }
    });
    backgroundIdToStarIdRef.current = mapping;
    if (typeof window !== 'undefined') {
      (window as any).__galaxyHighlightMap = mapping;
    }
  }, [constellationStars]);

  const handleBgPointsReady = React.useCallback((pts: Array<{x:number;y:number;size:number}>) => {
    domStarPointsRef.current = pts;
  }, []);

  const highlightFallback = React.useMemo(() => normalizeHex(litPalette.core ?? '#FFE2B0') ?? '#FFE2B0', [litPalette.core]);
  useEffect(() => {
    setGalaxyHighlightColor(highlightFallback);
  }, [highlightFallback, setGalaxyHighlightColor]);

  const paletteLitMap = React.useMemo(() => {
    const map = new Map<string, string>();
    const entries: Array<[keyof typeof defaultPalette, string]> = [
      ['core', palette.core],
      ['ridge', palette.ridge],
      ['armBright', palette.armBright],
      ['armEdge', palette.armEdge],
      ['hii', palette.hii],
      ['dust', palette.dust],
      ['outer', palette.outer],
    ];
    entries.forEach(([key, base]) => {
      const normalizedBase = normalizeHex(base);
      const litValue = normalizeHex((litPalette as any)[key] ?? base);
      if (normalizedBase && litValue) {
        map.set(normalizedBase, litValue);
      }
    });
    return map;
  }, [palette, litPalette, highlightFallback]);

  const mapHighlightsToStars = React.useCallback((points: Array<{id?:string;x:number;y:number;color?:string;litColor?:string}>) => {
    const matches: Array<{ starId: string; color: string }> = [];
    const mapping = backgroundIdToStarIdRef.current;
    const fallbackColor = highlightFallback;
    points.forEach(pt => {
      if (!pt?.id) return;
      const starId = mapping[pt.id];
      if (!starId) return;
      const highlight = constellationHighlights[starId]?.color;
      const baseColor = normalizeHex(pt.color ?? '');
      const mappedLit = baseColor ? paletteLitMap.get(baseColor) : undefined;
      const sourceColor = normalizeHex(highlight ?? mappedLit ?? pt.litColor ?? fallbackColor) ?? fallbackColor;
      matches.push({ starId, color: sourceColor });
    });
    if (typeof window !== 'undefined') {
      (window as any).__galaxyMappedHighlights = matches;
    }
    return matches;
  }, [constellationHighlights, highlightFallback, paletteLitMap]);
  const resolveBandHighlight = React.useCallback((bandId?: string, source?: { color?: string; litColor?: string }) => {
    if (bandId) {
      const starId = backgroundIdToStarIdRef.current[bandId];
      if (starId) {
        const highlight = constellationHighlights[starId];
        if (highlight?.color) {
          return highlight.color;
        }
      }
    }
    const baseColor = normalizeHex(source?.color ?? '');
    if (baseColor && paletteLitMap.has(baseColor)) {
      return paletteLitMap.get(baseColor)!;
    }
    const litSource = normalizeHex(source?.litColor ?? '');
    if (litSource) {
      return litSource;
    }
    return highlightFallback;
  }, [constellationHighlights, highlightFallback, paletteLitMap]);

  const colorizeBandPoints = React.useCallback((points: Array<{id:string;band:number;x:number;y:number;size:number;color?:string;litColor?:string}>) => {
    return points.map(point => {
      const resolved = resolveBandHighlight(point.id, point);
      const normalized = normalizeHex(resolved) ?? highlightFallback;
      return {
        ...point,
        color: normalized,
        litColor: normalized,
      };
    });
  }, [resolveBandHighlight, highlightFallback]);

  return (
    <>
      <canvas
        ref={canvasRef}
        className={
          className || 'fixed top-0 left-0 w-full h-full -z-10'
        }
        onClick={handleClick}
        onMouseMove={handleMouseMove}
      />
      <GalaxyLightweight
          params={params}
          palette={palette}
          litPalette={litPalette}
          structureColoring={structureColoring}
          armCount={defaultParams.armCount}
          scale={params.galaxyScale}
          onBandPointsReady={handleBandPointsReady}
          onBgPointsReady={handleBgPointsReady}
          persistentHighlights={persistentHighlights}
        />
      {/* DOM/SVG 脉冲（无需像素读回）：只使用BG层星点位置 */}
      <GalaxyDOMPulseOverlay
        pointsRef={domStarPointsRef}
        bandPointsRef={domBandPointsRef}
        scale={params.galaxyScale}
        rotateEnabled={rotateEnabled}
        config={glowCfg}
        resolveHighlightColor={resolveBandHighlight}
        resolveClickMeta={computeClickMeta}
        onBackgroundClick={handleBackgroundMeta}
        onPersistHighlights={(points) => {
      if (!points.length) {
        return;
      }
          if (process.env.NODE_ENV !== 'production') {
            console.debug('[InteractiveGalaxyBackground] persist highlights', points);
          }
          const coloredPoints = colorizeBandPoints(points);
          setPersistentHighlights(prev => {
            const map = new Map<string, typeof points[number]>()
            colorizeBandPoints(prev).forEach(item => map.set(item.id, item))
            coloredPoints.forEach(item => {
              if (map.has(item.id)) {
                map.delete(item.id)
              }
              map.set(item.id, item)
            })
            const merged = Array.from(map.values())
            if (areHighlightListsEqual(prev, merged)) {
              return prev
            }
            return merged
          })
          const mapped = mapHighlightsToStars(coloredPoints);
          if (mapped.length) {
            setGalaxyHighlights(mapped);
          }
          if (pendingCardRegionRef.current) {
            const region = pendingCardRegionRef.current;
            pendingCardRegionRef.current = null;
            // 延迟与脉冲动画对齐，让卡片在星星闪烁完成后出现
            window.setTimeout(() => {
              try {
                drawInspirationCard(region as any);
              } catch (error) {
                console.warn('drawInspirationCard 调用失败:', error);
              }
            }, 120);
          }
        }}
      />
    </>
  );
};

export default React.memo(InteractiveGalaxyBackground);

```

`staroracle-app_allreact/src/store/useGalaxyStore.ts`:

```ts
import { create } from 'zustand'

export type GalaxyRegion = 'emotion' | 'relation' | 'growth'

export interface Hotspot {
  id: string
  xPct: number // 0-100
  yPct: number // 0-100
  region: GalaxyRegion
  seed: number
  cooldownUntil?: number
}

export interface Ripple {
  id: string
  x: number
  y: number
  startAt: number
  duration: number
}

interface GalaxyState {
  width: number
  height: number
  hotspots: Hotspot[]
  ripples: Ripple[]
  hoveredId?: string
  setCanvasSize: (w: number, h: number) => void
  generateHotspots: (count?: number) => void
  hoverAt: (x: number, y: number) => void
  clickAt: (x: number, y: number) => void
  cleanupFx: () => void
}

const clamp = (v: number, min: number, max: number) => Math.max(min, Math.min(max, v))

const angleToRegion = (angleRad: number): GalaxyRegion => {
  const deg = ((angleRad * 180) / Math.PI + 360) % 360
  if (deg < 120) return 'emotion'
  if (deg < 240) return 'relation'
  return 'growth'
}

export const useGalaxyStore = create<GalaxyState>((set, get) => ({
  width: 0,
  height: 0,
  hotspots: [],
  ripples: [],
  setCanvasSize: (w, h) => set({ width: w, height: h }),
  generateHotspots: (count = 30) => {
    const { width, height } = get()
    if (!width || !height) return
    const centerX = width / 2
    const centerY = height / 2
    const maxR = Math.min(width, height) * 0.4
    const hs: Hotspot[] = []
    for (let i = 0; i < count; i++) {
      // 在半径[0.2,1]*maxR 区间随机生成，避开中心小区域
      const rr = 0.2 + 0.8 * Math.random()
      const r = rr * maxR
      const t = Math.random() * Math.PI * 2
      const x = centerX + r * Math.cos(t)
      const y = centerY + r * Math.sin(t)
      const region = angleToRegion(Math.atan2(y - centerY, x - centerX))
      hs.push({
        id: `hs_${i}_${Date.now()}`,
        xPct: clamp((x / width) * 100, 0, 100),
        yPct: clamp((y / height) * 100, 0, 100),
        region,
        seed: i,
      })
    }
    set({ hotspots: hs })
  },
  hoverAt: (x, y) => {
    const { width, height, hotspots } = get()
    if (!width || !height) return
    const px = clamp((x / width) * 100, 0, 100)
    const py = clamp((y / height) * 100, 0, 100)
    let minD = Infinity
    let id: string | undefined
    for (const h of hotspots) {
      const dx = px - h.xPct
      const dy = py - h.yPct
      const d = Math.hypot(dx, dy)
      if (d < minD && d < 8) { // 近距离 hover
        minD = d
        id = h.id
      }
    }
    set({ hoveredId: id })
  },
  clickAt: (x, y) => {
    const { width, height, hotspots, ripples } = get()
    if (!width || !height) return
    // 记录两圈涟漪
    const now = performance.now()
    const rp: Ripple[] = [
      { id: `rp_${now}`, x, y, startAt: now, duration: 900 },
      { id: `rp_${now}_2`, x, y, startAt: now + 120, duration: 900 },
    ]
    // 命中热点进入冷却
    const px = clamp((x / width) * 100, 0, 100)
    const py = clamp((y / height) * 100, 0, 100)
    const hs = hotspots.map(h => {
      const d = Math.hypot(px - h.xPct, py - h.yPct)
      if (d < 6) return { ...h, cooldownUntil: now + 60000 }
      return h
    })
    set({ ripples: ripples.concat(rp), hotspots: hs })
  },
  cleanupFx: () => {
    const now = performance.now()
    set(state => ({
      ripples: state.ripples.filter(r => now - r.startAt < r.duration),
    }))
  }
}))


```

`staroracle-app_allreact/src/store/useStarStore.ts`:

```ts
import { create } from 'zustand';
import { Star, Connection, Constellation, PlanetRecord, PlanetVariant } from '../types';
import { generateRandomStarImage } from '../utils/imageUtils';
import { 
  analyzeStarContent, 
  generateSmartConnections,
  generateAIResponse,
  getAIConfig as getAIConfigFromUtils
} from '../utils/aiTaggingUtils';
import { instantiateTemplate } from '../utils/constellationTemplates';
import { getRandomInspirationCard, InspirationCard, GalaxyRegion } from '../utils/inspirationCards';
import { ConstellationTemplate } from '../types';

const normalizeHighlightHex = (color: unknown): string => {
  if (!color && color !== 0) return '#FFFFFF';
  let value = typeof color === 'string' ? color.trim() : String(color).trim();
  if (!value.startsWith('#')) return '#FFFFFF';
  if (value.length === 4) {
    value = `#${value[1]}${value[1]}${value[2]}${value[2]}${value[3]}${value[3]}`;
  }
  if (value.length !== 7) return '#FFFFFF';
  return value.toUpperCase();
};

interface StarPosition {
  x: number;
  y: number;
}

interface StarState {
  constellation: Constellation;
  activeStarId: string | null;
  highlightedStarId: string | null;
  galaxyHighlights: Record<string, { color: string }>;
  galaxyHighlightColor: string;
  isAsking: boolean;
  isLoading: boolean; // New state to track loading during star creation
  pendingStarPosition: StarPosition | null;
  currentInspirationCard: InspirationCard | null;
  hasTemplate: boolean;
  templateInfo: { name: string; element: string } | null;
  lastCreatedStarId: string | null;
  planetCards: PlanetRecord[];
  addStar: (question: string) => Promise<Star>;
  drawInspirationCard: (region?: GalaxyRegion) => InspirationCard;
  useInspirationCard: () => void;
  dismissInspirationCard: () => void;
  viewStar: (id: string | null) => void;
  hideStarDetail: () => void;
  setIsAsking: (isAsking: boolean, position?: StarPosition) => void;
  regenerateConnections: () => void;
  applyTemplate: (template: ConstellationTemplate) => void;
  clearConstellation: () => void;
  updateStarTags: (starId: string, newTags: string[]) => void;
  setGalaxyHighlights: (entries: Array<{ starId: string; color?: string }>) => void;
  setGalaxyHighlightColor: (color: string) => void;
  addPlanetCard: (params?: { region?: GalaxyRegion }) => PlanetRecord;
}

// Generate initial empty constellation
const generateEmptyConstellation = (): Constellation => {
  return {
    stars: [],
    connections: []
  };
};

export const useStarStore = create<StarState>((set, get) => {
  // AIConfig getter - 使用集中式的配置管理
  const getAIConfig = () => {
    // 使用aiTaggingUtils中的getAIConfig来获取配置
    // 该函数会自动处理优先级：用户配置 > 系统默认配置 > 空配置
    return getAIConfigFromUtils();
  };

  const regionVariantMap: Record<GalaxyRegion, PlanetVariant> = {
    emotion: 'ocean',
    relation: 'gas',
    growth: 'desert'
  };

  const pickVariant = (region?: GalaxyRegion): PlanetVariant => {
    if (region && regionVariantMap[region]) {
      return regionVariantMap[region];
    }
    const variants: PlanetVariant[] = ['gas', 'ocean', 'lava', 'ice', 'desert'];
    return variants[Math.floor(Math.random() * variants.length)];
  };

  return {
    constellation: generateEmptyConstellation(),
    activeStarId: null, // 确保初始状态为null
    highlightedStarId: null,
    galaxyHighlights: {},
    galaxyHighlightColor: '#FFE2B0',
    isAsking: false,
    isLoading: false, // Initialize loading state as false
    pendingStarPosition: null,
    currentInspirationCard: null,
    hasTemplate: false,
    templateInfo: null,
    lastCreatedStarId: null,
    planetCards: [],
    
    addStar: async (question: string) => {
      const { constellation, pendingStarPosition } = get();
      const { stars } = constellation;
      
      console.log(`===== User asked a question =====`);
      console.log(`Question: "${question}"`);
      
      // Set loading state to true
      set({ isLoading: true });
      
      // Get AI configuration
      const aiConfig = getAIConfig();
      console.log('Retrieved AI config result:', {
        hasApiKey: !!aiConfig.apiKey,
        hasEndpoint: !!aiConfig.endpoint,
        provider: aiConfig.provider,
        model: aiConfig.model
      });
      
      // Create new star at the clicked position or random position first (with placeholder answer)
      const x = pendingStarPosition?.x ?? (Math.random() * 70 + 15); // 15-85%
      const y = pendingStarPosition?.y ?? (Math.random() * 70 + 15); // 15-85%
      
      // Create placeholder star (we'll update it with AI response later)
      const newStar: Star = {
        id: `star-${Date.now()}`,
        x,
        y,
        size: Math.random() * 1.5 + 2.0, // Will be updated based on AI analysis
        brightness: 0.6, // Placeholder brightness
        question,
        answer: '', // Empty initially, will be filled by streaming
        imageUrl: generateRandomStarImage(),
        createdAt: new Date(),
        isSpecial: false, // Will be updated based on AI analysis
        tags: [], // Will be filled by AI analysis
        primary_category: 'philosophy_and_existence', // Placeholder
        emotional_tone: ['探寻中'], // Placeholder
        question_type: '探索型', // Placeholder
        insight_level: { value: 1, description: '星尘' }, // Placeholder
        initial_luminosity: 10, // Placeholder
        connection_potential: 3, // Placeholder
        suggested_follow_up: '', // Will be filled by AI analysis
        card_summary: question, // Placeholder
        isTemplate: false,
        isStreaming: true, // Mark as currently streaming
      };
      
      // Add placeholder star to constellation immediately for better UX
      const updatedStars = [...stars, newStar];
      set({
        constellation: {
          stars: updatedStars,
          connections: constellation.connections, // Keep existing connections for now
        },
        activeStarId: newStar.id, // Show the star being created
        highlightedStarId: newStar.id,
        isAsking: false,
        pendingStarPosition: null,
        lastCreatedStarId: newStar.id,
      });
      
      // Generate AI response with streaming
      console.log('Starting AI response generation with streaming...');
      let answer: string;
      let streamingAnswer = '';
      
      try {
        // Set up streaming callback
        const onStream = (chunk: string) => {
          streamingAnswer += chunk;
          
          // Update star with streaming content in real time
          set(state => ({
            constellation: {
              ...state.constellation,
              stars: state.constellation.stars.map(star => 
                star.id === newStar.id 
                  ? { ...star, answer: streamingAnswer }
                  : star
              )
            }
          }));
        };
        
        answer = await generateAIResponse(question, aiConfig, onStream);
        console.log(`Got AI response: "${answer}"`);
        
        // Ensure we have a valid answer
        if (!answer || answer.trim().length === 0) {
          throw new Error('Empty AI response');
        }
      } catch (error) {
        console.warn('AI response failed, using fallback:', error);
        // Use fallback response generation
        answer = generateFallbackResponse(question);
        console.log(`Fallback response: "${answer}"`);
        
        // Update with fallback answer
        streamingAnswer = answer;
      }
      
      // Analyze content with AI for tags and categorization
      const analysis = await analyzeStarContent(question, answer, aiConfig);
      
      // Update star with final AI analysis results
      const finalStar: Star = {
        ...newStar,
        // 根据洞察等级调整星星大小，洞察等级越高，星星越大
        size: Math.random() * 1.5 + 2.0 + (analysis.insight_level?.value || 0) * 0.5, // 2.0-6.5px
        // 亮度也受洞察等级影响
        brightness: (analysis.initial_luminosity || 60) / 100, // 转换为0-1范围
        answer: streamingAnswer || answer, // Use final streamed answer
        isSpecial: Math.random() < 0.12 || (analysis.insight_level?.value || 0) >= 4, // 启明星和超新星自动成为特殊星
        tags: analysis.tags,
        primary_category: analysis.primary_category,
        emotional_tone: analysis.emotional_tone,
        question_type: analysis.question_type,
        insight_level: analysis.insight_level,
        initial_luminosity: analysis.initial_luminosity,
        connection_potential: analysis.connection_potential,
        suggested_follow_up: analysis.suggested_follow_up,
        card_summary: analysis.card_summary,
        isStreaming: false, // Streaming completed
      };
      
      console.log('⭐ Final star with AI analysis:', {
        question: finalStar.question,
        answer: finalStar.answer,
        answerLength: finalStar.answer.length,
        tags: finalStar.tags,
        primary_category: finalStar.primary_category,
        emotional_tone: finalStar.emotional_tone,
        insight_level: finalStar.insight_level,
        connection_potential: finalStar.connection_potential
      });
      
      // Update with final star and regenerate connections
      const finalStars = updatedStars.map(star => 
        star.id === newStar.id ? finalStar : star
      );
      const smartConnections = generateSmartConnections(finalStars);
      
      set({
        constellation: {
          stars: finalStars,
          connections: smartConnections,
        },
        isLoading: false, // Set loading state back to false
      });
      
      return finalStar;
    },

    drawInspirationCard: (region?: GalaxyRegion) => {
      const card = getRandomInspirationCard(region);
      console.log('🌟 Drawing inspiration card:', card.question);
      set({ currentInspirationCard: card });
      return card;
    },

    useInspirationCard: () => {
      const { currentInspirationCard } = get();
      if (currentInspirationCard) {
        console.log('✨ Using inspiration card for new star');
        // Start asking mode with the inspiration card question
        set({ 
          isAsking: true,
          currentInspirationCard: null 
        });
        
        // Pre-fill the question in the oracle input
        // This will be handled by the OracleInput component
      }
    },

    dismissInspirationCard: () => {
      console.log('👋 Dismissing inspiration card');
      set({ currentInspirationCard: null });
    },
    
    viewStar: (id: string | null) => {
      set(state => ({
        activeStarId: id,
        highlightedStarId: id ?? state.highlightedStarId,
      }));
      console.log(`👁️ Viewing star: ${id}`);
    },
    
    hideStarDetail: () => {
      set({ activeStarId: null });
      console.log('👁️ Hiding star detail');
    },
    
    setIsAsking: (isAsking: boolean, position?: StarPosition) => {
      set({ 
        isAsking,
        pendingStarPosition: position ?? null,
      });
    },

    setGalaxyHighlights: (entries) => {
      const fallback = get().galaxyHighlightColor;
      const next: Record<string, { color: string }> = {};
      entries.forEach(({ starId, color }) => {
        const resolved = color ?? fallback;
        next[starId] = { color: normalizeHighlightHex(resolved) };
      });
      set({ galaxyHighlights: next });
      if (typeof window !== 'undefined') {
        (window as any).__galaxyHighlights = next;
      }
    },

    setGalaxyHighlightColor: (color) => {
      set({ galaxyHighlightColor: normalizeHighlightHex(color) });
    },

    addPlanetCard: (params) => {
      const region = params?.region;
      const newPlanet: PlanetRecord = {
        id: `planet-${Date.now()}-${Math.floor(Math.random() * 9999)}`,
        seed: Math.floor(Math.random() * 10_000_000),
        variant: pickVariant(region),
        region,
        createdAt: Date.now()
      };

      set(state => {
        const next = [...state.planetCards, newPlanet];
        return { planetCards: next.slice(-32) };
      });

      return newPlanet;
    },
    
    regenerateConnections: () => {
      const { constellation } = get();
      const smartConnections = generateSmartConnections(constellation.stars);
      
      console.log('Regenerating connections, found:', smartConnections.length);
      
      set({
        constellation: {
          ...constellation,
          connections: smartConnections,
        },
      });
    },

    applyTemplate: (template: ConstellationTemplate) => {
      console.log(`🌟 Applying template: ${template.chineseName}`);
      
      // Instantiate the template
      const { stars: templateStars, connections: templateConnections } = instantiateTemplate(template);
      
      // Get current user stars (non-template stars)
      const { constellation } = get();
      const userStars = constellation.stars.filter(star => !star.isTemplate);
      
      // Combine template stars with existing user stars
      const allStars = [...templateStars, ...userStars];
      
      // Generate connections including both template and smart connections
      const smartConnections = generateSmartConnections(allStars);
      const allConnections = [...templateConnections, ...smartConnections];
      
      set({
        constellation: {
          stars: allStars,
          connections: allConnections,
        },
        activeStarId: null, // 清除活动星星ID，避免阻止按钮点击
        highlightedStarId: null,
        hasTemplate: true,
        templateInfo: {
          name: template.chineseName,
          element: template.element
        }
      });
      
      console.log(`✨ Applied template with ${templateStars.length} stars and ${templateConnections.length} connections`);
    },

    clearConstellation: () => {
      set({
        constellation: generateEmptyConstellation(),
        activeStarId: null,
        highlightedStarId: null,
        galaxyHighlights: {},
        hasTemplate: false,
        templateInfo: null,
      });
      console.log('🧹 Cleared constellation');
    },

    updateStarTags: (starId: string, newTags: string[]) => {
      set(state => {
        // Update the star with new tags
        const updatedStars = state.constellation.stars.map(star => 
          star.id === starId 
            ? { ...star, tags: newTags } 
            : star
        );
        
        // Regenerate connections with updated tags - ensure non-null values
        const newConnections = generateSmartConnections(updatedStars);
        
        return {
          constellation: {
            stars: updatedStars,
            connections: newConnections
          }
        };
      });
      
      console.log(`🏷️ Updated tags for star ${starId}`);
    }
  };
});

// Fallback response generator for when AI fails
const generateFallbackResponse = (question: string): string => {
  const lowerQuestion = question.toLowerCase();
  
  // Question-specific responses for better relevance
  if (lowerQuestion.includes('爱') || lowerQuestion.includes('恋') || lowerQuestion.includes('love') || lowerQuestion.includes('relationship')) {
    const loveResponses = [
      "当心灵敞开时，星辰便会排列成行。爱会流向那些勇敢拥抱脆弱的人。",
      "如同双星相互环绕，真正的连接需要独立与统一并存。",
      "当灵魂以真实的光芒闪耀时，宇宙会密谋让它们相遇。",
      "爱不是被找到的，而是被认出的，就像在异国天空中看到熟悉的星座。",
      "真爱如月圆之夜的潮汐，既有规律可循，又充满神秘的力量。",
    ];
    return loveResponses[Math.floor(Math.random() * loveResponses.length)];
  }
  
  if (lowerQuestion.includes('目标') || lowerQuestion.includes('意义') || lowerQuestion.includes('purpose') || lowerQuestion.includes('meaning')) {
    const purposeResponses = [
      "你的目标如星云诞生恒星般展开——缓慢、美丽、不可避免。",
      "宇宙不会询问星辰的目标；它们只是闪耀。你也应如此。",
      "意义从你的天赋与世界需求的交汇处涌现，如光线穿过三棱镜般折射。",
      "你的目标写在你最深的喜悦和服务意愿的语言中。",
      "生命的意义不在远方，而在每一个当下的选择与行动中绽放。",
    ];
    return purposeResponses[Math.floor(Math.random() * purposeResponses.length)];
  }
  
  if (lowerQuestion.includes('成功') || lowerQuestion.includes('事业') || lowerQuestion.includes('成就') || lowerQuestion.includes('success') || lowerQuestion.includes('career') || lowerQuestion.includes('achieve')) {
    const successResponses = [
      "成功如超新星般绽放——突然的辉煌源于长久耐心的燃烧。",
      "通往成就的道路如银河系的螺旋臂般蜿蜒，每个转弯都揭示新的可能性。",
      "真正的成功不在于积累，而在于你为他人黑暗中带来的光明。",
      "如行星找到轨道般，成功来自于将你的努力与自然力量对齐。",
      "成功的种子早已种在你的内心，只需要时间和坚持的浇灌。",
    ];
    return successResponses[Math.floor(Math.random() * successResponses.length)];
  }
  
  if (lowerQuestion.includes('恐惧') || lowerQuestion.includes('害怕') || lowerQuestion.includes('焦虑') || lowerQuestion.includes('fear') || lowerQuestion.includes('anxiety') || lowerQuestion.includes('worry')) {
    const fearResponses = [
      "恐惧是你潜能投下的阴影。转向光明，看它消失。",
      "勇气不是没有恐惧，而是在可能性的星光下与之共舞。",
      "如流星进入大气层时燃烧得明亮，转化需要拥抱火焰。",
      "你的恐惧是古老的星尘；承认它们，然后让它们在宇宙风中飘散。",
      "恐惧是成长的前奏，如黎明前的黑暗，预示着光明的到来。",
    ];
    return fearResponses[Math.floor(Math.random() * fearResponses.length)];
  }
  
  if (lowerQuestion.includes('未来') || lowerQuestion.includes('将来') || lowerQuestion.includes('命运') || lowerQuestion.includes('future') || lowerQuestion.includes('destiny')) {
    const futureResponses = [
      "未来是你通过连接选择之星而创造的星座。",
      "时间如恒星风般流淌，将可能性的种子带到肥沃的时刻。",
      "你的命运不像恒星般固定，而像彗星般流动，由你的方向塑造。",
      "未来以直觉的语言低语；用心聆听，而非恐惧。",
      "明天的轮廓隐藏在今日的每一个微小决定中。",
    ];
    return futureResponses[Math.floor(Math.random() * futureResponses.length)];
  }
  
  if (lowerQuestion.includes('快乐') || lowerQuestion.includes('幸福') || lowerQuestion.includes('喜悦') || lowerQuestion.includes('happiness') || lowerQuestion.includes('joy') || lowerQuestion.includes('fulfillment')) {
    const happinessResponses = [
      "快乐不是目的地，而是穿越体验宇宙的旅行方式。",
      "喜悦如星光在水面闪烁——存在于你选择看见它的每个时刻。",
      "满足来自于将你内在的星座与外在的表达对齐。",
      "真正的快乐从内心辐射，如恒星产生自己的光和热。",
      "幸福如花朵，在感恩的土壤中最容易绽放。",
    ];
    return happinessResponses[Math.floor(Math.random() * happinessResponses.length)];
  }
  
  // General mystical responses for other questions
  const generalResponses = [
    "星辰低语着未曾踏足的道路，然而你的旅程始终忠于内心的召唤。",
    "如月光映照水面，你所寻求的既在那里又不在那里。请深入探寻。",
    "古老的光芒穿越时空抵达你的眸；耐心将揭示匆忙所掩盖的真相。",
    "宇宙编织着可能性的图案。你的问题已经包含了它的答案。",
    "天体尽管相距遥远却和谐共舞。在生命的盛大芭蕾中找到你的节拍。",
    "当星系在虚空中螺旋前进时，你的道路在黑暗中蜿蜒向着遥远的光明。",
    "你思想的星云包含着尚未诞生的恒星种子。请滋养它们。",
    "时间如恒星风般流淌，将你存在的景观塑造成未知的形态。",
    "星辰之间的虚空并非空无，而是充满潜能。拥抱你生命中的空间。",
    "你的问题在宇宙中回响，带着星光承载的智慧归来。",
    "宇宙无目的地扩张。你的旅程无需超越自身的理由。",
    "星座是我们强加给混沌的图案。从随机的经验之星中创造意义。",
    "你看到的光芒很久以前就开始了它的旅程。相信所揭示的，即使延迟。",
    "宇宙尘埃变成恒星再变成尘埃。所有的转化对你都是可能的。",
    "你意图的引力将体验拉入围绕你的轨道。明智地选择你所吸引的。",
  ];
  
  return generalResponses[Math.floor(Math.random() * generalResponses.length)];
};

```
