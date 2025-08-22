import React from 'react';
import { useWebSocketAuthSync } from '@/services/websocket';

interface WebSocketProviderProps {
  children: React.ReactNode;
}

export const WebSocketProvider: React.FC<WebSocketProviderProps> = ({ children }) => {
  useWebSocketAuthSync();
  return <>{children}</>;
}; 