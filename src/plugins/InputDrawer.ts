import { registerPlugin } from '@capacitor/core';

export interface InputDrawerPlugin {
  show(options: { animated?: boolean }): Promise<{ success: boolean; visible: boolean }>;
  hide(options: { animated?: boolean }): Promise<{ success: boolean; visible: boolean }>;
  setText(options: { text: string }): Promise<{ success: boolean }>;
  getText(): Promise<{ text: string }>;
  focus(): Promise<{ success: boolean }>;
  blur(): Promise<{ success: boolean }>;
  setBottomSpace(options: { space: number }): Promise<{ success: boolean }>;
  setPlaceholder(options: { placeholder: string }): Promise<{ success: boolean }>;
  isVisible(): Promise<{ visible: boolean }>;
}

export const InputDrawer = registerPlugin<InputDrawerPlugin>('InputDrawer', {
  web: () => ({
    show: async (options) => {
      console.log('🌐 Web InputDrawer: show', options);
      return { success: true, visible: true };
    },
    hide: async (options) => {
      console.log('🌐 Web InputDrawer: hide', options);
      return { success: true, visible: false };
    },
    setText: async (options) => {
      console.log('🌐 Web InputDrawer: setText', options);
      return { success: true };
    },
    getText: async () => {
      console.log('🌐 Web InputDrawer: getText');
      return { text: '' };
    },
    focus: async () => {
      console.log('🌐 Web InputDrawer: focus');
      return { success: true };
    },
    blur: async () => {
      console.log('🌐 Web InputDrawer: blur');
      return { success: true };
    },
    setBottomSpace: async (options) => {
      console.log('🌐 Web InputDrawer: setBottomSpace', options);
      return { success: true };
    },
    setPlaceholder: async (options) => {
      console.log('🌐 Web InputDrawer: setPlaceholder', options);
      return { success: true };
    },
    isVisible: async () => {
      console.log('🌐 Web InputDrawer: isVisible');
      return { visible: true };
    }
  })
});
