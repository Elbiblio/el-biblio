# Offline Commitment Fallback Implementation

## Overview
This implementation provides robust offline fallbacks for daily commitments when the API is unavailable, ensuring users can continue their spiritual practice without interruption. **The system now supports dynamic durations** that match the graduated time commitment requirements of the main application.

## Architecture

### 1. Offline Data Structure (`offline_commitment_data.dart`)
- **Virtue-Specific Commitments**: Each virtue (Humility, Love, Faith, Knowledge) has 6 curated commitments
- **Dynamic Durations**: Commitments support flexible duration assignment (not locked to specific values)
- **Difficulty Levels**: Level 1-2 commitments for appropriate challenge scaling
- **Negative IDs**: Offline commitments use negative IDs (-101 to -406) to distinguish from API data

### 2. Enhanced Repository (`commitment_repository.dart`)
- **Automatic Fallback**: Attempts API first, falls back to offline data on failure
- **Virtue ID Mapping**: Converts API virtue IDs to VirtueType for offline data retrieval
- **Default Duration**: Uses 240 minutes (4 hours) as default for backward compatibility
- **Error Logging**: Enhanced logging for debugging offline fallback scenarios

### 3. Enhanced Notifier (`commitment_notifier.dart`)
- **Offline State Tracking**: `isUsingOfflineData` flag indicates current data source
- **Dynamic Duration Support**: Methods support custom duration assignment
- **Duration Options**: Support for multiple duration variations (1h, 2h, 3h, 4h)
- **Manual Fallback**: Multiple methods for explicit offline mode activation

### 4. Enhanced UI (`commitment_selection_dialog.dart`)
- **Offline Indicator**: Visual badge when using offline data
- **Offline Notice**: Informative message about offline mode
- **Error Handling**: Dual action buttons (Retry/Use Offline) in error states
- **User Feedback**: Clear communication about data source status

## Dynamic Duration System

### Core Principle
Offline commitments are no longer locked to specific durations. Instead, they support **dynamic duration assignment** that matches the graduated commitment system:

```dart
// Base commitment with duration 0 (dynamic)
{
  'id': -101,
  'title': 'Listen Before Speaking',
  'description': 'Ask one clarifying question before you share your own view.',
  'durationMinutes': 0, // Dynamic duration - will be set based on user selection
  'categoryTags': ['communication', 'listening', 'humility'],
  'difficultyLevel': 1,
  'themeId': 1,
}
```

### Duration Assignment Methods

#### 1. Default Duration Assignment
```dart
// Uses 240 minutes (4 hours) as default for compatibility
OfflineCommitmentData.getCommitmentsForVirtue(virtueType)
```

#### 2. Custom Duration Assignment
```dart
// Specify exact duration needed
OfflineCommitmentData.getCommitmentsForVirtue(virtueType, defaultDurationMinutes: 120)
```

#### 3. Multiple Duration Options
```dart
// Creates 24 variations (6 commitments × 4 duration options)
OfflineCommitmentData.getCommitmentsWithDurationOptions(virtueType)
// Duration options: 60, 120, 180, 240 minutes (1h, 2h, 3h, 4h)
```

#### 4. Single Commitment with Duration
```dart
// Get specific commitment with custom duration
OfflineCommitmentData.getCommitmentWithDuration(virtueType, 0, 180)
```

## Data Structure

### Commitment Distribution by Virtue

#### Humility (Theme ID: 1)
- **Dynamic Duration**: Supports 1-4 hours based on user selection
- **Focus**: Communication, service, self-awareness
- **Examples**: "Listen Before Speaking", "Notice Quiet Efforts", "Give Credit Publicly"

#### Love (Theme ID: 2)  
- **Dynamic Duration**: Supports 1-4 hours based on user selection
- **Focus**: Relationships, compassion, kindness
- **Examples**: "Notice Someone's Effort", "Send Encouragement", "Be Fully Present"

#### Faith (Theme ID: 3)
- **Dynamic Duration**: Supports 1-4 hours based on user selection
- **Focus**: Prayer, trust, spiritual practices
- **Examples**: "Start with Trust", "Gratitude Pause", "Trust in Delays"

#### Knowledge (Theme ID: 4)
- **Dynamic Duration**: Supports 1-4 hours based on user selection
- **Focus**: Learning, curiosity, wisdom
- **Examples**: "Ask One More Question", "Learn a Small Fact", "Clarify Before Acting"

## User Experience Flow

### 1. Normal Operation (API Available)
```
User opens commitment dialog → API call succeeds → Full commitment list displayed
```

### 2. Automatic Fallback (API Unavailable)
```
User opens commitment dialog → API call fails → Offline fallback activates → 
Offline indicator shown → Offline commitment list displayed with default 4h duration
```

### 3. Manual Fallback (Error State)
```
API error shown → User chooses "Use Offline" → Offline commitments loaded → 
Offline indicator shown → User can proceed with selection
```

### 4. Duration Selection (Enhanced Offline)
```
User in offline mode → System shows duration options → User selects preferred duration → 
Commitment displayed with selected duration → Progress tracking uses selected duration
```

### 5. Retry Logic
```
User in offline mode → Taps retry → API call attempted → 
Success: Online mode restored / Failure: Stay in offline mode with current duration
```

## Technical Implementation Details

### API Endpoint Structure
- **Endpoint**: `/api/virtues/{virtueId}/commitments`
- **Response Format**: `{ "data": [commitment_array] }`
- **Virtue ID Mapping**: 1=Humility, 2=Love, 3=Faith, 4=Knowledge

### Offline Data Format
```dart
{
  'id': -101,                    // Negative ID for offline identification
  'title': 'Listen Before Speaking',
  'description': 'Ask one clarifying question...',
  'durationMinutes': 0,          // Dynamic duration placeholder
  'categoryTags': ['communication', 'listening', 'humility'],
  'difficultyLevel': 1,
  'themeId': 1,                 // Matches API virtue ID
}
```

### Dynamic Duration Assignment
```dart
// Runtime duration assignment
return Commitment(
  id: data['id'] as int,
  title: data['title'] as String,
  description: data['description'] as String,
  durationMinutes: duration,  // Set at runtime based on user/system needs
  categoryTags: (data['categoryTags'] as List<dynamic>).cast<String>(),
  difficultyLevel: data['difficultyLevel'] as int,
  themeId: data['themeId'] as int,
);
```

### State Management
```dart
class CommitmentState {
  final List<Commitment> commitments;
  final bool isLoading;
  final String? error;
  final bool isUsingOfflineData;  // Offline tracking
}
```

## Benefits

### 1. Reliability
- **Zero Downtime**: Users always have access to commitments
- **Graceful Degradation**: Smooth transition from online to offline
- **Data Integrity**: Offline commitments match API structure perfectly

### 2. Flexibility
- **Dynamic Durations**: Support for graduated commitment requirements
- **User Choice**: Multiple duration options available offline
- **Adaptive System**: Can adjust to different user time constraints

### 3. User Experience
- **Transparency**: Clear indication of online/offline status
- **Choice**: Users can retry connection or stay offline
- **Continuity**: No interruption to daily practice routine
- **Personalization**: Duration selection matches user availability

### 4. Performance
- **Instant Access**: Offline data loads immediately
- **Reduced Latency**: No network dependency for fallback data
- **Battery Efficient**: No repeated failed API calls

## Usage Examples

### Basic Offline Fallback
```dart
// Repository automatically falls back with default 4h duration
final commitments = await repository.getCommitmentsForVirtue(virtueId);
```

### Custom Duration Assignment
```dart
// Get offline commitments with 2-hour default
final commitments = notifier.getOfflineCommitments(virtueType, defaultDurationMinutes: 120);
```

### Multiple Duration Options
```dart
// Get all commitment variations (6 × 4 = 24 options)
final commitments = notifier.getOfflineCommitmentsWithDurationOptions(virtueType);
```

### Manual Offline Activation
```dart
// Activate offline mode with custom duration
notifier.setOfflineCommitments(virtueType, defaultDurationMinutes: 180);
```

## Future Enhancements

### 1. Smart Duration Selection
- **User Preference Learning**: Remember user's preferred duration choices
- **Context-Aware Suggestions**: Suggest durations based on time of day
- **Adaptive Difficulty**: Adjust difficulty based on duration selection

### 2. Enhanced Offline Content
- **More Commitments**: Larger offline commitment pool
- **Dynamic Selection**: Rotate offline commitments for variety
- **User Progress**: Track offline completion statistics by duration

### 3. Advanced Features
- **Offline Analytics**: Track offline usage patterns and duration preferences
- **Smart Retry**: Intelligent retry timing based on connectivity and user patterns
- **Progressive Enhancement**: Add features as connectivity improves

## Testing Scenarios

### 1. Network Scenarios
- **No Internet**: Pure offline operation with dynamic durations
- **Poor Connection**: Automatic fallback with retry and duration options
- **Intermittent**: Seamless switching between modes with duration preservation

### 2. Duration Handling
- **Default Assignment**: 4-hour default for backward compatibility
- **Custom Assignment**: User-specified durations for flexibility
- **Multiple Options**: Full range of duration choices (1h, 2h, 3h, 4h)

### 3. Error Handling
- **API Timeout**: Graceful fallback to offline with default duration
- **Server Error**: Clear error message with offline duration options
- **Invalid Response**: Fallback with error logging and duration flexibility

## Conclusion

This enhanced offline fallback implementation ensures that users can maintain their daily spiritual practice regardless of connectivity status, with **full support for dynamic duration requirements**. The system provides a seamless experience with clear user feedback, robust error handling, and maintains complete functionality in offline scenarios while supporting the graduated commitment duration system.

The dynamic duration approach ensures that offline commitments are not locked to specific time requirements but can adapt to user needs, providing the same flexibility as the online API system.
