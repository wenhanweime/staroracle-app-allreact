import { WebPlugin } from '@capacitor/core';
import { ChatOverlayPlugin } from './ChatOverlay';

export class ChatOverlayWeb extends WebPlugin implements ChatOverlayPlugin {
  async show(options: { isOpen: boolean }): Promise<void> {
    console.log('🌐 ChatOverlay show called with:', options);
    // Web端回退到React组件
  }

  async hide(): Promise<void> {
    console.log('🌐 ChatOverlay hide called');
  }

  async sendMessage(options: { message: string }): Promise<void> {
    console.log('🌐 ChatOverlay sendMessage called with:', options);
  }
}