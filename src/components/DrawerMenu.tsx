import React, { useEffect, useMemo, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  SquarePen,
  ChevronRight 
} from 'lucide-react';
import { listSessions as listNativeSessions, switchSession as switchNativeSession, newSession as newNativeSession, renameSession as renameNativeSession, onSessionsChanged, getSessionSummaryContext } from '@/utils/conversationBridge';
import { ChatOverlay } from '@/plugins/ChatOverlay';

interface DrawerMenuProps {
  isOpen: boolean;
  onClose: () => void;
  onOpenSettings: () => void;
  onOpenTemplateSelector: () => void;
}

const DrawerMenu: React.FC<DrawerMenuProps> = ({ isOpen, onClose, onOpenSettings, onOpenTemplateSelector }) => {
  const [sessions, setSessions] = useState<Array<{ id: string; title?: string; displayTitle?: string; rawTitle?: string; hasCustomTitle?: boolean; createdAt: number; updatedAt: number; messagesCount?: number }>>([]);
  const [loadingSessions, setLoadingSessions] = useState(false);
  const [summarizing, setSummarizing] = useState<Record<string, boolean>>({});
  const [query, setQuery] = useState('');

  // 订阅原生侧会话变化
  useEffect(() => {
    if (!isOpen) return;
    const sub = onSessionsChanged((data: any) => {
      if (Array.isArray(data?.sessions)) {
        // 按 updatedAt 倒序
        const sorted = [...data.sessions].sort((a, b) => b.updatedAt - a.updatedAt);
        setSessions(sorted);
        triggerSummaries(sorted);
      }
    });
    return () => { try { (sub as any)?.remove?.(); } catch {} };
  }, [isOpen]);

  // 打开时加载会话列表
  useEffect(() => {
    const load = async () => {
      if (!isOpen) return;
      setLoadingSessions(true);
      try {
        const res = await listNativeSessions();
        const items = (res?.sessions ?? []) as Array<{ id: string; title?: string; displayTitle?: string; rawTitle?: string; hasCustomTitle?: boolean; createdAt: number; updatedAt: number; messagesCount?: number }>;
        const sorted = items.sort((a, b) => b.updatedAt - a.updatedAt);
        setSessions(sorted);
        // 触发需要的标题总结
        triggerSummaries(sorted);
      } catch (e) {
        console.warn('listSessions failed', e);
        setSessions([]);
      } finally {
        setLoadingSessions(false);
      }
    };
    load();
  }, [isOpen]);

  // 判断是否为默认/占位标题
  const isPlaceholderTitle = (rawTitle?: string, hasCustom?: boolean) => {
    if (hasCustom) return false;
    const title = (rawTitle || '').trim();
    const defaults = new Set(['', '新会话', '默认会话', '迁移会话', '未命名会话', '闲聊对话']);
    return title.length === 0 || defaults.has(title);
  };

  // 调用AI生成标题（使用“弹幕型链路” generateAIResponse）
  const summarizeTitle = async (id: string) => {
    if (summarizing[id]) return; // 去重
    setSummarizing(prev => ({ ...prev, [id]: true }));
    try {
      const ctx = await getSessionSummaryContext(id, 8);
      const count = ctx?.count || 0;
      const messages = (ctx?.messages || []) as Array<{ role: 'user' | 'assistant'; content: string }>;
      if (!messages.length || count === 0) return;
      const conversation = messages.map(m => `${m.role === 'user' ? '用户' : 'AI'}：${m.content}`).join('\n');
      const prompt = `请为以下对话生成一个简洁的标题（不超过10个字）：\n\n${conversation}\n\n要求：\n- 标题要准确反映对话的核心主题\n- 使用中文\n- 不超过10个字\n- 不要包含标点符号\n- 直接返回标题，不要其他内容`;
      const { generateAIResponse } = await import('@/utils/aiTaggingUtils');
      // 使用弹幕型链路（启用stream）获取标题
      const title = await generateAIResponse(prompt, undefined, () => {});
      const cleanTitle = (title || '')
        .replace(/["'“”‘’]/g, '')
        .replace(/[。！？，、；：]/g, '')
        .replace(/[.!?,;:]/g, '')
        .trim()
        .substring(0, 10) || '未命名会话';
      await renameNativeSession(id, cleanTitle);
    } catch (e) {
      console.warn('summarizeTitle failed', e);
    } finally {
      setSummarizing(prev => ({ ...prev, [id]: false }));
    }
  };

  // 遍历触发总结
  const triggerSummaries = (items: Array<{ id: string; rawTitle?: string; hasCustomTitle?: boolean; messagesCount?: number }>) => {
    for (const s of items) {
      const count = s.messagesCount ?? 0;
      if (count === 0) continue;
      if (!isPlaceholderTitle(s.rawTitle, s.hasCustomTitle)) continue;
      void summarizeTitle(s.id);
    }
  };

  const handleSwitch = async (id: string) => {
    try {
      await switchNativeSession(id);
      try { await ChatOverlay.show({ isOpen: true }); } catch {}
      onClose();
    } catch (e) {
      console.warn('switchSession failed', e);
    }
  };

  const handleNew = async () => {
    try {
      const title = prompt('新会话标题（可留空自动生成）', '');
      const res = await newNativeSession(title ? { title } : {});
      // 选中新建会话
      if (res?.id) await switchNativeSession(res.id);
      onClose();
    } catch (e) {
      console.warn('newSession failed', e);
    }
  };

  // 根据评审：历史会话项点击即切换，不提供重命名/删除入口

  // 菜单项配置（基于demo的设计）
  const menuItems = [
    { label: '所有项目', active: true },
    { label: '记忆', count: 0 },
    { 
      label: '选择星座', 
      hasArrow: true,
      onClick: () => {
        onOpenTemplateSelector();
        onClose();
      }
    },
    { label: '智能标签', count: 9, section: '资料库' },
    { label: '人物', count: 0 },
    { label: '事物', count: 0 },
    { label: '地点', count: 0 },
    { label: '类型' },
    { 
      label: 'AI配置', 
      hasArrow: true,
      onClick: () => {
        onOpenSettings();
        onClose();
      }
    },
    { label: '导入', hasArrow: true }
  ];

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-50 flex">
          {/* 抽屉内容 */}
          <motion.div
            initial={{ x: -320 }}
            animate={{ x: 0 }}
            exit={{ x: -320 }}
            transition={{ type: "spring", damping: 25, stiffness: 200 }}
            className="w-80 h-full shadow-2xl flex flex-col"
            style={{
              background: 'linear-gradient(135deg, rgba(27, 39, 53, 0.95) 0%, rgba(9, 10, 15, 0.98) 100%)',
              backdropFilter: 'blur(20px)'
            }}
          >
            {/* 抽屉顶部 - 与主页Header位置对齐（改为搜索 + 新建）*/}
            <div 
              className="px-5 border-b border-white/10"
              style={{
                paddingLeft: `calc(1.25rem + var(--safe-area-inset-left, 0px))`, // 20px + 安全区域
                paddingRight: `calc(1.25rem + var(--safe-area-inset-right, 0px))`, // 20px + 安全区域
                paddingTop: '3rem', // 48px - 与Header完全一致
                paddingBottom: '0.5rem' // 8px - 与Header完全一致
              }}
            >
              <div className="flex items-center justify-between gap-2">
                <div className="flex-1 mr-2 min-w-0">
                  <input
                    type="text"
                    value={query}
                    onChange={(e) => setQuery(e.target.value)}
                    placeholder="搜索对话…"
                    className="w-full px-3 py-2 rounded-full bg-white/10 text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-blue-400/60 border border-white/15"
                  />
                </div>
                <button
                  onClick={handleNew}
                  className="p-2 rounded-full dialog-transparent-button transition-colors duration-200 hover:bg-white/10 border border-white/10"
                  title="新建对话"
                  aria-label="新建对话"
                >
                  <SquarePen className="w-5 h-5 text-white" />
                </button>
              </div>
            </div>

            {/* 菜单项列表（中间区域可滚动） */}
            <div className="flex-1 overflow-y-auto" style={{ WebkitOverflowScrolling: 'touch' as any }}>
              {/* 历史对话 */}
              <div className="px-5 py-3 text-xs text-white/40 font-medium tracking-wide uppercase">历史对话</div>
              {/* 顶部已提供新建入口，移除列表上方的“新建会话”按钮 */}
              {loadingSessions && (
                <div className="px-5 py-2 text-white/40 text-sm">加载中…</div>
              )}
              {!loadingSessions && sessions.length === 0 && (
                <div className="px-5 py-2 text-white/40 text-sm">暂无历史会话</div>
              )}
              {!loadingSessions && sessions
                .filter(s => {
                  const q = query.trim().toLowerCase();
                  if (!q) return true;
                  const t = (s.displayTitle || s.title || '').toLowerCase();
                  return t.includes(q);
                })
                .map(s => (
                <div
                  key={s.id}
                  className="group flex items-center justify-between px-5 py-3 cursor-pointer hover:bg-white/5 transition-colors"
                  onClick={() => handleSwitch(s.id)}
                >
                  <div className="flex-1 min-w-0">
                    <div className="stellar-body text-white truncate">
                      {(s.displayTitle || s.title || '未命名会话')}
                      {summarizing[s.id] ? <span className="ml-2 text-xs text-white/40">（生成标题中…）</span> : null}
                    </div>
                    <div className="text-xs text-white/40">{new Date(s.updatedAt).toLocaleString()}</div>
                  </div>
                </div>
              ))}

              {menuItems.map((item, index) => {
                return (
                  <div key={index}>
                    {/* 分组标题 */}
                    {item.section && (
                      <div className="px-5 py-3 text-xs text-white/40 font-medium tracking-wide uppercase">
                        {item.section}
                      </div>
                    )}
                    
                    {/* 菜单项 */}
                    <div 
                      className={`flex items-center justify-between px-5 py-4 cursor-pointer transition-all duration-200 ${
                        item.active 
                          ? 'text-white border-r-2 border-blue-400' 
                          : 'text-white/60 hover:text-white'
                      }`}
                      onClick={item.onClick}
                    >
                      <div className="flex items-center">
                        <span className="stellar-body">{item.label}</span>
                      </div>
                      
                      <div className="flex items-center gap-2">
                        {typeof item.count === 'number' && (
                          <span className={`text-sm ${
                            item.active 
                              ? 'text-blue-300' 
                              : 'text-white/40'
                          }`}>
                            {item.count}
                          </span>
                        )}
                        {item.hasArrow && (
                          <ChevronRight className="w-4 h-4 text-white/40" />
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* 底部用户信息 */}
            <div className="px-5 py-4 border-t border-white/10 backdrop-blur-sm" 
                 style={{ background: 'rgba(255, 255, 255, 0.02)' }}>
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 bg-gradient-to-r from-blue-400 to-cyan-400 rounded-full flex items-center justify-center text-white text-sm font-bold">
                  ✦
                </div>
                <div className="flex-1">
                  <div className="stellar-body text-white">星谕用户</div>
                  <div className="text-xs text-white/60">探索星辰的奥秘</div>
                </div>
              </div>
            </div>
          </motion.div>

          {/* 背景遮罩 */}
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="flex-1 bg-black/50 backdrop-blur-sm"
            onClick={onClose}
          />
        </div>
      )}
    </AnimatePresence>
  );
};

export default DrawerMenu;
