export interface Star {
  id: string;
  x: number;
  y: number;
  size: number;
  brightness: number;
  question: string;
  answer: string;
  imageUrl: string;
  createdAt: Date;
  isSpecial: boolean;
  tags: string[];
  primary_category: string; // 更新为 primary_category
  emotional_tone: string[]; // 更新为数组类型
  question_type?: string; // 新增：问题类型
  insight_level?: {
    value: number; // 1-5
    description: string; // '星尘', '微光', '寻常星', '启明星', '超新星'
  };
  initial_luminosity?: number; // 0-100
  connection_potential?: number; // 1-5
  suggested_follow_up?: string; // 建议的追问
  card_summary?: string; // 卡片摘要
  similarity?: number; // For connection strength
  isTemplate?: boolean; // 标记是否为模板星星
  templateType?: string; // 模板类型（星座名称）
  isStreaming?: boolean; // 标记是否正在流式输出回答
}

export interface Connection {
  id: string;
  fromStarId: string;
  toStarId: string;
  strength: number; // 0-1, based on tag similarity
  sharedTags: string[];
  isTemplate?: boolean; // 标记是否为模板连接
  constellationName?: string; // 标记该连接所属的星座名称
}

export interface Constellation {
  stars: Star[];
  connections: Connection[];
}

// 更新为更完整的分析结构
export interface TagAnalysis {
  tags: string[];
  primary_category: string;
  emotional_tone: string[];
  question_type: string;
  insight_level: {
    value: number;
    description: string;
  };
  initial_luminosity: number;
  connection_potential: number;
  suggested_follow_up: string;
  card_summary: string;
}

// 星座模板接口
export interface ConstellationTemplate {
  id: string;
  name: string;
  chineseName: string;
  description: string;
  element: 'fire' | 'earth' | 'air' | 'water';
  stars: TemplateStarData[];
  connections: TemplateConnectionData[];
  centerX: number;
  centerY: number;
  scale: number;
}

export interface TemplateStarData {
  id: string;
  x: number; // 相对于星座中心的位置
  y: number;
  size: number;
  brightness: number;
  question: string;
  answer: string;
  tags: string[];
  category?: string; // 兼容旧的模板数据
  emotionalTone?: string; // 兼容旧的模板数据
  primary_category?: string; // 新的类别字段
  emotional_tone?: string[]; // 新的情感基调字段
  question_type?: string;
  insight_level?: {
    value: number;
    description: string;
  };
  initial_luminosity?: number;
  connection_potential?: number;
  suggested_follow_up?: string;
  card_summary?: string;
  isMainStar?: boolean; // 是否为主星
}

export interface TemplateConnectionData {
  fromStarId: string;
  toStarId: string;
  strength: number;
  sharedTags: string[];
}