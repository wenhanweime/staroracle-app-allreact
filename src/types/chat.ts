// 觉察分析结果接口
export interface AwarenessInsight {
  hasInsight: boolean; // 是否包含觉察价值
  insightLevel: 'low' | 'medium' | 'high'; // 觉察深度等级
  insightType: string; // 觉察类型，如"自我认知"、"情绪洞察"等
  keyInsights: string[]; // 关键洞察点
  emotionalPattern: string; // 情绪模式分析
  suggestedReflection: string; // 建议的深入思考方向
  followUpQuestions: string[]; // 后续可以继续探索的问题
}

export interface ChatMessage {
  id: string;
  text: string;
  isUser: boolean;
  timestamp: Date;
  isLoading?: boolean;
  isStreaming?: boolean; // 标记是否正在流式输出
  // 觉察相关字段
  awarenessInsight?: AwarenessInsight; // AI分析的觉察洞见
  isAnalyzingAwareness?: boolean; // 是否正在分析觉察
}

export interface ChatState {
  messages: ChatMessage[];
  isLoading: boolean;
}