import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/recommendation_result.dart';

class ApiService {
  /// BEFORE: hardcoded 'http://127.0.0.1:5000'. Now delegates to AppConfig,
  /// which picks the right host per platform (see app_config.dart for why
  /// this matters on Android emulators and physical devices).
  static String get baseUrl => AppConfig.baseUrl;

  /// BEFORE: no timeout at all - a hung backend or bad network would leave
  /// the UI stuck on the loading spinner forever with no way out.
  static const _timeout = Duration(seconds: 15);

  static Future<RecommendationResult> getRecommendation({
    required double rainfall,
    required double temperature,
    required String soilType,
    required String cropType,
    required double area,
    double? budget,
  }) async {
    final requestBody = <String, dynamic>{
      'rainfall': rainfall,
      'temperature': temperature,
      'soil_type': soilType,
      'crop_type': cropType,
      'area': area,
      if (budget != null) 'budget': budget,
    };

    _log('Connecting to: $baseUrl/recommend');

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/recommend'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      _log('Response status: ${response.statusCode}');

      // AUDIT FIX: previously checked response.statusCode BEFORE ever
      // decoding the body - meaning any non-200 response (400 validation
      // errors, 429 rate limits, 500s) threw a generic
      // 'Server error: 400' and discarded the backend's actual,
      // specific error message entirely. Verified live: submitting an
      // invalid budget returns a real, helpful body
      // ({"error":"Validation failed","details":["budget: Budget must
      // be a positive number"]}) that a user would genuinely want to
      // see, but this code never even looked at it. Now the body is
      // decoded first (Flask consistently returns JSON error bodies for
      // every failure case in this API), and its 'error'/'details'
      // fields are used when present, falling back to a generic message
      // only if the body isn't the expected shape.
      Map<String, dynamic>? data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (_) {
        data = null;
      }

      if (response.statusCode != 200 || data?['status'] == 'error') {
        final serverMessage = data?['error']?.toString();
        final details = data?['details'];
        final detailText = (details is List && details.isNotEmpty)
            ? details.join('; ')
            : null;

        throw ApiException(
          detailText ??
              serverMessage ??
              'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      return RecommendationResult.fromJson(data!);
    } on http.ClientException catch (e) {
      _log('Connection error: $e');
      throw ApiException(
        'Could not reach the server. Check that the backend is running at $baseUrl',
      );
    } on FormatException catch (e) {
      _log('Response parsing error: $e');
      throw ApiException('The server returned an unexpected response format.');
    } on ApiException {
      rethrow;
    } catch (e) {
      // AUDIT FIX: previously interpolated the raw caught exception
      // object directly into the user-facing message
      // ('Failed to get recommendation: $e'), which could surface a raw
      // Dart exception toString() (implementation details, not
      // user-appropriate wording) in the UI. The real exception is still
      // logged via _log for debugging; the user gets a stable, generic
      // message instead.
      _log('Unexpected error: $e');
      throw const ApiException('An unexpected error occurred. Please try again.');
    }
  }

  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'), headers: {'Accept': 'application/json'})
          .timeout(_timeout);
      final ok = response.statusCode == 200;
      _log(ok ? 'API is reachable' : 'API returned status: ${response.statusCode}');
      return ok;
    } catch (e) {
      _log('Cannot reach API: $e');
      return false;
    }
  }

  /// BEFORE: raw print() calls left in production code, which is noisy,
  /// leaks internal details in release builds, and can't be filtered by
  /// log level. kDebugMode gate ensures this is a no-op in release builds.
  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ApiService] $message');
    }
  }
}

/// Dedicated exception type instead of throwing/catching generic
/// Exception(String) and doing fragile `.replaceAll('Exception: ', '')`
/// string surgery on the message at the call site (as the old code did).
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
