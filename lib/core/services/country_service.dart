import 'package:logger/logger.dart';

import '../network/dio_client.dart';

class CountryService {
  final DioClient _dioClient;
  final Logger _logger;

  CountryService(this._dioClient, this._logger);

  /// Fetches the user's country code (e.g., '+1') via IP geolocation.
  /// Falls back to '+1' (US) if detection fails.
  Future<String> detectCountryCode() async {
    try {
      // Using ipapi.co (free tier, no API key needed)
      final response = await _dioClient.get('https://ipapi.co/json/');
      final data = response.data as Map<String, dynamic>;
      final countryCode = data['country_calling_code'] as String?;
      if (countryCode != null && countryCode.isNotEmpty) {
        _logger.i('[CountryService] Detected country code: $countryCode');
        return countryCode;
      }
    } catch (e) {
      _logger.w('[CountryService] Failed to detect country code: $e');
    }
    // Fallback to US
    _logger.i('[CountryService] Using fallback country code: +1');
    return '+1';
  }
}
