
这是一个非常扎实且深思熟虑的架构方案。回答你的核心问题：**是的，这份文档不仅足够实现 NextChat 级别的对话架构，而且在多端同步、数据持久化和个性化演化方面，已经超越了纯客户端版本的 NextChat。**

这份方案成功地将 NextChat 的核心**策略（Strategy）**与 Vercel/Supabase 的现代**基建（Infrastructure）**结合在了一起。

为了确保你能够顺利落地，我将把这份对话记录和方案变化总结成一份**完整的落地实施方案**。

---

# 🌌 集星问问 (Star Collection) - 云原生架构落地白皮书

## 一、 核心架构理念：瘦客户端，富后端

我们正在进行一次从“胖客户端”（NextChat 模式）到“云原生架构”（Serverless 模式）的彻底重构。

- **NextChat (原版)**：浏览器计算 Token，浏览器生成摘要，浏览器存数据。**缺点**：换设备数据丢失，手机发热，Key 容易泄露。
- **集星问问 (新版)**：
    - **iOS (Swift)**：只负责**渲染**（显示气泡、渲染星空）和**流式接收**。
    - **Supabase (Edge Functions)**：负责**思考**（上下文拼接、Token 计算、自动摘要、铸星逻辑）。
    - **PostgreSQL**：负责**记忆**（持久化存储、向量检索）。

---

## 二、 数据库 Schema 设计 (PostgreSQL)

这是系统的基石。请在 Supabase SQL Editor 中执行以下设计。

### 1. `chats` 表：会话的大脑

不仅存储会话元数据，还存储了 NextChat 的核心配置和长期记忆。

```sql
create table chats (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users not null,
  title text default 'New Chat',

  -- [核心移植] 长期记忆摘要 (对应 NextChat session.memoryPrompt)
  memory_prompt text,

  -- [核心移植] 摘要游标 (对应 NextChat session.lastSummarizeIndex)
  last_summarize_index int4 default 0,

  -- [核心移植] 模型配置 (对应 session.mask.modelConfig)
  -- 存 JSON: { "temperature": 0.5, "historyMessageCount": 10, "systemPrompt": "..." }
  config jsonb default '{}'::jsonb,

  created_at timestamptz default now()
);
-- 启用 RLS
alter table chats enable row level security;
create policy "Users manage own chats" on chats for all using (auth.uid() = user_id);

```

### 2. `messages` 表：对话流

增加了 Token 计数，以便后端快速计算上下文窗口。

```sql
create table messages (
  id uuid primary key default uuid_generate_v4(),
  chat_id uuid references chats(id) on delete cascade not null,
  role text check (role in ('system', 'user', 'assistant')),
  content text not null,

  -- [优化] 写入时计算好，后端读取时直接累加，不用再遍历计算
  token_count int4,

  created_at timestamptz default now()
);
alter table messages enable row level security;
create policy "Users see own messages" on messages for all using (
  exists (select 1 from chats where chats.id = messages.chat_id and chats.user_id = auth.uid())
);

```

### 3. `stars` 表：结构化资产 (核心差异点)

将对话转化为可视化的“星星”。

```sql
create extension if not exists vector; -- 启用向量扩展

create table stars (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users not null,
  chat_id uuid references chats(id),

  -- 核心感悟 (Structured Output)
  core_thought text,

  -- 向量化字段：用于 RAG (检索增强生成)，让 AI 回想起类似的情绪
  emotion_vector vector(1536),
  embedding_text text, -- 用于生成向量的原始文本

  -- 星图坐标与属性
  insight_level int2, -- 0-3，星卡等级（影响星球样式/分辨率），不直接决定银河亮度
  coordinates jsonb, -- {x, y, z}

  created_at timestamptz default now()
);
alter table stars enable row level security;
create policy "Users see own stars" on stars for all using (auth.uid() = user_id);

```

---

## 三、 Edge Function 实现：`chat-send`

这是整个系统的“大脑”。它接管了 NextChat 前端最复杂的 `useChatStore` 逻辑。

**文件路径**: `supabase/functions/chat-send/index.ts`

### 1. 核心流程逻辑

1. **鉴权**：验证用户身份。
2. **加载状态**：从 DB 读取 `chats` 配置和 `messages` 历史。
3. **构建上下文 (Context Building)** - **关键步骤**：
    - 插入 `System Prompt`。
    - 插入 `Memory Prompt` (如果有)。
    - 倒序插入 `History Messages`，直到达到 Token 限制 (智能截断)。
4. **流式响应 (Streaming)**：调用 OpenAI，将结果实时推流给客户端。
5. **后台异步处理 (Background Tasks)**：
    - 使用 `EdgeRuntime.waitUntil` 确保响应结束后代码继续运行。
    - 保存新消息。
    - **触发自动摘要**：如果新消息积累过多，压缩历史并更新 `chats.memory_prompt`。
    - **触发铸星**：如果对话达到深度，提取并生成 `stars` 数据。

### 2. 代码实现框架 (TypeScript)

```tsx
import { serve } from "<https://deno.land/std@0.168.0/http/server.ts>";
import { createClient } from "<https://esm.sh/@supabase/supabase-js@2>";
import { OpenAI } from "<https://esm.sh/openai@4>";
import { encode } from "<https://esm.sh/gpt-tokenizer>"; // 准确计算 Token

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    // 1. 初始化 & 鉴权
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) throw new Error('Unauthorized');

    const { chat_id, message } = await req.json();

    // 2. 加载 NextChat 风格的配置与记忆
    const { data: chatData } = await supabaseClient
      .from('chats')
      .select('memory_prompt, config, last_summarize_index')
      .eq('id', chat_id)
      .single();

    const modelConfig = chatData?.config || {};

    // 3. 构建上下文 (Context Builder) - 移植自 NextChat
    const contextMessages = [];

    // A. 系统提示词
    contextMessages.push({
      role: 'system',
      content: modelConfig.systemPrompt || "你是一个通过星星来疗愈心灵的 AI..."
    });

    // B. 长期记忆 (Memory Prompt)
    if (chatData?.memory_prompt) {
      contextMessages.push({
        role: 'system',
        content: `历史对话摘要：\\n${chatData.memory_prompt}`
      });
    }

    // C. 近期消息与截断 (Rolling Window)
    const maxTokens = 4000; // 假设阈值
    let currentTokens = encode(message).length; // 当前用户消息 Token

    const { data: historyMsgs } = await supabaseClient
      .from('messages')
      .select('role, content, token_count')
      .eq('chat_id', chat_id)
      .order('created_at', { ascending: false })
      .limit(modelConfig.historyMessageCount || 20);

    const tempHistory = [];
    if (historyMsgs) {
      for (const msg of historyMsgs) {
        if (currentTokens + msg.token_count > maxTokens) break;
        tempHistory.unshift({ role: msg.role, content: msg.content });
        currentTokens += msg.token_count;
      }
    }

    // 合并历史与当前消息
    contextMessages.push(...tempHistory);
    contextMessages.push({ role: 'user', content: message });

    // 4. 调用 OpenAI 流式输出
    const openai = new OpenAI({ apiKey: Deno.env.get('OPENAI_API_KEY') });
    const stream = await openai.chat.completions.create({
      model: modelConfig.model || 'gpt-4o-mini',
      messages: contextMessages,
      stream: true,
      temperature: modelConfig.temperature || 0.6
    });

    // 5. 处理流并执行后台任务
    const { readable, writable } = new TransformStream();
    const writer = writable.getWriter();
    const encoder = new TextEncoder();

    // 关键：不阻塞客户端响应，后台运行
    // @ts-ignore
    EdgeRuntime.waitUntil((async () => {
      let fullResponse = "";
      try {
        for await (const part of stream) {
          const content = part.choices[0]?.delta?.content || '';
          if (content) {
            fullResponse += content;
            await writer.write(encoder.encode(content));
          }
        }
      } finally {
        await writer.close();

        // --- 异步任务开始 ---

        // 1. 保存消息
        await supabaseClient.from('messages').insert([
          { chat_id, role: 'user', content: message, token_count: encode(message).length },
          { chat_id, role: 'assistant', content: fullResponse, token_count: encode(fullResponse).length }
        ]);

        // 2. 检查并生成摘要 (移植 summarizeSession)
        // 逻辑：如果未摘要的消息 Token 数超过一定阈值，调用 LLM 生成新摘要
        await checkAndSummarize(chat_id, chatData, supabaseClient, openai);

        // 3. 检查并铸造星星
        // 逻辑：如果对话判定为“深刻”，提取 JSON 存入 stars 表
        await checkAndCastStar(chat_id, fullResponse, supabaseClient, openai);
      }
    })());

    return new Response(readable, {
      headers: { ...corsHeaders, 'Content-Type': 'text/event-stream' },
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});

// 辅助函数占位符
async function checkAndSummarize(chatId, chatData, supabase, openai) { /* ...实现摘要更新逻辑... */ }
async function checkAndCastStar(chatId, response, supabase, openai) { /* ...实现 JSON 提取与存库逻辑... */ }

```

---

## 四、 客户端实现 (Swift 极简版)

因为逻辑都在后端，Swift 客户端变得非常轻量。

```swift
import Supabase

// 1. 发送消息
func sendMessage(text: String, chatId: UUID) async {
    // 乐观 UI：立即将 text 显示在屏幕上

    let url = URL(string: "https://YOUR_PROJECT.supabase.co/functions/v1/chat-send")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \\(supabase.auth.session?.accessToken ?? "")", forHTTPHeaderField: "Authorization")

    let body = ["chat_id": chatId.uuidString, "message": text]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    // 2. 接收流
    let (bytes, _) = try! await URLSession.shared.bytes(for: request)

    var aiResponse = ""
    for try await byte in bytes {
        let chunk = String(decoding: [byte], as: UTF8.self)
        aiResponse += chunk
        // 实时更新 UI：updateLastMessage(aiResponse)
    }
}

// 3. 星图展示
// 只需要监听 'stars' 表的变化，或者每次进入页面 fetch 一次
func fetchStars() async -> [Star] {
    let query = supabase.database.from("stars").select("*")
    // ... 解析 JSON 并渲染 ...
}

```

---

## 五、 总结：为什么这套方案能成？

1. **解决了痛点**：NextChat 的痛点是数据在本地，换手机就没了。这套方案数据在云端（Postgres），逻辑在云端（Edge Function），用户换任何设备都能无缝衔接。
2. **保留了精华**：通过 `memory_prompt` 和 Token 截断逻辑的后端移植，保留了 NextChat 优秀的“长对话记忆”体验。
3. **增加了壁垒**：通过 `stars` 表和 Edge Function 的异步处理，你实现了“对话即资产”。用户的每一次聊天都在生成可视化的数据，这比单纯的聊天记录更有粘性。
4. **性能更优**：繁重的 Token 计算和摘要生成都在服务器端完成，不仅 iOS 端省电，而且响应速度更快。

**这是一个完全可落地、且具备商业级扩展能力的架构方案。**
