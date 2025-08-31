# WebSocket Service Documentation

## Overview

The WebSocket service provides real-time communication capabilities for the El Biblio app. It handles authentication, connection management, and event handling for features like live notifications, verse interactions, and challenge updates.

## Architecture

### WebSocketService Class

The main service class that manages the WebSocket connection:

- **Connection Management**: Handles connection, disconnection, and reconnection logic
- **Authentication**: Integrates with the auth system to provide secure connections
- **Event Handling**: Processes incoming messages and routes them to appropriate handlers
- **State Management**: Maintains connection state and notifies listeners of changes

### Key Features

1. **Automatic Authentication**: Syncs with the auth store to automatically connect when user logs in
2. **Reconnection Logic**: Implements exponential backoff for failed connections
3. **Heartbeat**: Sends periodic ping messages to keep connection alive
4. **Event Subscription**: Allows components to subscribe to specific events
5. **Error Handling**: Comprehensive error handling and logging

## Usage

### Basic Usage in Components

```typescript
import { useWebSocket } from '@/services/websocket';

const MyComponent = () => {
  const { isConnected, sendMessage, subscribeToEvent } = useWebSocket();
  
  useEffect(() => {
    // Subscribe to a specific event
    subscribeToEvent('verse.liked', (data) => {
      console.log('Verse liked:', data);
    });
  }, []);
  
  const handleLikeVerse = () => {
    sendMessage('verse.like', { verseId: '123' });
  };
  
  return (
    <View>
      <Text>Connection Status: {isConnected ? 'Connected' : 'Disconnected'}</Text>
    </View>
  );
};
```

### Automatic Auth Sync

The WebSocket service automatically syncs with the auth state through the `WebSocketProvider`:

```typescript
// In App.tsx (already implemented)
<AuthProvider>
  <WebSocketProvider>
    <AppContent />
  </WebSocketProvider>
</AuthProvider>
```

### Manual Auth Management

You can also manually set auth information:

```typescript
import { webSocketService } from '@/services/websocket';

// Set auth info
webSocketService.setAuthInfo({
  token: 'your-jwt-token',
  userId: 'user-id'
});

// Connect manually
await webSocketService.connect();
```

## Event Types

### Built-in Events

- `verse.voted` - When a verse receives a vote
- `verse.liked` - When a verse is liked
- `verse.shared` - When a verse is shared
- `challenge.joined` - When a user joins a challenge
- `challenge.left` - When a user leaves a challenge
- `challenge.completed` - When a challenge is completed
- `notification.sent` - When a new notification is sent

### Custom Events

You can subscribe to custom events:

```typescript
const { subscribeToEvent } = useWebSocket();

useEffect(() => {
  subscribeToEvent('custom.event', (data) => {
    // Handle custom event
  });
}, []);
```

## Configuration

The WebSocket service uses environment variables for configuration:

```typescript
const config = {
  host: process.env.EXPO_PUBLIC_WS_HOST || 'localhost',
  port: process.env.EXPO_PUBLIC_WS_PORT || '8080',
  appKey: process.env.EXPO_PUBLIC_WS_APP_KEY || 'your-app-key',
  secure: process.env.EXPO_PUBLIC_WS_SECURE === 'true',
};
```

## Error Handling

The service includes comprehensive error handling:

- Connection failures are logged and retried with exponential backoff
- Authentication errors trigger disconnection
- Invalid messages are logged but don't crash the service
- Network errors are handled gracefully

## State Management

The WebSocket state includes:

```typescript
interface WebSocketState {
  isConnected: boolean;
  isConnecting: boolean;
  error: string | null;
  lastMessage: Date | null;
}
```

## Best Practices

1. **Always check connection status** before sending messages
2. **Subscribe to events in useEffect** and clean up in the return function
3. **Handle errors gracefully** - the service will attempt to reconnect automatically
4. **Use the provider pattern** for automatic auth sync
5. **Test connection status** before performing critical operations

## Troubleshooting

### Common Issues

1. **"Cannot read property 'useContext' of null"**
   - This was fixed by removing React hooks from the service class
   - The service now accepts auth info as parameters instead

2. **Connection not established**
   - Check that auth token is valid
   - Verify WebSocket server is running
   - Check network connectivity

3. **Events not received**
   - Ensure you're subscribed to the correct event name
   - Check that the WebSocket is connected
   - Verify the event is being sent from the server

### Debug Mode

Enable debug logging by checking the console for WebSocket-related messages:

```typescript
// The service logs connection events, errors, and message handling
console.log('WebSocket connected');
console.log('WebSocket disconnected:', event.code, event.reason);
console.log('New notification:', data);
``` 