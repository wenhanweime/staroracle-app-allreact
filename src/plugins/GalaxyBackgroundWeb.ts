import type { GalaxyBackgroundPlugin, GalaxyQuality, GalaxyHighlightInput } from './GalaxyBackground';

export class GalaxyBackgroundWeb implements GalaxyBackgroundPlugin {
  async configure(options: { quality?: GalaxyQuality; reducedMotion?: boolean }): Promise<void> {
    console.log('[GalaxyBackgroundWeb] configure (noop)', options);
  }

  async setQuality(options: { quality: GalaxyQuality; reducedMotion?: boolean }): Promise<void> {
    console.log('[GalaxyBackgroundWeb] setQuality (noop)', options);
  }

  async setMode(options: { mode: 'native' | 'web' }): Promise<void> {
    console.log('[GalaxyBackgroundWeb] setMode (noop)', options);
  }

  async setHighlights(options: { highlights: GalaxyHighlightInput[] }): Promise<void> {
    console.log('[GalaxyBackgroundWeb] setHighlights (noop)', options.highlights?.length ?? 0);
  }

  async clearHighlights(): Promise<void> {
    console.log('[GalaxyBackgroundWeb] clearHighlights (noop)');
  }
}
