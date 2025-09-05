// 灵感卡片系统
export interface InspirationCard {
  id: string;
  question: string;
  reflection: string;
  tags: string[];
  category: string;
  emotionalTone: 'positive' | 'neutral' | 'contemplative' | 'seeking';
}

// 灵感卡片数据库
const INSPIRATION_CARDS: InspirationCard[] = [
  // 自我探索类
  {
    id: 'self-1',
    question: '如果今天是你生命的最后一天，你最想做什么？',
    reflection: '生命的有限性让每个选择都变得珍贵，真正重要的事物会在这种思考中浮现。',
    tags: ['life', 'priorities', 'meaning', 'death', 'values'],
    category: 'existential',
    emotionalTone: 'contemplative'
  },
  {
    id: 'self-2',
    question: '你最害怕失去的是什么？为什么？',
    reflection: '恐惧往往指向我们最珍视的东西，了解恐惧就是了解自己的价值观。',
    tags: ['fear', 'loss', 'values', 'attachment', 'security'],
    category: 'personal_growth',
    emotionalTone: 'seeking'
  },
  {
    id: 'self-3',
    question: '如果你可以给10年前的自己一个建议，会是什么？',
    reflection: '回望过去的智慧往往是对当下最好的指引。',
    tags: ['wisdom', 'growth', 'regret', 'learning', 'time'],
    category: 'personal_growth',
    emotionalTone: 'contemplative'
  },
  {
    id: 'self-4',
    question: '什么时候你感到最像真正的自己？',
    reflection: '真实的自我在特定的时刻和环境中会自然流露，找到这些时刻就是找到回家的路。',
    tags: ['authenticity', 'self', 'identity', 'freedom', 'truth'],
    category: 'personal_growth',
    emotionalTone: 'seeking'
  },

  // 关系类
  {
    id: 'relationship-1',
    question: '你在关系中最容易重复的模式是什么？',
    reflection: '我们在关系中的模式往往反映了内心深处的信念和恐惧。',
    tags: ['relationships', 'patterns', 'behavior', 'awareness', 'growth'],
    category: 'relationships',
    emotionalTone: 'contemplative'
  },
  {
    id: 'relationship-2',
    question: '如果你的朋友用三个词形容你，会是哪三个词？',
    reflection: '他人眼中的我们往往能揭示我们自己看不到的特质。',
    tags: ['identity', 'perception', 'friendship', 'self_image', 'reflection'],
    category: 'relationships',
    emotionalTone: 'seeking'
  },
  {
    id: 'relationship-3',
    question: '你最想对某个人说但一直没说的话是什么？',
    reflection: '未说出的话语往往承载着我们最深的情感和遗憾。',
    tags: ['communication', 'regret', 'courage', 'expression', 'love'],
    category: 'relationships',
    emotionalTone: 'contemplative'
  },

  // 梦想与目标类
  {
    id: 'dreams-1',
    question: '如果金钱不是问题，你会如何度过你的一生？',
    reflection: '当外在限制被移除，内心真正的渴望就会显现。',
    tags: ['dreams', 'freedom', 'purpose', 'passion', 'life_design'],
    category: 'life_direction',
    emotionalTone: 'positive'
  },
  {
    id: 'dreams-2',
    question: '你小时候的梦想现在还重要吗？为什么？',
    reflection: '童年的梦想往往包含着我们最纯真的渴望，值得重新审视。',
    tags: ['childhood', 'dreams', 'growth', 'change', 'authenticity'],
    category: 'life_direction',
    emotionalTone: 'contemplative'
  },
  {
    id: 'dreams-3',
    question: '什么阻止了你追求真正想要的生活？',
    reflection: '障碍往往不在外界，而在我们内心的信念和恐惧中。',
    tags: ['obstacles', 'fear', 'limiting_beliefs', 'courage', 'change'],
    category: 'life_direction',
    emotionalTone: 'seeking'
  },

  // 情感与内心类
  {
    id: 'emotion-1',
    question: '你最近一次真正快乐是什么时候？那种感觉是什么样的？',
    reflection: '快乐的记忆是心灵的指南针，指向我们真正需要的方向。',
    tags: ['happiness', 'joy', 'memory', 'fulfillment', 'gratitude'],
    category: 'wellbeing',
    emotionalTone: 'positive'
  },
  {
    id: 'emotion-2',
    question: '如果你的情绪是一种天气，现在是什么天气？',
    reflection: '用自然的语言描述情绪，往往能带来更深的理解和接纳。',
    tags: ['emotions', 'metaphor', 'awareness', 'feelings', 'weather'],
    category: 'wellbeing',
    emotionalTone: 'contemplative'
  },
  {
    id: 'emotion-3',
    question: '你最想治愈内心的哪个部分？',
    reflection: '承认伤痛是治愈的第一步，每个伤口都包含着成长的种子。',
    tags: ['healing', 'pain', 'growth', 'self_care', 'compassion'],
    category: 'wellbeing',
    emotionalTone: 'seeking'
  },

  // 创造与表达类
  {
    id: 'creative-1',
    question: '如果你必须创造一件作品来代表现在的你，会是什么？',
    reflection: '创造是自我表达的最直接方式，作品往往比言语更能传达内心。',
    tags: ['creativity', 'expression', 'art', 'identity', 'representation'],
    category: 'creative',
    emotionalTone: 'positive'
  },
  {
    id: 'creative-2',
    question: '你最想学会的技能是什么？为什么？',
    reflection: '我们渴望学习的技能往往反映了内心未被满足的表达需求。',
    tags: ['learning', 'skills', 'growth', 'curiosity', 'development'],
    category: 'creative',
    emotionalTone: 'seeking'
  },

  // 哲学与存在类
  {
    id: 'philosophy-1',
    question: '如果你可以知道一个关于宇宙的终极真理，你想知道什么？',
    reflection: '我们对终极真理的好奇往往反映了当下最困扰我们的问题。',
    tags: ['truth', 'universe', 'meaning', 'curiosity', 'existence'],
    category: 'existential',
    emotionalTone: 'contemplative'
  },
  {
    id: 'philosophy-2',
    question: '什么让你感到生命是有意义的？',
    reflection: '意义不是被发现的，而是被创造的，在我们的选择和行动中诞生。',
    tags: ['meaning', 'purpose', 'life', 'significance', 'values'],
    category: 'existential',
    emotionalTone: 'contemplative'
  },
  {
    id: 'philosophy-3',
    question: '如果今天是世界的最后一天，你会如何度过？',
    reflection: '末日的假设能够剥离一切不重要的东西，让真正珍贵的浮现。',
    tags: ['priorities', 'death', 'meaning', 'love', 'presence'],
    category: 'existential',
    emotionalTone: 'contemplative'
  },

  // 成长与变化类
  {
    id: 'growth-1',
    question: '你最想改变自己的哪个方面？为什么？',
    reflection: '改变的渴望往往指向我们对更好自己的向往，也反映了当下的不满足。',
    tags: ['change', 'growth', 'improvement', 'self_development', 'aspiration'],
    category: 'personal_growth',
    emotionalTone: 'seeking'
  },
  {
    id: 'growth-2',
    question: '你从最大的失败中学到了什么？',
    reflection: '失败是最严厉也是最慈悲的老师，它强迫我们成长。',
    tags: ['failure', 'learning', 'resilience', 'wisdom', 'growth'],
    category: 'personal_growth',
    emotionalTone: 'contemplative'
  },
  {
    id: 'growth-3',
    question: '如果你可以重新开始，你会做什么不同的选择？',
    reflection: '重新开始的幻想往往揭示了我们对当下生活的真实感受。',
    tags: ['regret', 'choices', 'restart', 'wisdom', 'reflection'],
    category: 'personal_growth',
    emotionalTone: 'contemplative'
  }
];

// 获取随机灵感卡片
// 根据银河区域获取随机卡片（可选）
export type GalaxyRegion = 'emotion' | 'relation' | 'growth';

export const getRandomInspirationCard = (region?: GalaxyRegion): InspirationCard => {
  if (!region) {
    const randomIndex = Math.floor(Math.random() * INSPIRATION_CARDS.length);
    return INSPIRATION_CARDS[randomIndex];
  }

  // 将三大区域映射到卡片分类池（可根据实际内容调整权重与集合）
  const regionCategoryMap: Record<GalaxyRegion, string[]> = {
    emotion: ['wellbeing', 'creative', 'existential'],
    relation: ['relationships', 'wellbeing'],
    growth: ['personal_growth', 'life_direction', 'existential'],
  };

  const categories = regionCategoryMap[region];
  const pool = INSPIRATION_CARDS.filter(c => categories.includes(c.category));
  if (pool.length === 0) {
    const randomIndex = Math.floor(Math.random() * INSPIRATION_CARDS.length);
    return INSPIRATION_CARDS[randomIndex];
  }
  const randomIndex = Math.floor(Math.random() * pool.length);
  return pool[randomIndex];
};

// 根据标签获取相关卡片
export const getCardsByTags = (tags: string[], limit: number = 5): InspirationCard[] => {
  const matchingCards = INSPIRATION_CARDS.filter(card =>
    card.tags.some(tag => tags.includes(tag))
  );
  
  // 随机排序并限制数量
  return matchingCards
    .sort(() => Math.random() - 0.5)
    .slice(0, limit);
};

// 根据类别获取卡片
export const getCardsByCategory = (category: string): InspirationCard[] => {
  return INSPIRATION_CARDS.filter(card => card.category === category);
};

// 根据情感基调获取卡片
export const getCardsByTone = (tone: string): InspirationCard[] => {
  return INSPIRATION_CARDS.filter(card => card.emotionalTone === tone);
};
