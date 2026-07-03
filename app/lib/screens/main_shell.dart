import 'package:flutter/material.dart';

import '../data/menu_repository.dart';
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

  void _goToMenu() => setState(() => _index = 1);

  @override
  Widget build(BuildContext context) {
    // IndexedStack: 탭을 바꿔도 각 화면 상태(스크롤 등)를 유지한다.
    final pages = <Widget>[
      HomePage(onGoToMenu: _goToMenu),
      MenuListPage(repository: widget.repository),
      MyPage(repository: widget.repository),
    ];

    return Scaffold(
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
    );
  }
}
