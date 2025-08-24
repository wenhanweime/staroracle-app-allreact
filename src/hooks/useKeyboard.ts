import { useState, useEffect } from 'react';
import { Keyboard, KeyboardInfo } from '@capacitor/keyboard';

export const useKeyboard = () => {
  const [keyboardHeight, setKeyboardHeight] = useState(0);
  const [isKeyboardOpen, setIsKeyboardOpen] = useState(false);

  useEffect(() => {
    const keyboardWillShowListener = Keyboard.addListener('keyboardWillShow', (info: KeyboardInfo) => {
      console.log('🔍 键盘即将显示:', info);
      setKeyboardHeight(info.keyboardHeight);
      setIsKeyboardOpen(true);
    });

    const keyboardDidShowListener = Keyboard.addListener('keyboardDidShow', (info: KeyboardInfo) => {
      console.log('🔍 键盘已显示:', info);
      setKeyboardHeight(info.keyboardHeight);
      setIsKeyboardOpen(true);
    });

    const keyboardWillHideListener = Keyboard.addListener('keyboardWillHide', () => {
      console.log('🔍 键盘即将隐藏');
      setKeyboardHeight(0);
      setIsKeyboardOpen(false);
    });

    const keyboardDidHideListener = Keyboard.addListener('keyboardDidHide', () => {
      console.log('🔍 键盘已隐藏');
      setKeyboardHeight(0);
      setIsKeyboardOpen(false);
    });

    return () => {
      keyboardWillShowListener.remove();
      keyboardDidShowListener.remove();
      keyboardWillHideListener.remove();
      keyboardDidHideListener.remove();
    };
  }, []);

  return { keyboardHeight, isKeyboardOpen };
};