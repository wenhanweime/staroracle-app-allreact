import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Brain, Eye, Heart, MessageCircle } from 'lucide-react';
import { AwarenessInsight } from '../types/chat';

interface AwarenessDetailModalProps {
  isOpen: boolean;
  onClose: () => void;
  insight: AwarenessInsight;
  onAskFollowUp: (question: string) => void;
}

const AwarenessDetailModal: React.FC<AwarenessDetailModalProps> = ({
  isOpen,
  onClose,
  insight,
  onAskFollowUp
}) => {
  if (!isOpen) return null;

  // 获取等级对应的图标和颜色
  const getLevelConfig = (level: string) => {
    switch (level) {
      case 'high':
        return {
          icon: Brain,
          color: 'text-yellow-400',
          bgColor: 'bg-yellow-400/10',
          borderColor: 'border-yellow-400/30',
          title: '深度洞察',
          description: '这段对话触及了深层的自我认知'
        };
      case 'medium':
        return {
          icon: Eye,
          color: 'text-blue-400',
          bgColor: 'bg-blue-400/10',
          borderColor: 'border-blue-400/30',
          title: '中度觉察',
          description: '这段对话带来了有价值的自我觉察'
        };
      case 'low':
        return {
          icon: Heart,
          color: 'text-green-400',
          bgColor: 'bg-green-400/10',
          borderColor: 'border-green-400/30',
          title: '初步觉知',
          description: '这段对话开启了自我探索的可能'
        };
      default:
        return {
          icon: MessageCircle,
          color: 'text-gray-400',
          bgColor: 'bg-gray-400/10',
          borderColor: 'border-gray-400/30',
          title: '一般对话',
          description: '这是一段常规的对话交流'
        };
    }
  };

  const levelConfig = getLevelConfig(insight.insightLevel);
  const LevelIcon = levelConfig.icon;

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-50 flex items-center justify-center p-4"
        >
          {/* 背景遮罩 */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            onClick={onClose}
          />
          
          {/* 弹窗内容 */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            className={`
              relative w-full max-w-md bg-gray-900/95 backdrop-blur-xl 
              rounded-2xl border ${levelConfig.borderColor} 
              shadow-2xl overflow-hidden
            `}
          >
            {/* 头部 */}
            <div className={`${levelConfig.bgColor} px-6 py-4 border-b ${levelConfig.borderColor}`}>
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className={`
                    p-2 rounded-full ${levelConfig.bgColor} 
                    border ${levelConfig.borderColor}
                  `}>
                    <LevelIcon className={`w-5 h-5 ${levelConfig.color}`} />
                  </div>
                  <div>
                    <h3 className={`font-semibold ${levelConfig.color} stellar-title`}>
                      {levelConfig.title}
                    </h3>
                    <p className="text-sm text-gray-400 stellar-body">
                      {levelConfig.description}
                    </p>
                  </div>
                </div>
                <button
                  onClick={onClose}
                  className="p-1 rounded-full hover:bg-gray-700/50 transition-colors"
                >
                  <X className="w-5 h-5 text-gray-400" />
                </button>
              </div>
            </div>
            
            {/* 主要内容 */}
            <div className="p-6 space-y-5">
              {/* 觉察类型 */}
              <div>
                <h4 className="text-sm font-medium text-gray-300 mb-2 stellar-body">
                  觉察类型
                </h4>
                <div className={`
                  inline-flex items-center px-3 py-1 rounded-full text-xs
                  ${levelConfig.bgColor} ${levelConfig.borderColor} border
                  ${levelConfig.color}
                `}>
                  {insight.insightType}
                </div>
              </div>
              
              {/* 关键洞察 */}
              {insight.keyInsights.length > 0 && (
                <div>
                  <h4 className="text-sm font-medium text-gray-300 mb-2 stellar-body">
                    关键洞察
                  </h4>
                  <ul className="space-y-1">
                    {insight.keyInsights.map((insight, index) => (
                      <li key={index} className="text-sm text-gray-200 flex items-start stellar-body">
                        <span className={`inline-block w-1 h-1 rounded-full ${levelConfig.color.replace('text-', 'bg-')} mt-2 mr-2 flex-shrink-0`} />
                        {insight}
                      </li>
                    ))}
                  </ul>
                </div>
              )}
              
              {/* 情绪模式 */}
              {insight.emotionalPattern && (
                <div>
                  <h4 className="text-sm font-medium text-gray-300 mb-2 stellar-body">
                    识别模式
                  </h4>
                  <p className="text-sm text-gray-200 stellar-body">
                    {insight.emotionalPattern}
                  </p>
                </div>
              )}
              
              {/* 建议思考 */}
              {insight.suggestedReflection && (
                <div>
                  <h4 className="text-sm font-medium text-gray-300 mb-2 stellar-body">
                    深入思考
                  </h4>
                  <p className="text-sm text-gray-200 italic stellar-body">
                    {insight.suggestedReflection}
                  </p>
                </div>
              )}
              
              {/* 后续问题 */}
              {insight.followUpQuestions.length > 0 && (
                <div>
                  <h4 className="text-sm font-medium text-gray-300 mb-3 stellar-body">
                    继续探索
                  </h4>
                  <div className="space-y-2">
                    {insight.followUpQuestions.map((question, index) => (
                      <motion.button
                        key={index}
                        whileHover={{ scale: 1.02 }}
                        whileTap={{ scale: 0.98 }}
                        onClick={() => {
                          onAskFollowUp(question);
                          onClose();
                        }}
                        className={`
                          w-full text-left p-3 rounded-lg border
                          ${levelConfig.bgColor} ${levelConfig.borderColor}
                          hover:bg-opacity-20 transition-all duration-200
                          text-sm text-gray-200 stellar-body
                        `}
                      >
                        <MessageCircle className={`w-4 h-4 ${levelConfig.color} inline mr-2`} />
                        {question}
                      </motion.button>
                    ))}
                  </div>
                </div>
              )}
            </div>
            
            {/* 底部提示 */}
            <div className="px-6 py-3 border-t border-gray-700/50 bg-gray-800/30">
              <p className="text-xs text-gray-400 text-center stellar-body">
                点击问题可以继续深入探索
              </p>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};

export default AwarenessDetailModal;