import { registerPlugin } from '@capacitor/core';

export type GalaxyQuality = 'auto' | 'low' | 'mid' | 'high';

export interface GalaxyHighlightInput {
  id: string;
  color?: string;
  intensity?: number;
  x?: number;
  y?: number;
}

export interface GalaxyBackgroundPlugin {
  configure(options: { quality?: GalaxyQuality; reducedMotion?: boolean }): Promise<void>;
  setQuality(options: { quality: GalaxyQuality; reducedMotion?: boolean }): Promise<void>;
  setMode(options: { mode: 'native' | 'web' }): Promise<void>;
  setHighlights(options: { highlights: GalaxyHighlightInput[] }): Promise<void>;
  clearHighlights(): Promise<void>;
}

export const GalaxyBackground = registerPlugin<GalaxyBackgroundPlugin>('GalaxyBackground', {
  web: () => import('./GalaxyBackgroundWeb').then(m => new m.GalaxyBackgroundWeb()),
});
