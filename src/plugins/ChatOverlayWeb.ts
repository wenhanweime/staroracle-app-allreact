import { WebPlugin } from '@capacitor/core';
import { ChatOverlayPlugin } from './ChatOverlay';

export class ChatOverlayWeb extends WebPlugin implements ChatOverlayPlugin {
  async show(options: { isOpen: boolean }): Promise<void> {
    console.log('🌐 ChatOverlay show called with:', options);
    // Web端回退到React组件
  }

  async hide(): Promise<void> {
    console.log('🌐 ChatOverlay hide called');
  }

  async sendMessage(options: { message: string }): Promise<void> {
    console.log('🌐 ChatOverlay sendMessage called with:', options);
  }

  async receiveAIResponse(): Promise<void> {
    console.log('🌐 ChatOverlay receiveAIResponse called');
  }

  async updateMessages(options: { messages: any[] }): Promise<void> {
    console.log('🌐 ChatOverlay updateMessages called with:', options.messages?.length);
  }

  async setLoading(options: { loading: boolean }): Promise<void> {
    console.log('🌐 ChatOverlay setLoading called:', options.loading);
  }

  async setConversationTitle(options: { title: string }): Promise<void> {
    console.log('🌐 ChatOverlay setConversationTitle called:', options.title);
  }

  async setKeyboardHeight(options: { height: number }): Promise<void> {
    console.log('🌐 ChatOverlay setKeyboardHeight called:', options.height);
  }

  async setViewportHeight(options: { height: number }): Promise<void> {
    console.log('🌐 ChatOverlay setViewportHeight called:', options.height);
  }

  async setInitialInput(options: { input: string }): Promise<void> {
    console.log('🌐 ChatOverlay setInitialInput called:', options.input);
  }

  async setFollowUpQuestion(options: { question: string }): Promise<void> {
    console.log('🌐 ChatOverlay setFollowUpQuestion called:', options.question);
  }

  async appendAIChunk(options: { id?: string; delta: string }): Promise<void> {
    console.log('🌐 ChatOverlay appendAIChunk called:', options.id, options.delta?.length);
  }

  async updateLastAI(options: { id?: string; text: string }): Promise<void> {
    console.log('🌐 ChatOverlay updateLastAI called:', options.id, options.text?.length);
  }

  async cancelStreaming(): Promise<void> {
    console.log('🌐 ChatOverlay cancelStreaming called');
  }

  async startNativeStream(): Promise<void> {
    console.log('🌐 ChatOverlay startNativeStream called');
  }

  async setSystemPrompt(options: { text: string }): Promise<void> {
    console.log('🌐 ChatOverlay setSystemPrompt called:', options.text?.length);
  }

  async loadHistory(): Promise<{ count: number }> {
    console.log('🌐 ChatOverlay loadHistory called');
    return { count: 0 };
  }

  async clearConversation(): Promise<void> {
    console.log('🌐 ChatOverlay clearConversation called');
  }

  async listSessions(): Promise<{ success: boolean; sessions: Array<{ id: string; title: string; createdAt: number; updatedAt: number }> }> {
    console.log('🌐 ChatOverlay listSessions called');
    return { success: true, sessions: [] };
  }

  async switchSession(options: { id: string }): Promise<{ success: boolean; count: number }> {
    console.log('🌐 ChatOverlay switchSession called:', options.id);
    return { success: true, count: 0 };
  }

  async newSession(options?: { title?: string }): Promise<{ success: boolean; id: string; count: number }> {
    console.log('🌐 ChatOverlay newSession called:', options?.title);
    return { success: true, id: 'web-stub', count: 0 };
  }

  async renameSession(options: { id: string; title: string }): Promise<{ success: boolean }> {
    console.log('🌐 ChatOverlay renameSession called:', options.id, options.title);
    return { success: true };
  }

  async deleteSession(options: { id: string }): Promise<{ success: boolean; count: number }> {
    console.log('🌐 ChatOverlay deleteSession called:', options.id);
    return { success: true, count: 0 };
  }

  async getSessionSummaryContext(options: { id: string; limit?: number }): Promise<{ success: boolean; count: number; messages: Array<{ role: 'user' | 'assistant'; content: string }> }> {
    console.log('🌐 ChatOverlay getSessionSummaryContext called:', options.id, options.limit);
    return { success: false, count: 0, messages: [] };
  }
}
