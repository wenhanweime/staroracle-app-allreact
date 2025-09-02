import { registerPlugin } from '@capacitor/core';

export interface ChatOverlayPlugin {
  show(options: { isOpen: boolean }): Promise<void>;
  hide(): Promise<void>;
  sendMessage(options: { message: string }): Promise<void>;
  receiveAIResponse(options: { response: string; timestamp: number }): Promise<void>;
  updateMessages(options: { messages: any[] }): Promise<void>;
  setLoading(options: { loading: boolean }): Promise<void>;
  // 新增方法 - 对应Web版本的完整功能
  setConversationTitle(options: { title: string }): Promise<void>;
  setKeyboardHeight(options: { height: number }): Promise<void>;
  setViewportHeight(options: { height: number }): Promise<void>;
  setInitialInput(options: { input: string }): Promise<void>;
  setFollowUpQuestion(options: { question: string }): Promise<void>;
  // 新增增量接口
  appendAIChunk(options: { id?: string; delta: string }): Promise<void>;
  updateLastAI(options: { id?: string; text: string }): Promise<void>;
  cancelStreaming(): Promise<void>;
  // 原生发起流式：使用原生StreamingClient进行SSE
  startNativeStream(options: {
    endpoint: string;
    apiKey: string;
    model: string;
    messages: Array<{ role: 'user' | 'assistant' | 'system'; content: string }>;
    temperature?: number;
    maxTokens?: number;
  }): Promise<void>;
}

export const ChatOverlay = registerPlugin<ChatOverlayPlugin>('ChatOverlay', {
  web: () => import('./ChatOverlayWeb').then(m => new m.ChatOverlayWeb()),
});
