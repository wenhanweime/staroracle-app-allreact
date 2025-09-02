import { useState, useEffect, useRef } from 'react';
import { Capacitor } from '@capacitor/core';
import { ChatOverlay } from '../plugins/ChatOverlay';
import { generateAIResponse } from '../utils/aiTaggingUtils';
import { useChatStore } from '../store/useChatStore';

export interface ChatMessage {
  id: string;
  text: string;
  isUser: boolean;
  timestamp: number;
}

export const useNativeChatOverlay = () => {
  // 原生端统一接管消息与流式时，关闭JS侧心跳同步
  const NATIVE_STREAM_ENABLED = true;
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  
  // 新增状态 - 对应Web版本的完整功能
  const [conversationTitle, setConversationTitle] = useState('');
  const [keyboardHeight, setKeyboardHeight] = useState(0);
  const [viewportHeight, setViewportHeight] = useState(window.innerHeight);
  
  // 使用聊天store来保持消息同步
  const { 
    messages: storeMessages, 
    addUserMessage, 
    addStreamingAIMessage, 
    updateStreamingMessage,
    finalizeStreamingMessage,
    setLoading,
    isLoading: chatIsLoading,
    conversationTitle: storeTitleFull,
    generateConversationTitle
  } = useChatStore();

  useEffect(() => {
    if (!Capacitor.isNativePlatform()) {
      console.log('🌐 Web环境，使用React ChatOverlay');
      return;
    }

    console.log('📱 原生环境，设置ChatOverlay监听器');

    // 监听浮窗状态变化
    const overlayStateListener = ChatOverlay.addListener('overlayStateChanged', (data: any) => {
      console.log('📱 浮窗状态变化:', data);
      console.log('📱 设置isOpen状态为:', data.isOpen);
      setIsOpen(data.isOpen);
    });
    
    // 新增监听器 - 对应Web版本的各种状态更新
    const followUpProcessedListener = ChatOverlay.addListener('followUpProcessed', () => {
      console.log('📱 后续问题处理完成');
    });
    
    const conversationTitleListener = ChatOverlay.addListener('conversationTitleChanged', (data: any) => {
      console.log('📱 对话标题变化:', data.title);
      setConversationTitle(data.title);
    });
    
    const keyboardHeightListener = ChatOverlay.addListener('keyboardHeightChanged', (data: any) => {
      console.log('📱 键盘高度变化:', data.height);
      setKeyboardHeight(data.height);
    });
    
    const viewportHeightListener = ChatOverlay.addListener('viewportHeightChanged', (data: any) => {
      console.log('📱 视口高度变化:', data.height);
      setViewportHeight(data.height);
    });

    return () => {
      overlayStateListener.then(listener => listener.remove());
      followUpProcessedListener.then(listener => listener.remove());
      conversationTitleListener.then(listener => listener.remove());
      keyboardHeightListener.then(listener => listener.remove());
      viewportHeightListener.then(listener => listener.remove());
    };
  }, []);

  // 🚨 【关键新增】状态守卫：防止AI流式响应与用户操作的竞争条件
  const lastSentOverlayStateRef = useRef<{ expanded: boolean; visible: boolean } | null>(null);
  
  // 🚨 【关键修复】添加消息同步节流和去重机制
  const lastSyncMessagesRef = useRef<string>('');
  const syncThrottleRef = useRef<NodeJS.Timeout | null>(null);
  // 🚀 针对AI流式：改为节拍式推送，避免被去抖合并成一次性
  const streamingLoopRef = useRef<NodeJS.Timeout | null>(null);
  const latestNativeMessagesRef = useRef<any[]>([]);
  
  // 🔧 优化同步：监听store中的消息变化并同步到原生ChatOverlay
  useEffect(() => {
    if (!Capacitor.isNativePlatform() || storeMessages.length === 0) {
      return;
    }

    // 原生流式启用时，不再由JS整表心跳驱动消息同步
    if (NATIVE_STREAM_ENABLED) {
      return;
    }

    console.log('📱 [优化同步] 消息列表发生变化，同步到原生ChatOverlay');
    console.log('📱 当前store消息数量:', storeMessages.length);
    
    // 将store的ChatMessage转换为原生可识别的格式
    const nativeMessages = storeMessages.map(msg => ({
      id: msg.id,
      text: msg.text,
      isUser: msg.isUser,
      timestamp: msg.timestamp.getTime() // 转换Date为毫秒时间戳
    }));
    // 更新最新消息引用（供流式循环使用）
    latestNativeMessagesRef.current = nativeMessages;

    // 🚨 【关键修复】消息内容去重：生成消息内容的哈希值
    const messagesHash = JSON.stringify(nativeMessages.map(msg => ({
      id: msg.id,
      text: msg.text,
      isUser: msg.isUser
    })));
    
    // 如果消息内容没有变化，跳过同步
    if (lastSyncMessagesRef.current === messagesHash) {
      console.log('📱 [去重] 消息内容未变化，跳过同步');
      return;
    }
    
    lastSyncMessagesRef.current = messagesHash;

    // 🚨 【关键修复】基于内容变化的智能同步策略
    // 分析消息变化类型
    const lastMessage = nativeMessages[nativeMessages.length - 1];
    const isUserMessage = lastMessage?.isUser;
    const isNewMessage = nativeMessages.length !== (lastSyncMessagesRef.current ? JSON.parse(lastSyncMessagesRef.current).length : 0);
    // 直接基于store消息的标志判断是否处于流式
    const lastStoreMsg = storeMessages[storeMessages.length - 1];
    const isStreamingActive = !!(lastStoreMsg && !lastStoreMsg.isUser && lastStoreMsg.isStreaming);

    // 流式期间：采用“节拍式”推送，固定节奏发送最新内容（避免被去抖合并）
    if (isStreamingActive) {
      if (!streamingLoopRef.current) {
        const beat = 80; // ms/次，可调 60–120ms
        console.log('🚀 [流式] 启动原生同步节拍循环:', beat, 'ms');
        const tick = async () => {
          streamingLoopRef.current = setTimeout(async () => {
            try {
              await ChatOverlay.updateMessages({ messages: latestNativeMessagesRef.current });
              console.log('✅ [流式节拍] 已同步最新增量');
            } catch (e) {
              console.warn('⚠️ [流式节拍] 同步失败:', e);
            } finally {
              // 持续循环，直到流式结束
              const currentMessages = useChatStore.getState().messages;
              const currentLast = currentMessages[currentMessages.length - 1];
              const stillStreaming = !!(currentLast && !currentLast.isUser && (currentLast as any).isStreaming);
              if (stillStreaming) {
                tick();
              } else {
                console.log('🛑 [流式] 结束，清理节拍循环');
                if (streamingLoopRef.current) {
                  clearTimeout(streamingLoopRef.current);
                  streamingLoopRef.current = null;
                }
                // 流式刚结束：做一次最终同步
                try {
                  await ChatOverlay.updateMessages({ messages: latestNativeMessagesRef.current });
                  console.log('✅ [流式结束] 最终同步完成');
                } catch (e2) {
                  console.warn('⚠️ [流式结束] 最终同步失败:', e2);
                }
              }
            }
          }, beat);
        };
        tick();
      }
      return; // 流式下不再走去抖逻辑
    }

    // 非流式：使用轻量去抖，避免多余刷新
    if (syncThrottleRef.current) {
      clearTimeout(syncThrottleRef.current);
    }
    const throttleDelay = isUserMessage && isNewMessage ? 0 : (!isUserMessage && isNewMessage ? 50 : 100);
    syncThrottleRef.current = setTimeout(async () => {
      try {
        await ChatOverlay.updateMessages({ messages: latestNativeMessagesRef.current });
        console.log(`✅ [智能同步] 消息同步成功，类型: ${isUserMessage ? '用户消息' : '其他'}, 延迟: ${throttleDelay}ms`);
      } catch (error) {
        console.error('❌ [智能同步] 消息同步失败:', error);
      }
    }, throttleDelay);

  }, [storeMessages]); // 只依赖storeMessages数组变化

  // 🔧 删除清理定时器逻辑（不再需要）

  const showOverlay = async (expanded = true) => {
    if (Capacitor.isNativePlatform()) {
      // 🚨 【关键修复】状态守卫：只有在状态真的变化时才发送通知
      const currentOverlayState = { expanded, visible: true };
      const lastState = lastSentOverlayStateRef.current;
      
      if (lastState && 
          lastState.expanded === currentOverlayState.expanded && 
          lastState.visible === currentOverlayState.visible) {
        console.log('☑️ [状态守卫] ChatOverlay状态未变化，跳过通知发送，防止竞争条件');
        return;
      }
      
      console.log('📱 尝试显示原生ChatOverlay', expanded);
      console.log('📱 当前isOpen状态（显示前）:', isOpen);
      console.log('✅ [状态守卫] ChatOverlay状态发生变化，发送通知:', currentOverlayState);
      
      try {
        await ChatOverlay.show({ isOpen: expanded });
        
        // 更新状态守卫
        lastSentOverlayStateRef.current = currentOverlayState;
        
        console.log('✅ 原生ChatOverlay显示成功');
        console.log('📱 当前isOpen状态（显示后）:', isOpen);
      } catch (error) {
        console.error('❌ 原生ChatOverlay显示失败:', error);
      }
    } else {
      console.log('🌐 显示React ChatOverlay');
      setIsOpen(true);
    }
  };

  const hideOverlay = async () => {
    if (Capacitor.isNativePlatform()) {
      // 🚨 【关键修复】状态守卫：只有在状态真的变化时才发送通知
      const currentOverlayState = { expanded: false, visible: false };
      const lastState = lastSentOverlayStateRef.current;
      
      if (lastState && 
          lastState.expanded === currentOverlayState.expanded && 
          lastState.visible === currentOverlayState.visible) {
        console.log('☑️ [状态守卫] ChatOverlay状态未变化，跳过通知发送，防止竞争条件');
        return;
      }
      
      console.log('📱 隐藏原生ChatOverlay');
      console.log('📱 当前isOpen状态（隐藏前）:', isOpen);
      console.log('✅ [状态守卫] ChatOverlay状态发生变化，发送隐藏通知:', currentOverlayState);
      
      await ChatOverlay.hide();
      
      // 更新状态守卫
      lastSentOverlayStateRef.current = currentOverlayState;
      
      console.log('📱 ChatOverlay隐藏完成');
      console.log('📱 当前isOpen状态（隐藏后）:', isOpen);
    } else {
      console.log('🌐 隐藏React ChatOverlay');
      setIsOpen(false);
    }
  };

  const sendMessage = async (message: string) => {
    if (Capacitor.isNativePlatform()) {
      console.log('📱 通过原生插件发送消息:', message);
      await ChatOverlay.sendMessage({ message });
    } else {
      console.log('🌐 通过React组件发送消息:', message);
      // Web端逻辑
    }
  };
  
  // 新增方法 - 对应Web版本的完整功能
  const setConversationTitleNative = async (title: string) => {
    if (Capacitor.isNativePlatform()) {
      await ChatOverlay.setConversationTitle({ title });
    }
  };
  
  const setKeyboardHeightNative = async (height: number) => {
    if (Capacitor.isNativePlatform()) {
      await ChatOverlay.setKeyboardHeight({ height });
    }
  };
  
  const setViewportHeightNative = async (height: number) => {
    if (Capacitor.isNativePlatform()) {
      await ChatOverlay.setViewportHeight({ height });
    }
  };
  
  const setInitialInputNative = async (input: string) => {
    if (Capacitor.isNativePlatform()) {
      await ChatOverlay.setInitialInput({ input });
    }
  };
  
  const setFollowUpQuestionNative = async (question: string) => {
    if (Capacitor.isNativePlatform()) {
      await ChatOverlay.setFollowUpQuestion({ question });
    }
  };
  
  const updateMessagesNative = async (messages: ChatMessage[]) => {
    if (Capacitor.isNativePlatform()) {
      await ChatOverlay.updateMessages({ messages });
    }
  };
  
  const setLoadingNative = async (loading: boolean) => {
    if (Capacitor.isNativePlatform()) {
      await ChatOverlay.setLoading({ loading });
    }
  };

  return {
    isOpen,
    messages: storeMessages, // 使用store中的消息
    isLoading: chatIsLoading, // 使用store中的加载状态
    showOverlay,
    hideOverlay,
    sendMessage,
    // 新增的状态和方法 - 对应Web版本的完整功能
    conversationTitle: storeTitleFull || conversationTitle,
    keyboardHeight,
    viewportHeight,
    setConversationTitle: setConversationTitleNative,
    setKeyboardHeight: setKeyboardHeightNative,
    setViewportHeight: setViewportHeightNative,
    setInitialInput: setInitialInputNative,
    setFollowUpQuestion: setFollowUpQuestionNative,
    updateMessages: updateMessagesNative,
    setLoading: setLoadingNative,
    isNative: Capacitor.isNativePlatform()
  };
};
