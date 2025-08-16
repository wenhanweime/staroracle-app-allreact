import { ConstellationTemplate, Star, Connection } from '../types';

// 辅助函数，将旧的emotionalTone转换为新的格式
const convertOldEmotionalTone = (oldTone: string): string => {
  const mapping: Record<string, string> = {
    'positive': '充满希望的',
    'contemplative': '思考的',
    'seeking': '探寻中',
    'neutral': '中性的'
  };
  return mapping[oldTone] || '探寻中';
};

// 辅助函数，将旧的category转换为新的primary_category
const convertOldCategory = (oldCategory: string): string => {
  const mapping: Record<string, string> = {
    'relationships': 'relationships',
    'personal_growth': 'personal_growth',
    'life_direction': 'career_and_purpose',
    'wellbeing': 'emotional_wellbeing',
    'material': 'daily_life',
    'creative': 'creativity_and_passion',
    'existential': 'philosophy_and_existence'
  };
  return mapping[oldCategory] || 'philosophy_and_existence';
};

// 根据问题文本推断问题类型
const getQuestionType = (question: string): string => {
  const lowerQuestion = question.toLowerCase();
  if (lowerQuestion.includes('为什么') || lowerQuestion.includes('why') || 
      lowerQuestion.includes('是否') || lowerQuestion.includes('if') || 
      lowerQuestion.includes('是不是')) {
    return '探索型';
  } else if (lowerQuestion.includes('如何') || lowerQuestion.includes('how to') || 
             lowerQuestion.includes('方法') || lowerQuestion.includes('steps')) {
    return '实用型';
  } else if (lowerQuestion.includes('什么是') || lowerQuestion.includes('what is') || 
             lowerQuestion.includes('谁') || lowerQuestion.includes('who') || 
             lowerQuestion.includes('where')) {
    return '事实型';
  }
  // 默认返回探索型
  return '探索型';
};

// 根据类别生成默认的追问
const getSuggestedFollowUp = (category: string): string => {
  const followUpMap: Record<string, string> = {
    'relationships': '这种关系模式在你生活的其他方面是否也有体现？',
    'personal_growth': '你觉得是什么阻碍了你在这方面的进一步成长？',
    'career_and_purpose': '如果没有任何限制，你理想中的职业道路是什么样的？',
    'emotional_wellbeing': '这种情绪是从什么时候开始的，有没有特定的触发点？',
    'philosophy_and_existence': '这个信念对你日常生活的决策有什么影响？',
    'creativity_and_passion': '你上一次完全沉浸在创造性活动中是什么时候？那感觉如何？',
    'daily_life': '这个日常习惯如何影响了你的整体生活质量？'
  };
  return followUpMap[category] || '关于这个话题，你还有什么更深层次的感受或想法？';
};

// 12星座模板数据
export const ZODIAC_TEMPLATES: ConstellationTemplate[] = [
  {
    id: 'aries',
    name: 'Aries',
    chineseName: '白羊座',
    description: '勇敢的开拓者，充满激情与活力',
    element: 'fire',
    centerX: 25,
    centerY: 30,
    scale: 1.0,
    stars: [
      {
        id: 'aries-1',
        x: 0,
        y: 0,
        size: 4,
        brightness: 1.0,
        question: '我如何发现自己的勇气？',
        answer: '勇气如火星般燃烧，在行动中点燃，在挑战中壮大。',
        tags: ['courage', 'leadership', 'action', 'passion', 'initiative'],
        category: 'personal_growth',
        emotionalTone: 'positive',
        isMainStar: true
      },
      {
        id: 'aries-2',
        x: -8,
        y: 5,
        size: 3,
        brightness: 0.8,
        question: '如何成为更好的领导者？',
        answer: '真正的领导者如北极星，不是最亮的，却为他人指引方向。',
        tags: ['leadership', 'guidance', 'responsibility', 'vision'],
        category: 'life_direction',
        emotionalTone: 'contemplative'
      },
      {
        id: 'aries-3',
        x: 8,
        y: -3,
        size: 2.5,
        brightness: 0.7,
        question: '我的激情在哪里？',
        answer: '激情如恒星核心的聚变，从内心深处释放无穷能量。',
        tags: ['passion', 'energy', 'motivation', 'drive'],
        category: 'personal_growth',
        emotionalTone: 'seeking'
      },
      {
        id: 'aries-4',
        x: 3,
        y: 8,
        size: 2,
        brightness: 0.6,
        question: '如何开始新的征程？',
        answer: '每个新开始都是宇宙的重新创造，勇敢迈出第一步。',
        tags: ['new_beginnings', 'adventure', 'courage', 'change'],
        category: 'life_direction',
        emotionalTone: 'positive'
      }
    ],
    connections: [
      { fromStarId: 'aries-1', toStarId: 'aries-2', strength: 0.8, sharedTags: ['leadership', 'courage'] },
      { fromStarId: 'aries-1', toStarId: 'aries-3', strength: 0.7, sharedTags: ['passion', 'energy'] },
      { fromStarId: 'aries-2', toStarId: 'aries-4', strength: 0.6, sharedTags: ['leadership', 'new_beginnings'] }
    ]
  },
  {
    id: 'taurus',
    name: 'Taurus',
    chineseName: '金牛座',
    description: '稳重的建设者，追求美好与安全',
    element: 'earth',
    centerX: 75,
    centerY: 25,
    scale: 1.0,
    stars: [
      {
        id: 'taurus-1',
        x: 0,
        y: 0,
        size: 4,
        brightness: 1.0,
        question: '如何建立稳定的生活？',
        answer: '稳定如大地般深厚，在耐心与坚持中慢慢积累。',
        tags: ['stability', 'security', 'patience', 'persistence'],
        category: 'wellbeing',
        emotionalTone: 'contemplative',
        isMainStar: true
      },
      {
        id: 'taurus-2',
        x: -6,
        y: -4,
        size: 3,
        brightness: 0.8,
        question: '什么是真正的财富？',
        answer: '真正的财富不在金库，而在心灵的富足与关系的深度。',
        tags: ['wealth', 'abundance', 'values', 'material'],
        category: 'material',
        emotionalTone: 'contemplative'
      },
      {
        id: 'taurus-3',
        x: 7,
        y: 6,
        size: 2.5,
        brightness: 0.7,
        question: '如何欣赏生活中的美？',
        answer: '美如花朵在感恩的土壤中绽放，用心感受每个瞬间。',
        tags: ['beauty', 'appreciation', 'senses', 'gratitude'],
        category: 'wellbeing',
        emotionalTone: 'positive'
      },
      {
        id: 'taurus-4',
        x: 2,
        y: -8,
        size: 2,
        brightness: 0.6,
        question: '如何保持内心的平静？',
        answer: '平静如深山古井，不因外界波动而失去内在的宁静。',
        tags: ['peace', 'calm', 'stability', 'inner_strength'],
        category: 'wellbeing',
        emotionalTone: 'contemplative'
      }
    ],
    connections: [
      { fromStarId: 'taurus-1', toStarId: 'taurus-2', strength: 0.7, sharedTags: ['stability', 'security'] },
      { fromStarId: 'taurus-1', toStarId: 'taurus-4', strength: 0.8, sharedTags: ['stability', 'peace'] },
      { fromStarId: 'taurus-3', toStarId: 'taurus-4', strength: 0.6, sharedTags: ['peace', 'appreciation'] }
    ]
  },
  {
    id: 'gemini',
    name: 'Gemini',
    chineseName: '双子座',
    description: '好奇的探索者，善于沟通与学习',
    element: 'air',
    centerX: 50,
    centerY: 70,
    scale: 1.0,
    stars: [
      {
        id: 'gemini-1',
        x: -4,
        y: 0,
        size: 3.5,
        brightness: 0.9,
        question: '如何提升我的沟通能力？',
        answer: '沟通如双星系统，倾听与表达相互环绕，创造和谐共鸣。',
        tags: ['communication', 'expression', 'listening', 'connection'],
        category: 'relationships',
        emotionalTone: 'seeking',
        isMainStar: true
      },
      {
        id: 'gemini-2',
        x: 4,
        y: 0,
        size: 3.5,
        brightness: 0.9,
        question: '如何平衡生活的多面性？',
        answer: '如月亮的阴晴圆缺，拥抱你内在的多重面向，它们都是完整的你。',
        tags: ['balance', 'duality', 'adaptability', 'flexibility'],
        category: 'personal_growth',
        emotionalTone: 'contemplative',
        isMainStar: true
      },
      {
        id: 'gemini-3',
        x: 0,
        y: -6,
        size: 2.5,
        brightness: 0.7,
        question: '如何保持学习的热情？',
        answer: '好奇心如星际尘埃，在宇宙中永远飘散，永远发现新的世界。',
        tags: ['learning', 'curiosity', 'knowledge', 'growth'],
        category: 'personal_growth',
        emotionalTone: 'positive'
      },
      {
        id: 'gemini-4',
        x: 0,
        y: 6,
        size: 2,
        brightness: 0.6,
        question: '如何建立深度的友谊？',
        answer: '友谊如星座，看似分散的点，实则由无形的引力紧密相连。',
        tags: ['friendship', 'connection', 'loyalty', 'understanding'],
        category: 'relationships',
        emotionalTone: 'positive'
      }
    ],
    connections: [
      { fromStarId: 'gemini-1', toStarId: 'gemini-2', strength: 0.9, sharedTags: ['communication', 'balance'] },
      { fromStarId: 'gemini-1', toStarId: 'gemini-4', strength: 0.7, sharedTags: ['communication', 'connection'] },
      { fromStarId: 'gemini-2', toStarId: 'gemini-3', strength: 0.6, sharedTags: ['growth', 'adaptability'] }
    ]
  },
  {
    id: 'cancer',
    name: 'Cancer',
    chineseName: '巨蟹座',
    description: '温暖的守护者，重视家庭与情感',
    element: 'water',
    centerX: 20,
    centerY: 75,
    scale: 1.0,
    stars: [
      {
        id: 'cancer-1',
        x: 0,
        y: 0,
        size: 4,
        brightness: 1.0,
        question: '如何创造温暖的家？',
        answer: '家不在建筑中，而在心灵的港湾，用爱编织的安全感。',
        tags: ['home', 'family', 'security', 'nurturing', 'love'],
        category: 'relationships',
        emotionalTone: 'positive',
        isMainStar: true
      },
      {
        id: 'cancer-2',
        x: -5,
        y: 5,
        size: 3,
        brightness: 0.8,
        question: '如何处理敏感的情感？',
        answer: '敏感如月光映水，既是脆弱也是力量，学会拥抱你的深度。',
        tags: ['emotions', 'sensitivity', 'intuition', 'empathy'],
        category: 'personal_growth',
        emotionalTone: 'contemplative'
      },
      {
        id: 'cancer-3',
        x: 6,
        y: -3,
        size: 2.5,
        brightness: 0.7,
        question: '如何照顾他人又不失自我？',
        answer: '如月亮照亮夜空却不失去自己的光芒，给予中保持自我的完整。',
        tags: ['caring', 'boundaries', 'self_care', 'balance'],
        category: 'relationships',
        emotionalTone: 'seeking'
      },
      {
        id: 'cancer-4',
        x: 2,
        y: 7,
        size: 2,
        brightness: 0.6,
        question: '如何找到内心的安全感？',
        answer: '真正的安全感来自内心的根基，如深海般宁静而深邃。',
        tags: ['security', 'inner_peace', 'self_trust', 'stability'],
        category: 'wellbeing',
        emotionalTone: 'contemplative'
      }
    ],
    connections: [
      { fromStarId: 'cancer-1', toStarId: 'cancer-2', strength: 0.8, sharedTags: ['emotions', 'nurturing'] },
      { fromStarId: 'cancer-1', toStarId: 'cancer-4', strength: 0.7, sharedTags: ['security', 'home'] },
      { fromStarId: 'cancer-2', toStarId: 'cancer-3', strength: 0.6, sharedTags: ['emotions', 'caring'] }
    ]
  },
  {
    id: 'leo',
    name: 'Leo',
    chineseName: '狮子座',
    description: '自信的表演者，散发光芒与魅力',
    element: 'fire',
    centerX: 80,
    centerY: 60,
    scale: 1.0,
    stars: [
      {
        id: 'leo-1',
        x: 0,
        y: 0,
        size: 4.5,
        brightness: 1.0,
        question: '如何建立真正的自信？',
        answer: '自信如太阳般从内心发光，不需要外界的认可来证明自己的价值。',
        tags: ['confidence', 'self_worth', 'authenticity', 'inner_strength'],
        category: 'personal_growth',
        emotionalTone: 'positive',
        isMainStar: true
      },
      {
        id: 'leo-2',
        x: -6,
        y: -4,
        size: 3,
        brightness: 0.8,
        question: '如何展现我的创造力？',
        answer: '创造力如恒星的光芒，需要勇气点燃，用热情维持燃烧。',
        tags: ['creativity', 'expression', 'art', 'passion', 'uniqueness'],
        category: 'creative',
        emotionalTone: 'positive'
      },
      {
        id: 'leo-3',
        x: 7,
        y: 5,
        size: 2.5,
        brightness: 0.7,
        question: '如何成为他人的光芒？',
        answer: '如太阳照亮行星，真正的光芒在于启发他人发现自己的光。',
        tags: ['inspiration', 'leadership', 'generosity', 'influence'],
        category: 'relationships',
        emotionalTone: 'positive'
      },
      {
        id: 'leo-4',
        x: 3,
        y: -7,
        size: 2,
        brightness: 0.6,
        question: '如何平衡自我与谦逊？',
        answer: '真正的王者如太阳，强大而温暖，照亮一切却不炫耀自己。',
        tags: ['humility', 'balance', 'wisdom', 'maturity'],
        category: 'personal_growth',
        emotionalTone: 'contemplative'
      }
    ],
    connections: [
      { fromStarId: 'leo-1', toStarId: 'leo-2', strength: 0.8, sharedTags: ['confidence', 'creativity'] },
      { fromStarId: 'leo-1', toStarId: 'leo-3', strength: 0.7, sharedTags: ['confidence', 'leadership'] },
      { fromStarId: 'leo-2', toStarId: 'leo-3', strength: 0.6, sharedTags: ['creativity', 'inspiration'] }
    ]
  },
  {
    id: 'virgo',
    name: 'Virgo',
    chineseName: '处女座',
    description: '完美的工匠，追求精确与服务',
    element: 'earth',
    centerX: 30,
    centerY: 50,
    scale: 1.0,
    stars: [
      {
        id: 'virgo-1',
        x: 0,
        y: 0,
        size: 4,
        brightness: 1.0,
        question: '如何在细节中找到完美？',
        answer: '完美不在无瑕，而在每个细节中倾注的爱与专注。',
        tags: ['perfection', 'attention', 'craftsmanship', 'dedication'],
        category: 'personal_growth',
        emotionalTone: 'contemplative',
        isMainStar: true
      },
      {
        id: 'virgo-2',
        x: -5,
        y: 6,
        size: 3,
        brightness: 0.8,
        question: '如何更好地服务他人？',
        answer: '服务如星光，看似微小却能照亮他人前行的道路。',
        tags: ['service', 'helping', 'contribution', 'purpose'],
        category: 'relationships',
        emotionalTone: 'positive'
      },
      {
        id: 'virgo-3',
        x: 6,
        y: -4,
        size: 2.5,
        brightness: 0.7,
        question: '如何管理我的时间和精力？',
        answer: '时间如星辰运行，有序而精确，在规律中找到效率的美。',
        tags: ['organization', 'efficiency', 'planning', 'discipline'],
        category: 'life_direction',
        emotionalTone: 'seeking'
      },
      {
        id: 'virgo-4',
        x: 2,
        y: 8,
        size: 2,
        brightness: 0.6,
        question: '如何接受不完美的自己？',
        answer: '如星空中的每颗星都有独特的光芒，不完美也是美的一种形式。',
        tags: ['self_acceptance', 'growth', 'compassion', 'healing'],
        category: 'personal_growth',
        emotionalTone: 'contemplative'
      }
    ],
    connections: [
      { fromStarId: 'virgo-1', toStarId: 'virgo-3', strength: 0.8, sharedTags: ['perfection', 'organization'] },
      { fromStarId: 'virgo-1', toStarId: 'virgo-4', strength: 0.7, sharedTags: ['perfection', 'growth'] },
      { fromStarId: 'virgo-2', toStarId: 'virgo-4', strength: 0.6, sharedTags: ['service', 'compassion'] }
    ]
  }
  // 可以继续添加其他6个星座...
];

// 获取所有星座模板
export const getAllTemplates = (): ConstellationTemplate[] => {
  return ZODIAC_TEMPLATES;
};

// 根据ID获取特定星座模板
export const getTemplateById = (id: string): ConstellationTemplate | undefined => {
  return ZODIAC_TEMPLATES.find(template => template.id === id);
};

// 根据元素获取星座模板
export const getTemplatesByElement = (element: 'fire' | 'earth' | 'air' | 'water'): ConstellationTemplate[] => {
  return ZODIAC_TEMPLATES.filter(template => template.element === element);
};

// 将模板转换为实际的星星和连接
export const instantiateTemplate = (template: ConstellationTemplate, offsetX: number = 0, offsetY: number = 0) => {
  const stars = template.stars.map(starData => {
    // 将旧的category和emotionalTone字段转换为新的字段格式
    const emotional_tone = Array.isArray(starData.emotional_tone) ? 
      starData.emotional_tone : 
      [convertOldEmotionalTone(starData.emotionalTone)];

    // 转换旧的类别字段
    const primary_category = starData.primary_category || 
                       convertOldCategory(starData.category as string);
    
    // 创建新的星星对象
    return {
      id: `${template.id}-${starData.id}-${Date.now()}`,
      x: template.centerX + (starData.x * template.scale) + offsetX,
      y: template.centerY + (starData.y * template.scale) + offsetY,
      size: starData.size,
      brightness: starData.brightness,
      question: starData.question,
      answer: starData.answer,
      imageUrl: `https://images.pexels.com/photos/${Math.floor(Math.random() * 2000000) + 1000000}/pexels-photo-${Math.floor(Math.random() * 2000000) + 1000000}.jpeg`,
      createdAt: new Date(),
      isSpecial: starData.isMainStar || false,
      tags: starData.tags,
      primary_category: primary_category,
      emotional_tone: emotional_tone,
      question_type: starData.question_type || getQuestionType(starData.question),
      insight_level: starData.insight_level || {
        value: starData.isMainStar ? 4 : 3,
        description: starData.isMainStar ? '启明星' : '寻常星'
      },
      initial_luminosity: starData.initial_luminosity || (starData.isMainStar ? 90 : 60),
      connection_potential: starData.connection_potential || 4,
      suggested_follow_up: starData.suggested_follow_up || getSuggestedFollowUp(primary_category),
      card_summary: starData.card_summary || starData.question,
      isTemplate: true,
      templateType: template.chineseName
    };
  });

  const connections: Connection[] = [];
  
  // Create connections, filtering out null values
  template.connections.forEach(connData => {
    const fromStar = stars.find(s => s.id.includes(connData.fromStarId));
    const toStar = stars.find(s => s.id.includes(connData.toStarId));
    
    if (fromStar && toStar) {
      connections.push({
        id: `connection-${fromStar.id}-${toStar.id}`,
        fromStarId: fromStar.id,
        toStarId: toStar.id,
        strength: connData.strength,
        sharedTags: connData.sharedTags,
        isTemplate: true
      });
    }
  });

  return { stars, connections };
};