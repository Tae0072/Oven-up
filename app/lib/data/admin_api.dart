import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/menu_item.dart';
import '../models/order_detail.dart';
import '../models/order_summary.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// 관리자(사장님) 주문 관리 API 호출 (05_API §11, 화면 A4). ADMIN 토큰 필요.
class AdminApi {
  final http.Client _client;

  AdminApi({http.Client? client}) : _client = client ?? http.Client();

  /// 전체(또는 상태별) 주문 목록
  Future<List<OrderSummary>> fetchOrders(String token, {String? status}) async {
    final uri = (status == null || status.isEmpty)
        ? Uri.parse('$kApiBaseUrl/api/admin/orders')
        : Uri.parse('$kApiBaseUrl/api/admin/orders?status=${Uri.encodeQueryComponent(status)}');
    final res = await _client.get(uri, headers: {'Authorization': 'Bearer $token'});
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '주문 목록을 불러오지 못했어요'));
    }
    return (body['data'] as List<dynamic>)
        .map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 주문 상세 (관리자)
  Future<OrderDetail> fetchDetail(String token, int orderId) async {
    final res = await _client.get(
      Uri.parse('$kApiBaseUrl/api/admin/orders/$orderId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '주문을 불러오지 못했어요'));
    }
    return OrderDetail.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 주문 상태 변경
  Future<OrderDetail> updateStatus(String token, int orderId, String status) async {
    final res = await _client.patch(
      Uri.parse('$kApiBaseUrl/api/admin/orders/$orderId/status'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'status': status}),
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '상태를 바꾸지 못했어요'));
    }
    return OrderDetail.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 쿠폰 목록 (관리자)
  Future<List<AdminCoupon>> fetchCoupons(String token) async {
    final res = await _client.get(Uri.parse('$kApiBaseUrl/api/admin/coupons'),
        headers: {'Authorization': 'Bearer $token'});
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '쿠폰 목록을 불러오지 못했어요'));
    }
    return (body['data'] as List<dynamic>)
        .map((e) => AdminCoupon.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 쿠폰 발급 (관리자)
  Future<void> createCoupon(
    String token, {
    required String code,
    required String name,
    required String type, // AMOUNT / PERCENT
    required int value,
    required int minOrderAmount,
    String? expiresAtIso,
  }) async {
    final payload = <String, dynamic>{
      'code': code,
      'name': name,
      'type': type,
      'value': value,
      'minOrderAmount': minOrderAmount,
    };
    if (expiresAtIso != null && expiresAtIso.isNotEmpty) {
      payload['expiresAt'] = expiresAtIso;
    }
    final res = await _client.post(
      Uri.parse('$kApiBaseUrl/api/admin/coupons'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 201) {
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      throw ApiException(_errorMessage(body, '쿠폰 발급에 실패했어요'));
    }
  }

  // ===== 메뉴 관리 (A3) =====

  /// 전체 메뉴(품절 포함)
  Future<List<MenuItem>> fetchMenus(String token) async {
    final res = await _client.get(Uri.parse('$kApiBaseUrl/api/admin/menus'),
        headers: {'Authorization': 'Bearer $token'});
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '메뉴 목록을 불러오지 못했어요'));
    }
    return (body['data'] as List<dynamic>)
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> _menuPayload({
    required String name,
    required String description,
    required int price,
    required String bread,
    required String emoji,
    required bool best,
  }) =>
      {
        'name': name,
        'description': description,
        'price': price,
        'category': '샌드위치',
        'bread': bread,
        'emoji': emoji.isEmpty ? '🥪' : emoji,
        'best': best,
      };

  /// 메뉴 등록
  Future<void> createMenu(String token,
      {required String name,
      required String description,
      required int price,
      required String bread,
      required String emoji,
      required bool best}) async {
    final res = await _client.post(
      Uri.parse('$kApiBaseUrl/api/admin/menus'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(_menuPayload(
          name: name, description: description, price: price, bread: bread, emoji: emoji, best: best)),
    );
    if (res.statusCode != 201) {
      throw ApiException(_errorMessage(
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>, '메뉴 등록에 실패했어요'));
    }
  }

  /// 메뉴 수정
  Future<void> updateMenu(String token, int id,
      {required String name,
      required String description,
      required int price,
      required String bread,
      required String emoji,
      required bool best}) async {
    final res = await _client.put(
      Uri.parse('$kApiBaseUrl/api/admin/menus/$id'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(_menuPayload(
          name: name, description: description, price: price, bread: bread, emoji: emoji, best: best)),
    );
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>, '메뉴 수정에 실패했어요'));
    }
  }

  /// 품절/판매중 토글
  Future<void> setSoldOut(String token, int id, bool soldOut) async {
    final res = await _client.patch(
      Uri.parse('$kApiBaseUrl/api/admin/menus/$id/soldout'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'soldOut': soldOut}),
    );
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>, '상태 변경에 실패했어요'));
    }
  }

  /// 메뉴 삭제
  Future<void> deleteMenu(String token, int id) async {
    final res = await _client.delete(Uri.parse('$kApiBaseUrl/api/admin/menus/$id'),
        headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>, '메뉴 삭제에 실패했어요'));
    }
  }

  // ===== 대시보드 통계 (A5) =====

  /// 관리자 대시보드 통계 조회
  Future<DashboardStats> fetchStats(String token) async {
    final res = await _client.get(Uri.parse('$kApiBaseUrl/api/admin/stats'),
        headers: {'Authorization': 'Bearer $token'});
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '통계를 불러오지 못했어요'));
    }
    return DashboardStats.fromJson(body['data'] as Map<String, dynamic>);
  }

  String _errorMessage(Map<String, dynamic> body, String fallback) {
    final error = body['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    return fallback;
  }
}

/// 대시보드 통계 (05_API /api/admin/stats)
class DashboardStats {
  final int todaySales;
  final int todayOrders;
  final int weekSales;
  final int weekOrders;
  final int totalSales;
  final int totalOrders;
  final List<DailyPoint> daily;
  final List<StatusCount> statusCounts;
  final List<TopMenu> topMenus;

  const DashboardStats({
    required this.todaySales,
    required this.todayOrders,
    required this.weekSales,
    required this.weekOrders,
    required this.totalSales,
    required this.totalOrders,
    required this.daily,
    required this.statusCounts,
    required this.topMenus,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
        todaySales: (j['todaySales'] as num?)?.toInt() ?? 0,
        todayOrders: (j['todayOrders'] as num?)?.toInt() ?? 0,
        weekSales: (j['weekSales'] as num?)?.toInt() ?? 0,
        weekOrders: (j['weekOrders'] as num?)?.toInt() ?? 0,
        totalSales: (j['totalSales'] as num?)?.toInt() ?? 0,
        totalOrders: (j['totalOrders'] as num?)?.toInt() ?? 0,
        daily: (j['daily'] as List<dynamic>? ?? [])
            .map((e) => DailyPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        statusCounts: (j['statusCounts'] as List<dynamic>? ?? [])
            .map((e) => StatusCount.fromJson(e as Map<String, dynamic>))
            .toList(),
        topMenus: (j['topMenus'] as List<dynamic>? ?? [])
            .map((e) => TopMenu.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DailyPoint {
  final String date; // yyyy-MM-dd
  final int sales;
  final int orders;

  const DailyPoint({required this.date, required this.sales, required this.orders});

  factory DailyPoint.fromJson(Map<String, dynamic> j) => DailyPoint(
        date: (j['date'] as String?) ?? '',
        sales: (j['sales'] as num?)?.toInt() ?? 0,
        orders: (j['orders'] as num?)?.toInt() ?? 0,
      );

  /// 그래프 라벨용: 'MM.dd'의 dd (일)
  String get dayLabel {
    final parts = date.split('-');
    return parts.length == 3 ? parts[2] : date;
  }
}

class StatusCount {
  final String status;
  final int count;

  const StatusCount({required this.status, required this.count});

  factory StatusCount.fromJson(Map<String, dynamic> j) => StatusCount(
        status: (j['status'] as String?) ?? '',
        count: (j['count'] as num?)?.toInt() ?? 0,
      );
}

class TopMenu {
  final String menuName;
  final int quantity;
  final int sales;

  const TopMenu({required this.menuName, required this.quantity, required this.sales});

  factory TopMenu.fromJson(Map<String, dynamic> j) => TopMenu(
        menuName: (j['menuName'] as String?) ?? '',
        quantity: (j['quantity'] as num?)?.toInt() ?? 0,
        sales: (j['sales'] as num?)?.toInt() ?? 0,
      );
}

/// 관리자 쿠폰 정보
class AdminCoupon {
  final int couponId;
  final String code;
  final String name;
  final String type;
  final int value;
  final int minOrderAmount;
  final bool active;

  const AdminCoupon({
    required this.couponId,
    required this.code,
    required this.name,
    required this.type,
    required this.value,
    required this.minOrderAmount,
    required this.active,
  });

  factory AdminCoupon.fromJson(Map<String, dynamic> j) => AdminCoupon(
        couponId: (j['couponId'] as num).toInt(),
        code: (j['code'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        type: (j['type'] as String?) ?? '',
        value: (j['value'] as num?)?.toInt() ?? 0,
        minOrderAmount: (j['minOrderAmount'] as num?)?.toInt() ?? 0,
        active: (j['active'] as bool?) ?? true,
      );

  String get discountText => type == 'PERCENT' ? '$value%' : '$value원';
}

/// 관리자가 바꿀 수 있는 주문 상태 (서버 ADMIN_STATUSES와 맞춤)
const List<String> kAdminStatuses = [
  '준비중',
  '준비완료',
  '픽업완료',
  '배달중',
  '배달완료',
  '취소',
];
