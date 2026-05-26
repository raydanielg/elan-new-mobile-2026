import 'api.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  final TokenStore tokenStore = TokenStore();

  late final ApiClient client = ApiClient(
    config: const ApiConfig(baseUrl: kApiBaseUrl),
    tokenStore: tokenStore,
  );

  late final AuthApi auth = AuthApi(client: client, tokenStore: tokenStore);
  late final AppApi app = AppApi(client: client);
}
