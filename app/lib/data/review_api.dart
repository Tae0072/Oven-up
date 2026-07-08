import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

/// 리뷰 API (03_기능 §12)
/// - GET  /api/menus/{menuId}/reviews : 목록 + 요약 (공개)
/// - POST /api/menus/{menuId}/reviews : 작성 (로그인 + 구매자)
class ReviewApi {
  final http.Client _client;

  ReviewApi({http.Client? client}) : _client = client ?? http.Client();

  Future<MenuReviews> fetchReviews(int menuId) async {
    final res = await _client.get(Uri.parse('$kApiBaseUrl/api/menus/$menuId/reviews'));
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '리뷰를 불러오지 못했어요'));
    }
    return MenuReviews.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// 리뷰 작성 가능 여부 (구매 이력·중복 확인). canWrite=false면 reason에 안내문.
  Future<({bool canWrite, String reason})> checkEligibility({
    required String token,
    required int menuId,
  }) async {
    final res = await _client.get(
      Uri.parse('$kApiBaseUrl/api/menus/$menuId/reviews/eligibility'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(body, '리뷰 작성 가능 여부를 확인하지 못했어요'));
    }
    final data = body['data'] as Map<String, dynamic>;
    return (
      canWrite: (data['canWrite'] as bool?) ?? false,
      reason: (data['reason'] as String?) ?? '',
    );
  }

  Future<void> createReview({
    required String token,
    required int menuId,
    required int rating,
    required String content,
  }) async {
    final res = await _client.post(
      Uri.parse('$kApiBaseUrl/api/menus/$menuId/reviews'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'rating': rating, 'content': content}),
    );
    if (res.statusCode != 201) {
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      throw ApiException(_errorMessage(body, '리뷰 작성에 실패했어요'));
    }
  }

  String _errorMessage(Map<String, dynamic> body, String fallback) {
    final error = body['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    return fallback;
  }
}

/// 메뉴 리뷰 요약 + 목록
class MenuReviews {
  final double ratingAvg;
  final int reviewCount;
  final List<ReviewView> items;

  const MenuReviews({required this.ratingAvg, required this.reviewCount, required this.items});

  factory MenuReviews.fromJson(Map<String, dynamic> j) => MenuReviews(
        ratingAvg: (j['ratingAvg'] as num?)?.toDouble() ?? 0,
        reviewCount: (j['reviewCount'] as num?)?.toInt() ?? 0,
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => ReviewView.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 리뷰 한 건
class ReviewView {
  final int reviewId;
  final int rating;
  final String content;
  final String authorName;

  const ReviewView({
    required this.reviewId,
    required this.rating,
    required this.content,
    required this.authorName,
  });

  factory ReviewView.fromJson(Map<String, dynamic> j) => ReviewView(
        reviewId: (j['reviewId'] as num?)?.toInt() ?? 0,
        rating: (j['rating'] as num?)?.toInt() ?? 0,
        content: (j['content'] as String?) ?? '',
        authorName: (j['authorName'] as String?) ?? '',
      );
}
