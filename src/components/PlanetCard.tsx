import React, { useEffect, useRef } from 'react';
import { PlanetRecord } from '@/types';
import { drawPlanetScene } from '@/utils/planetGenerator';

const regionLabelMap: Record<string, string> = {
  emotion: '情绪星带',
  relation: '关系轨道',
  growth: '成长区域'
};

const variantLabelMap: Record<PlanetRecord['variant'], string> = {
  gas: '气态巨行星',
  ocean: '海洋星球',
  lava: '熔岩行星',
  ice: '冰晶行星',
  desert: '荒漠行星'
};

interface PlanetCardProps {
  planet: PlanetRecord;
}

const PlanetCard: React.FC<PlanetCardProps> = ({ planet }) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    if (!canvasRef.current) return;
    drawPlanetScene(canvasRef.current, planet);
  }, [planet]);

  const regionLabel = planet.region ? regionLabelMap[planet.region] : '星际随机';
  const variantLabel = variantLabelMap[planet.variant];
  const createdAt = new Date(planet.createdAt);
  const timestamp = createdAt.toLocaleString('zh-CN', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });

  return (
    <div className="rounded-3xl bg-gradient-to-br from-black/60 via-indigo-900/30 to-black/70 border border-white/10 shadow-xl overflow-hidden flex flex-col">
      <div className="p-4 pb-0">
        <canvas
          ref={canvasRef}
          width={220}
          height={220}
          className="w-full aspect-square rounded-2xl bg-[#05030b]"
        />
      </div>
      <div className="px-4 py-3 text-white/90">
        <div className="flex items-center justify-between text-xs uppercase tracking-widest text-white/60 mb-1">
          <span>{regionLabel}</span>
          <span>{timestamp}</span>
        </div>
        <div className="text-base font-semibold text-white">{variantLabel}</div>
      </div>
    </div>
  );
};

export default PlanetCard;
