import 'package:flutter/material.dart';

import 'screens/menu_list_page.dart';

void main() {
  runApp(const OvenUpApp());
}

/// 오븐업(5VEN UP) 앱의 시작점.
/// 지금은 첫 화면으로 "메뉴 목록"을 바로 보여준다.
/// (홈/장바구니/주문서 등은 로드맵 순서대로 이어서 붙인다.)
class OvenUpApp extends StatelessWidget {
  const OvenUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '오븐업 5VEN UP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB5651D)),
        useMaterial3: true,
      ),
      home: const MenuListPage(),
    );
  }
}
