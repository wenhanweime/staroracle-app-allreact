import { create } from 'zustand';
import { ChatMessage, ChatState } from '../types/chat';

interface ChatStore extends ChatState {
  addUserMessage: (text: string) => void;
  addAIMessage: (text: string) => void;
  addStreamingAIMessage: (text: string) => string; // 返回消息ID
  updateStreamingMessage: (id: string, text: string) => void;
  finalizeStreamingMessage: (id: string) => void;
  setLoading: (loading: boolean) => void;
  clearMessages: () => void;
}

export const useChatStore = create<ChatStore>((set, get) => ({
  messages: [],
  isLoading: false,

  addUserMessage: (text: string) => {
    const newMessage: ChatMessage = {
      id: `user-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      text,
      isUser: true,
      timestamp: new Date()
    };
    
    set(state => ({
      messages: [...state.messages, newMessage]
    }));
  },

  addAIMessage: (text: string) => {
    const newMessage: ChatMessage = {
      id: `ai-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      text,
      isUser: false,
      timestamp: new Date()
    };
    
    set(state => ({
      messages: [...state.messages, newMessage]
    }));
  },

  addStreamingAIMessage: (text: string = '') => {
    const messageId = `ai-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    const newMessage: ChatMessage = {
      id: messageId,
      text,
      isUser: false,
      timestamp: new Date(),
      isStreaming: true
    };
    
    set(state => ({
      messages: [...state.messages, newMessage]
    }));
    
    return messageId;
  },

  updateStreamingMessage: (id: string, text: string) => {
    set(state => ({
      messages: state.messages.map(msg => 
        msg.id === id 
          ? { ...msg, text }
          : msg
      )
    }));
  },

  finalizeStreamingMessage: (id: string) => {
    set(state => ({
      messages: state.messages.map(msg => 
        msg.id === id 
          ? { ...msg, isStreaming: false }
          : msg
      )
    }));
  },

  setLoading: (loading: boolean) => {
    set({ isLoading: loading });
  },

  clearMessages: () => {
    set({ messages: [], isLoading: false });
  }
}));