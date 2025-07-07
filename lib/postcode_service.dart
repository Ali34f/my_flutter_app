import 'package:http/http.dart' as http;
import 'dart:convert';

class PostcodeService {
  // Postcodes.io API
  static const String baseUrl = 'https://api.postcodes.io';

  static Future<Map<String, String>> lookupPostcode(String postcode) async {
    try {
      // Clean postcode
      final cleanPostcode = postcode.replaceAll(' ', '').toUpperCase();

      // Make API call
      final response = await http.get(
        Uri.parse('$baseUrl/postcodes/$cleanPostcode'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 200 && data['result'] != null) {
          final result = data['result'];

          return {
            'city': result['admin_district'] ?? result['parish'] ?? '',
            'region': result['region'] ?? '',
            'country': result['country'] ?? 'England',
            'latitude': result['latitude']?.toString() ?? '',
            'longitude': result['longitude']?.toString() ?? '',
          };
        } else {
          throw Exception('Invalid postcode format');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Postcode not found. Please check and try again.');
      } else {
        throw Exception(
          'Service temporarily unavailable. Please try again later.',
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        throw Exception(
          'No internet connection. Please check your connection and try again.',
        );
      } else if (e.toString().startsWith('Exception:')) {
        rethrow; // Re-throw our custom exceptions
      } else {
        throw Exception('Failed to verify postcode. Please try again.');
      }
    }
  }

  // Validate UK postcode format
  static bool isValidUKPostcode(String postcode) {
    final cleanPostcode = postcode.replaceAll(' ', '').toUpperCase();
    // UK postcode regex pattern
    return RegExp(
      r'^[A-Z]{1,2}[0-9][A-Z0-9]?[0-9][A-Z]{2}$',
    ).hasMatch(cleanPostcode);
  }

  // Format postcode properly (add space if missing)
  static String formatPostcode(String postcode) {
    final cleanPostcode = postcode.replaceAll(' ', '').toUpperCase();
    if (cleanPostcode.length >= 5) {
      final outward = cleanPostcode.substring(0, cleanPostcode.length - 3);
      final inward = cleanPostcode.substring(cleanPostcode.length - 3);
      return '$outward $inward';
    }
    return cleanPostcode;
  }
}
