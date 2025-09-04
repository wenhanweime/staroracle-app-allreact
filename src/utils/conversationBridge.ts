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

// 会话列表与管理桥接
export const listSessions = async () => {
  try { return await (ChatOverlay as any).listSessions(); } catch (e) { console.warn('listSessions failed', e); return { success: false, sessions: [] as Array<any> }; }
};

export const switchSession = async (id: string) => {
  try { return await (ChatOverlay as any).switchSession({ id }); } catch (e) { console.warn('switchSession failed', e); return { success: false, count: 0 }; }
};

export const newSession = async (title?: string) => {
  try { return await (ChatOverlay as any).newSession({ title }); } catch (e) { console.warn('newSession failed', e); return { success: false, id: '', count: 0 }; }
};

export const renameSession = async (id: string, title: string) => {
  try { return await (ChatOverlay as any).renameSession({ id, title }); } catch (e) { console.warn('renameSession failed', e); return { success: false }; }
};

export const deleteSession = async (id: string) => {
  try { return await (ChatOverlay as any).deleteSession({ id }); } catch (e) { console.warn('deleteSession failed', e); return { success: false, count: 0 }; }
};

// 事件订阅
export const onSessionsChanged = (cb: (data: { sessions: Array<{ id: string; title: string; createdAt: number; updatedAt: number }> }) => void) => {
  try {
    return (ChatOverlay as any).addListener('sessionsChanged', cb);
  } catch (e) {
    console.warn('addListener(sessionsChanged) failed', e);
    return { remove: () => {} };
  }
};

// 获取会话摘要上下文（用于AI生成标题）
export const getSessionSummaryContext = async (id: string, limit = 6) => {
  try { return await (ChatOverlay as any).getSessionSummaryContext({ id, limit }); } catch (e) { console.warn('getSessionSummaryContext failed', e); return { success: false, count: 0, messages: [] as Array<{ role: 'user' | 'assistant'; content: string }> }; }
};
