import '../api/api_service.dart';
import '../services/permission_service.dart';

class ShopContext {
  ShopContext._();

  static final ShopContext instance = ShopContext._();

  String? _activeShopId;
  bool _isSwitching = false;

  String? get activeShopId => _activeShopId;

  Future<void> ensureShop(String? shopId) async {
    final targetShopId = (shopId ?? ApiService.instance.tokenStore.selectedShopId)?.trim();
    if (targetShopId == null || targetShopId.isEmpty) return;

    if (_activeShopId == targetShopId) return;

    // Prevent concurrent shop switches
    if (_isSwitching) return;
    _isSwitching = true;

    try {
      // Add timeout to prevent hanging during network issues
      final res = await ApiService.instance.auth
          .switchShop(shopId: targetShopId)
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Shop switch timed out after 30 seconds');
      });

      // Check if response is valid before accessing raw
      if (res.status) {
        final newToken = res.raw['token']?.toString();
        if (newToken != null && newToken.isNotEmpty) {
          await ApiService.instance.tokenStore.setToken(newToken);
        }
      }

      await ApiService.instance.tokenStore.setSelectedShopId(targetShopId);
      _activeShopId = targetShopId;

      // Initialize permissions with error handling
      try {
        await PermissionService().init();
      } catch (e) {
        // Silently fail permission init - app can still work
        print('Permission init failed: $e');
      }
    } catch (e) {
      print('ShopContext.ensureShop error: $e');
      // Don't crash - just log and continue
      // The UI should handle showing appropriate error
      rethrow;
    } finally {
      _isSwitching = false;
    }
  }

  void clear() {
    _activeShopId = null;
  }
}
