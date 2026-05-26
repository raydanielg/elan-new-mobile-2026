import '../api/api_service.dart';
import 'api_result.dart';
import 'shop_context.dart';

class FilterRepository {
  FilterRepository._();

  static final FilterRepository instance = FilterRepository._();

  Future<ApiResult<Map<String, dynamic>>> applyGlobalFilter({String? shopId}) async {
    try {
      await ShopContext.instance.ensureShop(shopId);

      final filterType = ApiService.instance.tokenStore.globalFilterType;
      if (filterType != 'reset') {
        final body = <String, String>{'filter': filterType};
        final from = ApiService.instance.tokenStore.globalFilterFrom;
        final to = ApiService.instance.tokenStore.globalFilterTo;
        if (from != null) body['from'] = from;
        if (to != null) body['to'] = to;
        await ApiService.instance.app.postData('filter/set', body: body);
      }

      final fr = await ApiService.instance.app.getData('filter_range');
      if (fr is Map) {
        return ApiResult.success(fr.map((k, v) => MapEntry(k.toString(), v)));
      }
      return ApiResult.success(const {});
    } catch (e) {
      return ApiResult.failure(message: e.toString(), error: e);
    }
  }

  Future<ApiResult<void>> resetBackendFilter({String? shopId}) async {
    try {
      await ShopContext.instance.ensureShop(shopId);
      await ApiService.instance.app.postData('filter/set', body: {'filter': 'reset'});
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(message: e.toString(), error: e);
    }
  }
}
