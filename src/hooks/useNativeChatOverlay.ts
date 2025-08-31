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
  
  // 🔧 简化同步：监听store中的消息变化并同步到原生ChatOverlay
  useEffect(() => {
    if (!Capacitor.isNativePlatform() || storeMessages.length === 0) {
      return;
    }

    console.log('📱 [简化同步] 消息列表发生变化，同步到原生ChatOverlay');
    console.log('📱 当前store消息数量:', storeMessages.length);
    
    // 将store的ChatMessage转换为原生可识别的格式
    const nativeMessages = storeMessages.map(msg => ({
      id: msg.id,
      text: msg.text,
      isUser: msg.isUser,
      timestamp: msg.timestamp.getTime() // 转换Date为毫秒时间戳
    }));

    // 🎯 关键简化：无差别同步，让原生端自己决定何时播放动画
    const syncMessages = async () => {
      try {
        await ChatOverlay.updateMessages({ messages: nativeMessages });
        console.log('✅ [简化同步] 消息同步成功，动画判断交由原生端处理');
      } catch (error) {
        console.error('❌ [简化同步] 消息同步失败:', error);
      }
    };

    // 立即执行同步，不再区分用户消息、AI消息或流式更新
    syncMessages();
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