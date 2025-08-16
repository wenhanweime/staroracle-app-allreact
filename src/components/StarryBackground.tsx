import React, { useEffect, useRef, useState } from 'react';

interface StarryBackgroundProps {
  starCount?: number;
}

interface BackgroundStar {
  x: number;
  y: number;
  size: number;
  opacity: number;
  speed: number;
  twinkleSpeed: number;
  twinklePhase: number;
  pulseSize: number;
  pulseSpeed: number;
}

interface Nebula {
  x: number;
  y: number;
  radius: number;
  color: string;
  speed: number;
  pulsePhase: number;
}

const StarryBackground: React.FC<StarryBackgroundProps> = ({ starCount = 200 }) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [mousePos, setMousePos] = useState({ x: 0, y: 0 });
  
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    
    // Set canvas dimensions
    const resizeCanvas = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    };
    
    window.addEventListener('resize', resizeCanvas);
    resizeCanvas();
    
    // Create stars with enhanced properties
    const stars: BackgroundStar[] = Array.from({ length: starCount }).map(() => ({
      x: Math.random() * canvas.width,
      y: Math.random() * canvas.height,
      size: Math.random() * 2 + 0.5, // 恢复原版小星星：0.5-2.5px
      opacity: Math.random() * 0.8 + 0.2, // 恢复原版透明度：0.2-1.0
      speed: Math.random() * 0.05 + 0.01,
      twinkleSpeed: Math.random() * 0.01 + 0.003,
      twinklePhase: Math.random() * Math.PI * 2,
      pulseSize: Math.random() * 0.5 + 0.5,
      pulseSpeed: Math.random() * 0.002 + 0.001,
    }));
    
    // Create nebula clouds with pulsing effect
    const nebulae: Nebula[] = Array.from({ length: 5 }).map(() => ({
      x: Math.random() * canvas.width,
      y: Math.random() * canvas.height,
      radius: Math.random() * 200 + 100,
      color: [
        `rgba(88, 101, 242, ${Math.random() * 0.1 + 0.05})`, // 恢复原版低透明度
        `rgba(93, 71, 119, ${Math.random() * 0.1 + 0.05})`,
        `rgba(44, 83, 100, ${Math.random() * 0.1 + 0.05})`,
      ][Math.floor(Math.random() * 3)],
      speed: Math.random() * 0.02 + 0.005,
      pulsePhase: Math.random() * Math.PI * 2,
    }));
    
    // Mouse move handler for interactive effects
    const handleMouseMove = (e: MouseEvent) => {
      setMousePos({ x: e.clientX, y: e.clientY });
    };
    
    canvas.addEventListener('mousemove', handleMouseMove);
    
    // Animation loop
    let animationFrameId: number;
    
    const render = (time: number) => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      
      // Draw nebulae with pulsing effect
      nebulae.forEach(nebula => {
        const pulseScale = Math.sin(time * 0.001 + nebula.pulsePhase) * 0.2 + 1;
        const currentRadius = nebula.radius * pulseScale;
        
        const gradient = ctx.createRadialGradient(
          nebula.x, nebula.y, 0,
          nebula.x, nebula.y, currentRadius
        );
        
        gradient.addColorStop(0, nebula.color);
        gradient.addColorStop(1, 'rgba(0, 0, 0, 0)');
        
        ctx.fillStyle = gradient;
        ctx.beginPath();
        ctx.arc(nebula.x, nebula.y, currentRadius, 0, Math.PI * 2);
        ctx.fill();
        
        // Move nebula
        nebula.x += Math.sin(time * 0.0001) * nebula.speed;
        nebula.y += Math.cos(time * 0.0001) * nebula.speed;
        
        // Wrap around edges
        if (nebula.x < -currentRadius) nebula.x = canvas.width + currentRadius;
        if (nebula.x > canvas.width + currentRadius) nebula.x = -currentRadius;
        if (nebula.y < -currentRadius) nebula.y = canvas.height + currentRadius;
        if (nebula.y > canvas.height + currentRadius) nebula.y = -currentRadius;
      });
      
      // Draw stars with enhanced effects
      stars.forEach(star => {
        // Calculate distance to mouse for interactive glow
        const dx = mousePos.x - star.x;
        const dy = mousePos.y - star.y;
        const distance = Math.sqrt(dx * dx + dy * dy);
        const mouseInfluence = Math.max(0, 1 - distance / 200);
        
        // Calculate twinkling and pulsing effects
        const twinkle = Math.sin(time * star.twinkleSpeed + star.twinklePhase) * 0.3 + 0.7;
        const pulse = Math.sin(time * star.pulseSpeed) * star.pulseSize + 1;
        
        // Combine all effects for final opacity and size
        const finalOpacity = star.opacity * twinkle * (1 + mouseInfluence * 0.5);
        const finalSize = star.size * pulse * (1 + mouseInfluence);
        
        // Draw star core
        ctx.fillStyle = `rgba(255, 255, 255, ${finalOpacity})`;
        ctx.beginPath();
        ctx.arc(star.x, star.y, finalSize, 0, Math.PI * 2);
        ctx.fill();
        
        // Draw star glow
        if (mouseInfluence > 0) {
          const gradient = ctx.createRadialGradient(
            star.x, star.y, 0,
            star.x, star.y, finalSize * 4
          );
          gradient.addColorStop(0, `rgba(255, 255, 255, ${mouseInfluence * 0.3})`);
          gradient.addColorStop(1, 'rgba(255, 255, 255, 0)');
          
          ctx.fillStyle = gradient;
          ctx.beginPath();
          ctx.arc(star.x, star.y, finalSize * 4, 0, Math.PI * 2);
          ctx.fill();
        }
        
        // Move star
        star.y += star.speed;
        
        // Wrap around bottom edge
        if (star.y > canvas.height) {
          star.y = 0;
          star.x = Math.random() * canvas.width;
        }
      });
      
      animationFrameId = requestAnimationFrame(render);
    };
    
    animationFrameId = requestAnimationFrame(render);
    
    return () => {
      window.removeEventListener('resize', resizeCanvas);
      canvas.removeEventListener('mousemove', handleMouseMove);
      cancelAnimationFrame(animationFrameId);
    };
  }, [starCount]);
  
  return (
    <canvas
      ref={canvasRef}
      className="fixed top-0 left-0 w-full h-full -z-10 pointer-events-none"
    />
  );
};

export default StarryBackground;