import { Capacitor } from '@capacitor/core';
import { Haptics, ImpactStyle } from '@capacitor/haptics';

export const triggerHapticFeedback = async (type: 'light' | 'medium' | 'heavy' | 'success' | 'warning' | 'error' = 'light') => {
  if (!Capacitor.isNativePlatform()) return;
  
  try {
    switch (type) {
      case 'light':
        await Haptics.impact({ style: ImpactStyle.Light });
        break;
      case 'medium':
        await Haptics.impact({ style: ImpactStyle.Medium });
        break;
      case 'heavy':
        await Haptics.impact({ style: ImpactStyle.Heavy });
        break;
      case 'success':
      case 'warning':
      case 'error':
        // 对于通知类型，使用中等强度的冲击反馈
        await Haptics.impact({ style: ImpactStyle.Medium });
        break;
    }
  } catch (error) {
    console.warn('Haptic feedback not available:', error);
  }
};

export const triggerSelectionHaptic = async () => {
  if (!Capacitor.isNativePlatform()) return;
  
  try {
    await Haptics.selectionStart();
    setTimeout(async () => {
      await Haptics.selectionEnd();
    }, 100);
  } catch (error) {
    console.warn('Selection haptic not available:', error);
  }
};