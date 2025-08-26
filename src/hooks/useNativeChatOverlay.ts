import { useState, useEffect } from 'react';
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

  const showOverlay = async (expanded = true) => {
    if (Capacitor.isNativePlatform()) {
      console.log('📱 尝试显示原生ChatOverlay', expanded);
      try {
        await ChatOverlay.show({ isOpen: expanded });
        console.log('✅ 原生ChatOverlay显示成功');
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
      console.log('📱 隐藏原生ChatOverlay');
      await ChatOverlay.hide();
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