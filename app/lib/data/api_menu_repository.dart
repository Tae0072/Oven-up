import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/menu_item.dart';
import 'menu_repository.dart';

/// 서버 기본 주소.
/// - 웹 / 데스크톱: http://localhost:8080
/// - ⚠️ 안드로이드 에뮬레이터에서는 http://10.0.2.2:8080 을 써야 함(추후 플랫폼 분기).
const String kApiBaseUrl = 'http://localhost:8080';

/// 실제 서버(Spring Boot)에서 메뉴를 가져오는 저장소. (05_API §3.1)
class ApiMenuRepository implements MenuRepository {
  final http.Client _client;

  ApiMenuRepository({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<List<MenuItem>> fetchMenus() async {
    final response = await _client.get(Uri.parse('$kApiBaseUrl/api/menus'));
    if (response.statusCode != 200) {
      throw Exception('메뉴를 불러오지 못했어요 (상태코드 ${response.statusCode})');
    }
    // 한글이 깨지지 않도록 UTF-8로 직접 디코드
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final data = (body['data'] as List<dynamic>)
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return data;
  }
}
