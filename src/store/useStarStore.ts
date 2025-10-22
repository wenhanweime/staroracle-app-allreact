import { create } from 'zustand';
import { Star, Connection, Constellation } from '../types';
import { generateRandomStarImage } from '../utils/imageUtils';
import { 
  analyzeStarContent, 
  generateSmartConnections,
  generateAIResponse,
  getAIConfig as getAIConfigFromUtils
} from '../utils/aiTaggingUtils';
import { instantiateTemplate } from '../utils/constellationTemplates';
import { getRandomInspirationCard, InspirationCard, GalaxyRegion } from '../utils/inspirationCards';
import { ConstellationTemplate } from '../types';

const normalizeHighlightHex = (color: unknown): string => {
  if (!color && color !== 0) return '#FFFFFF';
  let value = typeof color === 'string' ? color.trim() : String(color).trim();
  if (!value.startsWith('#')) return '#FFFFFF';
  if (value.length === 4) {
    value = `#${value[1]}${value[1]}${value[2]}${value[2]}${value[3]}${value[3]}`;
  }
  if (value.length !== 7) return '#FFFFFF';
  return value.toUpperCase();
};

interface StarPosition {
  x: number;
  y: number;
}

interface StarState {
  constellation: Constellation;
  activeStarId: string | null;
  highlightedStarId: string | null;
  galaxyHighlights: Record<string, { color: string }>;
  galaxyHighlightColor: string;
  isAsking: boolean;
  isLoading: boolean; // New state to track loading during star creation
  pendingStarPosition: StarPosition | null;
  currentInspirationCard: InspirationCard | null;
  hasTemplate: boolean;
  templateInfo: { name: string; element: string } | null;
  lastCreatedStarId: string | null;
  addStar: (question: string) => Promise<Star>;
  drawInspirationCard: (region?: GalaxyRegion) => InspirationCard;
  useInspirationCard: () => void;
  dismissInspirationCard: () => void;
  viewStar: (id: string | null) => void;
  hideStarDetail: () => void;
  setIsAsking: (isAsking: boolean, position?: StarPosition) => void;
  addGalaxyHighlightStar: (payload: { xPct: number; yPct: number; region: GalaxyRegion; question?: string; answer?: string }) => void;
  regenerateConnections: () => void;
  applyTemplate: (template: ConstellationTemplate) => void;
  clearConstellation: () => void;
  updateStarTags: (starId: string, newTags: string[]) => void;
  setGalaxyHighlights: (entries: Array<{ starId: string; color?: string }>) => void;
  setGalaxyHighlightColor: (color: string) => void;
}

// Generate initial empty constellation
const generateEmptyConstellation = (): Constellation => {
  return {
    stars: [],
    connections: []
  };
};

export const useStarStore = create<StarState>((set, get) => {
  // AIConfig getter - 使用集中式的配置管理
  const getAIConfig = () => {
    // 使用aiTaggingUtils中的getAIConfig来获取配置
    // 该函数会自动处理优先级：用户配置 > 系统默认配置 > 空配置
    return getAIConfigFromUtils();
  };

  return {
    constellation: generateEmptyConstellation(),
    activeStarId: null, // 确保初始状态为null
    highlightedStarId: null,
    galaxyHighlights: {},
    galaxyHighlightColor: '#FFE2B0',
    isAsking: false,
    isLoading: false, // Initialize loading state as false
    pendingStarPosition: null,
    currentInspirationCard: null,
    hasTemplate: false,
    templateInfo: null,
    lastCreatedStarId: null,
    
    addStar: async (question: string) => {
      const { constellation, pendingStarPosition } = get();
      const { stars } = constellation;
      
      console.log(`===== User asked a question =====`);
      console.log(`Question: "${question}"`);
      
      // Set loading state to true
      set({ isLoading: true });
      
      // Get AI configuration
      const aiConfig = getAIConfig();
      console.log('Retrieved AI config result:', {
        hasApiKey: !!aiConfig.apiKey,
        hasEndpoint: !!aiConfig.endpoint,
        provider: aiConfig.provider,
        model: aiConfig.model
      });
      
      // Create new star at the clicked position or random position first (with placeholder answer)
      const x = pendingStarPosition?.x ?? (Math.random() * 70 + 15); // 15-85%
      const y = pendingStarPosition?.y ?? (Math.random() * 70 + 15); // 15-85%
      
      // Create placeholder star (we'll update it with AI response later)
      const newStar: Star = {
        id: `star-${Date.now()}`,
        x,
        y,
        size: Math.random() * 1.5 + 2.0, // Will be updated based on AI analysis
        brightness: 0.6, // Placeholder brightness
        question,
        answer: '', // Empty initially, will be filled by streaming
        imageUrl: generateRandomStarImage(),
        createdAt: new Date(),
        isSpecial: false, // Will be updated based on AI analysis
        tags: [], // Will be filled by AI analysis
        primary_category: 'philosophy_and_existence', // Placeholder
        emotional_tone: ['探寻中'], // Placeholder
        question_type: '探索型', // Placeholder
        insight_level: { value: 1, description: '星尘' }, // Placeholder
        initial_luminosity: 10, // Placeholder
        connection_potential: 3, // Placeholder
        suggested_follow_up: '', // Will be filled by AI analysis
        card_summary: question, // Placeholder
        isTemplate: false,
        isStreaming: true, // Mark as currently streaming
      };
      
      // Add placeholder star to constellation immediately for better UX
      const updatedStars = [...stars, newStar];
      set({
        constellation: {
          stars: updatedStars,
          connections: constellation.connections, // Keep existing connections for now
        },
        activeStarId: newStar.id, // Show the star being created
        highlightedStarId: newStar.id,
        isAsking: false,
        pendingStarPosition: null,
        lastCreatedStarId: newStar.id,
      });
      
      // Generate AI response with streaming
      console.log('Starting AI response generation with streaming...');
      let answer: string;
      let streamingAnswer = '';
      
      try {
        // Set up streaming callback
        const onStream = (chunk: string) => {
          streamingAnswer += chunk;
          
          // Update star with streaming content in real time
          set(state => ({
            constellation: {
              ...state.constellation,
              stars: state.constellation.stars.map(star => 
                star.id === newStar.id 
                  ? { ...star, answer: streamingAnswer }
                  : star
              )
            }
          }));
        };
        
        answer = await generateAIResponse(question, aiConfig, onStream);
        console.log(`Got AI response: "${answer}"`);
        
        // Ensure we have a valid answer
        if (!answer || answer.trim().length === 0) {
          throw new Error('Empty AI response');
        }
      } catch (error) {
        console.warn('AI response failed, using fallback:', error);
        // Use fallback response generation
        answer = generateFallbackResponse(question);
        console.log(`Fallback response: "${answer}"`);
        
        // Update with fallback answer
        streamingAnswer = answer;
      }
      
      // Analyze content with AI for tags and categorization
      const analysis = await analyzeStarContent(question, answer, aiConfig);
      
      // Update star with final AI analysis results
      const finalStar: Star = {
        ...newStar,
        // 根据洞察等级调整星星大小，洞察等级越高，星星越大
        size: Math.random() * 1.5 + 2.0 + (analysis.insight_level?.value || 0) * 0.5, // 2.0-6.5px
        // 亮度也受洞察等级影响
        brightness: (analysis.initial_luminosity || 60) / 100, // 转换为0-1范围
        answer: streamingAnswer || answer, // Use final streamed answer
        isSpecial: Math.random() < 0.12 || (analysis.insight_level?.value || 0) >= 4, // 启明星和超新星自动成为特殊星
        tags: analysis.tags,
        primary_category: analysis.primary_category,
        emotional_tone: analysis.emotional_tone,
        question_type: analysis.question_type,
        insight_level: analysis.insight_level,
        initial_luminosity: analysis.initial_luminosity,
        connection_potential: analysis.connection_potential,
        suggested_follow_up: analysis.suggested_follow_up,
        card_summary: analysis.card_summary,
        isStreaming: false, // Streaming completed
      };
      
      console.log('⭐ Final star with AI analysis:', {
        question: finalStar.question,
        answer: finalStar.answer,
        answerLength: finalStar.answer.length,
        tags: finalStar.tags,
        primary_category: finalStar.primary_category,
        emotional_tone: finalStar.emotional_tone,
        insight_level: finalStar.insight_level,
        connection_potential: finalStar.connection_potential
      });
      
      // Update with final star and regenerate connections
      const finalStars = updatedStars.map(star => 
        star.id === newStar.id ? finalStar : star
      );
      const smartConnections = generateSmartConnections(finalStars);
      
      set({
        constellation: {
          stars: finalStars,
          connections: smartConnections,
        },
        isLoading: false, // Set loading state back to false
      });
      
      return finalStar;
    },

    drawInspirationCard: (region?: GalaxyRegion) => {
      const card = getRandomInspirationCard(region);
      console.log('🌟 Drawing inspiration card:', card.question);
      set({ currentInspirationCard: card });
      return card;
    },

    useInspirationCard: () => {
      const { currentInspirationCard } = get();
      if (currentInspirationCard) {
        console.log('✨ Using inspiration card for new star');
        // Start asking mode with the inspiration card question
        set({ 
          isAsking: true,
          currentInspirationCard: null 
        });
        
        // Pre-fill the question in the oracle input
        // This will be handled by the OracleInput component
      }
    },

    dismissInspirationCard: () => {
      console.log('👋 Dismissing inspiration card');
      set({ currentInspirationCard: null });
    },
    
    viewStar: (id: string | null) => {
      set(state => ({
        activeStarId: id,
        highlightedStarId: id ?? state.highlightedStarId,
      }));
      console.log(`👁️ Viewing star: ${id}`);
    },
    
    hideStarDetail: () => {
      set({ activeStarId: null });
      console.log('👁️ Hiding star detail');
    },
    
    setIsAsking: (isAsking: boolean, position?: StarPosition) => {
      set({ 
        isAsking,
        pendingStarPosition: position ?? null,
      });
    },

    addGalaxyHighlightStar: ({ xPct, yPct, region, question, answer }) => {
      const regionLabel =
        region === 'emotion' ? '情绪之光' : region === 'relation' ? '关系之光' : '成长之光';
      const now = Date.now();
      const newStar: Star = {
        id: `galaxy-${now}`,
        x: Math.min(100, Math.max(0, xPct)),
        y: Math.min(100, Math.max(0, yPct)),
        size: 2.5,
        brightness: 0.6,
        question: question ?? `你捕捉到的${regionLabel}提问`,
        answer: answer ?? '',
        imageUrl: generateRandomStarImage(),
        createdAt: new Date(),
        isSpecial: false,
        tags: [],
        primary_category: 'inspiration',
        emotional_tone: [regionLabel],
        question_type: '探索型',
        insight_level: { value: 1, description: '星尘' },
        initial_luminosity: 60,
        connection_potential: 2,
        suggested_follow_up: '',
        card_summary: question ?? `在${regionLabel}下的灵感`,
        isTemplate: false,
        isStreaming: false,
      };

      set(state => ({
        constellation: {
          ...state.constellation,
          stars: [...state.constellation.stars, newStar],
        },
        lastCreatedStarId: newStar.id,
      }));
    },

    setGalaxyHighlights: (entries) => {
      const fallback = get().galaxyHighlightColor;
      const next: Record<string, { color: string }> = {};
      entries.forEach(({ starId, color }) => {
        const resolved = color ?? fallback;
        next[starId] = { color: normalizeHighlightHex(resolved) };
      });
      set({ galaxyHighlights: next });
      if (typeof window !== 'undefined') {
        (window as any).__galaxyHighlights = next;
      }
    },

    setGalaxyHighlightColor: (color) => {
      set({ galaxyHighlightColor: normalizeHighlightHex(color) });
    },
    
    regenerateConnections: () => {
      const { constellation } = get();
      const smartConnections = generateSmartConnections(constellation.stars);
      
      console.log('Regenerating connections, found:', smartConnections.length);
      
      set({
        constellation: {
          ...constellation,
          connections: smartConnections,
        },
      });
    },

    applyTemplate: (template: ConstellationTemplate) => {
      console.log(`🌟 Applying template: ${template.chineseName}`);
      
      // Instantiate the template
      const { stars: templateStars, connections: templateConnections } = instantiateTemplate(template);
      
      // Get current user stars (non-template stars)
      const { constellation } = get();
      const userStars = constellation.stars.filter(star => !star.isTemplate);
      
      // Combine template stars with existing user stars
      const allStars = [...templateStars, ...userStars];
      
      // Generate connections including both template and smart connections
      const smartConnections = generateSmartConnections(allStars);
      const allConnections = [...templateConnections, ...smartConnections];
      
      set({
        constellation: {
          stars: allStars,
          connections: allConnections,
        },
        activeStarId: null, // 清除活动星星ID，避免阻止按钮点击
        highlightedStarId: null,
        hasTemplate: true,
        templateInfo: {
          name: template.chineseName,
          element: template.element
        }
      });
      
      console.log(`✨ Applied template with ${templateStars.length} stars and ${templateConnections.length} connections`);
    },

    clearConstellation: () => {
      set({
        constellation: generateEmptyConstellation(),
        activeStarId: null,
        highlightedStarId: null,
        galaxyHighlights: {},
        hasTemplate: false,
        templateInfo: null,
      });
      console.log('🧹 Cleared constellation');
    },

    updateStarTags: (starId: string, newTags: string[]) => {
      set(state => {
        // Update the star with new tags
        const updatedStars = state.constellation.stars.map(star => 
          star.id === starId 
            ? { ...star, tags: newTags } 
            : star
        );
        
        // Regenerate connections with updated tags - ensure non-null values
        const newConnections = generateSmartConnections(updatedStars);
        
        return {
          constellation: {
            stars: updatedStars,
            connections: newConnections
          }
        };
      });
      
      console.log(`🏷️ Updated tags for star ${starId}`);
    }
  };
});

// Fallback response generator for when AI fails
const generateFallbackResponse = (question: string): string => {
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
