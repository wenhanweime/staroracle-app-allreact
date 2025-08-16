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