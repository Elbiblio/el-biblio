import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/today/domain/models/daily_anchors.dart';

class PrayerSharingService {
  static const String _baseUrl = 'https://elbiblio.com/images';
  final Dio _dio = Dio();

  /// Maps virtue types to their corresponding image filenames
  String _getVirtueImageFileName(VirtueType virtue) {
    switch (virtue) {
      case VirtueType.humility:
        return 'humility-foundation.jpg';
      case VirtueType.love:
        return 'living-water.jpg'; // Using existing image as metaphor for love
      case VirtueType.faith:
        return 'pentecost-renewal.jpg'; // Pentecost represents faith/renewal
      case VirtueType.knowledge:
        return 'wisdom-retreat.jpg'; // Wisdom relates to knowledge
    }
  }

  /// Generates the prayer text based on virtue
  String _generatePrayerText(VirtueType virtue) {
    switch (virtue) {
      case VirtueType.humility:
        return 'I pray for humility this day.';
      case VirtueType.love:
        return 'I pray for love this day.';
      case VirtueType.faith:
        return 'I pray for faith this day.';
      case VirtueType.knowledge:
        return 'I pray for knowledge this day.';
    }
  }

  /// Downloads virtue image and shares it with prayer text
  Future<void> shareDailyPrayer(VirtueType virtue) async {
    try {
      // Generate prayer text
      final prayerText = _generatePrayerText(virtue);
      final imageFileName = _getVirtueImageFileName(virtue);
      final imageUrl = '$_baseUrl/$imageFileName';

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final imagePath = '${tempDir.path}/$imageFileName';

      // Download image
      await _dio.download(
        imageUrl,
        imagePath,
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      // Share image with text
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: prayerText,
      );

    } catch (e) {
      // Fallback: share text only if image download fails
      await Share.share(
        _generatePrayerText(virtue),
        subject: "Today's Prayer",
      );
    }
  }

  /// Downloads image and returns local path for caching
  Future<String?> downloadVirtueImage(VirtueType virtue) async {
    try {
      final imageFileName = _getVirtueImageFileName(virtue);
      final imageUrl = '$_baseUrl/$imageFileName';

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final imagePath = '${tempDir.path}/$imageFileName';

      // Check if file already exists
      final file = File(imagePath);
      if (await file.exists()) {
        return imagePath;
      }

      // Download image
      await _dio.download(
        imageUrl,
        imagePath,
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      return imagePath;
    } catch (e) {
      return null;
    }
  }
}
