import React, { useEffect, useRef, useState } from 'react';

const GalaxySimulator = () => {
  const canvasRef = useRef(null);
  const [isGenerating, setIsGenerating] = useState(false);
  
  // 优化后的参数配置 - 细化旋臂结构
  const [params, setParams] = useState({
    // 核心区参数
    coreDensity: 0.95,
    coreRadius: 45,
    coreSizeMin: 1,
    coreSizeMax: 4,
    
    // 旋臂参数 - 减小宽度，增加层次
    armCount: 2,
    armDensity: 0.4,        // 降低主旋臂密度
    armBaseSizeMin: 0.8,
    armBaseSizeMax: 2,
    armHighlightSize: 6,
    armHighlightProb: 0.008,
    spiralA: 6,
    spiralB: 0.22,
    
    // 旋臂宽度参数 - 显著减小
    armWidthInner: 25,      // 从45减到25
    armWidthOuter: 60,      // 从140减到60
    armWidthGrowth: 1.8,    // 增加增长率，让内部更细
    
    // 新增：分层旋臂系统
    brightRidgeWidth: 8,    // 明亮脊线宽度
    brightRidgeDensity: 0.8, // 脊线密度
    darkLaneWidth: 4,       // 暗尘埃带宽度
    darkLaneOffset: 0.3,    // 尘埃带偏移（相对于旋臂中心）
    
    // 自然淡化参数
    fadeStartRadius: 0.7,   // 开始淡化的半径比例
    fadeEndRadius: 1.2,     // 完全淡化的半径比例
    
    // 旋臂过渡控制
    armTransitionSoftness: 3.0,
    outerDensityMaintain: 0.15, // 降低外围保持密度
    
    // 旋臂间区域填充 - 减少
    interArmDensity: 0.08,
    interArmSizeMin: 0.6,
    interArmSizeMax: 1.5,
    
    // 径向衰减参数
    radialDecay: 0.0012,
    
    // 背景参数
    backgroundDensity: 0.00015,
    backgroundSizeVariation: 2.5
  });
  
  // 计算旋臂宽度（随半径变化，但控制最大宽度）
  const getArmWidth = (radius, maxRadius) => {
    const progress = Math.min(radius / (maxRadius * 0.8), 1); // 限制增长范围
    return params.armWidthInner + (params.armWidthOuter - params.armWidthInner) * Math.pow(progress, params.armWidthGrowth);
  };
  
  // 计算自然淡化因子
  const getFadeFactor = (radius, maxRadius) => {
    const fadeStart = maxRadius * params.fadeStartRadius;
    const fadeEnd = maxRadius * params.fadeEndRadius;
    
    if (radius < fadeStart) return 1.0;
    if (radius > fadeEnd) return 0.0;
    
    // 平滑淡化曲线
    const progress = (radius - fadeStart) / (fadeEnd - fadeStart);
    return Math.pow(1 - progress, 2); // 平滑的二次衰减
  };
  
  // 计算径向密度衰减 - 更自然的衰减
  const getRadialDecay = (radius, maxRadius) => {
    const baseFactor = Math.exp(-radius * params.radialDecay);
    const fadeFactor = getFadeFactor(radius, maxRadius);
    const maintainFactor = params.outerDensityMaintain;
    
    return Math.max(baseFactor * fadeFactor, maintainFactor * fadeFactor);
  };
  
  // 获取旋臂在特定半径和角度的位置
  const getArmPositions = (radius, centerX, centerY) => {
    const positions = [];
    const angle = Math.log(Math.max(radius, params.spiralA) / params.spiralA) / params.spiralB;
    
    for (let arm = 0; arm < params.armCount; arm++) {
      const armOffset = (arm * 2 * Math.PI) / params.armCount;
      const theta = armOffset + angle;
      positions.push({
        x: centerX + radius * Math.cos(theta),
        y: centerY + radius * Math.sin(theta),
        theta: theta,
        armIndex: arm
      });
    }
    
    return positions;
  };
  
  // 计算点到最近旋臂的距离和详细信息
  const getArmInfo = (x, y, centerX, centerY, maxRadius) => {
    const dx = x - centerX;
    const dy = y - centerY;
    const radius = Math.sqrt(dx * dx + dy * dy);
    
    if (radius < 3) return { distance: 0, armIndex: 0, radius: radius, inArm: true };
    
    // 超出淡化范围直接返回
    if (radius > maxRadius * params.fadeEndRadius) {
      return { distance: Infinity, armIndex: 0, radius: radius, inArm: false };
    }
    
    const armPositions = getArmPositions(radius, centerX, centerY);
    let minDistance = Infinity;
    let nearestArmIndex = 0;
    
    armPositions.forEach((pos, index) => {
      const distance = Math.sqrt((x - pos.x) ** 2 + (y - pos.y) ** 2);
      if (distance < minDistance) {
        minDistance = distance;
        nearestArmIndex = index;
      }
    });
    
    const armWidth = getArmWidth(radius, maxRadius);
    const inArm = minDistance < armWidth;
    
    return { 
      distance: minDistance, 
      armIndex: nearestArmIndex, 
      radius: radius, 
      inArm: inArm,
      armWidth: armWidth
    };
  };
  
  // 计算分层旋臂密度
  const getLayeredArmDensity = (armInfo, x, y, centerX, centerY) => {
    const { distance, radius, armWidth } = armInfo;
    const armPositions = getArmPositions(radius, centerX, centerY);
    const nearestArm = armPositions[armInfo.armIndex];
    
    // 计算到旋臂中心线的距离
    const dx = x - nearestArm.x;
    const dy = y - nearestArm.y;
    const distanceToCenter = Math.sqrt(dx * dx + dy * dy);
    
    let totalDensity = 0;
    let size = params.armBaseSizeMin + Math.random() * (params.armBaseSizeMax - params.armBaseSizeMin);
    
    // 1. 明亮脊线 - 旋臂中心的高亮带
    if (distanceToCenter < params.brightRidgeWidth) {
      const ridgeProfile = Math.exp(-Math.pow(distanceToCenter / (params.brightRidgeWidth * 0.4), 2));
      totalDensity += params.brightRidgeDensity * ridgeProfile;
      
      if (ridgeProfile > 0.5 && Math.random() < params.armHighlightProb) {
        size = params.armHighlightSize + Math.random() * 2;
      }
    }
    
    // 2. 主旋臂结构 - 基础密度分布
    const armProfile = Math.exp(-0.5 * Math.pow(distance / (armWidth / params.armTransitionSoftness), 2));
    totalDensity += params.armDensity * armProfile;
    
    // 3. 暗尘埃带 - 在旋臂内部创造暗纹理
    const darkLaneCenter = params.darkLaneOffset * armWidth;
    const distanceToDarkLane = Math.abs(distanceToCenter - darkLaneCenter);
    if (distanceToDarkLane < params.darkLaneWidth) {
      const darkProfile = Math.exp(-Math.pow(distanceToDarkLane / (params.darkLaneWidth * 0.5), 2));
      totalDensity *= (1 - 0.6 * darkProfile); // 减少60%的密度
    }
    
    return { density: totalDensity, size: size };
  };
  
  // 生成银河系
  const generateGalaxy = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;
    const centerX = width / 2;
    const centerY = height / 2;
    const maxRadius = Math.min(width, height) * 0.4; // 减小基础范围
    const extendedRadius = maxRadius * params.fadeEndRadius; // 扩展淡化范围
    
    setIsGenerating(true);
    
    // 清空画布
    ctx.fillStyle = '#000000';
    ctx.fillRect(0, 0, width, height);
    ctx.fillStyle = '#FFFFFF';
    
    // 1. 绘制背景星空
    const backgroundStars = width * height * params.backgroundDensity;
    for (let i = 0; i < backgroundStars; i++) {
      const x = Math.random() * width;
      const y = Math.random() * height;
      
      let size;
      const rand = Math.random();
      if (rand < 0.85) size = 0.8;
      else if (rand < 0.97) size = 1.2;
      else size = params.backgroundSizeVariation;
      
      ctx.beginPath();
      ctx.arc(x, y, size, 0, 2 * Math.PI);
      ctx.fill();
    }
    
    // 2. 使用网格法绘制银河系 - 扩展到淡化范围
    const step = 1.1;
    for (let x = 0; x < width; x += step) {
      for (let y = 0; y < height; y += step) {
        const dx = x - centerX;
        const dy = y - centerY;
        const radius = Math.sqrt(dx * dx + dy * dy);
        
        if (radius > extendedRadius || radius < 3) continue;
        
        const radialDecay = getRadialDecay(radius, maxRadius);
        let density = 0;
        let size = 1;
        
        // 检查是否在核心区域
        if (radius < params.coreRadius) {
          const coreProfile = Math.exp(-Math.pow(radius / params.coreRadius, 1.5));
          density = params.coreDensity * coreProfile * radialDecay;
          size = params.coreSizeMin + Math.random() * (params.coreSizeMax - params.coreSizeMin);
        } else {
          // 获取旋臂信息
          const armInfo = getArmInfo(x, y, centerX, centerY, maxRadius);
          
          if (armInfo.inArm) {
            // 在旋臂区域内 - 使用分层密度系统
            const layeredResult = getLayeredArmDensity(armInfo, x, y, centerX, centerY);
            density = layeredResult.density * radialDecay;
            size = layeredResult.size;
          } else {
            // 在旋臂间区域
            const interArmFactor = Math.exp(-(armInfo.distance - armInfo.armWidth) * 0.02);
            density = params.interArmDensity * interArmFactor * radialDecay;
            size = params.interArmSizeMin + Math.random() * (params.interArmSizeMax - params.interArmSizeMin);
          }
        }
        
        // 添加随机性，避免过于规整
        const randomFactor = 0.7 + Math.random() * 0.6;
        density *= randomFactor;
        
        if (Math.random() < density) {
          // 添加位置的微小随机偏移
          const offsetX = x + (Math.random() - 0.5) * step;
          const offsetY = y + (Math.random() - 0.5) * step;
          
          ctx.beginPath();
          ctx.arc(offsetX, offsetY, size, 0, 2 * Math.PI);
          ctx.fill();
        }
      }
    }
    
    // 3. 增强旋臂的明亮脊线（额外绘制）
    for (let r = params.spiralA; r < maxRadius * params.fadeStartRadius; r += 1.8) {
      const armPositions = getArmPositions(r, centerX, centerY);
      
      armPositions.forEach(pos => {
        if (pos.x < 0 || pos.x > width || pos.y < 0 || pos.y > height) return;
        
        const radialDecay = getRadialDecay(r, maxRadius);
        const brightnessFactor = 0.2 * radialDecay;
        
        if (Math.random() < brightnessFactor) {
          const size = 1.5 + Math.random() * 3;
          ctx.beginPath();
          ctx.arc(pos.x, pos.y, size, 0, 2 * Math.PI);
          ctx.fill();
        }
      });
    }
    
    setIsGenerating(false);
  };
  
  useEffect(() => {
    generateGalaxy();
  }, []);
  
  const handleParamChange = (param, value) => {
    setParams(prev => ({
      ...prev,
      [param]: parseFloat(value)
    }));
  };
  
  return (
    <div className="min-h-screen bg-gray-900 text-white p-6">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold mb-6 text-center">银河系极简模拟器 v4.0</h1>
        <p className="text-gray-300 mb-8 text-center max-w-3xl mx-auto">
          精细化版本：细化旋臂、分层结构、自然淡化边缘
        </p>
        
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
          {/* 控制面板 */}
          <div className="bg-gray-800 p-4 rounded-lg overflow-y-auto max-h-[500px]">
            <h2 className="text-xl font-semibold mb-4">参数控制</h2>
            
            <div className="space-y-3 text-xs">
              <div>
                <h3 className="text-sm font-medium mb-2 text-yellow-400">星系核心</h3>
                <div className="space-y-1">
                  <label className="block">
                    核心密度: {params.coreDensity.toFixed(2)}
                    <input
                      type="range"
                      min="0.5"
                      max="1"
                      step="0.05"
                      value={params.coreDensity}
                      onChange={(e) => handleParamChange('coreDensity', e.target.value)}
                      className="w-full"
                    />
                  </label>
                  <label className="block">
                    核心半径: {params.coreRadius}
                    <input
                      type="range"
                      min="25"
                      max="70"
                      step="5"
                      value={params.coreRadius}
                      onChange={(e) => handleParamChange('coreRadius', e.target.value)}
                      className="w-full"
                    />
                  </label>
                </div>
              </div>
              
              <div>
                <h3 className="text-sm font-medium mb-2 text-blue-400">旋臂基础</h3>
                <div className="space-y-1">
                  <label className="block">
                    旋臂数量: {params.armCount}
                    <input
                      type="range"
                      min="2"
                      max="6"
                      step="1"
                      value={params.armCount}
                      onChange={(e) => handleParamChange('armCount', e.target.value)}
                      className="w-full"
                    />
                  </label>
                  <label className="block">
                    旋臂密度: {params.armDensity.toFixed(2)}
                    <input
                      type="range"
                      min="0.2"
                      max="0.6"
                      step="0.05"
                      value={params.armDensity}
                      onChange={(e) => handleParamChange('armDensity', e.target.value)}
                      className="w-full"
                    />
                  </label>
                  <label className="block">
                    螺旋紧密度: {params.spiralB.toFixed(2)}
                    <input
                      type="range"
                      min="0.15"
                      max="0.35"
                      step="0.02"
                      value={params.spiralB}
                      onChange={(e) => handleParamChange('spiralB', e.target.value)}
                      className="w-full"
                    />
                  </label>
                </div>
              </div>
              
              <div>
                <h3 className="text-sm font-medium mb-2 text-green-400">旋臂宽度（精细化）</h3>
                <div className="space-y-1">
                  <label className="block">
                    内侧宽度: {params.armWidthInner}
                    <input
                      type="range"
                      min="15"
                      max="40"
                      step="2"
                      value={params.armWidthInner}
                      onChange={(e) => handleParamChange('armWidthInner', e.target.value)}
                      className="w-full"
                    />
                  </label>
                  <label className="block">
                    外侧宽度: {params.armWidthOuter}
                    <input
                      type="range"
                      min="40"
                      max="100"
                      step="5"
                      value={params.armWidthOuter}
                      onChange={(e) => handleParamChange('armWidthOuter', e.target.value)}
                      className="w-full"
                    />
                  </label>
                  <label className="block">
                    宽度增长: {params.armWidthGrowth.toFixed(1)}
                    <input
                      type="range"
                      min="1.2"
                      max="2.5"
                      step="0.1"
                      value={params.armWidthGrowth}
                      onChange={(e) => handleParamChange('armWidthGrowth', e.target.value)}
                      className="w-full"
                    />
                  </label>
                </div>
              </div>
              
              <div>
                <h3 className="text-sm font-medium mb-2 text-purple-400">分层结构（新功能）</h3>
                <div className="space-y-1">
                  <label className="block">
                    明亮脊线宽度: {params.brightRidgeWidth}
                    <input
                      type="range"
                      min="4"
                      max="15"
                      step="1"
                      value={params.brightRidgeWidth}
                      onChange={(e) => handleParamChange('brightRidgeWidth', e.target.value)}
                      className="w-full"
                    />
                  </label>
                  <label className="block">
                    脊线密度: {params.brightRidgeDensity.toFixed(2)}
                    <input
                      type="range"
                      min="0.4"
                      max="1.0"
                      step="0.05"
                      value={params.brightRidgeDensity}
                      onChange={(e) => handleParamChange('brightRidgeDensity', e.target.value)}
                      className="w-full"
                    />
                  </label>
                  <label className="block">
                    暗尘埃带宽度: {params.darkLaneWidth}
                    <input
                      type="range"
                      min="2"
                      max="8"
                      step="1"
                      value={params.darkLaneWidth}
                      onChange={(e) => handleParamChange('darkLaneWidth', e.target.value)}
                      className="w-full"
                    />
                  </label>
                </div>
              </div>
              
              <div>
                <h3 className="text-sm font-medium mb-2 text-orange-400">自然淡化（新功能）</h3>
                <div className="space-y-1">
                  <label className="block">
                    淡化起始: {params.fadeStartRadius.toFixed(1)}
                    <input
                      type="range"
                      min="0.5"
                      max="0.9"
                      step="0.05"
                      value={params.fadeStartRadius}
                      onChange={(e) => handleParamChange('fadeStartRadius', e.target.value)}
                      className="w-full"
                    />
                  </label>
                  <label className="block">
                    淡化结束: {params.fadeEndRadius.toFixed(1)}
                    <input
                      type="range"
                      min="1.0"
                      max="1.5"
                      step="0.05"
                      value={params.fadeEndRadius}
                      onChange={(e) => handleParamChange('fadeEndRadius', e.target.value)}
                      className="w-full"
                    />
                  </label>
                </div>
              </div>
              
              <div>
                <h3 className="text-sm font-medium mb-2 text-cyan-400">其他设置</h3>
                <div className="space-y-1">
                  <label className="block">
                    过渡柔和度: {params.armTransitionSoftness.toFixed(1)}
                    <input
                      type="range"
                      min="2.0"
                      max="4.5"
                      step="0.1"
                      value={params.armTransitionSoftness}
                      onChange={(e) => handleParamChange('armTransitionSoftness', e.target.value)}
                      className="w-full"
                    />
                  </label>
                  <label className="block">
                    旋臂间密度: {params.interArmDensity.toFixed(2)}
                    <input
                      type="range"
                      min="0.02"
                      max="0.15"
                      step="0.01"
                      value={params.interArmDensity}
                      onChange={(e) => handleParamChange('interArmDensity', e.target.value)}
                      className="w-full"
                    />
                  </label>
                </div>
              </div>
              
              <button
                onClick={generateGalaxy}
                disabled={isGenerating}
                className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-gray-600 px-3 py-2 rounded transition-colors mt-4"
              >
                {isGenerating ? '生成中...' : '重新生成银河系'}
              </button>
            </div>
          </div>
          
          {/* 画布区域 */}
          <div className="lg:col-span-3">
            <div className="bg-black rounded-lg overflow-hidden">
              <canvas
                ref={canvasRef}
                width={800}
                height={600}
                className="w-full h-auto border border-gray-700"
              />
            </div>
            
            <div className="mt-4 text-sm text-gray-400">
              <h3 className="font-medium mb-2">v4.0 精细化特性：</h3>
              <ul className="space-y-1">
                <li>• <span className="text-green-400">细化旋臂</span>：宽度大幅减小（25-60px），避免过粗问题</li>
                <li>• <span className="text-purple-400">明亮脊线</span>：旋臂中心的高亮带，模拟恒星密集区</li>
                <li>• <span className="text-purple-400">暗尘埃带</span>：旋臂内部暗纹理，增加真实感</li>
                <li>• <span className="text-orange-400">自然淡化</span>：移除硬边界，旋臂末尾平滑消散</li>
                <li>• <span className="text-blue-400">三层密度</span>：脊线+主臂+尘埃带的复合结构</li>
                <li>• <span className="text-cyan-400">渐进衰减</span>：外围密度平滑过渡到零</li>
                <li>• 分离宽度控制，防止外围过度扩张</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default GalaxySimulator;