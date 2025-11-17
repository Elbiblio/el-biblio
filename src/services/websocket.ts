import * as React from 'react';
import Constants from 'expo-constants';
import Pusher, { Channel, PresenceChannel } from 'pusher-js';
import { useAuthStore, useVerseStore, useWordHubsStore } from '@/stores/StoreProvider';

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

export interface WebSocketRuntimeConfig {
  host: string;
  port: string; // string to match Pusher options and existing config
  appKey: string;
  secure: boolean;
}

class WebSocketService {
  private pusher: Pusher | null = null;
  private channels: Map<string, Channel | PresenceChannel> = new Map();
  private subscriptions: Map<string, (data: any) => void> = new Map();
  private authInfo: WebSocketAuthInfo = { token: null };
  private verseHandlers?: {
    updateVerseVotes: (id: any, votes: any, is_voted: any) => void;
    updateVerseLikes: (id: any, likes: any, is_liked: any) => void;
    updateVerseShares: (id: any, shares: any) => void;
  };
  private wordHubHandlers?: {
    addMessageInRealTime: (hubId: string, message: any, author?: any) => void;
    updateHubInRealTime: (hubId: string, updates: any) => void;
    setConnectionStatus: (isConnected: boolean) => void;
  };
  private reconnectAttempts = 0;
  private reconnectTimer: any = null;
  
  // Optional runtime configuration (preferred) – typically provided from API
  private runtimeConfig: WebSocketRuntimeConfig | null = null;

  // Configuration sourced from app.json extra as a fallback
  private getDefaultConfig(): WebSocketRuntimeConfig {
    const extra: any = (Constants as any)?.expoConfig?.extra || (Constants as any)?.manifest?.extra || {};
    return {
      host: extra.WS_HOST || 'api.elbiblio.com',
      port: String(extra.WS_PORT || '8080'),
      appKey: extra.WS_APP_KEY || 'your-app-key',
      secure: !!extra.WS_SECURE,
    };
  }

  private getConfig(): WebSocketRuntimeConfig {
    return this.runtimeConfig ?? this.getDefaultConfig();
  }

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
    // Pusher will be initialized when auth info is set
  }

  // Allow callers (e.g., App initialization) to provide runtime WebSocket config from API
  public setConfig(config: WebSocketRuntimeConfig | null): void {
    this.runtimeConfig = config;
    // Optionally reconnect with new config if already authenticated
    if (this.authInfo.token && this.authInfo.userId && this.pusher) {
      this.reconnect().catch(() => undefined);
    }
  }

  // Method to set auth information
  public setAuthInfo(authInfo: WebSocketAuthInfo): void {
    this.authInfo = authInfo;
    if (this.reconnectTimer) { clearTimeout(this.reconnectTimer); this.reconnectTimer = null; }
    this.reconnectAttempts = 0;
    
    // If we have a token and user, try to connect
    if (authInfo.token && authInfo.userId) {
      this.connect();
    } else {
      // If no auth info, disconnect
      this.disconnect();
    }
  }

  public async connect(): Promise<boolean> {
    if (this.pusher?.connection.state === 'connected') {
      return true;
    }

    if (this.state.isConnecting) {
      return false;
    }

    // Check if we have auth info
    if (!this.authInfo.token) {
      if (__DEV__) console.log('No auth token available for WebSocket connection');
      return false;
    }

    this.setState({ isConnecting: true, error: null });

    try {
      // Resolve configuration (runtime config from API preferred over app.json extras)
      const config = this.getConfig();

      // Initialize Pusher with Reverb configuration
      this.pusher = new Pusher(config.appKey, {
        wsHost: config.host,
        wsPort: parseInt(config.port, 10),
        wssPort: parseInt(config.port, 10),
        forceTLS: config.secure,
        enabledTransports: ['ws', 'wss'],
        disableStats: true,
        cluster: 'mt1', // dummy for self-hosted Reverb
        authEndpoint: 'https://api.elbiblio.com/api/broadcasting/auth',
        auth: {
          headers: {
            'Authorization': `Bearer ${this.authInfo.token}`,
            'Accept': 'application/json'
          }
        }
      });

      // Set up connection state handlers
      this.pusher.connection.bind('connected', () => {
        if (__DEV__) console.log('Pusher connected');
        this.setState({ 
          isConnected: true, 
          isConnecting: false, 
          error: null,
          lastMessage: new Date()
        });
        if (this.reconnectTimer) { clearTimeout(this.reconnectTimer); this.reconnectTimer = null; }
        this.reconnectAttempts = 0;
        this.wordHubHandlers?.setConnectionStatus(true);
        this.subscribeToChannels();
      });

      this.pusher.connection.bind('disconnected', () => {
        if (__DEV__) console.log('Pusher disconnected');
        this.setState({ 
          isConnected: false, 
          isConnecting: false
        });
        this.wordHubHandlers?.setConnectionStatus(false);
        this.scheduleReconnect();
      });

      this.pusher.connection.bind('error', (error: any) => {
        if (__DEV__) console.error('Pusher connection error:', error);
        this.setState({ 
          isConnecting: false,
          error: error.message || 'Connection failed'
        });
        this.scheduleReconnect();
      });

      this.pusher.connection.bind('state_change', (states: any) => {
        if (__DEV__) console.log('Pusher state changed:', states.previous, '->', states.current);
      });

      return true;
    } catch (error) {
      console.error('Failed to initialize Pusher:', error);
      this.setState({ 
        isConnecting: false,
        error: error instanceof Error ? error.message : 'Connection failed'
      });
      return false;
    }
  }

  public disconnect(): void {
    if (this.pusher) {
      // Unsubscribe from all channels
      this.channels.forEach((channel, channelName) => {
        channel.unbind_all();
        this.pusher?.unsubscribe(channelName);
      });
      this.channels.clear();
      
      // Disconnect Pusher
      this.pusher.disconnect();
      this.pusher = null;
    }
    
    this.setState({ 
      isConnected: false, 
      isConnecting: false,
      error: null
    });
    this.wordHubHandlers?.setConnectionStatus(false);
    if (this.reconnectTimer) { clearTimeout(this.reconnectTimer); this.reconnectTimer = null; }
    this.reconnectAttempts = 0;
  }

  private scheduleReconnect(): void {
    if (!this.authInfo.token) return;
    if (this.pusher?.connection.state === 'connected') return;
    if (this.reconnectTimer) return;
    const base = Math.min(30000, Math.pow(2, this.reconnectAttempts) * 1000);
    const jitter = Math.floor(Math.random() * 500);
    const delay = Math.max(1000, base + jitter);
    this.reconnectAttempts = Math.min(this.reconnectAttempts + 1, 10);
    this.reconnectTimer = setTimeout(async () => {
      this.reconnectTimer = null;
      await this.connect();
    }, delay);
  }

  private subscribeToChannels(): void {
    if (!this.authInfo.userId || !this.pusher) return;

    // Subscribe to private user channel
    this.subscribeToChannel(`private-user.${this.authInfo.userId}`);
    
    // Subscribe to private notifications channel
    this.subscribeToChannel(`private-notifications.${this.authInfo.userId}`);
    
    // Subscribe to public channels
    this.subscribeToChannel('community-challenges');
  }

  // Public method to subscribe to a specific channel (e.g., WordHub presence channels)
  public subscribeToChannel(channelName: string): Channel | PresenceChannel | null {
    if (!this.pusher) {
      if (__DEV__) console.warn('Cannot subscribe: Pusher not initialized');
      return null;
    }

    // Check if already subscribed
    if (this.channels.has(channelName)) {
      return this.channels.get(channelName)!;
    }

    try {
      const channel = this.pusher.subscribe(channelName);
      this.channels.set(channelName, channel);
      
      // Set up event listeners based on channel type
      this.setupChannelListeners(channelName, channel);
      
      if (__DEV__) console.log(`Subscribed to channel: ${channelName}`);
      return channel;
    } catch (error) {
      if (__DEV__) console.error(`Failed to subscribe to channel ${channelName}:`, error);
      return null;
    }
  }

  // Public method to unsubscribe from a specific channel
  public unsubscribeFromChannel(channelName: string): void {
    const channel = this.channels.get(channelName);
    if (channel && this.pusher) {
      channel.unbind_all();
      this.pusher.unsubscribe(channelName);
      this.channels.delete(channelName);
      if (__DEV__) console.log(`Unsubscribed from channel: ${channelName}`);
    }
  }

  private setupChannelListeners(channelName: string, channel: Channel | PresenceChannel): void {
    // Notification events
    if (channelName.includes('notifications')) {
      channel.bind('notification.sent', (data: any) => {
        this.handleNotification(data);
      });
    }

    // Challenge events
    if (channelName.includes('challenges')) {
      channel.bind('challenge.joined', (data: any) => {
        this.handleChallengeJoined(data);
      });
      
      channel.bind('challenge.left', (data: any) => {
        this.handleChallengeLeft(data);
      });
      
      channel.bind('challenge.completed', (data: any) => {
        this.handleChallengeCompleted(data);
      });
    }

    // WordHub events (presence channels)
    if (channelName.startsWith('presence-wordhub.')) {
      const hubId = channelName.replace('presence-wordhub.', '');
      
      channel.bind('wordhub.message.sent', (data: any) => {
        this.handleWordHubMessage(hubId, data);
      });

      channel.bind('wordhub.updated', (data: any) => {
        this.handleWordHubUpdated(hubId, data);
      });

      // Presence channel specific events
      if ((channel as PresenceChannel).members) {
        (channel as PresenceChannel).bind('pusher:subscription_succeeded', (members: any) => {
          if (__DEV__) console.log(`WordHub ${hubId} members:`, members.count);
        });

        (channel as PresenceChannel).bind('pusher:member_added', (member: any) => {
          if (__DEV__) console.log(`Member joined WordHub ${hubId}:`, member.id);
        });

        (channel as PresenceChannel).bind('pusher:member_removed', (member: any) => {
          if (__DEV__) console.log(`Member left WordHub ${hubId}:`, member.id);
        });
      }
    }

    // Verse events
    channel.bind('verse.voted', (data: any) => {
      this.handleVerseVoted(data);
    });
    
    channel.bind('verse.liked', (data: any) => {
      this.handleVerseLiked(data);
    });
    
    channel.bind('verse.shared', (data: any) => {
      this.handleVerseShared(data);
    });

    // Allow custom event subscriptions
    this.subscriptions.forEach((handler, event) => {
      channel.bind(event, handler);
    });
  }

  // WordHub event handlers
  private handleWordHubMessage(hubId: string, data: any): void {
    if (__DEV__) console.log('WordHub message received:', hubId, data);
    this.setState({ lastMessage: new Date() });
    
    // Delegate to WordHubsStore if handler is set
    if (this.wordHubHandlers?.addMessageInRealTime) {
      const message = data.message || data;
      const author = data.author || data.user;
      this.wordHubHandlers.addMessageInRealTime(hubId, message, author);
    }
  }

  private handleWordHubUpdated(hubId: string, data: any): void {
    if (__DEV__) console.log('WordHub updated:', hubId, data);
    this.setState({ lastMessage: new Date() });
    
    // Delegate to WordHubsStore if handler is set
    if (this.wordHubHandlers?.updateHubInRealTime) {
      this.wordHubHandlers.updateHubInRealTime(hubId, data);
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
    if (__DEV__) console.log('User joined challenge:', data);
  }

  private handleChallengeLeft(data: any): void {
    // Update challenge participants count
    if (__DEV__) console.log('User left challenge:', data);
  }

  private handleChallengeCompleted(data: any): void {
    // Update challenge completion status
    if (__DEV__) console.log('Challenge completed:', data);
  }

  // Notification handler
  private handleNotification(data: any): void {
    // Handle real-time notifications
    if (__DEV__) console.log('New notification:', data);
    // You could integrate with a notification service here
  }

  // Public methods
  public subscribeToEvent(event: string, handler: (data: any) => void): void {
    this.subscriptions.set(event, handler);
  }

  public unsubscribeFromEvent(event: string): void {
    this.subscriptions.delete(event);
  }

  public sendMessage(channelName: string, event: string, data: any): boolean {
    const channel = this.channels.get(channelName);
    if (channel && this.pusher?.connection.state === 'connected') {
      channel.trigger(event, data);
      return true;
    }
    return false;
  }

  public async reconnect(): Promise<boolean> {
    if (this.state.isConnecting) return false;
    this.disconnect();
    return this.connect();
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

  public setWordHubHandlers(handlers?: WebSocketService['wordHubHandlers']): void {
    this.wordHubHandlers = handlers;
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
    reconnect: () => webSocketService.reconnect(),
    sendMessage: (channelName: string, event: string, data: any) => 
      webSocketService.sendMessage(channelName, event, data),
    subscribeToChannel: (channelName: string) => webSocketService.subscribeToChannel(channelName),
    unsubscribeFromChannel: (channelName: string) => webSocketService.unsubscribeFromChannel(channelName),
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

// Hook to bind WordHub store handlers to the WebSocket service
export const useWebSocketWordHubSync = () => {
  const wordHubsStore = useWordHubsStore();

  React.useEffect(() => {
    webSocketService.setWordHubHandlers({
      addMessageInRealTime: wordHubsStore.addMessageInRealTime.bind(wordHubsStore),
      updateHubInRealTime: wordHubsStore.updateHubInRealTime.bind(wordHubsStore),
      setConnectionStatus: wordHubsStore.setConnectionStatus.bind(wordHubsStore),
    });

    return () => {
      webSocketService.setWordHubHandlers(undefined);
    };
  }, [wordHubsStore]);
};

export default webSocketService; 