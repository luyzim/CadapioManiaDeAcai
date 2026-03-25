import '../models/menu_models.dart';
import 'api_client.dart';

class MenuService {
  MenuService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<MenuCategory>> fetchCategories() async {
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      await _apiClient.get('/api/menu') as Map,
    );

    final List<dynamic> rawCategories = List<dynamic>.from(
      data['categories'] as List<dynamic>? ?? <dynamic>[],
    );

    return rawCategories
        .map(
          (dynamic category) =>
              MenuCategory.fromMap(Map<String, dynamic>.from(category as Map)),
        )
        .toList();
  }
}
