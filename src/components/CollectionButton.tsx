import React from 'react';
import { motion } from 'framer-motion';
import { BookOpen, Star } from 'lucide-react';
import { useStarStore } from '../store/useStarStore';

interface CollectionButtonProps {
  onClick: () => void;
}

const CollectionButton: React.FC<CollectionButtonProps> = ({ onClick }) => {
  const { constellation } = useStarStore();
  const starCount = constellation.stars.length;

  const handleClick = () => {
    console.log('🔍 CollectionButton internal click triggered!');
    onClick();
  };

  return (
    <motion.button
      className="collection-trigger-btn"
      onClick={handleClick}
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      initial={{ opacity: 0, x: -20 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ delay: 0.5 }}
    >
      <div className="btn-content">
        <div className="btn-icon">
          <BookOpen className="w-5 h-5" />
          {starCount > 0 && (
            <motion.div
              className="star-count-badge"
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              key={starCount}
            >
              {starCount}
            </motion.div>
          )}
        </div>
        <span className="btn-text">Star Collection</span>
      </div>
      
      {/* Floating stars animation */}
      <div className="floating-stars">
        {Array.from({ length: 3 }).map((_, i) => (
          <motion.div
            key={i}
            className="floating-star"
            animate={{
              y: [-5, -15, -5],
              opacity: [0.3, 0.8, 0.3],
              scale: [0.8, 1.2, 0.8],
            }}
            transition={{
              duration: 2,
              repeat: Infinity,
              delay: i * 0.3,
            }}
          >
            <Star className="w-3 h-3" />
          </motion.div>
        ))}
      </div>
    </motion.button>
  );
};

export default CollectionButton;