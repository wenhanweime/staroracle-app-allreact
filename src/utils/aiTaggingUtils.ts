// AI Tagging and Analysis Utilities
import { Star, Connection, TagAnalysis } from '../types';
import type { ApiProvider } from '../vite-env';

export interface AITaggingConfig {
  provider?: ApiProvider; // 新增：API提供商
  apiKey?: string;
  endpoint?: string;
  model?: string;
  _version?: string; // 添加版本号用于未来可能的迁移
  _lastUpdated?: string; // 添加最后更新时间
}

export interface APIValidationResult {
  isValid: boolean;
  error?: string;
  responseTime?: number;
  modelInfo?: string;
}

// API验证函数
export const validateAIConfig = async (config: AITaggingConfig): Promise<APIValidationResult> => {
  if (!config.provider || !config.apiKey || !config.endpoint || !config.model) {
    return {
      isValid: false,
      error: '请选择提供商并填写完整的API配置信息（API Key、Endpoint、Model）'
    };
  }

  const startTime = Date.now();
  const testPrompt = '请简单回复"测试成功"';
  let requestBody;
  let requestHeaders = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${config.apiKey}`,
  };
  
  try {
    console.log(`🔍 Validating ${config.provider} API configuration...`);

    // 根据provider构建不同的请求体
    switch (config.provider) {
      case 'gemini':
        requestBody = {
          contents: [{ parts: [{ text: testPrompt }] }]
        };
        break;
      
      case 'openai':
      default: // OpenAI 和 NewAPI 等兼容服务
        requestBody = {
          model: config.model,
          messages: [{ role: 'user', content: testPrompt }],
          max_tokens: 10,
          temperature: 0.1,
        };
        break;
    }

    const response = await fetch(config.endpoint, {
      method: 'POST',
      headers: requestHeaders,
      body: JSON.stringify(requestBody),
    });

    const responseTime = Date.now() - startTime;

    if (!response.ok) {
      let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
      
      try {
        // Check if response is JSON before parsing
        const contentType = response.headers.get('content-type');
        if (contentType && contentType.includes('application/json')) {
          const errorData = await response.json();
          if (errorData.error?.message) {
            errorMessage = errorData.error.message;
          } else if (errorData.message) {
            errorMessage = errorData.message;
          }
        } else {
          // If not JSON, get text content for better error reporting
          const textContent = await response.text();
          if (textContent.includes('<!doctype') || textContent.includes('<html')) {
            errorMessage = `服务器返回了HTML页面而不是API响应。请检查endpoint地址是否正确。`;
          } else {
            errorMessage = `非JSON响应: ${textContent.slice(0, 100)}...`;
          }
        }
      } catch (parseError) {
        // If we can't parse the error response, use the HTTP status
        errorMessage = `HTTP ${response.status}: 无法解析错误响应`;
      }

      return {
        isValid: false,
        error: errorMessage,
        responseTime
      };
    }

    let data;
    try {
      // Check if response is JSON before parsing
      const contentType = response.headers.get('content-type');
      if (!contentType || !contentType.includes('application/json')) {
        const textContent = await response.text();
        return {
          isValid: false,
          error: `API返回了非JSON响应。请检查endpoint是否正确。响应内容: ${textContent.slice(0, 100)}...`,
          responseTime
        };
      }
      
      data = await response.json();
    } catch (parseError) {
      return {
        isValid: false,
        error: 'API响应不是有效的JSON格式，请检查endpoint是否支持OpenAI格式',
        responseTime
      };
    }
    
    // 根据provider解析不同的响应
    let testResponse: string | undefined;

    switch (config.provider) {
      case 'gemini':
        testResponse = data.candidates?.[0]?.content?.parts?.[0]?.text;
        if (!testResponse) {
          return { isValid: false, error: 'Gemini响应格式不正确', responseTime };
        }
        break;
      case 'openai':
      default:
        // 检查响应格式
        if (!data.choices || !data.choices[0] || !data.choices[0].message) {
          return {
            isValid: false,
            error: 'API响应格式不正确，请检查endpoint是否支持OpenAI格式',
            responseTime
          };
        }

        testResponse = data.choices[0].message.content;
        break;
    }
    
    console.log('✅ API validation successful:', {
      responseTime: `${responseTime}ms`,
      model: config.model,
      testResponse: testResponse?.slice(0, 50)
    });

    return {
      isValid: true,
      responseTime,
      modelInfo: `${config.model} (${responseTime}ms)`
    };

  } catch (error) {
    const responseTime = Date.now() - startTime;
    console.error('❌ API validation failed:', error);
    
    let errorMessage = '网络连接失败';
    if (error instanceof Error) {
      if (error.message.includes('fetch')) {
        errorMessage = '无法连接到API服务器，请检查网络和endpoint地址';
      } else if (error.message.includes('CORS')) {
        errorMessage = 'CORS错误，请检查API服务器是否允许跨域请求';
      } else if (error.message.includes('JSON')) {
        errorMessage = '服务器响应格式错误，请检查endpoint地址是否正确';
      } else {
        errorMessage = error.message;
      }
    }

    return {
      isValid: false,
      error: errorMessage,
      responseTime
    };
  }
};

// Enhanced mock AI analysis with better tag generation
const mockAIAnalysis = (question: string, answer: string): TagAnalysis => {
  const content = `${question} ${answer}`.toLowerCase();
  
  // More comprehensive tag mapping
  const tagMap = {
    // 核心生活领域 - Core Life Areas
    'love': ['relationships', 'romance', 'connection', 'heart', 'soulmate'],
    'family': ['relationships', 'parents', 'children', 'home', 'roots', 'legacy'],
    'friendship': ['connection', 'social', 'trust', 'loyalty', 'support'],
    'career': ['work', 'profession', 'vocation', 'success', 'achievement'],
    'education': ['learning', 'knowledge', 'growth', 'skills', 'wisdom'],
    'health': ['wellness', 'fitness', 'balance', 'vitality', 'self-care'],
    'finance': ['money', 'wealth', 'abundance', 'security', 'resources'],
    'spirituality': ['faith', 'soul', 'meaning', 'divinity', 'practice'],
    
    // 内在体验 - Inner Experience
    'emotions': ['feelings', 'awareness', 'processing', 'expression', 'regulation'],
    'happiness': ['joy', 'fulfillment', 'contentment', 'bliss', 'satisfaction'],
    'anxiety': ['fear', 'worry', 'stress', 'uncertainty', 'overwhelm'],
    'grief': ['loss', 'sadness', 'mourning', 'acceptance', 'healing'],
    'anger': ['frustration', 'resentment', 'boundaries', 'assertiveness', 'release'],
    'shame': ['guilt', 'regret', 'inadequacy', 'worthiness', 'forgiveness'],
    
    // 自我发展 - Self Development
    'identity': ['self', 'authenticity', 'values', 'discovery', 'integration'],
    'purpose': ['meaning', 'calling', 'mission', 'direction', 'contribution'],
    'growth': ['development', 'evolution', 'improvement', 'transformation', 'potential'],
    'resilience': ['strength', 'adaptation', 'recovery', 'endurance', 'perseverance'],
    'creativity': ['expression', 'inspiration', 'imagination', 'innovation', 'artistry'],
    'wisdom': ['insight', 'perspective', 'understanding', 'discernment', 'reflection'],
    
    // 人际关系 - Relationships
    'communication': ['expression', 'listening', 'understanding', 'clarity', 'connection'],
    'intimacy': ['closeness', 'vulnerability', 'trust', 'bonding', 'openness'],
    'boundaries': ['limits', 'protection', 'respect', 'space', 'autonomy'],
    'conflict': ['resolution', 'understanding', 'healing', 'growth', 'peace'],
    'trust': ['faith', 'reliability', 'consistency', 'safety', 'honesty'],
    
    // 生活哲学 - Life Philosophy
    'meaning': ['purpose', 'significance', 'values', 'understanding', 'exploration'],
    'mindfulness': ['presence', 'awareness', 'attention', 'consciousness', 'being'],
    'gratitude': ['appreciation', 'thankfulness', 'recognition', 'abundance', 'positivity'],
    'legacy': ['impact', 'contribution', 'remembrance', 'influence', 'heritage'],
    'values': ['principles', 'ethics', 'morality', 'beliefs', 'priorities'],
    
    // 生活转变 - Life Transitions
    'change': ['transition', 'adaptation', 'adjustment', 'evolution', 'transformation'],
    'decision': ['choice', 'discernment', 'wisdom', 'judgment', 'crossroads'],
    'future': ['planning', 'vision', 'direction', 'goals', 'possibilities'],
    'past': ['history', 'memories', 'reflection', 'lessons', 'integration'],
    'letting-go': ['release', 'surrender', 'acceptance', 'closure', 'freedom'],
    
    // 世界关系 - Relation to World
    'nature': ['environment', 'connection', 'outdoors', 'harmony', 'elements'],
    'society': ['community', 'culture', 'belonging', 'contribution', 'citizenship'],
    'justice': ['fairness', 'equality', 'rights', 'advocacy', 'ethics'],
    'service': ['contribution', 'helping', 'impact', 'giving', 'purpose'],
    'technology': ['digital', 'tools', 'innovation', 'adaptation', 'balance']
  };
  
  // 新的类别映射到旧的类别
  const categoryMapping = {
    'relationships': 'relationships',
    'personal_growth': 'personal_growth',
    'career_and_purpose': 'career_and_purpose',
    'emotional_wellbeing': 'emotional_wellbeing',
    'philosophy_and_existence': 'philosophy_and_existence',
    'creativity_and_passion': 'creativity_and_passion',
    'daily_life': 'daily_life'
  };
  
  // 类别关键词
  const categories = {
    'relationships': ['love', 'family', 'friendship', 'connection', 'intimacy', 'communication', 'boundaries', 'trust'],
    'personal_growth': ['identity', 'purpose', 'wisdom', 'growth', 'resilience', 'spirituality', 'creativity', 'education'],
    'career_and_purpose': ['future', 'career', 'decision', 'change', 'goals', 'values', 'legacy', 'mission', 'purpose'],
    'emotional_wellbeing': ['happiness', 'health', 'emotions', 'mindfulness', 'balance', 'self-care', 'vitality', 'healing'],
    'philosophy_and_existence': ['meaning', 'purpose', 'spirituality', 'values', 'wisdom', 'legacy', 'faith', 'life', 'death'],
    'creativity_and_passion': ['creativity', 'expression', 'imagination', 'innovation', 'artistry', 'inspiration', 'passion'],
    'daily_life': ['finance', 'security', 'abundance', 'resources', 'stability', 'wealth', 'work', 'routine', 'daily', 'practical']
  };
  
  // 情感基调映射
  const emotionalToneMapping = {
    'positive': '充满希望的',
    'contemplative': '思考的',
    'seeking': '探寻中',
    'neutral': '中性的'
  };
  
  // Improved emotional tone detection
  const emotionalTones = {
    '充满希望的': ['happy', 'joy', 'gratitude', 'hope', 'excitement', 'love', 'strength', 'peace', 'confidence'],
    '思考的': ['meaning', 'purpose', 'wisdom', 'reflect', 'wonder', 'ponder', 'consider', 'understand', 'explore'],
    '探寻中': ['find', 'search', 'discover', 'seek', 'direction', 'path', 'guidance', 'answers', 'clarity', 'help'],
    '中性的': ['what', 'is', 'are', 'should', 'would', 'could', 'might', 'perhaps', 'maybe', 'possibly'],
    '焦虑的': ['anxiety', 'worry', 'stress', 'fear', 'nervous', 'uncertain', 'overwhelm'],
    '感激的': ['grateful', 'thankful', 'appreciate', 'blessing', 'gift', 'fortune'],
    '困惑的': ['confused', 'puzzled', 'unclear', 'unsure', 'complexity', 'complicated'],
    '忧郁的': ['sad', 'depressed', 'melancholy', 'down', 'blue', 'grief', 'loss'],
    '坚定的': ['determined', 'resolved', 'committed', 'decided', 'sure', 'certain', 'confident']
  };

  // 问题类型检测
  const questionTypePatterns = {
    '探索型': ['why', 'why do i', 'what if', 'how come', '为什么', '怎么会', '如果', '假设', '是不是因为', '可能是'],
    '实用型': ['how to', 'how can i', 'what is the way to', 'steps to', 'method', '如何', '怎么做', '方法', '步骤', '技巧'],
    '事实型': ['what is', 'when', 'where', 'who', '什么是', '何时', '何地', '谁', '哪里', '多少'],
    '表达型': ['i feel', 'i am', 'i think', 'i believe', '我觉得', '我认为', '我感到', '我相信', '我想']
  };
  
  // Extract tags based on content with better matching
  const extractedTags: string[] = [];
  let detectedCategory = 'philosophy_and_existence';
  const detectedTones: string[] = ['探寻中'];
  let questionType = '探索型';
  
  // Find matching tags with partial matching
  Object.entries(tagMap).forEach(([key, relatedTags]) => {
    if (content.includes(key) || relatedTags.some(tag => content.includes(tag))) {
      extractedTags.push(key);
      // Add 1-2 related tags for better connections but avoid too many tags
      extractedTags.push(...relatedTags.slice(0, 2));
    }
  });
  
  // Add common universal tags to ensure connections
  const universalTags = ['wisdom', 'growth', 'reflection', 'insight'];
  extractedTags.push(...universalTags.slice(0, 2));
  
  // Determine category with better matching
  Object.entries(categories).forEach(([category, keywords]) => {
    const matchCount = keywords.filter(keyword => content.includes(keyword)).length;
    if (matchCount > 0) {
      detectedCategory = category;
    }
  });
  
  // Determine emotional tones (multiple can be detected)
  Object.entries(emotionalTones).forEach(([tone, keywords]) => {
    const matchCount = keywords.filter(keyword => content.includes(keyword)).length;
    if (matchCount > 0 && !detectedTones.includes(tone)) {
      detectedTones.push(tone);
    }
  });
  
  // Limit to two emotional tones
  if (detectedTones.length > 2) {
    detectedTones.splice(2);
  }
  
  // Determine question type
  Object.entries(questionTypePatterns).forEach(([type, patterns]) => {
    if (patterns.some(pattern => question.toLowerCase().includes(pattern))) {
      questionType = type;
      return;
    }
  });
  
  // Ensure we have enough tags for connections
  if (extractedTags.length < 3) {
    extractedTags.push('reflection', 'insight', 'awareness');
  }
  
  // Remove duplicates and limit to 6 tags for better connections
  const uniqueTags = [...new Set(extractedTags)].slice(0, 6);
  
  // Determine insight level based on content depth
  let insightLevel = {
    value: 1,
    description: '星尘'
  };
  
  // 简单的洞察度评估规则
  if (question.length > 50 && answer.length > 150) {
    insightLevel.value = 4;
    insightLevel.description = '启明星';
  } else if (question.length > 30 && answer.length > 100) {
    insightLevel.value = 3;
    insightLevel.description = '寻常星';
  } else if (question.length > 10 && answer.length > 50) {
    insightLevel.value = 2;
    insightLevel.description = '微光';
  }
  
  // 判断是否是深度自我探索的问题
  const selfReflectionWords = ['我自己', '我的内心', '自我', '成长', '人生', '意义', '价值', '恐惧', '梦想', '目标', '自我意识'];
  if (selfReflectionWords.some(word => content.includes(word))) {
    insightLevel.value = Math.min(5, insightLevel.value + 1);
    if (insightLevel.value >= 4) {
      insightLevel.description = insightLevel.value === 5 ? '超新星' : '启明星';
    }
  }
  
  // 计算初始亮度
  const luminosityMap = [0, 10, 30, 60, 90, 100];
  const initialLuminosity = luminosityMap[insightLevel.value];
  
  // 确定连接潜力
  let connectionPotential = 3; // 默认中等连接潜力
  
  // 通用主题有较高的连接潜力
  const universalThemes = ['love', 'purpose', 'meaning', 'growth', 'change', 'fear', 'happiness', 'success'];
  if (universalThemes.some(theme => uniqueTags.includes(theme))) {
    connectionPotential = 5;
  } else if (uniqueTags.length <= 2) {
    connectionPotential = 1; // 标签很少，连接潜力低
  } else if (uniqueTags.length >= 5) {
    connectionPotential = 4; // 标签多，连接潜力高
  }
  
  // 生成简单的卡片摘要
  let cardSummary = question.length > 30 ? question : question + " - " + answer.slice(0, 40) + "...";
  
  // 生成追问
  let suggestedFollowUp = '';
  const followUpMap: Record<string, string> = {
    'relationships': '这种关系模式在你生活的其他方面是否也有体现？',
    'personal_growth': '你觉得是什么阻碍了你在这方面的进一步成长？',
    'career_and_purpose': '如果没有任何限制，你理想中的职业道路是什么样的？',
    'emotional_wellbeing': '这种情绪是从什么时候开始的，有没有特定的触发点？',
    'philosophy_and_existence': '这个信念对你日常生活的决策有什么影响？',
    'creativity_and_passion': '你上一次完全沉浸在创造性活动中是什么时候？那感觉如何？',
    'daily_life': '这个日常习惯如何影响了你的整体生活质量？'
  };
  
  suggestedFollowUp = followUpMap[detectedCategory] || '关于这个话题，你还有什么更深层次的感受或想法？';
  
  return {
    tags: uniqueTags,
    primary_category: detectedCategory,
    emotional_tone: detectedTones,
    question_type: questionType,
    insight_level: insightLevel,
    initial_luminosity: initialLuminosity,
    connection_potential: connectionPotential,
    suggested_follow_up: suggestedFollowUp,
    card_summary: cardSummary
  };
};

// Main AI tagging function
export const analyzeStarContent = async (
  question: string, 
  answer: string,
  config?: AITaggingConfig,
  userHistory?: { previousInsightLevel: number, recentTags: string[] }
): Promise<TagAnalysis> => {
  try {
    // Always try to use AI service first
    if (config?.apiKey && config?.endpoint) {
      console.log(`🤖 使用${config.provider || 'openai'}服务进行内容分析`);
      console.log(`📝 分析内容 - 问题: "${question}", 回答: "${answer}"`);
      return await callAIService(question, answer, config);
    } else {
      // Try to use default API config if available
      const defaultConfig = getAIConfig();
      if (defaultConfig.apiKey && defaultConfig.endpoint) {
        console.log(`🤖 使用默认${defaultConfig.provider || 'openai'}配置进行内容分析`);
        console.log(`📝 分析内容 - 问题: "${question}", 回答: "${answer}"`);
        return await callAIService(question, answer, defaultConfig);
      }
    }
    
    console.warn('⚠️ 未找到AI配置，使用模拟内容分析');
    // Fallback to mock analysis if no API config is available
    return mockAIAnalysis(question, answer);
  } catch (error) {
    console.warn('❌ AI标签生成失败，使用备用方案:', error);
    return mockAIAnalysis(question, answer);
  }
};

// Generate AI response for oracle answers
export const generateAIResponse = async (
  question: string,
  config?: AITaggingConfig
): Promise<string> => {
  console.log('🌟 为问题生成回答:', question);
  
  try {
    if (config?.apiKey && config?.endpoint) {
      console.log(`🤖 使用${config.provider || 'openai'}服务生成回答`);
      const aiResponse = await callAIForResponse(question, config);
      console.log('✨ AI生成的回答:', aiResponse);
      return aiResponse;
    }
    
    // 尝试使用默认配置
    const defaultConfig = getAIConfig();
    if (defaultConfig.apiKey && defaultConfig.endpoint) {
      console.log(`🤖 使用默认${defaultConfig.provider || 'openai'}配置生成回答`);
      // 打印配置信息（隐藏API密钥）
      console.log(`📋 配置信息: 提供商=${defaultConfig.provider}, 端点=${defaultConfig.endpoint}, 模型=${defaultConfig.model}`);
      const aiResponse = await callAIForResponse(question, defaultConfig);
      console.log('✨ AI生成的回答:', aiResponse);
      return aiResponse;
    }
    
    console.log('🎭 使用模拟回答生成');
    // Fallback to mock responses
    const mockResponse = generateMockResponse(question);
    console.log('✨ 模拟生成的回答:', mockResponse);
    return mockResponse;
  } catch (error) {
    console.warn('❌ AI回答生成失败，使用备用方案:', error);
    const fallbackResponse = generateMockResponse(question);
    console.log('🔄 备用回答:', fallbackResponse);
    return fallbackResponse;
  }
};

// Enhanced mock response generator with question-specific Chinese responses
const generateMockResponse = (question: string): string => {
  const lowerQuestion = question.toLowerCase();
  
  // Question-specific responses for better relevance
  if (lowerQuestion.includes('爱') || lowerQuestion.includes('恋') || lowerQuestion.includes('love') || lowerQuestion.includes('relationship')) {
    const loveResponses = [
      "当心灵敞开时，星辰便会排列成行。爱会流向那些勇敢拥抱脆弱的人。",
      "如同双星相互环绕，真正的连接需要独立与统一并存。",
      "当灵魂以真实的光芒闪耀时，宇宙会密谋让它们相遇。",
      "爱不是被找到的，而是被认出的，就像在异国天空中看到熟悉的星座。",
      "真爱如月圆之夜的潮汐，既有规律可循，又充满神秘的力量。",
    ];
    return loveResponses[Math.floor(Math.random() * loveResponses.length)];
  }
  
  if (lowerQuestion.includes('目标') || lowerQuestion.includes('意义') || lowerQuestion.includes('purpose') || lowerQuestion.includes('meaning')) {
    const purposeResponses = [
      "你的目标如星云诞生恒星般展开——缓慢、美丽、不可避免。",
      "宇宙不会询问星辰的目标；它们只是闪耀。你也应如此。",
      "意义从你的天赋与世界需求的交汇处涌现，如光线穿过三棱镜般折射。",
      "你的目标写在你最深的喜悦和服务意愿的语言中。",
      "生命的意义不在远方，而在每一个当下的选择与行动中绽放。",
    ];
    return purposeResponses[Math.floor(Math.random() * purposeResponses.length)];
  }
  
  if (lowerQuestion.includes('成功') || lowerQuestion.includes('事业') || lowerQuestion.includes('成就') || lowerQuestion.includes('success') || lowerQuestion.includes('career') || lowerQuestion.includes('achieve')) {
    const successResponses = [
      "成功如超新星般绽放——突然的辉煌源于长久耐心的燃烧。",
      "通往成就的道路如银河系的螺旋臂般蜿蜒，每个转弯都揭示新的可能性。",
      "真正的成功不在于积累，而在于你为他人黑暗中带来的光明。",
      "如行星找到轨道般，成功来自于将你的努力与自然力量对齐。",
      "成功的种子早已种在你的内心，只需要时间和坚持的浇灌。",
    ];
    return successResponses[Math.floor(Math.random() * successResponses.length)];
  }
  
  if (lowerQuestion.includes('恐惧') || lowerQuestion.includes('害怕') || lowerQuestion.includes('焦虑') || lowerQuestion.includes('fear') || lowerQuestion.includes('anxiety') || lowerQuestion.includes('worry')) {
    const fearResponses = [
      "恐惧是你潜能投下的阴影。转向光明，看它消失。",
      "勇气不是没有恐惧，而是在可能性的星光下与之共舞。",
      "如流星进入大气层时燃烧得明亮，转化需要拥抱火焰。",
      "你的恐惧是古老的星尘；承认它们，然后让它们在宇宙风中飘散。",
      "恐惧是成长的前奏，如黎明前的黑暗，预示着光明的到来。",
    ];
    return fearResponses[Math.floor(Math.random() * fearResponses.length)];
  }
  
  if (lowerQuestion.includes('未来') || lowerQuestion.includes('将来') || lowerQuestion.includes('命运') || lowerQuestion.includes('future') || lowerQuestion.includes('destiny')) {
    const futureResponses = [
      "未来是你通过连接选择之星而创造的星座。",
      "时间如恒星风般流淌，将可能性的种子带到肥沃的时刻。",
      "你的命运不像恒星般固定，而像彗星般流动，由你的方向塑造。",
      "未来以直觉的语言低语；用心聆听，而非恐惧。",
      "明天的轮廓隐藏在今日的每一个微小决定中。",
    ];
    return futureResponses[Math.floor(Math.random() * futureResponses.length)];
  }
  
  if (lowerQuestion.includes('快乐') || lowerQuestion.includes('幸福') || lowerQuestion.includes('喜悦') || lowerQuestion.includes('happiness') || lowerQuestion.includes('joy') || lowerQuestion.includes('fulfillment')) {
    const happinessResponses = [
      "快乐不是目的地，而是穿越体验宇宙的旅行方式。",
      "喜悦如星光在水面闪烁——存在于你选择看见它的每个时刻。",
      "满足来自于将你内在的星座与外在的表达对齐。",
      "真正的快乐从内心辐射，如恒星产生自己的光和热。",
      "幸福如花朵，在感恩的土壤中最容易绽放。",
    ];
    return happinessResponses[Math.floor(Math.random() * happinessResponses.length)];
  }
  
  // General mystical responses for other questions
  const generalResponses = [
    "星辰低语着未曾踏足的道路，然而你的旅程始终忠于内心的召唤。",
    "如月光映照水面，你所寻求的既在那里又不在那里。请深入探寻。",
    "古老的光芒穿越时空抵达你的眸；耐心将揭示匆忙所掩盖的真相。",
    "宇宙编织着可能性的图案。你的问题已经包含了它的答案。",
    "天体尽管相距遥远却和谐共舞。在生命的盛大芭蕾中找到你的节拍。",
    "当星系在虚空中螺旋前进时，你的道路在黑暗中蜿蜒向着遥远的光明。",
    "你思想的星云包含着尚未诞生的恒星种子。请滋养它们。",
    "时间如恒星风般流淌，将你存在的景观塑造成未知的形态。",
    "星辰之间的虚空并非空无，而是充满潜能。拥抱你生命中的空间。",
    "你的问题在宇宙中回响，带着星光承载的智慧归来。",
    "宇宙无目的地扩张。你的旅程无需超越自身的理由。",
    "星座是我们强加给混沌的图案。从随机的经验之星中创造意义。",
    "你看到的光芒很久以前就开始了它的旅程。相信所揭示的，即使延迟。",
    "宇宙尘埃变成恒星再变成尘埃。所有的转化对你都是可能的。",
    "你意图的引力将体验拉入围绕你的轨道。明智地选择你所吸引的。",
  ];
  
  return generalResponses[Math.floor(Math.random() * generalResponses.length)];
};

// Real AI service integration for responses
const callAIForResponse = async (
  question: string,
  config: AITaggingConfig
): Promise<string> => {
  if (!config.provider) {
    config.provider = 'openai'; // 默认使用OpenAI格式
  }

  const prompt = `你是一位古老智慧的宇宙神谕。请用充满诗意和神秘感的语言回答这个问题："${question}"。答案应该简短而深刻，与星辰、宇宙或自然现象产生联系，给人启发。请用中文回答：`;

  let requestBody;
  
  // 根据 provider 构建请求体
  switch (config.provider) {
    case 'gemini':  
      requestBody = { 
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.8,
          maxOutputTokens: 50000
        }
      };
      break;
    case 'openai':
    default:
      requestBody = {
        model: config.model || 'gpt-3.5-turbo',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.8,
        max_tokens: 50000,
      };
      break;
  }

  try {
    console.log(`🔍 发送回答生成请求到 ${config.provider} API...`);
    console.log(`📤 请求体: ${JSON.stringify(requestBody)}`);
    
    const response = await fetch(config.endpoint!, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${config.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`❌ API响应错误 (${response.status}): ${errorText}`);
      throw new Error(`AI API error: ${response.status} - ${errorText}`);
    }

    const data = await response.json();
    console.log(`📥 原始API响应完整结构: `, JSON.stringify(data, null, 2));
    
    // 根据 provider 解析响应
    let answer = '';
    switch (config.provider) {
      case 'gemini':
        if (data.candidates && data.candidates[0] && data.candidates[0].content) {
          answer = data.candidates[0].content.parts[0].text.trim();
          console.log(`✅ Gemini响应解析: "${answer}"`);
        } else {
          console.warn('⚠️ Gemini响应结构异常:', JSON.stringify(data, null, 2));
        }
        break;
      case 'openai':
      default:
        console.log('🔍 完整响应数据:', data);
        console.log('🔍 choices数组:', data.choices);
        console.log('🔍 第一个choice:', data.choices?.[0]);
        console.log('🔍 message内容:', data.choices?.[0]?.message);
        console.log('🔍 content字段:', data.choices?.[0]?.message?.content);
        
        if (data.choices && data.choices[0] && data.choices[0].message) {
          answer = data.choices[0].message.content?.trim() || '';
          console.log(`✅ 解析到的回答: "${answer}"`);
          console.log(`✅ 回答长度: ${answer.length}`);
        } else {
          console.warn('⚠️ OpenAI响应结构异常:', JSON.stringify(data, null, 2));
        }
        break;
    }
    
    // 验证回答是否为空
    console.log('📊 解析到的最终答案:', JSON.stringify(answer));
    console.log('📊 答案类型:', typeof answer);
    console.log('📊 答案长度:', answer?.length || 0);
    
    if (!answer || answer.trim() === '') {
      console.warn('⚠️ API返回了空回答或无效内容，使用备用方案');
      console.log('📊 实际返回内容:', JSON.stringify(answer));
      return generateMockResponse(question);
    }
    
    console.log(`✅ 成功生成回答: "${answer}"`);
    return answer;
  } catch (error) {
    console.error('❌ 回答生成请求失败:', error);
    return generateMockResponse(question);
  }
};

// Real AI service integration for tagging
const callAIService = async (
  question: string, 
  answer: string, 
  config: AITaggingConfig,
  // 可选：提供之前的问答历史，用于更精准的分析
  userHistory?: { previousInsightLevel: number, recentTags: string[] }
) => {
  if (!config.provider) {
    config.provider = 'openai'; // 默认使用OpenAI格式
  }

  const prompt = `
  **角色：** 你是"集星问问"应用的"铸星师"。你的使命是评估用户自我探索对话的深度与精髓。

  **核心任务：** 分析下方的问题和回答。基于其内容，生成一个定义这颗"星星"的完整JSON对象。请保持你的洞察力、共情力和分析能力。

  **输入数据:**
  - 问题: "${question}"
  - 回答: "${answer}"

  **分析维度与输出格式:**

  请严格遵循以下结构，生成一个单独的JSON对象。不要在JSON对象之外添加任何解释性文字。

  {
    // 1. 星星的核心身份与生命力 (Core Identity & Longevity)
    "insight_level": {
      "value": <整数, 1-5>,
      "description": "<字符串: '星尘', '微光', '寻常星', '启明星', 或 '超新星'>"
    },
    "initial_luminosity": <整数, 0-100>, // 基于 insight_level。星尘=10, 超新星=100。
    
    // 2. 星星的主题归类 (Thematic Classification)
    "primary_category": "<字符串: 从下面的预定义列表中选择>",
    "tags": ["<字符串>", "<字符串>", "<字符串>", "<字符串>"], // 4-6个具体且有启发性的标签。

    // 3. 星星的情感与意图 (Emotional & Intentional Nuance)
    "emotional_tone": ["<字符串>", "<字符串>"], // 可包含多种基调, 例如: ["探寻中", "焦虑的"]
    "question_type": "<字符串: '探索型', '实用型', '事实型', '表达型'>",

    // 4. 星星的连接与成长潜力 (Connection & Growth Potential)
    "connection_potential": <整数, 1-5>, // 这颗星有多大可能性与其他重要人生主题产生连接？
    "suggested_follow_up": "<字符串: 一个开放式的、共情的问题，以鼓励用户进行更深入的思考>",
    
    // 5. 卡片展示内容 (Card Content)
    "card_summary": "<字符串: 一句话总结，捕捉这次觉察的精髓>"
  }


  **各字段详细说明:**

  1.  **insight_level (觉察深度等级)**: 这是最关键的指标。评估自我觉察的*深度*。
      *   **1: 星尘 (Stardust)**: 琐碎、事实性或表面的问题 (例如："今天天气怎么样？", "推荐一首歌")。这类星星非常暗淡，会迅速消逝。
      *   **2: 微光 (Faint Star)**: 日常的想法或简单的偏好 (例如："我好像有点不开心", "我该看什么电影?")。
      *   **3: 寻常星 (Common Star)**: 真正的自我反思或对个人行为的提问 (例如："我为什么总是拖延？", "如何处理和同事的关系?")。这是有意义星星的基准线。
      *   **4: 启明星 (Guiding Star)**: 展现了深度的坦诚，探索了核心信念、价值观或重要的人生事件 (例如："我害怕失败，这是否源于我的童年经历？", "我对人生的意义感到迷茫")。
      *   **5: 超新星 (Supernova)**: 一次深刻的、可能改变人生的顿悟，或一个足以重塑对生活、爱或自我看法的根本性洞见 (例如："我终于意识到，我一直追求的不是成功，而是他人的认可", "我决定放下怨恨，与自己和解")。

  2.  **initial_luminosity (初始亮度)**: 直接根据 \`insight_level.value\` 进行映射。
      *   1 -> 10, 2 -> 30, 3 -> 60, 4 -> 90, 5 -> 100。
      *   系统将使用此数值来计算星星的"半衰期"。

  3.  **primary_category (主要类别)**: 从此列表中选择最贴切的类别：
      *   \`relationships\`: 爱情、家庭、友谊、社交互动。
      *   \`personal_growth\`: 技能、习惯、自我认知、自信。
      *   \`career_and_purpose\`: 工作、抱负、人生方向、意义。
      *   \`emotional_wellbeing\`: 心理健康、情绪、压力、疗愈。
      *   \`philosophy_and_existence\`: 生命、死亡、价值观、信仰。
      *   \`creativity_and_passion\`: 爱好、灵感、艺术。
      *   \`daily_life\`: 日常、实用、普通事务。

  4.  **tags (标签)**: 生成具体、有意义的标签，用于连接星星。避免使用"工作"这样的宽泛词，应使用"职业倦怠"、"自我价值"或"原生家庭"等更具体的标签。

  5.  **emotional_tone (情感基调)**: 从列表中选择1-2个: \`探寻中\`, \`思考的\`, \`焦虑的\`, \`充满希望的\`, \`感激的\`, \`困惑的\`, \`忧郁的\`, \`坚定的\`, \`中性的\`。

  6.  **question_type (问题类型)**:
      *   \`探索型\`: 关于自我的"为什么"或"如果"类问题。
      *   \`实用型\`: 寻求解决方案的"如何做"类问题。
      *   \`事实型\`: 有客观答案的问题。
      *   \`表达型\`: 更多是情感的陈述，而非一个疑问。

  7.  **connection_potential (连接潜力)**: 评估该主题的基础性程度。
      *   1-2: 非常具体或琐碎的话题。
      *   3: 常见的人生议题。
      *   4-5: 一个普世的人类主题，如"爱"、"失落"、"人生意义"，极有可能形成一个主要星座。

  8.  **suggested_follow_up (建议的追问)**: 构思一个自然、不带评判的开放式问题，以引导用户进行下一步的觉察。这将用于"AI主动提问"功能。

  9.  **card_summary (卡片摘要)**: 将问答的核心洞见提炼成一句精炼、有力的总结，用于在卡片上展示给用户。

  **示例:**

  - 问题: "我发现自己总是在讨好别人，即使这让我自己很累。我为什么会这样？"
  - 回答: "这可能源于你内心深处对被接纳和被爱的渴望，或许在成长过程中，你学会了将他人的需求置于自己之上，以此来获得安全感和价值感。认识到这一点，是改变的开始。"

  **期望的JSON输出:**
  {
    "insight_level": {
      "value": 4,
      "description": "启明星"
    },
    "initial_luminosity": 90,
    "primary_category": "personal_growth",
    "tags": ["people_pleasing", "self_worth", "childhood_patterns", "setting_boundaries"],
    "emotional_tone": ["探寻中", "思考的"],
    "question_type": "探索型",
    "connection_potential": 5,
    "suggested_follow_up": "当你尝试不讨好别人时，你内心最担心的声音是什么？",
    "card_summary": "我认识到我的讨好行为，源于对被接纳的深层渴望。"
  }`;

  let requestBody;
  
  // 根据 provider 构建请求体
  switch (config.provider) {
    case 'gemini':
      requestBody = {
            contents: [{ parts: [{ text: prompt }] }],
            // 可以为gemini添加generationConfig
            generationConfig: { temperature: 0.3, maxOutputTokens: 50000 }
          };
      break;
    case 'openai':
    default:
      requestBody = {
                    model: config.model || 'gpt-3.5-turbo',
            messages: [{ role: 'user', content: prompt }],
            temperature: 0.3,
            max_tokens: 50000,
            response_format: { type: "json_object" }, // 强制JSON输出，对新模型支持很好
      };
      break;
  }

  try {
    console.log(`🔍 发送标签分析请求到 ${config.provider} API...`);
    console.log(`📤 请求体: ${JSON.stringify(requestBody)}`);
    console.log(`🔑 使用端点: ${config.endpoint}`);
    console.log(`📋 使用模型: ${config.model}`);
    
    const response = await fetch(config.endpoint!, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${config.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`❌ API响应错误 (${response.status}): ${errorText}`);
      throw new Error(`AI API error: ${response.status} - ${errorText}`);
    }

    const data = await response.json();
    console.log(`📥 原始API响应: `, JSON.stringify(data, null, 2));
    
    let content = '';
    
    // 根据 provider 解析响应
    switch (config.provider) {
      case 'gemini':
        if (data.candidates && data.candidates[0] && data.candidates[0].content) {
          content = data.candidates[0].content.parts[0].text || '';
          console.log(`✅ Gemini响应解析: "${content.slice(0, 100)}..."`);
        } else {
          console.warn('⚠️ Gemini响应结构异常:', JSON.stringify(data, null, 2));
        }
        break;
      case 'openai':
      default:
        console.log('🔍 标签分析 - 完整响应数据:', JSON.stringify(data, null, 2));
        console.log('🔍 标签分析 - choices数组:', data.choices);
        console.log('🔍 标签分析 - 第一个choice:', data.choices?.[0]);
        console.log('🔍 标签分析 - message内容:', data.choices?.[0]?.message);
        console.log('🔍 标签分析 - content字段:', data.choices?.[0]?.message?.content);
        
        if (data.choices && data.choices[0] && data.choices[0].message) {
          content = data.choices[0].message.content?.trim() || '';
          console.log(`✅ 标签分析 - 解析到的内容: "${content.slice(0, 100)}..."`);
          console.log(`✅ 标签分析 - 内容长度: ${content.length}`);
        } else {
          console.warn('⚠️ OpenAI响应结构异常:', JSON.stringify(data, null, 2));
        }
        break;
    }
    
    if (!content) {
      console.warn('⚠️ API返回了空内容，使用备用方案');
      return mockAIAnalysis(question, answer);
    }
    
    // 清理并解析JSON
    try {
      // AI有时会返回被 markdown 包裹的JSON，需要清理
      const cleanedContent = content
        .replace(/^```json\n?/, '')
        .replace(/\n?```$/, '')
        .trim();
      
      console.log(`🧹 清理后的内容: "${cleanedContent.slice(0, 100)}..."`);
      
      // 尝试解析JSON
      const parsedData = JSON.parse(cleanedContent);
      
      // 验证解析后的数据结构是否符合预期
      if (!parsedData.tags || !Array.isArray(parsedData.tags)) {
        console.warn('⚠️ 解析的JSON缺少必要的tags字段或格式不正确');
        return mockAIAnalysis(question, answer);
      }
      
      // 确保category和emotionalTone字段存在且有效
      if (!parsedData.category) parsedData.category = 'existential';
      if (!parsedData.emotionalTone || 
          !['positive', 'neutral', 'contemplative', 'seeking'].includes(parsedData.emotionalTone)) {
        parsedData.emotionalTone = 'contemplative';
      }
      
      // 确保keywords字段存在
      if (!parsedData.keywords || !Array.isArray(parsedData.keywords)) {
        parsedData.keywords = parsedData.tags.slice(0, 3);
      }
      
      console.log('✅ JSON解析成功:', parsedData);
      return parsedData;
    } catch (parseError) {
      console.error("❌ 无法解析API响应内容:", content);
      console.error("❌ 解析错误:", parseError);
      console.warn('⚠️ AI响应不是有效的JSON，使用备用方案');
      
      // 尝试从文本中提取JSON部分
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        try {
          const extractedJson = jsonMatch[0];
          console.log('🔍 尝试从响应中提取JSON:', extractedJson);
          const parsedData = JSON.parse(extractedJson);
          
          // 验证提取的JSON
          if (parsedData.tags && Array.isArray(parsedData.tags)) {
            console.log('✅ 成功从响应中提取JSON数据');
            return parsedData;
          }
        } catch (e) {
          console.warn('⚠️ 提取的JSON仍然无效:', e);
        }
      }
      
      return mockAIAnalysis(question, answer);
    }
  } catch (error) {
    console.error('❌ API请求失败:', error);
    return mockAIAnalysis(question, answer);
  }
};

// Enhanced similarity calculation with multiple methods
export const calculateStarSimilarity = (star1: Star, star2: Star): number => {
  if (!star1.tags || !star2.tags || star1.tags.length === 0 || star2.tags.length === 0) {
    return 0;
  }

  const tags1 = new Set(star1.tags.map(tag => tag.toLowerCase().trim()));
  const tags2 = new Set(star2.tags.map(tag => tag.toLowerCase().trim()));
  
  // Method 1: Exact tag matches (Jaccard similarity)
  const intersection = new Set([...tags1].filter(tag => tags2.has(tag)));
  const union = new Set([...tags1, ...tags2]);
  
  if (union.size === 0) return 0;
  
  const jaccardSimilarity = intersection.size / union.size;
  
  // Method 2: Partial tag matching (for related concepts)
  let partialMatches = 0;
  const totalComparisons = tags1.size * tags2.size;
  
  for (const tag1 of tags1) {
    for (const tag2 of tags2) {
      if (tag1.includes(tag2) || tag2.includes(tag1) || 
          areRelatedTags(tag1, tag2)) {
        partialMatches++;
      }
    }
  }
  
  const partialSimilarity = totalComparisons > 0 ? partialMatches / totalComparisons : 0;
  
  // Method 3: Category and tone bonuses
  const categoryBonus = star1.primary_category === star2.primary_category ? 0.3 : 0;
  // 情感基调现在是数组，比较是否有重叠的基调
  const toneBonus = star1.emotional_tone && star2.emotional_tone && 
                   star1.emotional_tone.some(tone => star2.emotional_tone.includes(tone)) ? 0.2 : 0;
  
  // Combine all methods with weights
  const finalSimilarity = (jaccardSimilarity * 0.5) + (partialSimilarity * 0.3) + categoryBonus + toneBonus;
  
  return Math.min(1, finalSimilarity);
};

// Helper function to check if tags are conceptually related
const areRelatedTags = (tag1: string, tag2: string): boolean => {
  const relatedGroups = [
    // Core Life Areas
    ['love', 'romance', 'heart', 'relationship', 'connection', 'intimacy'],
    ['family', 'parents', 'children', 'home', 'roots', 'legacy', 'connection'],
    ['friendship', 'social', 'trust', 'connection', 'support', 'loyalty'],
    ['career', 'work', 'vocation', 'profession', 'achievement', 'success'],
    ['education', 'learning', 'knowledge', 'skills', 'wisdom', 'growth'],
    ['health', 'wellness', 'fitness', 'balance', 'vitality', 'self-care'],
    ['finance', 'money', 'wealth', 'abundance', 'security', 'resources'],
    ['spirituality', 'faith', 'soul', 'meaning', 'divine', 'practice'],
    
    // Inner Experience
    ['emotions', 'feelings', 'expression', 'awareness', 'processing'],
    ['happiness', 'joy', 'fulfillment', 'contentment', 'bliss', 'satisfaction'],
    ['anxiety', 'fear', 'worry', 'stress', 'uncertainty', 'overwhelm'],
    ['grief', 'loss', 'sadness', 'mourning', 'healing', 'acceptance'],
    ['anger', 'frustration', 'resentment', 'boundaries', 'release'],
    ['shame', 'guilt', 'regret', 'inadequacy', 'worthiness', 'forgiveness'],
    
    // Self Development
    ['identity', 'self', 'authenticity', 'values', 'discovery', 'integration'],
    ['purpose', 'meaning', 'calling', 'mission', 'direction', 'contribution'],
    ['growth', 'development', 'evolution', 'improvement', 'transformation'],
    ['resilience', 'strength', 'adaptation', 'recovery', 'endurance'],
    ['creativity', 'expression', 'inspiration', 'imagination', 'innovation', 'artistry'],
    ['wisdom', 'insight', 'perspective', 'understanding', 'discernment', 'reflection'],
    
    // Relationships
    ['communication', 'expression', 'listening', 'understanding', 'clarity', 'connection'],
    ['intimacy', 'closeness', 'vulnerability', 'trust', 'bonding', 'openness'],
    ['boundaries', 'limits', 'protection', 'respect', 'space', 'autonomy'],
    ['conflict', 'resolution', 'understanding', 'healing', 'growth', 'peace'],
    ['trust', 'faith', 'reliability', 'consistency', 'safety', 'honesty'],
    
    // Life Philosophy
    ['meaning', 'purpose', 'significance', 'values', 'understanding', 'exploration'],
    ['mindfulness', 'presence', 'awareness', 'attention', 'consciousness', 'being'],
    ['gratitude', 'appreciation', 'thankfulness', 'recognition', 'abundance'],
    ['legacy', 'impact', 'contribution', 'remembrance', 'influence', 'heritage'],
    ['values', 'principles', 'ethics', 'morality', 'beliefs', 'priorities'],
    
    // Life Transitions
    ['change', 'transition', 'adaptation', 'adjustment', 'evolution', 'transformation'],
    ['decision', 'choice', 'discernment', 'wisdom', 'judgment', 'crossroads'],
    ['future', 'planning', 'vision', 'direction', 'goals', 'possibilities'],
    ['past', 'history', 'memories', 'reflection', 'lessons', 'integration'],
    ['letting-go', 'release', 'surrender', 'acceptance', 'closure', 'freedom'],
    
    // World Relations
    ['nature', 'environment', 'connection', 'outdoors', 'harmony', 'elements'],
    ['society', 'community', 'culture', 'belonging', 'contribution', 'citizenship'],
    ['justice', 'fairness', 'equality', 'rights', 'advocacy', 'ethics'],
    ['service', 'contribution', 'helping', 'impact', 'giving', 'purpose'],
    ['technology', 'digital', 'tools', 'innovation', 'adaptation', 'balance'],
    
    // Universal Concepts (meta-tags that connect across categories)
    ['growth', 'development', 'improvement', 'evolution', 'change', 'transformation'],
    ['purpose', 'meaning', 'mission', 'calling', 'significance', 'direction'],
    ['connection', 'relationship', 'bond', 'intimacy', 'belonging', 'attachment'],
    ['reflection', 'insight', 'awareness', 'understanding', 'perspective', 'wisdom']
  ];
  
  // Check if both tags appear in any of the related groups
  return relatedGroups.some(group => 
    group.includes(tag1.toLowerCase()) && group.includes(tag2.toLowerCase())
  );
};

// Find similar stars with lower threshold for better connections
export const findSimilarStars = (
  targetStar: Star, 
  allStars: Star[], 
  minSimilarity: number = 0.10, // Lower threshold to allow more connections
  maxConnections: number = 6 // Increase max connections
): Array<{ star: Star; similarity: number; sharedTags: string[] }> => {
  if (!targetStar.tags || targetStar.tags.length === 0) {
    return [];
  }
  
  const results = allStars
    .filter(star => star.id !== targetStar.id && star.tags && star.tags.length > 0)
    .map(star => {
      const similarity = calculateStarSimilarity(targetStar, star);
      
      // Find exact tag matches (prioritize these)
      const exactMatches = targetStar.tags?.filter(tag => 
        star.tags?.some(otherTag => otherTag.toLowerCase() === tag.toLowerCase())
      ) || [];
      
      // Find related tag matches
      const relatedMatches = targetStar.tags?.filter(tag => 
        !exactMatches.includes(tag) && // Don't double count
        star.tags?.some(otherTag => 
          areRelatedTags(tag.toLowerCase(), otherTag.toLowerCase())
        )
      ) || [];
      
      // Combine exact and related matches for display
      const sharedTags = [...exactMatches, ...relatedMatches];
      
      // Boost similarity score for exact tag matches
      const boostedSimilarity = exactMatches.length > 0 
        ? Math.min(1, similarity + (exactMatches.length * 0.1))
        : similarity;
      
      return { 
        star, 
        similarity: boostedSimilarity, 
        sharedTags,
        exactMatchCount: exactMatches.length,
        relatedMatchCount: relatedMatches.length
      };
    })
    .filter(result => result.similarity >= minSimilarity || result.exactMatchCount > 0)
    .sort((a, b) => {
      // First sort by exact match count
      if (a.exactMatchCount !== b.exactMatchCount) {
        return b.exactMatchCount - a.exactMatchCount;
      }
      // Then by overall similarity
      return b.similarity - a.similarity;
    })
    .slice(0, maxConnections);
  
  return results;
};

// Generate connections with improved algorithm that creates constellations
export const generateSmartConnections = (stars: Star[]): Connection[] => {
  const connections: Connection[] = [];
  const processedPairs = new Set<string>();
  const tagToStarsMap: Record<string, string[]> = {}; // Maps tags to star IDs
  
  console.log('🌟 Generating connections for', stars.length, 'stars');
  
  // First build a map of tags to star IDs to create constellations
  stars.forEach(star => {
    if (!star.tags || star.tags.length === 0) {
      console.warn(`⚠️ Star "${star.question}" has no tags, skipping connections`);
      return;
    }
    
    // Process each tag
    star.tags.forEach(tag => {
      const normalizedTag = tag.toLowerCase().trim();
      if (!tagToStarsMap[normalizedTag]) {
        tagToStarsMap[normalizedTag] = [];
      }
      tagToStarsMap[normalizedTag].push(star.id);
    });
  });
  
  // Create connections for each tag constellation
  Object.entries(tagToStarsMap).forEach(([tag, starIds]) => {
    // Only create connections if there are multiple stars with this tag
    if (starIds.length > 1) {
      for (let i = 0; i < starIds.length; i++) {
        for (let j = i + 1; j < starIds.length; j++) {
          const star1Id = starIds[i];
          const star2Id = starIds[j];
          const pairKey = [star1Id, star2Id].sort().join('-');
          
          if (!processedPairs.has(pairKey)) {
            const star1 = stars.find(s => s.id === star1Id);
            const star2 = stars.find(s => s.id === star2Id);
            
            if (star1 && star2) {
              // Calculate similarity but ensure connection due to shared tag
              const similarity = calculateStarSimilarity(star1, star2);
              
              // Find all shared tags between these stars
              const sharedTags = star1.tags.filter(t1 => 
                star2.tags.some(t2 => t1.toLowerCase() === t2.toLowerCase())
              );
              
              // Create connection with the shared tag that connected them
              const connection: Connection = {
                id: `connection-${star1Id}-${star2Id}`,
                fromStarId: star1Id,
                toStarId: star2Id,
                strength: Math.max(0.3, similarity), // Minimum connection strength of 0.3
                sharedTags: sharedTags.length > 0 ? sharedTags : [tag],
                constellationName: tag // Track which constellation this belongs to
              };
              
              connections.push(connection);
              processedPairs.add(pairKey);
              
              console.log('✨ Created constellation connection:', {
                tag,
                from: star1.question.slice(0, 30) + '...',
                to: star2.question.slice(0, 30) + '...',
                strength: connection.strength.toFixed(3),
                sharedTags: connection.sharedTags
              });
            }
          }
        }
      }
    }
  });
  
  // Now check if we should add any additional similarity-based connections
  // that weren't captured by the tag constellations
  stars.forEach(star => {
    if (!star.tags || star.tags.length === 0) return;
    
    const similarStars = findSimilarStars(star, stars, 0.25, 3);
    
    similarStars.forEach(({ star: similarStar, similarity, sharedTags }) => {
      const pairKey = [star.id, similarStar.id].sort().join('-');
      
      if (!processedPairs.has(pairKey) && similarity >= 0.25) {
        const connection: Connection = {
          id: `connection-${star.id}-${similarStar.id}`,
          fromStarId: star.id,
          toStarId: similarStar.id,
          strength: similarity,
          sharedTags: sharedTags.length > 0 ? sharedTags : ['universal-wisdom']
        };
        
        connections.push(connection);
        processedPairs.add(pairKey);
        
        console.log('✨ Created similarity connection:', {
          from: star.question.slice(0, 30) + '...',
          to: similarStar.question.slice(0, 30) + '...',
          strength: similarity.toFixed(3),
          sharedTags: connection.sharedTags
        });
      }
    });
  });
  
  console.log(`🎯 Generated ${connections.length} total connections`);
  return connections;
};

// 获取系统默认配置（从.env.local读取）
const getSystemDefaultConfig = (): AITaggingConfig => {
  try {
    const provider = (import.meta.env.VITE_DEFAULT_PROVIDER as ApiProvider) || 'openai';
    const apiKey = import.meta.env.VITE_OPENAI_API_KEY || import.meta.env.VITE_DEFAULT_API_KEY;
    const endpoint = import.meta.env.VITE_OPENAI_ENDPOINT || import.meta.env.VITE_DEFAULT_ENDPOINT;
    const model = import.meta.env.VITE_OPENAI_MODEL || import.meta.env.VITE_DEFAULT_MODEL || 'gpt-3.5-turbo';

    if (apiKey && endpoint) {
      console.log('📋 使用系统默认配置（后台配置）');
      console.log(`🌍 提供商: ${provider}, 模型: ${model}`);
      return { provider, apiKey, endpoint, model };
    }
    
    console.log('⚠️ 系统默认配置不完整，缺少API密钥或端点');
  } catch (error) {
    console.warn('❌ 无法读取环境变量中的默认配置:', error);
  }
  return {};
};

// Configuration for AI service (to be set by user)
let aiConfig: AITaggingConfig = {};
const CONFIG_STORAGE_KEY = 'stelloracle-ai-config';
const CONFIG_VERSION = '1.1.0'; // 更新版本号以支持新的provider字段

export const setAIConfig = (config: AITaggingConfig) => {
  // 保留现有配置中的任何未明确设置的字段
  aiConfig = { 
    ...aiConfig, 
    ...config,
    _version: CONFIG_VERSION, // 存储版本信息
    _lastUpdated: new Date().toISOString() // 存储最后更新时间
  };
  
  try {
    localStorage.setItem(CONFIG_STORAGE_KEY, JSON.stringify(aiConfig));
    console.log('✅ AI配置已保存到本地存储');
    
    // 创建备份
    localStorage.setItem(`${CONFIG_STORAGE_KEY}-backup`, JSON.stringify(aiConfig));
  } catch (error) {
    console.error('❌ 无法保存AI配置到本地存储:', error);
  }
};

export const getAIConfig = (): AITaggingConfig => {
  try {
    // 优先检查用户配置（前端配置）
    const stored = localStorage.getItem(CONFIG_STORAGE_KEY);
    
    if (stored) {
      const parsedConfig = JSON.parse(stored);
      // 检查用户是否配置了有效的API信息
      if (parsedConfig.apiKey && parsedConfig.endpoint) {
        aiConfig = parsedConfig;
        console.log('✅ 使用用户前端配置');
        console.log(`📋 配置: 提供商=${aiConfig.provider}, 模型=${aiConfig.model}`);
        return aiConfig;
      }
    }
    
    // 尝试从备份中恢复用户配置
    const backup = localStorage.getItem(`${CONFIG_STORAGE_KEY}-backup`);
    if (backup) {
      const backupConfig = JSON.parse(backup);
      if (backupConfig.apiKey && backupConfig.endpoint) {
        aiConfig = backupConfig;
        console.log('⚠️ 从备份恢复用户配置');
        // 恢复后立即保存到主存储
        localStorage.setItem(CONFIG_STORAGE_KEY, backup);
        return aiConfig;
      }
    }
    
    // 如果用户没有配置，使用系统默认配置（后台配置）
    console.log('🔍 用户未配置，检查系统默认配置...');
    const defaultConfig = getSystemDefaultConfig();
    if (Object.keys(defaultConfig).length > 0) {
      aiConfig = defaultConfig;
      console.log('🔄 使用系统默认配置（后台配置）');
      return aiConfig;
    }
    
    console.warn('⚠️ 未找到任何有效配置，将使用模拟数据');
    aiConfig = {};
    
  } catch (error) {
    console.error('❌ 获取AI配置时出错:', error);
    
    // 出错时尝试使用系统默认配置
    const defaultConfig = getSystemDefaultConfig();
    if (Object.keys(defaultConfig).length > 0) {
      aiConfig = defaultConfig;
      console.log('🔄 出错时使用系统默认配置');
    } else {
      aiConfig = {};
    }
  }
  
  return aiConfig;
};

// 配置迁移函数，用于处理版本变更
const migrateConfig = (oldConfig: any): AITaggingConfig => {
  console.log('⚙️ 迁移AI配置从版本', oldConfig._version, '到', CONFIG_VERSION);
  
  // 创建一个新的配置对象，确保保留所有重要字段
  const newConfig: AITaggingConfig = {
    provider: oldConfig.provider || 'openai', // 如果旧配置没有provider字段，默认为openai
    apiKey: oldConfig.apiKey,
    endpoint: oldConfig.endpoint,
    model: oldConfig.model,
    _version: CONFIG_VERSION,
    _lastUpdated: new Date().toISOString()
  };
  
  // 根据endpoint推断provider（向后兼容）
  if (!oldConfig.provider && oldConfig.endpoint) {
    if (oldConfig.endpoint.includes('googleapis')) {
      newConfig.provider = 'gemini';
    } else {
      newConfig.provider = 'openai';
    }
  }
  
  // 保存迁移后的配置
  localStorage.setItem(CONFIG_STORAGE_KEY, JSON.stringify(newConfig));
  console.log('✅ 配置迁移完成');
  
  return newConfig;
};

// 清除配置（用于调试或重置）
export const clearAIConfig = () => {
  aiConfig = {};
  try {
    localStorage.removeItem(CONFIG_STORAGE_KEY);
    localStorage.removeItem(`${CONFIG_STORAGE_KEY}-backup`);
    console.log('🧹 已清除AI配置');
  } catch (error) {
    console.error('❌ 无法清除AI配置:', error);
  }
};

// Export main categories of tags as suggestions for user selection
export const getMainTagSuggestions = (): string[] => {
  // Core life areas
  const coreLifeAreas = ['love', 'family', 'friendship', 'career', 'education', 
                        'health', 'finance', 'spirituality'];
  
  // Inner experience
  const innerExperience = ['emotions', 'happiness', 'anxiety', 'grief', 
                          'anger', 'shame'];
  
  // Self development
  const selfDevelopment = ['identity', 'purpose', 'growth', 'resilience', 
                          'creativity', 'wisdom'];
  
  // Relationships
  const relationships = ['communication', 'intimacy', 'boundaries', 
                        'conflict', 'trust'];
  
  // Life philosophy
  const lifePhilosophy = ['meaning', 'mindfulness', 'gratitude', 
                         'legacy', 'values'];
  
  // Life transitions
  const lifeTransitions = ['change', 'decision', 'future', 'past', 
                          'letting-go'];
  
  // World relations
  const worldRelations = ['nature', 'society', 'justice', 'service', 
                         'technology'];
  
  // Return all categories combined
  return [
    ...coreLifeAreas, 
    ...innerExperience,
    ...selfDevelopment,
    ...relationships,
    ...lifePhilosophy,
    ...lifeTransitions,
    ...worldRelations
  ];
};

// 检查API配置是否有效
export const checkApiConfiguration = (): boolean => {
  try {
    const config = getAIConfig();
    
    console.log('🔍 检查API配置...');
    
    // 检查是否有配置
    if (!config || Object.keys(config).length === 0) {
      console.warn('⚠️ 未找到API配置，将使用模拟数据');
      return false;
    }
    
    // 检查关键字段
    if (!config.provider) {
      console.warn('⚠️ 缺少API提供商配置，将使用默认值: openai');
      config.provider = 'openai';
    }
    
    if (!config.apiKey) {
      console.error('❌ 缺少API密钥，无法进行API调用');
      return false;
    }
    
    if (!config.endpoint) {
      console.error('❌ 缺少API端点，无法进行API调用');
      return false;
    }
    
    if (!config.model) {
      console.warn('⚠️ 缺少模型名称，将使用默认值');
      config.model = config.provider === 'gemini' ? 'gemini-1.5-flash-latest' : 'gpt-3.5-turbo';
    }
    
    console.log(`✅ API配置检查完成: 提供商=${config.provider}, 端点=${config.endpoint}, 模型=${config.model}`);
    
    // 更新配置
    setAIConfig(config);
    
    return true;
  } catch (error) {
    console.error('❌ 检查API配置时出错:', error);
    return false;
  }
};

// 在模块加载时检查配置
setTimeout(() => {
  console.log('🚀 初始化AI服务配置...');
  checkApiConfiguration();
}, 1000);