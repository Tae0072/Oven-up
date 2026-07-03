import 'package:flutter/material.dart';

import 'data/api_menu_repository.dart';
import 'data/menu_repository.dart';
import 'screens/menu_list_page.dart';
import 'state/auth_store.dart';

Future<void> main() async {
  // 기기에 저장된 로그인 정보를 먼저 복원한 뒤 앱을 시작한다.
  WidgetsFlutterBinding.ensureInitialized();
  await AuthStore.instance.load();
  runApp(OvenUpApp());
}

/// 오븐업(5VEN UP) 앱의 시작점.
/// 첫 화면으로 "메뉴 목록"을 보여주며, 메뉴는 서버(ApiMenuRepository)에서 가져온다.
/// (테스트에서는 repository 에 가짜 저장소를 넣어 서버 없이 확인한다.)
class OvenUpApp extends StatelessWidget {
  final MenuRepository repository;

  OvenUpApp({super.key, MenuRepository? repository})
      : repository = repository ?? ApiMenuRepository();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '오븐업 5VEN UP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB5651D)),
        useMaterial3: true,
      ),
      home: MenuListPage(repository: repository),
    );
  }
}
