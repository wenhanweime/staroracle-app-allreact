import React from 'react';
import { motion } from 'framer-motion';
import { Star } from 'lucide-react';
import { useStarStore } from '../store/useStarStore';
import StarRayIcon from './StarRayIcon';

interface TemplateButtonProps {
  onClick: () => void;
}

const TemplateButton: React.FC<TemplateButtonProps> = ({ onClick }) => {
  const { hasTemplate, templateInfo } = useStarStore();

  const handleClick = () => {
    onClick();
  };

  return (
    <motion.button
      className="template-trigger-btn"
      onClick={handleClick}
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ delay: 0.5 }}
    >
      <div className="btn-content">
        <div className="btn-icon">
          <StarRayIcon size={20} animated={false} />
          {hasTemplate && (
            <motion.div
              className="template-badge"
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
            >
              ✨
            </motion.div>
          )}
        </div>
        <div className="btn-text-container">
          <span className="btn-text">
            {hasTemplate ? '更换星座' : '选择星座'}
          </span>
          {hasTemplate && templateInfo && (
            <span className="template-name">
              {templateInfo.name}
            </span>
          )}
        </div>
      </div>
      
      {/* Floating stars animation */}
      <div className="floating-stars">
        {Array.from({ length: 4 }).map((_, i) => (
          <motion.div
            key={i}
            className="floating-star"
            animate={{
              y: [-5, -15, -5],
              opacity: [0.3, 0.8, 0.3],
              scale: [0.8, 1.2, 0.8],
            }}
            transition={{
              duration: 2.5,
              repeat: Infinity,
              delay: i * 0.4,
            }}
          >
            <Star className="w-3 h-3" />
          </motion.div>
        ))}
      </div>
    </motion.button>
  );
};

export default TemplateButton;