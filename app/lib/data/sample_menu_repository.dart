import '../models/menu_item.dart';
import 'menu_repository.dart';
import 'sample_menus.dart';

/// 서버 없이 동작하는 가짜 저장소 (위젯 테스트·오프라인용).
/// 서버가 아직 없거나 테스트할 때 5VEN UP 샘플 메뉴 7종을 그대로 돌려준다.
class SampleMenuRepository implements MenuRepository {
  @override
  Future<List<MenuItem>> fetchMenus() async => sampleMenus;
}
