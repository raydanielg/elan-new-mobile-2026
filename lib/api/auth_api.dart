import 'dart:convert';

import 'api_client.dart';
import 'api_response.dart';
import 'token_store.dart';

class BusinessCategory {
  const BusinessCategory({required this.id, required this.name});

  final int id;
  final String name;

  static BusinessCategory fromJson(Map<String, dynamic> json) {
    return BusinessCategory(
      id: (json['lob_id'] is int)
          ? (json['lob_id'] as int)
          : int.tryParse(json['lob_id']?.toString() ?? '') ?? 0,
      name: json['lob_name']?.toString() ?? '',
    );
  }
}

class AuthApi {
  AuthApi({required this.client, required this.tokenStore});

  final ApiClient client;
  final TokenStore tokenStore;

  bool get isLoggedIn => tokenStore.token != null && tokenStore.token!.isNotEmpty;

  String? _userIdFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length < 2) return null;

    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded);
      if (payload is Map) {
        final uid = payload['user_id'];
        if (uid == null) return null;
        final v = uid.toString().trim();
        return v.isEmpty ? null : v;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<ApiResponse<Map<String, dynamic>>> signIn({
    required String username,
    required String password,
  }) async {
    final res = await client.postJson(
      '/app/auth/signin',
      body: {
        'username': username,
        'password': password,
      },
    );

    final token = res.raw['token']?.toString();
    if (token != null && token.isNotEmpty) {
      await tokenStore.setToken(token);
    }

    // Save user email if available in response
    final userEmail = res.raw['email']?.toString() ??
        res.raw['user']?['email']?.toString() ??
        res.raw['data']?['email']?.toString();
    if (userEmail != null && userEmail.isNotEmpty) {
      await tokenStore.setUserEmail(userEmail);
    }

    return res;
  }

  Future<ApiResponse<Map<String, dynamic>>> login({
    required String username,
    required String password,
  }) {
    return client.postJson(
      '/app/auth/login',
      body: {
        'username': username,
        'password': password,
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> register({
    required String username,
    required String email,
    required String phone,
    required String country,
    required String password,
    required String iso,
    required String region,
    required String shopName,
    required String shopType,
    required String lobId,
  }) async {
    final res = await client.postJson(
      '/app/auth/register',
      body: {
        'username': username,
        'email': email,
        'phone': phone,
        'country': country,
        'password': password,
        'iso': iso,
        'region': region,
        'shop_name': shopName,
        'shop_type': shopType,
        'lob_id': lobId,
      },
    );

    final token = res.raw['token']?.toString();
    if (token != null && token.isNotEmpty) {
      await tokenStore.setToken(token);
    }

    // Save user email if available in response
    final userEmail = res.raw['email']?.toString() ??
        res.raw['user']?['email']?.toString() ??
        res.raw['data']?['email']?.toString() ??
        email; // Use the email from registration input
    if (userEmail != null && userEmail.isNotEmpty) {
      await tokenStore.setUserEmail(userEmail);
    }

    return res;
  }

  Future<ApiResponse<Map<String, dynamic>>> resetSendOtp({
    required String username,
  }) {
    return client.postJson(
      '/app/auth/reset/send',
      body: {
        'username': username,
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> requestPassword({
    required String username,
  }) {
    return client.postJson(
      '/app/auth/requestpassword',
      body: {
        'username': username,
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> addShop({
    Map<String, dynamic>? body,
  }) async {
    final payload = <String, dynamic>{...?body};
    final uid = _userIdFromToken(tokenStore.token);
    if (uid != null && uid.isNotEmpty && !payload.containsKey('user_id')) {
      payload['user_id'] = uid;
    }

    try {
      return await client.postJson('/app/auth/addshop', body: payload);
    } catch (_) {
      return client.postForm('/app/auth/addshop', body: payload);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> switchShop({
    required String shopId,
  }) {
    final userId = _userIdFromToken(tokenStore.token);
    return client.postJson(
      '/app/auth/switchshop',
      body: {
        'shop_id': shopId,
        if (userId != null) 'user_id': userId,
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> signOut() async {
    final res = await client.postJson('/app/auth/signout');
    await tokenStore.clear();
    return res;
  }

  Future<ApiResponse<Map<String, dynamic>>> constants() {
    return client.getJson('/app/auth/constants');
  }

  Future<ApiResponse<Map<String, dynamic>>> constantsPost({Object? body}) {
    return client.postJson('/app/auth/constants', body: body);
  }

  Future<List<BusinessCategory>> businessCategories() async {
    try {
      final res = await this.constants();
      final constantsPayload = res.raw['constants'];
      if (constantsPayload is Map) {
        final bc = constantsPayload['business_category'];
        if (bc is List) {
          final out = <BusinessCategory>[];
          for (final item in bc) {
            if (item is Map<String, dynamic>) {
              final parsed = BusinessCategory.fromJson(item);
              if (parsed.id != 0 && parsed.name.isNotEmpty) {
                out.add(parsed);
              }
            } else if (item is Map) {
              final parsed = BusinessCategory.fromJson(
                item.map((k, v) => MapEntry(k.toString(), v)),
              );
              if (parsed.id != 0 && parsed.name.isNotEmpty) {
                out.add(parsed);
              }
            }
          }
          out.sort((a, b) => a.name.compareTo(b.name));
          return out;
        }
      }
    } catch (_) {
      // ignore and fall back
    }

    final raw = await client.getRawJson('/auth/business_category');
    if (raw is! List) {
      return const [];
    }

    final out = <BusinessCategory>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        final parsed = BusinessCategory.fromJson(item);
        if (parsed.id != 0 && parsed.name.isNotEmpty) {
          out.add(parsed);
        }
      } else if (item is Map) {
        final parsed = BusinessCategory.fromJson(
          item.map((k, v) => MapEntry(k.toString(), v)),
        );
        if (parsed.id != 0 && parsed.name.isNotEmpty) {
          out.add(parsed);
        }
      }
    }

    out.sort((a, b) => a.name.compareTo(b.name));
    return out;
  }
}
