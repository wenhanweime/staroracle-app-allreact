import { create } from 'zustand';
import { ChatMessage, ChatState, AwarenessInsight } from '../types/chat';

// 整体对话觉察状态
export interface ConversationAwareness {
  overallLevel: 'none' | 'low' | 'medium' | 'high';
  conversationDepth: number; // 0-100
  isAnalyzing: boolean;
  insights: AwarenessInsight[];
  topicProgression: string[]; // 话题演进
}

interface ChatStore extends ChatState {
  // 现有方法
  addUserMessage: (text: string) => void;
  addAIMessage: (text: string) => void;
  addStreamingAIMessage: (text: string) => string; // 返回消息ID
  updateStreamingMessage: (id: string, text: string) => void;
  finalizeStreamingMessage: (id: string) => void;
  setLoading: (loading: boolean) => void;
  clearMessages: () => void;
  
  // 单条消息觉察分析
  startAwarenessAnalysis: (messageId: string) => void;
  completeAwarenessAnalysis: (messageId: string, insight: AwarenessInsight) => void;
  
  // 整体对话觉察状态
  conversationAwareness: ConversationAwareness;
  updateConversationAwareness: () => void;
  setConversationAnalyzing: (isAnalyzing: boolean) => void;
}

export const useChatStore = create<ChatStore>((set, get) => ({
  messages: [],
  isLoading: false,
  
  // 初始化对话觉察状态
  conversationAwareness: {
    overallLevel: 'none',
    conversationDepth: 0,
    isAnalyzing: false,
    insights: [],
    topicProgression: []
  },

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
  },

  // 开始觉察分析
  startAwarenessAnalysis: (messageId: string) => {
    set(state => ({
      messages: state.messages.map(msg => 
        msg.id === messageId 
          ? { ...msg, isAnalyzingAwareness: true }
          : msg
      )
    }));
  },

  // 完成觉察分析
  completeAwarenessAnalysis: (messageId: string, insight: AwarenessInsight) => {
    set(state => ({
      messages: state.messages.map(msg => 
        msg.id === messageId 
          ? { 
              ...msg, 
              isAnalyzingAwareness: false,
              awarenessInsight: insight 
            }
          : msg
      )
    }));
    
    // 完成单条分析后，更新整体对话觉察状态
    get().updateConversationAwareness();
  },

  // 更新整体对话觉察状态
  updateConversationAwareness: () => {
    const { messages } = get();
    
    // 收集所有有效的觉察洞察
    const allInsights = messages
      .filter(msg => !msg.isUser && msg.awarenessInsight && msg.awarenessInsight.hasInsight)
      .map(msg => msg.awarenessInsight!)
      .filter(Boolean);
    
    // 计算整体觉察等级
    let overallLevel: 'none' | 'low' | 'medium' | 'high' = 'none';
    let conversationDepth = 0;
    
    if (allInsights.length > 0) {
      // 统计不同等级的洞察数量
      const levelCounts = {
        high: allInsights.filter(i => i.insightLevel === 'high').length,
        medium: allInsights.filter(i => i.insightLevel === 'medium').length,
        low: allInsights.filter(i => i.insightLevel === 'low').length
      };
      
      // 计算对话深度 (0-100)
      conversationDepth = Math.min(100, 
        (levelCounts.high * 30 + levelCounts.medium * 20 + levelCounts.low * 10)
      );
      
      // 确定整体等级
      if (levelCounts.high >= 2 || (levelCounts.high >= 1 && levelCounts.medium >= 2)) {
        overallLevel = 'high';
      } else if (levelCounts.medium >= 2 || (levelCounts.medium >= 1 && levelCounts.low >= 3)) {
        overallLevel = 'medium';
      } else if (levelCounts.low >= 1 || levelCounts.medium >= 1) {
        overallLevel = 'low';
      }
    }
    
    // 提取话题演进
    const topicProgression = allInsights
      .map(insight => insight.insightType)
      .filter((topic, index, arr) => arr.indexOf(topic) === index); // 去重
    
    set(state => ({
      conversationAwareness: {
        ...state.conversationAwareness,
        overallLevel,
        conversationDepth,
        insights: allInsights,
        topicProgression
      }
    }));
  },

  // 设置对话分析状态
  setConversationAnalyzing: (isAnalyzing: boolean) => {
    set(state => ({
      conversationAwareness: {
        ...state.conversationAwareness,
        isAnalyzing
      }
    }));
  }
}));