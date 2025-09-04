import { registerPlugin } from '@capacitor/core';

export interface ChatOverlayPlugin {
  show(options: { isOpen: boolean }): Promise<void>;
  hide(options?: { animated?: boolean }): Promise<void>;
  isVisible(): Promise<{ visible: boolean }>;
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
  // 会话/上下文管理
  setSystemPrompt(options: { text: string }): Promise<void>;
  loadHistory(options?: { sessionId?: string }): Promise<{ count: number }>;
  clearConversation(options?: { sessionId?: string }): Promise<void>;
  // 会话列表与管理
  listSessions(): Promise<{ success: boolean; sessions: Array<{ id: string; title?: string; displayTitle?: string; rawTitle?: string; hasCustomTitle?: boolean; createdAt: number; updatedAt: number; messagesCount?: number }> }>;
  switchSession(options: { id: string }): Promise<{ success: boolean; count: number }>;
  newSession(options?: { title?: string }): Promise<{ success: boolean; id: string; count: number }>;
  renameSession(options: { id: string; title: string }): Promise<{ success: boolean }>;
  deleteSession(options: { id: string }): Promise<{ success: boolean; count: number }>;
  getSessionSummaryContext(options: { id: string; limit?: number }): Promise<{ success: boolean; count: number; messages: Array<{ role: 'user' | 'assistant'; content: string }> }>;
}

export const ChatOverlay = registerPlugin<ChatOverlayPlugin>('ChatOverlay', {
  web: () => import('./ChatOverlayWeb').then(m => new m.ChatOverlayWeb()),
});
