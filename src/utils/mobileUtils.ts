import { Capacitor } from '@capacitor/core';

/**
 * 检测是否为移动端原生环境
 */
export const isMobileNative = () => {
  return Capacitor.isNativePlatform();
};

/**
 * 检测是否为iOS
 */
export const isIOS = () => {
  return Capacitor.getPlatform() === 'ios';
};

/**
 * 创建最高层级的Portal容器
 */
export const createTopLevelContainer = (): HTMLElement => {
  let container = document.getElementById('top-level-modals');
  
  if (!container) {
    container = document.createElement('div');
    container.id = 'top-level-modals';
    container.style.cssText = `
      position: fixed !important;
      top: 0 !important;
      left: 0 !important;
      right: 0 !important;
      bottom: 0 !important;
      z-index: 2147483647 !important;
      pointer-events: none !important;
      -webkit-transform: translateZ(0) !important;
      transform: translateZ(0) !important;
      -webkit-backface-visibility: hidden !important;
      backface-visibility: hidden !important;
    `;
    document.body.appendChild(container);
  }
  
  return container;
};

/**
 * 获取移动端特有的模态框样式
 */
export const getMobileModalStyles = () => {
  return {
    position: 'fixed' as const,
    zIndex: 2147483647, // 使用最大z-index值
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    pointerEvents: 'auto' as const,
    WebkitTransform: 'translateZ(0)',
    transform: 'translateZ(0)',
    WebkitBackfaceVisibility: 'hidden' as const,
    backfaceVisibility: 'hidden' as const,
  };
};

/**
 * 获取移动端特有的CSS类名
 */
export const getMobileModalClasses = () => {
  return 'fixed inset-0 flex items-center justify-center';
};

/**
 * 强制隐藏所有其他元素（除了模态框）
 */
export const hideOtherElements = () => {
  if (!isIOS()) return () => {};
  
  // 如果Portal和z-index修复已经工作，我们可能不需要隐藏主页按钮
  // 让我们尝试一个最小化的方法：只在绝对必要时隐藏
  
  console.log('iOS hideOtherElements called - using minimal approach');
  
  // 返回一个空的恢复函数，不隐藏任何元素
  return () => {
    console.log('iOS hideOtherElements restore called');
  };
};

/**
 * 修复iOS层级问题的通用方案
 */
export const fixIOSZIndex = () => {
  if (!isIOS()) return;
  
  // 创建顶级容器
  createTopLevelContainer();
  
  // 为body添加特殊的层级修复
  document.body.style.webkitTransform = 'translateZ(0)';
  document.body.style.transform = 'translateZ(0)';
};