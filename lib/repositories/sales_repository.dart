import '../api/api_response.dart';
import '../api/api_service.dart';
import 'api_result.dart';
import 'shop_context.dart';

class SalesRepository {
  SalesRepository._();

  static final SalesRepository instance = SalesRepository._();

  Future<ApiResult<List<dynamic>>> getSalesOrders({String? shopId}) async {
    try {
      await ShopContext.instance.ensureShop(shopId);
      final raw = await ApiService.instance.app.getSalesOrders();
      final data = _asList(raw is Map ? (raw['data'] ?? raw) : raw);
      return ApiResult.success(data);
    } catch (e) {
      return ApiResult.failure(message: e.toString(), error: e);
    }
  }

  Future<ApiResult<Map<String, dynamic>>> getSaleRecord(String saleId, {String? shopId}) async {
    try {
      await ShopContext.instance.ensureShop(shopId);
      final raw = await ApiService.instance.app.getSaleRecord(saleId);
      if (raw is Map<String, dynamic>) {
        return ApiResult.success(raw);
      }
      if (raw is Map) {
        return ApiResult.success(Map<String, dynamic>.from(raw));
      }
      return ApiResult.failure(message: 'Invalid sale record response');
    } catch (e) {
      return ApiResult.failure(message: e.toString(), error: e);
    }
  }

  Future<ApiResult<ApiResponse<Map<String, dynamic>>>> sendEmail({
    required String type,
    required String recordId,
    required String email,
    String? shopId,
  }) async {
    try {
      await ShopContext.instance.ensureShop(shopId);
      final res = await ApiService.instance.app.sendEmail(type: type, recordId: recordId, email: email);
      return ApiResult.success(res, message: res.message);
    } catch (e) {
      return ApiResult.failure(message: e.toString(), error: e);
    }
  }

  List<dynamic> _asList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map) {
      final data = raw['data'] ?? raw['result'] ?? raw['rows'] ?? raw['list'];
      if (data is List) return data;
    }
    return const [];
  }
}
