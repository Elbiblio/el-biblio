import * as React from 'react';
import Constants from 'expo-constants';
import { useAuthStore, useVerseStore } from '@/stores/StoreProvider';

// WebSocket event types
export interface WebSocketEvent {
  event: string;
  data: any;
  channel: string;
}

// WebSocket connection state
export interface WebSocketState {
  isConnected: boolean;
  isConnecting: boolean;
  error: string | null;
  lastMessage: Date | null;
}

// Auth information interface
export interface WebSocketAuthInfo {
  token: string | null;
  userId?: string | number;
}

class WebSocketService {
  private ws: WebSocket | null = null;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private reconnectDelay = 1000;
  private heartbeatInterval: ReturnType<typeof setInterval> | null = null;
  private subscriptions: Map<string, (data: any) => void> = new Map();
  private authInfo: WebSocketAuthInfo = { token: null };
  private verseHandlers?: {
    updateVerseVotes: (id: any, votes: any, is_voted: any) => void;
    updateVerseLikes: (id: any, likes: any, is_liked: any) => void;
    updateVerseShares: (id: any, shares: any) => void;
  };
  
  // Configuration sourced from app.json extra to avoid process.env on SDK 52
  private config = (() => {
    const extra: any = (Constants as any)?.expoConfig?.extra || (Constants as any)?.manifest?.extra || {};
    return {
      host: extra.WS_HOST || 'localhost',
      port: String(extra.WS_PORT || '8080'),
      appKey: extra.WS_APP_KEY || 'your-app-key',
      secure: !!extra.WS_SECURE,
    };
  })();

  // State
  public state: WebSocketState = {
    isConnected: false,
    isConnecting: false,
    error: null,
    lastMessage: null,
  };

  // Event listeners
  private listeners: Map<string, ((state: WebSocketState) => void)[]> = new Map();

  constructor() {
    // Remove the setupEventListeners call from constructor
  }

  // Method to set auth information
  public setAuthInfo(authInfo: WebSocketAuthInfo): void {
    this.authInfo = authInfo;
    
    // If we have a token and user, try to connect
    if (authInfo.token && authInfo.userId) {
      this.connect();
    } else {
      // If no auth info, disconnect
      this.disconnect();
    }
  }

  public async connect(): Promise<boolean> {
    if (this.ws?.readyState === WebSocket.OPEN) {
      return true;
    }

    if (this.state.isConnecting) {
      return false;
    }

    // Check if we have auth info
    if (!this.authInfo.token) {
      console.log('No auth token available for WebSocket connection');
      return false;
    }

    this.setState({ isConnecting: true, error: null });

    try {
      const protocol = this.config.secure ? 'wss' : 'ws';
      const url = `${protocol}://${this.config.host}:${this.config.port}/app/${this.config.appKey}`;

      this.ws = new WebSocket(url);

      this.ws.onopen = () => {
        console.log('WebSocket connected');
        this.setState({ 
          isConnected: true, 
          isConnecting: false, 
          error: null,
          lastMessage: new Date()
        });
        this.reconnectAttempts = 0;
        this.startHeartbeat();
        this.subscribeToChannels();
      };

      this.ws.onmessage = (event) => {
        try {
          const message = JSON.parse(event.data);
          this.handleMessage(message);
          this.setState({ lastMessage: new Date() });
        } catch (error) {
          console.error('Error parsing WebSocket message:', error);
        }
      };

      this.ws.onclose = (event) => {
        console.log('WebSocket disconnected:', event.code, event.reason);
        this.setState({ 
          isConnected: false, 
          isConnecting: false,
          error: event.reason || 'Connection closed'
        });
        this.stopHeartbeat();
        this.handleReconnect();
      };

      this.ws.onerror = (error) => {
        console.error('WebSocket error:', error);
        this.setState({ 
          isConnecting: false,
          error: 'Connection failed'
        });
      };

      return true;
    } catch (error) {
      console.error('Failed to connect to WebSocket:', error);
      this.setState({ 
        isConnecting: false,
        error: error instanceof Error ? error.message : 'Connection failed'
      });
      return false;
    }
  }

  public disconnect(): void {
    if (this.ws) {
      this.ws.close(1000, 'User initiated disconnect');
      this.ws = null;
    }
    this.stopHeartbeat();
    this.setState({ 
      isConnected: false, 
      isConnecting: false,
      error: null
    });
  }

  private startHeartbeat(): void {
    this.heartbeatInterval = setInterval(() => {
      if (this.ws?.readyState === WebSocket.OPEN) {
        this.ws.send(JSON.stringify({ event: 'ping' }));
      }
    }, 30000); // Send ping every 30 seconds
  }

  private stopHeartbeat(): void {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
      this.heartbeatInterval = null;
    }
  }

  private handleReconnect(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      this.setState({ error: 'Max reconnection attempts reached' });
      return;
    }

    this.reconnectAttempts++;
    const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);

    setTimeout(() => {
      console.log(`Attempting to reconnect (${this.reconnectAttempts}/${this.maxReconnectAttempts})`);
      this.connect();
    }, delay);
  }

  private subscribeToChannels(): void {
    if (!this.authInfo.userId) return;

    // Subscribe to user-specific channels
    this.subscribe('private-user.' + this.authInfo.userId);
    
    // Subscribe to public channels
    this.subscribe('community-challenges');
    this.subscribe('daily-verses');
    this.subscribe('notifications');
  }

  private subscribe(channel: string): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      const message = {
        event: 'pusher:subscribe',
        data: {
          channel: channel,
          auth: this.authInfo.token
        }
      };
      this.ws.send(JSON.stringify(message));
    }
  }

  private handleMessage(message: any): void {
    // Handle different message types
    switch (message.event) {
      case 'pong':
        // Heartbeat response
        break;
        
      case 'verse.voted':
        this.handleVerseVoted(message.data);
        break;
        
      case 'verse.liked':
        this.handleVerseLiked(message.data);
        break;
        
      case 'verse.shared':
        this.handleVerseShared(message.data);
        break;
        
      case 'challenge.joined':
        this.handleChallengeJoined(message.data);
        break;
        
      case 'challenge.left':
        this.handleChallengeLeft(message.data);
        break;
        
      case 'challenge.completed':
        this.handleChallengeCompleted(message.data);
        break;
        
      case 'notification.sent':
        this.handleNotification(message.data);
        break;
        
      default:
        // Handle custom events
        const handler = this.subscriptions.get(message.event);
        if (handler) {
          handler(message.data);
        }
    }
  }

  // Verse event handlers
  private handleVerseVoted(data: any): void {
    this.verseHandlers?.updateVerseVotes?.(data.verse_id, data.votes, data.is_voted);
  }

  private handleVerseLiked(data: any): void {
    this.verseHandlers?.updateVerseLikes?.(data.verse_id, data.likes, data.is_liked);
  }

  private handleVerseShared(data: any): void {
    this.verseHandlers?.updateVerseShares?.(data.verse_id, data.shares);
  }

  // Challenge event handlers
  private handleChallengeJoined(data: any): void {
    // Update challenge participants count
    console.log('User joined challenge:', data);
  }

  private handleChallengeLeft(data: any): void {
    // Update challenge participants count
    console.log('User left challenge:', data);
  }

  private handleChallengeCompleted(data: any): void {
    // Update challenge completion status
    console.log('Challenge completed:', data);
  }

  // Notification handler
  private handleNotification(data: any): void {
    // Handle real-time notifications
    console.log('New notification:', data);
    // You could integrate with a notification service here
  }

  // Public methods
  public subscribeToEvent(event: string, handler: (data: any) => void): void {
    this.subscriptions.set(event, handler);
  }

  public unsubscribeFromEvent(event: string): void {
    this.subscriptions.delete(event);
  }

  public sendMessage(event: string, data: any): boolean {
    if (this.ws?.readyState === WebSocket.OPEN) {
      const message = { event, data };
      this.ws.send(JSON.stringify(message));
      return true;
    }
    return false;
  }

  // State management
  private setState(updates: Partial<WebSocketState>): void {
    this.state = { ...this.state, ...updates };
    this.notifyListeners();
  }

  public addStateListener(listener: (state: WebSocketState) => void): void {
    const key = 'state';
    if (!this.listeners.has(key)) {
      this.listeners.set(key, []);
    }
    this.listeners.get(key)!.push(listener);
  }

  public removeStateListener(listener: (state: WebSocketState) => void): void {
    const key = 'state';
    const listeners = this.listeners.get(key);
    if (listeners) {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
    }
  }

  private notifyListeners(): void {
    this.listeners.forEach((listeners) => {
      listeners.forEach(listener => listener(this.state));
    });
  }

  // Utility methods
  public getState(): WebSocketState {
    return { ...this.state };
  }

  public isConnected(): boolean {
    return this.state.isConnected;
  }

  // Injection API for non-React service to talk to stores
  public setVerseHandlers(handlers?: WebSocketService['verseHandlers']): void {
    this.verseHandlers = handlers;
  }
}

// Create singleton instance
export const webSocketService = new WebSocketService();

// Hook for using WebSocket in components
export const useWebSocket = () => {
  const [state, setState] = React.useState<WebSocketState>(webSocketService.getState());

  React.useEffect(() => {
    const listener = (newState: WebSocketState) => {
      setState(newState);
    };

    webSocketService.addStateListener(listener);
    return () => webSocketService.removeStateListener(listener);
  }, []);

  return {
    ...state,
    connect: () => webSocketService.connect(),
    disconnect: () => webSocketService.disconnect(),
    sendMessage: (event: string, data: any) => webSocketService.sendMessage(event, data),
    subscribeToEvent: (event: string, handler: (data: any) => void) => 
      webSocketService.subscribeToEvent(event, handler),
    unsubscribeFromEvent: (event: string) => webSocketService.unsubscribeFromEvent(event),
    setAuthInfo: (authInfo: WebSocketAuthInfo) => webSocketService.setAuthInfo(authInfo),
  };
};

// Hook to automatically sync auth state with WebSocket
export const useWebSocketAuthSync = () => {
  const { user, token } = useAuthStore();
  
  React.useEffect(() => {
    if (user && token) {
      webSocketService.setAuthInfo({
        token,
        userId: user.id
      });
    } else {
      webSocketService.setAuthInfo({ token: null });
    }
  }, [user, token]);
};

// Hook to bind verse store handlers to the WebSocket service
export const useWebSocketVerseSync = () => {
  const verseStore = useVerseStore();

  React.useEffect(() => {
    webSocketService.setVerseHandlers({
      updateVerseVotes: verseStore.updateVerseVotes.bind(verseStore),
      updateVerseLikes: verseStore.updateVerseLikes.bind(verseStore),
      updateVerseShares: verseStore.updateVerseShares.bind(verseStore),
    });

    return () => {
      webSocketService.setVerseHandlers(undefined);
    };
  }, [verseStore]);
};

export default webSocketService; 