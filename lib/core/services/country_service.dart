import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class CountryService {
  final Logger _logger;
  final Dio _externalDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      responseType: ResponseType.json,
    ),
  );

  CountryService(this._logger);

  /// Fetches the user's country code (e.g., '+1') via IP geolocation.
  /// Falls back to '+1' (US) if detection fails.
  Future<String> detectCountryCode() async {
    try {
      final response = await _externalDio.get<Map<String, dynamic>>(
        'https://ipapi.co/json/',
      );
      final data = response.data as Map<String, dynamic>;
      final countryCode = data['country_calling_code'] as String?;
      if (countryCode != null && countryCode.isNotEmpty) {
        _logger.i('[CountryService] Detected country code: $countryCode');
        return countryCode;
      }
    } catch (e) {
      _logger.w('[CountryService] ipapi detection failed: $e');
    }

    try {
      final response = await _externalDio.get<Map<String, dynamic>>(
        'https://ipwho.is/',
      );
      final data = response.data as Map<String, dynamic>;
      final callingCode = data['calling_code']?.toString();
      if (callingCode != null && callingCode.isNotEmpty) {
        final countryCode = callingCode.startsWith('+')
            ? callingCode
            : '+$callingCode';
        _logger.i('[CountryService] Detected country code: $countryCode');
        return countryCode;
      }

      final country = data['country_code']?.toString().toUpperCase();
      final mapped = _countryCallingCodes[country];
      if (mapped != null) {
        _logger.i('[CountryService] Mapped country $country to $mapped');
        return mapped;
      }
    } catch (e) {
      _logger.w('[CountryService] ipwho.is detection failed: $e');
    }

    _logger.i('[CountryService] Using fallback country code: +1');
    return '+1';
  }

  static const Map<String, String> _countryCallingCodes = {
    'US': '+1',
    'CA': '+1',
    'NG': '+234',
    'GB': '+44',
    'GH': '+233',
    'KE': '+254',
    'ZA': '+27',
    'IN': '+91',
    'PH': '+63',
    'BR': '+55',
    'MX': '+52',
    'FR': '+33',
    'DE': '+49',
    'ES': '+34',
    'IT': '+39',
    'AU': '+61',
  };
}
