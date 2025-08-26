import { registerPlugin } from '@capacitor/core';

export interface SimpleTestPlugin {
  test(): Promise<{ message: string }>;
}

export const SimpleTest = registerPlugin<SimpleTestPlugin>('SimpleTestPlugin', {
  web: () => ({
    test: async () => ({ message: 'Web版本测试插件' })
  })
});