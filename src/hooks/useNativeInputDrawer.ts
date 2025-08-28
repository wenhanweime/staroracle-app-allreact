import { useState, useEffect } from 'react';
import { Capacitor } from '@capacitor/core';
import { InputDrawer } from '../plugins/InputDrawer';

export interface InputDrawerHook {
  isVisible: boolean;
  text: string;
  show: () => Promise<void>;
  hide: () => Promise<void>;
  setText: (text: string) => Promise<void>;
  getText: () => Promise<string>;
  focus: () => Promise<void>;
  blur: () => Promise<void>;
  setBottomSpace: (space: number) => Promise<void>;
  setPlaceholder: (placeholder: string) => Promise<void>;
  isNative: boolean;
}

export const useNativeInputDrawer = (): InputDrawerHook => {
  const [isVisible, setIsVisible] = useState(false);
  const [text, setText] = useState('');
  
  const isNative = Capacitor.isNativePlatform();

  useEffect(() => {
    if (!isNative) {
      console.log('🌐 Web环境，使用React InputDrawer');
      return;
    }

    console.log('📱 原生环境，设置InputDrawer监听器');

    // TODO: 添加原生事件监听器
    // const inputChangeListener = InputDrawer.addListener('inputChanged', (data: any) => {
    //   console.log('📱 输入框内容变化:', data.text);
    //   setText(data.text);
    // });

    return () => {
      // TODO: 清理监听器
      // inputChangeListener.then(listener => listener.remove());
    };
  }, [isNative]);

  const show = async () => {
    if (isNative) {
      console.log('📱 显示原生InputDrawer');
      try {
        const result = await InputDrawer.show({ animated: true });
        setIsVisible(result.visible);
        console.log('✅ 原生InputDrawer显示成功');
      } catch (error) {
        console.error('❌ 原生InputDrawer显示失败:', error);
      }
    } else {
      console.log('🌐 显示React InputDrawer');
      setIsVisible(true);
    }
  };

  const hide = async () => {
    if (isNative) {
      console.log('📱 隐藏原生InputDrawer');
      try {
        const result = await InputDrawer.hide({ animated: true });
        setIsVisible(result.visible);
      } catch (error) {
        console.error('❌ 原生InputDrawer隐藏失败:', error);
      }
    } else {
      console.log('🌐 隐藏React InputDrawer');
      setIsVisible(false);
    }
  };

  const setTextNative = async (newText: string) => {
    if (isNative) {
      console.log('📱 设置原生InputDrawer文本:', newText);
      try {
        await InputDrawer.setText({ text: newText });
        setText(newText);
      } catch (error) {
        console.error('❌ 设置原生InputDrawer文本失败:', error);
      }
    } else {
      console.log('🌐 设置React InputDrawer文本:', newText);
      setText(newText);
    }
  };

  const getTextNative = async (): Promise<string> => {
    if (isNative) {
      console.log('📱 获取原生InputDrawer文本');
      try {
        const result = await InputDrawer.getText();
        setText(result.text);
        return result.text;
      } catch (error) {
        console.error('❌ 获取原生InputDrawer文本失败:', error);
        return text;
      }
    } else {
      console.log('🌐 获取React InputDrawer文本');
      return text;
    }
  };

  const focus = async () => {
    if (isNative) {
      console.log('📱 聚焦原生InputDrawer');
      try {
        await InputDrawer.focus();
      } catch (error) {
        console.error('❌ 聚焦原生InputDrawer失败:', error);
      }
    } else {
      console.log('🌐 聚焦React InputDrawer');
      // TODO: 实现Web版本的focus
    }
  };

  const blur = async () => {
    if (isNative) {
      console.log('📱 失焦原生InputDrawer');
      try {
        await InputDrawer.blur();
      } catch (error) {
        console.error('❌ 失焦原生InputDrawer失败:', error);
      }
    } else {
      console.log('🌐 失焦React InputDrawer');
      // TODO: 实现Web版本的blur
    }
  };

  const setBottomSpace = async (space: number) => {
    if (isNative) {
      console.log('📱 设置原生InputDrawer底部空间:', space);
      try {
        await InputDrawer.setBottomSpace({ space });
      } catch (error) {
        console.error('❌ 设置原生InputDrawer底部空间失败:', error);
      }
    } else {
      console.log('🌐 设置React InputDrawer底部空间:', space);
      // TODO: 实现Web版本的setBottomSpace
    }
  };

  const setPlaceholder = async (placeholder: string) => {
    if (isNative) {
      console.log('📱 设置原生InputDrawer占位符:', placeholder);
      try {
        await InputDrawer.setPlaceholder({ placeholder });
      } catch (error) {
        console.error('❌ 设置原生InputDrawer占位符失败:', error);
      }
    } else {
      console.log('🌐 设置React InputDrawer占位符:', placeholder);
      // TODO: 实现Web版本的setPlaceholder
    }
  };

  return {
    isVisible,
    text,
    show,
    hide,
    setText: setTextNative,
    getText: getTextNative,
    focus,
    blur,
    setBottomSpace,
    setPlaceholder,
    isNative
  };
};