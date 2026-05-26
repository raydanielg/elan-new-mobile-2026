import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_exception.dart';
import 'api_response.dart';
import 'api_config.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient({
    required this.config,
    required this.tokenStore,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final ApiConfig config;
  final TokenStore tokenStore;
  final http.Client _http;

  Uri _uri(String path, [Map<String, dynamic>? queryParameters]) {
    final base = Uri.parse(config.baseUrl);

    final normalizedBasePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;

    final normalizedPath = path.startsWith('/') ? path : '/$path';

    final qp = queryParameters?.map((k, v) => MapEntry(k, v?.toString()));

    return base.replace(
      path: '$normalizedBasePath$normalizedPath',
      queryParameters: qp,
    );
  }

  Map<String, String> _headers({
    String? token,
    Map<String, String>? extra,
  }) {
    final resolvedToken = token ?? tokenStore.token;

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (resolvedToken != null && resolvedToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $resolvedToken';
      headers['token'] = resolvedToken;
    }

    if (extra != null) {
      headers.addAll(extra);
    }

    return headers;
  }

  Future<ApiResponse<Map<String, dynamic>>> getJson(
    String path, {
    String? token,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _uri(path, queryParameters);

    final resp = await _http.get(
      uri,
      headers: _headers(token: token, extra: headers),
    );

    return _parseResponse(resp);
  }

  Future<ApiResponse<Map<String, dynamic>>> postForm(
    String path, {
    Map<String, dynamic>? body,
    String? token,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _uri(path, queryParameters);

    final form = <String, String>{};
    if (body != null) {
      for (final e in body.entries) {
        final v = e.value;
        if (v == null) continue;
        form[e.key] = v.toString();
      }
    }

    final resp = await _http.post(
      uri,
      headers: _headers(
        token: token,
        extra: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          ...?headers,
        },
      ),
      body: form,
    );

    return _parseResponse(resp);
  }

  Future<dynamic> getRawJson(
    String path, {
    String? token,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _uri(path, queryParameters);

    final resp = await _http.get(
      uri,
      headers: _headers(token: token, extra: headers),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(
        'Request failed',
        statusCode: resp.statusCode.toString(),
        details: {
          'body': resp.body,
        },
      );
    }

    try {
      return jsonDecode(resp.body);
    } catch (e) {
      throw ApiException(
        'Invalid response from server',
        details: {
          'http_status': resp.statusCode,
          'body': resp.body,
          'error': e.toString(),
        },
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> postJson(
    String path, {
    Object? body,
    String? token,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _uri(path, queryParameters);

    final resp = await _http.post(
      uri,
      headers: _headers(token: token, extra: headers),
      body: body == null ? null : jsonEncode(body),
    );

    return _parseResponse(resp);
  }

  ApiResponse<Map<String, dynamic>> _parseResponse(http.Response resp) {
    Map<String, dynamic> json;
    final bodyText = utf8.decode(resp.bodyBytes);

    // Handle empty response
    if (bodyText.trim().isEmpty) {
      throw ApiException(
        'Server returned empty response',
        statusCode: resp.statusCode.toString(),
        details: {'http_status': resp.statusCode},
      );
    }

    try {
      final decoded = jsonDecode(bodyText);
      if (decoded is Map<String, dynamic>) {
        json = decoded;
      } else if (decoded is List) {
        // Wrap list response in a map
        json = {'data': decoded, 'status': true};
      } else {
        json = {'data': decoded, 'status': true};
      }
    } catch (e) {
      // Response is not JSON (might be HTML error page)
      final isHtml = bodyText.trim().startsWith('<') || bodyText.trim().startsWith('<!');
      if (isHtml) {
        throw ApiException(
          'Server returned HTML instead of JSON. Check your API endpoint or authentication.',
          statusCode: resp.statusCode.toString(),
          details: {
            'http_status': resp.statusCode,
            'body_preview': bodyText.length > 200 ? bodyText.substring(0, 200) : bodyText,
          },
        );
      }
      throw ApiException(
        'Invalid response from server',
        statusCode: resp.statusCode.toString(),
        details: {
          'http_status': resp.statusCode,
          'body': bodyText.length > 500 ? bodyText.substring(0, 500) : bodyText,
          'error': e.toString(),
        },
      );
    }

    final parsed = ApiResponse.fromJson(json);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(
        parsed.message ?? 'Request failed (HTTP ${resp.statusCode})',
        statusCode: parsed.statusCode ?? resp.statusCode.toString(),
        details: parsed.raw,
      );
    }

    if (parsed.status == false) {
      throw ApiException(
        parsed.message ?? 'Request failed',
        statusCode: parsed.statusCode,
        details: parsed.raw,
      );
    }

    return parsed;
  }

  Future<ApiResponse<Map<String, dynamic>>> postMultipart(
    String path, {
    Map<String, String>? fields,
    List<File>? files,
    String? fileKey,
    String? token,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _uri(path, queryParameters);
    final request = http.MultipartRequest('POST', uri);

    // Add headers (without Content-Type - multipart sets its own with boundary)
    final resolvedToken = token ?? tokenStore.token;
    if (resolvedToken != null && resolvedToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $resolvedToken';
      request.headers['token'] = resolvedToken;
    }
    request.headers['Accept'] = 'application/json';

    // Add fields
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Add files
    if (files != null && fileKey != null) {
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();
        final multipartFile = http.MultipartFile(
          fileKey,
          stream,
          length,
          filename: file.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }
    }

    // Debug logging
    if (kDebugMode) {
      print('[POST MULTIPART] URL: $uri');
      print('[POST MULTIPART] Fields: ${request.fields}');
      print('[POST MULTIPART] Files count: ${request.files.length}');
    }

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Request timed out after 60 seconds');
        },
      );
      final resp = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print('[POST MULTIPART] Response status: ${resp.statusCode}');
        print('[POST MULTIPART] Response body preview: ${resp.body.length > 200 ? resp.body.substring(0, 200) : resp.body}');
      }

      return _parseResponse(resp);
    } on TimeoutException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('[POST MULTIPART] Error: $e');
      }
      rethrow;
    }
  }
}
