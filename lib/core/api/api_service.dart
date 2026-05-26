import 'api_client.dart';
import 'api_endpoints.dart';

class ApiService {
  ApiService._privateConstructor();
  static final ApiService instance = ApiService._privateConstructor();

  final ApiClient _client = ApiClient.instance;

  // Initialize service
  Future<void> init() async {
    await _client.init();
  }

  // Check login state
  bool get isLoggedIn => _client.isLoggedIn;
  String? get token => _client.token;

  // ==========================================
  // 1. AUTH SERVICE WRAPPERS
  // ==========================================

  /// Login a user and capture JWT Token
  Future<Map<String, dynamic>> signin(String username, String password) async {
    final response = await _client.post(ApiEndpoints.authSignin, body: {
      'username': username,
      'password': password,
    });

    final token = response['token'];
    if (token != null) {
      await _client.saveToken(token);
    }
    return response;
  }

  /// Create a new account and shop
  Future<Map<String, dynamic>> register({
    required String username,
    required String shopName,
    required String shopType,
    required String phone,
    required String email,
    required String password,
    String? country,
    String? iso,
    String? region,
    String? lobId,
    String? resellerId,
  }) async {
    return await _client.post(ApiEndpoints.authRegister, body: {
      'username': username,
      'shop_name': shopName,
      'shop_type': shopType,
      'phone': phone,
      'email': email,
      'password': password,
      'confirm_password': password,
      if (country != null) 'country': country,
      if (iso != null) 'iso': iso,
      if (region != null) 'region': region,
      if (lobId != null) 'lob_id': lobId,
      if (resellerId != null) 'reseller_id': resellerId,
    });
  }

  /// Complete profile fields during onboarding
  Future<Map<String, dynamic>> completeProfile({
    required String region,
    required String lobId,
    String? resellerId,
  }) async {
    return await _client.post(ApiEndpoints.authCompleteProfile, body: {
      'region': region,
      'lob_id': lobId,
      if (resellerId != null) 'reseller_id': resellerId,
    });
  }

  /// Send password recovery SMS OTP
  Future<Map<String, dynamic>> resetPasswordOtp(String username) async {
    return await _client.post(ApiEndpoints.authResetSend, body: {
      'username': username,
    });
  }

  /// Verify OTP and reset password
  Future<Map<String, dynamic>> verifyOtpAndReset({
    required String username,
    required String otp,
    required String newPassword,
  }) async {
    return await _client.post(ApiEndpoints.authResetVerify, body: {
      'username': username,
      'otp': otp,
      'new_password': newPassword,
    });
  }

  /// Create an additional shop
  Future<Map<String, dynamic>> addShop({
    required String shopName,
    required String shopType,
    required String lobId,
  }) async {
    return await _client.post(ApiEndpoints.authAddShop, body: {
      'shop_name': shopName,
      'shop_type': shopType,
      'lob_id': lobId,
    });
  }

  /// Switch active shop context in current session (Updates JWT Token)
  Future<Map<String, dynamic>> switchShop(String shopId) async {
    final response = await _client.post(
      '${ApiEndpoints.authSwitchShop}/$shopId',
    );

    final newToken = response['token'];
    if (newToken != null) {
      await _client.saveToken(newToken);
    }
    return response;
  }

  /// Fetch public static categories and menus
  Future<Map<String, dynamic>> fetchConstants() async {
    return await _client.get(ApiEndpoints.authConstants);
  }

  /// Log out from session and remove JWT Token
  Future<Map<String, dynamic>> signout() async {
    try {
      return await _client.post(ApiEndpoints.authSignout);
    } finally {
      await _client.clearToken();
    }
  }


  // ==========================================
  // 2. GETTER / READ SERVICE WRAPPERS
  // ==========================================

  /// Fetch the active post-login dashboard menu
  Future<Map<String, dynamic>> fetchDashboardMenu() async {
    return await _client.get(ApiEndpoints.getDashboard);
  }

  /// Fetch dashboard summary data
  Future<Map<String, dynamic>> fetchDashboardSummary() async {
    return await _client.get(ApiEndpoints.getData('dashboard_summary'));
  }

  /// Fetch list/entity data dynamically via helper endpoint
  Future<dynamic> fetchData(String endpoint, {Map<String, String>? queryParams}) async {
    return await _client.get(
      ApiEndpoints.getData(endpoint),
      queryParameters: queryParams,
    );
  }

  /// Fetch a custom report dataset dynamically
  Future<dynamic> fetchReport(String reportFunction, {Map<String, String>? queryParams}) async {
    return await _client.get(
      ApiEndpoints.getReport(reportFunction),
      queryParameters: queryParams,
    );
  }


  // ==========================================
  // 3. POST / MUTATION SERVICE WRAPPERS
  // ==========================================

  /// Post/Write operations dynamically via endpoint
  Future<dynamic> postData(String endpoint, Map<String, dynamic> payload) async {
    return await _client.post(
      ApiEndpoints.postData(endpoint),
      body: payload,
    );
  }

  /// Set the shared date filter context
  Future<Map<String, dynamic>> setDateFilter({
    required String filter,
    String? from,
    String? to,
    String? title,
  }) async {
    return await postData('filter/set', {
      'filter': filter,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (title != null) 'title': title,
    });
  }

  /// Set the shared date filter context for reports
  Future<Map<String, dynamic>> setReportFilter({
    required String filter,
    String? from,
    String? to,
    String? title,
  }) async {
    return await postData('report/filter/set', {
      'filter': filter,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (title != null) 'title': title,
    });
  }
}
