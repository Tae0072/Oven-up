import 'menu_option.dart';

/// 메뉴 한 개를 나타내는 데이터 모델.
/// 서버 API(GET /api/menus) 응답을 이 모델로 바꿔서 화면에 쓴다.
/// 참고: 04_데이터구조_ERD menu 테이블, 05_API_명세서 §3.1~3.2
class MenuItem {
  /// 메뉴 고유번호
  final int id;

  /// 메뉴 이름 (예: LA갈비 바게트 샌드위치)
  final String name;

  /// 메뉴 설명
  final String description;

  /// 빵 종류 — 화면 카테고리 탭 용도 (바게트/치아바타/샤워도우)
  final String bread;

  /// 기본 가격(원)
  final int price;

  /// 사진이 아직 없어 임시로 쓰는 대표 이모지
  final String emoji;

  /// 대표(BEST) 메뉴 여부
  final bool isBest;

  /// 판매 상태 (판매중 / 품절)
  final String status;

  /// 평균 별점 (0이면 리뷰 없음)
  final double ratingAvg;

  /// 리뷰 개수
  final int reviewCount;

  /// 선택 가능한 옵션들 (없으면 빈 목록)
  final List<MenuOption> options;

  const MenuItem({
    required this.id,
    required this.name,
    required this.bread,
    required this.price,
    required this.emoji,
    this.description = '',
    this.isBest = false,
    this.status = '판매중',
    this.ratingAvg = 0,
    this.reviewCount = 0,
    this.options = const <MenuOption>[],
  });

  /// 품절 여부
  bool get soldOut => status == '품절';

  /// 서버 JSON → MenuItem
  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        description: (json['description'] as String?) ?? '',
        bread: (json['bread'] as String?) ?? '',
        price: (json['price'] as num).toInt(),
        emoji: (json['emoji'] as String?) ?? '🥪',
        isBest: (json['isBest'] as bool?) ?? false,
        status: (json['status'] as String?) ?? '판매중',
        ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        options: ((json['options'] as List<dynamic>?) ?? const <dynamic>[])
            .map((e) => MenuOption.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
