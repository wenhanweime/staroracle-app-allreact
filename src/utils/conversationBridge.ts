import { ChatOverlay } from '@/plugins/ChatOverlay';

export const setSystemPrompt = async (text: string) => {
  try { await (ChatOverlay as any).setSystemPrompt({ text }); } catch (e) { console.warn('setSystemPrompt failed', e); }
};

export const loadHistory = async () => {
  try { return await (ChatOverlay as any).loadHistory({}); } catch (e) { console.warn('loadHistory failed', e); return { count: 0 }; }
};

export const clearConversation = async () => {
  try { await (ChatOverlay as any).clearConversation({}); } catch (e) { console.warn('clearConversation failed', e); }
};

