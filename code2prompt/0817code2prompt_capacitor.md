Project Path: staroracle-app_v1

Source Tree:

```txt
staroracle-app_v1
├── ref
│   └── dark-input-bar.tsx
└── src
    ├── App.tsx
    ├── ErrorBoundary.tsx
    ├── components
    │   ├── AIConfigPanel.tsx
    │   ├── CollectionButton.tsx
    │   ├── Constellation.tsx
    │   ├── ConstellationSelector.tsx
    │   ├── ConversationDrawer.tsx
    │   ├── Header.tsx
    │   ├── InspirationCard.tsx
    │   ├── OracleInput.tsx
    │   ├── Star.tsx
    │   ├── StarCard.tsx
    │   ├── StarCollection.tsx
    │   ├── StarDetail.tsx
    │   ├── StarRayIcon.tsx
    │   ├── StarryBackground.tsx
    │   └── TemplateButton.tsx
    ├── index.css
    ├── main.tsx
    ├── store
    │   └── useStarStore.ts
    ├── types
    │   └── index.ts
    ├── utils
    │   ├── aiTaggingUtils.ts
    │   ├── bookOfAnswers.ts
    │   ├── constellationTemplates.ts
    │   ├── hapticUtils.ts
    │   ├── imageUtils.ts
    │   ├── inspirationCards.ts
    │   ├── mobileUtils.ts
    │   ├── oracleUtils.ts
    │   └── soundUtils.ts
    └── vite-env.d.ts

```

`staroracle-app_v1/ref/dark-input-bar.tsx`:

```tsx
import React, { useState } from 'react';
import { Plus, Mic } from 'lucide-react';

// Star Ray Icon Component with animation
const StarRayIcon = ({ size = 20, animated = false, iconColor = "#ffffff" }) => {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className="star-ray-icon"
    >
      {/* Center circle */}
      {animated ? (
        <circle
          cx="12"
          cy="12"
          r="2"
          fill={iconColor}
          className="animate-pulse"
        />
      ) : (
        <circle cx="12" cy="12" r="2" fill={iconColor} />
      )}
      
      {/* Eight rays */}
      {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => {
        const angle = (i * 45) * (Math.PI / 180); // Convert to radians
        const startX = 12 + Math.cos(angle) * 3;
        const startY = 12 + Math.sin(angle) * 3;
        const endX = 12 + Math.cos(angle) * 8;
        const endY = 12 + Math.sin(angle) * 8;
        
        return animated ? (
          <line
            key={i}
            x1={startX}
            y1={startY}
            x2={endX}
            y2={endY}
            stroke={iconColor}
            strokeWidth="2"
            strokeLinecap="round"
            className="animate-ray"
            style={{
              animation: `rayExpand 0.5s ease-out ${0.1 + i * 0.05}s both`,
              transformOrigin: '12px 12px'
            }}
          />
        ) : (
          <line
            key={i}
            x1={startX}
            y1={startY}
            x2={endX}
            y2={endY}
            stroke={iconColor}
            strokeWidth="2"
            strokeLinecap="round"
          />
        );
      })}
      
      {/* CSS Animation styles */}
      <style jsx>{`
        @keyframes rayExpand {
          0% {
            stroke-dasharray: 5;
            stroke-dashoffset: 5;
          }
          100% {
            stroke-dasharray: 5;
            stroke-dashoffset: 0;
          }
        }
        .animate-ray {
          stroke-dasharray: 5;
          stroke-dashoffset: 0;
        }
      `}</style>
    </svg>
  );
};

const DarkInputBar = () => {
  const [inputValue, setInputValue] = useState('');
  const [isRecording, setIsRecording] = useState(false);
  const [starAnimated, setStarAnimated] = useState(false);

  const handleAddClick = () => {
    console.log('Add button clicked');
  };

  const handleMicClick = () => {
    setIsRecording(!isRecording);
    console.log('Microphone clicked, recording:', !isRecording);
  };

  const handleStarClick = () => {
    setStarAnimated(true);
    console.log('Star ray button clicked');
    
    // Reset animation after completion
    setTimeout(() => {
      setStarAnimated(false);
    }, 1000);
  };

  const handleInputChange = (e) => {
    setInputValue(e.target.value);
  };

  const handleSubmit = () => {
    if (inputValue.trim()) {
      console.log('Submitted:', inputValue);
      setInputValue('');
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter') {
      handleSubmit();
    }
  };

  return (
    <div className="w-full max-w-md mx-auto p-4">
      <div className="relative">
        {/* Main container with dark background */}
        <div className="flex items-center bg-gray-900 rounded-full h-12 shadow-lg border border-gray-800">
          
          {/* Plus button - positioned flush left */}
          <button
            type="button"
            onClick={handleAddClick}
            className="flex-shrink-0 w-10 h-10 bg-gray-700 hover:bg-gray-600 rounded-full flex items-center justify-center ml-1 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 focus:ring-offset-gray-900"
          >
            <Plus className="w-5 h-5 text-white" strokeWidth={2} />
          </button>

          {/* Input field */}
          <input
            type="text"
            value={inputValue}
            onChange={handleInputChange}
            onKeyPress={handleKeyPress}
            placeholder="询问任何问题"
            className="flex-1 bg-transparent text-white placeholder-gray-400 px-4 py-2 focus:outline-none text-sm font-normal"
            style={{ fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif' }}
          />

          {/* Right side icons container */}
          <div className="flex items-center space-x-2 mr-3">
            
            {/* Microphone button */}
            <button
              type="button"
              onClick={handleMicClick}
              className={`p-2 rounded-full transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-500 ${
                isRecording 
                  ? 'bg-red-600 hover:bg-red-500 text-white' 
                  : 'hover:bg-gray-700 text-gray-300'
              }`}
            >
              <Mic className="w-4 h-4" strokeWidth={2} />
            </button>

            {/* Star ray button */}
            <button
              type="button"
              onClick={handleStarClick}
              className="p-2 rounded-full hover:bg-gray-700 text-gray-300 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-500"
            >
              <StarRayIcon 
                size={16} 
                animated={starAnimated || !!inputValue.trim()} 
                iconColor="#ffffff"
              />
            </button>
            
          </div>
        </div>

        {/* Recording indicator */}
        {isRecording && (
          <div className="absolute -bottom-8 left-1/2 transform -translate-x-1/2">
            <div className="flex items-center space-x-2 text-red-400 text-xs">
              <div className="w-2 h-2 bg-red-500 rounded-full animate-pulse"></div>
              <span>Recording...</span>
            </div>
          </div>
        )}
      </form>

      {/* Demo instructions */}
      <div className="mt-8 text-gray-400 text-sm space-y-2">
        <p className="font-medium">Interactive Features:</p>
        <ul className="space-y-1 text-xs">
          <li>• Plus button: Add new conversation</li>
          <li>• Microphone: Toggle voice recording (red when active)</li>
          <li>• Star rays: Animated star with expanding rays on click/input</li>
          <li>• Enter to submit text input</li>
          <li>• Star animates when typing or clicking</li>
        </ul>
      </div>
    </div>
  );
};

export default DarkInputBar;
```

`staroracle-app_v1/src/App.tsx`:

```tsx
import React, { useEffect, useState } from 'react';
import { Capacitor } from '@capacitor/core';
import { StatusBar, Style } from '@capacitor/status-bar';
import { SplashScreen } from '@capacitor/splash-screen';
import { Keyboard } from '@capacitor/keyboard';
import StarryBackground from './components/StarryBackground';
import Constellation from './components/Constellation';
import InspirationCard from './components/InspirationCard';
import StarDetail from './components/StarDetail';
import StarCollection from './components/StarCollection';
import CollectionButton from './components/CollectionButton';
import TemplateButton from './components/TemplateButton';
import ConstellationSelector from './components/ConstellationSelector';
import AIConfigPanel from './components/AIConfigPanel';
import Header from './components/Header';
import ConversationDrawer from './components/ConversationDrawer';
import OracleInput from './components/OracleInput';
import { startAmbientSound, stopAmbientSound, playSound } from './utils/soundUtils';
import { triggerHapticFeedback } from './utils/hapticUtils';
import { Settings } from 'lucide-react';
import { useStarStore } from './store/useStarStore';
import { ConstellationTemplate } from './types';
import { checkApiConfiguration } from './utils/aiTaggingUtils';
import { motion, AnimatePresence } from 'framer-motion';

function App() {
  const [isCollectionOpen, setIsCollectionOpen] = useState(false);
  const [isConfigOpen, setIsConfigOpen] = useState(false);
  const [isTemplateSelectorOpen, setIsTemplateSelectorOpen] = useState(false);
  const [appReady, setAppReady] = useState(false);
  const { 
    applyTemplate, 
    currentInspirationCard, 
    dismissInspirationCard 
  } = useStarStore();

  // 添加原生平台效果（只在原生环境下执行）
  useEffect(() => {
    const setupNative = async () => {
      if (Capacitor.isNativePlatform()) {
        // 设置状态栏为暗色模式，文字为亮色
        await StatusBar.setStyle({ style: Style.Dark });
        
        // 标记应用准备就绪
        setAppReady(true);
        
        // 延迟隐藏启动屏，让应用完全加载
        setTimeout(async () => {
          await SplashScreen.hide({
            fadeOutDuration: 300
          });
        }, 500);
      } else {
        // Web环境立即设置为准备就绪
        setAppReady(true);
      }
    };
    setupNative();
  }, []);

  // 检查API配置（静默模式 - 只在控制台提示）
  useEffect(() => {
    // 延迟检查，确保应用已完全加载
    const timer = setTimeout(() => {
      const isConfigValid = checkApiConfiguration();
      // 移除UI警告，改为静默模式
      // setShowApiWarning(!isConfigValid);
      
      if (!isConfigValid) {
        console.warn('⚠️ API配置无效或不完整，请配置API以使用完整功能');
        console.info('💡 点击右上角设置图标进行API配置');
      } else {
        console.log('✅ API配置正常');
      }
    }, 2000);
    
    return () => clearTimeout(timer);
  }, []);

  // 监控灵感卡片状态变化（保持Web版本逻辑）
  useEffect(() => {
    console.log('🃏 灵感卡片状态变化:', currentInspirationCard ? '显示' : '隐藏');
    if (currentInspirationCard) {
      console.log('📝 当前卡片问题:', currentInspirationCard.question);
    }
  }, [currentInspirationCard]);

  // Start ambient sound when user interacts（延迟到用户交互后）
  useEffect(() => {
    const handleFirstInteraction = () => {
      startAmbientSound();
      document.removeEventListener('touchstart', handleFirstInteraction);
      document.removeEventListener('click', handleFirstInteraction);
    };
    
    document.addEventListener('touchstart', handleFirstInteraction);
    document.addEventListener('click', handleFirstInteraction);
    
    return () => {
      document.removeEventListener('touchstart', handleFirstInteraction);
      document.removeEventListener('click', handleFirstInteraction);
      stopAmbientSound();
    };
  }, []);

  const handleOpenCollection = () => {
    console.log('🔍 Collection button clicked - handleOpenCollection triggered!');
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('light');
    }
    playSound('starLight');
    setIsCollectionOpen(true);
  };

  const handleCloseCollection = () => {
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('light');
    }
    setIsCollectionOpen(false);
  };

  const handleOpenConfig = () => {
    console.log('⚙️ Settings button clicked - handleOpenConfig triggered!');
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('medium');
    }
    playSound('starClick');
    setIsConfigOpen(true);
  };

  const handleCloseConfig = () => {
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('light');
    }
    setIsConfigOpen(false);
    // 静默模式：移除配置检查和UI提示
  };

  const handleOpenTemplateSelector = () => {
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('light');
    }
    playSound('starClick');
    setIsTemplateSelectorOpen(true);
  };

  const handleCloseTemplateSelector = () => {
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('light');
    }
    setIsTemplateSelectorOpen(false);
  };

  const handleSelectTemplate = (template: ConstellationTemplate) => {
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('success');
    }
    applyTemplate(template);
    playSound('starReveal');
  };
  
  return (
    <div className="min-h-screen cosmic-bg overflow-hidden relative">
      {/* Background with stars - 延迟渲染 */}
      {appReady && <StarryBackground starCount={75} />}
      
      {/* Header */}
      <Header />
      
      {/* Left side buttons - 避免与Header重叠 */}
      <div 
        className="fixed z-50 flex flex-col gap-3"
        style={{
          top: `calc(5rem + var(--safe-area-inset-top, 0px))`, // Header高度4rem + 1rem间距
          left: `calc(1rem + var(--safe-area-inset-left, 0px))`
        }}
      >
        <CollectionButton onClick={handleOpenCollection} />
        <TemplateButton onClick={handleOpenTemplateSelector} />
      </div>

      {/* AI Config Button - 避免与Header重叠 */}
      <div 
        className="fixed z-50"
        style={{
          top: `calc(5rem + var(--safe-area-inset-top, 0px))`, // Header高度4rem + 1rem间距
          right: `calc(1rem + var(--safe-area-inset-right, 0px))`
        }}
      >
        <button
          className="cosmic-button rounded-full p-3 flex items-center justify-center"
          onClick={handleOpenConfig}
          title="AI Configuration"
        >
          <Settings className="w-5 h-5 text-white" />
        </button>
      </div>
      
      {/* User's constellation - 延迟渲染 */}
      {appReady && <Constellation />}
      
      {/* Inspiration card */}
      {currentInspirationCard && (
        <InspirationCard
          card={currentInspirationCard}
          onDismiss={dismissInspirationCard}
        />
      )}
      
      {/* Star detail modal */}
      {appReady && <StarDetail />}
      
      {/* Star collection modal */}
      <StarCollection 
        isOpen={isCollectionOpen} 
        onClose={handleCloseCollection} 
      />

      {/* Template selector modal */}
      <ConstellationSelector
        isOpen={isTemplateSelectorOpen}
        onClose={handleCloseTemplateSelector}
        onSelectTemplate={handleSelectTemplate}
      />

      {/* AI Configuration Panel */}
      <AIConfigPanel
        isOpen={isConfigOpen}
        onClose={handleCloseConfig}
      />

      {/* Oracle Input for star creation */}
      <OracleInput />

      {/* Conversation Drawer */}
      <ConversationDrawer isOpen={true} onToggle={() => {}} />
    </div>
  );
}

export default App;
```

`staroracle-app_v1/src/ErrorBoundary.tsx`:

```tsx
import React, { Component, ReactNode } from 'react';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: any) {
    console.error('App Error Boundary caught an error:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-black relative flex items-center justify-center">
          <div className="text-white bg-red-500 p-4 rounded max-w-md">
            <h2 className="text-xl mb-2">Application Error</h2>
            <p className="mb-2">Something went wrong:</p>
            <pre className="text-sm bg-black p-2 rounded overflow-auto">
              {this.state.error?.message}
            </pre>
            <button 
              onClick={() => this.setState({ hasError: false })}
              className="mt-2 px-4 py-2 bg-blue-500 rounded text-white"
            >
              Try Again
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
```

`staroracle-app_v1/src/components/AIConfigPanel.tsx`:

```tsx
import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { createPortal } from 'react-dom';
import { Settings, X, Key, Globe, Cpu, CheckCircle, XCircle, Loader, Download, Upload, Clock } from 'lucide-react';
import { setAIConfig, getAIConfig, validateAIConfig, APIValidationResult, clearAIConfig } from '../utils/aiTaggingUtils';
import { playSound } from '../utils/soundUtils';
import { getMobileModalStyles, getMobileModalClasses, fixIOSZIndex, createTopLevelContainer, hideOtherElements } from '../utils/mobileUtils';
import type { ApiProvider } from '../vite-env';

interface AIConfigPanelProps {
  isOpen: boolean;
  onClose: () => void;
}

const AIConfigPanel: React.FC<AIConfigPanelProps> = ({ isOpen, onClose }) => {
  const [config, setConfig] = useState(() => getAIConfig());
  const [isSaving, setIsSaving] = useState(false);
  const [isValidating, setIsValidating] = useState(false);
  const [validationResult, setValidationResult] = useState<APIValidationResult | null>(null);
  const [showLastUpdated, setShowLastUpdated] = useState(false);
  const [provider, setProvider] = useState<ApiProvider>(config.provider || 'openai');
  const [restoreElements, setRestoreElements] = useState<(() => void) | null>(null);
  
  // 添加refs用于直接访问DOM元素
  const apiKeyRef = useRef<HTMLInputElement>(null);
  const endpointRef = useRef<HTMLInputElement>(null);
  const modelRef = useRef<HTMLInputElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // 初始化iOS层级修复
  useEffect(() => {
    fixIOSZIndex();
  }, []);

  // 当模态框打开时隐藏其他元素
  useEffect(() => {
    if (isOpen) {
      document.body.classList.add('modal-open');
      const restore = hideOtherElements();
      setRestoreElements(() => restore);
    } else {
      document.body.classList.remove('modal-open');
      if (restoreElements) {
        restoreElements();
        setRestoreElements(null);
      }
    }
    
    return () => {
      document.body.classList.remove('modal-open');
      if (restoreElements) {
        restoreElements();
      }
    };
  }, [isOpen]);

  // 当组件打开时，确保输入框可以接受粘贴
  useEffect(() => {
    if (isOpen) {
      const handlePaste = (e: ClipboardEvent) => {
        // 允许默认粘贴行为
        e.stopPropagation();
      };

      // 为所有输入框添加粘贴事件监听
      const elements = [apiKeyRef.current, endpointRef.current, modelRef.current];
      elements.forEach(el => {
        if (el) {
          el.addEventListener('paste', handlePaste);
        }
      });

      // 设置当前provider
      setProvider(config.provider || 'openai');

      return () => {
        // 清理事件监听
        elements.forEach(el => {
          if (el) {
            el.removeEventListener('paste', handlePaste);
          }
        });
      };
    }
  }, [isOpen, config]);

  const handleProviderChange = (value: ApiProvider) => {
    setProvider(value);
    setConfig({
      ...config,
      provider: value
    });

    // 根据选择的provider设置不同的endpoint和model示例
    if (value === 'gemini') {
      if (!config.endpoint || config.endpoint.includes('openai.com')) {
        setConfig(prev => ({
          ...prev,
          endpoint: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent',
          model: 'gemini-1.5-flash-latest'
        }));
      }
    } else if (value === 'openai') {
      if (!config.endpoint || config.endpoint.includes('googleapis.com')) {
        setConfig(prev => ({
          ...prev,
          endpoint: 'https://api.openai.com/v1/chat/completions',
          model: 'gpt-4o'
        }));
      }
    }
  };

  const handleValidate = async () => {
    if (!config.provider || !config.apiKey || !config.endpoint || !config.model) {
      setValidationResult({
        isValid: false,
        error: '请填写完整的配置信息'
      });
      return;
    }

    setIsValidating(true);
    setValidationResult(null);
    playSound('starClick');

    try {
      const result = await validateAIConfig(config);
      setValidationResult(result);
      
      if (result.isValid) {
        playSound('starReveal');
      } else {
        playSound('starClick');
      }
    } catch (error) {
      setValidationResult({
        isValid: false,
        error: '验证过程中发生错误'
      });
    } finally {
      setIsValidating(false);
    }
  };

  const handleSave = async () => {
    setIsSaving(true);
    playSound('starLight');
    
    try {
      setAIConfig(config);
      // Test the configuration
      await new Promise(resolve => setTimeout(resolve, 1000));
      playSound('starReveal');
      onClose();
    } catch (error) {
      console.error('Failed to save AI config:', error);
    } finally {
      setIsSaving(false);
    }
  };

  const handleClose = () => {
    playSound('starClick');
    onClose();
  };

  const getValidationIcon = () => {
    if (isValidating) {
      return <Loader className="w-4 h-4 animate-spin text-blue-400" />;
    }
    if (validationResult?.isValid) {
      return <CheckCircle className="w-4 h-4 text-green-400" />;
    }
    if (validationResult && !validationResult.isValid) {
      return <XCircle className="w-4 h-4 text-red-400" />;
    }
    return null;
  };

  const getValidationMessage = () => {
    if (isValidating) {
      return "正在验证API配置...";
    }
    if (validationResult?.isValid) {
      return `✅ API验证成功！响应时间: ${validationResult.responseTime}ms`;
    }
    if (validationResult && !validationResult.isValid) {
      return `❌ ${validationResult.error}`;
    }
    return null;
  };

  // 导出配置到文件
  const handleExportConfig = () => {
    try {
      const configData = JSON.stringify({
        provider: config.provider,
        apiKey: config.apiKey,
        endpoint: config.endpoint,
        model: config.model,
        exportDate: new Date().toISOString()
      }, null, 2);
      
      const blob = new Blob([configData], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      
      const a = document.createElement('a');
      a.href = url;
      a.download = `stelloracle-config-${new Date().toISOString().slice(0, 10)}.json`;
      document.body.appendChild(a);
      a.click();
      
      setTimeout(() => {
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      }, 0);
      
      playSound('starLight');
    } catch (error) {
      console.error('导出配置失败:', error);
    }
  };

  // 导入配置
  const handleImportConfig = () => {
    if (fileInputRef.current) {
      fileInputRef.current.click();
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    
    const reader = new FileReader();
    reader.onload = (event) => {
      try {
        const importedConfig = JSON.parse(event.target?.result as string);
        
        // 验证导入的配置
        if (importedConfig.apiKey && importedConfig.endpoint) {
          const newConfig = {
            provider: importedConfig.provider || 'openai',
            apiKey: importedConfig.apiKey,
            endpoint: importedConfig.endpoint,
            model: importedConfig.model || config.model
          };
          
          setConfig(newConfig);
          setProvider(newConfig.provider);
          playSound('starReveal');
        } else {
          console.error('导入的配置格式不正确');
        }
      } catch (error) {
        console.error('解析导入的配置失败:', error);
      }
      
      // 重置文件输入，以便可以再次选择同一文件
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    };
    
    reader.readAsText(file);
  };

  // 格式化最后更新时间
  const formatLastUpdated = (dateString?: string) => {
    if (!dateString) return '未知';
    try {
      const date = new Date(dateString);
      return date.toLocaleString('zh-CN');
    } catch (e) {
      return dateString;
    }
  };

  return createPortal(
    <AnimatePresence>
      {isOpen && (
        <motion.div
          className={getMobileModalClasses()}
          style={getMobileModalStyles()}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
        >
          <motion.div
            className="absolute inset-0 bg-black bg-opacity-90 backdrop-blur-md"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={handleClose}
          />

          <motion.div
            className="cosmic-input rounded-lg w-full max-w-md mx-4 z-10"
            initial={{ opacity: 0, y: 20, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.9 }}
            transition={{ type: 'spring', damping: 25 }}
          >
            <div className="p-6">
              {/* Header */}
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-3">
                  <Settings className="w-6 h-6 text-cosmic-accent" />
                  <h2 className="text-xl font-heading text-white">AI Configuration</h2>
                </div>
                <button
                  className="w-8 h-8 rounded-full cosmic-button flex items-center justify-center"
                  onClick={handleClose}
                >
                  <X className="w-4 h-4 text-white" />
                </button>
              </div>
              
              {/* API Provider Selection */}
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-300 mb-2 flex items-center">
                  <Globe className="w-4 h-4 mr-2" />
                  API 提供商
                </label>
                <div className="flex gap-3">
                  <button
                    className={`flex-1 py-2 px-3 rounded-md text-sm flex items-center justify-center gap-2 transition-colors ${
                      provider === 'openai' 
                        ? 'bg-cosmic-accent text-white' 
                        : 'cosmic-button text-gray-300'
                    }`}
                    onClick={() => handleProviderChange('openai')}
                  >
                    OpenAI / 兼容服务
                  </button>
                  <button
                    className={`flex-1 py-2 px-3 rounded-md text-sm flex items-center justify-center gap-2 transition-colors ${
                      provider === 'gemini' 
                        ? 'bg-cosmic-accent text-white' 
                        : 'cosmic-button text-gray-300'
                    }`}
                    onClick={() => handleProviderChange('gemini')}
                  >
                    Google Gemini
                  </button>
                </div>
              </div>

              {/* API Key */}
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-300 mb-2 flex items-center">
                  <Key className="w-4 h-4 mr-2" />
                  API Key
                </label>
                <input
                  ref={apiKeyRef}
                  type="password"
                  className="w-full cosmic-input rounded-md px-3 py-2 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-cosmic-accent"
                  placeholder={provider === 'gemini' ? "Google API Key" : "OpenAI API Key"}
                  value={config.apiKey || ''}
                  onChange={(e) => setConfig({ ...config, apiKey: e.target.value })}
                />
              </div>

              {/* Endpoint */}
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-300 mb-2 flex items-center">
                  <Globe className="w-4 h-4 mr-2" />
                  API Endpoint
                </label>
                <input
                  ref={endpointRef}
                  type="text"
                  className="w-full cosmic-input rounded-md px-3 py-2 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-cosmic-accent"
                  placeholder={
                    provider === 'gemini' 
                      ? "https://generativelanguage.googleapis.com/..." 
                      : "https://api.openai.com/v1/chat/completions"
                  }
                  value={config.endpoint || ''}
                  onChange={(e) => setConfig({ ...config, endpoint: e.target.value })}
                />
              </div>

              {/* Model */}
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-300 mb-2 flex items-center">
                  <Cpu className="w-4 h-4 mr-2" />
                  模型名称
                </label>
                <input
                  ref={modelRef}
                  type="text"
                  className="w-full cosmic-input rounded-md px-3 py-2 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-cosmic-accent"
                  placeholder={provider === 'gemini' ? "gemini-1.5-flash-latest" : "gpt-4o"}
                  value={config.model || ''}
                  onChange={(e) => setConfig({ ...config, model: e.target.value })}
                />
              </div>

              {/* Validation Result */}
              {(isValidating || validationResult) && (
                <div className={`mb-6 p-3 rounded-md flex items-start gap-2 text-sm ${
                  validationResult?.isValid 
                    ? 'bg-green-500 bg-opacity-20 text-green-300' 
                    : 'bg-red-500 bg-opacity-20 text-red-300'
                }`}>
                  {getValidationIcon()}
                  <div>{getValidationMessage()}</div>
                </div>
              )}

              {/* Last Updated */}
              {config._lastUpdated && (
                <div className="mb-6">
                  <button
                    className="text-xs text-gray-400 flex items-center gap-1 hover:text-gray-300 transition-colors"
                    onClick={() => setShowLastUpdated(!showLastUpdated)}
                  >
                    <Clock className="w-3 h-3" />
                    {showLastUpdated 
                      ? `最后更新: ${formatLastUpdated(config._lastUpdated)}` 
                      : '显示最后更新时间'}
                  </button>
                </div>
              )}

              {/* Actions */}
              <div className="flex flex-wrap gap-3">
                <button
                  className="flex-1 py-2 px-4 cosmic-button text-white rounded-md flex items-center justify-center gap-2 transition-colors"
                  onClick={handleValidate}
                  disabled={isValidating}
                >
                  {isValidating ? (
                    <Loader className="w-4 h-4 animate-spin" />
                  ) : (
                    <CheckCircle className="w-4 h-4" />
                  )}
                  验证
                </button>
                <button
                  className="flex-1 py-2 px-4 bg-cosmic-accent hover:bg-cosmic-accent-dark text-white rounded-md flex items-center justify-center gap-2 transition-colors"
                  onClick={handleSave}
                  disabled={isSaving}
                >
                  {isSaving ? (
                    <Loader className="w-4 h-4 animate-spin" />
                  ) : (
                    <Settings className="w-4 h-4" />
                  )}
                  保存
                </button>
              </div>

              {/* Import/Export */}
              <div className="mt-4 flex justify-between">
                <button
                  className="text-sm text-gray-400 flex items-center gap-1 hover:text-gray-300 transition-colors"
                  onClick={handleImportConfig}
                >
                  <Upload className="w-4 h-4" />
                  导入配置
                </button>
                <input
                  ref={fileInputRef}
                  type="file"
                  accept=".json"
                  style={{ display: 'none' }}
                  onChange={handleFileChange}
                />
                <button
                  className="text-sm text-gray-400 flex items-center gap-1 hover:text-gray-300 transition-colors"
                  onClick={handleExportConfig}
                >
                  <Download className="w-4 h-4" />
                  导出配置
                </button>
              </div>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>,
    createTopLevelContainer()
  );
};

export default AIConfigPanel;
```

`staroracle-app_v1/src/components/CollectionButton.tsx`:

```tsx
import React from 'react';
import { motion } from 'framer-motion';
import { BookOpen, Star } from 'lucide-react';
import { useStarStore } from '../store/useStarStore';

interface CollectionButtonProps {
  onClick: () => void;
}

const CollectionButton: React.FC<CollectionButtonProps> = ({ onClick }) => {
  const { constellation } = useStarStore();
  const starCount = constellation.stars.length;

  const handleClick = () => {
    console.log('🔍 CollectionButton internal click triggered!');
    onClick();
  };

  return (
    <motion.button
      className="collection-trigger-btn"
      onClick={handleClick}
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      initial={{ opacity: 0, x: -20 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ delay: 0.5 }}
    >
      <div className="btn-content">
        <div className="btn-icon">
          <BookOpen className="w-5 h-5" />
          {starCount > 0 && (
            <motion.div
              className="star-count-badge"
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              key={starCount}
            >
              {starCount}
            </motion.div>
          )}
        </div>
        <span className="btn-text">Star Collection</span>
      </div>
      
      {/* Floating stars animation */}
      <div className="floating-stars">
        {Array.from({ length: 3 }).map((_, i) => (
          <motion.div
            key={i}
            className="floating-star"
            animate={{
              y: [-5, -15, -5],
              opacity: [0.3, 0.8, 0.3],
              scale: [0.8, 1.2, 0.8],
            }}
            transition={{
              duration: 2,
              repeat: Infinity,
              delay: i * 0.3,
            }}
          >
            <Star className="w-3 h-3" />
          </motion.div>
        ))}
      </div>
    </motion.button>
  );
};

export default CollectionButton;
```

`staroracle-app_v1/src/components/Constellation.tsx`:

```tsx
import React, { useEffect, useState, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import Star from './Star';
import StarRayIcon from './StarRayIcon';

const Constellation: React.FC = () => {
  const { 
    constellation, 
    activeStarId, 
    viewStar, 
    setIsAsking,
    drawInspirationCard,
    pendingStarPosition,
    isLoading
  } = useStarStore();
  const { stars, connections } = constellation;
  const [dimensions, setDimensions] = useState({ width: 0, height: 0 });
  const [mousePos, setMousePos] = useState({ x: 0, y: 0 });
  const [sparkles, setSparkles] = useState<Array<{ id: number; x: number; y: number }>>([]);
  const [lastClickTime, setLastClickTime] = useState(0);
  
  useEffect(() => {
    const updateDimensions = () => {
      setDimensions({
        width: window.innerWidth,
        height: window.innerHeight,
      });
    };
    
    window.addEventListener('resize', updateDimensions);
    updateDimensions();
    
    return () => window.removeEventListener('resize', updateDimensions);
  }, []);
  
  const handleMouseMove = useCallback((e: React.MouseEvent) => {
    setMousePos({ x: e.clientX, y: e.clientY });
  }, []);
  
  const handleStarClick = (id: string) => {
    playSound('starClick');
    viewStar(id);
  };
  
  const createSparkle = (x: number, y: number) => {
    const id = Date.now();
    setSparkles(current => [...current, { id, x, y }]);
    setTimeout(() => {
      setSparkles(current => current.filter(sparkle => sparkle.id !== id));
    }, 1000);
  };
  
  const handleBackgroundClick = (e: React.MouseEvent) => {
    console.log('🌌 Constellation clicked at:', e.clientX, e.clientY);
    console.log('🎯 Click target:', e.target);
    
    // 检查点击是否在按钮区域 - 排除左上角和右上角按钮区域
    const isInButtonArea = (clientX: number, clientY: number) => {
      // 左侧按钮区域 (Collection + Template)
      if (clientX < 200 && clientY < 200) return true;
      // 右侧按钮区域 (Settings)  
      if (clientX > window.innerWidth - 200 && clientY < 200) return true;
      return false;
    };
    
    if (isInButtonArea(e.clientX, e.clientY)) {
      console.log('🚫 Click in button area, ignoring');
      return; // 不处理按钮区域的点击
    }
    
    // If we're currently loading a star, don't allow new interactions
    if (isLoading) return;
    
    if ((e.target as HTMLElement).classList.contains('constellation-area')) {
      console.log('✅ Valid constellation area click');
      const currentTime = Date.now();
      const timeDiff = currentTime - lastClickTime;
      
      const rect = (e.target as HTMLElement).getBoundingClientRect();
      const x = ((e.clientX - rect.left) / rect.width) * 100;
      const y = ((e.clientY - rect.top) / rect.height) * 100;
      
      createSparkle(e.clientX, e.clientY);
      playSound('starClick');
      
      // 检测双击 (300ms内的两次点击)
      if (timeDiff < 300) {
        console.log('🌟 Double click detected - drawing inspiration card');
        // 双击：摘星模式
        drawInspirationCard();
        playSound('starReveal');
      } else {
        // 单击：普通提问模式
        setIsAsking(true, { x, y });
      }
      
      setLastClickTime(currentTime);
    } else {
      console.log('❌ Click not on constellation area');
    }
  };
  
  // 右键点击事件处理 - 显示灵感卡片
  const handleContextMenu = (e: React.MouseEvent) => {
    // If we're currently loading a star, don't allow new interactions
    if (isLoading) return;
    
    e.preventDefault(); // 阻止默认的右键菜单
    console.log('🔍 右键点击事件触发');
    
    if ((e.target as HTMLElement).classList.contains('constellation-area')) {
      const rect = (e.target as HTMLElement).getBoundingClientRect();
      const x = ((e.clientX - rect.left) / rect.width) * 100;
      const y = ((e.clientY - rect.top) / rect.height) * 100;
      
      createSparkle(e.clientX, e.clientY);
      playSound('starReveal');
      
      console.log('🌟 右键点击 - 显示灵感卡片');
      const card = drawInspirationCard();
      console.log('📇 灵感卡片已生成:', card.question);
    }
  };
  
  return (
    <div 
      className="absolute inset-0 overflow-hidden constellation-area"
      onClick={handleBackgroundClick}
      onContextMenu={handleContextMenu}
      onMouseMove={handleMouseMove}
    >
      {/* Hover indicator */}
      <div 
        className="hover-indicator"
        style={{
          left: `${mousePos.x}px`,
          top: `${mousePos.y}px`,
        }}
      />
      
      {/* Loading animation for pending star */}
      {isLoading && pendingStarPosition && (
        <div 
          className="absolute pointer-events-none z-20"
          style={{
            left: `${pendingStarPosition.x}%`,
            top: `${pendingStarPosition.y}%`,
            transform: 'translate(-50%, -50%)'
          }}
        >
          <motion.div
            initial={{ scale: 0, opacity: 0 }}
            animate={{ 
              scale: [0.8, 1.2, 0.8],
              opacity: [0.4, 0.8, 0.4]
            }}
            transition={{
              duration: 2,
              repeat: Infinity,
              ease: "easeInOut"
            }}
            className="flex items-center justify-center"
          >
            <StarRayIcon size={48} animated={true} className="text-cosmic-accent" />
          </motion.div>
        </div>
      )}
      
      {/* Sparkle effects */}
      <AnimatePresence>
        {sparkles.map(sparkle => (
          <motion.div
            key={sparkle.id}
            className="star-sparkle"
            style={{
              left: sparkle.x - 10,
              top: sparkle.y - 10,
            }}
            initial={{ scale: 0, rotate: 0, opacity: 0 }}
            animate={{ scale: 1, rotate: 180, opacity: 1 }}
            exit={{ scale: 0, rotate: 360, opacity: 0 }}
          />
        ))}
      </AnimatePresence>
      
      {/* Star connections - 使用绝对定位的SVG，确保与星星在同一坐标系统 */}
      {dimensions.width > 0 && dimensions.height > 0 && (
        <div className="absolute inset-0 pointer-events-none" style={{ zIndex: 5, overflow: 'visible' }}>
        <svg
          width={dimensions.width}
          height={dimensions.height}
            style={{ 
              position: 'absolute', 
              top: 0, 
              left: 0,
              overflow: 'visible'
            }}
        >
          <defs>
              {connections.map(connection => {
                const fromStar = stars.find(s => s.id === connection.fromStarId);
                const toStar = stars.find(s => s.id === connection.toStarId);
                
                if (!fromStar || !toStar) return null;
                
                // 根据连线标签选择颜色
                const baseColor = (() => {
                  // If the connection belongs to a specific constellation (tag-based), use that tag to determine color
                  if (connection.constellationName) {
                    const tag = connection.constellationName.toLowerCase();
                    
                    // Core Life Areas
                    if (['love', 'romance', 'heart', 'relationship', 'intimacy'].includes(tag)) {
                      return '255, 105, 180'; // Hot Pink
                    }
                    if (['family', 'parents', 'children', 'home', 'roots'].includes(tag)) {
                      return '255, 165, 0'; // Orange
                    }
                    if (['friendship', 'social', 'trust', 'loyalty'].includes(tag)) {
                      return '124, 252, 0'; // Lawn Green
                    }
                    if (['career', 'work', 'profession', 'vocation'].includes(tag)) {
                      return '255, 215, 0'; // Gold
                    }
                    if (['education', 'learning', 'knowledge', 'skills'].includes(tag)) {
                      return '30, 144, 255'; // Dodger Blue
                    }
                    if (['health', 'wellness', 'fitness', 'balance'].includes(tag)) {
                      return '50, 205, 50'; // Lime Green
                    }
                    if (['finance', 'money', 'wealth', 'abundance'].includes(tag)) {
                      return '218, 165, 32'; // Golden Rod
                    }
                    if (['spirituality', 'faith', 'soul', 'divine'].includes(tag)) {
                      return '147, 112, 219'; // Medium Purple
                    }
                    
                    // Inner Experience
                    if (['emotions', 'feelings', 'expression', 'awareness'].includes(tag)) {
                      return '255, 99, 71'; // Tomato
                    }
                    if (['happiness', 'joy', 'fulfillment', 'contentment'].includes(tag)) {
                      return '255, 255, 0'; // Yellow
                    }
                    if (['anxiety', 'fear', 'worry', 'stress'].includes(tag)) {
                      return '70, 130, 180'; // Steel Blue
                    }
                    if (['grief', 'loss', 'sadness', 'mourning'].includes(tag)) {
                      return '75, 0, 130'; // Indigo
                    }
                    
                    // Self Development
                    if (['identity', 'self', 'authenticity', 'values'].includes(tag)) {
                      return '0, 206, 209'; // Dark Turquoise
                    }
                    if (['purpose', 'meaning', 'calling', 'mission'].includes(tag)) {
                      return '138, 43, 226'; // Blue Violet
                    }
                    if (['growth', 'development', 'evolution', 'improvement'].includes(tag)) {
                      return '60, 179, 113'; // Medium Sea Green
                    }
                    if (['resilience', 'strength', 'adaptation', 'recovery'].includes(tag)) {
                      return '178, 34, 34'; // Firebrick
                    }
                    if (['creativity', 'expression', 'imagination', 'innovation'].includes(tag)) {
                      return '255, 140, 0'; // Dark Orange
                    }
                    if (['wisdom', 'insight', 'perspective', 'understanding'].includes(tag)) {
                      return '186, 85, 211'; // Medium Orchid
                    }
                    
                    // Default colors for other tags
                    if (['mindfulness', 'presence', 'awareness'].includes(tag)) {
                      return '240, 230, 140'; // Khaki
                    }
                    if (['change', 'transition', 'transformation'].includes(tag)) {
                      return '0, 191, 255'; // Deep Sky Blue
                    }
                    
                    // If no specific match, use a hash-based color to ensure consistent colors for same tag
                    const hash = tag.split('').reduce((acc, char) => {
                      return acc + char.charCodeAt(0);
                    }, 0);
                    
                    // Generate a pastel color based on the hash
                    const h = hash % 360;
                    const s = 70 + (hash % 20); // 70-90%
                    const l = 65 + (hash % 15); // 65-80%
                    
                    // Convert HSL to RGB
                    const c = (1 - Math.abs(2 * l / 100 - 1)) * s / 100;
                    const x = c * (1 - Math.abs((h / 60) % 2 - 1));
                    const m = l / 100 - c / 2;
                    
                    let r, g, b;
                    if (h < 60) { r = c; g = x; b = 0; }
                    else if (h < 120) { r = x; g = c; b = 0; }
                    else if (h < 180) { r = 0; g = c; b = x; }
                    else if (h < 240) { r = 0; g = x; b = c; }
                    else if (h < 300) { r = x; g = 0; b = c; }
                    else { r = c; g = 0; b = x; }
                    
                    r = Math.round((r + m) * 255);
                    g = Math.round((g + m) * 255);
                    b = Math.round((b + m) * 255);
                    
                    return `${r}, ${g}, ${b}`;
                  }
                  
                  // Fall back to original logic for connections not based on specific constellation
                  if (connection.sharedTags?.includes('love') || connection.sharedTags?.includes('romance')) {
                    return '255, 182, 193'; // 粉色
                  }
                  if (connection.sharedTags?.includes('wisdom') || connection.sharedTags?.includes('purpose')) {
                    return '138, 95, 189'; // 紫色
                  }
                  if (connection.sharedTags?.includes('success') || connection.sharedTags?.includes('career')) {
                    return '255, 215, 0'; // 金色
                  }
                  return '255, 255, 255'; // 白色
                })();
                
                // 计算星星中心的像素坐标
                const fromX = (fromStar.x / 100) * dimensions.width;
                const fromY = (fromStar.y / 100) * dimensions.height;
                const toX = (toStar.x / 100) * dimensions.width;
                const toY = (toStar.y / 100) * dimensions.height;
              
              return (
                  <linearGradient
                    key={connection.id}
                    id={`gradient-${connection.id}`}
                    gradientUnits="userSpaceOnUse"
                    x1={fromX}
                    y1={fromY}
                    x2={toX}
                    y2={toY}
                  >
                  <stop offset="0%" stopColor={`rgba(${baseColor}, 0)`} />
                  <stop offset="25%" stopColor={`rgba(${baseColor}, 0.2)`} />
                  <stop offset="50%" stopColor={`rgba(${baseColor}, 0.6)`} />
                  <stop offset="75%" stopColor={`rgba(${baseColor}, 0.2)`} />
                  <stop offset="100%" stopColor={`rgba(${baseColor}, 0)`} />
                </linearGradient>
              );
            })}
          </defs>
          
          {connections.map((connection, index) => {
            const fromStar = stars.find(s => s.id === connection.fromStarId);
            const toStar = stars.find(s => s.id === connection.toStarId);
            
            if (!fromStar || !toStar) return null;
            
              // 计算星星中心的像素坐标
            const fromX = (fromStar.x / 100) * dimensions.width;
            const fromY = (fromStar.y / 100) * dimensions.height;
            const toX = (toStar.x / 100) * dimensions.width;
            const toY = (toStar.y / 100) * dimensions.height;
            
            const isActive = fromStar.id === activeStarId || toStar.id === activeStarId;
            const connectionStrength = connection.strength || 0.3;
            
            return (
              <g key={connection.id}>
                {/* 背景光晕层 - 最粗，营造氛围 */}
                <motion.line
                  x1={fromX}
                  y1={fromY}
                  x2={toX}
                  y2={toY}
                  stroke={`url(#gradient-${connection.id})`}
                  strokeWidth={isActive ? 6 : Math.max(3, connectionStrength * 5)}
                  filter="blur(3px)"
                  initial={{ 
                    pathLength: 0,
                    opacity: 0 
                  }}
                  animate={{ 
                    pathLength: 1,
                    opacity: isActive 
                      ? [0.2, 0.5, 0.2] 
                      : [0.05, Math.max(0.15, connectionStrength * 0.3), 0.05]
                  }}
                  transition={{ 
                    pathLength: { duration: 2, ease: "easeInOut", delay: index * 0.1 },
                    opacity: { 
                      duration: 4 + Math.random() * 2, 
                      repeat: Infinity, 
                      ease: "easeInOut",
                      delay: index * 0.3
                    }
                  }}
                />
                
                {/* 中间层 - 中等粗细，主要呼吸效果 */}
                <motion.line
                  x1={fromX}
                  y1={fromY}
                  x2={toX}
                  y2={toY}
                  stroke={`url(#gradient-${connection.id})`}
                  strokeWidth={isActive ? 3 : Math.max(1.5, connectionStrength * 2.5)}
                  filter="blur(1px)"
                  initial={{ 
                    pathLength: 0,
                    opacity: 0 
                  }}
                  animate={{ 
                    pathLength: 1,
                    opacity: isActive 
                      ? [0.3, 0.7, 0.3] 
                      : [0.1, Math.max(0.25, connectionStrength * 0.5), 0.1]
                  }}
                  transition={{ 
                    pathLength: { duration: 2.5, ease: "easeInOut", delay: index * 0.15 },
                    opacity: { 
                      duration: 5 + Math.random() * 3, 
                      repeat: Infinity, 
                      ease: "easeInOut",
                      delay: index * 0.4 + 0.5
                    }
                  }}
                />
                
                {/* 核心层 - 最细最亮，精确连接 */}
                <motion.line
                  x1={fromX}
                  y1={fromY}
                  x2={toX}
                  y2={toY}
                  stroke={`url(#gradient-${connection.id})`}
                  strokeWidth={isActive ? 1 : Math.max(0.5, connectionStrength)}
                  initial={{ 
                    pathLength: 0,
                    opacity: 0 
                  }}
                  animate={{ 
                    pathLength: 1,
                    opacity: isActive 
                      ? [0.5, 1, 0.5] 
                      : [0.2, Math.max(0.4, connectionStrength * 0.8), 0.2]
                  }}
                  transition={{ 
                    pathLength: { duration: 3, ease: "easeInOut", delay: index * 0.2 },
                    opacity: { 
                      duration: 6 + Math.random() * 4, 
                      repeat: Infinity, 
                      ease: "easeInOut",
                      delay: index * 0.5 + 1
                    }
                  }}
                />
                
                {/* 激活时的流动光点 */}
                {isActive && (
                  <motion.circle
                    cx={fromX}
                    cy={fromY}
                    r="1.5"
                    fill="rgba(255, 255, 255, 0.9)"
                    initial={{ opacity: 0 }}
                    animate={{ 
                      cx: [fromX, toX, fromX],
                      cy: [fromY, toY, fromY],
                      opacity: [0, 1, 0]
                    }}
                    transition={{
                      duration: 3,
                      repeat: Infinity,
                      ease: "easeInOut"
                    }}
                  />
                )}
              </g>
            );
          })}
        </svg>
        </div>
      )}
      
      {/* Stars */}
      {stars.map(star => {
        const pixelX = (star.x / 100) * dimensions.width;
        const pixelY = (star.y / 100) * dimensions.height;
        const isActive = star.id === activeStarId;
        
        // Find connected stars
        const connectedStars = connections
          .filter(conn => conn.fromStarId === star.id || conn.toStarId === star.id)
          .map(conn => conn.fromStarId === star.id ? conn.toStarId : conn.fromStarId);
        
        const hasStrongConnections = connections.some(
          conn => (conn.fromStarId === star.id || conn.toStarId === star.id) && conn.strength > 0.4
        );
        
        return (
          <Star
            key={star.id}
            x={pixelX}
            y={pixelY}
            size={star.size * (hasStrongConnections ? 1.2 : 1)}
            brightness={star.brightness}
            isSpecial={star.isSpecial || hasStrongConnections}
            isActive={isActive}
            onClick={() => handleStarClick(star.id)}
            tags={star.tags}
            category={star.primary_category} // Updated to use primary_category
            connectionCount={connectedStars.length}
          />
        );
      })}
    </div>
  );
};

export default Constellation;
```

`staroracle-app_v1/src/components/ConstellationSelector.tsx`:

```tsx
import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { createPortal } from 'react-dom';
import { Star, X, Flame, Mountain, Wind, Waves } from 'lucide-react';
import { getAllTemplates, getTemplatesByElement } from '../utils/constellationTemplates';
import { ConstellationTemplate } from '../types';
import { playSound } from '../utils/soundUtils';
import { getMobileModalStyles, getMobileModalClasses, fixIOSZIndex, createTopLevelContainer, hideOtherElements } from '../utils/mobileUtils';
import StarRayIcon from './StarRayIcon';

interface ConstellationSelectorProps {
  isOpen: boolean;
  onClose: () => void;
  onSelectTemplate: (template: ConstellationTemplate) => void;
}

const ConstellationSelector: React.FC<ConstellationSelectorProps> = ({
  isOpen,
  onClose,
  onSelectTemplate
}) => {
  const [selectedElement, setSelectedElement] = useState<'all' | 'fire' | 'earth' | 'air' | 'water'>('all');
  const [restoreElements, setRestoreElements] = useState<(() => void) | null>(null);
  
  const allTemplates = getAllTemplates();
  const filteredTemplates = selectedElement === 'all' 
    ? allTemplates 
    : getTemplatesByElement(selectedElement);

  // 初始化iOS层级修复
  useEffect(() => {
    fixIOSZIndex();
  }, []);

  // 当模态框打开时隐藏其他元素
  useEffect(() => {
    if (isOpen) {
      document.body.classList.add('modal-open');
      const restore = hideOtherElements();
      setRestoreElements(() => restore);
    } else {
      document.body.classList.remove('modal-open');
      if (restoreElements) {
        restoreElements();
        setRestoreElements(null);
      }
    }
    
    return () => {
      document.body.classList.remove('modal-open');
      if (restoreElements) {
        restoreElements();
      }
    };
  }, [isOpen]);

  const handleClose = () => {
    playSound('starClick');
    onClose();
  };

  const handleSelectTemplate = (template: ConstellationTemplate) => {
    playSound('starReveal');
    onSelectTemplate(template);
    onClose();
  };

  const getElementIcon = (element: string) => {
    switch (element) {
      case 'fire': return <Flame className="w-4 h-4" />;
      case 'earth': return <Mountain className="w-4 h-4" />;
      case 'air': return <Wind className="w-4 h-4" />;
      case 'water': return <Waves className="w-4 h-4" />;
      default: return <Star className="w-4 h-4" />;
    }
  };

  const getElementColor = (element: string) => {
    switch (element) {
      case 'fire': return 'text-red-400 border-red-400';
      case 'earth': return 'text-green-400 border-green-400';
      case 'air': return 'text-blue-400 border-blue-400';
      case 'water': return 'text-cyan-400 border-cyan-400';
      default: return 'text-white border-white';
    }
  };

  return createPortal(
    <AnimatePresence>
      {isOpen && (
        <motion.div
          className={getMobileModalClasses()}
          style={getMobileModalStyles()}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
        >
          <motion.div
            className="absolute inset-0 bg-black bg-opacity-90 backdrop-blur-md"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={handleClose}
          />

          <motion.div
            className="cosmic-input rounded-lg w-full max-w-4xl mx-4 z-10 max-h-[90vh] overflow-hidden"
            initial={{ opacity: 0, y: 20, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.9 }}
            transition={{ type: 'spring', damping: 25 }}
          >
            <div className="p-6">
              {/* Header */}
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-3">
                  <StarRayIcon size={24} className="text-cosmic-accent" animated={true} />
                  <h2 className="text-xl font-heading text-white">选择星座模板</h2>
                </div>
                <button
                  className="w-8 h-8 rounded-full cosmic-button flex items-center justify-center"
                  onClick={handleClose}
                >
                  <X className="w-4 h-4 text-white" />
                </button>
              </div>

              {/* Element Filter */}
              <div className="flex gap-2 mb-6 overflow-x-auto">
                {[
                  { key: 'all', label: '全部', icon: <Star className="w-4 h-4" /> },
                  { key: 'fire', label: '火象', icon: <Flame className="w-4 h-4" /> },
                  { key: 'earth', label: '土象', icon: <Mountain className="w-4 h-4" /> },
                  { key: 'air', label: '风象', icon: <Wind className="w-4 h-4" /> },
                  { key: 'water', label: '水象', icon: <Waves className="w-4 h-4" /> }
                ].map(({ key, label, icon }) => (
                  <button
                    key={key}
                    className={`flex items-center gap-2 px-4 py-2 rounded-full border transition-all ${
                      selectedElement === key
                        ? 'bg-cosmic-accent bg-opacity-20 border-cosmic-accent text-cosmic-accent'
                        : 'cosmic-button text-white'
                    }`}
                    onClick={() => setSelectedElement(key as any)}
                  >
                    {icon}
                    <span className="text-sm font-medium">{label}</span>
                  </button>
                ))}
              </div>

              {/* Templates Grid */}
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 max-h-96 overflow-y-auto">
                <AnimatePresence>
                  {filteredTemplates.map((template, index) => (
                    <motion.div
                      key={template.id}
                      className="constellation-template-card"
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -20 }}
                      transition={{ delay: index * 0.1 }}
                      whileHover={{ y: -5 }}
                      onClick={() => handleSelectTemplate(template)}
                    >
                      {/* Template Preview */}
                      <div className="template-preview">
                        <svg className="w-full h-24" viewBox="0 0 100 60">
                          {/* Draw template stars */}
                          {template.stars.map((star, i) => (
                            <g key={i}>
                              <circle
                                cx={50 + star.x * 2}
                                cy={30 + star.y * 2}
                                r={star.size * 0.8}
                                fill={star.isMainStar ? '#8A5FBD' : '#ffffff'}
                                opacity={star.brightness}
                              />
                              {star.isMainStar && (
                                <circle
                                  cx={50 + star.x * 2}
                                  cy={30 + star.y * 2}
                                  r={star.size * 1.2}
                                  fill="none"
                                  stroke="#8A5FBD"
                                  strokeWidth="0.5"
                                  opacity="0.6"
                                />
                              )}
                            </g>
                          ))}
                          
                          {/* Draw template connections */}
                          {template.connections.map((conn, i) => {
                            const fromStar = template.stars.find(s => s.id === conn.fromStarId);
                            const toStar = template.stars.find(s => s.id === conn.toStarId);
                            if (!fromStar || !toStar) return null;
                            
                            return (
                              <line
                                key={i}
                                x1={50 + fromStar.x * 2}
                                y1={30 + fromStar.y * 2}
                                x2={50 + toStar.x * 2}
                                y2={30 + toStar.y * 2}
                                stroke="rgba(255,255,255,0.3)"
                                strokeWidth="0.5"
                              />
                            );
                          })}
                        </svg>
                      </div>

                      {/* Template Info */}
                      <div className="template-info">
                        <div className="flex items-center justify-between mb-2">
                          <h3 className="font-heading text-white text-lg">{template.chineseName}</h3>
                          <div className={`flex items-center gap-1 px-2 py-1 rounded-full border text-xs ${getElementColor(template.element)}`}>
                            {getElementIcon(template.element)}
                            <span>{template.element}</span>
                          </div>
                        </div>
                        
                        <p className="text-sm text-gray-300 mb-3">{template.description}</p>
                        
                        <div className="flex items-center justify-between text-xs text-gray-400">
                          <span>{template.stars.length} 颗星</span>
                          <span>{template.connections.length} 条连线</span>
                        </div>
                      </div>
                    </motion.div>
                  ))}
                </AnimatePresence>
              </div>

              {/* Info */}
              <div className="mt-6 p-4 bg-cosmic-purple bg-opacity-10 border border-cosmic-purple border-opacity-20 rounded-md">
                <p className="text-sm text-gray-300">
                  <strong>提示:</strong> 选择一个星座模板作为你的星空基础。你可以在此基础上继续添加自己的星星，
                  创造独特的个人星座。模板星星会以特殊样式显示，与你后续添加的星星形成美丽的连接。
                </p>
              </div>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>,
    createTopLevelContainer()
  );
};

export default ConstellationSelector;
```

`staroracle-app_v1/src/components/ConversationDrawer.tsx`:

```tsx
import React, { useState, useRef, useEffect } from 'react';
import { Mic, Plus } from 'lucide-react';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import { triggerHapticFeedback } from '../utils/hapticUtils';
import StarRayIcon from './StarRayIcon';
import { Capacitor } from '@capacitor/core';

interface ConversationDrawerProps {
  isOpen: boolean;
  onToggle: () => void;
}

const ConversationDrawer: React.FC<ConversationDrawerProps> = () => {
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [starAnimated, setStarAnimated] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const { addStar, isAsking, setIsAsking } = useStarStore();

  // 监听isAsking状态变化，当用户在星空中点击时自动聚焦输入框
  useEffect(() => {
    if (isAsking && inputRef.current) {
      inputRef.current.focus();
    }
  }, [isAsking]);

  const handleAddClick = () => {
    console.log('Add button clicked');
    // 可以用于打开历史对话或其他功能
  };

  const handleMicClick = () => {
    setIsRecording(!isRecording);
    console.log('Microphone clicked, recording:', !isRecording);
    // TODO: 集成语音识别功能
    // 添加触感反馈（仅原生环境）
    if (Capacitor.isNativePlatform()) {
      triggerHapticFeedback('light');
    }
    playSound('starClick');
  };

  const handleStarClick = () => {
    setStarAnimated(true);
    console.log('Star ray button clicked');
    
    // 如果有输入内容，直接提交
    if (inputValue.trim()) {
      handleSend();
    }
    
    // Reset animation after completion
    setTimeout(() => {
      setStarAnimated(false);
    }, 1000);
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInputValue(e.target.value);
  };

  const handleInputKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSend();
    }
  };

  const handleSend = async () => {
    if (!inputValue.trim() || isLoading) return;
    
    setIsLoading(true);
    const trimmedQuestion = inputValue.trim();
    setInputValue('');
    
    try {
      // 在星空中创建星星
      const newStar = await addStar(trimmedQuestion);
      console.log("✨ 新星星已创建:", newStar.id);
      playSound('starReveal');
    } catch (error) {
      console.error('Error creating star:', error);
    } finally {
      setIsLoading(false);
    }
  };
  
  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSend();
    }
  };

  return (
    <div className="fixed bottom-0 left-0 right-0 z-40 p-4" style={{ paddingBottom: `var(--safe-area-inset-bottom)` }}>
      <div className="w-full max-w-md mx-auto">
        <div className="relative">
          {/* Main container with dark background */}
          <div className="flex items-center bg-gray-900 rounded-full h-12 shadow-lg border border-gray-800">
            
            {/* Plus button - positioned flush left */}
            <button
              type="button"
              onClick={handleAddClick}
              className="flex-shrink-0 w-10 h-10 bg-gray-700 hover:bg-gray-600 rounded-full flex items-center justify-center ml-1 transition-colors duration-200 focus:outline-none"
              disabled={isLoading}
            >
              <Plus className="w-5 h-5 text-white" strokeWidth={2} />
            </button>

            {/* Input field */}
            <input
              ref={inputRef}
              type="text"
              value={inputValue}
              onChange={handleInputChange}
              onKeyPress={handleKeyPress}
              placeholder="询问任何问题"
              className="flex-1 bg-transparent text-white placeholder-gray-400 px-4 py-2 focus:outline-none text-sm font-normal"
              style={{ fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif' }}
              disabled={isLoading}
            />

            {/* Right side icons container */}
            <div className="flex items-center space-x-2 mr-3">
              
              {/* Microphone button */}
              <button
                type="button"
                onClick={handleMicClick}
                className={`p-2 rounded-full transition-colors duration-200 focus:outline-none ${
                  isRecording 
                    ? 'bg-red-600 hover:bg-red-500 text-white' 
                    : 'hover:bg-gray-700 text-gray-300'
                }`}
                disabled={isLoading}
              >
                <Mic className="w-4 h-4" strokeWidth={2} />
              </button>

              {/* Star ray button */}
              <button
                type="button"
                onClick={handleStarClick}
                className="p-2 rounded-full hover:bg-gray-700 text-gray-300 transition-colors duration-200 focus:outline-none"
                disabled={isLoading}
              >
                <StarRayIcon 
                  size={16} 
                  animated={starAnimated || !!inputValue.trim()} 
                  iconColor="#ffffff"
                />
              </button>
              
            </div>
          </div>

          {/* Recording indicator */}
          {isRecording && (
            <div className="absolute -bottom-8 left-1/2 transform -translate-x-1/2">
              <div className="flex items-center space-x-2 text-red-400 text-xs">
                <div className="w-2 h-2 bg-red-500 rounded-full animate-pulse"></div>
                <span>Recording...</span>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default ConversationDrawer;
```

`staroracle-app_v1/src/components/Header.tsx`:

```tsx
import React from 'react';
import StarRayIcon from './StarRayIcon';

const Header: React.FC = () => {
  return (
    <header 
      className="fixed top-0 left-0 right-0 z-30"
      style={{
        paddingTop: `calc(1rem + var(--safe-area-inset-top, 0px))`,
        paddingLeft: `calc(1rem + var(--safe-area-inset-left, 0px))`,
        paddingRight: `calc(1rem + var(--safe-area-inset-right, 0px))`,
        paddingBottom: '1rem',
        height: `calc(4rem + var(--safe-area-inset-top, 0px))` // 固定头部高度
      }}
    >
      <div className="flex justify-center h-full items-center">
        <h1 className="text-xl font-heading text-white flex items-center">
          <StarRayIcon size={18} className="mr-2 text-cosmic-accent" animated={true} />
          <span>星谕</span>
          <span className="ml-2 text-sm opacity-70">(StellOracle)</span>
        </h1>
      </div>
    </header>
  );
};

export default Header;
```

`staroracle-app_v1/src/components/InspirationCard.tsx`:

```tsx
import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { createPortal } from 'react-dom';
import { Sparkles, MessageCircle } from 'lucide-react';
import { InspirationCard as IInspirationCard } from '../utils/inspirationCards';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import { getBookAnswer, getAnswerReflection } from '../utils/bookOfAnswers';
import ConversationDrawer from './ConversationDrawer';
import StarRayIcon from './StarRayIcon';

interface InspirationCardProps {
  card: IInspirationCard;
  onDismiss: () => void;
}

const InspirationCard: React.FC<InspirationCardProps> = ({ card, onDismiss }) => {
  const { addStar } = useStarStore();
  const [isFlipped, setIsFlipped] = useState(false);
  const [bookAnswer, setBookAnswer] = useState('');
  const [answerReflection, setAnswerReflection] = useState('');
  const [inputValue, setInputValue] = useState('');
  const inputRef = useRef<HTMLInputElement>(null);
  
  // 在组件挂载时生成答案，确保答案在整个卡片生命周期内保持不变
  useEffect(() => {
    const answer = getBookAnswer();
    const reflection = getAnswerReflection(answer);
    setBookAnswer(answer);
    setAnswerReflection(reflection);
  }, []);
    
  // 当卡片翻转到背面时，自动聚焦输入框
  useEffect(() => {
    if (isFlipped && inputRef.current) {
      setTimeout(() => {
        inputRef.current?.focus();
      }, 600); // 等待卡片翻转动画完成
    }
  }, [isFlipped]);

  const handleDismiss = () => {
    playSound('starClick');
    onDismiss();
  };

  const handleCardClick = () => {
    setIsFlipped(!isFlipped);
    playSound('starClick');
  };
  
  const handleSendMessage = () => {
    if (inputValue.trim()) {
      // 这里可以处理发送消息的逻辑
      console.log("发送消息:", inputValue);
      // 示例：创建一个新的星星
      addStar(inputValue);
      setInputValue('');
      playSound('starClick');
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  // 为卡片生成唯一ID，用于渐变效果
  const cardId = `insp-${Date.now()}`;

  return createPortal(
    <motion.div
      className="fixed inset-0 flex items-center justify-center"
      style={{ zIndex: 999999 }}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      <motion.div
        className="absolute inset-0 bg-black bg-opacity-70 backdrop-blur-sm"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={handleDismiss}
      />
      
      <motion.div
        className="star-card-container"
        initial={{ opacity: 0, y: 20, scale: 0.8 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ type: "spring", damping: 20 }}
        whileHover={{ y: -5 }}
      >
        <div className="star-card-wrapper">
          <motion.div
            className="star-card"
            animate={{ rotateY: isFlipped ? 180 : 0 }}
            transition={{ duration: 0.6, type: "spring" }}
            onClick={handleCardClick}
          >
            {/* Front Side - Card Design */}
            <div className="star-card-face star-card-front">
              <div className="star-card-bg">
                <div className="star-card-constellation">
                  {/* Star pattern */}
                  <svg className="constellation-svg" viewBox="0 0 200 200">
              <defs>
                      <radialGradient id={`starGlow-${cardId}`} cx="50%" cy="50%" r="50%">
                        <stop offset="0%" stopColor="#ffffff" stopOpacity="0.8"/>
                        <stop offset="100%" stopColor="#ffffff" stopOpacity="0"/>
                </radialGradient>
              </defs>
              
              {/* Background stars */}
                    {Array.from({ length: 12 }).map((_, i) => (
                <motion.circle
                  key={i}
                        cx={20 + (i % 4) * 40 + Math.random() * 20}
                        cy={20 + Math.floor(i / 4) * 40 + Math.random() * 20}
                  r={Math.random() * 1.5 + 0.5}
                  fill="rgba(255,255,255,0.6)"
                  initial={{ opacity: 0.3 }}
                  animate={{ 
                    opacity: [0.3, 0.8, 0.3],
                    scale: [1, 1.2, 1]
                  }}
                  transition={{
                    duration: 2 + Math.random() * 2,
                    repeat: Infinity,
                    delay: Math.random() * 2
                  }}
                />
              ))}
              
                    {/* Main star */}
                    <motion.circle
                      cx="100"
                cy="100"
                      r="8"
                      fill={`url(#starGlow-${cardId})`}
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      transition={{ delay: 0.3, type: "spring" }}
                    />
                    
                    {/* Star rays - 使用星星动画阶段的动画效果 */}
                    {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => (
                      <motion.line
                        key={i}
                        x1="100"
                        y1="100"
                        x2={100 + Math.cos(i * Math.PI / 4) * 40}
                        y2={100 + Math.sin(i * Math.PI / 4) * 40}
                        stroke="#ffffff"
                        strokeWidth="2"
                        initial={{ pathLength: 0, opacity: 0 }}
                        animate={{ 
                          pathLength: 1,
                          opacity: [0, 0.8, 0],
                        }}
                        transition={{
                          duration: 1.5,
                          delay: i * 0.1,
                          repeat: Infinity,
                          repeatDelay: 1,
                        }}
              />
                    ))}
            </svg>
          </div>

                <motion.div
                  className="card-prompt"
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 0.7, y: 0 }}
                  transition={{ delay: 0.5 }}
                >
                  <p className="text-center text-base text-neutral-300 font-normal">
                    翻开卡片，宇宙会回答你
                  </p>
                </motion.div>

                {/* Decorative elements */}
                <div className="star-card-decorations">
                  {Array.from({ length: 6 }).map((_, i) => (
            <motion.div
              key={i}
              className="floating-particle"
              style={{
                left: `${20 + Math.random() * 60}%`,
                top: `${20 + Math.random() * 60}%`,
              }}
              animate={{
                        y: [-5, 5, -5],
                        opacity: [0.3, 0.7, 0.3],
              }}
              transition={{
                duration: 3 + Math.random() * 2,
                repeat: Infinity,
                delay: Math.random() * 2,
              }}
            />
          ))}
                </div>
              </div>
            </div>

            {/* Back Side - Book of Answers */}
            <div className="star-card-face star-card-back">
              <div className="star-card-content flex flex-col h-full">
                {/* 标题 */}
                <motion.div
                  initial={{ opacity: 0, y: -10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.2 }}
                >
                  <h3 className="answer-label text-xl font-semibold text-cosmic-accent text-center mb-6">来自宇宙的答案</h3>
                </motion.div>
                
                {/* 答案部分 - 居中显示 */}
                <div className="answer-section flex-grow flex items-center justify-center px-6">
                  <motion.div
                    className="answer-reveal text-center"
                    initial={{ opacity: 0, scale: 0.9 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: 0.4, type: "spring", damping: 20 }}
                  >
                    <p className="answer-text text-3xl font-bold text-white mb-2 drop-shadow-[0_0_8px_rgba(255,255,255,0.3)]">{bookAnswer}</p>
                  </motion.div>
                </div>
                
                {/* 附言部分 - 放在底部，进一步降低视觉重要性 */}
                <motion.div
                  className="reflection-section mt-auto mb-3 px-4"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 0.45 }}
                  transition={{ delay: 0.6 }}
                >
                  <p className="reflection-text text-[9px] text-neutral-500 italic text-center leading-tight tracking-wide">{answerReflection}</p>
                </motion.div>
                
                {/* 抽屉式输入框 - 直接显示，无需点击按钮 */}
                <motion.div
                  className="card-footer"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.7 }}
                  onClick={(e) => e.stopPropagation()} // 防止点击输入框时触发卡片翻转
                >
                  <motion.div 
                    className="input-ghost-wrapper w-full"
                    initial={{ y: 20, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    transition={{ type: "spring", damping: 20, delay: 0.7 }}
                  >
                    <div className="flex items-center gap-3 relative py-2 px-1">
                      <input
                        ref={inputRef}
                        type="text"
                        className="flex-1 bg-transparent text-white placeholder-neutral-400 outline-none text-sm leading-relaxed border-0 border-b border-neutral-600/50 focus:border-cosmic-accent transition-colors duration-300"
                        placeholder="说说你的困惑吧"
                        value={inputValue}
                        onChange={(e) => setInputValue(e.target.value)}
                        onKeyPress={handleKeyPress}
                      />
                      <motion.button
                        className={`w-7 h-7 rounded-full flex items-center justify-center transition-colors ${
                          inputValue.trim() ? 'bg-cosmic-accent/80 text-white' : 'bg-transparent text-neutral-400'
                        }`}
                        onClick={handleSendMessage}
                        disabled={!inputValue.trim()}
                        whileHover={inputValue.trim() ? { scale: 1.1 } : {}}
                        whileTap={inputValue.trim() ? { scale: 0.95 } : {}}
                      >
                        <StarRayIcon size={14} animated={!!inputValue.trim()} />
                      </motion.button>
                    </div>
                  </motion.div>
                </motion.div>
              </div>
            </div>
          </motion.div>
          
          {/* Hover glow effect */}
          <motion.div
            className="star-card-glow"
            animate={{
              opacity: 0.4,
              scale: 1.05,
            }}
            transition={{ duration: 0.3 }}
          />
        </div>
      </motion.div>
    </motion.div>,
    document.body
  );
};

export default InspirationCard;
```

`staroracle-app_v1/src/components/OracleInput.tsx`:

```tsx
import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { createPortal } from 'react-dom';
import { Plus, Mic } from 'lucide-react';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import StarRayIcon from './StarRayIcon';

const OracleInput: React.FC = () => {
  const { isAsking, setIsAsking, addStar, pendingStarPosition, isLoading } = useStarStore();
  const [question, setQuestion] = useState('');
  const [isRecording, setIsRecording] = useState(false);
  const [starAnimated, setStarAnimated] = useState(false);
  
  const handleCloseInput = () => {
    if (!isLoading) {
      setIsAsking(false);
    }
  };
  
  const handleAddClick = () => {
    console.log('Add button clicked');
    // 可以用于打开历史对话或其他功能
  };

  const handleMicClick = () => {
    setIsRecording(!isRecording);
    console.log('Microphone clicked, recording:', !isRecording);
    // TODO: 集成语音识别功能
  };

  const handleStarClick = () => {
    setStarAnimated(true);
    console.log('Star ray button clicked');
    
    // 如果有输入内容，直接提交
    if (question.trim()) {
      // 创建一个模拟的表单事件
      const fakeEvent = {
        preventDefault: () => {},
      } as React.FormEvent;
      handleSubmit(fakeEvent);
    }
    
    // Reset animation after completion
    setTimeout(() => {
      setStarAnimated(false);
    }, 1000);
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setQuestion(e.target.value);
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSubmit(e as any);
    }
  };
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!question.trim() || isLoading) return;
    
    playSound('starLight');
    
    try {
      // Close the input modal immediately
      setIsAsking(false);
      
      // Add the star (this will trigger the loading animation)
      await addStar(question);
      
      setQuestion('');
      setTimeout(() => {
        playSound('starReveal');
      }, 1000);
    } catch (error) {
      console.error('Error creating star:', error);
    }
  };
  
  return (
    <>
      {/* Question input modal with new dark input bar design */}
      {createPortal(
        <AnimatePresence>
          {isAsking && (
            <motion.div
              className="fixed inset-0 flex items-center justify-center"
              style={{ zIndex: 999999 }}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            >
              <motion.div
                className="absolute inset-0 bg-black bg-opacity-50 backdrop-blur-sm"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                onClick={handleCloseInput}
              />
              
              <motion.div
                className="w-full max-w-md mx-4 z-10"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: 20 }}
              >
                {/* Title */}
                <h2 className="text-2xl font-heading text-white mb-6 text-center">Ask the Stars</h2>
                
                {/* Dark Input Bar */}
                <form onSubmit={handleSubmit}>
                  <div className="relative">
                    {/* Main container with dark background */}
                    <div className="flex items-center bg-gray-900 rounded-full h-12 shadow-lg border border-gray-800">
                      
                      {/* Plus button - positioned flush left */}
                      <button
                        type="button"
                        onClick={handleAddClick}
                        className="flex-shrink-0 w-10 h-10 bg-gray-700 hover:bg-gray-600 rounded-full flex items-center justify-center ml-1 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 focus:ring-offset-gray-900"
                        disabled={isLoading}
                      >
                        <Plus className="w-5 h-5 text-white" strokeWidth={2} />
                      </button>

                      {/* Input field */}
                      <input
                        type="text"
                        value={question}
                        onChange={handleInputChange}
                        onKeyPress={handleKeyPress}
                        placeholder="What wisdom do you seek from the cosmos?"
                        className="flex-1 bg-transparent text-white placeholder-gray-400 px-4 py-2 focus:outline-none text-sm font-normal"
                        style={{ fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif' }}
                        autoFocus
                        disabled={isLoading}
                      />

                      {/* Right side icons container */}
                      <div className="flex items-center space-x-2 mr-3">
                        
                        {/* Microphone button */}
                        <button
                          type="button"
                          onClick={handleMicClick}
                          className={`p-2 rounded-full transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-500 ${
                            isRecording 
                              ? 'bg-red-600 hover:bg-red-500 text-white' 
                              : 'hover:bg-gray-700 text-gray-300'
                          }`}
                          disabled={isLoading}
                        >
                          <Mic className="w-4 h-4" strokeWidth={2} />
                        </button>

                        {/* Star ray submit button */}
                        <motion.button
                          type="button"
                          onClick={handleStarClick}
                          className={`p-2 rounded-full transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-gray-500 ${
                            question.trim() 
                              ? 'hover:bg-cosmic-purple text-cosmic-accent' 
                              : 'hover:bg-gray-700 text-gray-300'
                          }`}
                          disabled={isLoading}
                          whileHover={!isLoading ? { scale: 1.1 } : {}}
                        >
                          {isLoading ? (
                            <StarRayIcon 
                              size={16} 
                              animated={true} 
                              iconColor="#ffffff"
                            />
                          ) : (
                            <StarRayIcon 
                              size={16} 
                              animated={starAnimated || !!question.trim()} 
                              iconColor={question.trim() ? "#9333ea" : "#ffffff"}
                            />
                          )}
                        </motion.button>
                        
                      </div>
                    </div>

                    {/* Recording indicator */}
                    {isRecording && (
                      <div className="absolute -bottom-8 left-1/2 transform -translate-x-1/2">
                        <div className="flex items-center space-x-2 text-red-400 text-xs">
                          <div className="w-2 h-2 bg-red-500 rounded-full animate-pulse"></div>
                          <span>Recording...</span>
                        </div>
                      </div>
                    )}
                  </div>
                </form>

                {/* Cancel button */}
                <div className="flex justify-center mt-6">
                  <button
                    type="button"
                    className="cosmic-button px-6 py-2 rounded-full text-white text-sm"
                    onClick={handleCloseInput}
                    disabled={isLoading}
                  >
                    Cancel
                  </button>
                </div>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>,
        document.body
      )}
      
      {/* Loading animation where the star will appear - keep original */}
      <AnimatePresence>
        {isLoading && pendingStarPosition && (
          <motion.div 
            className="absolute z-20 pointer-events-none"
            style={{ 
              left: `${pendingStarPosition.x}%`, 
              top: `${pendingStarPosition.y}%`,
              transform: 'translate(-50%, -50%)'
            }}
            initial={{ opacity: 0, scale: 0.5 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0 }}
          >
            <div className="w-12 h-12 flex items-center justify-center">
              <StarRayIcon size={48} animated={true} className="text-cosmic-accent animate-pulse" />
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
};

export default OracleInput;
```

`staroracle-app_v1/src/components/Star.tsx`:

```tsx
import React from 'react';
import { motion } from 'framer-motion';

interface StarProps {
  x: number;
  y: number;
  size: number;
  brightness: number;
  isSpecial: boolean;
  isActive: boolean;
  isGrowing?: boolean;
  onClick: () => void;
  tags?: string[];
  category?: string;
  connectionCount?: number;
}

const Star: React.FC<StarProps> = ({
  x,
  y,
  size,
  brightness,
  isSpecial,
  isActive,
  isGrowing = false,
  onClick,
  tags = [],
  category = 'existential',
  connectionCount = 0,
}) => {
  return (
    // 1. 外部定位容器：负责精确定位在坐标系中
    <div
      style={{
        position: 'absolute',
        left: `${x}px`,
        top: `${y}px`,
        transform: 'translate(-50%, -50%)',
        // 使用Flexbox确保内部元素完美居中
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        // 设置一个合理的点击区域
        width: `${size * 1.5}px`,
        height: `${size * 1.5}px`,
        cursor: 'pointer',
        zIndex: isGrowing ? 20 : 10,
      }}
      onClick={onClick}
      title={`${category.replace('_', ' ')} • ${tags.slice(0, 3).join(', ')}`}
    >
      {/* 2. 视觉元素容器：负责星星的外观和动画 */}
      <motion.div
        className={`star-container ${isActive ? 'pulse' : ''} ${isSpecial ? 'special twinkle' : ''}`}
        initial={{ opacity: 0, scale: 0 }}
        animate={{ 
          opacity: isGrowing ? 1 : brightness,
          scale: isGrowing ? 2 : 1,
        }}
        whileHover={{ scale: isGrowing ? 2 : 1.5, opacity: 1 }}
        whileTap={{ scale: 0.9 }}
        style={{
          width: `${size}px`,
          height: `${size}px`,
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
        }}
      >
        {/* 3. 星星核心：实际的星星视觉效果 */}
        <motion.div
          className="star-core"
          style={{
            width: '100%',
            height: '100%',
            backgroundColor: '#fff',
            borderRadius: '50%',
            filter: isActive ? 'blur(0)' : 'blur(1px)',
          }}
        />
        
        {/* 4. 星星辐射线：仅在增长状态显示 */}
        {isGrowing && (
          <svg
            className="star-lines"
            style={{
              position: 'absolute',
              top: '50%',
              left: '50%',
              transform: 'translate(-50%, -50%)',
              width: '200%',
              height: '200%',
            }}
          >
            {[0, 1, 2, 3].map((i) => (
              <motion.line
                key={i}
                x1="50%"
                y1="50%"
                x2={`${50 + Math.cos(i * Math.PI / 2) * 40}%`}
                y2={`${50 + Math.sin(i * Math.PI / 2) * 40}%`}
                stroke="#fff"
                strokeWidth="1"
                initial={{ pathLength: 0, opacity: 0 }}
                animate={{ 
                  pathLength: 1,
                  opacity: [0, 0.8, 0],
                }}
                transition={{
                  duration: 1.5,
                  delay: i * 0.2,
                  repeat: Infinity,
                  repeatDelay: 1,
                }}
              />
            ))}
          </svg>
        )}
      </motion.div>
    </div>
  );
};

export default Star;
```

`staroracle-app_v1/src/components/StarCard.tsx`:

```tsx
import React, { useState, useMemo, useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import { Calendar, Heart } from 'lucide-react';
import { Star as IStar } from '../types';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import StarRayIcon from './StarRayIcon';

// 星星样式类型
const STAR_STYLES = {
  STANDARD: 'standard', // 标准8条光芒
  CROSS: 'cross',       // 十字形
  BURST: 'burst',       // 爆发式
  SPARKLE: 'sparkle',   // 闪烁式
  RINGED: 'ringed',     // 带环星
  // 行星样式
  PLANET_SMOOTH: 'planet_smooth',   // 平滑行星
  PLANET_CRATERS: 'planet_craters', // 陨石坑行星
  PLANET_SEAS: 'planet_seas',       // 海洋行星
  PLANET_DUST: 'planet_dust',       // 尘埃行星
  PLANET_RINGS: 'planet_rings'      // 带环行星
};

// 宇宙色彩主题
const COSMIC_PALETTES = [
  { 
    name: '深空蓝', 
    inner: 'hsl(250, 40%, 20%)', 
    outer: 'hsl(230, 50%, 5%)',
    star: 'hsl(220, 100%, 85%)',
    accent: 'hsl(240, 70%, 70%)'
  },
  { 
    name: '星云紫', 
    inner: 'hsl(280, 50%, 18%)', 
    outer: 'hsl(260, 60%, 4%)',
    star: 'hsl(290, 100%, 85%)',
    accent: 'hsl(280, 70%, 70%)'
  },
  { 
    name: '远古红', 
    inner: 'hsl(340, 45%, 15%)', 
    outer: 'hsl(320, 50%, 5%)',
    star: 'hsl(350, 100%, 85%)',
    accent: 'hsl(340, 70%, 70%)'
  },
  { 
    name: '冰晶蓝', 
    inner: 'hsl(200, 50%, 15%)', 
    outer: 'hsl(220, 60%, 6%)',
    star: 'hsl(190, 100%, 85%)',
    accent: 'hsl(200, 70%, 70%)'
  }
];

interface StarCardProps {
  star: IStar;
  isFlipped?: boolean;
  onFlip?: () => void;
  showActions?: boolean;
  starStyle?: string; // 可选的星星样式
  colorTheme?: number; // 可选的颜色主题索引
  onContextMenu?: (e: React.MouseEvent) => void; // 右键菜单回调
}

const StarCard: React.FC<StarCardProps> = ({ 
  star, 
  isFlipped = false, 
  onFlip,
  showActions = true,
  starStyle,
  colorTheme,
  onContextMenu
}) => {
  const [isHovered, setIsHovered] = useState(false);
  const planetCanvasRef = useRef<HTMLCanvasElement>(null);
  
  // 为每个星星确定一个稳定的样式和颜色主题
  const { style, theme, hasRing, dustCount } = useMemo(() => {
    // 使用星星ID作为随机种子，确保同一个星星总是有相同的样式
    const seed = star.id.split('-')[1] ? parseInt(star.id.split('-')[1]) : Date.now();
    const seedRandom = (min: number, max: number) => {
      const x = Math.sin(seed) * 10000;
      const r = x - Math.floor(x);
      return Math.floor(r * (max - min + 1)) + min;
    };
    
    // 获取所有可能的样式
    const allStyles = Object.values(STAR_STYLES);
    const randomStyle = starStyle || allStyles[seedRandom(0, allStyles.length - 1)];
    const randomTheme = colorTheme !== undefined ? colorTheme : seedRandom(0, 3);
    const randomHasRing = star.isSpecial ? (seedRandom(0, 10) > 6) : false;
    const randomDustCount = seedRandom(5, star.isSpecial ? 20 : 10);
    
    return {
      style: randomStyle,
      theme: randomTheme,
      hasRing: randomHasRing,
      dustCount: randomDustCount
    };
  }, [star.id, star.isSpecial, starStyle, colorTheme]);
  
  // 获取当前颜色主题
  const currentTheme = COSMIC_PALETTES[theme];
  
  // 星星基本颜色（特殊星星使用主题色，普通星星使用白色）
  const starColor = star.isSpecial ? currentTheme.accent : currentTheme.star;
  
  // 随机生成尘埃粒子
  const dustParticles = useMemo(() => {
    return Array.from({ length: dustCount }).map((_, i) => {
      const angle = Math.random() * Math.PI * 2;
      const distance = 30 + Math.random() * 40;
      return {
        id: i,
        x: 100 + Math.cos(angle) * distance,
        y: 100 + Math.sin(angle) * distance,
        size: Math.random() * 1.5 + 0.5,
        opacity: Math.random() * 0.7 + 0.3,
        animationDuration: 2 + Math.random() * 3
      };
    });
  }, [dustCount]);
  
  // 生成星环配置（如果有）
  const ringConfig = useMemo(() => {
    if (!hasRing) return null;
    
    const ringTilt = (Math.random() - 0.5) * 0.8;
    return {
      tilt: ringTilt,
      radiusX: 25,
      radiusY: 25 * 0.35,
      color: starColor,
      lineWidth: 1.5
    };
  }, [hasRing, starColor]);

  // 处理右键点击，显示灵感卡片
  const handleContextMenu = (e: React.MouseEvent) => {
    e.preventDefault();
    if (onContextMenu) {
      onContextMenu(e);
    }
  };

  // 行星绘制函数 - 从star-plantegenerate.html移植
  useEffect(() => {
    // 只有当样式是行星类型且canvas存在时绘制行星
    if (!style.startsWith('planet_') || !planetCanvasRef.current) return;
    
    const canvas = planetCanvasRef.current;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    
    // 设置canvas尺寸 - 提高分辨率，解决模糊和锯齿问题
    const scale = window.devicePixelRatio || 2; // 使用设备像素比或至少2倍
    canvas.width = 200 * scale;
    canvas.height = 200 * scale;
    ctx.scale(scale, scale); // 缩放上下文以匹配更高的分辨率
    
    // 启用抗锯齿
    ctx.imageSmoothingEnabled = true;
    ctx.imageSmoothingQuality = 'high';
    
    // 使用星星ID作为随机种子
    const seed = star.id.split('-')[1] ? parseInt(star.id.split('-')[1]) : Date.now();
    const seedRandom = (min: number, max: number) => {
      const x = Math.sin(seed) * 10000;
      const r = x - Math.floor(x);
      return Math.floor(r * (max - min + 1)) + min;
    };
    
    // 星球绘制工具函数
    const drawPlanet = () => {
      try {
        // 清空画布
        ctx.clearRect(0, 0, 200, 200); // 注意：这里使用逻辑尺寸200x200
        
        // 背景为透明
        ctx.fillStyle = 'rgba(0,0,0,0)';
        ctx.fillRect(0, 0, 200, 200);
        
        // 使用与星星相同的色系逻辑
        // 星星基本颜色（特殊星星使用主题色，普通星星使用白色）
        const planetBaseColor = star.isSpecial ? currentTheme.accent : currentTheme.star;
        
        // 解析HSL颜色值以获取色相、饱和度和亮度
        let hue = 0, saturation = 0, lightness = 70;
        
        try {
          const hslMatch = planetBaseColor.match(/hsl\((\d+),\s*(\d+)%,\s*(\d+)%\)/);
          if (hslMatch && hslMatch.length >= 4) {
            hue = parseInt(hslMatch[1]);
            saturation = parseInt(hslMatch[2]);
            lightness = parseInt(hslMatch[3]);
          }
        } catch (e) {
          console.error('HSL解析错误:', e);
          // 使用默认值
          hue = 0;
          saturation = 0;
          lightness = 70;
        }
        
        // 为行星创建自己的色系，基于星星的颜色
        const baseLightness = Math.max(40, lightness - 20); // 比星星暗一些
        const lightRange = 25 + seedRandom(0, 20);
        const darkL = baseLightness - lightRange / 2;
        const lightL = baseLightness + lightRange / 2;
        
        const palette = { 
          base: `hsl(${hue}, ${saturation * 0.7}%, ${baseLightness}%)`, 
          shadow: `hsl(${hue}, ${saturation * 0.5}%, ${darkL}%)`, 
          highlight: `hsl(${hue}, ${saturation * 0.9}%, ${lightL}%)`,
          glow: planetBaseColor
        };
        
        // 星球半径（canvas中心点为100,100）- 缩小到原来的一半
        const planetRadius = (15 + seedRandom(0, 5)); // 原来是30+seedRandom(0,10)
        const planetX = 100; // 保持在中心位置
        const planetY = 100;
        
        // 星球配置
        const planet = {
          x: planetX,
          y: planetY,
          radius: planetRadius,
          palette: palette,
          shading: {
            lightAngle: seedRandom(0, 628) / 100, // 0 to 2π
            numBands: 5 + seedRandom(0, 5),
            darkL: darkL,
            lightL: lightL
          }
        };
        
        // 是否有行星环
        const hasPlanetRings = style === 'planet_rings' || (style.startsWith('planet_') && seedRandom(0, 10) > 7);
        const ringConfig = hasPlanetRings ? {
          tilt: (seedRandom(0, 100) - 50) / 100 * 0.8,
          radius: planetRadius * 1.6,
          color: palette.base,
          lineWidth: 1 + seedRandom(0, 1) // 减小线宽
        } : null;
        
        // 绘制小星星
        const drawStars = () => {
          ctx.save();
          for (let i = 0; i < 30; i++) {
            const x = Math.random() * 200;
            const y = Math.random() * 200;
            const size = Math.random() * 1.2 + 0.3; // 稍微减小星星大小
            ctx.fillStyle = '#ffffff';
            ctx.globalAlpha = Math.random() * 0.7 + 0.1;
            ctx.fillRect(x, y, size, size);
          }
          ctx.restore();
        };
        
        // 绘制行星光晕 - 参考放射状星星的中心光晕
        const drawPlanetGlow = () => {
          try {
            ctx.save();
            
            // 创建径向渐变
            const gradient = ctx.createRadialGradient(
              planet.x, planet.y, planet.radius * 0.8,
              planet.x, planet.y, planet.radius * 3
            );
            
            // 设置渐变颜色 - 修复可能的颜色格式问题
            const safeGlowColor = palette.glow || 'rgba(255,255,255,0.7)';
            gradient.addColorStop(0, safeGlowColor.replace(')', ', 0.7)').replace('rgb', 'rgba')); // 半透明
            gradient.addColorStop(0.5, safeGlowColor.replace(')', ', 0.3)').replace('rgb', 'rgba')); // 更透明
            gradient.addColorStop(1, 'rgba(0,0,0,0)'); // 完全透明
            
            // 绘制光晕
            ctx.globalCompositeOperation = 'screen'; // 使用screen混合模式增强发光效果
            ctx.fillStyle = gradient;
            ctx.beginPath();
            ctx.arc(planet.x, planet.y, planet.radius * 3, 0, Math.PI * 2);
            ctx.fill();
            
            ctx.restore();
          } catch (e) {
            console.error('绘制光晕错误:', e);
            ctx.restore();
          }
        };
        
        // 绘制星球阴影
        const drawShadow = () => {
          const lightAngle = planet.shading.lightAngle;
          const numBands = planet.shading.numBands;
          const darkL = planet.shading.darkL;
          const lightL = planet.shading.lightL;
          const lightVec = { x: Math.cos(lightAngle), y: Math.sin(lightAngle) };
          const totalOffset = planet.radius * 0.8;
          
          for (let i = 0; i < numBands; i++) {
            const t = i / (numBands - 1);
            const currentL = darkL + t * (lightL - darkL);
            const currentColor = `hsl(${hue}, ${Math.max(0, saturation - 20 + t * 20)}%, ${currentL}%)`;
            const offsetFactor = -1 + 2 * t;
            const offsetX = lightVec.x * totalOffset * offsetFactor * -0.5;
            const offsetY = lightVec.y * totalOffset * offsetFactor * -0.5;
            
            ctx.beginPath();
            ctx.arc(planet.x - offsetX, planet.y - offsetY, planet.radius, 0, Math.PI * 2);
            ctx.fillStyle = currentColor;
            ctx.fill();
          }
        };
        
        // 绘制行星环背面 - 修复椭圆比例问题
        const drawRingBack = () => {
          if (!hasPlanetRings || !ringConfig) return;
          
          ctx.save();
          ctx.translate(planet.x, planet.y);
          ctx.rotate(ringConfig.tilt);
          const radiusX = ringConfig.radius;
          const radiusY = ringConfig.radius * 0.3; // 调整Y轴半径以修复椭圆比例
          
          ctx.beginPath();
          ctx.ellipse(0, 0, radiusX, radiusY, 0, Math.PI, Math.PI * 2);
          ctx.strokeStyle = palette.base;
          ctx.lineWidth = ringConfig.lineWidth;
          ctx.globalAlpha = 0.6;
          ctx.stroke();
          ctx.restore();
        };
        
        // 绘制行星环前面 - 修复椭圆比例问题
        const drawRingFront = () => {
          if (!hasPlanetRings || !ringConfig) return;
          
          ctx.save();
          ctx.translate(planet.x, planet.y);
          ctx.rotate(ringConfig.tilt);
          const radiusX = ringConfig.radius;
          const radiusY = ringConfig.radius * 0.3; // 调整Y轴半径以修复椭圆比例
          
          ctx.beginPath();
          ctx.ellipse(0, 0, radiusX, radiusY, 0, 0, Math.PI);
          ctx.strokeStyle = palette.base;
          ctx.lineWidth = ringConfig.lineWidth;
          ctx.globalAlpha = 0.8;
          ctx.stroke();
          ctx.restore();
        };
        
        // 绘制尘埃
        const drawDust = () => {
          ctx.save();
          ctx.translate(planet.x, planet.y);
          ctx.beginPath();
          ctx.arc(0, 0, planet.radius, 0, 2 * Math.PI);
          ctx.clip();
          
          const numDust = 10 + seedRandom(0, 10); // 减少尘埃数量
          for (let i = 0; i < numDust; i++) {
            const angle = seedRandom(0, 628) / 100;
            const distance = seedRandom(0, Math.floor(planet.radius * 100)) / 100;
            const x = Math.cos(angle) * distance;
            const y = Math.sin(angle) * distance;
            const radius = seedRandom(0, 10) / 10 + 0.3; // 减小尘埃大小
            
            ctx.beginPath();
            ctx.arc(x, y, radius, 0, 2 * Math.PI);
            ctx.fillStyle = palette.highlight;
            ctx.globalAlpha = 0.8;
            ctx.fill();
          }
          ctx.restore();
        };
        
        // 绘制陨石坑
        const drawCraters = () => {
          ctx.save();
          ctx.translate(planet.x, planet.y);
          ctx.beginPath();
          ctx.arc(0, 0, planet.radius, 0, 2 * Math.PI);
          ctx.clip();
          
          const craterCount = 5 + seedRandom(0, 10); // 减少陨石坑数量
          
          for (let i = 0; i < craterCount; i++) {
            const angle = seedRandom(0, 628) / 100;
            const distance = seedRandom(0, Math.floor(planet.radius * 80)) / 100;
            const x = Math.cos(angle) * distance;
            const y = Math.sin(angle) * distance;
            const radius = (seedRandom(0, 6) / 100 + 0.01) * planet.radius;
            
            // 计算陨石坑透视效果
            const distFromPlanetCenter = Math.sqrt(x * x + y * y);
            const MIN_SQUASH = 0.1;
            const relativeDist = Math.min(distFromPlanetCenter / planet.radius, 1.0);
            const squashFactor = Math.max(MIN_SQUASH, Math.sqrt(1.0 - Math.pow(relativeDist, 2)));
            const radiusMajor = radius;
            const radiusMinor = radius * squashFactor;
            const radialAngle = Math.atan2(y, x);
            const rotation = radialAngle + Math.PI / 2;
            
            ctx.beginPath();
            ctx.ellipse(x, y, radiusMajor, radiusMinor, rotation, 0, 2 * Math.PI);
            ctx.fillStyle = seedRandom(0, 10) > 5 ? palette.shadow : palette.highlight;
            ctx.globalAlpha = 0.6;
            ctx.fill();
          }
          
          ctx.restore();
        };
        
        // 添加一些光晕射线效果
        const drawGlowRays = () => {
          if (!star.isSpecial) return; // 只为特殊星星添加射线
          
          try {
            ctx.save();
            ctx.translate(planet.x, planet.y);
            
            const rayCount = 4 + seedRandom(0, 4);
            const baseAngle = seedRandom(0, 100) / 100 * Math.PI;
            
            for (let i = 0; i < rayCount; i++) {
              const angle = baseAngle + (i * Math.PI * 2) / rayCount;
              const length = planet.radius * (2 + seedRandom(0, 20) / 10);
              
              ctx.beginPath();
              ctx.moveTo(0, 0);
              ctx.lineTo(Math.cos(angle) * length, Math.sin(angle) * length);
              
              // 创建线性渐变
              const gradient = ctx.createLinearGradient(0, 0, Math.cos(angle) * length, Math.sin(angle) * length);
              const safeGlowColor = palette.glow || 'rgba(255,255,255,0.9)';
              gradient.addColorStop(0, safeGlowColor.replace(')', ', 0.9)').replace('rgb', 'rgba'));
              gradient.addColorStop(1, 'rgba(0,0,0,0)');
              
              ctx.strokeStyle = gradient;
              ctx.lineWidth = 1 + seedRandom(0, 10) / 10;
              ctx.globalAlpha = 0.3 + seedRandom(0, 5) / 10;
              ctx.stroke();
            }
            
            ctx.restore();
          } catch (e) {
            console.error('绘制光晕射线错误:', e);
            ctx.restore();
          }
        };
        
        // 绘制流程
        // 1. 首先绘制光晕
        drawPlanetGlow();
        
        // 2. 绘制背景星星
        drawStars();
        
        // 3. 如果有行星环，绘制背面部分
        if (hasPlanetRings) {
          drawRingBack();
        }
        
        // 4. 绘制主星球
        ctx.save();
        ctx.beginPath();
        ctx.arc(planet.x, planet.y, planet.radius, 0, 2 * Math.PI);
        ctx.clip();
        drawShadow();
        ctx.restore();
        
        // 5. 根据星球类型绘制不同特征
        if (style === STAR_STYLES.PLANET_CRATERS) {
          drawCraters();
        } else if (style === STAR_STYLES.PLANET_DUST) {
          drawDust();
        }
        
        // 6. 如果有行星环，绘制前部
        if (hasPlanetRings) {
          drawRingFront();
        }
        
        // 7. 为特殊星球添加光晕射线
        drawGlowRays();
      } catch (error) {
        console.error('行星绘制错误:', error);
      }
    };
    
    drawPlanet();
    
  }, [style, star.id, currentTheme, starColor]);

  return (
    <motion.div
      className="star-card-container"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      whileHover={{ y: -5 }}
      onHoverStart={() => setIsHovered(true)}
      onHoverEnd={() => setIsHovered(false)}
      onContextMenu={handleContextMenu}
    >
      <div className="star-card-wrapper">
        <motion.div
          className="star-card"
          animate={{ rotateY: isFlipped ? 180 : 0 }}
          transition={{ duration: 0.6, type: "spring" }}
          onClick={onFlip}
        >
          {/* Front Side - Star Design */}
          <div className="star-card-face star-card-front">
            <div className="star-card-bg"
              style={{
                background: `radial-gradient(circle, ${currentTheme.inner} 0%, ${currentTheme.outer} 100%)`,
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'center', // 确保内容垂直居中
                alignItems: 'center', // 确保内容水平居中
                position: 'relative'
              }}
            >
              <div className="star-card-constellation" style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                position: 'relative',
                flex: '1', // 改为占据剩余空间
                height: '200px', // 固定高度
                width: '100%',
                minHeight: '200px' // 确保最小高度
              }}>
                {/* 渲染行星类型星星 */}
                {style.startsWith('planet_') && (
                  <canvas 
                    ref={planetCanvasRef} 
                    width="200" 
                    height="200" 
                    className="planet-canvas"
                    style={{
                      width: '160px',
                      height: '160px',
                      maxWidth: '160px',
                      maxHeight: '160px',
                      display: 'block', // 确保canvas是块级元素
                      margin: '0 auto' // 水平居中
                    }}
                  />
                )}
                
                {/* 星星模式 - 仅在非行星样式时显示 */}
                {!style.startsWith('planet_') && (
                  <svg className="constellation-svg" viewBox="0 0 200 200">
                    <defs>
                      <radialGradient id={`starGlow-${star.id}`} cx="50%" cy="50%" r="50%">
                        <stop offset="0%" stopColor={starColor} stopOpacity="0.8"/>
                        <stop offset="100%" stopColor={starColor} stopOpacity="0"/>
                      </radialGradient>
                      
                      {/* 添加星环滤镜 */}
                      <filter id={`glow-${star.id}`} x="-50%" y="-50%" width="200%" height="200%">
                        <feGaussianBlur stdDeviation="2" result="blur" />
                        <feComposite in="SourceGraphic" in2="blur" operator="over" />
                      </filter>
                    </defs>
                    
                    {/* 背景星星 */}
                    {Array.from({ length: 20 }).map((_, i) => (
                      <motion.circle
                        key={`bg-star-${i}`}
                        cx={20 + (i % 5) * 40 + Math.random() * 20}
                        cy={20 + Math.floor(i / 5) * 40 + Math.random() * 20}
                        r={Math.random() * 1.5 + 0.5}
                        fill="rgba(255,255,255,0.6)"
                        initial={{ opacity: 0.3 }}
                        animate={{ 
                          opacity: [0.3, 0.8, 0.3],
                          scale: [1, 1.2, 1]
                        }}
                        transition={{
                          duration: 2 + Math.random() * 2,
                          repeat: Infinity,
                          delay: Math.random() * 2
                        }}
                      />
                    ))}
                    
                    {/* 尘埃粒子 */}
                    {dustParticles.map(particle => (
                      <motion.circle
                        key={`dust-${particle.id}`}
                        cx={particle.x}
                        cy={particle.y}
                        r={particle.size}
                        fill={starColor}
                        initial={{ opacity: 0 }}
                        animate={{ 
                          opacity: [0, particle.opacity, 0],
                          cx: [particle.x - 2, particle.x + 2, particle.x - 2],
                          cy: [particle.y - 2, particle.y + 2, particle.y - 2]
                        }}
                        transition={{
                          duration: particle.animationDuration,
                          repeat: Infinity,
                          ease: "easeInOut"
                        }}
                      />
                    ))}
                    
                    {/* 星环（如果有） */}
                    {hasRing && ringConfig && (
                      <>
                        {/* 背面星环 */}
                        <motion.ellipse
                          cx="100"
                          cy="100"
                          rx={ringConfig.radiusX}
                          ry={ringConfig.radiusY}
                          transform={`rotate(${ringConfig.tilt * 180 / Math.PI} 100 100)`}
                          fill="none"
                          stroke={ringConfig.color}
                          strokeWidth={ringConfig.lineWidth}
                          strokeDasharray="1,2"
                          initial={{ opacity: 0 }}
                          animate={{ 
                            opacity: [0.2, 0.5, 0.2],
                            strokeWidth: [ringConfig.lineWidth, ringConfig.lineWidth * 1.5, ringConfig.lineWidth]
                          }}
                          transition={{
                            duration: 4,
                            repeat: Infinity,
                            ease: "easeInOut"
                          }}
                        />
                        
                        {/* 前面星环 */}
                        <motion.path
                          d={`M ${100 - ringConfig.radiusX} ${100} A ${ringConfig.radiusX} ${ringConfig.radiusY} ${ringConfig.tilt * 180 / Math.PI} 0 1 ${100 + ringConfig.radiusX} ${100}`}
                          fill="none"
                          stroke={ringConfig.color}
                          strokeWidth={ringConfig.lineWidth}
                          initial={{ opacity: 0 }}
                          animate={{ 
                            opacity: [0.5, 0.8, 0.5],
                            strokeWidth: [ringConfig.lineWidth, ringConfig.lineWidth * 1.5, ringConfig.lineWidth]
                          }}
                          transition={{
                            duration: 3,
                            repeat: Infinity,
                            ease: "easeInOut"
                          }}
                        />
                      </>
                    )}
                    
                    {/* 主星 */}
                    <motion.circle
                      cx="100"
                      cy="100"
                      r="8"
                      fill={`url(#starGlow-${star.id})`}
                      filter={`url(#glow-${star.id})`}
                      initial={{ scale: 0 }}
                      animate={{ 
                        scale: [1, 1.1, 1],
                        opacity: [0.8, 1, 0.8]
                      }}
                      transition={{ 
                        scale: {
                          duration: 3,
                          repeat: Infinity,
                          ease: "easeInOut"
                        },
                        opacity: {
                          duration: 2,
                          repeat: Infinity,
                          ease: "easeInOut"
                        }
                      }}
                    />
                    
                    {/* 星星光芒 - 根据样式渲染不同类型 */}
                    {style === STAR_STYLES.STANDARD && (
                      // 标准8条光芒
                      [0, 1, 2, 3, 4, 5, 6, 7].map((i) => (
                        <motion.line
                          key={`ray-${i}`}
                          x1="100"
                          y1="100"
                          x2={100 + Math.cos(i * Math.PI / 4) * 40}
                          y2={100 + Math.sin(i * Math.PI / 4) * 40}
                          stroke={starColor}
                          strokeWidth="2"
                          initial={{ pathLength: 0, opacity: 0 }}
                          animate={{ 
                            pathLength: 1,
                            opacity: [0, 0.8, 0],
                          }}
                          transition={{
                            duration: 1.5,
                            delay: i * 0.1,
                            repeat: Infinity,
                            repeatDelay: 1,
                          }}
                        />
                      ))
                    )}
                    
                    {style === STAR_STYLES.CROSS && (
                      // 十字形光芒
                      [0, 1, 2, 3].map((i) => (
                        <motion.rect
                          key={`cross-${i}`}
                          x={100 - (i % 2 === 0 ? 1 : 15)}
                          y={100 - (i % 2 === 1 ? 1 : 15)}
                          width={i % 2 === 0 ? 2 : 30}
                          height={i % 2 === 1 ? 2 : 30}
                          fill={starColor}
                          initial={{ opacity: 0, scale: 0 }}
                          animate={{ 
                            opacity: [0, 0.8, 0],
                            scale: [0, 1, 0],
                            rotate: [0, 90, 180]
                          }}
                          transition={{
                            duration: 2,
                            delay: i * 0.2,
                            repeat: Infinity,
                            repeatDelay: 0.5,
                          }}
                        />
                      ))
                    )}
                    
                    {style === STAR_STYLES.BURST && (
                      // 爆发式光芒
                      Array.from({ length: 12 }).map((_, i) => {
                        const angle = (i * Math.PI * 2) / 12;
                        const length = 20 + Math.random() * 30;
                        return (
                          <motion.line
                            key={`burst-${i}`}
                            x1="100"
                            y1="100"
                            x2={100 + Math.cos(angle) * length}
                            y2={100 + Math.sin(angle) * length}
                            stroke={starColor}
                            strokeWidth={Math.random() * 1.5 + 0.5}
                            initial={{ pathLength: 0, opacity: 0 }}
                            animate={{ 
                              pathLength: [0, 1, 0],
                              opacity: [0, 0.7, 0],
                            }}
                            transition={{
                              duration: 2 + Math.random(),
                              delay: i * 0.05,
                              repeat: Infinity,
                              repeatDelay: Math.random(),
                            }}
                          />
                        );
                      })
                    )}
                    
                    {style === STAR_STYLES.SPARKLE && (
                      // 闪烁式
                      Array.from({ length: 8 }).map((_, i) => {
                        const angle = (i * Math.PI * 2) / 8;
                        const distance = 15 + Math.random() * 20;
                        return (
                          <motion.circle
                            key={`sparkle-${i}`}
                            cx={100 + Math.cos(angle) * distance}
                            cy={100 + Math.sin(angle) * distance}
                            r={Math.random() * 2 + 1}
                            fill={starColor}
                            initial={{ opacity: 0, scale: 0 }}
                            animate={{ 
                              opacity: [0, 0.9, 0],
                              scale: [0, 1, 0]
                            }}
                            transition={{
                              duration: 1 + Math.random(),
                              delay: i * 0.1,
                              repeat: Infinity,
                              repeatDelay: Math.random() * 2,
                            }}
                          />
                        );
                      })
                    )}
                    
                    {style === STAR_STYLES.RINGED && !hasRing && (
                      // 带环星（如果没有实际环）
                      <motion.circle
                        cx="100"
                        cy="100"
                        r="15"
                        fill="none"
                        stroke={starColor}
                        strokeWidth="1"
                        strokeDasharray="1,2"
                        initial={{ opacity: 0 }}
                        animate={{ 
                          opacity: [0.3, 0.6, 0.3],
                          r: [15, 18, 15]
                        }}
                        transition={{
                          duration: 3,
                          repeat: Infinity,
                          ease: "easeInOut"
                        }}
                      />
                    )}
                  </svg>
                )}
              </div>
              
              {/* Card title */}
              <div className="star-card-title">
                <motion.div
                  className="star-type-badge"
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.8 }}
                  style={{
                    backgroundColor: star.isSpecial ? `${currentTheme.accent}30` : 'rgba(255,255,255,0.1)'
                  }}
                >
                  {star.isSpecial ? (
                    <>
                      <StarRayIcon className="w-3 h-3" color={currentTheme.accent} />
                      <span style={{ color: currentTheme.accent }}>Rare Celestial</span>
                    </>
                  ) : (
                    <>
                      <div className="w-3 h-3 rounded-full bg-white opacity-80" />
                      <span>Inner Star</span>
                    </>
                  )}
                </motion.div>
                
                <motion.div
                  className="star-date"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 1 }}
                >
                  <Calendar className="w-3 h-3" />
                  <span>{star.createdAt.toLocaleDateString()}</span>
                </motion.div>
              </div>
              
              {/* Decorative elements */}
              <div className="star-card-decorations">
                {Array.from({ length: 6 }).map((_, i) => (
                  <motion.div
                    key={i}
                    className="floating-particle"
                    style={{
                      left: `${20 + Math.random() * 60}%`,
                      top: `${20 + Math.random() * 60}%`,
                      backgroundColor: starColor,
                    }}
                    animate={{
                      y: [-5, 5, -5],
                      opacity: [0.3, 0.7, 0.3],
                    }}
                    transition={{
                      duration: 3 + Math.random() * 2,
                      repeat: Infinity,
                      delay: Math.random() * 2,
                    }}
                  />
                ))}
              </div>
            </div>
          </div>

          {/* Back Side - Answer */}
          <div className="star-card-face star-card-back">
            <div className="star-card-content">
              <div className="question-section">
                <h3 className="question-label">Your Question</h3>
                <p className="question-text">"{star.question}"</p>
              </div>
              
              <div className="divider">
                <StarRayIcon className="w-4 h-4 text-cosmic-accent" />
              </div>
              
              <div className="answer-section">
                <motion.div
                  className="answer-reveal"
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.3 }}
                >
                  <h3 className="answer-label">星辰的启示</h3>
                <p className="answer-text">{star.answer}</p>
                </motion.div>
              </div>
              
              <motion.div
                className="card-footer"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.6 }}
              >
                <div className="star-stats">
                  <span className="stat">
                    Brightness: {Math.round(star.brightness * 100)}%
                  </span>
                  <span className="stat">
                    Size: {star.size.toFixed(1)}px
                  </span>
                </div>
                <p className="text-center text-sm text-cosmic-accent mt-3">
                  再次点击卡片继续探索星空
                </p>
              </motion.div>
            </div>
          </div>
        </motion.div>
        
        {/* Hover glow effect */}
        <motion.div
          className="star-card-glow"
          animate={{
            opacity: isHovered ? 0.6 : 0,
            scale: isHovered ? 1.05 : 1,
          }}
          transition={{ duration: 0.3 }}
          style={{
            background: isHovered 
              ? `radial-gradient(circle, ${currentTheme.accent}40 0%, transparent 70%)` 
              : 'none'
          }}
        />
      </div>
      
      {/* Action buttons - only shown in collection view */}
      {showActions && (
        <motion.div
          className="star-card-actions"
          initial={{ opacity: 0 }}
          animate={{ opacity: isHovered ? 1 : 0 }}
          transition={{ duration: 0.2 }}
        >
          <button className="action-btn favorite">
            <Heart className="w-4 h-4" />
          </button>
          <button className="action-btn flip" onClick={onFlip}>
            <StarRayIcon className="w-4 h-4" />
          </button>
        </motion.div>
      )}
    </motion.div>
  );
};

export default StarCard;
```

`staroracle-app_v1/src/components/StarCollection.tsx`:

```tsx
import React, { useState, useMemo, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { createPortal } from 'react-dom';
import { X, Grid, List, Search, Filter, Star as StarIcon } from 'lucide-react';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import { getMobileModalStyles, getMobileModalClasses, fixIOSZIndex, createTopLevelContainer, hideOtherElements } from '../utils/mobileUtils';
import StarCard from './StarCard';

// 星星样式类型 - 与StarCard组件中的定义保持一致
const STAR_STYLES = {
  STANDARD: 'standard', // 标准8条光芒
  CROSS: 'cross',       // 十字形
  BURST: 'burst',       // 爆发式
  SPARKLE: 'sparkle',   // 闪烁式
  RINGED: 'ringed',     // 带环星
  // 行星样式
  PLANET_SMOOTH: 'planet_smooth',   // 平滑行星
  PLANET_CRATERS: 'planet_craters', // 陨石坑行星
  PLANET_SEAS: 'planet_seas',       // 海洋行星
  PLANET_DUST: 'planet_dust',       // 尘埃行星
  PLANET_RINGS: 'planet_rings'      // 带环行星
};

interface StarCollectionProps {
  isOpen: boolean;
  onClose: () => void;
}

const StarCollection: React.FC<StarCollectionProps> = ({ isOpen, onClose }) => {
  const { constellation, drawInspirationCard } = useStarStore();
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState<'all' | 'special' | 'recent'>('all');
  const [flippedCards, setFlippedCards] = useState<Set<string>>(new Set());
  const [restoreElements, setRestoreElements] = useState<(() => void) | null>(null);

  // 初始化iOS层级修复
  useEffect(() => {
    fixIOSZIndex();
  }, []);

  // 当模态框打开时隐藏其他元素
  useEffect(() => {
    if (isOpen) {
      document.body.classList.add('modal-open');
      const restore = hideOtherElements();
      setRestoreElements(() => restore);
    } else {
      document.body.classList.remove('modal-open');
      if (restoreElements) {
        restoreElements();
        setRestoreElements(null);
      }
    }
    
    return () => {
      document.body.classList.remove('modal-open');
      if (restoreElements) {
        restoreElements();
      }
    };
  }, [isOpen]);

  // 为每个星星生成样式映射
  const starStyleMap = useMemo(() => {
    const map = new Map();
    constellation.stars.forEach(star => {
      // 使用星星ID作为随机种子
      const seed = star.id.split('-')[1] ? parseInt(star.id.split('-')[1]) : Date.now();
      const seedRandom = (min: number, max: number) => {
        const x = Math.sin(seed) * 10000;
        const r = x - Math.floor(x);
        return Math.floor(r * (max - min + 1)) + min;
      };
      
      // 获取所有可能的样式
      const allStyles = Object.values(STAR_STYLES);
      // 随机选择样式和颜色主题
      const styleIndex = seedRandom(0, allStyles.length - 1);
      const colorTheme = seedRandom(0, 3);
      
      map.set(star.id, {
        style: allStyles[styleIndex],
        theme: colorTheme
      });
    });
    return map;
  }, [constellation.stars]);

  const handleClose = () => {
    playSound('starClick');
    onClose();
  };

  const handleCardFlip = (starId: string) => {
    playSound('starClick');
    setFlippedCards(prev => {
      const newSet = new Set(prev);
      if (newSet.has(starId)) {
        newSet.delete(starId);
      } else {
        newSet.add(starId);
      }
      return newSet;
    });
  };

  // 处理右键点击，显示灵感卡片
  const handleContextMenu = (e: React.MouseEvent) => {
    e.preventDefault();
    playSound('starReveal');
    const card = drawInspirationCard();
    console.log('📇 灵感卡片已生成:', card.question);
  };

  // Filter stars based on search and filter criteria
  const filteredStars = constellation.stars.filter(star => {
    const matchesSearch = star.question.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         star.answer.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesFilter = filterType === 'all' || 
                         (filterType === 'special' && star.isSpecial) ||
                         (filterType === 'recent' && 
                          (Date.now() - star.createdAt.getTime()) < 7 * 24 * 60 * 60 * 1000);
    
    return matchesSearch && matchesFilter;
  });

  return createPortal(
    <AnimatePresence>
      {isOpen && (
        <motion.div
          className={getMobileModalClasses()}
          style={getMobileModalStyles()}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onContextMenu={handleContextMenu}
        >
          {/* Backdrop */}
          <motion.div
            className="absolute inset-0 bg-black bg-opacity-90 backdrop-blur-md"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={handleClose}
          />

          {/* Collection Panel */}
          <motion.div
            className="star-collection-panel"
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            transition={{ type: 'spring', damping: 25 }}
          >
            {/* Header */}
            <div className="collection-header">
              <div className="header-left">
                <StarIcon className="w-6 h-6 text-cosmic-accent" />
                <h2 className="collection-title">Star Collection</h2>
                <span className="star-count">{filteredStars.length} stars</span>
              </div>
              
              <button
                className="close-btn"
                onClick={handleClose}
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Controls */}
            <div className="collection-controls">
              <div className="search-bar">
                <Search className="w-4 h-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search your stars..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="search-input"
                />
              </div>
              
              <div className="control-buttons">
                <select
                  value={filterType}
                  onChange={(e) => setFilterType(e.target.value as any)}
                  className="filter-select"
                >
                  <option value="all">All Stars</option>
                  <option value="special">Special Stars</option>
                  <option value="recent">Recent (7 days)</option>
                </select>
                
                <div className="view-toggle">
                  <button
                    className={`view-btn ${viewMode === 'grid' ? 'active' : ''}`}
                    onClick={() => setViewMode('grid')}
                  >
                    <Grid className="w-4 h-4" />
                  </button>
                  <button
                    className={`view-btn ${viewMode === 'list' ? 'active' : ''}`}
                    onClick={() => setViewMode('list')}
                  >
                    <List className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>

            {/* Star Cards */}
            <div className={`collection-content ${viewMode}`}>
              <AnimatePresence>
                {filteredStars.map((star, index) => {
                  const styleConfig = starStyleMap.get(star.id) || { style: 'standard', theme: 0 };
                  return (
                    <motion.div
                      key={star.id}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -20 }}
                      transition={{ delay: index * 0.1 }}
                    >
                      <StarCard
                        star={star}
                        isFlipped={flippedCards.has(star.id)}
                        onFlip={() => handleCardFlip(star.id)}
                        starStyle={styleConfig.style}
                        colorTheme={styleConfig.theme}
                        onContextMenu={handleContextMenu}
                      />
                    </motion.div>
                  );
                })}
              </AnimatePresence>
              
              {filteredStars.length === 0 && (
                <motion.div
                  className="empty-state"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                >
                  <StarIcon className="w-12 h-12 text-gray-400 mb-4" />
                  <p className="text-gray-400">No stars found matching your criteria</p>
                </motion.div>
              )}
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>,
    createTopLevelContainer()
  );
};

export default StarCollection;
```

`staroracle-app_v1/src/components/StarDetail.tsx`:

```tsx
import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { createPortal } from 'react-dom';
import { X, Share2, Save, Tag, Heart } from 'lucide-react';
import { useStarStore } from '../store/useStarStore';
import { playSound } from '../utils/soundUtils';
import StarRayIcon from './StarRayIcon';
import { getMainTagSuggestions } from '../utils/aiTaggingUtils';

const StarDetail: React.FC = () => {
  const { 
    constellation, 
    activeStarId, 
    hideStarDetail,
    updateStarTags
  } = useStarStore();
  
  const activeStar = constellation.stars.find(star => star.id === activeStarId);

  const [editingTags, setEditingTags] = useState(false);
  const [currentTags, setCurrentTags] = useState<string[]>([]);
  const [newTag, setNewTag] = useState('');
  const [tagSuggestions, setTagSuggestions] = useState<string[]>([]);
  
  const handleClose = () => {
    playSound('starClick');
    hideStarDetail();
  };
  
  const handleShare = () => {
    playSound('starClick');
    // TODO: 实现分享功能
    console.log('分享功能将在这里实现');
  };
  
  const handleSave = () => {
    playSound('starClick');
    // TODO: 实现保存到星图功能
    console.log('保存到星图功能将在这里实现');
  };
  
  // 开始编辑标签时初始化
  const startEditingTags = () => {
    if (activeStar) {
      setCurrentTags([...activeStar.tags]);
      setEditingTags(true);
      // 根据预定义的标签系统加载建议
      setTagSuggestions(getMainTagSuggestions());
    }
  };
  
  // 保存编辑后的标签
  const saveTagChanges = () => {
    if (activeStar) {
      updateStarTags(activeStar.id, currentTags);
      setEditingTags(false);
    }
  };
  
  // 添加新标签
  const addTag = (tag: string) => {
    const normalizedTag = tag.trim().toLowerCase();
    if (normalizedTag && !currentTags.some(t => t.toLowerCase() === normalizedTag)) {
      setCurrentTags([...currentTags, normalizedTag]);
      setNewTag('');
    }
  };
  
  // 移除标签
  const removeTag = (tagToRemove: string) => {
    setCurrentTags(currentTags.filter(tag => tag !== tagToRemove));
  };
  
  // 用户输入时筛选建议
  const filterSuggestions = (input: string) => {
    const filtered = getMainTagSuggestions().filter(
      tag => tag.toLowerCase().includes(input.toLowerCase())
    );
    setTagSuggestions(filtered.slice(0, 10)); // 限制为10个建议
  };
  
  // 处理新标签输入变化
  const handleTagInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setNewTag(value);
    filterSuggestions(value);
  };
  
  const getCategoryColor = (category: string) => {
    const colors = {
      'relationships': '#FF69B4',
      'personal_growth': '#9370DB',
      'career_and_purpose': '#FFD700',  // 从'life_direction'更新
      'emotional_wellbeing': '#98FB98', // 从'wellbeing'更新
      'material': '#FFA500',
      'creative': '#FF6347',
      'philosophy_and_existence': '#87CEEB', // 从'existential'更新
      'creativity_and_passion': '#FF6347', // 添加新类别
      'daily_life': '#FFA500', // 添加新类别
    };
    return colors[category as keyof typeof colors] || '#fff';
  };
  
  if (!activeStar) return null;
  
  // 查找相连的星星
  const connectedStars = constellation.connections
    .filter(conn => conn.fromStarId === activeStarId || conn.toStarId === activeStarId)
    .map(conn => {
      const connectedStarId = conn.fromStarId === activeStarId ? conn.toStarId : conn.fromStarId;
      const connectedStar = constellation.stars.find(s => s.id === connectedStarId);
      return { star: connectedStar, connection: conn };
    })
    .filter(item => item.star);
  
  return createPortal(
    <AnimatePresence>
      {activeStarId && activeStar && (
        <motion.div
          className="fixed inset-0 flex items-center justify-center"
          style={{ zIndex: 999999 }}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
        >
          <motion.div
            className="absolute inset-0 bg-black bg-opacity-70 backdrop-blur-sm"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={handleClose}
          />
          
          <motion.div
            className="oracle-card rounded-lg w-full max-w-lg mx-4 overflow-hidden z-10"
            initial={{ opacity: 0, y: 20, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.9 }}
            transition={{ type: 'spring', damping: 25 }}
          >
            {/* 星星图像 */}
            <div className="relative">
              <img
                src={activeStar.imageUrl}
                alt="宇宙视觉"
                className="w-full h-48 object-cover"
              />
              
              {/* 关闭按钮 */}
              <button 
                className="absolute top-2 right-2 bg-black bg-opacity-50 rounded-full p-1"
                onClick={handleClose}
              >
                <X className="w-5 h-5 text-white" />
              </button>
              
              {/* 类别标签 */}
              <div 
                className="absolute top-2 left-2 rounded-full px-3 py-1 text-xs font-semibold"
                style={{ 
                  backgroundColor: `${getCategoryColor(activeStar.primary_category)}20`,
                  border: `1px solid ${getCategoryColor(activeStar.primary_category)}60`,
                  color: getCategoryColor(activeStar.primary_category)
                }}
              >
                {activeStar.primary_category.replace('_', ' ').toUpperCase()}
              </div>
              
              {/* 特殊星星指示器 */}
              {activeStar.isSpecial && (
                <div className="absolute top-2 right-12 bg-cosmic-purple bg-opacity-70 rounded-full px-2 py-1 text-xs">
                  ✨ 稀有天体事件
                </div>
              )}
            </div>
            
            <div className="p-6">
              {/* 问题 */}
              <h3 className="text-lg text-gray-300 mb-2 italic">
                "{activeStar.question}"
              </h3>
              
              {/* 神谕回应 */}
              <p className="text-xl font-heading text-white mb-4">
                {activeStar.answer}
              </p>
              
              {/* 标签部分 */}
              <div className="mb-4">
                <div className="flex items-center gap-2 mb-2">
                  <Tag className="w-4 h-4 text-cosmic-accent" />
                  <span className="text-sm font-semibold text-cosmic-accent">主题</span>
                  
                  {!editingTags && (
                    <button 
                      className="ml-auto text-blue-400 hover:text-blue-300 text-sm"
                      onClick={startEditingTags}
                    >
                      编辑标签
                    </button>
                  )}
                </div>
                
                {!editingTags ? (
                  <div className="flex flex-wrap gap-2">
                    {activeStar.tags.map(tag => (
                      <span
                        key={tag}
                        className="px-2 py-1 bg-cosmic-purple bg-opacity-20 border border-cosmic-purple border-opacity-30 rounded-full text-xs text-white"
                      >
                        {tag}
                      </span>
                    ))}
                  </div>
                ) : (
                  <div>
                    <div className="flex flex-wrap gap-2 mb-3">
                      {currentTags.map(tag => (
                        <div key={tag} className="bg-blue-900 bg-opacity-40 rounded-full px-3 py-1 text-sm flex items-center">
                          <span className="text-blue-300">{tag}</span>
                          <button 
                            className="ml-2 text-gray-400 hover:text-white"
                            onClick={() => removeTag(tag)}
                          >
                            &times;
                          </button>
                        </div>
                      ))}
                      {currentTags.length === 0 && (
                        <span className="text-gray-500 text-sm italic">添加标签以创建星座</span>
                      )}
                    </div>
                    
                    <div className="flex mb-3">
                      <input
                        type="text"
                        value={newTag}
                        onChange={handleTagInputChange}
                        placeholder="添加新标签..."
                        className="flex-grow bg-gray-800 text-white px-3 py-2 rounded-l-md focus:outline-none focus:ring-1 focus:ring-blue-500"
                      />
                      <button 
                        onClick={() => addTag(newTag)}
                        className="bg-blue-700 hover:bg-blue-600 text-white px-3 py-1 rounded-r-md"
                      >
                        添加
                      </button>
                    </div>
                    
                    {tagSuggestions.length > 0 && (
                      <div className="bg-gray-800 rounded-md p-2 mb-3">
                        <p className="text-gray-400 text-xs mb-2">推荐标签：</p>
                        <div className="flex flex-wrap gap-2">
                          {tagSuggestions.map(suggestion => (
                            <button
                              key={suggestion}
                              onClick={() => addTag(suggestion)}
                              disabled={currentTags.some(t => t.toLowerCase() === suggestion.toLowerCase())}
                              className={`text-xs px-2 py-1 rounded-full ${
                                currentTags.some(t => t.toLowerCase() === suggestion.toLowerCase())
                                  ? 'bg-gray-700 text-gray-500 cursor-not-allowed'
                                  : 'bg-gray-700 hover:bg-gray-600 text-white'
                              }`}
                            >
                              {suggestion}
                            </button>
                          ))}
                        </div>
                      </div>
                    )}
                    
                    <div className="flex justify-end gap-2">
                      <button 
                        onClick={() => setEditingTags(false)}
                        className="bg-gray-700 hover:bg-gray-600 text-white px-3 py-1 rounded-md"
                      >
                        取消
                      </button>
                      <button 
                        onClick={saveTagChanges}
                        className="bg-green-700 hover:bg-green-600 text-white px-3 py-1 rounded-md"
                      >
                        保存更改
                      </button>
                    </div>
                  </div>
                )}
              </div>
              
              {/* 相连的星星 */}
              {connectedStars.length > 0 && (
                <div className="mb-4">
                  <div className="flex items-center gap-2 mb-2">
                    <StarRayIcon size={16} />
                    <span className="text-sm font-semibold text-cosmic-accent">相连的星星</span>
                  </div>
                  <div className="space-y-2">
                    {connectedStars.slice(0, 3).map(({ star, connection }) => (
                      <div 
                        key={star!.id}
                        className="flex items-center justify-between p-2 bg-cosmic-navy bg-opacity-30 rounded-md"
                      >
                        <div className="flex-1">
                          <p className="text-sm text-white truncate">"{star!.question}"</p>
                          <p className="text-xs text-gray-400">
                            共享：{connection.sharedTags?.join('、') || '相似能量'}
                          </p>
                        </div>
                        <div className="text-xs text-cosmic-accent font-semibold">
                          {Math.round(connection.strength * 100)}%
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
              
              {/* 情感基调 */}
              <div className="mb-4">
                <div className="flex items-center gap-2 mb-1">
                  <Heart className="w-4 h-4 text-cosmic-accent" />
                  <span className="text-sm font-semibold text-cosmic-accent">情感基调</span>
                </div>
                <span className="text-sm text-gray-300 capitalize">
                  {activeStar.emotional_tone && activeStar.emotional_tone.length > 0 
                    ? activeStar.emotional_tone.join('、') 
                    : '中性'}
                </span>
              </div>
              
              {/* 日期 */}
              <p className="text-sm text-gray-400 mb-4">
                照亮于 {activeStar.createdAt.toLocaleDateString(undefined, { 
                  year: 'numeric', 
                  month: 'long', 
                  day: 'numeric' 
                })}
              </p>
              
              {/* 操作按钮 */}
              <div className="flex justify-between">
                <button
                  className="cosmic-button rounded-md px-3 py-2 flex items-center"
                  onClick={handleSave}
                >
                  <Save className="w-4 h-4 mr-2" />
                  <span>保存到星图</span>
                </button>
                
                <button
                  className="cosmic-button rounded-md px-3 py-2 flex items-center"
                  onClick={handleShare}
                >
                  <Share2 className="w-4 h-4 mr-2" />
                  <span>分享星语</span>
                </button>
              </div>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>,
    document.body
  );
};

export default StarDetail;
```

`staroracle-app_v1/src/components/StarRayIcon.tsx`:

```tsx
import React from 'react';

// StarRayIcon组件接口 - 按照demo版本设计
interface StarRayIconProps {
  size?: number;
  animated?: boolean;
  iconColor?: string;
  className?: string;
  color?: string; // 保持向后兼容
  isSpecial?: boolean; // 保持向后兼容
}

const StarRayIcon: React.FC<StarRayIconProps> = ({ 
  size = 20, 
  animated = false, 
  iconColor = "#ffffff",
  className = "",
  color, // 向后兼容参数
  isSpecial = false // 向后兼容参数
}) => {
  // 优先使用iconColor参数，然后是color参数，最后是默认值
  const finalColor = iconColor || color || (isSpecial ? "#FFD700" : "#ffffff");
  
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={`star-ray-icon ${className}`}
    >
      {/* Center circle */}
      {animated ? (
        <circle
          cx="12"
          cy="12"
          r="2"
          fill={finalColor}
          className="animate-pulse"
        />
      ) : (
        <circle cx="12" cy="12" r="2" fill={finalColor} />
      )}
      
      {/* Eight rays */}
      {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => {
        const angle = (i * 45) * (Math.PI / 180); // Convert to radians
        const startX = 12 + Math.cos(angle) * 3;
        const startY = 12 + Math.sin(angle) * 3;
        const endX = 12 + Math.cos(angle) * 8;
        const endY = 12 + Math.sin(angle) * 8;
        
        return animated ? (
          <line
            key={i}
            x1={startX}
            y1={startY}
            x2={endX}
            y2={endY}
            stroke={finalColor}
            strokeWidth="2"
            strokeLinecap="round"
            className="animate-ray"
            style={{
              animation: `rayExpand 0.5s ease-out ${0.1 + i * 0.05}s both`,
              transformOrigin: '12px 12px'
            }}
          />
        ) : (
          <line
            key={i}
            x1={startX}
            y1={startY}
            x2={endX}
            y2={endY}
            stroke={finalColor}
            strokeWidth="2"
            strokeLinecap="round"
          />
        );
      })}
      
      {/* CSS Animation styles - 内联样式来确保动画正常工作 */}
      <style jsx>{`
        @keyframes rayExpand {
          0% {
            stroke-dasharray: 5;
            stroke-dashoffset: 5;
          }
          100% {
            stroke-dasharray: 5;
            stroke-dashoffset: 0;
          }
        }
        .animate-ray {
          stroke-dasharray: 5;
          stroke-dashoffset: 0;
        }
      `}</style>
    </svg>
  );
};

export default StarRayIcon; 
```

`staroracle-app_v1/src/components/StarryBackground.tsx`:

```tsx
import React, { useEffect, useRef, useState } from 'react';

interface StarryBackgroundProps {
  starCount?: number;
}

interface BackgroundStar {
  x: number;
  y: number;
  size: number;
  opacity: number;
  speed: number;
  twinkleSpeed: number;
  twinklePhase: number;
  pulseSize: number;
  pulseSpeed: number;
}

interface Nebula {
  x: number;
  y: number;
  radius: number;
  color: string;
  speed: number;
  pulsePhase: number;
}

const StarryBackground: React.FC<StarryBackgroundProps> = ({ starCount = 100 }) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [mousePos, setMousePos] = useState({ x: 0, y: 0 });
  
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    
    // Set canvas dimensions
    const resizeCanvas = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    };
    
    window.addEventListener('resize', resizeCanvas);
    resizeCanvas();
    
    // Create stars with enhanced properties
    const stars: BackgroundStar[] = Array.from({ length: starCount }).map(() => ({
      x: Math.random() * canvas.width,
      y: Math.random() * canvas.height,
      size: Math.random() * 2 + 0.5, // 恢复原版小星星：0.5-2.5px
      opacity: Math.random() * 0.8 + 0.2, // 恢复原版透明度：0.2-1.0
      speed: Math.random() * 0.05 + 0.01,
      twinkleSpeed: Math.random() * 0.01 + 0.003,
      twinklePhase: Math.random() * Math.PI * 2,
      pulseSize: Math.random() * 0.5 + 0.5,
      pulseSpeed: Math.random() * 0.002 + 0.001,
    }));
    
    // Create nebula clouds with pulsing effect
    const nebulae: Nebula[] = Array.from({ length: 5 }).map(() => ({
      x: Math.random() * canvas.width,
      y: Math.random() * canvas.height,
      radius: Math.random() * 200 + 100,
      color: [
        `rgba(88, 101, 242, ${Math.random() * 0.1 + 0.05})`, // 恢复原版低透明度
        `rgba(93, 71, 119, ${Math.random() * 0.1 + 0.05})`,
        `rgba(44, 83, 100, ${Math.random() * 0.1 + 0.05})`,
      ][Math.floor(Math.random() * 3)],
      speed: Math.random() * 0.02 + 0.005,
      pulsePhase: Math.random() * Math.PI * 2,
    }));
    
    // Mouse move handler for interactive effects
    const handleMouseMove = (e: MouseEvent) => {
      setMousePos({ x: e.clientX, y: e.clientY });
    };
    
    canvas.addEventListener('mousemove', handleMouseMove);
    
    // Animation loop
    let animationFrameId: number;
    
    const render = (time: number) => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      
      // Draw nebulae with pulsing effect
      nebulae.forEach(nebula => {
        const pulseScale = Math.sin(time * 0.001 + nebula.pulsePhase) * 0.2 + 1;
        const currentRadius = nebula.radius * pulseScale;
        
        const gradient = ctx.createRadialGradient(
          nebula.x, nebula.y, 0,
          nebula.x, nebula.y, currentRadius
        );
        
        gradient.addColorStop(0, nebula.color);
        gradient.addColorStop(1, 'rgba(0, 0, 0, 0)');
        
        ctx.fillStyle = gradient;
        ctx.beginPath();
        ctx.arc(nebula.x, nebula.y, currentRadius, 0, Math.PI * 2);
        ctx.fill();
        
        // Move nebula
        nebula.x += Math.sin(time * 0.0001) * nebula.speed;
        nebula.y += Math.cos(time * 0.0001) * nebula.speed;
        
        // Wrap around edges
        if (nebula.x < -currentRadius) nebula.x = canvas.width + currentRadius;
        if (nebula.x > canvas.width + currentRadius) nebula.x = -currentRadius;
        if (nebula.y < -currentRadius) nebula.y = canvas.height + currentRadius;
        if (nebula.y > canvas.height + currentRadius) nebula.y = -currentRadius;
      });
      
      // Draw stars with enhanced effects
      stars.forEach(star => {
        // Calculate distance to mouse for interactive glow
        const dx = mousePos.x - star.x;
        const dy = mousePos.y - star.y;
        const distance = Math.sqrt(dx * dx + dy * dy);
        const mouseInfluence = Math.max(0, 1 - distance / 200);
        
        // Calculate twinkling and pulsing effects
        const twinkle = Math.sin(time * star.twinkleSpeed + star.twinklePhase) * 0.3 + 0.7;
        const pulse = Math.sin(time * star.pulseSpeed) * star.pulseSize + 1;
        
        // Combine all effects for final opacity and size
        const finalOpacity = star.opacity * twinkle * (1 + mouseInfluence * 0.5);
        const finalSize = star.size * pulse * (1 + mouseInfluence);
        
        // Draw star core
        ctx.fillStyle = `rgba(255, 255, 255, ${finalOpacity})`;
        ctx.beginPath();
        ctx.arc(star.x, star.y, finalSize, 0, Math.PI * 2);
        ctx.fill();
        
        // Draw star glow
        if (mouseInfluence > 0) {
          const gradient = ctx.createRadialGradient(
            star.x, star.y, 0,
            star.x, star.y, finalSize * 4
          );
          gradient.addColorStop(0, `rgba(255, 255, 255, ${mouseInfluence * 0.3})`);
          gradient.addColorStop(1, 'rgba(255, 255, 255, 0)');
          
          ctx.fillStyle = gradient;
          ctx.beginPath();
          ctx.arc(star.x, star.y, finalSize * 4, 0, Math.PI * 2);
          ctx.fill();
        }
        
        // Move star
        star.y += star.speed;
        
        // Wrap around bottom edge
        if (star.y > canvas.height) {
          star.y = 0;
          star.x = Math.random() * canvas.width;
        }
      });
      
      animationFrameId = requestAnimationFrame(render);
    };
    
    animationFrameId = requestAnimationFrame(render);
    
    return () => {
      window.removeEventListener('resize', resizeCanvas);
      canvas.removeEventListener('mousemove', handleMouseMove);
      cancelAnimationFrame(animationFrameId);
    };
  }, [starCount]);
  
  return (
    <canvas
      ref={canvasRef}
      className="fixed top-0 left-0 w-full h-full -z-10 pointer-events-none"
    />
  );
};

export default StarryBackground;
```

`staroracle-app_v1/src/components/TemplateButton.tsx`:

```tsx
import React from 'react';
import { motion } from 'framer-motion';
import { Star } from 'lucide-react';
import { useStarStore } from '../store/useStarStore';
import StarRayIcon from './StarRayIcon';

interface TemplateButtonProps {
  onClick: () => void;
}

const TemplateButton: React.FC<TemplateButtonProps> = ({ onClick }) => {
  const { hasTemplate, templateInfo } = useStarStore();

  const handleClick = () => {
    onClick();
  };

  return (
    <motion.button
      className="template-trigger-btn"
      onClick={handleClick}
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ delay: 0.5 }}
    >
      <div className="btn-content">
        <div className="btn-icon">
          <StarRayIcon size={20} animated={false} />
          {hasTemplate && (
            <motion.div
              className="template-badge"
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
            >
              ✨
            </motion.div>
          )}
        </div>
        <div className="btn-text-container">
          <span className="btn-text">
            {hasTemplate ? '更换星座' : '选择星座'}
          </span>
          {hasTemplate && templateInfo && (
            <span className="template-name">
              {templateInfo.name}
            </span>
          )}
        </div>
      </div>
      
      {/* Floating stars animation */}
      <div className="floating-stars">
        {Array.from({ length: 4 }).map((_, i) => (
          <motion.div
            key={i}
            className="floating-star"
            animate={{
              y: [-5, -15, -5],
              opacity: [0.3, 0.8, 0.3],
              scale: [0.8, 1.2, 0.8],
            }}
            transition={{
              duration: 2.5,
              repeat: Infinity,
              delay: i * 0.4,
            }}
          >
            <Star className="w-3 h-3" />
          </motion.div>
        ))}
      </div>
    </motion.button>
  );
};

export default TemplateButton;
```

`staroracle-app_v1/src/index.css`:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --font-heading: 'Cinzel', serif;
  --font-body: 'Cormorant Garamond', serif;
  /* iOS安全区域变量 */
  --safe-area-inset-top: env(safe-area-inset-top, 0px);
  --safe-area-inset-right: env(safe-area-inset-right, 0px);
  --safe-area-inset-bottom: env(safe-area-inset-bottom, 0px);
  --safe-area-inset-left: env(safe-area-inset-left, 0px);
}

/* 移动端触摸优化 */
* {
  -webkit-tap-highlight-color: transparent;
  -webkit-touch-callout: none;
  /* -webkit-user-select: none;  暂时移除，可能影响点击 */
  /* user-select: none; 暂时移除，可能影响点击 */
}

/* 禁用双击缩放 */
input, textarea, button, select {
  touch-action: manipulation;
}

/* 全局禁用缩放和滚动 */
html {
  overflow: hidden;
  position: fixed;
  width: 100%;
  height: 100%;
}

body {
  overflow: hidden;
  position: fixed;
  width: 100%;
  height: 100%;
  /* touch-action: pan-x pan-y; 移除触摸限制进行调试 */
}

html, body, #root {
  height: 100%;
  width: 100%;
  margin: 0;
  padding: 0;
  overflow: hidden;
}

/* 移动端特有的层级修复 */
@supports (-webkit-touch-callout: none) {
  /* iOS专用修复 */
  .mobile-modal-fix {
    position: fixed !important;
    z-index: 999999 !important;
    top: 0 !important;
    left: 0 !important;
    right: 0 !important;
    bottom: 0 !important;
    -webkit-transform: translateZ(0);
    transform: translateZ(0);
    -webkit-backface-visibility: hidden;
    backface-visibility: hidden;
  }
  
  /* 强制硬件加速 */
  .modal-hardware-acceleration {
    -webkit-transform: translate3d(0, 0, 0);
    transform: translate3d(0, 0, 0);
    -webkit-perspective: 1000px;
    perspective: 1000px;
  }
}

/* 最高优先级的模态框容器 */
#top-level-modals {
  position: fixed !important;
  top: 0 !important;
  left: 0 !important;
  right: 0 !important;
  bottom: 0 !important;
  z-index: 2147483647 !important;
  pointer-events: none !important;
}

#top-level-modals > * {
  pointer-events: auto !important;
}

/* iOS WebView特殊修复 */
@media screen and (max-width: 768px) {
  /* 移除过于激进的全局隐藏规则，改为更精确的控制 */
  body.modal-open #top-level-modals,
  body.modal-open #top-level-modals * {
    visibility: visible !important;
  }
}

body {
  font-family: var(--font-body);
  color: #f8f9fa;
  background-color: #000;
}

h1, h2, h3, h4, h5, h6 {
  font-family: var(--font-heading);
}

.cosmic-bg {
  background: radial-gradient(ellipse at bottom, #1B2735 0%, #090A0F 100%);
}

.star {
  position: absolute;
  background-color: #fff;
  border-radius: 50%;
  filter: blur(1px);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.star:hover {
  filter: blur(0);
  box-shadow: 0 0 15px rgba(255, 255, 255, 0.8),
              0 0 30px rgba(255, 255, 255, 0.6),
              0 0 45px rgba(255, 255, 255, 0.4);
}

.star.special:hover {
  box-shadow: 0 0 15px rgba(138, 95, 189, 0.8),
              0 0 30px rgba(138, 95, 189, 0.6),
              0 0 45px rgba(138, 95, 189, 0.4);
}

.cosmic-input {
  background: rgba(13, 18, 30, 0.7);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.cosmic-button {
  background: rgba(88, 101, 242, 0.2);
  backdrop-filter: blur(4px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  min-height: 48px;
  min-width: 48px;
}

.cosmic-button:hover {
  background: rgba(88, 101, 242, 0.4);
  border: 1px solid rgba(255, 255, 255, 0.2);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(88, 101, 242, 0.3);
}

.cosmic-button:active {
  transform: translateY(0);
}

.oracle-card {
  background: rgba(13, 18, 30, 0.7);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 4px 30px rgba(0, 0, 0, 0.1);
}

.star-image {
  border-radius: 50%;
  overflow: hidden;
  box-shadow: 0 0 20px rgba(255, 255, 255, 0.3);
}

/* Star Card Styles */
.star-card-container {
  position: relative;
  width: 280px;
  height: 400px;
  margin: 16px;
}

.star-card-wrapper {
  position: relative;
  width: 100%;
  height: 100%;
  perspective: 1000px;
}

.star-card {
  position: relative;
  width: 100%;
  height: 100%;
  transform-style: preserve-3d;
  cursor: pointer;
}

.star-card-face {
  position: absolute;
  width: 100%;
  height: 100%;
  backface-visibility: hidden;
  border-radius: 16px;
  overflow: hidden;
}

.star-card-front {
  background: linear-gradient(135deg, 
    rgba(13, 18, 30, 0.9) 0%, 
    rgba(27, 39, 53, 0.9) 50%, 
    rgba(44, 83, 100, 0.9) 100%
  );
  border: 1px solid rgba(138, 95, 189, 0.3);
}

.star-card-back {
  background: linear-gradient(135deg, 
    rgba(27, 39, 53, 0.95) 0%, 
    rgba(13, 18, 30, 0.95) 100%
  );
  border: 1px solid rgba(255, 255, 255, 0.2);
  transform: rotateY(180deg);
}

.star-card-bg {
  position: relative;
  width: 100%;
  height: 100%;
  padding: 24px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.star-card-constellation {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

.constellation-svg {
  width: 160px;
  height: 160px;
  filter: drop-shadow(0 0 10px rgba(255, 255, 255, 0.3));
  display: block;
  margin: 0 auto;
}

.star-card-title {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.star-type-badge {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background: rgba(138, 95, 189, 0.2);
  border: 1px solid rgba(138, 95, 189, 0.3);
  border-radius: 20px;
  font-size: 12px;
  color: #fff;
  width: fit-content;
}

.star-date {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: rgba(255, 255, 255, 0.6);
}

.star-card-decorations {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.floating-particle {
  position: absolute;
  width: 4px;
  height: 4px;
  background: rgba(255, 255, 255, 0.6);
  border-radius: 50%;
  filter: blur(0.5px);
}

.star-card-content {
  padding: 24px;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.question-section, .answer-section {
  flex: 1;
}

.question-label, .answer-label {
  font-family: var(--font-heading);
  font-size: 14px;
  color: rgba(138, 95, 189, 1);
  margin-bottom: 8px;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.question-text {
  font-size: 16px;
  color: rgba(255, 255, 255, 0.9);
  line-height: 1.4;
  font-style: italic;
}

.answer-text {
  font-size: 15px;
  color: #fff;
  line-height: 1.5;
  font-family: var(--font-body);
}

.divider {
  display: flex;
  justify-content: center;
  align-items: center;
  margin: 16px 0;
  opacity: 0.6;
}

.card-footer {
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.star-stats {
  display: flex;
  justify-content: space-between;
  font-size: 11px;
  color: rgba(255, 255, 255, 0.5);
}

.star-card-glow {
  position: absolute;
  inset: -4px;
  background: linear-gradient(135deg, 
    rgba(138, 95, 189, 0.3) 0%, 
    rgba(88, 101, 242, 0.3) 100%
  );
  border-radius: 20px;
  filter: blur(8px);
  z-index: -1;
}

.star-card-actions {
  position: absolute;
  top: 12px;
  right: 12px;
  display: flex;
  gap: 8px;
  z-index: 10;
}

.action-btn {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.action-btn:hover {
  background: rgba(138, 95, 189, 0.3);
  transform: scale(1.1);
}

/* Collection Panel Styles */
.star-collection-panel {
  width: 90vw;
  max-width: 1200px;
  height: 85vh;
  background: rgba(13, 18, 30, 0.95);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 20px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.collection-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24px 32px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(27, 39, 53, 0.5);
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.collection-title {
  font-family: var(--font-heading);
  font-size: 24px;
  color: #fff;
  margin: 0;
}

.star-count {
  padding: 4px 12px;
  background: rgba(138, 95, 189, 0.2);
  border: 1px solid rgba(138, 95, 189, 0.3);
  border-radius: 12px;
  font-size: 12px;
  color: rgba(255, 255, 255, 0.8);
}

.close-btn {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.close-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  transform: scale(1.05);
}

.collection-controls {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 32px;
  gap: 16px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.search-bar {
  position: relative;
  flex: 1;
  max-width: 300px;
}

.search-bar svg {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
}

.search-input {
  width: 100%;
  padding: 10px 12px 10px 40px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  color: #fff;
  font-size: 14px;
}

.search-input::placeholder {
  color: rgba(255, 255, 255, 0.4);
}

.search-input:focus {
  outline: none;
  border-color: rgba(138, 95, 189, 0.5);
  box-shadow: 0 0 0 2px rgba(138, 95, 189, 0.2);
}

.control-buttons {
  display: flex;
  align-items: center;
  gap: 12px;
}

.filter-select {
  padding: 8px 12px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 6px;
  color: #fff;
  font-size: 14px;
}

.filter-select:focus {
  outline: none;
  border-color: rgba(138, 95, 189, 0.5);
}

.view-toggle {
  display: flex;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 6px;
  overflow: hidden;
}

.view-btn {
  padding: 8px 12px;
  background: rgba(255, 255, 255, 0.05);
  border: none;
  color: rgba(255, 255, 255, 0.6);
  transition: all 0.2s ease;
}

.view-btn.active {
  background: rgba(138, 95, 189, 0.3);
  color: #fff;
}

.view-btn:hover {
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
}

.collection-content {
  flex: 1;
  overflow-y: auto;
  padding: 24px 32px;
}

.collection-content.grid {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 24px;
}

.collection-content.list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.collection-content.list .star-card-container {
  width: 100%;
  height: 120px;
  margin: 0;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 200px;
  text-align: center;
}

/* Collection Button Styles */
.collection-trigger-btn {
  position: relative;
  padding: 16px 24px;
  min-height: 48px;
  min-width: 48px;
  background: rgba(13, 18, 30, 0.8);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(138, 95, 189, 0.3);
  border-radius: 12px;
  color: #fff;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  overflow: hidden;
}

.collection-trigger-btn:hover {
  background: rgba(138, 95, 189, 0.2);
  border-color: rgba(138, 95, 189, 0.5);
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(138, 95, 189, 0.3);
}

.btn-content {
  display: flex;
  align-items: center;
  gap: 8px;
  position: relative;
  z-index: 2;
}

.btn-icon {
  position: relative;
}

.star-count-badge {
  position: absolute;
  top: -8px;
  right: -8px;
  width: 18px;
  height: 18px;
  background: rgba(138, 95, 189, 0.9);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 10px;
  font-weight: bold;
  color: #fff;
}

.btn-text {
  font-size: 14px;
  font-weight: 500;
}

.floating-stars {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 1;
}

.floating-star {
  position: absolute;
  color: rgba(138, 95, 189, 0.6);
}

.floating-star:nth-child(1) { top: 20%; left: 15%; }
.floating-star:nth-child(2) { top: 60%; right: 20%; }
.floating-star:nth-child(3) { bottom: 25%; left: 50%; }

/* Template Button Styles */
.template-trigger-btn {
  position: relative;
  padding: 16px 24px;
  min-height: 48px;
  min-width: 48px;
  background: rgba(13, 18, 30, 0.8);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 215, 0, 0.3);
  border-radius: 12px;
  color: #fff;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  overflow: hidden;
  min-width: 160px;
}

.template-trigger-btn:hover {
  background: rgba(255, 215, 0, 0.2);
  border-color: rgba(255, 215, 0, 0.5);
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(255, 215, 0, 0.3);
}

.template-badge {
  position: absolute;
  top: -8px;
  right: -8px;
  width: 18px;
  height: 18px;
  background: rgba(255, 215, 0, 0.9);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 10px;
  color: #000;
}

.btn-text-container {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.template-name {
  font-size: 11px;
  color: rgba(255, 215, 0, 0.8);
  font-weight: 400;
}

/* Constellation Template Card Styles */
.constellation-template-card {
  background: rgba(13, 18, 30, 0.8);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 16px;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.constellation-template-card:hover {
  background: rgba(138, 95, 189, 0.1);
  border-color: rgba(138, 95, 189, 0.3);
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(138, 95, 189, 0.2);
}

.template-preview {
  background: rgba(0, 0, 0, 0.3);
  border-radius: 8px;
  padding: 12px;
  margin-bottom: 12px;
}

.template-info h3 {
  margin: 0 0 8px 0;
}

.template-info p {
  margin: 0 0 12px 0;
}

@keyframes twinkle {
  0% { opacity: 0.3; transform: scale(1); }
  50% { opacity: 1; transform: scale(1.2); }
  100% { opacity: 0.3; transform: scale(1); }
}

@keyframes pulse {
  0% { transform: scale(1); opacity: 1; }
  50% { transform: scale(1.1); opacity: 0.8; }
  100% { transform: scale(1); opacity: 1; }
}

@keyframes float {
  0% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
  100% { transform: translateY(0); }
}

@keyframes sparkle {
  0% { transform: scale(0) rotate(0deg); opacity: 0; }
  50% { transform: scale(1) rotate(180deg); opacity: 1; }
  100% { transform: scale(0) rotate(360deg); opacity: 0; }
}

.pulse {
  animation: pulse 2s infinite ease-in-out;
}

.twinkle {
  animation: twinkle 3s infinite ease-in-out;
}

.float {
  animation: float 6s infinite ease-in-out;
}

.constellation-area {
  cursor: crosshair;
}

.constellation-area::before {
  content: '';
  position: fixed;
  width: 300px;
  height: 300px;
  border-radius: 50%;
  background: radial-gradient(circle, 
    rgba(138, 95, 189, 0.15) 0%,
    rgba(138, 95, 189, 0.1) 30%,
    transparent 70%
  );
  transform: translate(-50%, -50%);
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.3s ease;
  z-index: 1;
}

.constellation-area:hover::before {
  opacity: 1;
}

.star-sparkle {
  position: absolute;
  width: 20px;
  height: 20px;
  background: rgba(255, 255, 255, 0.8);
  clip-path: polygon(50% 0%, 61% 35%, 98% 35%, 68% 57%, 79% 91%, 50% 70%, 21% 91%, 32% 57%, 2% 35%, 39% 35%);
  animation: sparkle 1s ease-in-out forwards;
  pointer-events: none;
}

.hover-indicator {
  position: fixed;
  width: 300px;
  height: 300px;
  border-radius: 50%;
  background: radial-gradient(circle,
    rgba(138, 95, 189, 0.15) 0%,
    rgba(138, 95, 189, 0.1) 30%,
    transparent 70%
  );
  transform: translate(-50%, -50%);
  pointer-events: none;
  z-index: 1;
  opacity: 0;
  transition: opacity 0.3s ease;
}

.constellation-area:hover .hover-indicator {
  opacity: 1;
}

/* Conversation Dialog Styles */
.conversation-dialog {
  width: 90vw;
  max-width: 600px;
  height: 70vh;
  max-height: 600px;
  background: rgba(13, 18, 30, 0.95);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.conversation-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(27, 39, 53, 0.5);
}

.conversation-messages {
  flex: 1;
  overflow-y: auto;
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.message {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.message.user {
  align-items: flex-end;
}

.message.assistant {
  align-items: flex-start;
}

.message-content {
  max-width: 80%;
}

.user-message {
  background: rgba(138, 95, 189, 0.2);
  border: 1px solid rgba(138, 95, 189, 0.3);
  border-radius: 16px 16px 4px 16px;
  padding: 12px 16px;
}

.user-message p {
  color: #fff;
  margin: 0;
  line-height: 1.4;
}

.assistant-message {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px 16px 16px 4px;
  padding: 12px 16px;
  display: flex;
  align-items: flex-start;
  gap: 8px;
}

.message-icon {
  color: rgba(138, 95, 189, 1);
  margin-top: 2px;
  flex-shrink: 0;
}

.assistant-message p {
  color: #fff;
  margin: 0;
  line-height: 1.4;
  flex: 1;
}

.message-time {
  font-size: 11px;
  color: rgba(255, 255, 255, 0.4);
  margin: 0 16px;
}

.conversation-input {
  padding: 20px 24px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(27, 39, 53, 0.3);
}

.conversation-textarea {
  width: 100%;
  padding: 12px 16px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  color: #fff;
  font-size: 14px;
  line-height: 1.4;
  resize: none;
  font-family: inherit;
}

.conversation-textarea::placeholder {
  color: rgba(255, 255, 255, 0.4);
}

.conversation-textarea:focus {
  outline: none;
  border-color: rgba(138, 95, 189, 0.5);
  box-shadow: 0 0 0 2px rgba(138, 95, 189, 0.2);
}

.conversation-textarea {
  overflow-y: auto;
  scrollbar-width: thin;
  scrollbar-color: rgba(138, 95, 189, 0.3) transparent;
}

.conversation-textarea::-webkit-scrollbar {
  width: 4px;
}

.conversation-textarea::-webkit-scrollbar-track {
  background: transparent;
}

.conversation-textarea::-webkit-scrollbar-thumb {
  background: rgba(138, 95, 189, 0.3);
  border-radius: 2px;
}

.conversation-btn {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  color: #fff;
}

.conversation-btn.primary {
  background: rgba(138, 95, 189, 0.3);
  border-color: rgba(138, 95, 189, 0.5);
}

.conversation-btn.primary:hover:not(:disabled) {
  background: rgba(138, 95, 189, 0.5);
  transform: scale(1.05);
}

.conversation-btn.secondary {
  background: rgba(255, 215, 0, 0.2);
  border-color: rgba(255, 215, 0, 0.4);
}

.conversation-btn.secondary:hover:not(:disabled) {
  background: rgba(255, 215, 0, 0.3);
  transform: scale(1.05);
}

.conversation-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.conversation-hint {
  margin-top: 8px;
  text-align: center;
}

/* Inspiration Card Styles */
.inspiration-card {
  width: 90vw;
  max-width: 480px;
  background: rgba(13, 18, 30, 0.95);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(138, 95, 189, 0.3);
  border-radius: 20px;
  overflow: hidden;
  position: relative;
}

.inspiration-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.category-badge {
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.inspiration-card-content {
  position: relative;
  padding: 32px 24px;
  min-height: 300px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 24px;
}

.inspiration-bg {
  position: absolute;
  inset: 0;
  opacity: 0.6;
  pointer-events: none;
}

.inspiration-question {
  position: relative;
  z-index: 2;
}

.question-text {
  font-family: var(--font-heading);
  font-size: 20px;
  color: #fff;
  text-align: center;
  line-height: 1.3;
  margin: 0;
}

.inspiration-reflection {
  position: relative;
  z-index: 2;
}

.reflection-text {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.8);
  text-align: center;
  line-height: 1.5;
  margin: 0;
  font-style: italic;
}

.inspiration-tags {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 8px;
  position: relative;
  z-index: 2;
}

.inspiration-tag {
  padding: 4px 12px;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 12px;
  font-size: 11px;
  color: rgba(255, 255, 255, 0.8);
  text-transform: lowercase;
}

.inspiration-card-actions {
  display: flex;
  justify-content: space-between;
  padding: 20px 24px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(27, 39, 53, 0.3);
}

.inspiration-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s ease;
  border: 1px solid;
}

.inspiration-btn.dismiss {
  background: rgba(255, 255, 255, 0.05);
  border-color: rgba(255, 255, 255, 0.2);
  color: rgba(255, 255, 255, 0.8);
}

.inspiration-btn.dismiss:hover {
  background: rgba(255, 255, 255, 0.1);
  transform: translateY(-1px);
}

.inspiration-btn.explore {
  background: rgba(138, 95, 189, 0.2);
  border-color: rgba(138, 95, 189, 0.4);
  color: #fff;
}

.inspiration-btn.explore:hover {
  background: rgba(138, 95, 189, 0.3);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(138, 95, 189, 0.3);
}

.inspiration-particles {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 1;
}

.inspiration-particles .floating-particle {
  position: absolute;
  width: 3px;
  height: 3px;
  background: rgba(138, 95, 189, 0.6);
  border-radius: 50%;
  filter: blur(0.5px);
}

/* Bottom Chat Input Styles */
.bottom-input-container {
  background: rgba(0, 0, 0, 0.95);
  backdrop-filter: blur(20px);
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  padding: 16px 20px 20px;
}

.suggestion-scroll-container {
  margin-bottom: 16px;
}

.suggestion-scroll {
  display: flex;
  gap: 12px;
  overflow-x: auto;
  padding: 8px 0;
  scrollbar-width: none;
  -ms-overflow-style: none;
}

.suggestion-scroll::-webkit-scrollbar {
  display: none;
}

.suggestion-card {
  flex-shrink: 0;
  background: rgba(28, 28, 30, 0.8);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  padding: 12px 16px;
  min-width: 180px;
  text-align: left;
  transition: all 0.2s ease;
}

.suggestion-card:hover {
  background: rgba(138, 95, 189, 0.2);
  border-color: rgba(138, 95, 189, 0.3);
  transform: translateY(-1px);
}

.suggestion-title {
  color: #fff;
  font-weight: 600;
  font-size: 14px;
  margin-bottom: 4px;
}

.suggestion-subtitle {
  color: rgba(255, 255, 255, 0.6);
  font-size: 13px;
  line-height: 1.3;
}

.input-bar-container {
  display: flex;
  align-items: flex-end;
  gap: 8px;
}

.input-icon-btn {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: rgba(255, 255, 255, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  flex-shrink: 0;
}

.input-icon-btn:hover {
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
  transform: scale(1.05);
}

.text-input-wrapper {
  flex: 1;
  background: rgba(28, 28, 30, 0.8);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 20px;
  overflow: hidden;
}

.text-input {
  width: 100%;
  background: transparent;
  border: none;
  outline: none;
  color: #fff;
  font-size: 16px;
  line-height: 1.4;
  padding: 12px 16px;
  resize: none;
  font-family: inherit;
  min-height: 44px;
  max-height: 120px;
}

.text-input::placeholder {
  color: rgba(255, 255, 255, 0.4);
}

.text-input:focus {
  outline: none;
}

.text-input-wrapper:focus-within {
  border-color: rgba(138, 95, 189, 0.5);
  box-shadow: 0 0 0 2px rgba(138, 95, 189, 0.2);
}

.send-btn {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  background: rgba(138, 95, 189, 0.3);
  border: 1px solid rgba(138, 95, 189, 0.5);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  flex-shrink: 0;
}

.send-btn:hover:not(:disabled) {
  background: rgba(138, 95, 189, 0.5);
  transform: scale(1.05);
}

.send-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Modern Conversation Styles */
.close-conversation-btn {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.close-conversation-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  transform: scale(1.1);
}

.modern-input-container {
  display: flex;
  align-items: flex-end;
  gap: 12px;
  padding: 16px 20px;
  background: rgba(28, 28, 30, 0.95);
  border-radius: 24px;
  border: 2px solid transparent;
  border-top: 2px solid rgba(0, 191, 255, 0.6);
  backdrop-filter: blur(20px);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}

.modern-input-wrapper {
  flex: 1;
  position: relative;
}

.modern-textarea {
  width: 100%;
  background: transparent;
  border: none;
  outline: none;
  color: #ffffff;
  font-size: 16px;
  line-height: 1.4;
  resize: none;
  font-family: inherit;
  min-height: 24px;
  max-height: 120px;
  padding: 0;
}

.modern-textarea::placeholder {
  color: rgba(142, 142, 147, 1);
}

.modern-button-group {
  display: flex;
  align-items: center;
  gap: 8px;
}

.modern-btn {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  cursor: pointer;
  position: relative;
  overflow: hidden;
}

.modern-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none !important;
}

.voice-btn {
  background: rgba(142, 142, 147, 0.3);
  color: rgba(142, 142, 147, 1);
}

.voice-btn:hover:not(:disabled) {
  background: rgba(142, 142, 147, 0.5);
  color: #ffffff;
}

.send-btn.active {
  background: rgba(138, 95, 189, 0.8);
  color: #ffffff;
  box-shadow: 0 4px 15px rgba(138, 95, 189, 0.4);
}

.send-btn:not(.active) {
  background: rgba(142, 142, 147, 0.3);
  color: rgba(142, 142, 147, 1);
}

.star-btn {
  background: linear-gradient(135deg, rgba(138, 95, 189, 0.8), rgba(255, 215, 0, 0.6));
  color: #ffffff;
  box-shadow: 0 4px 20px rgba(138, 95, 189, 0.5);
}

.star-btn:hover:not(:disabled) {
  box-shadow: 0 6px 25px rgba(138, 95, 189, 0.7);
}

.star-hint {
  text-align: center;
  margin-top: 12px;
}

.star-hint-text {
  font-size: 12px;
  font-weight: 500;
  margin: 0;
}

/* Enhanced Message Styles */
.user-message {
  background: linear-gradient(135deg, rgba(138, 95, 189, 0.3), rgba(138, 95, 189, 0.2));
  border: 1px solid rgba(138, 95, 189, 0.4);
  border-radius: 20px 20px 6px 20px;
  padding: 14px 18px;
  backdrop-filter: blur(10px);
  box-shadow: 0 4px 15px rgba(138, 95, 189, 0.2);
}

.assistant-message {
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.08), rgba(255, 255, 255, 0.05));
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 20px 20px 20px 6px;
  padding: 14px 18px;
  display: flex;
  align-items: flex-start;
  gap: 12px;
  backdrop-filter: blur(10px);
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
}

/* Enhanced Input Styles */
.text-input-wrapper {
  flex: 1;
  background: linear-gradient(135deg, rgba(28, 28, 30, 0.9), rgba(28, 28, 30, 0.8));
  border: 2px solid rgba(255, 255, 255, 0.1);
  border-radius: 22px;
  overflow: hidden;
  backdrop-filter: blur(20px);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.text-input-wrapper:focus-within {
  border-color: rgba(138, 95, 189, 0.6);
  box-shadow: 0 0 0 4px rgba(138, 95, 189, 0.2);
  background: linear-gradient(135deg, rgba(28, 28, 30, 0.95), rgba(28, 28, 30, 0.9));
}

.input-icon-btn {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.08), rgba(255, 255, 255, 0.05));
  border: 1px solid rgba(255, 255, 255, 0.15);
  color: rgba(255, 255, 255, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  flex-shrink: 0;
  backdrop-filter: blur(10px);
}

.input-icon-btn:hover {
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.15), rgba(255, 255, 255, 0.1));
  color: #fff;
  border-color: rgba(255, 255, 255, 0.3);
  box-shadow: 0 4px 15px rgba(255, 255, 255, 0.1);
}

.send-btn {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  border: 2px solid;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  flex-shrink: 0;
  backdrop-filter: blur(10px);
}

/* Enhanced Suggestion Cards */
.suggestion-card {
  flex-shrink: 0;
  background: linear-gradient(135deg, rgba(28, 28, 30, 0.9), rgba(28, 28, 30, 0.8));
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 18px;
  padding: 16px 20px;
  min-width: 200px;
  text-align: left;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  backdrop-filter: blur(20px);
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
}

.suggestion-card:hover {
  background: linear-gradient(135deg, rgba(138, 95, 189, 0.3), rgba(138, 95, 189, 0.2));
  border-color: rgba(138, 95, 189, 0.5);
  box-shadow: 0 8px 25px rgba(138, 95, 189, 0.3);
}

/* Enhanced Bottom Container */
.bottom-input-container {
  background: linear-gradient(180deg, 
    rgba(0, 0, 0, 0.8) 0%, 
    rgba(0, 0, 0, 0.95) 100%
  );
  backdrop-filter: blur(30px);
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  padding: 20px 24px 24px;
  box-shadow: 0 -8px 32px rgba(0, 0, 0, 0.3);
}

/* 星星和卡片动画样式 */
.inspiration-card {
  @apply bg-cosmic-navy/90 backdrop-blur-sm rounded-lg overflow-hidden;
  width: 400px;
  min-height: 300px;
  perspective: 1000px;
  transform-style: preserve-3d;
  cursor: pointer;
}

.backface-hidden {
  backface-visibility: hidden;
  transform-style: preserve-3d;
}

.star-container {
  position: relative;
  transform-style: preserve-3d;
  perspective: 1000px;
}

.star-core {
  box-shadow: 0 0 20px rgba(255, 255, 255, 0.8);
}

.star-lines {
  pointer-events: none;
}

/* 卡片翻转效果 */
.card-front,
.card-back {
  position: absolute;
  width: 100%;
  height: 100%;
  backface-visibility: hidden;
}

.card-back {
  transform: rotateY(180deg);
}

/* 装饰性粒子 */
.floating-particle {
  @apply absolute w-1 h-1 rounded-full bg-white opacity-30;
  pointer-events: none;
}
```

`staroracle-app_v1/src/main.tsx`:

```tsx
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.tsx';
import ErrorBoundary from './ErrorBoundary.tsx';
import './index.css';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ErrorBoundary>
      <App />
    </ErrorBoundary>
  </StrictMode>
);

```

`staroracle-app_v1/src/store/useStarStore.ts`:

```ts
import { create } from 'zustand';
import { Star, Connection, Constellation } from '../types';
import { generateRandomStarImage } from '../utils/imageUtils';
import { 
  analyzeStarContent, 
  generateSmartConnections,
  generateAIResponse,
  getAIConfig as getAIConfigFromUtils
} from '../utils/aiTaggingUtils';
import { instantiateTemplate } from '../utils/constellationTemplates';
import { getRandomInspirationCard, InspirationCard } from '../utils/inspirationCards';
import { ConstellationTemplate } from '../types';

interface StarPosition {
  x: number;
  y: number;
}

interface StarState {
  constellation: Constellation;
  activeStarId: string | null;
  isAsking: boolean;
  isLoading: boolean; // New state to track loading during star creation
  pendingStarPosition: StarPosition | null;
  currentInspirationCard: InspirationCard | null;
  hasTemplate: boolean;
  templateInfo: { name: string; element: string } | null;
  addStar: (question: string) => Promise<Star>;
  drawInspirationCard: () => InspirationCard;
  useInspirationCard: () => void;
  dismissInspirationCard: () => void;
  viewStar: (id: string | null) => void;
  hideStarDetail: () => void;
  setIsAsking: (isAsking: boolean, position?: StarPosition) => void;
  regenerateConnections: () => void;
  applyTemplate: (template: ConstellationTemplate) => void;
  clearConstellation: () => void;
  updateStarTags: (starId: string, newTags: string[]) => void;
}

// Generate initial empty constellation
const generateEmptyConstellation = (): Constellation => {
  return {
    stars: [],
    connections: []
  };
};

export const useStarStore = create<StarState>((set, get) => {
  // AIConfig getter - 使用集中式的配置管理
  const getAIConfig = () => {
    // 使用aiTaggingUtils中的getAIConfig来获取配置
    // 该函数会自动处理优先级：用户配置 > 系统默认配置 > 空配置
    return getAIConfigFromUtils();
  };

  return {
    constellation: generateEmptyConstellation(),
    activeStarId: null, // 确保初始状态为null
    isAsking: false,
    isLoading: false, // Initialize loading state as false
    pendingStarPosition: null,
    currentInspirationCard: null,
    hasTemplate: false,
    templateInfo: null,
    
    addStar: async (question: string) => {
      const { constellation, pendingStarPosition } = get();
      const { stars } = constellation;
      
      console.log(`🤔 User asked: "${question}"`);
      
      // Set loading state to true
      set({ isLoading: true });
      
      // Get AI configuration
      const aiConfig = getAIConfig();
      
      // Generate AI response with proper error handling
      console.log('🤖 Generating AI response...');
      let answer: string;
      
      try {
        answer = await generateAIResponse(question, aiConfig);
        console.log(`💫 AI responded: "${answer}"`);
        
        // Ensure we have a valid answer
        if (!answer || answer.trim().length === 0) {
          throw new Error('Empty AI response');
        }
      } catch (error) {
        console.warn('❌ AI response failed, using fallback:', error);
        // Use fallback response generation
        answer = generateFallbackResponse(question);
        console.log(`🔄 Fallback response: "${answer}"`);
      }
      
      // Analyze content with AI for tags and categorization
      const analysis = await analyzeStarContent(question, answer, aiConfig);
      
      // Create new star at the clicked position or random position
      const x = pendingStarPosition?.x ?? (Math.random() * 70 + 15); // 15-85%
      const y = pendingStarPosition?.y ?? (Math.random() * 70 + 15); // 15-85%
      
      // Create new star with AI-generated tags and properties
      const newStar: Star = {
        id: `star-${Date.now()}`,
        x,
        y,
        // 根据洞察等级调整星星大小，洞察等级越高，星星越大
        size: Math.random() * 1.5 + 2.0 + (analysis.insight_level?.value || 0) * 0.5, // 2.0-6.5px
        // 亮度也受洞察等级影响
        brightness: (analysis.initial_luminosity || 60) / 100, // 转换为0-1范围
        question,
        answer, // Ensure answer is always set
        imageUrl: generateRandomStarImage(),
        createdAt: new Date(),
        isSpecial: Math.random() < 0.12 || (analysis.insight_level?.value || 0) >= 4, // 启明星和超新星自动成为特殊星
        tags: analysis.tags,
        primary_category: analysis.primary_category,
        emotional_tone: analysis.emotional_tone,
        question_type: analysis.question_type,
        insight_level: analysis.insight_level,
        initial_luminosity: analysis.initial_luminosity,
        connection_potential: analysis.connection_potential,
        suggested_follow_up: analysis.suggested_follow_up,
        card_summary: analysis.card_summary,
        isTemplate: false, // User-created stars are not templates
      };
      
      console.log('⭐ Adding new star:', {
        question: newStar.question,
        answer: newStar.answer,
        answerLength: newStar.answer.length,
        tags: newStar.tags,
        primary_category: newStar.primary_category,
        emotional_tone: newStar.emotional_tone,
        insight_level: newStar.insight_level,
        connection_potential: newStar.connection_potential
      });
      
      // Add new star to constellation
      const updatedStars = [...stars, newStar];
      
      // Regenerate all connections based on tag similarity
      const smartConnections = generateSmartConnections(updatedStars);
      
      set({
        constellation: {
          stars: updatedStars,
          connections: smartConnections,
        },
        activeStarId: null, // 不自动显示星星详情，避免阻止按钮点击
        isAsking: false,
        isLoading: false, // Set loading state back to false
        pendingStarPosition: null,
      });
      
      return newStar;
    },

    drawInspirationCard: () => {
      const card = getRandomInspirationCard();
      console.log('🌟 Drawing inspiration card:', card.question);
      set({ currentInspirationCard: card });
      return card;
    },

    useInspirationCard: () => {
      const { currentInspirationCard } = get();
      if (currentInspirationCard) {
        console.log('✨ Using inspiration card for new star');
        // Start asking mode with the inspiration card question
        set({ 
          isAsking: true,
          currentInspirationCard: null 
        });
        
        // Pre-fill the question in the oracle input
        // This will be handled by the OracleInput component
      }
    },

    dismissInspirationCard: () => {
      console.log('👋 Dismissing inspiration card');
      set({ currentInspirationCard: null });
    },
    
    viewStar: (id: string | null) => {
      set({ activeStarId: id });
      console.log(`👁️ Viewing star: ${id}`);
    },
    
    hideStarDetail: () => {
      set({ activeStarId: null });
      console.log('👁️ Hiding star detail');
    },
    
    setIsAsking: (isAsking: boolean, position?: StarPosition) => {
      set({ 
        isAsking,
        pendingStarPosition: position ?? null,
      });
    },
    
    regenerateConnections: () => {
      const { constellation } = get();
      const smartConnections = generateSmartConnections(constellation.stars);
      
      console.log('Regenerating connections, found:', smartConnections.length);
      
      set({
        constellation: {
          ...constellation,
          connections: smartConnections,
        },
      });
    },

    applyTemplate: (template: ConstellationTemplate) => {
      console.log(`🌟 Applying template: ${template.chineseName}`);
      
      // Instantiate the template
      const { stars: templateStars, connections: templateConnections } = instantiateTemplate(template);
      
      // Get current user stars (non-template stars)
      const { constellation } = get();
      const userStars = constellation.stars.filter(star => !star.isTemplate);
      
      // Combine template stars with existing user stars
      const allStars = [...templateStars, ...userStars];
      
      // Generate connections including both template and smart connections
      const smartConnections = generateSmartConnections(allStars);
      const allConnections = [...templateConnections, ...smartConnections];
      
      set({
        constellation: {
          stars: allStars,
          connections: allConnections,
        },
        activeStarId: null, // 清除活动星星ID，避免阻止按钮点击
        hasTemplate: true,
        templateInfo: {
          name: template.chineseName,
          element: template.element
        }
      });
      
      console.log(`✨ Applied template with ${templateStars.length} stars and ${templateConnections.length} connections`);
    },

    clearConstellation: () => {
      set({
        constellation: generateEmptyConstellation(),
        activeStarId: null,
        hasTemplate: false,
        templateInfo: null,
      });
      console.log('🧹 Cleared constellation');
    },

    updateStarTags: (starId: string, newTags: string[]) => {
      set(state => {
        // Update the star with new tags
        const updatedStars = state.constellation.stars.map(star => 
          star.id === starId 
            ? { ...star, tags: newTags } 
            : star
        );
        
        // Regenerate connections with updated tags - ensure non-null values
        const newConnections = generateSmartConnections(updatedStars);
        
        return {
          constellation: {
            stars: updatedStars,
            connections: newConnections
          }
        };
      });
      
      console.log(`🏷️ Updated tags for star ${starId}`);
    }
  };
});

// Fallback response generator for when AI fails
const generateFallbackResponse = (question: string): string => {
  const lowerQuestion = question.toLowerCase();
  
  // Question-specific responses for better relevance
  if (lowerQuestion.includes('爱') || lowerQuestion.includes('恋') || lowerQuestion.includes('love') || lowerQuestion.includes('relationship')) {
    const loveResponses = [
      "当心灵敞开时，星辰便会排列成行。爱会流向那些勇敢拥抱脆弱的人。",
      "如同双星相互环绕，真正的连接需要独立与统一并存。",
      "当灵魂以真实的光芒闪耀时，宇宙会密谋让它们相遇。",
      "爱不是被找到的，而是被认出的，就像在异国天空中看到熟悉的星座。",
      "真爱如月圆之夜的潮汐，既有规律可循，又充满神秘的力量。",
    ];
    return loveResponses[Math.floor(Math.random() * loveResponses.length)];
  }
  
  if (lowerQuestion.includes('目标') || lowerQuestion.includes('意义') || lowerQuestion.includes('purpose') || lowerQuestion.includes('meaning')) {
    const purposeResponses = [
      "你的目标如星云诞生恒星般展开——缓慢、美丽、不可避免。",
      "宇宙不会询问星辰的目标；它们只是闪耀。你也应如此。",
      "意义从你的天赋与世界需求的交汇处涌现，如光线穿过三棱镜般折射。",
      "你的目标写在你最深的喜悦和服务意愿的语言中。",
      "生命的意义不在远方，而在每一个当下的选择与行动中绽放。",
    ];
    return purposeResponses[Math.floor(Math.random() * purposeResponses.length)];
  }
  
  if (lowerQuestion.includes('成功') || lowerQuestion.includes('事业') || lowerQuestion.includes('成就') || lowerQuestion.includes('success') || lowerQuestion.includes('career') || lowerQuestion.includes('achieve')) {
    const successResponses = [
      "成功如超新星般绽放——突然的辉煌源于长久耐心的燃烧。",
      "通往成就的道路如银河系的螺旋臂般蜿蜒，每个转弯都揭示新的可能性。",
      "真正的成功不在于积累，而在于你为他人黑暗中带来的光明。",
      "如行星找到轨道般，成功来自于将你的努力与自然力量对齐。",
      "成功的种子早已种在你的内心，只需要时间和坚持的浇灌。",
    ];
    return successResponses[Math.floor(Math.random() * successResponses.length)];
  }
  
  if (lowerQuestion.includes('恐惧') || lowerQuestion.includes('害怕') || lowerQuestion.includes('焦虑') || lowerQuestion.includes('fear') || lowerQuestion.includes('anxiety') || lowerQuestion.includes('worry')) {
    const fearResponses = [
      "恐惧是你潜能投下的阴影。转向光明，看它消失。",
      "勇气不是没有恐惧，而是在可能性的星光下与之共舞。",
      "如流星进入大气层时燃烧得明亮，转化需要拥抱火焰。",
      "你的恐惧是古老的星尘；承认它们，然后让它们在宇宙风中飘散。",
      "恐惧是成长的前奏，如黎明前的黑暗，预示着光明的到来。",
    ];
    return fearResponses[Math.floor(Math.random() * fearResponses.length)];
  }
  
  if (lowerQuestion.includes('未来') || lowerQuestion.includes('将来') || lowerQuestion.includes('命运') || lowerQuestion.includes('future') || lowerQuestion.includes('destiny')) {
    const futureResponses = [
      "未来是你通过连接选择之星而创造的星座。",
      "时间如恒星风般流淌，将可能性的种子带到肥沃的时刻。",
      "你的命运不像恒星般固定，而像彗星般流动，由你的方向塑造。",
      "未来以直觉的语言低语；用心聆听，而非恐惧。",
      "明天的轮廓隐藏在今日的每一个微小决定中。",
    ];
    return futureResponses[Math.floor(Math.random() * futureResponses.length)];
  }
  
  if (lowerQuestion.includes('快乐') || lowerQuestion.includes('幸福') || lowerQuestion.includes('喜悦') || lowerQuestion.includes('happiness') || lowerQuestion.includes('joy') || lowerQuestion.includes('fulfillment')) {
    const happinessResponses = [
      "快乐不是目的地，而是穿越体验宇宙的旅行方式。",
      "喜悦如星光在水面闪烁——存在于你选择看见它的每个时刻。",
      "满足来自于将你内在的星座与外在的表达对齐。",
      "真正的快乐从内心辐射，如恒星产生自己的光和热。",
      "幸福如花朵，在感恩的土壤中最容易绽放。",
    ];
    return happinessResponses[Math.floor(Math.random() * happinessResponses.length)];
  }
  
  // General mystical responses for other questions
  const generalResponses = [
    "星辰低语着未曾踏足的道路，然而你的旅程始终忠于内心的召唤。",
    "如月光映照水面，你所寻求的既在那里又不在那里。请深入探寻。",
    "古老的光芒穿越时空抵达你的眸；耐心将揭示匆忙所掩盖的真相。",
    "宇宙编织着可能性的图案。你的问题已经包含了它的答案。",
    "天体尽管相距遥远却和谐共舞。在生命的盛大芭蕾中找到你的节拍。",
    "当星系在虚空中螺旋前进时，你的道路在黑暗中蜿蜒向着遥远的光明。",
    "你思想的星云包含着尚未诞生的恒星种子。请滋养它们。",
    "时间如恒星风般流淌，将你存在的景观塑造成未知的形态。",
    "星辰之间的虚空并非空无，而是充满潜能。拥抱你生命中的空间。",
    "你的问题在宇宙中回响，带着星光承载的智慧归来。",
    "宇宙无目的地扩张。你的旅程无需超越自身的理由。",
    "星座是我们强加给混沌的图案。从随机的经验之星中创造意义。",
    "你看到的光芒很久以前就开始了它的旅程。相信所揭示的，即使延迟。",
    "宇宙尘埃变成恒星再变成尘埃。所有的转化对你都是可能的。",
    "你意图的引力将体验拉入围绕你的轨道。明智地选择你所吸引的。",
  ];
  
  return generalResponses[Math.floor(Math.random() * generalResponses.length)];
};
```

`staroracle-app_v1/src/types/index.ts`:

```ts
export interface Star {
  id: string;
  x: number;
  y: number;
  size: number;
  brightness: number;
  question: string;
  answer: string;
  imageUrl: string;
  createdAt: Date;
  isSpecial: boolean;
  tags: string[];
  primary_category: string; // 更新为 primary_category
  emotional_tone: string[]; // 更新为数组类型
  question_type?: string; // 新增：问题类型
  insight_level?: {
    value: number; // 1-5
    description: string; // '星尘', '微光', '寻常星', '启明星', '超新星'
  };
  initial_luminosity?: number; // 0-100
  connection_potential?: number; // 1-5
  suggested_follow_up?: string; // 建议的追问
  card_summary?: string; // 卡片摘要
  similarity?: number; // For connection strength
  isTemplate?: boolean; // 标记是否为模板星星
  templateType?: string; // 模板类型（星座名称）
}

export interface Connection {
  id: string;
  fromStarId: string;
  toStarId: string;
  strength: number; // 0-1, based on tag similarity
  sharedTags: string[];
  isTemplate?: boolean; // 标记是否为模板连接
  constellationName?: string; // 标记该连接所属的星座名称
}

export interface Constellation {
  stars: Star[];
  connections: Connection[];
}

// 更新为更完整的分析结构
export interface TagAnalysis {
  tags: string[];
  primary_category: string;
  emotional_tone: string[];
  question_type: string;
  insight_level: {
    value: number;
    description: string;
  };
  initial_luminosity: number;
  connection_potential: number;
  suggested_follow_up: string;
  card_summary: string;
}

// 星座模板接口
export interface ConstellationTemplate {
  id: string;
  name: string;
  chineseName: string;
  description: string;
  element: 'fire' | 'earth' | 'air' | 'water';
  stars: TemplateStarData[];
  connections: TemplateConnectionData[];
  centerX: number;
  centerY: number;
  scale: number;
}

export interface TemplateStarData {
  id: string;
  x: number; // 相对于星座中心的位置
  y: number;
  size: number;
  brightness: number;
  question: string;
  answer: string;
  tags: string[];
  category?: string; // 兼容旧的模板数据
  emotionalTone?: string; // 兼容旧的模板数据
  primary_category?: string; // 新的类别字段
  emotional_tone?: string[]; // 新的情感基调字段
  question_type?: string;
  insight_level?: {
    value: number;
    description: string;
  };
  initial_luminosity?: number;
  connection_potential?: number;
  suggested_follow_up?: string;
  card_summary?: string;
  isMainStar?: boolean; // 是否为主星
}

export interface TemplateConnectionData {
  fromStarId: string;
  toStarId: string;
  strength: number;
  sharedTags: string[];
}
```

`staroracle-app_v1/src/utils/aiTaggingUtils.ts`:

```ts
// AI Tagging and Analysis Utilities
import { Star, Connection, TagAnalysis } from '../types';
import type { ApiProvider } from '../vite-env';

export interface AITaggingConfig {
  provider?: ApiProvider; // 新增：API提供商
  apiKey?: string;
  endpoint?: string;
  model?: string;
  _version?: string; // 添加版本号用于未来可能的迁移
  _lastUpdated?: string; // 添加最后更新时间
}

export interface APIValidationResult {
  isValid: boolean;
  error?: string;
  responseTime?: number;
  modelInfo?: string;
}

// API验证函数
export const validateAIConfig = async (config: AITaggingConfig): Promise<APIValidationResult> => {
  if (!config.provider || !config.apiKey || !config.endpoint || !config.model) {
    return {
      isValid: false,
      error: '请选择提供商并填写完整的API配置信息（API Key、Endpoint、Model）'
    };
  }

  const startTime = Date.now();
  const testPrompt = '请简单回复"测试成功"';
  let requestBody;
  let requestHeaders = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${config.apiKey}`,
  };
  
  try {
    console.log(`🔍 Validating ${config.provider} API configuration...`);

    // 根据provider构建不同的请求体
    switch (config.provider) {
      case 'gemini':
        requestBody = {
          contents: [{ parts: [{ text: testPrompt }] }]
        };
        break;
      
      case 'openai':
      default: // OpenAI 和 NewAPI 等兼容服务
        requestBody = {
          model: config.model,
          messages: [{ role: 'user', content: testPrompt }],
          max_tokens: 10,
          temperature: 0.1,
        };
        break;
    }

    const response = await fetch(config.endpoint, {
      method: 'POST',
      headers: requestHeaders,
      body: JSON.stringify(requestBody),
    });

    const responseTime = Date.now() - startTime;

    if (!response.ok) {
      let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
      
      try {
        // Check if response is JSON before parsing
        const contentType = response.headers.get('content-type');
        if (contentType && contentType.includes('application/json')) {
          const errorData = await response.json();
          if (errorData.error?.message) {
            errorMessage = errorData.error.message;
          } else if (errorData.message) {
            errorMessage = errorData.message;
          }
        } else {
          // If not JSON, get text content for better error reporting
          const textContent = await response.text();
          if (textContent.includes('<!doctype') || textContent.includes('<html')) {
            errorMessage = `服务器返回了HTML页面而不是API响应。请检查endpoint地址是否正确。`;
          } else {
            errorMessage = `非JSON响应: ${textContent.slice(0, 100)}...`;
          }
        }
      } catch (parseError) {
        // If we can't parse the error response, use the HTTP status
        errorMessage = `HTTP ${response.status}: 无法解析错误响应`;
      }

      return {
        isValid: false,
        error: errorMessage,
        responseTime
      };
    }

    let data;
    try {
      // Check if response is JSON before parsing
      const contentType = response.headers.get('content-type');
      if (!contentType || !contentType.includes('application/json')) {
        const textContent = await response.text();
        return {
          isValid: false,
          error: `API返回了非JSON响应。请检查endpoint是否正确。响应内容: ${textContent.slice(0, 100)}...`,
          responseTime
        };
      }
      
      data = await response.json();
    } catch (parseError) {
      return {
        isValid: false,
        error: 'API响应不是有效的JSON格式，请检查endpoint是否支持OpenAI格式',
        responseTime
      };
    }
    
    // 根据provider解析不同的响应
    let testResponse: string | undefined;

    switch (config.provider) {
      case 'gemini':
        testResponse = data.candidates?.[0]?.content?.parts?.[0]?.text;
        if (!testResponse) {
          return { isValid: false, error: 'Gemini响应格式不正确', responseTime };
        }
        break;
      case 'openai':
      default:
        // 检查响应格式
        if (!data.choices || !data.choices[0] || !data.choices[0].message) {
          return {
            isValid: false,
            error: 'API响应格式不正确，请检查endpoint是否支持OpenAI格式',
            responseTime
          };
        }

        testResponse = data.choices[0].message.content;
        break;
    }
    
    console.log('✅ API validation successful:', {
      responseTime: `${responseTime}ms`,
      model: config.model,
      testResponse: testResponse?.slice(0, 50)
    });

    return {
      isValid: true,
      responseTime,
      modelInfo: `${config.model} (${responseTime}ms)`
    };

  } catch (error) {
    const responseTime = Date.now() - startTime;
    console.error('❌ API validation failed:', error);
    
    let errorMessage = '网络连接失败';
    if (error instanceof Error) {
      if (error.message.includes('fetch')) {
        errorMessage = '无法连接到API服务器，请检查网络和endpoint地址';
      } else if (error.message.includes('CORS')) {
        errorMessage = 'CORS错误，请检查API服务器是否允许跨域请求';
      } else if (error.message.includes('JSON')) {
        errorMessage = '服务器响应格式错误，请检查endpoint地址是否正确';
      } else {
        errorMessage = error.message;
      }
    }

    return {
      isValid: false,
      error: errorMessage,
      responseTime
    };
  }
};

// Enhanced mock AI analysis with better tag generation
const mockAIAnalysis = (question: string, answer: string): TagAnalysis => {
  const content = `${question} ${answer}`.toLowerCase();
  
  // More comprehensive tag mapping
  const tagMap = {
    // 核心生活领域 - Core Life Areas
    'love': ['relationships', 'romance', 'connection', 'heart', 'soulmate'],
    'family': ['relationships', 'parents', 'children', 'home', 'roots', 'legacy'],
    'friendship': ['connection', 'social', 'trust', 'loyalty', 'support'],
    'career': ['work', 'profession', 'vocation', 'success', 'achievement'],
    'education': ['learning', 'knowledge', 'growth', 'skills', 'wisdom'],
    'health': ['wellness', 'fitness', 'balance', 'vitality', 'self-care'],
    'finance': ['money', 'wealth', 'abundance', 'security', 'resources'],
    'spirituality': ['faith', 'soul', 'meaning', 'divinity', 'practice'],
    
    // 内在体验 - Inner Experience
    'emotions': ['feelings', 'awareness', 'processing', 'expression', 'regulation'],
    'happiness': ['joy', 'fulfillment', 'contentment', 'bliss', 'satisfaction'],
    'anxiety': ['fear', 'worry', 'stress', 'uncertainty', 'overwhelm'],
    'grief': ['loss', 'sadness', 'mourning', 'acceptance', 'healing'],
    'anger': ['frustration', 'resentment', 'boundaries', 'assertiveness', 'release'],
    'shame': ['guilt', 'regret', 'inadequacy', 'worthiness', 'forgiveness'],
    
    // 自我发展 - Self Development
    'identity': ['self', 'authenticity', 'values', 'discovery', 'integration'],
    'purpose': ['meaning', 'calling', 'mission', 'direction', 'contribution'],
    'growth': ['development', 'evolution', 'improvement', 'transformation', 'potential'],
    'resilience': ['strength', 'adaptation', 'recovery', 'endurance', 'perseverance'],
    'creativity': ['expression', 'inspiration', 'imagination', 'innovation', 'artistry'],
    'wisdom': ['insight', 'perspective', 'understanding', 'discernment', 'reflection'],
    
    // 人际关系 - Relationships
    'communication': ['expression', 'listening', 'understanding', 'clarity', 'connection'],
    'intimacy': ['closeness', 'vulnerability', 'trust', 'bonding', 'openness'],
    'boundaries': ['limits', 'protection', 'respect', 'space', 'autonomy'],
    'conflict': ['resolution', 'understanding', 'healing', 'growth', 'peace'],
    'trust': ['faith', 'reliability', 'consistency', 'safety', 'honesty'],
    
    // 生活哲学 - Life Philosophy
    'meaning': ['purpose', 'significance', 'values', 'understanding', 'exploration'],
    'mindfulness': ['presence', 'awareness', 'attention', 'consciousness', 'being'],
    'gratitude': ['appreciation', 'thankfulness', 'recognition', 'abundance', 'positivity'],
    'legacy': ['impact', 'contribution', 'remembrance', 'influence', 'heritage'],
    'values': ['principles', 'ethics', 'morality', 'beliefs', 'priorities'],
    
    // 生活转变 - Life Transitions
    'change': ['transition', 'adaptation', 'adjustment', 'evolution', 'transformation'],
    'decision': ['choice', 'discernment', 'wisdom', 'judgment', 'crossroads'],
    'future': ['planning', 'vision', 'direction', 'goals', 'possibilities'],
    'past': ['history', 'memories', 'reflection', 'lessons', 'integration'],
    'letting-go': ['release', 'surrender', 'acceptance', 'closure', 'freedom'],
    
    // 世界关系 - Relation to World
    'nature': ['environment', 'connection', 'outdoors', 'harmony', 'elements'],
    'society': ['community', 'culture', 'belonging', 'contribution', 'citizenship'],
    'justice': ['fairness', 'equality', 'rights', 'advocacy', 'ethics'],
    'service': ['contribution', 'helping', 'impact', 'giving', 'purpose'],
    'technology': ['digital', 'tools', 'innovation', 'adaptation', 'balance']
  };
  
  // 新的类别映射到旧的类别
  const categoryMapping = {
    'relationships': 'relationships',
    'personal_growth': 'personal_growth',
    'career_and_purpose': 'career_and_purpose',
    'emotional_wellbeing': 'emotional_wellbeing',
    'philosophy_and_existence': 'philosophy_and_existence',
    'creativity_and_passion': 'creativity_and_passion',
    'daily_life': 'daily_life'
  };
  
  // 类别关键词
  const categories = {
    'relationships': ['love', 'family', 'friendship', 'connection', 'intimacy', 'communication', 'boundaries', 'trust'],
    'personal_growth': ['identity', 'purpose', 'wisdom', 'growth', 'resilience', 'spirituality', 'creativity', 'education'],
    'career_and_purpose': ['future', 'career', 'decision', 'change', 'goals', 'values', 'legacy', 'mission', 'purpose'],
    'emotional_wellbeing': ['happiness', 'health', 'emotions', 'mindfulness', 'balance', 'self-care', 'vitality', 'healing'],
    'philosophy_and_existence': ['meaning', 'purpose', 'spirituality', 'values', 'wisdom', 'legacy', 'faith', 'life', 'death'],
    'creativity_and_passion': ['creativity', 'expression', 'imagination', 'innovation', 'artistry', 'inspiration', 'passion'],
    'daily_life': ['finance', 'security', 'abundance', 'resources', 'stability', 'wealth', 'work', 'routine', 'daily', 'practical']
  };
  
  // 情感基调映射
  const emotionalToneMapping = {
    'positive': '充满希望的',
    'contemplative': '思考的',
    'seeking': '探寻中',
    'neutral': '中性的'
  };
  
  // Improved emotional tone detection
  const emotionalTones = {
    '充满希望的': ['happy', 'joy', 'gratitude', 'hope', 'excitement', 'love', 'strength', 'peace', 'confidence'],
    '思考的': ['meaning', 'purpose', 'wisdom', 'reflect', 'wonder', 'ponder', 'consider', 'understand', 'explore'],
    '探寻中': ['find', 'search', 'discover', 'seek', 'direction', 'path', 'guidance', 'answers', 'clarity', 'help'],
    '中性的': ['what', 'is', 'are', 'should', 'would', 'could', 'might', 'perhaps', 'maybe', 'possibly'],
    '焦虑的': ['anxiety', 'worry', 'stress', 'fear', 'nervous', 'uncertain', 'overwhelm'],
    '感激的': ['grateful', 'thankful', 'appreciate', 'blessing', 'gift', 'fortune'],
    '困惑的': ['confused', 'puzzled', 'unclear', 'unsure', 'complexity', 'complicated'],
    '忧郁的': ['sad', 'depressed', 'melancholy', 'down', 'blue', 'grief', 'loss'],
    '坚定的': ['determined', 'resolved', 'committed', 'decided', 'sure', 'certain', 'confident']
  };

  // 问题类型检测
  const questionTypePatterns = {
    '探索型': ['why', 'why do i', 'what if', 'how come', '为什么', '怎么会', '如果', '假设', '是不是因为', '可能是'],
    '实用型': ['how to', 'how can i', 'what is the way to', 'steps to', 'method', '如何', '怎么做', '方法', '步骤', '技巧'],
    '事实型': ['what is', 'when', 'where', 'who', '什么是', '何时', '何地', '谁', '哪里', '多少'],
    '表达型': ['i feel', 'i am', 'i think', 'i believe', '我觉得', '我认为', '我感到', '我相信', '我想']
  };
  
  // Extract tags based on content with better matching
  const extractedTags: string[] = [];
  let detectedCategory = 'philosophy_and_existence';
  const detectedTones: string[] = ['探寻中'];
  let questionType = '探索型';
  
  // Find matching tags with partial matching
  Object.entries(tagMap).forEach(([key, relatedTags]) => {
    if (content.includes(key) || relatedTags.some(tag => content.includes(tag))) {
      extractedTags.push(key);
      // Add 1-2 related tags for better connections but avoid too many tags
      extractedTags.push(...relatedTags.slice(0, 2));
    }
  });
  
  // Add common universal tags to ensure connections
  const universalTags = ['wisdom', 'growth', 'reflection', 'insight'];
  extractedTags.push(...universalTags.slice(0, 2));
  
  // Determine category with better matching
  Object.entries(categories).forEach(([category, keywords]) => {
    const matchCount = keywords.filter(keyword => content.includes(keyword)).length;
    if (matchCount > 0) {
      detectedCategory = category;
    }
  });
  
  // Determine emotional tones (multiple can be detected)
  Object.entries(emotionalTones).forEach(([tone, keywords]) => {
    const matchCount = keywords.filter(keyword => content.includes(keyword)).length;
    if (matchCount > 0 && !detectedTones.includes(tone)) {
      detectedTones.push(tone);
    }
  });
  
  // Limit to two emotional tones
  if (detectedTones.length > 2) {
    detectedTones.splice(2);
  }
  
  // Determine question type
  Object.entries(questionTypePatterns).forEach(([type, patterns]) => {
    if (patterns.some(pattern => question.toLowerCase().includes(pattern))) {
      questionType = type;
      return;
    }
  });
  
  // Ensure we have enough tags for connections
  if (extractedTags.length < 3) {
    extractedTags.push('reflection', 'insight', 'awareness');
  }
  
  // Remove duplicates and limit to 6 tags for better connections
  const uniqueTags = [...new Set(extractedTags)].slice(0, 6);
  
  // Determine insight level based on content depth
  let insightLevel = {
    value: 1,
    description: '星尘'
  };
  
  // 简单的洞察度评估规则
  if (question.length > 50 && answer.length > 150) {
    insightLevel.value = 4;
    insightLevel.description = '启明星';
  } else if (question.length > 30 && answer.length > 100) {
    insightLevel.value = 3;
    insightLevel.description = '寻常星';
  } else if (question.length > 10 && answer.length > 50) {
    insightLevel.value = 2;
    insightLevel.description = '微光';
  }
  
  // 判断是否是深度自我探索的问题
  const selfReflectionWords = ['我自己', '我的内心', '自我', '成长', '人生', '意义', '价值', '恐惧', '梦想', '目标', '自我意识'];
  if (selfReflectionWords.some(word => content.includes(word))) {
    insightLevel.value = Math.min(5, insightLevel.value + 1);
    if (insightLevel.value >= 4) {
      insightLevel.description = insightLevel.value === 5 ? '超新星' : '启明星';
    }
  }
  
  // 计算初始亮度
  const luminosityMap = [0, 10, 30, 60, 90, 100];
  const initialLuminosity = luminosityMap[insightLevel.value];
  
  // 确定连接潜力
  let connectionPotential = 3; // 默认中等连接潜力
  
  // 通用主题有较高的连接潜力
  const universalThemes = ['love', 'purpose', 'meaning', 'growth', 'change', 'fear', 'happiness', 'success'];
  if (universalThemes.some(theme => uniqueTags.includes(theme))) {
    connectionPotential = 5;
  } else if (uniqueTags.length <= 2) {
    connectionPotential = 1; // 标签很少，连接潜力低
  } else if (uniqueTags.length >= 5) {
    connectionPotential = 4; // 标签多，连接潜力高
  }
  
  // 生成简单的卡片摘要
  let cardSummary = question.length > 30 ? question : question + " - " + answer.slice(0, 40) + "...";
  
  // 生成追问
  let suggestedFollowUp = '';
  const followUpMap: Record<string, string> = {
    'relationships': '这种关系模式在你生活的其他方面是否也有体现？',
    'personal_growth': '你觉得是什么阻碍了你在这方面的进一步成长？',
    'career_and_purpose': '如果没有任何限制，你理想中的职业道路是什么样的？',
    'emotional_wellbeing': '这种情绪是从什么时候开始的，有没有特定的触发点？',
    'philosophy_and_existence': '这个信念对你日常生活的决策有什么影响？',
    'creativity_and_passion': '你上一次完全沉浸在创造性活动中是什么时候？那感觉如何？',
    'daily_life': '这个日常习惯如何影响了你的整体生活质量？'
  };
  
  suggestedFollowUp = followUpMap[detectedCategory] || '关于这个话题，你还有什么更深层次的感受或想法？';
  
  return {
    tags: uniqueTags,
    primary_category: detectedCategory,
    emotional_tone: detectedTones,
    question_type: questionType,
    insight_level: insightLevel,
    initial_luminosity: initialLuminosity,
    connection_potential: connectionPotential,
    suggested_follow_up: suggestedFollowUp,
    card_summary: cardSummary
  };
};

// Main AI tagging function
export const analyzeStarContent = async (
  question: string, 
  answer: string,
  config?: AITaggingConfig,
  userHistory?: { previousInsightLevel: number, recentTags: string[] }
): Promise<TagAnalysis> => {
  try {
    // Always try to use AI service first
    if (config?.apiKey && config?.endpoint) {
      console.log(`🤖 使用${config.provider || 'openai'}服务进行内容分析`);
      console.log(`📝 分析内容 - 问题: "${question}", 回答: "${answer}"`);
      return await callAIService(question, answer, config);
    } else {
      // Try to use default API config if available
      const defaultConfig = getAIConfig();
      if (defaultConfig.apiKey && defaultConfig.endpoint) {
        console.log(`🤖 使用默认${defaultConfig.provider || 'openai'}配置进行内容分析`);
        console.log(`📝 分析内容 - 问题: "${question}", 回答: "${answer}"`);
        return await callAIService(question, answer, defaultConfig);
      }
    }
    
    console.warn('⚠️ 未找到AI配置，使用模拟内容分析');
    // Fallback to mock analysis if no API config is available
    return mockAIAnalysis(question, answer);
  } catch (error) {
    console.warn('❌ AI标签生成失败，使用备用方案:', error);
    return mockAIAnalysis(question, answer);
  }
};

// Generate AI response for oracle answers
export const generateAIResponse = async (
  question: string,
  config?: AITaggingConfig
): Promise<string> => {
  console.log('🌟 为问题生成回答:', question);
  
  try {
    if (config?.apiKey && config?.endpoint) {
      console.log(`🤖 使用${config.provider || 'openai'}服务生成回答`);
      const aiResponse = await callAIForResponse(question, config);
      console.log('✨ AI生成的回答:', aiResponse);
      return aiResponse;
    }
    
    // 尝试使用默认配置
    const defaultConfig = getAIConfig();
    if (defaultConfig.apiKey && defaultConfig.endpoint) {
      console.log(`🤖 使用默认${defaultConfig.provider || 'openai'}配置生成回答`);
      // 打印配置信息（隐藏API密钥）
      console.log(`📋 配置信息: 提供商=${defaultConfig.provider}, 端点=${defaultConfig.endpoint}, 模型=${defaultConfig.model}`);
      const aiResponse = await callAIForResponse(question, defaultConfig);
      console.log('✨ AI生成的回答:', aiResponse);
      return aiResponse;
    }
    
    console.log('🎭 使用模拟回答生成');
    // Fallback to mock responses
    const mockResponse = generateMockResponse(question);
    console.log('✨ 模拟生成的回答:', mockResponse);
    return mockResponse;
  } catch (error) {
    console.warn('❌ AI回答生成失败，使用备用方案:', error);
    const fallbackResponse = generateMockResponse(question);
    console.log('🔄 备用回答:', fallbackResponse);
    return fallbackResponse;
  }
};

// Enhanced mock response generator with question-specific Chinese responses
const generateMockResponse = (question: string): string => {
  const lowerQuestion = question.toLowerCase();
  
  // Question-specific responses for better relevance
  if (lowerQuestion.includes('爱') || lowerQuestion.includes('恋') || lowerQuestion.includes('love') || lowerQuestion.includes('relationship')) {
    const loveResponses = [
      "当心灵敞开时，星辰便会排列成行。爱会流向那些勇敢拥抱脆弱的人。",
      "如同双星相互环绕，真正的连接需要独立与统一并存。",
      "当灵魂以真实的光芒闪耀时，宇宙会密谋让它们相遇。",
      "爱不是被找到的，而是被认出的，就像在异国天空中看到熟悉的星座。",
      "真爱如月圆之夜的潮汐，既有规律可循，又充满神秘的力量。",
    ];
    return loveResponses[Math.floor(Math.random() * loveResponses.length)];
  }
  
  if (lowerQuestion.includes('目标') || lowerQuestion.includes('意义') || lowerQuestion.includes('purpose') || lowerQuestion.includes('meaning')) {
    const purposeResponses = [
      "你的目标如星云诞生恒星般展开——缓慢、美丽、不可避免。",
      "宇宙不会询问星辰的目标；它们只是闪耀。你也应如此。",
      "意义从你的天赋与世界需求的交汇处涌现，如光线穿过三棱镜般折射。",
      "你的目标写在你最深的喜悦和服务意愿的语言中。",
      "生命的意义不在远方，而在每一个当下的选择与行动中绽放。",
    ];
    return purposeResponses[Math.floor(Math.random() * purposeResponses.length)];
  }
  
  if (lowerQuestion.includes('成功') || lowerQuestion.includes('事业') || lowerQuestion.includes('成就') || lowerQuestion.includes('success') || lowerQuestion.includes('career') || lowerQuestion.includes('achieve')) {
    const successResponses = [
      "成功如超新星般绽放——突然的辉煌源于长久耐心的燃烧。",
      "通往成就的道路如银河系的螺旋臂般蜿蜒，每个转弯都揭示新的可能性。",
      "真正的成功不在于积累，而在于你为他人黑暗中带来的光明。",
      "如行星找到轨道般，成功来自于将你的努力与自然力量对齐。",
      "成功的种子早已种在你的内心，只需要时间和坚持的浇灌。",
    ];
    return successResponses[Math.floor(Math.random() * successResponses.length)];
  }
  
  if (lowerQuestion.includes('恐惧') || lowerQuestion.includes('害怕') || lowerQuestion.includes('焦虑') || lowerQuestion.includes('fear') || lowerQuestion.includes('anxiety') || lowerQuestion.includes('worry')) {
    const fearResponses = [
      "恐惧是你潜能投下的阴影。转向光明，看它消失。",
      "勇气不是没有恐惧，而是在可能性的星光下与之共舞。",
      "如流星进入大气层时燃烧得明亮，转化需要拥抱火焰。",
      "你的恐惧是古老的星尘；承认它们，然后让它们在宇宙风中飘散。",
      "恐惧是成长的前奏，如黎明前的黑暗，预示着光明的到来。",
    ];
    return fearResponses[Math.floor(Math.random() * fearResponses.length)];
  }
  
  if (lowerQuestion.includes('未来') || lowerQuestion.includes('将来') || lowerQuestion.includes('命运') || lowerQuestion.includes('future') || lowerQuestion.includes('destiny')) {
    const futureResponses = [
      "未来是你通过连接选择之星而创造的星座。",
      "时间如恒星风般流淌，将可能性的种子带到肥沃的时刻。",
      "你的命运不像恒星般固定，而像彗星般流动，由你的方向塑造。",
      "未来以直觉的语言低语；用心聆听，而非恐惧。",
      "明天的轮廓隐藏在今日的每一个微小决定中。",
    ];
    return futureResponses[Math.floor(Math.random() * futureResponses.length)];
  }
  
  if (lowerQuestion.includes('快乐') || lowerQuestion.includes('幸福') || lowerQuestion.includes('喜悦') || lowerQuestion.includes('happiness') || lowerQuestion.includes('joy') || lowerQuestion.includes('fulfillment')) {
    const happinessResponses = [
      "快乐不是目的地，而是穿越体验宇宙的旅行方式。",
      "喜悦如星光在水面闪烁——存在于你选择看见它的每个时刻。",
      "满足来自于将你内在的星座与外在的表达对齐。",
      "真正的快乐从内心辐射，如恒星产生自己的光和热。",
      "幸福如花朵，在感恩的土壤中最容易绽放。",
    ];
    return happinessResponses[Math.floor(Math.random() * happinessResponses.length)];
  }
  
  // General mystical responses for other questions
  const generalResponses = [
    "星辰低语着未曾踏足的道路，然而你的旅程始终忠于内心的召唤。",
    "如月光映照水面，你所寻求的既在那里又不在那里。请深入探寻。",
    "古老的光芒穿越时空抵达你的眸；耐心将揭示匆忙所掩盖的真相。",
    "宇宙编织着可能性的图案。你的问题已经包含了它的答案。",
    "天体尽管相距遥远却和谐共舞。在生命的盛大芭蕾中找到你的节拍。",
    "当星系在虚空中螺旋前进时，你的道路在黑暗中蜿蜒向着遥远的光明。",
    "你思想的星云包含着尚未诞生的恒星种子。请滋养它们。",
    "时间如恒星风般流淌，将你存在的景观塑造成未知的形态。",
    "星辰之间的虚空并非空无，而是充满潜能。拥抱你生命中的空间。",
    "你的问题在宇宙中回响，带着星光承载的智慧归来。",
    "宇宙无目的地扩张。你的旅程无需超越自身的理由。",
    "星座是我们强加给混沌的图案。从随机的经验之星中创造意义。",
    "你看到的光芒很久以前就开始了它的旅程。相信所揭示的，即使延迟。",
    "宇宙尘埃变成恒星再变成尘埃。所有的转化对你都是可能的。",
    "你意图的引力将体验拉入围绕你的轨道。明智地选择你所吸引的。",
  ];
  
  return generalResponses[Math.floor(Math.random() * generalResponses.length)];
};

// Real AI service integration for responses
const callAIForResponse = async (
  question: string,
  config: AITaggingConfig
): Promise<string> => {
  if (!config.provider) {
    config.provider = 'openai'; // 默认使用OpenAI格式
  }

  const prompt = `你是一位古老智慧的宇宙神谕。请用充满诗意和神秘感的语言回答这个问题："${question}"。答案应该简短而深刻，与星辰、宇宙或自然现象产生联系，给人启发。请用中文回答：`;

  let requestBody;
  
  // 根据 provider 构建请求体
  switch (config.provider) {
    case 'gemini':  
      requestBody = { 
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.8,
          maxOutputTokens: 50000
        }
      };
      break;
    case 'openai':
    default:
      requestBody = {
        model: config.model || 'gpt-3.5-turbo',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.8,
        max_tokens: 50000,
      };
      break;
  }

  try {
    console.log(`🔍 发送回答生成请求到 ${config.provider} API...`);
    console.log(`📤 请求体: ${JSON.stringify(requestBody)}`);
    
    const response = await fetch(config.endpoint!, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${config.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`❌ API响应错误 (${response.status}): ${errorText}`);
      throw new Error(`AI API error: ${response.status} - ${errorText}`);
    }

    const data = await response.json();
    console.log(`📥 原始API响应完整结构: `, JSON.stringify(data, null, 2));
    
    // 根据 provider 解析响应
    let answer = '';
    switch (config.provider) {
      case 'gemini':
        if (data.candidates && data.candidates[0] && data.candidates[0].content) {
          answer = data.candidates[0].content.parts[0].text.trim();
          console.log(`✅ Gemini响应解析: "${answer}"`);
        } else {
          console.warn('⚠️ Gemini响应结构异常:', JSON.stringify(data, null, 2));
        }
        break;
      case 'openai':
      default:
        console.log('🔍 完整响应数据:', data);
        console.log('🔍 choices数组:', data.choices);
        console.log('🔍 第一个choice:', data.choices?.[0]);
        console.log('🔍 message内容:', data.choices?.[0]?.message);
        console.log('🔍 content字段:', data.choices?.[0]?.message?.content);
        
        if (data.choices && data.choices[0] && data.choices[0].message) {
          answer = data.choices[0].message.content?.trim() || '';
          console.log(`✅ 解析到的回答: "${answer}"`);
          console.log(`✅ 回答长度: ${answer.length}`);
        } else {
          console.warn('⚠️ OpenAI响应结构异常:', JSON.stringify(data, null, 2));
        }
        break;
    }
    
    // 验证回答是否为空
    console.log('📊 解析到的最终答案:', JSON.stringify(answer));
    console.log('📊 答案类型:', typeof answer);
    console.log('📊 答案长度:', answer?.length || 0);
    
    if (!answer || answer.trim() === '') {
      console.warn('⚠️ API返回了空回答或无效内容，使用备用方案');
      console.log('📊 实际返回内容:', JSON.stringify(answer));
      return generateMockResponse(question);
    }
    
    console.log(`✅ 成功生成回答: "${answer}"`);
    return answer;
  } catch (error) {
    console.error('❌ 回答生成请求失败:', error);
    return generateMockResponse(question);
  }
};

// Real AI service integration for tagging
const callAIService = async (
  question: string, 
  answer: string, 
  config: AITaggingConfig,
  // 可选：提供之前的问答历史，用于更精准的分析
  userHistory?: { previousInsightLevel: number, recentTags: string[] }
) => {
  if (!config.provider) {
    config.provider = 'openai'; // 默认使用OpenAI格式
  }

  const prompt = `
  **角色：** 你是"集星问问"应用的"铸星师"。你的使命是评估用户自我探索对话的深度与精髓。

  **核心任务：** 分析下方的问题和回答。基于其内容，生成一个定义这颗"星星"的完整JSON对象。请保持你的洞察力、共情力和分析能力。

  **输入数据:**
  - 问题: "${question}"
  - 回答: "${answer}"

  **分析维度与输出格式:**

  请严格遵循以下结构，生成一个单独的JSON对象。不要在JSON对象之外添加任何解释性文字。

  {
    // 1. 星星的核心身份与生命力 (Core Identity & Longevity)
    "insight_level": {
      "value": <整数, 1-5>,
      "description": "<字符串: '星尘', '微光', '寻常星', '启明星', 或 '超新星'>"
    },
    "initial_luminosity": <整数, 0-100>, // 基于 insight_level。星尘=10, 超新星=100。
    
    // 2. 星星的主题归类 (Thematic Classification)
    "primary_category": "<字符串: 从下面的预定义列表中选择>",
    "tags": ["<字符串>", "<字符串>", "<字符串>", "<字符串>"], // 4-6个具体且有启发性的标签。

    // 3. 星星的情感与意图 (Emotional & Intentional Nuance)
    "emotional_tone": ["<字符串>", "<字符串>"], // 可包含多种基调, 例如: ["探寻中", "焦虑的"]
    "question_type": "<字符串: '探索型', '实用型', '事实型', '表达型'>",

    // 4. 星星的连接与成长潜力 (Connection & Growth Potential)
    "connection_potential": <整数, 1-5>, // 这颗星有多大可能性与其他重要人生主题产生连接？
    "suggested_follow_up": "<字符串: 一个开放式的、共情的问题，以鼓励用户进行更深入的思考>",
    
    // 5. 卡片展示内容 (Card Content)
    "card_summary": "<字符串: 一句话总结，捕捉这次觉察的精髓>"
  }


  **各字段详细说明:**

  1.  **insight_level (觉察深度等级)**: 这是最关键的指标。评估自我觉察的*深度*。
      *   **1: 星尘 (Stardust)**: 琐碎、事实性或表面的问题 (例如："今天天气怎么样？", "推荐一首歌")。这类星星非常暗淡，会迅速消逝。
      *   **2: 微光 (Faint Star)**: 日常的想法或简单的偏好 (例如："我好像有点不开心", "我该看什么电影?")。
      *   **3: 寻常星 (Common Star)**: 真正的自我反思或对个人行为的提问 (例如："我为什么总是拖延？", "如何处理和同事的关系?")。这是有意义星星的基准线。
      *   **4: 启明星 (Guiding Star)**: 展现了深度的坦诚，探索了核心信念、价值观或重要的人生事件 (例如："我害怕失败，这是否源于我的童年经历？", "我对人生的意义感到迷茫")。
      *   **5: 超新星 (Supernova)**: 一次深刻的、可能改变人生的顿悟，或一个足以重塑对生活、爱或自我看法的根本性洞见 (例如："我终于意识到，我一直追求的不是成功，而是他人的认可", "我决定放下怨恨，与自己和解")。

  2.  **initial_luminosity (初始亮度)**: 直接根据 \`insight_level.value\` 进行映射。
      *   1 -> 10, 2 -> 30, 3 -> 60, 4 -> 90, 5 -> 100。
      *   系统将使用此数值来计算星星的"半衰期"。

  3.  **primary_category (主要类别)**: 从此列表中选择最贴切的类别：
      *   \`relationships\`: 爱情、家庭、友谊、社交互动。
      *   \`personal_growth\`: 技能、习惯、自我认知、自信。
      *   \`career_and_purpose\`: 工作、抱负、人生方向、意义。
      *   \`emotional_wellbeing\`: 心理健康、情绪、压力、疗愈。
      *   \`philosophy_and_existence\`: 生命、死亡、价值观、信仰。
      *   \`creativity_and_passion\`: 爱好、灵感、艺术。
      *   \`daily_life\`: 日常、实用、普通事务。

  4.  **tags (标签)**: 生成具体、有意义的标签，用于连接星星。避免使用"工作"这样的宽泛词，应使用"职业倦怠"、"自我价值"或"原生家庭"等更具体的标签。

  5.  **emotional_tone (情感基调)**: 从列表中选择1-2个: \`探寻中\`, \`思考的\`, \`焦虑的\`, \`充满希望的\`, \`感激的\`, \`困惑的\`, \`忧郁的\`, \`坚定的\`, \`中性的\`。

  6.  **question_type (问题类型)**:
      *   \`探索型\`: 关于自我的"为什么"或"如果"类问题。
      *   \`实用型\`: 寻求解决方案的"如何做"类问题。
      *   \`事实型\`: 有客观答案的问题。
      *   \`表达型\`: 更多是情感的陈述，而非一个疑问。

  7.  **connection_potential (连接潜力)**: 评估该主题的基础性程度。
      *   1-2: 非常具体或琐碎的话题。
      *   3: 常见的人生议题。
      *   4-5: 一个普世的人类主题，如"爱"、"失落"、"人生意义"，极有可能形成一个主要星座。

  8.  **suggested_follow_up (建议的追问)**: 构思一个自然、不带评判的开放式问题，以引导用户进行下一步的觉察。这将用于"AI主动提问"功能。

  9.  **card_summary (卡片摘要)**: 将问答的核心洞见提炼成一句精炼、有力的总结，用于在卡片上展示给用户。

  **示例:**

  - 问题: "我发现自己总是在讨好别人，即使这让我自己很累。我为什么会这样？"
  - 回答: "这可能源于你内心深处对被接纳和被爱的渴望，或许在成长过程中，你学会了将他人的需求置于自己之上，以此来获得安全感和价值感。认识到这一点，是改变的开始。"

  **期望的JSON输出:**
  {
    "insight_level": {
      "value": 4,
      "description": "启明星"
    },
    "initial_luminosity": 90,
    "primary_category": "personal_growth",
    "tags": ["people_pleasing", "self_worth", "childhood_patterns", "setting_boundaries"],
    "emotional_tone": ["探寻中", "思考的"],
    "question_type": "探索型",
    "connection_potential": 5,
    "suggested_follow_up": "当你尝试不讨好别人时，你内心最担心的声音是什么？",
    "card_summary": "我认识到我的讨好行为，源于对被接纳的深层渴望。"
  }`;

  let requestBody;
  
  // 根据 provider 构建请求体
  switch (config.provider) {
    case 'gemini':
      requestBody = {
            contents: [{ parts: [{ text: prompt }] }],
            // 可以为gemini添加generationConfig
            generationConfig: { temperature: 0.3, maxOutputTokens: 50000 }
          };
      break;
    case 'openai':
    default:
      requestBody = {
                    model: config.model || 'gpt-3.5-turbo',
            messages: [{ role: 'user', content: prompt }],
            temperature: 0.3,
            max_tokens: 50000,
            response_format: { type: "json_object" }, // 强制JSON输出，对新模型支持很好
      };
      break;
  }

  try {
    console.log(`🔍 发送标签分析请求到 ${config.provider} API...`);
    console.log(`📤 请求体: ${JSON.stringify(requestBody)}`);
    console.log(`🔑 使用端点: ${config.endpoint}`);
    console.log(`📋 使用模型: ${config.model}`);
    
    const response = await fetch(config.endpoint!, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${config.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`❌ API响应错误 (${response.status}): ${errorText}`);
      throw new Error(`AI API error: ${response.status} - ${errorText}`);
    }

    const data = await response.json();
    console.log(`📥 原始API响应: `, JSON.stringify(data, null, 2));
    
    let content = '';
    
    // 根据 provider 解析响应
    switch (config.provider) {
      case 'gemini':
        if (data.candidates && data.candidates[0] && data.candidates[0].content) {
          content = data.candidates[0].content.parts[0].text || '';
          console.log(`✅ Gemini响应解析: "${content.slice(0, 100)}..."`);
        } else {
          console.warn('⚠️ Gemini响应结构异常:', JSON.stringify(data, null, 2));
        }
        break;
      case 'openai':
      default:
        console.log('🔍 标签分析 - 完整响应数据:', JSON.stringify(data, null, 2));
        console.log('🔍 标签分析 - choices数组:', data.choices);
        console.log('🔍 标签分析 - 第一个choice:', data.choices?.[0]);
        console.log('🔍 标签分析 - message内容:', data.choices?.[0]?.message);
        console.log('🔍 标签分析 - content字段:', data.choices?.[0]?.message?.content);
        
        if (data.choices && data.choices[0] && data.choices[0].message) {
          content = data.choices[0].message.content?.trim() || '';
          console.log(`✅ 标签分析 - 解析到的内容: "${content.slice(0, 100)}..."`);
          console.log(`✅ 标签分析 - 内容长度: ${content.length}`);
        } else {
          console.warn('⚠️ OpenAI响应结构异常:', JSON.stringify(data, null, 2));
        }
        break;
    }
    
    if (!content) {
      console.warn('⚠️ API返回了空内容，使用备用方案');
      return mockAIAnalysis(question, answer);
    }
    
    // 清理并解析JSON
    try {
      // AI有时会返回被 markdown 包裹的JSON，需要清理
      const cleanedContent = content
        .replace(/^```json\n?/, '')
        .replace(/\n?```$/, '')
        .trim();
      
      console.log(`🧹 清理后的内容: "${cleanedContent.slice(0, 100)}..."`);
      
      // 尝试解析JSON
      const parsedData = JSON.parse(cleanedContent);
      
      // 验证解析后的数据结构是否符合预期
      if (!parsedData.tags || !Array.isArray(parsedData.tags)) {
        console.warn('⚠️ 解析的JSON缺少必要的tags字段或格式不正确');
        return mockAIAnalysis(question, answer);
      }
      
      // 确保category和emotionalTone字段存在且有效
      if (!parsedData.category) parsedData.category = 'existential';
      if (!parsedData.emotionalTone || 
          !['positive', 'neutral', 'contemplative', 'seeking'].includes(parsedData.emotionalTone)) {
        parsedData.emotionalTone = 'contemplative';
      }
      
      // 确保keywords字段存在
      if (!parsedData.keywords || !Array.isArray(parsedData.keywords)) {
        parsedData.keywords = parsedData.tags.slice(0, 3);
      }
      
      console.log('✅ JSON解析成功:', parsedData);
      return parsedData;
    } catch (parseError) {
      console.error("❌ 无法解析API响应内容:", content);
      console.error("❌ 解析错误:", parseError);
      console.warn('⚠️ AI响应不是有效的JSON，使用备用方案');
      
      // 尝试从文本中提取JSON部分
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        try {
          const extractedJson = jsonMatch[0];
          console.log('🔍 尝试从响应中提取JSON:', extractedJson);
          const parsedData = JSON.parse(extractedJson);
          
          // 验证提取的JSON
          if (parsedData.tags && Array.isArray(parsedData.tags)) {
            console.log('✅ 成功从响应中提取JSON数据');
            return parsedData;
          }
        } catch (e) {
          console.warn('⚠️ 提取的JSON仍然无效:', e);
        }
      }
      
      return mockAIAnalysis(question, answer);
    }
  } catch (error) {
    console.error('❌ API请求失败:', error);
    return mockAIAnalysis(question, answer);
  }
};

// Enhanced similarity calculation with multiple methods
export const calculateStarSimilarity = (star1: Star, star2: Star): number => {
  if (!star1.tags || !star2.tags || star1.tags.length === 0 || star2.tags.length === 0) {
    return 0;
  }

  const tags1 = new Set(star1.tags.map(tag => tag.toLowerCase().trim()));
  const tags2 = new Set(star2.tags.map(tag => tag.toLowerCase().trim()));
  
  // Method 1: Exact tag matches (Jaccard similarity)
  const intersection = new Set([...tags1].filter(tag => tags2.has(tag)));
  const union = new Set([...tags1, ...tags2]);
  
  if (union.size === 0) return 0;
  
  const jaccardSimilarity = intersection.size / union.size;
  
  // Method 2: Partial tag matching (for related concepts)
  let partialMatches = 0;
  const totalComparisons = tags1.size * tags2.size;
  
  for (const tag1 of tags1) {
    for (const tag2 of tags2) {
      if (tag1.includes(tag2) || tag2.includes(tag1) || 
          areRelatedTags(tag1, tag2)) {
        partialMatches++;
      }
    }
  }
  
  const partialSimilarity = totalComparisons > 0 ? partialMatches / totalComparisons : 0;
  
  // Method 3: Category and tone bonuses
  const categoryBonus = star1.primary_category === star2.primary_category ? 0.3 : 0;
  // 情感基调现在是数组，比较是否有重叠的基调
  const toneBonus = star1.emotional_tone && star2.emotional_tone && 
                   star1.emotional_tone.some(tone => star2.emotional_tone.includes(tone)) ? 0.2 : 0;
  
  // Combine all methods with weights
  const finalSimilarity = (jaccardSimilarity * 0.5) + (partialSimilarity * 0.3) + categoryBonus + toneBonus;
  
  return Math.min(1, finalSimilarity);
};

// Helper function to check if tags are conceptually related
const areRelatedTags = (tag1: string, tag2: string): boolean => {
  const relatedGroups = [
    // Core Life Areas
    ['love', 'romance', 'heart', 'relationship', 'connection', 'intimacy'],
    ['family', 'parents', 'children', 'home', 'roots', 'legacy', 'connection'],
    ['friendship', 'social', 'trust', 'connection', 'support', 'loyalty'],
    ['career', 'work', 'vocation', 'profession', 'achievement', 'success'],
    ['education', 'learning', 'knowledge', 'skills', 'wisdom', 'growth'],
    ['health', 'wellness', 'fitness', 'balance', 'vitality', 'self-care'],
    ['finance', 'money', 'wealth', 'abundance', 'security', 'resources'],
    ['spirituality', 'faith', 'soul', 'meaning', 'divine', 'practice'],
    
    // Inner Experience
    ['emotions', 'feelings', 'expression', 'awareness', 'processing'],
    ['happiness', 'joy', 'fulfillment', 'contentment', 'bliss', 'satisfaction'],
    ['anxiety', 'fear', 'worry', 'stress', 'uncertainty', 'overwhelm'],
    ['grief', 'loss', 'sadness', 'mourning', 'healing', 'acceptance'],
    ['anger', 'frustration', 'resentment', 'boundaries', 'release'],
    ['shame', 'guilt', 'regret', 'inadequacy', 'worthiness', 'forgiveness'],
    
    // Self Development
    ['identity', 'self', 'authenticity', 'values', 'discovery', 'integration'],
    ['purpose', 'meaning', 'calling', 'mission', 'direction', 'contribution'],
    ['growth', 'development', 'evolution', 'improvement', 'transformation'],
    ['resilience', 'strength', 'adaptation', 'recovery', 'endurance'],
    ['creativity', 'expression', 'inspiration', 'imagination', 'innovation', 'artistry'],
    ['wisdom', 'insight', 'perspective', 'understanding', 'discernment', 'reflection'],
    
    // Relationships
    ['communication', 'expression', 'listening', 'understanding', 'clarity', 'connection'],
    ['intimacy', 'closeness', 'vulnerability', 'trust', 'bonding', 'openness'],
    ['boundaries', 'limits', 'protection', 'respect', 'space', 'autonomy'],
    ['conflict', 'resolution', 'understanding', 'healing', 'growth', 'peace'],
    ['trust', 'faith', 'reliability', 'consistency', 'safety', 'honesty'],
    
    // Life Philosophy
    ['meaning', 'purpose', 'significance', 'values', 'understanding', 'exploration'],
    ['mindfulness', 'presence', 'awareness', 'attention', 'consciousness', 'being'],
    ['gratitude', 'appreciation', 'thankfulness', 'recognition', 'abundance'],
    ['legacy', 'impact', 'contribution', 'remembrance', 'influence', 'heritage'],
    ['values', 'principles', 'ethics', 'morality', 'beliefs', 'priorities'],
    
    // Life Transitions
    ['change', 'transition', 'adaptation', 'adjustment', 'evolution', 'transformation'],
    ['decision', 'choice', 'discernment', 'wisdom', 'judgment', 'crossroads'],
    ['future', 'planning', 'vision', 'direction', 'goals', 'possibilities'],
    ['past', 'history', 'memories', 'reflection', 'lessons', 'integration'],
    ['letting-go', 'release', 'surrender', 'acceptance', 'closure', 'freedom'],
    
    // World Relations
    ['nature', 'environment', 'connection', 'outdoors', 'harmony', 'elements'],
    ['society', 'community', 'culture', 'belonging', 'contribution', 'citizenship'],
    ['justice', 'fairness', 'equality', 'rights', 'advocacy', 'ethics'],
    ['service', 'contribution', 'helping', 'impact', 'giving', 'purpose'],
    ['technology', 'digital', 'tools', 'innovation', 'adaptation', 'balance'],
    
    // Universal Concepts (meta-tags that connect across categories)
    ['growth', 'development', 'improvement', 'evolution', 'change', 'transformation'],
    ['purpose', 'meaning', 'mission', 'calling', 'significance', 'direction'],
    ['connection', 'relationship', 'bond', 'intimacy', 'belonging', 'attachment'],
    ['reflection', 'insight', 'awareness', 'understanding', 'perspective', 'wisdom']
  ];
  
  // Check if both tags appear in any of the related groups
  return relatedGroups.some(group => 
    group.includes(tag1.toLowerCase()) && group.includes(tag2.toLowerCase())
  );
};

// Find similar stars with lower threshold for better connections
export const findSimilarStars = (
  targetStar: Star, 
  allStars: Star[], 
  minSimilarity: number = 0.10, // Lower threshold to allow more connections
  maxConnections: number = 6 // Increase max connections
): Array<{ star: Star; similarity: number; sharedTags: string[] }> => {
  if (!targetStar.tags || targetStar.tags.length === 0) {
    return [];
  }
  
  const results = allStars
    .filter(star => star.id !== targetStar.id && star.tags && star.tags.length > 0)
    .map(star => {
      const similarity = calculateStarSimilarity(targetStar, star);
      
      // Find exact tag matches (prioritize these)
      const exactMatches = targetStar.tags?.filter(tag => 
        star.tags?.some(otherTag => otherTag.toLowerCase() === tag.toLowerCase())
      ) || [];
      
      // Find related tag matches
      const relatedMatches = targetStar.tags?.filter(tag => 
        !exactMatches.includes(tag) && // Don't double count
        star.tags?.some(otherTag => 
          areRelatedTags(tag.toLowerCase(), otherTag.toLowerCase())
        )
      ) || [];
      
      // Combine exact and related matches for display
      const sharedTags = [...exactMatches, ...relatedMatches];
      
      // Boost similarity score for exact tag matches
      const boostedSimilarity = exactMatches.length > 0 
        ? Math.min(1, similarity + (exactMatches.length * 0.1))
        : similarity;
      
      return { 
        star, 
        similarity: boostedSimilarity, 
        sharedTags,
        exactMatchCount: exactMatches.length,
        relatedMatchCount: relatedMatches.length
      };
    })
    .filter(result => result.similarity >= minSimilarity || result.exactMatchCount > 0)
    .sort((a, b) => {
      // First sort by exact match count
      if (a.exactMatchCount !== b.exactMatchCount) {
        return b.exactMatchCount - a.exactMatchCount;
      }
      // Then by overall similarity
      return b.similarity - a.similarity;
    })
    .slice(0, maxConnections);
  
  return results;
};

// Generate connections with improved algorithm that creates constellations
export const generateSmartConnections = (stars: Star[]): Connection[] => {
  const connections: Connection[] = [];
  const processedPairs = new Set<string>();
  const tagToStarsMap: Record<string, string[]> = {}; // Maps tags to star IDs
  
  console.log('🌟 Generating connections for', stars.length, 'stars');
  
  // First build a map of tags to star IDs to create constellations
  stars.forEach(star => {
    if (!star.tags || star.tags.length === 0) {
      console.warn(`⚠️ Star "${star.question}" has no tags, skipping connections`);
      return;
    }
    
    // Process each tag
    star.tags.forEach(tag => {
      const normalizedTag = tag.toLowerCase().trim();
      if (!tagToStarsMap[normalizedTag]) {
        tagToStarsMap[normalizedTag] = [];
      }
      tagToStarsMap[normalizedTag].push(star.id);
    });
  });
  
  // Create connections for each tag constellation
  Object.entries(tagToStarsMap).forEach(([tag, starIds]) => {
    // Only create connections if there are multiple stars with this tag
    if (starIds.length > 1) {
      for (let i = 0; i < starIds.length; i++) {
        for (let j = i + 1; j < starIds.length; j++) {
          const star1Id = starIds[i];
          const star2Id = starIds[j];
          const pairKey = [star1Id, star2Id].sort().join('-');
          
          if (!processedPairs.has(pairKey)) {
            const star1 = stars.find(s => s.id === star1Id);
            const star2 = stars.find(s => s.id === star2Id);
            
            if (star1 && star2) {
              // Calculate similarity but ensure connection due to shared tag
              const similarity = calculateStarSimilarity(star1, star2);
              
              // Find all shared tags between these stars
              const sharedTags = star1.tags.filter(t1 => 
                star2.tags.some(t2 => t1.toLowerCase() === t2.toLowerCase())
              );
              
              // Create connection with the shared tag that connected them
              const connection: Connection = {
                id: `connection-${star1Id}-${star2Id}`,
                fromStarId: star1Id,
                toStarId: star2Id,
                strength: Math.max(0.3, similarity), // Minimum connection strength of 0.3
                sharedTags: sharedTags.length > 0 ? sharedTags : [tag],
                constellationName: tag // Track which constellation this belongs to
              };
              
              connections.push(connection);
              processedPairs.add(pairKey);
              
              console.log('✨ Created constellation connection:', {
                tag,
                from: star1.question.slice(0, 30) + '...',
                to: star2.question.slice(0, 30) + '...',
                strength: connection.strength.toFixed(3),
                sharedTags: connection.sharedTags
              });
            }
          }
        }
      }
    }
  });
  
  // Now check if we should add any additional similarity-based connections
  // that weren't captured by the tag constellations
  stars.forEach(star => {
    if (!star.tags || star.tags.length === 0) return;
    
    const similarStars = findSimilarStars(star, stars, 0.25, 3);
    
    similarStars.forEach(({ star: similarStar, similarity, sharedTags }) => {
      const pairKey = [star.id, similarStar.id].sort().join('-');
      
      if (!processedPairs.has(pairKey) && similarity >= 0.25) {
        const connection: Connection = {
          id: `connection-${star.id}-${similarStar.id}`,
          fromStarId: star.id,
          toStarId: similarStar.id,
          strength: similarity,
          sharedTags: sharedTags.length > 0 ? sharedTags : ['universal-wisdom']
        };
        
        connections.push(connection);
        processedPairs.add(pairKey);
        
        console.log('✨ Created similarity connection:', {
          from: star.question.slice(0, 30) + '...',
          to: similarStar.question.slice(0, 30) + '...',
          strength: similarity.toFixed(3),
          sharedTags: connection.sharedTags
        });
      }
    });
  });
  
  console.log(`🎯 Generated ${connections.length} total connections`);
  return connections;
};

// 获取系统默认配置（从.env.local读取）
const getSystemDefaultConfig = (): AITaggingConfig => {
  try {
    const provider = (import.meta.env.VITE_DEFAULT_PROVIDER as ApiProvider) || 'openai';
    const apiKey = import.meta.env.VITE_OPENAI_API_KEY || import.meta.env.VITE_DEFAULT_API_KEY;
    const endpoint = import.meta.env.VITE_OPENAI_ENDPOINT || import.meta.env.VITE_DEFAULT_ENDPOINT;
    const model = import.meta.env.VITE_OPENAI_MODEL || import.meta.env.VITE_DEFAULT_MODEL || 'gpt-3.5-turbo';

    if (apiKey && endpoint) {
      console.log('📋 使用系统默认配置（后台配置）');
      console.log(`🌍 提供商: ${provider}, 模型: ${model}`);
      return { provider, apiKey, endpoint, model };
    }
    
    console.log('⚠️ 系统默认配置不完整，缺少API密钥或端点');
  } catch (error) {
    console.warn('❌ 无法读取环境变量中的默认配置:', error);
  }
  return {};
};

// Configuration for AI service (to be set by user)
let aiConfig: AITaggingConfig = {};
const CONFIG_STORAGE_KEY = 'stelloracle-ai-config';
const CONFIG_VERSION = '1.1.0'; // 更新版本号以支持新的provider字段

export const setAIConfig = (config: AITaggingConfig) => {
  // 保留现有配置中的任何未明确设置的字段
  aiConfig = { 
    ...aiConfig, 
    ...config,
    _version: CONFIG_VERSION, // 存储版本信息
    _lastUpdated: new Date().toISOString() // 存储最后更新时间
  };
  
  try {
    localStorage.setItem(CONFIG_STORAGE_KEY, JSON.stringify(aiConfig));
    console.log('✅ AI配置已保存到本地存储');
    
    // 创建备份
    localStorage.setItem(`${CONFIG_STORAGE_KEY}-backup`, JSON.stringify(aiConfig));
  } catch (error) {
    console.error('❌ 无法保存AI配置到本地存储:', error);
  }
};

export const getAIConfig = (): AITaggingConfig => {
  try {
    // 优先检查用户配置（前端配置）
    const stored = localStorage.getItem(CONFIG_STORAGE_KEY);
    
    if (stored) {
      const parsedConfig = JSON.parse(stored);
      // 检查用户是否配置了有效的API信息
      if (parsedConfig.apiKey && parsedConfig.endpoint) {
        aiConfig = parsedConfig;
        console.log('✅ 使用用户前端配置');
        console.log(`📋 配置: 提供商=${aiConfig.provider}, 模型=${aiConfig.model}`);
        return aiConfig;
      }
    }
    
    // 尝试从备份中恢复用户配置
    const backup = localStorage.getItem(`${CONFIG_STORAGE_KEY}-backup`);
    if (backup) {
      const backupConfig = JSON.parse(backup);
      if (backupConfig.apiKey && backupConfig.endpoint) {
        aiConfig = backupConfig;
        console.log('⚠️ 从备份恢复用户配置');
        // 恢复后立即保存到主存储
        localStorage.setItem(CONFIG_STORAGE_KEY, backup);
        return aiConfig;
      }
    }
    
    // 如果用户没有配置，使用系统默认配置（后台配置）
    console.log('🔍 用户未配置，检查系统默认配置...');
    const defaultConfig = getSystemDefaultConfig();
    if (Object.keys(defaultConfig).length > 0) {
      aiConfig = defaultConfig;
      console.log('🔄 使用系统默认配置（后台配置）');
      return aiConfig;
    }
    
    console.warn('⚠️ 未找到任何有效配置，将使用模拟数据');
    aiConfig = {};
    
  } catch (error) {
    console.error('❌ 获取AI配置时出错:', error);
    
    // 出错时尝试使用系统默认配置
    const defaultConfig = getSystemDefaultConfig();
    if (Object.keys(defaultConfig).length > 0) {
      aiConfig = defaultConfig;
      console.log('🔄 出错时使用系统默认配置');
    } else {
      aiConfig = {};
    }
  }
  
  return aiConfig;
};

// 配置迁移函数，用于处理版本变更
const migrateConfig = (oldConfig: any): AITaggingConfig => {
  console.log('⚙️ 迁移AI配置从版本', oldConfig._version, '到', CONFIG_VERSION);
  
  // 创建一个新的配置对象，确保保留所有重要字段
  const newConfig: AITaggingConfig = {
    provider: oldConfig.provider || 'openai', // 如果旧配置没有provider字段，默认为openai
    apiKey: oldConfig.apiKey,
    endpoint: oldConfig.endpoint,
    model: oldConfig.model,
    _version: CONFIG_VERSION,
    _lastUpdated: new Date().toISOString()
  };
  
  // 根据endpoint推断provider（向后兼容）
  if (!oldConfig.provider && oldConfig.endpoint) {
    if (oldConfig.endpoint.includes('googleapis')) {
      newConfig.provider = 'gemini';
    } else {
      newConfig.provider = 'openai';
    }
  }
  
  // 保存迁移后的配置
  localStorage.setItem(CONFIG_STORAGE_KEY, JSON.stringify(newConfig));
  console.log('✅ 配置迁移完成');
  
  return newConfig;
};

// 清除配置（用于调试或重置）
export const clearAIConfig = () => {
  aiConfig = {};
  try {
    localStorage.removeItem(CONFIG_STORAGE_KEY);
    localStorage.removeItem(`${CONFIG_STORAGE_KEY}-backup`);
    console.log('🧹 已清除AI配置');
  } catch (error) {
    console.error('❌ 无法清除AI配置:', error);
  }
};

// Export main categories of tags as suggestions for user selection
export const getMainTagSuggestions = (): string[] => {
  // Core life areas
  const coreLifeAreas = ['love', 'family', 'friendship', 'career', 'education', 
                        'health', 'finance', 'spirituality'];
  
  // Inner experience
  const innerExperience = ['emotions', 'happiness', 'anxiety', 'grief', 
                          'anger', 'shame'];
  
  // Self development
  const selfDevelopment = ['identity', 'purpose', 'growth', 'resilience', 
                          'creativity', 'wisdom'];
  
  // Relationships
  const relationships = ['communication', 'intimacy', 'boundaries', 
                        'conflict', 'trust'];
  
  // Life philosophy
  const lifePhilosophy = ['meaning', 'mindfulness', 'gratitude', 
                         'legacy', 'values'];
  
  // Life transitions
  const lifeTransitions = ['change', 'decision', 'future', 'past', 
                          'letting-go'];
  
  // World relations
  const worldRelations = ['nature', 'society', 'justice', 'service', 
                         'technology'];
  
  // Return all categories combined
  return [
    ...coreLifeAreas, 
    ...innerExperience,
    ...selfDevelopment,
    ...relationships,
    ...lifePhilosophy,
    ...lifeTransitions,
    ...worldRelations
  ];
};

// 检查API配置是否有效
export const checkApiConfiguration = (): boolean => {
  try {
    const config = getAIConfig();
    
    console.log('🔍 检查API配置...');
    
    // 检查是否有配置
    if (!config || Object.keys(config).length === 0) {
      console.warn('⚠️ 未找到API配置，将使用模拟数据');
      return false;
    }
    
    // 检查关键字段
    if (!config.provider) {
      console.warn('⚠️ 缺少API提供商配置，将使用默认值: openai');
      config.provider = 'openai';
    }
    
    if (!config.apiKey) {
      console.error('❌ 缺少API密钥，无法进行API调用');
      return false;
    }
    
    if (!config.endpoint) {
      console.error('❌ 缺少API端点，无法进行API调用');
      return false;
    }
    
    if (!config.model) {
      console.warn('⚠️ 缺少模型名称，将使用默认值');
      config.model = config.provider === 'gemini' ? 'gemini-1.5-flash-latest' : 'gpt-3.5-turbo';
    }
    
    console.log(`✅ API配置检查完成: 提供商=${config.provider}, 端点=${config.endpoint}, 模型=${config.model}`);
    
    // 更新配置
    setAIConfig(config);
    
    return true;
  } catch (error) {
    console.error('❌ 检查API配置时出错:', error);
    return false;
  }
};

// 在模块加载时检查配置
setTimeout(() => {
  console.log('🚀 初始化AI服务配置...');
  checkApiConfiguration();
}, 1000);
```

`staroracle-app_v1/src/utils/bookOfAnswers.ts`:

```ts
// Book of Answers utility
// This file contains the answers from the mystical "Book of Answers"

/**
 * The Book of Answers is a collection of mystical, thought-provoking responses
 * that provide guidance and reflection to unspoken questions.
 * Users mentally ask a question and receive one of these answers.
 */

export const getBookAnswer = (): string => {
  // Collection of answers inspired by "The Book of Answers" concept
  const answers = [
    "是的，毫无疑问。",
    "相信你的直觉。",
    "现在不是时候。",
    "宇宙已经安排好了。",
    "耐心等待，时机即将到来。",
    "不要强求，顺其自然。",
    "放手，让它去吧。",
    "是时候改变方向了。",
    "这个问题的答案就在你心中。",
    "寻求更多信息后再决定。",
    "绝对不要。",
    "现在就行动。",
    "接受它，然后前进。",
    "你已经知道答案了。",
    "这个决定将带来意想不到的结果。",
    "重新思考你的问题。",
    "寻求他人的建议。",
    "相信这个过程。",
    "答案将在梦中揭示。",
    "观察自然的征兆。",
    "是的，但不要操之过急。",
    "不，但不要放弃希望。",
    "暂时搁置这个问题。",
    "专注于当下。",
    "回顾过去的经验。",
    "这不是正确的问题。",
    "跟随你的心。",
    "这是一个转折点。",
    "答案就在你面前。",
    "勇敢地面对恐惧。",
    "等待更清晰的指引。",
    "信任这个旅程。",
    "接受不确定性。",
    "改变你的视角。",
    "这个问题需要更深入的思考。",
    "现在是行动的时候了。",
    "寻找平衡。",
    "放下过去。",
    "相信宇宙的时机。",
    "答案将在意想不到的地方出现。",
    "保持开放的心态。",
    "这个决定将影响你的未来道路。",
    "不要被表面现象迷惑。",
    "寻找内在的智慧。",
    "是的，如果你全心投入。",
    "不，除非情况发生变化。",
    "宇宙正在为你创造更好的机会。",
    "这个挑战是一份礼物。",
    "你比自己想象的更强大。",
    "答案在星光中闪烁。",
  ];
  
  // Return a random answer
  return answers[Math.floor(Math.random() * answers.length)];
};

// Get a more detailed, reflective follow-up to an answer
export const getAnswerReflection = (answer: string): string => {
  // Map of reflections for each answer type
  const reflections: Record<string, string[]> = {
    // Positive answers
    "是的，毫无疑问。": [
      "有时宇宙会给予明确的指引，这是一个清晰的信号。",
      "当道路如此清晰，勇敢前行是唯一的选择。",
      "确定性是一种礼物，珍视这一刻的清晰。"
    ],
    "相信你的直觉。": [
      "内在的声音往往比理性更能接近真相。",
      "直觉是灵魂的语言，它知道理性尚未发现的真理。",
      "最深刻的智慧常常以感觉的形式出现。"
    ],
    
    // Waiting answers
    "现在不是时候。": [
      "时机的重要性常被低估，耐心等待是一种智慧。",
      "有些种子需要更长的时间才能发芽，给它应有的时间。",
      "延迟并不意味着拒绝，只是宇宙的时间与我们的期望不同。"
    ],
    "耐心等待，时机即将到来。": [
      "等待的过程本身就是准备的一部分。",
      "即将到来的转变需要你完全准备好。",
      "黎明前的黑暗常常最为深沉。"
    ],
    
    // Default reflections for other answers
    "default": [
      "每个答案都是一面镜子，反射出提问者内心的真相。",
      "有时答案的价值不在于它的内容，而在于它引发的思考。",
      "智慧不在于获得确定的答案，而在于提出更好的问题。",
      "答案可能会随着时间的推移而揭示其更深层的含义。",
      "星辰的指引是微妙的，需要安静的心灵才能理解。"
    ]
  };
  
  // Get reflection for the specific answer or use default
  const specificReflections = reflections[answer] || reflections["default"];
  return specificReflections[Math.floor(Math.random() * specificReflections.length)];
}; 
```

`staroracle-app_v1/src/utils/constellationTemplates.ts`:

```ts
import { ConstellationTemplate, Star, Connection } from '../types';

// 辅助函数，将旧的emotionalTone转换为新的格式
const convertOldEmotionalTone = (oldTone: string): string => {
  const mapping: Record<string, string> = {
    'positive': '充满希望的',
    'contemplative': '思考的',
    'seeking': '探寻中',
    'neutral': '中性的'
  };
  return mapping[oldTone] || '探寻中';
};

// 辅助函数，将旧的category转换为新的primary_category
const convertOldCategory = (oldCategory: string): string => {
  const mapping: Record<string, string> = {
    'relationships': 'relationships',
    'personal_growth': 'personal_growth',
    'life_direction': 'career_and_purpose',
    'wellbeing': 'emotional_wellbeing',
    'material': 'daily_life',
    'creative': 'creativity_and_passion',
    'existential': 'philosophy_and_existence'
  };
  return mapping[oldCategory] || 'philosophy_and_existence';
};

// 根据问题文本推断问题类型
const getQuestionType = (question: string): string => {
  const lowerQuestion = question.toLowerCase();
  if (lowerQuestion.includes('为什么') || lowerQuestion.includes('why') || 
      lowerQuestion.includes('是否') || lowerQuestion.includes('if') || 
      lowerQuestion.includes('是不是')) {
    return '探索型';
  } else if (lowerQuestion.includes('如何') || lowerQuestion.includes('how to') || 
             lowerQuestion.includes('方法') || lowerQuestion.includes('steps')) {
    return '实用型';
  } else if (lowerQuestion.includes('什么是') || lowerQuestion.includes('what is') || 
             lowerQuestion.includes('谁') || lowerQuestion.includes('who') || 
             lowerQuestion.includes('where')) {
    return '事实型';
  }
  // 默认返回探索型
  return '探索型';
};

// 根据类别生成默认的追问
const getSuggestedFollowUp = (category: string): string => {
  const followUpMap: Record<string, string> = {
    'relationships': '这种关系模式在你生活的其他方面是否也有体现？',
    'personal_growth': '你觉得是什么阻碍了你在这方面的进一步成长？',
    'career_and_purpose': '如果没有任何限制，你理想中的职业道路是什么样的？',
    'emotional_wellbeing': '这种情绪是从什么时候开始的，有没有特定的触发点？',
    'philosophy_and_existence': '这个信念对你日常生活的决策有什么影响？',
    'creativity_and_passion': '你上一次完全沉浸在创造性活动中是什么时候？那感觉如何？',
    'daily_life': '这个日常习惯如何影响了你的整体生活质量？'
  };
  return followUpMap[category] || '关于这个话题，你还有什么更深层次的感受或想法？';
};

// 12星座模板数据
export const ZODIAC_TEMPLATES: ConstellationTemplate[] = [
  {
    id: 'aries',
    name: 'Aries',
    chineseName: '白羊座',
    description: '勇敢的开拓者，充满激情与活力',
    element: 'fire',
    centerX: 25,
    centerY: 30,
    scale: 1.0,
    stars: [
      {
        id: 'aries-1',
        x: 0,
        y: 0,
        size: 4,
        brightness: 1.0,
        question: '我如何发现自己的勇气？',
        answer: '勇气如火星般燃烧，在行动中点燃，在挑战中壮大。',
        tags: ['courage', 'leadership', 'action', 'passion', 'initiative'],
        category: 'personal_growth',
        emotionalTone: 'positive',
        isMainStar: true
      },
      {
        id: 'aries-2',
        x: -8,
        y: 5,
        size: 3,
        brightness: 0.8,
        question: '如何成为更好的领导者？',
        answer: '真正的领导者如北极星，不是最亮的，却为他人指引方向。',
        tags: ['leadership', 'guidance', 'responsibility', 'vision'],
        category: 'life_direction',
        emotionalTone: 'contemplative'
      },
      {
        id: 'aries-3',
        x: 8,
        y: -3,
        size: 2.5,
        brightness: 0.7,
        question: '我的激情在哪里？',
        answer: '激情如恒星核心的聚变，从内心深处释放无穷能量。',
        tags: ['passion', 'energy', 'motivation', 'drive'],
        category: 'personal_growth',
        emotionalTone: 'seeking'
      },
      {
        id: 'aries-4',
        x: 3,
        y: 8,
        size: 2,
        brightness: 0.6,
        question: '如何开始新的征程？',
        answer: '每个新开始都是宇宙的重新创造，勇敢迈出第一步。',
        tags: ['new_beginnings', 'adventure', 'courage', 'change'],
        category: 'life_direction',
        emotionalTone: 'positive'
      }
    ],
    connections: [
      { fromStarId: 'aries-1', toStarId: 'aries-2', strength: 0.8, sharedTags: ['leadership', 'courage'] },
      { fromStarId: 'aries-1', toStarId: 'aries-3', strength: 0.7, sharedTags: ['passion', 'energy'] },
      { fromStarId: 'aries-2', toStarId: 'aries-4', strength: 0.6, sharedTags: ['leadership', 'new_beginnings'] }
    ]
  },
  {
    id: 'taurus',
    name: 'Taurus',
    chineseName: '金牛座',
    description: '稳重的建设者，追求美好与安全',
    element: 'earth',
    centerX: 75,
    centerY: 25,
    scale: 1.0,
    stars: [
      {
        id: 'taurus-1',
        x: 0,
        y: 0,
        size: 4,
        brightness: 1.0,
        question: '如何建立稳定的生活？',
        answer: '稳定如大地般深厚，在耐心与坚持中慢慢积累。',
        tags: ['stability', 'security', 'patience', 'persistence'],
        category: 'wellbeing',
        emotionalTone: 'contemplative',
        isMainStar: true
      },
      {
        id: 'taurus-2',
        x: -6,
        y: -4,
        size: 3,
        brightness: 0.8,
        question: '什么是真正的财富？',
        answer: '真正的财富不在金库，而在心灵的富足与关系的深度。',
        tags: ['wealth', 'abundance', 'values', 'material'],
        category: 'material',
        emotionalTone: 'contemplative'
      },
      {
        id: 'taurus-3',
        x: 7,
        y: 6,
        size: 2.5,
        brightness: 0.7,
        question: '如何欣赏生活中的美？',
        answer: '美如花朵在感恩的土壤中绽放，用心感受每个瞬间。',
        tags: ['beauty', 'appreciation', 'senses', 'gratitude'],
        category: 'wellbeing',
        emotionalTone: 'positive'
      },
      {
        id: 'taurus-4',
        x: 2,
        y: -8,
        size: 2,
        brightness: 0.6,
        question: '如何保持内心的平静？',
        answer: '平静如深山古井，不因外界波动而失去内在的宁静。',
        tags: ['peace', 'calm', 'stability', 'inner_strength'],
        category: 'wellbeing',
        emotionalTone: 'contemplative'
      }
    ],
    connections: [
      { fromStarId: 'taurus-1', toStarId: 'taurus-2', strength: 0.7, sharedTags: ['stability', 'security'] },
      { fromStarId: 'taurus-1', toStarId: 'taurus-4', strength: 0.8, sharedTags: ['stability', 'peace'] },
      { fromStarId: 'taurus-3', toStarId: 'taurus-4', strength: 0.6, sharedTags: ['peace', 'appreciation'] }
    ]
  },
  {
    id: 'gemini',
    name: 'Gemini',
    chineseName: '双子座',
    description: '好奇的探索者，善于沟通与学习',
    element: 'air',
    centerX: 50,
    centerY: 70,
    scale: 1.0,
    stars: [
      {
        id: 'gemini-1',
        x: -4,
        y: 0,
        size: 3.5,
        brightness: 0.9,
        question: '如何提升我的沟通能力？',
        answer: '沟通如双星系统，倾听与表达相互环绕，创造和谐共鸣。',
        tags: ['communication', 'expression', 'listening', 'connection'],
        category: 'relationships',
        emotionalTone: 'seeking',
        isMainStar: true
      },
      {
        id: 'gemini-2',
        x: 4,
        y: 0,
        size: 3.5,
        brightness: 0.9,
        question: '如何平衡生活的多面性？',
        answer: '如月亮的阴晴圆缺，拥抱你内在的多重面向，它们都是完整的你。',
        tags: ['balance', 'duality', 'adaptability', 'flexibility'],
        category: 'personal_growth',
        emotionalTone: 'contemplative',
        isMainStar: true
      },
      {
        id: 'gemini-3',
        x: 0,
        y: -6,
        size: 2.5,
        brightness: 0.7,
        question: '如何保持学习的热情？',
        answer: '好奇心如星际尘埃，在宇宙中永远飘散，永远发现新的世界。',
        tags: ['learning', 'curiosity', 'knowledge', 'growth'],
        category: 'personal_growth',
        emotionalTone: 'positive'
      },
      {
        id: 'gemini-4',
        x: 0,
        y: 6,
        size: 2,
        brightness: 0.6,
        question: '如何建立深度的友谊？',
        answer: '友谊如星座，看似分散的点，实则由无形的引力紧密相连。',
        tags: ['friendship', 'connection', 'loyalty', 'understanding'],
        category: 'relationships',
        emotionalTone: 'positive'
      }
    ],
    connections: [
      { fromStarId: 'gemini-1', toStarId: 'gemini-2', strength: 0.9, sharedTags: ['communication', 'balance'] },
      { fromStarId: 'gemini-1', toStarId: 'gemini-4', strength: 0.7, sharedTags: ['communication', 'connection'] },
      { fromStarId: 'gemini-2', toStarId: 'gemini-3', strength: 0.6, sharedTags: ['growth', 'adaptability'] }
    ]
  },
  {
    id: 'cancer',
    name: 'Cancer',
    chineseName: '巨蟹座',
    description: '温暖的守护者，重视家庭与情感',
    element: 'water',
    centerX: 20,
    centerY: 75,
    scale: 1.0,
    stars: [
      {
        id: 'cancer-1',
        x: 0,
        y: 0,
        size: 4,
        brightness: 1.0,
        question: '如何创造温暖的家？',
        answer: '家不在建筑中，而在心灵的港湾，用爱编织的安全感。',
        tags: ['home', 'family', 'security', 'nurturing', 'love'],
        category: 'relationships',
        emotionalTone: 'positive',
        isMainStar: true
      },
      {
        id: 'cancer-2',
        x: -5,
        y: 5,
        size: 3,
        brightness: 0.8,
        question: '如何处理敏感的情感？',
        answer: '敏感如月光映水，既是脆弱也是力量，学会拥抱你的深度。',
        tags: ['emotions', 'sensitivity', 'intuition', 'empathy'],
        category: 'personal_growth',
        emotionalTone: 'contemplative'
      },
      {
        id: 'cancer-3',
        x: 6,
        y: -3,
        size: 2.5,
        brightness: 0.7,
        question: '如何照顾他人又不失自我？',
        answer: '如月亮照亮夜空却不失去自己的光芒，给予中保持自我的完整。',
        tags: ['caring', 'boundaries', 'self_care', 'balance'],
        category: 'relationships',
        emotionalTone: 'seeking'
      },
      {
        id: 'cancer-4',
        x: 2,
        y: 7,
        size: 2,
        brightness: 0.6,
        question: '如何找到内心的安全感？',
        answer: '真正的安全感来自内心的根基，如深海般宁静而深邃。',
        tags: ['security', 'inner_peace', 'self_trust', 'stability'],
        category: 'wellbeing',
        emotionalTone: 'contemplative'
      }
    ],
    connections: [
      { fromStarId: 'cancer-1', toStarId: 'cancer-2', strength: 0.8, sharedTags: ['emotions', 'nurturing'] },
      { fromStarId: 'cancer-1', toStarId: 'cancer-4', strength: 0.7, sharedTags: ['security', 'home'] },
      { fromStarId: 'cancer-2', toStarId: 'cancer-3', strength: 0.6, sharedTags: ['emotions', 'caring'] }
    ]
  },
  {
    id: 'leo',
    name: 'Leo',
    chineseName: '狮子座',
    description: '自信的表演者，散发光芒与魅力',
    element: 'fire',
    centerX: 80,
    centerY: 60,
    scale: 1.0,
    stars: [
      {
        id: 'leo-1',
        x: 0,
        y: 0,
        size: 4.5,
        brightness: 1.0,
        question: '如何建立真正的自信？',
        answer: '自信如太阳般从内心发光，不需要外界的认可来证明自己的价值。',
        tags: ['confidence', 'self_worth', 'authenticity', 'inner_strength'],
        category: 'personal_growth',
        emotionalTone: 'positive',
        isMainStar: true
      },
      {
        id: 'leo-2',
        x: -6,
        y: -4,
        size: 3,
        brightness: 0.8,
        question: '如何展现我的创造力？',
        answer: '创造力如恒星的光芒，需要勇气点燃，用热情维持燃烧。',
        tags: ['creativity', 'expression', 'art', 'passion', 'uniqueness'],
        category: 'creative',
        emotionalTone: 'positive'
      },
      {
        id: 'leo-3',
        x: 7,
        y: 5,
        size: 2.5,
        brightness: 0.7,
        question: '如何成为他人的光芒？',
        answer: '如太阳照亮行星，真正的光芒在于启发他人发现自己的光。',
        tags: ['inspiration', 'leadership', 'generosity', 'influence'],
        category: 'relationships',
        emotionalTone: 'positive'
      },
      {
        id: 'leo-4',
        x: 3,
        y: -7,
        size: 2,
        brightness: 0.6,
        question: '如何平衡自我与谦逊？',
        answer: '真正的王者如太阳，强大而温暖，照亮一切却不炫耀自己。',
        tags: ['humility', 'balance', 'wisdom', 'maturity'],
        category: 'personal_growth',
        emotionalTone: 'contemplative'
      }
    ],
    connections: [
      { fromStarId: 'leo-1', toStarId: 'leo-2', strength: 0.8, sharedTags: ['confidence', 'creativity'] },
      { fromStarId: 'leo-1', toStarId: 'leo-3', strength: 0.7, sharedTags: ['confidence', 'leadership'] },
      { fromStarId: 'leo-2', toStarId: 'leo-3', strength: 0.6, sharedTags: ['creativity', 'inspiration'] }
    ]
  },
  {
    id: 'virgo',
    name: 'Virgo',
    chineseName: '处女座',
    description: '完美的工匠，追求精确与服务',
    element: 'earth',
    centerX: 30,
    centerY: 50,
    scale: 1.0,
    stars: [
      {
        id: 'virgo-1',
        x: 0,
        y: 0,
        size: 4,
        brightness: 1.0,
        question: '如何在细节中找到完美？',
        answer: '完美不在无瑕，而在每个细节中倾注的爱与专注。',
        tags: ['perfection', 'attention', 'craftsmanship', 'dedication'],
        category: 'personal_growth',
        emotionalTone: 'contemplative',
        isMainStar: true
      },
      {
        id: 'virgo-2',
        x: -5,
        y: 6,
        size: 3,
        brightness: 0.8,
        question: '如何更好地服务他人？',
        answer: '服务如星光，看似微小却能照亮他人前行的道路。',
        tags: ['service', 'helping', 'contribution', 'purpose'],
        category: 'relationships',
        emotionalTone: 'positive'
      },
      {
        id: 'virgo-3',
        x: 6,
        y: -4,
        size: 2.5,
        brightness: 0.7,
        question: '如何管理我的时间和精力？',
        answer: '时间如星辰运行，有序而精确，在规律中找到效率的美。',
        tags: ['organization', 'efficiency', 'planning', 'discipline'],
        category: 'life_direction',
        emotionalTone: 'seeking'
      },
      {
        id: 'virgo-4',
        x: 2,
        y: 8,
        size: 2,
        brightness: 0.6,
        question: '如何接受不完美的自己？',
        answer: '如星空中的每颗星都有独特的光芒，不完美也是美的一种形式。',
        tags: ['self_acceptance', 'growth', 'compassion', 'healing'],
        category: 'personal_growth',
        emotionalTone: 'contemplative'
      }
    ],
    connections: [
      { fromStarId: 'virgo-1', toStarId: 'virgo-3', strength: 0.8, sharedTags: ['perfection', 'organization'] },
      { fromStarId: 'virgo-1', toStarId: 'virgo-4', strength: 0.7, sharedTags: ['perfection', 'growth'] },
      { fromStarId: 'virgo-2', toStarId: 'virgo-4', strength: 0.6, sharedTags: ['service', 'compassion'] }
    ]
  }
  // 可以继续添加其他6个星座...
];

// 获取所有星座模板
export const getAllTemplates = (): ConstellationTemplate[] => {
  return ZODIAC_TEMPLATES;
};

// 根据ID获取特定星座模板
export const getTemplateById = (id: string): ConstellationTemplate | undefined => {
  return ZODIAC_TEMPLATES.find(template => template.id === id);
};

// 根据元素获取星座模板
export const getTemplatesByElement = (element: 'fire' | 'earth' | 'air' | 'water'): ConstellationTemplate[] => {
  return ZODIAC_TEMPLATES.filter(template => template.element === element);
};

// 将模板转换为实际的星星和连接
export const instantiateTemplate = (template: ConstellationTemplate, offsetX: number = 0, offsetY: number = 0) => {
  const stars = template.stars.map(starData => {
    // 将旧的category和emotionalTone字段转换为新的字段格式
    const emotional_tone = Array.isArray(starData.emotional_tone) ? 
      starData.emotional_tone : 
      [convertOldEmotionalTone(starData.emotionalTone)];

    // 转换旧的类别字段
    const primary_category = starData.primary_category || 
                       convertOldCategory(starData.category as string);
    
    // 创建新的星星对象
    return {
      id: `${template.id}-${starData.id}-${Date.now()}`,
      x: template.centerX + (starData.x * template.scale) + offsetX,
      y: template.centerY + (starData.y * template.scale) + offsetY,
      size: starData.size,
      brightness: starData.brightness,
      question: starData.question,
      answer: starData.answer,
      imageUrl: `https://images.pexels.com/photos/${Math.floor(Math.random() * 2000000) + 1000000}/pexels-photo-${Math.floor(Math.random() * 2000000) + 1000000}.jpeg`,
      createdAt: new Date(),
      isSpecial: starData.isMainStar || false,
      tags: starData.tags,
      primary_category: primary_category,
      emotional_tone: emotional_tone,
      question_type: starData.question_type || getQuestionType(starData.question),
      insight_level: starData.insight_level || {
        value: starData.isMainStar ? 4 : 3,
        description: starData.isMainStar ? '启明星' : '寻常星'
      },
      initial_luminosity: starData.initial_luminosity || (starData.isMainStar ? 90 : 60),
      connection_potential: starData.connection_potential || 4,
      suggested_follow_up: starData.suggested_follow_up || getSuggestedFollowUp(primary_category),
      card_summary: starData.card_summary || starData.question,
      isTemplate: true,
      templateType: template.chineseName
    };
  });

  const connections: Connection[] = [];
  
  // Create connections, filtering out null values
  template.connections.forEach(connData => {
    const fromStar = stars.find(s => s.id.includes(connData.fromStarId));
    const toStar = stars.find(s => s.id.includes(connData.toStarId));
    
    if (fromStar && toStar) {
      connections.push({
        id: `connection-${fromStar.id}-${toStar.id}`,
        fromStarId: fromStar.id,
        toStarId: toStar.id,
        strength: connData.strength,
        sharedTags: connData.sharedTags,
        isTemplate: true
      });
    }
  });

  return { stars, connections };
};
```

`staroracle-app_v1/src/utils/hapticUtils.ts`:

```ts
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
```

`staroracle-app_v1/src/utils/imageUtils.ts`:

```ts
// This function simulates generating a unique cosmic image for each star
// In a real app, this would connect to an AI image generation service
export const generateRandomStarImage = (): string => {
  // Array of cosmic-themed images from Pexels
  const cosmicImages = [
    'https://images.pexels.com/photos/1169754/pexels-photo-1169754.jpeg',
    'https://images.pexels.com/photos/1252890/pexels-photo-1252890.jpeg',
    'https://images.pexels.com/photos/1274260/pexels-photo-1274260.jpeg',
    'https://images.pexels.com/photos/1694000/pexels-photo-1694000.jpeg',
    'https://images.pexels.com/photos/1257860/pexels-photo-1257860.jpeg',
    'https://images.pexels.com/photos/1906658/pexels-photo-1906658.jpeg',
    'https://images.pexels.com/photos/1146134/pexels-photo-1146134.jpeg',
    'https://images.pexels.com/photos/1341279/pexels-photo-1341279.jpeg',
    'https://images.pexels.com/photos/816608/pexels-photo-816608.jpeg',
    'https://images.pexels.com/photos/1434608/pexels-photo-1434608.jpeg',
    'https://images.pexels.com/photos/1938348/pexels-photo-1938348.jpeg',
    'https://images.pexels.com/photos/1693095/pexels-photo-1693095.jpeg',
  ];
  
  // Return a random image from the array
  return cosmicImages[Math.floor(Math.random() * cosmicImages.length)];
};
```

`staroracle-app_v1/src/utils/inspirationCards.ts`:

```ts
// 灵感卡片系统
export interface InspirationCard {
  id: string;
  question: string;
  reflection: string;
  tags: string[];
  category: string;
  emotionalTone: 'positive' | 'neutral' | 'contemplative' | 'seeking';
}

// 灵感卡片数据库
const INSPIRATION_CARDS: InspirationCard[] = [
  // 自我探索类
  {
    id: 'self-1',
    question: '如果今天是你生命的最后一天，你最想做什么？',
    reflection: '生命的有限性让每个选择都变得珍贵，真正重要的事物会在这种思考中浮现。',
    tags: ['life', 'priorities', 'meaning', 'death', 'values'],
    category: 'existential',
    emotionalTone: 'contemplative'
  },
  {
    id: 'self-2',
    question: '你最害怕失去的是什么？为什么？',
    reflection: '恐惧往往指向我们最珍视的东西，了解恐惧就是了解自己的价值观。',
    tags: ['fear', 'loss', 'values', 'attachment', 'security'],
    category: 'personal_growth',
    emotionalTone: 'seeking'
  },
  {
    id: 'self-3',
    question: '如果你可以给10年前的自己一个建议，会是什么？',
    reflection: '回望过去的智慧往往是对当下最好的指引。',
    tags: ['wisdom', 'growth', 'regret', 'learning', 'time'],
    category: 'personal_growth',
    emotionalTone: 'contemplative'
  },
  {
    id: 'self-4',
    question: '什么时候你感到最像真正的自己？',
    reflection: '真实的自我在特定的时刻和环境中会自然流露，找到这些时刻就是找到回家的路。',
    tags: ['authenticity', 'self', 'identity', 'freedom', 'truth'],
    category: 'personal_growth',
    emotionalTone: 'seeking'
  },

  // 关系类
  {
    id: 'relationship-1',
    question: '你在关系中最容易重复的模式是什么？',
    reflection: '我们在关系中的模式往往反映了内心深处的信念和恐惧。',
    tags: ['relationships', 'patterns', 'behavior', 'awareness', 'growth'],
    category: 'relationships',
    emotionalTone: 'contemplative'
  },
  {
    id: 'relationship-2',
    question: '如果你的朋友用三个词形容你，会是哪三个词？',
    reflection: '他人眼中的我们往往能揭示我们自己看不到的特质。',
    tags: ['identity', 'perception', 'friendship', 'self_image', 'reflection'],
    category: 'relationships',
    emotionalTone: 'seeking'
  },
  {
    id: 'relationship-3',
    question: '你最想对某个人说但一直没说的话是什么？',
    reflection: '未说出的话语往往承载着我们最深的情感和遗憾。',
    tags: ['communication', 'regret', 'courage', 'expression', 'love'],
    category: 'relationships',
    emotionalTone: 'contemplative'
  },

  // 梦想与目标类
  {
    id: 'dreams-1',
    question: '如果金钱不是问题，你会如何度过你的一生？',
    reflection: '当外在限制被移除，内心真正的渴望就会显现。',
    tags: ['dreams', 'freedom', 'purpose', 'passion', 'life_design'],
    category: 'life_direction',
    emotionalTone: 'positive'
  },
  {
    id: 'dreams-2',
    question: '你小时候的梦想现在还重要吗？为什么？',
    reflection: '童年的梦想往往包含着我们最纯真的渴望，值得重新审视。',
    tags: ['childhood', 'dreams', 'growth', 'change', 'authenticity'],
    category: 'life_direction',
    emotionalTone: 'contemplative'
  },
  {
    id: 'dreams-3',
    question: '什么阻止了你追求真正想要的生活？',
    reflection: '障碍往往不在外界，而在我们内心的信念和恐惧中。',
    tags: ['obstacles', 'fear', 'limiting_beliefs', 'courage', 'change'],
    category: 'life_direction',
    emotionalTone: 'seeking'
  },

  // 情感与内心类
  {
    id: 'emotion-1',
    question: '你最近一次真正快乐是什么时候？那种感觉是什么样的？',
    reflection: '快乐的记忆是心灵的指南针，指向我们真正需要的方向。',
    tags: ['happiness', 'joy', 'memory', 'fulfillment', 'gratitude'],
    category: 'wellbeing',
    emotionalTone: 'positive'
  },
  {
    id: 'emotion-2',
    question: '如果你的情绪是一种天气，现在是什么天气？',
    reflection: '用自然的语言描述情绪，往往能带来更深的理解和接纳。',
    tags: ['emotions', 'metaphor', 'awareness', 'feelings', 'weather'],
    category: 'wellbeing',
    emotionalTone: 'contemplative'
  },
  {
    id: 'emotion-3',
    question: '你最想治愈内心的哪个部分？',
    reflection: '承认伤痛是治愈的第一步，每个伤口都包含着成长的种子。',
    tags: ['healing', 'pain', 'growth', 'self_care', 'compassion'],
    category: 'wellbeing',
    emotionalTone: 'seeking'
  },

  // 创造与表达类
  {
    id: 'creative-1',
    question: '如果你必须创造一件作品来代表现在的你，会是什么？',
    reflection: '创造是自我表达的最直接方式，作品往往比言语更能传达内心。',
    tags: ['creativity', 'expression', 'art', 'identity', 'representation'],
    category: 'creative',
    emotionalTone: 'positive'
  },
  {
    id: 'creative-2',
    question: '你最想学会的技能是什么？为什么？',
    reflection: '我们渴望学习的技能往往反映了内心未被满足的表达需求。',
    tags: ['learning', 'skills', 'growth', 'curiosity', 'development'],
    category: 'creative',
    emotionalTone: 'seeking'
  },

  // 哲学与存在类
  {
    id: 'philosophy-1',
    question: '如果你可以知道一个关于宇宙的终极真理，你想知道什么？',
    reflection: '我们对终极真理的好奇往往反映了当下最困扰我们的问题。',
    tags: ['truth', 'universe', 'meaning', 'curiosity', 'existence'],
    category: 'existential',
    emotionalTone: 'contemplative'
  },
  {
    id: 'philosophy-2',
    question: '什么让你感到生命是有意义的？',
    reflection: '意义不是被发现的，而是被创造的，在我们的选择和行动中诞生。',
    tags: ['meaning', 'purpose', 'life', 'significance', 'values'],
    category: 'existential',
    emotionalTone: 'contemplative'
  },
  {
    id: 'philosophy-3',
    question: '如果今天是世界的最后一天，你会如何度过？',
    reflection: '末日的假设能够剥离一切不重要的东西，让真正珍贵的浮现。',
    tags: ['priorities', 'death', 'meaning', 'love', 'presence'],
    category: 'existential',
    emotionalTone: 'contemplative'
  },

  // 成长与变化类
  {
    id: 'growth-1',
    question: '你最想改变自己的哪个方面？为什么？',
    reflection: '改变的渴望往往指向我们对更好自己的向往，也反映了当下的不满足。',
    tags: ['change', 'growth', 'improvement', 'self_development', 'aspiration'],
    category: 'personal_growth',
    emotionalTone: 'seeking'
  },
  {
    id: 'growth-2',
    question: '你从最大的失败中学到了什么？',
    reflection: '失败是最严厉也是最慈悲的老师，它强迫我们成长。',
    tags: ['failure', 'learning', 'resilience', 'wisdom', 'growth'],
    category: 'personal_growth',
    emotionalTone: 'contemplative'
  },
  {
    id: 'growth-3',
    question: '如果你可以重新开始，你会做什么不同的选择？',
    reflection: '重新开始的幻想往往揭示了我们对当下生活的真实感受。',
    tags: ['regret', 'choices', 'restart', 'wisdom', 'reflection'],
    category: 'personal_growth',
    emotionalTone: 'contemplative'
  }
];

// 获取随机灵感卡片
export const getRandomInspirationCard = (): InspirationCard => {
  const randomIndex = Math.floor(Math.random() * INSPIRATION_CARDS.length);
  return INSPIRATION_CARDS[randomIndex];
};

// 根据标签获取相关卡片
export const getCardsByTags = (tags: string[], limit: number = 5): InspirationCard[] => {
  const matchingCards = INSPIRATION_CARDS.filter(card =>
    card.tags.some(tag => tags.includes(tag))
  );
  
  // 随机排序并限制数量
  return matchingCards
    .sort(() => Math.random() - 0.5)
    .slice(0, limit);
};

// 根据类别获取卡片
export const getCardsByCategory = (category: string): InspirationCard[] => {
  return INSPIRATION_CARDS.filter(card => card.category === category);
};

// 根据情感基调获取卡片
export const getCardsByTone = (tone: string): InspirationCard[] => {
  return INSPIRATION_CARDS.filter(card => card.emotionalTone === tone);
};
```

`staroracle-app_v1/src/utils/mobileUtils.ts`:

```ts
import { Capacitor } from '@capacitor/core';

/**
 * 检测是否为移动端原生环境
 */
export const isMobileNative = () => {
  return Capacitor.isNativePlatform();
};

/**
 * 检测是否为iOS
 */
export const isIOS = () => {
  return Capacitor.getPlatform() === 'ios';
};

/**
 * 创建最高层级的Portal容器
 */
export const createTopLevelContainer = (): HTMLElement => {
  let container = document.getElementById('top-level-modals');
  
  if (!container) {
    container = document.createElement('div');
    container.id = 'top-level-modals';
    container.style.cssText = `
      position: fixed !important;
      top: 0 !important;
      left: 0 !important;
      right: 0 !important;
      bottom: 0 !important;
      z-index: 2147483647 !important;
      pointer-events: none !important;
      -webkit-transform: translateZ(0) !important;
      transform: translateZ(0) !important;
      -webkit-backface-visibility: hidden !important;
      backface-visibility: hidden !important;
    `;
    document.body.appendChild(container);
  }
  
  return container;
};

/**
 * 获取移动端特有的模态框样式
 */
export const getMobileModalStyles = () => {
  return {
    position: 'fixed' as const,
    zIndex: 2147483647, // 使用最大z-index值
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    pointerEvents: 'auto' as const,
    WebkitTransform: 'translateZ(0)',
    transform: 'translateZ(0)',
    WebkitBackfaceVisibility: 'hidden' as const,
    backfaceVisibility: 'hidden' as const,
  };
};

/**
 * 获取移动端特有的CSS类名
 */
export const getMobileModalClasses = () => {
  return 'fixed inset-0 flex items-center justify-center';
};

/**
 * 强制隐藏所有其他元素（除了模态框）
 */
export const hideOtherElements = () => {
  if (!isIOS()) return () => {};
  
  // 如果Portal和z-index修复已经工作，我们可能不需要隐藏主页按钮
  // 让我们尝试一个最小化的方法：只在绝对必要时隐藏
  
  console.log('iOS hideOtherElements called - using minimal approach');
  
  // 返回一个空的恢复函数，不隐藏任何元素
  return () => {
    console.log('iOS hideOtherElements restore called');
  };
};

/**
 * 修复iOS层级问题的通用方案
 */
export const fixIOSZIndex = () => {
  if (!isIOS()) return;
  
  // 创建顶级容器
  createTopLevelContainer();
  
  // 为body添加特殊的层级修复
  document.body.style.webkitTransform = 'translateZ(0)';
  document.body.style.transform = 'translateZ(0)';
};
```

`staroracle-app_v1/src/utils/oracleUtils.ts`:

```ts
// This function simulates generating a mystical, poetic response
// In a real app, this would connect to an AI service
export const generateOracleResponse = (): string => {
  const responses = [
    "The stars whisper of paths untaken, yet your journey remains true to your heart's calling.",
    "Like the moon's reflection on water, what you seek is both there and not there. Look deeper.",
    "Ancient light travels to reach your eyes; patience will reveal what haste conceals.",
    "The cosmos spins patterns of possibility. Your question already contains its answer.",
    "Celestial bodies dance in harmony despite distance. Find your rhythm in life's grand ballet.",
    "As galaxies spiral through the void, your path winds through darkness toward distant light.",
    "The nebula of your thoughts contains the seeds of stars yet unborn. Nurture them.",
    "Time flows like stellar winds, shaping the landscape of your existence into forms yet unknown.",
    "The void between stars is not empty but full of potential. Embrace the spaces in your life.",
    "Your question echoes across the cosmos, returning with wisdom carried on starlight.",
    "The universe expands without destination. Your journey needs no justification beyond itself.",
    "Constellations are patterns we impose on chaos. Create meaning from the random stars of experience.",
    "The light you see began its journey long ago. Trust in what is revealed, even if delayed.",
    "Cosmic dust becomes stars becomes dust again. All transformations are possible for you.",
    "The gravity of your intentions pulls experiences into orbit around you. Choose wisely what you attract.",
  ];
  
  return responses[Math.floor(Math.random() * responses.length)];
};
```

`staroracle-app_v1/src/utils/soundUtils.ts`:

```ts
import { Howl } from 'howler';

// Sound URLs
const SOUND_URLS = {
  starClick: 'https://assets.codepen.io/21542/click-2.mp3',
  starLight: 'https://assets.codepen.io/21542/pop-up-on.mp3',
  starReveal: 'https://assets.codepen.io/21542/pop-down.mp3',
  ambient: 'https://assets.codepen.io/21542/ambient-loop.mp3',
};

// Preload sounds
const sounds: Record<string, Howl> = {};

Object.entries(SOUND_URLS).forEach(([key, url]) => {
  sounds[key] = new Howl({
    src: [url],
    volume: key === 'ambient' ? 0.2 : 0.5,
    loop: key === 'ambient',
  });
});

// Sound utility functions
export function playSound(
  soundName: 'starClick' | 'starLight' | 'starReveal' | 'ambient' | 'uiClick',
  options: { volume?: number; loop?: boolean } = {}
) {
  // For uiClick, default to starClick if not available
  const actualSoundName = soundName === 'uiClick' ? 'starClick' : soundName;
  
  if (sounds[actualSoundName]) {
    // Set volume if provided
    if (options.volume !== undefined) {
      sounds[actualSoundName].volume(options.volume);
    }
    
    // Set loop if provided
    if (options.loop !== undefined) {
      sounds[actualSoundName].loop(options.loop);
    }
    
    // Play the sound
    sounds[actualSoundName].play();
    
    console.log(`🔊 Playing sound: ${soundName}`);
  } else {
    console.warn(`⚠️ Sound not found: ${soundName}`);
  }
}

export const stopSound = (soundName: keyof typeof SOUND_URLS) => {
  if (sounds[soundName]) {
    sounds[soundName].stop();
  }
};

export const startAmbientSound = () => {
  if (!sounds.ambient.playing()) {
    sounds.ambient.play();
  }
};

export const stopAmbientSound = () => {
  sounds.ambient.stop();
};
```

`staroracle-app_v1/src/vite-env.d.ts`:

```ts
/// <reference types="vite/client" />

// 定义支持的API提供商类型
export type ApiProvider = 'openai' | 'gemini';

interface ImportMetaEnv {
  readonly VITE_DEFAULT_PROVIDER?: ApiProvider; // 新增：API提供商
  readonly VITE_DEFAULT_API_KEY?: string;
  readonly VITE_DEFAULT_ENDPOINT?: string;
  readonly VITE_DEFAULT_MODEL?: string;
}

interface ImportMeta {
  readonly env: ImportMeta;
}

```