export interface ChatMessage {
  id: string;
  text: string;
  isUser: boolean;
  timestamp: Date;
  isLoading?: boolean;
  isStreaming?: boolean; // 标记是否正在流式输出
}

export interface ChatState {
  messages: ChatMessage[];
  isLoading: boolean;
}