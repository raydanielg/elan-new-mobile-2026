import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_endpoints.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  ApiException(this.statusCode, this.message, [this.details]);

  @override
  String toString() => 'ApiException [$statusCode]: $message';
}

class ApiClient {
  ApiClient._privateConstructor();
  static final ApiClient instance = ApiClient._privateConstructor();

  static const String _tokenKey = 'jwt_auth_token';
  String? _cachedToken;

  /// Initialize and load cached JWT token
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    if (kDebugMode) {
      print('API Client initialized. Token cached: ${_cachedToken != null}');
    }
  }

  /// Get the current JWT token
  String? get token => _cachedToken;

  /// Save a new JWT token
  Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Delete the current token (signout)
  Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Check if user is logged in
  bool get isLoggedIn => _cachedToken != null;

  /// Helper to build headers
  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (_cachedToken != null) {
      headers['Authorization'] = 'Bearer $_cachedToken';
      if (kDebugMode) {
        print('Using token: ${_cachedToken?.substring(0, 20)}...');
        print('Full token length: ${_cachedToken?.length}');
      }
    } else {
      if (kDebugMode) {
        print('No token available');
      }
    }
    return headers;
  }

  /// Core GET wrapper
  Future<dynamic> get(String path, {Map<String, String>? queryParameters}) async {
    try {
      final uri = _buildUri(path, queryParameters);
      if (kDebugMode) {
        print('API GET -> $uri');
      }

      final response = await http.get(uri, headers: _buildHeaders());
      return _processResponse(response);
    } catch (e) {
      _handleNetworkError(e);
    }
  }

  /// Core POST wrapper
  Future<dynamic> post(String path, {dynamic body}) async {
    try {
      final uri = _buildUri(path);
      if (kDebugMode) {
        print('API POST -> $uri');
        if (body != null) {
          print('API Payload -> ${jsonEncode(body)}');
        }
      }

      final response = await http.post(
        uri,
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      _handleNetworkError(e);
    }
  }

  /// Build full URI
  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '${ApiEndpoints.baseUrl}$cleanPath';
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return Uri.parse(fullUrl).replace(queryParameters: queryParameters);
    }
    return Uri.parse(fullUrl);
  }

  /// Process response payload and handle status codes
  dynamic _processResponse(http.Response response) {
    final int status = response.statusCode;
    if (kDebugMode) {
      print('API Response [$status] -> ${response.body}');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      // Return raw body if not JSON
      if (status >= 200 && status < 300) {
        return response.body;
      }
      throw ApiException(status, 'Invalid server response. Non-JSON output.');
    }

    if (status >= 200 && status < 300) {
      // Standard API error mapping inside JSON responses
      if (decoded is Map && decoded['status'] == false) {
        final message = decoded['message'] ?? 'An API operation failed';
        final statusCode = decoded['statusCode'] ?? status.toString();
        throw ApiException(int.tryParse(statusCode.toString()) ?? 400, message, decoded);
      }
      return decoded;
    }

    if (status == 401) {
      if (kDebugMode) {
        print('401 Unauthorized - Clearing token and forcing re-login');
      }
      clearToken(); // Force logout on unauthorized
      throw ApiException(401, 'Session expired. Please sign in again.', decoded);
    }

    final errorMessage = decoded is Map ? (decoded['message'] ?? 'Server error') : 'Server error';
    throw ApiException(status, errorMessage, decoded);
  }

  /// Network error handler
  void _handleNetworkError(dynamic e) {
    if (kDebugMode) {
      print('API Client Error: $e');
    }
    if (e is ApiException) {
      throw e;
    }
    throw ApiException(0, 'Network connection failed. Please check your internet connection.');
  }
}
