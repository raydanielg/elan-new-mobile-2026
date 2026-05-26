import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const String _tokenKey = 'auth_token';
  static const String _shopIdKey = 'selected_shop_id';
  static const String _userEmailKey = 'user_email';
  static const String _filterTypeKey = 'global_filter_type';
  static const String _filterFromKey = 'global_filter_from';
  static const String _filterToKey = 'global_filter_to';
  static const String _filterTitleKey = 'global_filter_title';
  
  String? _token;
  String? _selectedShopId;
  String? _userEmail;
  
  // Global filter state
  String _globalFilterType = 'reset';
  String? _globalFilterFrom;
  String? _globalFilterTo;
  String _globalFilterTitle = 'All Time';

  String? get token => _token;
  String? get selectedShopId => _selectedShopId;
  String? get userEmail => _userEmail;
  
  // Global filter getters
  String get globalFilterType => _globalFilterType;
  String? get globalFilterFrom => _globalFilterFrom;
  String? get globalFilterTo => _globalFilterTo;
  String get globalFilterTitle => _globalFilterTitle;
  
  /// Returns true if a custom filter is active
  bool get hasActiveFilter => _globalFilterType != 'reset';

  /// Loads the token and shop from local storage.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _selectedShopId = prefs.getString(_shopIdKey);
    _userEmail = prefs.getString(_userEmailKey);
    
    // Load global filter
    _globalFilterType = prefs.getString(_filterTypeKey) ?? 'reset';
    _globalFilterFrom = prefs.getString(_filterFromKey);
    _globalFilterTo = prefs.getString(_filterToKey);
    _globalFilterTitle = prefs.getString(_filterTitleKey) ?? 'All Time';
  }

  /// Sets the token and saves it to local storage.
  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }
  }

  /// Sets the selected shop and saves it to local storage.
  Future<void> setSelectedShopId(String? shopId) async {
    _selectedShopId = shopId;
    final prefs = await SharedPreferences.getInstance();
    if (shopId != null) {
      await prefs.setString(_shopIdKey, shopId);
    } else {
      await prefs.remove(_shopIdKey);
    }
  }

  /// Sets the user email and saves it to local storage.
  Future<void> setUserEmail(String? email) async {
    _userEmail = email;
    final prefs = await SharedPreferences.getInstance();
    if (email != null) {
      await prefs.setString(_userEmailKey, email);
    } else {
      await prefs.remove(_userEmailKey);
    }
  }

  /// Sets the global filter and saves it to local storage.
  Future<void> setGlobalFilter({
    required String type,
    String? from,
    String? to,
    String? title,
  }) async {
    _globalFilterType = type;
    _globalFilterFrom = from;
    _globalFilterTo = to;
    if (title != null) _globalFilterTitle = title;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_filterTypeKey, type);
    if (from != null) {
      await prefs.setString(_filterFromKey, from);
    } else {
      await prefs.remove(_filterFromKey);
    }
    if (to != null) {
      await prefs.setString(_filterToKey, to);
    } else {
      await prefs.remove(_filterToKey);
    }
    if (title != null) {
      await prefs.setString(_filterTitleKey, title);
    }
  }

  /// Resets the global filter.
  Future<void> resetGlobalFilter() async {
    _globalFilterType = 'reset';
    _globalFilterFrom = null;
    _globalFilterTo = null;
    _globalFilterTitle = 'All Time';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_filterTypeKey);
    await prefs.remove(_filterFromKey);
    await prefs.remove(_filterToKey);
    await prefs.remove(_filterTitleKey);
  }

  /// Clears the token and shop from memory and local storage.
  Future<void> clear() async {
    _token = null;
    _selectedShopId = null;
    _userEmail = null;
    _globalFilterType = 'reset';
    _globalFilterFrom = null;
    _globalFilterTo = null;
    _globalFilterTitle = 'All Time';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_shopIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_filterTypeKey);
    await prefs.remove(_filterFromKey);
    await prefs.remove(_filterToKey);
    await prefs.remove(_filterTitleKey);
  }
}
