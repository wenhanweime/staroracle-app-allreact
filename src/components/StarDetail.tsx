import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { createPortal } from 'react-dom';
import { X, Share2, Save, Tag, Heart } from 'lucide-react';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import StarRayIcon from './StarRayIcon';
import { getMainTagSuggestions } from '../utils/aiTaggingUtils';

const StarDetail: React.FC = () => {
  const { 
    constellation, 
    activeStarId, 
    hideStarDetail,
    updateStarTags
  } = useStarStore();
  
  const activeStar = constellation.stars.find(star => star.id === activeStarId);

  const [editingTags, setEditingTags] = useState(false);
  const [currentTags, setCurrentTags] = useState<string[]>([]);
  const [newTag, setNewTag] = useState('');
  const [tagSuggestions, setTagSuggestions] = useState<string[]>([]);
  
  const handleClose = () => {
    playSound('starClick');
    hideStarDetail();
  };
  
  const handleShare = () => {
    playSound('starClick');
    // TODO: 实现分享功能
    console.log('分享功能将在这里实现');
  };
  
  const handleSave = () => {
    playSound('starClick');
    // TODO: 实现保存到星图功能
    console.log('保存到星图功能将在这里实现');
  };
  
  // 开始编辑标签时初始化
  const startEditingTags = () => {
    if (activeStar) {
      setCurrentTags([...activeStar.tags]);
      setEditingTags(true);
      // 根据预定义的标签系统加载建议
      setTagSuggestions(getMainTagSuggestions());
    }
  };
  
  // 保存编辑后的标签
  const saveTagChanges = () => {
    if (activeStar) {
      updateStarTags(activeStar.id, currentTags);
      setEditingTags(false);
    }
  };
  
  // 添加新标签
  const addTag = (tag: string) => {
    const normalizedTag = tag.trim().toLowerCase();
    if (normalizedTag && !currentTags.some(t => t.toLowerCase() === normalizedTag)) {
      setCurrentTags([...currentTags, normalizedTag]);
      setNewTag('');
    }
  };
  
  // 移除标签
  const removeTag = (tagToRemove: string) => {
    setCurrentTags(currentTags.filter(tag => tag !== tagToRemove));
  };
  
  // 用户输入时筛选建议
  const filterSuggestions = (input: string) => {
    const filtered = getMainTagSuggestions().filter(
      tag => tag.toLowerCase().includes(input.toLowerCase())
    );
    setTagSuggestions(filtered.slice(0, 10)); // 限制为10个建议
  };
  
  // 处理新标签输入变化
  const handleTagInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setNewTag(value);
    filterSuggestions(value);
  };
  
  const getCategoryColor = (category: string) => {
    const colors = {
      'relationships': '#FF69B4',
      'personal_growth': '#9370DB',
      'career_and_purpose': '#FFD700',  // 从'life_direction'更新
      'emotional_wellbeing': '#98FB98', // 从'wellbeing'更新
      'material': '#FFA500',
      'creative': '#FF6347',
      'philosophy_and_existence': '#87CEEB', // 从'existential'更新
      'creativity_and_passion': '#FF6347', // 添加新类别
      'daily_life': '#FFA500', // 添加新类别
    };
    return colors[category as keyof typeof colors] || '#fff';
  };
  
  if (!activeStar) return null;
  
  // 查找相连的星星
  const connectedStars = constellation.connections
    .filter(conn => conn.fromStarId === activeStarId || conn.toStarId === activeStarId)
    .map(conn => {
      const connectedStarId = conn.fromStarId === activeStarId ? conn.toStarId : conn.fromStarId;
      const connectedStar = constellation.stars.find(s => s.id === connectedStarId);
      return { star: connectedStar, connection: conn };
    })
    .filter(item => item.star);
  
  return createPortal(
    <AnimatePresence>
      {activeStarId && activeStar && (
        <motion.div
          className="fixed inset-0 flex items-center justify-center"
          style={{ zIndex: 999999 }}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
        >
          <motion.div
            className="absolute inset-0 bg-black bg-opacity-10 backdrop-blur-sm"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={handleClose}
          />
          
          <motion.div
            className="oracle-card rounded-lg w-full max-w-lg mx-4 overflow-hidden z-10"
            initial={{ opacity: 0, y: 20, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.9 }}
            transition={{ type: 'spring', damping: 25 }}
          >
            {/* 星星图像 */}
            <div className="relative">
              <img
                src={activeStar.imageUrl}
                alt="宇宙视觉"
                className="w-full h-48 object-cover"
              />
              
              {/* 关闭按钮 */}
              <button 
                className="absolute top-2 right-2 bg-black bg-opacity-50 rounded-full p-1"
                onClick={handleClose}
              >
                <X className="w-5 h-5 text-white" />
              </button>
              
              {/* 类别标签 */}
              <div 
                className="absolute top-2 left-2 rounded-full px-3 py-1 text-xs font-semibold"
                style={{ 
                  backgroundColor: `${getCategoryColor(activeStar.primary_category)}20`,
                  border: `1px solid ${getCategoryColor(activeStar.primary_category)}60`,
                  color: getCategoryColor(activeStar.primary_category)
                }}
              >
                {activeStar.primary_category.replace('_', ' ').toUpperCase()}
              </div>
              
              {/* 特殊星星指示器 */}
              {activeStar.isSpecial && (
                <div className="absolute top-2 right-12 bg-cosmic-purple bg-opacity-70 rounded-full px-2 py-1 text-xs">
                  ✨ 稀有天体事件
                </div>
              )}
            </div>
            
            <div className="p-6">
              {/* 问题 */}
              <h3 className="text-lg text-gray-300 mb-2 italic">
                "{activeStar.question}"
              </h3>
              
              {/* 神谕回应 */}
              <p className="text-xl font-heading text-white mb-4">
                {activeStar.answer}
              </p>
              
              {/* 标签部分 */}
              <div className="mb-4">
                <div className="flex items-center gap-2 mb-2">
                  <Tag className="w-4 h-4 text-cosmic-accent" />
                  <span className="text-sm font-semibold text-cosmic-accent">主题</span>
                  
                  {!editingTags && (
                    <button 
                      className="ml-auto text-blue-400 hover:text-blue-300 text-sm"
                      onClick={startEditingTags}
                    >
                      编辑标签
                    </button>
                  )}
                </div>
                
                {!editingTags ? (
                  <div className="flex flex-wrap gap-2">
                    {activeStar.tags.map(tag => (
                      <span
                        key={tag}
                        className="px-2 py-1 bg-cosmic-purple bg-opacity-20 border border-cosmic-purple border-opacity-30 rounded-full text-xs text-white"
                      >
                        {tag}
                      </span>
                    ))}
                  </div>
                ) : (
                  <div>
                    <div className="flex flex-wrap gap-2 mb-3">
                      {currentTags.map(tag => (
                        <div key={tag} className="bg-blue-900 bg-opacity-40 rounded-full px-3 py-1 text-sm flex items-center">
                          <span className="text-blue-300">{tag}</span>
                          <button 
                            className="ml-2 text-gray-400 hover:text-white"
                            onClick={() => removeTag(tag)}
                          >
                            &times;
                          </button>
                        </div>
                      ))}
                      {currentTags.length === 0 && (
                        <span className="text-gray-500 text-sm italic">添加标签以创建星座</span>
                      )}
                    </div>
                    
                    <div className="flex mb-3">
                      <input
                        type="text"
                        value={newTag}
                        onChange={handleTagInputChange}
                        placeholder="添加新标签..."
                        className="flex-grow bg-gray-800 text-white px-3 py-2 rounded-l-md focus:outline-none focus:ring-1 focus:ring-blue-500"
                      />
                      <button 
                        onClick={() => addTag(newTag)}
                        className="bg-blue-700 hover:bg-blue-600 text-white px-3 py-1 rounded-r-md"
                      >
                        添加
                      </button>
                    </div>
                    
                    {tagSuggestions.length > 0 && (
                      <div className="bg-gray-800 rounded-md p-2 mb-3">
                        <p className="text-gray-400 text-xs mb-2">推荐标签：</p>
                        <div className="flex flex-wrap gap-2">
                          {tagSuggestions.map(suggestion => (
                            <button
                              key={suggestion}
                              onClick={() => addTag(suggestion)}
                              disabled={currentTags.some(t => t.toLowerCase() === suggestion.toLowerCase())}
                              className={`text-xs px-2 py-1 rounded-full ${
                                currentTags.some(t => t.toLowerCase() === suggestion.toLowerCase())
                                  ? 'bg-gray-700 text-gray-500 cursor-not-allowed'
                                  : 'bg-gray-700 hover:bg-gray-600 text-white'
                              }`}
                            >
                              {suggestion}
                            </button>
                          ))}
                        </div>
                      </div>
                    )}
                    
                    <div className="flex justify-end gap-2">
                      <button 
                        onClick={() => setEditingTags(false)}
                        className="bg-gray-700 hover:bg-gray-600 text-white px-3 py-1 rounded-md"
                      >
                        取消
                      </button>
                      <button 
                        onClick={saveTagChanges}
                        className="bg-green-700 hover:bg-green-600 text-white px-3 py-1 rounded-md"
                      >
                        保存更改
                      </button>
                    </div>
                  </div>
                )}
              </div>
              
              {/* 相连的星星 */}
              {connectedStars.length > 0 && (
                <div className="mb-4">
                  <div className="flex items-center gap-2 mb-2">
                    <StarRayIcon size={16} />
                    <span className="text-sm font-semibold text-cosmic-accent">相连的星星</span>
                  </div>
                  <div className="space-y-2">
                    {connectedStars.slice(0, 3).map(({ star, connection }) => (
                      <div 
                        key={star!.id}
                        className="flex items-center justify-between p-2 bg-cosmic-navy bg-opacity-30 rounded-md"
                      >
                        <div className="flex-1">
                          <p className="text-sm text-white truncate">"{star!.question}"</p>
                          <p className="text-xs text-gray-400">
                            共享：{connection.sharedTags?.join('、') || '相似能量'}
                          </p>
                        </div>
                        <div className="text-xs text-cosmic-accent font-semibold">
                          {Math.round(connection.strength * 100)}%
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
              
              {/* 情感基调 */}
              <div className="mb-4">
                <div className="flex items-center gap-2 mb-1">
                  <Heart className="w-4 h-4 text-cosmic-accent" />
                  <span className="text-sm font-semibold text-cosmic-accent">情感基调</span>
                </div>
                <span className="text-sm text-gray-300 capitalize">
                  {activeStar.emotional_tone && activeStar.emotional_tone.length > 0 
                    ? activeStar.emotional_tone.join('、') 
                    : '中性'}
                </span>
              </div>
              
              {/* 日期 */}
              <p className="text-sm text-gray-400 mb-4">
                照亮于 {activeStar.createdAt.toLocaleDateString(undefined, { 
                  year: 'numeric', 
                  month: 'long', 
                  day: 'numeric' 
                })}
              </p>
              
              {/* 操作按钮 */}
              <div className="flex justify-between">
                <button
                  className="cosmic-button rounded-md px-3 py-2 flex items-center"
                  onClick={handleSave}
                >
                  <Save className="w-4 h-4 mr-2" />
                  <span>保存到星图</span>
                </button>
                
                <button
                  className="cosmic-button rounded-md px-3 py-2 flex items-center"
                  onClick={handleShare}
                >
                  <Share2 className="w-4 h-4 mr-2" />
                  <span>分享星语</span>
                </button>
              </div>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>,
    document.body
  );
};

export default StarDetail;
