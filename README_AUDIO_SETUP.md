# Audio Setup for Meditation Chants

## Current Status
✅ **Fixed**: Audio URL accessibility issues (404 errors resolved with asset fallbacks)
✅ **Improved**: Upgraded to `just_audio` plugin for better performance
✅ **Enhanced**: Added proper error handling and user feedback
✅ **Configured**: Android permissions for audio playback

## How to Add Real Audio Files

1. **Replace the demo file**: 
   - Remove `assets/audio/chants/demo_chant.mp3` (placeholder)
   - Add actual MP3 files for each chant:
     - `10000_reasons.mp3`
     - `10000_reasons_african.mp3` 
     - `anima_christi.mp3`
     - `oceans_voice.mp3`

2. **Update chant tracks**:
   ```dart
   // In lib/features/meditation/domain/models/chant_tracks.dart
   voiceKey: 'assets/audio/chants/10000_reasons.mp3',
   ```

3. **Free audio sources**:
   - [Free Music Archive - Sacred](https://freemusicarchive.org/genre/Sacred)
   - [Pixabay Music - Chant](https://pixabay.com/music/chant/)
   - Record your own meditation chants

## Testing

The app now has proper fallback handling:
- **Asset files**: Play directly from app assets
- **Remote URLs**: Download then play with progress indicators
- **Error handling**: User-friendly error messages
- **Auto-stop**: 10-second preview limit

## Audio Libraries Used

- **just_audio**: Primary audio player (better performance than audioplayers)
- **audioplayers**: Kept as fallback for compatibility
- **dio**: For downloading remote audio files

## Permissions Added (Android)

- `WAKE_LOCK`: Keep device awake during meditation
- `MODIFY_AUDIO_SETTINGS`: Audio session management
- `RECORD_AUDIO`: For future voice recording features
- `READ/WRITE_EXTERNAL_STORAGE`: Audio file caching

## Next Steps

1. Add real audio files to `assets/audio/chants/`
2. Test on physical device (audio doesn't work in web emulator)
3. Configure backend to serve audio files when ready
4. Consider adding audio session management for phone calls
