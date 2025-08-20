import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { createPortal } from 'react-dom';
import { Star, X, Flame, Mountain, Wind, Waves } from 'lucide-react';
import { getAllTemplates, getTemplatesByElement } from '../utils/constellationTemplates';
import { ConstellationTemplate } from '../types';
import { playSound } from '../utils/soundUtils';
import { getMobileModalStyles, getMobileModalClasses, fixIOSZIndex, createTopLevelContainer, hideOtherElements } from '../utils/mobileUtils';
import StarRayIcon from './StarRayIcon';

interface ConstellationSelectorProps {
  isOpen: boolean;
  onClose: () => void;
  onSelectTemplate: (template: ConstellationTemplate) => void;
}

const ConstellationSelector: React.FC<ConstellationSelectorProps> = ({
  isOpen,
  onClose,
  onSelectTemplate
}) => {
  const [selectedElement, setSelectedElement] = useState<'all' | 'fire' | 'earth' | 'air' | 'water'>('all');
  const [restoreElements, setRestoreElements] = useState<(() => void) | null>(null);
  
  const allTemplates = getAllTemplates();
  const filteredTemplates = selectedElement === 'all' 
    ? allTemplates 
    : getTemplatesByElement(selectedElement);

  // 初始化iOS层级修复
  useEffect(() => {
    fixIOSZIndex();
  }, []);

  // 当模态框打开时隐藏其他元素
  useEffect(() => {
    if (isOpen) {
      document.body.classList.add('modal-open');
      const restore = hideOtherElements();
      setRestoreElements(() => restore);
    } else {
      document.body.classList.remove('modal-open');
      if (restoreElements) {
        restoreElements();
        setRestoreElements(null);
      }
    }
    
    return () => {
      document.body.classList.remove('modal-open');
      if (restoreElements) {
        restoreElements();
      }
    };
  }, [isOpen]);

  const handleClose = () => {
    playSound('starClick');
    onClose();
  };

  const handleSelectTemplate = (template: ConstellationTemplate) => {
    playSound('starReveal');
    onSelectTemplate(template);
    onClose();
  };

  const getElementIcon = (element: string) => {
    switch (element) {
      case 'fire': return <Flame className="w-4 h-4" />;
      case 'earth': return <Mountain className="w-4 h-4" />;
      case 'air': return <Wind className="w-4 h-4" />;
      case 'water': return <Waves className="w-4 h-4" />;
      default: return <Star className="w-4 h-4" />;
    }
  };

  const getElementColor = (element: string) => {
    switch (element) {
      case 'fire': return 'text-red-400 border-red-400';
      case 'earth': return 'text-green-400 border-green-400';
      case 'air': return 'text-blue-400 border-blue-400';
      case 'water': return 'text-cyan-400 border-cyan-400';
      default: return 'text-white border-white';
    }
  };

  return createPortal(
    <AnimatePresence>
      {isOpen && (
        <motion.div
          className={getMobileModalClasses()}
          style={getMobileModalStyles()}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
        >
          <motion.div
            className="absolute inset-0 bg-black bg-opacity-90 backdrop-blur-md"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={handleClose}
          />

          <motion.div
            className="cosmic-input rounded-lg w-full max-w-4xl mx-4 z-10 max-h-[90vh] overflow-hidden"
            initial={{ opacity: 0, y: 20, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.9 }}
            transition={{ type: 'spring', damping: 25 }}
          >
            <div className="p-6">
              {/* Header */}
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-3">
                  <StarRayIcon size={24} className="text-cosmic-accent" animated={true} />
                  <h2 className="stellar-title text-white">选择星座模板</h2>
                </div>
                <button
                  className="w-8 h-8 rounded-full cosmic-button flex items-center justify-center"
                  onClick={handleClose}
                >
                  <X className="w-4 h-4 text-white" />
                </button>
              </div>

              {/* Element Filter */}
              <div className="flex gap-2 mb-6 overflow-x-auto">
                {[
                  { key: 'all', label: '全部', icon: <Star className="w-4 h-4" /> },
                  { key: 'fire', label: '火象', icon: <Flame className="w-4 h-4" /> },
                  { key: 'earth', label: '土象', icon: <Mountain className="w-4 h-4" /> },
                  { key: 'air', label: '风象', icon: <Wind className="w-4 h-4" /> },
                  { key: 'water', label: '水象', icon: <Waves className="w-4 h-4" /> }
                ].map(({ key, label, icon }) => (
                  <button
                    key={key}
                    className={`flex items-center gap-2 px-4 py-2 rounded-full border transition-all ${
                      selectedElement === key
                        ? 'bg-cosmic-accent bg-opacity-20 border-cosmic-accent text-cosmic-accent'
                        : 'cosmic-button text-white'
                    }`}
                    onClick={() => setSelectedElement(key as any)}
                  >
                    {icon}
                    <span className="text-sm font-medium">{label}</span>
                  </button>
                ))}
              </div>

              {/* Templates Grid */}
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 max-h-96 overflow-y-auto">
                <AnimatePresence>
                  {filteredTemplates.map((template, index) => (
                    <motion.div
                      key={template.id}
                      className="constellation-template-card"
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -20 }}
                      transition={{ delay: index * 0.1 }}
                      whileHover={{ y: -5 }}
                      onClick={() => handleSelectTemplate(template)}
                    >
                      {/* Template Preview */}
                      <div className="template-preview">
                        <svg className="w-full h-24" viewBox="0 0 100 60">
                          {/* Draw template stars */}
                          {template.stars.map((star, i) => (
                            <g key={i}>
                              <circle
                                cx={50 + star.x * 2}
                                cy={30 + star.y * 2}
                                r={star.size * 0.8}
                                fill={star.isMainStar ? '#8A5FBD' : '#ffffff'}
                                opacity={star.brightness}
                              />
                              {star.isMainStar && (
                                <circle
                                  cx={50 + star.x * 2}
                                  cy={30 + star.y * 2}
                                  r={star.size * 1.2}
                                  fill="none"
                                  stroke="#8A5FBD"
                                  strokeWidth="0.5"
                                  opacity="0.6"
                                />
                              )}
                            </g>
                          ))}
                          
                          {/* Draw template connections */}
                          {template.connections.map((conn, i) => {
                            const fromStar = template.stars.find(s => s.id === conn.fromStarId);
                            const toStar = template.stars.find(s => s.id === conn.toStarId);
                            if (!fromStar || !toStar) return null;
                            
                            return (
                              <line
                                key={i}
                                x1={50 + fromStar.x * 2}
                                y1={30 + fromStar.y * 2}
                                x2={50 + toStar.x * 2}
                                y2={30 + toStar.y * 2}
                                stroke="rgba(255,255,255,0.3)"
                                strokeWidth="0.5"
                              />
                            );
                          })}
                        </svg>
                      </div>

                      {/* Template Info */}
                      <div className="template-info">
                        <div className="flex items-center justify-between mb-2">
                          <h3 className="font-heading text-white text-lg">{template.chineseName}</h3>
                          <div className={`flex items-center gap-1 px-2 py-1 rounded-full border text-xs ${getElementColor(template.element)}`}>
                            {getElementIcon(template.element)}
                            <span>{template.element}</span>
                          </div>
                        </div>
                        
                        <p className="text-sm text-gray-300 mb-3">{template.description}</p>
                        
                        <div className="flex items-center justify-between text-xs text-gray-400">
                          <span>{template.stars.length} 颗星</span>
                          <span>{template.connections.length} 条连线</span>
                        </div>
                      </div>
                    </motion.div>
                  ))}
                </AnimatePresence>
              </div>

              {/* Info */}
              <div className="mt-6 p-4 bg-cosmic-purple bg-opacity-10 border border-cosmic-purple border-opacity-20 rounded-md">
                <p className="text-sm text-gray-300">
                  <strong>提示:</strong> 选择一个星座模板作为你的星空基础。你可以在此基础上继续添加自己的星星，
                  创造独特的个人星座。模板星星会以特殊样式显示，与你后续添加的星星形成美丽的连接。
                </p>
              </div>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>,
    createTopLevelContainer()
  );
};

export default ConstellationSelector;