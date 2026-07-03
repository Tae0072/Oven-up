import '../models/menu_item.dart';

/// 메뉴 데이터를 가져오는 창구(인터페이스).
/// - 실제 서버: [ApiMenuRepository]
/// - 테스트/오프라인: [SampleMenuRepository]
/// 화면은 이 인터페이스만 알고, 어디서 오는지는 신경 쓰지 않는다(갈아끼우기 쉬움).
abstract class MenuRepository {
  Future<List<MenuItem>> fetchMenus();
}
