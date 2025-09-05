import React, { useEffect, useRef, useState } from 'react';
import { createNoise2D } from 'simplex-noise'; // 引入噪声库

// 创建一个带种子的噪声实例，确保每次刷新效果一致，便于调试
const noise2D = createNoise2D(() => 0.5); // 固定种子

const GalaxySimulator = () => {
  const canvasRef = useRef(null);
  const [isGenerating, setIsGenerating] = useState(false);
  const [savedConfigs, setSavedConfigs] = useState([]); // 新增：保存的配置列表
  const [configName, setConfigName] = useState(''); // 新增：配置名称输入
  
  // 单一连续密度剖面模型 - 用户定制的默认参数配置
  const [params, setParams] = useState({
    // 星系核心
    coreDensity: 0.70,      // 核心密度
    coreRadius: 25,         // 核心半径
    coreSizeMin: 1,
    coreSizeMax: 3.5,
    
    // 旋臂基础
    armCount: 5,            // 旋臂数量
    armDensity: 0.60,       // 旋臂密度
    armBaseSizeMin: 0.7,
    armBaseSizeMax: 2.0,
    armHighlightSize: 5,
    armHighlightProb: 0.01,
    spiralA: 8,
    spiralB: 0.29,          // 螺旋紧密度
    
    // 旋臂宽度（精细化）
    armWidthInner: 29,      // 内侧宽度
    armWidthOuter: 65,      // 外侧宽度
    armWidthGrowth: 2.5,    // 宽度增长
    
    // 平滑过渡控制
    armTransitionSoftness: 5.2, // 山坡平缓度
    
    // 自然淡化参数
    fadeStartRadius: 0.5,   // 淡化起始
    fadeEndRadius: 1.3,     // 淡化结束
    outerDensityMaintain: 0.1,
    
    // 旋臂密度剖面（核心）
    interArmDensity: 0.150, // 臂间基础密度
    interArmSizeMin: 0.6,
    interArmSizeMax: 1.2,
    
    // 径向衰减参数
    radialDecay: 0.0015,
    
    // 背景星空
    backgroundDensity: 0.00024, // 背景密度
    backgroundSizeVariation: 2.0,
    
    // 【新增】破碎飘带效果参数
    jitterStrength: 10,           // 垂直抖动强度 (用户定制值)
    densityNoiseScale: 0.018,     // 密度噪声的缩放（团块大小）
    densityNoiseStrength: 0.8,    // 密度噪声的影响强度 (用户定制值)
    
    // 【修改】星星大小独立调节
    armStarSizeMultiplier: 1.0,         // 新增：旋臂星星大小倍数
    interArmStarSizeMultiplier: 1.0,    // 新增：臂间星星大小倍数
    backgroundStarSizeMultiplier: 1.0,  // 背景星星大小倍数
  });
  
  // 计算旋臂宽度（随半径变化，但控制最大宽度）
  const getArmWidth = (radius, maxRadius) => {
    const progress = Math.min(radius / (maxRadius * 0.8), 1); // 限制增长范围
    return params.armWidthInner + (params.armWidthOuter - params.armWidthInner) * Math.pow(progress, params.armWidthGrowth);
  };
  
  // 计算自然淡化因子 - 【修改】使用更平滑的曲线
  const getFadeFactor = (radius, maxRadius) => {
    const fadeStart = maxRadius * params.fadeStartRadius;
    const fadeEnd = maxRadius * params.fadeEndRadius;
    
    if (radius < fadeStart) return 1.0;
    if (radius > fadeEnd) return 0.0;
    
    const progress = (radius - fadeStart) / (fadeEnd - fadeStart);
    // MODIFICATION: 使用余弦插值，提供更平滑的开始和结束
    return 0.5 * (1 + Math.cos(progress * Math.PI));
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
    
    if (radius < 3) return { distance: 0, armIndex: 0, radius: radius, inArm: true, armWidth: 0, theta: 0 };
    
    // 【重要】移除硬判断 - 让getRadialDecay完全控制衰减
    /*
    if (radius > maxRadius * params.fadeEndRadius) {
      return { distance: Infinity, armIndex: 0, radius: radius, inArm: false };
    }
    */
    
    const armPositions = getArmPositions(radius, centerX, centerY);
    let minDistance = Infinity;
    let nearestArmIndex = 0;
    let nearestArmTheta = 0; // 【新增】记录最近旋臂的角度
    
    armPositions.forEach((pos, index) => {
      const distance = Math.sqrt((x - pos.x) ** 2 + (y - pos.y) ** 2);
      if (distance < minDistance) {
        minDistance = distance;
        nearestArmIndex = index;
        nearestArmTheta = pos.theta; // 【新增】记录角度
      }
    });
    
    const armWidth = getArmWidth(radius, maxRadius);
    const inArm = minDistance < armWidth;
    
    return { 
      distance: minDistance, 
      armIndex: nearestArmIndex, 
      radius: radius, 
      inArm: inArm,
      armWidth: armWidth,
      theta: nearestArmTheta // 【新增】返回角度
    };
  };
  
  // 新的单一剖面密度计算函数 - 旋臂作为平滑"山脉"
  const calculateArmDensityProfile = (armInfo) => {
    const { distance, armWidth } = armInfo;

    // 1. 计算单一、平滑的旋臂密度剖面（高斯曲线）
    //    这个剖面值在旋臂中心为1，向外平滑衰减到0
    const profile = Math.exp(-0.5 * Math.pow(distance / (armWidth / params.armTransitionSoftness), 2));

    // 2. 最终密度 = 基础臂间密度 + 旋臂剖面带来的额外密度
    const totalDensity = params.interArmDensity + params.armDensity * profile;

    // 3. 星点大小和密度剖面关联，模拟亮星集中在中心区域
    let size; // 先声明变量

    if (profile > 0.1) { // 判断为在旋臂上
      size = params.armBaseSizeMin + (params.armBaseSizeMax - params.armBaseSizeMin) * profile;
      if (profile > 0.7 && Math.random() < params.armHighlightProb) {
        size = params.armHighlightSize;
      }
      // 只对旋臂星星应用其专属倍数
      size *= params.armStarSizeMultiplier; 
    } else { // 判断为在臂间
      // 使用臂间的基础大小范围
      size = params.interArmSizeMin + (params.interArmSizeMax - params.interArmSizeMin) * Math.random();
      // 只对臂间星星应用其专属倍数
      size *= params.interArmStarSizeMultiplier;
    }

    return { density: totalDensity, size: size, profile: profile }; // 【修改】返回 profile
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
      
      // 【修改】应用背景星星独立大小调节
      size *= params.backgroundStarSizeMultiplier;
      
      ctx.beginPath();
      ctx.arc(x, y, size, 0, 2 * Math.PI);
      ctx.fill();
    }
    
    // 2. 使用网格法绘制银河系 - 【修正】让循环覆盖整个画布
    const step = 1.1;
    for (let x = 0; x < width; x += step) {
      for (let y = 0; y < height; y += step) {
        const dx = x - centerX;
        const dy = y - centerY;
        const radius = Math.sqrt(dx * dx + dy * dy);
        
        // 【修正】只保留一个最小半径的判断，彻底移除半径上限
        if (radius < 3) continue;
        
        const radialDecay = getRadialDecay(radius, maxRadius);
        let density = 0;
        let size = 1;
        // 【结构调整】始终计算 armInfo 和 result
        const armInfo = getArmInfo(x, y, centerX, centerY, maxRadius);
        const result = calculateArmDensityProfile(armInfo);
        
        // 检查是否在核心区域
        if (radius < params.coreRadius) {
          const coreProfile = Math.exp(-Math.pow(radius / params.coreRadius, 1.5));
          density = params.coreDensity * coreProfile * radialDecay;
          size = (params.coreSizeMin + Math.random() * (params.coreSizeMax - params.coreSizeMin)) * params.armStarSizeMultiplier;
        } else {
          // 不再是 else 分支，核心外的所有区域都走旋臂逻辑
          // ================================================================
          // A. 使用噪声调制密度 (制造团块感)
          // ================================================================
          // 从噪声函数获取一个 (-1 到 1) 的值
          const noiseValue = noise2D(x * params.densityNoiseScale, y * params.densityNoiseScale);
          // 将其映射到 (1 - strength) 到 1 的范围，用于削弱密度
          const densityModulation = 1.0 - params.densityNoiseStrength * (0.5 * (1.0 - noiseValue));
          
          density = result.density * radialDecay * densityModulation; // 乘以噪声调制因子
          size = result.size; // 已经在calculateArmDensityProfile中应用了倍数
        }
        
        // 添加随机性，避免过于规整
        const randomFactor = 0.8 + Math.random() * 0.4;
        density *= randomFactor;
        
        // 【重要】现在，这里的 if 块可以正确地访问到上面计算好的 armInfo 和 result
        if (Math.random() < density) {
          let offsetX = x; // 先初始化为原始坐标
          let offsetY = y;

          // ================================================================
          // B. 【最终修正版】垂直于旋臂"曲线"的、对称的抖动
          // ================================================================
          if (result.profile > 0.001) { // 只要在旋臂的微弱影响范围内就计算
            // 【优化】直接使用外层已经计算好的 armInfo，避免重复计算！
            
            // 1. 计算对数螺线的 pitch angle
            const pitchAngle = Math.atan(1 / params.spiralB);
            
            // 2. 计算正确的法线角度
            // 【重要】这里的 theta 必须来自外层计算的 armInfo
            const jitterAngle = armInfo.theta + pitchAngle + Math.PI / 2;

            // 3. 使用高斯随机数
            const rand1 = Math.random() || 1e-6; // 避免 log(0)
            const rand2 = Math.random();
            const gaussianRand = Math.sqrt(-2.0 * Math.log(rand1)) * Math.cos(2.0 * Math.PI * rand2);
            
            // 4. 【重要修正】抖动强度与 profile 正相关
            // 旋臂中心最"蓬松"，向边缘逐渐减弱
            const jitterAmount = params.jitterStrength * result.profile * gaussianRand;
            
            const dx_jitter = jitterAmount * Math.cos(jitterAngle);
            const dy_jitter = jitterAmount * Math.sin(jitterAngle);

            offsetX += dx_jitter;
            offsetY += dy_jitter;
          }
          
          ctx.beginPath();
          // 添加一个基础的、微小的随机位移，打破网格感
          offsetX += (Math.random() - 0.5) * step;
          offsetY += (Math.random() - 0.5) * step;
          ctx.arc(offsetX, offsetY, size, 0, 2 * Math.PI);
          ctx.fill();
        }
      }
    }
    
    // 【移除幽灵代码】原本的"增强旋臂明亮脊线"代码已移除
    // 现在完全依靠单一连续密度剖面模型来生成平滑的旋臂效果
    
    setIsGenerating(false);
  };
  
  useEffect(() => {
    generateGalaxy();
  }, [params]); // 【修改】监听 params 变化，自动重新生成
  
  const handleParamChange = (param, value) => {
    setParams(prev => ({
      ...prev,
      [param]: parseFloat(value)
    }));
  };

  // 新增：保存当前参数配置
  const saveConfig = () => {
    if (!configName.trim()) {
      alert('请输入配置名称');
      return;
    }
    
    const newConfig = {
      id: Date.now(),
      name: configName.trim(),
      params: { ...params },
      timestamp: new Date().toLocaleString()
    };
    
    setSavedConfigs(prev => [...prev, newConfig]);
    setConfigName('');
    alert(`配置 "${newConfig.name}" 已保存`);
  };

  // 新增：加载保存的配置
  const loadConfig = (config) => {
    setParams(config.params);
    alert(`已加载配置 "${config.name}"`);
  };

  // 新增：删除保存的配置
  const deleteConfig = (configId) => {
    setSavedConfigs(prev => prev.filter(config => config.id !== configId));
  };
  
  return (
    <div className="min-h-screen bg-gray-900 text-white p-6">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold mb-6 text-center">银河系极简模拟器 v5.0</h1>
        <p className="text-gray-300 mb-8 text-center max-w-3xl mx-auto">
          单一连续密度剖面模型：旋臂作为平滑"山脉"，彻底消除台阶效应
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
                      min="0.4"
                      max="1.5"
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
                <h3 className="text-sm font-medium mb-2 text-purple-400">旋臂密度剖面（核心）</h3>
                <div className="space-y-1">
                  
                  {/* 【重要修改】移除重复的 "旋臂峰值密度" 滑块，因为它和上面的 "旋臂密度" 冲突了 */}
                  {/* 我们只保留一个控制 armDensity 的地方，就在 "旋臂基础" 分类里 */}
                  
                  <label className="block">
                    臂间基础密度: {params.interArmDensity.toFixed(3)}
                    <input
                      type="range"
                      min="0.01"
                      max="0.15"
                      step="0.005"
                      value={params.interArmDensity}
                      onChange={(e) => handleParamChange('interArmDensity', e.target.value)}
                      className="w-full"
                    />
                  </label>
                  <label className="block">
                    山坡平缓度: {params.armTransitionSoftness.toFixed(1)}
                    <input
                      type="range"
                      min="2.0"
                      max="6.0"
                      step="0.2"
                      value={params.armTransitionSoftness}
                      onChange={(e) => handleParamChange('armTransitionSoftness', e.target.value)}
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
                <h3 className="text-sm font-medium mb-2 text-cyan-400">背景星空</h3>
                <div className="space-y-1">
                  <label className="block">
                    背景星星数量 (密度): {params.backgroundDensity.toFixed(5)}
                    <input
                      type="range"
                      min="0.0001"
                      max="0.05"
                      step="0.001"
                      value={params.backgroundDensity}
                      onChange={(e) => handleParamChange('backgroundDensity', e.target.value)}
                      className="w-full"
                    />
                  </label>
                  <label className="block">
                    背景星星大小: {params.backgroundStarSizeMultiplier.toFixed(1)}x
                    <input
                      type="range"
                      min="0.5"
                      max="3.0"
                      step="0.1"
                      value={params.backgroundStarSizeMultiplier}
                      onChange={(e) => handleParamChange('backgroundStarSizeMultiplier', e.target.value)}
                      className="w-full"
                    />
                  </label>
                </div>
              </div>
              
              <div>
                <h3 className="text-sm font-medium mb-2 text-red-400">破碎飘带效果（新功能）</h3>
                <div className="space-y-1">
                  <label className="block">
                    垂直抖动强度: {params.jitterStrength}
                    <input
                      type="range"
                      min="0.1"
                      max="20"
                      step="0.1"
                      value={params.jitterStrength}
                      onChange={(e) => handleParamChange('jitterStrength', e.target.value)}
                      className="w-full"
                    />
                  </label>
                  <label className="block">
                    密度噪声缩放: {params.densityNoiseScale.toFixed(3)}
                    <input
                      type="range"
                      min="0.010"
                      max="0.030"
                      step="0.002"
                      value={params.densityNoiseScale}
                      onChange={(e) => handleParamChange('densityNoiseScale', e.target.value)}
                      className="w-full"
                    />
                  </label>
                  <label className="block">
                    密度噪声强度: {params.densityNoiseStrength.toFixed(1)}
                    <input
                      type="range"
                      min="0.3"
                      max="1.0"
                      step="0.1"
                      value={params.densityNoiseStrength}
                      onChange={(e) => handleParamChange('densityNoiseStrength', e.target.value)}
                      className="w-full"
                    />
                  </label>
                </div>
              </div>
              
              <div>
                <h3 className="text-sm font-medium mb-2 text-pink-400">星星大小调节</h3>
                <div className="space-y-1">
                  <label className="block">
                    旋臂星星大小: {params.armStarSizeMultiplier.toFixed(1)}x
                    <input
                      type="range"
                      min="0.1"
                      max="1.0"
                      step="0.1"
                      value={params.armStarSizeMultiplier}
                      onChange={(e) => handleParamChange('armStarSizeMultiplier', e.target.value)}
                      className="w-full"
                    />
                  </label>
                  <label className="block">
                    臂间星星大小: {params.interArmStarSizeMultiplier.toFixed(2)}x
                    <input
                      type="range"
                      min="0.05"
                      max="1.2"
                      step="0.05"
                      value={params.interArmStarSizeMultiplier}
                      onChange={(e) => handleParamChange('interArmStarSizeMultiplier', e.target.value)}
                      className="w-full"
                    />
                  </label>
                  <label className="block">
                    背景星星大小: {params.backgroundStarSizeMultiplier.toFixed(2)}x
                    <input
                      type="range"
                      min="0.05"
                      max="1.2"
                      step="0.05"
                      value={params.backgroundStarSizeMultiplier}
                      onChange={(e) => handleParamChange('backgroundStarSizeMultiplier', e.target.value)}
                      className="w-full"
                    />
                  </label>
                </div>
              </div>
              
              <div className="mt-4 text-center">
                <p className="text-xs text-gray-400">
                  💡 调整参数将自动重新生成银河系
                </p>
              </div>

              {/* 新增：参数保存功能 */}
              <div className="mt-6 border-t border-gray-700 pt-4">
                <h3 className="text-sm font-medium mb-3 text-yellow-400">参数配置管理</h3>
                <div className="space-y-2">
                  <div className="flex gap-2">
                    <input
                      type="text"
                      placeholder="输入配置名称..."
                      value={configName}
                      onChange={(e) => setConfigName(e.target.value)}
                      className="flex-1 px-2 py-1 text-xs bg-gray-700 border border-gray-600 rounded text-white placeholder-gray-400"
                      onKeyPress={(e) => e.key === 'Enter' && saveConfig()}
                    />
                    <button
                      onClick={saveConfig}
                      className="px-3 py-1 text-xs bg-yellow-600 hover:bg-yellow-700 rounded transition-colors"
                    >
                      保存
                    </button>
                  </div>
                  
                  {/* 保存的配置标签 */}
                  {savedConfigs.length > 0 && (
                    <div className="space-y-2">
                      <p className="text-xs text-gray-400">已保存的配置：</p>
                      <div className="flex flex-wrap gap-2">
                        {savedConfigs.map(config => (
                          <div key={config.id} className="group relative">
                            <button
                              onClick={() => loadConfig(config)}
                              className="px-2 py-1 text-xs bg-gray-700 hover:bg-gray-600 border border-gray-600 rounded transition-colors"
                              title={`保存时间: ${config.timestamp}`}
                            >
                              {config.name}
                            </button>
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                deleteConfig(config.id);
                              }}
                              className="absolute -top-1 -right-1 w-4 h-4 bg-red-600 hover:bg-red-700 rounded-full text-xs opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center"
                              title="删除配置"
                            >
                              ×
                            </button>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              </div>
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
              <h3 className="font-medium mb-2">v5.0 单一连续密度剖面 + 破碎飘带特性：</h3>
              <ul className="space-y-1">
                <li>• <span className="text-green-400">平滑山脉模型</span>：旋臂密度如高斯曲线，彻底消除台阶</li>
                <li>• <span className="text-purple-400">单一剖面</span>：从臂间到臂心的密度变化完全连续</li>
                <li>• <span className="text-blue-400">物理直观</span>：符合密度波理论的"面"概念</li>
                <li>• <span className="text-red-400">破碎飘带</span>：垂直抖动+密度噪声，解决旋臂戛然而止问题</li>
                <li>• <span className="text-orange-400">自然团块</span>：simplex噪声制造星团聚集效果</li>
                <li>• <span className="text-cyan-400">数学保证</span>：高斯分布天然保证无断崖过渡</li>
                <li>• <span className="text-yellow-400">自然弥散</span>：旋臂末端自然散开，无尖锐边缘</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default GalaxySimulator;