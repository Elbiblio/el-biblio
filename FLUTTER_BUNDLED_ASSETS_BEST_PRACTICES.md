# Flutter Bundled Assets Best Practices

## Problem: Readonly File System Error

The error `FileSystemException: Creation failed, path = '/.dart_tool' (OS Error: Read-only file system, errno = 30)` occurs when:
- `getDatabasesPath()` returns an invalid path on some platforms/configurations
- The app lacks proper storage permissions
- Parent directories don't exist or can't be created

## Best Practices for Copying Bundled Assets

### 1. **Use Proper Directory Detection with Fallbacks**

```dart
Future<String> _getDbDirectory() async {
  try {
    if (Platform.isAndroid) {
      dbPath = await getDatabasesPath();
      // Validate the path is not invalid
      if (dbPath.isEmpty || dbPath == '/.dart_tool' || !dbPath.contains('/')) {
        throw Exception('Invalid Android database path: $dbPath');
      }
      return dbPath;
    }
    // ... other platforms
  } catch (e) {
    // Fallback to application documents directory
    final dir = await getApplicationDocumentsDirectory();
    final bibleDir = Directory(join(dir.path, 'BibleDBs'));
    if (!await bibleDir.exists()) {
      await bibleDir.create(recursive: true);
    }
    return bibleDir.path;
  }
}
```

### 2. **Use `databaseExists()` Instead of `File.exists()`**

```dart
import 'package:sqflite/sqflite.dart';

// ✅ Correct: Use databaseExists
if (!await databaseExists(path)) {
  // Copy database
}

// ❌ Avoid: Use File.exists directly
if (!await File(path).exists()) {
  // Copy database
}
```

### 3. **Ensure Parent Directory Exists with Permission Check**

```dart
// Ensure parent directory exists with proper error handling
try {
  final parentDir = targetFile.parent;
  if (!await parentDir.exists()) {
    await parentDir.create(recursive: true);
  }
  
  // Test write permission
  final testFile = File(join(parentDir.path, '.write_test'));
  await testFile.writeAsString('test');
  await testFile.delete();
  
} catch (dirError) {
  throw Exception('Cannot create or write to database directory: $dirError');
}
```

### 4. **Copy Assets Using Recommended Approach**

```dart
// Copy from assets using the recommended approach
final byteData = await rootBundle.load(assetPath);
final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);

// Write and flush the bytes written (important for data integrity)
await targetFile.writeAsBytes(bytes, flush: true);

// Verify the copy worked
if (await targetFile.exists()) {
  final fileSize = await targetFile.length();
  if (fileSize > 0) {
    _logger.i('Successfully copied database: $version ($fileSize bytes)');
  } else {
    throw Exception('Copied database file is empty: $targetPath');
  }
}
```

### 5. **Add Proper Error Handling and Cleanup**

```dart
try {
  // Copy database logic
} catch (e) {
  // Clean up any partial file
  try {
    final partialFile = File(targetPath);
    if (await partialFile.exists()) {
      await partialFile.delete();
    }
  } catch (cleanupError) {
    _logger.w('Failed to clean up partial file: $cleanupError');
  }
  rethrow;
}
```

### 6. **Configure Assets in pubspec.yaml**

```yaml
flutter:
  assets:
    - assets/bibles/rv.db
```

### 7. **Platform-Specific Considerations**

#### Android:
- Uses `getDatabasesPath()` (typically `/data/data/your.package/databases`)
- May require storage permissions depending on Android version
- Path validation is crucial due to potential configuration issues

#### iOS:
- Use `getLibraryDirectory()` + subdirectory
- More predictable path structure
- Generally no additional permissions needed for app-local storage

#### Desktop (Windows/Linux/macOS):
- Use `getApplicationSupportDirectory()`
- Create app-specific subdirectory
- More flexible file system access

### 8. **Testing Strategy**

```dart
// Test write permissions before copying
final testFile = File(join(parentDir.path, '.write_test'));
await testFile.writeAsString('test');
await testFile.delete();

// Verify copied file integrity
final fileSize = await targetFile.length();
if (fileSize == 0) {
  throw Exception('Copied file is empty');
}
```

## Key Takeaways

1. **Always validate paths** returned by `getDatabasesPath()`
2. **Use `databaseExists()`** for SQLite database checks
3. **Test write permissions** before attempting to copy
4. **Implement proper fallbacks** for directory access
5. **Use `flush: true`** when writing database files
6. **Clean up partial files** on failure
7. **Verify file integrity** after copying

## Common Pitfalls to Avoid

- ❌ Using `File.exists()` instead of `databaseExists()`
- ❌ Not validating paths from `getDatabasesPath()`
- ❌ Missing write permission checks
- ❌ Not using `flush: true` when writing
- ❌ No cleanup on copy failure
- ❌ Hardcoding platform-specific paths
- ❌ Not handling edge cases in directory creation

## Implementation in El-Biblio

The `BibleDatabaseService` has been updated with all these best practices:

- ✅ Robust path detection with multiple fallbacks
- ✅ Proper `databaseExists()` usage throughout
- ✅ Write permission testing
- ✅ Asset copying with flush and verification
- ✅ Comprehensive error handling and cleanup
- ✅ Platform-specific optimizations

This should resolve the readonly file system errors and provide reliable database copying across all supported platforms.
