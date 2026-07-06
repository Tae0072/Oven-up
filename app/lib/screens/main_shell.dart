import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;

import '../data/menu_repository.dart';
import '../data/push_service.dart';
import '../state/address_store.dart';
import '../state/auth_store.dart';
import 'home_page.dart';
import 'menu_list_page.dart';
import 'my_page.dart';

/// 로그인 후 기본 화면. 하단 내비게이션으로 홈·메뉴·마이페이지를 오간다.
/// (02_화면_정의서 S2 하단 내비게이션)
class MainShell extends StatefulWidget {
  final MenuRepository repository;

  const MainShell({super.key, required this.repository});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    // 로그인 후 홈에 들어오면 이 기기의 푸시 토큰을 서버에 등록한다.
    // (Firebase 미설정/웹/테스트에서는 내부에서 조용히 건너뜀)
    PushService.registerToken(AuthStore.instance.token);
    // 상단 주소 표시용 — 내 주소 불러오기
    AddressStore.instance.load();
  }

  void _goToMenu() => setState(() => _index = 1);

  /// 뒤로가기 처리: 다른 탭이면 홈으로, 홈이면 2초 안에 한 번 더 눌러야 종료.
  void _handleBack() {
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('한 번 더 누르면 앱이 종료돼요'),
          duration: Duration(seconds: 2),
        ));
      return;
    }
    SystemNavigator.pop(); // 앱 종료
  }

  @override
  Widget build(BuildContext context) {
    // IndexedStack: 탭을 바꿔도 각 화면 상태(스크롤 등)를 유지한다.
    final pages = <Widget>[
      HomePage(onGoToMenu: _goToMenu),
      MenuListPage(repository: widget.repository),
      MyPage(repository: widget.repository),
    ];

    return PopScope(
      canPop: false, // 뒤로가기를 직접 처리 (홈 아니면 홈으로, 홈이면 두 번 눌러 종료)
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
          NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: '메뉴'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '마이페이지'),
        ],
      ),
      ),
    );
  }
}
