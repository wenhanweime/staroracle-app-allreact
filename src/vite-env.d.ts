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
