import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.staroracle.app',
  appName: 'StarOracle',
  webDir: 'dist',
  server: {
    androidScheme: 'https'
  },
  plugins: {
    Keyboard: {
      resize: 'ionic',  // 使用ionic模式的键盘调整
      style: 'dark',    // 键盘样式
      resizeOnFullScreen: true
    }
  }
};

export default config;
