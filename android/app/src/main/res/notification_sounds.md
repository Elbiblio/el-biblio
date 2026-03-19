# Android Notification Sound Setup

## Custom Sound Files (IMPLEMENTED ✅)

Sound files placed in: `android/app/src/main/res/raw/`

### Available Sound Files:
- `notification_sound.mp3` - **bell-meditation.mp3** (Gentle meditation bell for morning/evening reminders)
- `notification_sound_gentle.mp3` - **success_bell.mp3** (Soft success bell for daily/snooze notifications)
- `notification_sound_urgent.wav` - **chime.wav** (Prominent chime for urgent notifications -备用)

### Sound Mapping:
- **Daily Rhythm Channel**: `notification_sound_gentle.mp3` (subtle reminder)
- **Morning Rhythm Channel**: `notification_sound.mp3` (meditation bell)
- **Evening Rhythm Channel**: `notification_sound.mp3` (meditation bell)
- **Snooze Channel**: `notification_sound_gentle.mp3` (gentle reminder)

## iOS Sound Setup (IMPLEMENTED ✅)

Sound files placed in: `ios/Runner/`

### Available Sound Files:
- `notification_sound_gentle.mp3` - **success_bell.mp3** (for daily/snooze notifications)
- `notification_sound.wav` - **chime.wav** (for morning/evening reminders)

### Sound Mapping:
- **Daily Notifications**: `notification_sound_gentle.mp3`
- **Morning/Evening Rich Notifications**: `notification_sound.wav`
- **Snooze Notifications**: `notification_sound_gentle.mp3`

## Implementation Status

✅ **Android**: Custom sounds configured with proper vibration patterns
✅ **iOS**: Custom sounds configured with proper interruption levels
✅ **Fallback**: System defaults if custom sounds fail
✅ **Permissions**: Sound permissions properly requested

## Testing

1. **Android**: Test with device sound on, check notification channel settings
2. **iOS**: Test with ringer switch on, volume up, check Focus modes
3. **Both**: Verify custom sounds play instead of system defaults
