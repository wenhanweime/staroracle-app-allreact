import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.staroracle.app',
  appName: 'StarOracle',
  webDir: 'dist',
  server: {
    androidScheme: 'https'
  }
};

export default config;
