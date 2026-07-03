// 메뉴 목록 + 상세 + 장바구니 + 주문서 화면 기본 동작 테스트.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oven_up_app/data/sample_menus.dart';
import 'package:oven_up_app/main.dart';
import 'package:oven_up_app/state/cart.dart';

void main() {
  setUp(() {
    // 테스트마다 장바구니를 비워 시작한다.
    Cart.instance.clear();
  });

  testWidgets('메뉴 목록이 보이고 담기 누르면 장바구니 수가 는다', (WidgetTester tester) async {
    await tester.pumpWidget(const OvenUpApp());

    expect(find.text('메뉴'), findsWidgets);
    expect(find.text('LA갈비 바게트 샌드위치'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.text('담기').first);
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('메뉴 카드를 누르면 상세 화면이 뜬다', (WidgetTester tester) async {
    await tester.pumpWidget(const OvenUpApp());

    await tester.tap(find.text('잠봉 루꼴라 샌드위치'));
    await tester.pumpAndSettle();

    expect(find.text('옵션 선택'), findsOneWidget);
    expect(find.text('치즈 추가'), findsOneWidget);
  });

  testWidgets('장바구니 화면에서 항목과 총액이 보인다', (WidgetTester tester) async {
    Cart.instance.add(sampleMenus.first);
    await tester.pumpWidget(const OvenUpApp());

    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await tester.pumpAndSettle();

    expect(find.text('장바구니'), findsOneWidget);
    expect(find.text('LA갈비 바게트 샌드위치'), findsOneWidget);
    expect(find.text('총액'), findsOneWidget);
    expect(find.text('주문하기'), findsOneWidget);
  });

  testWidgets('장바구니에서 주문하기 누르면 주문서가 뜬다', (WidgetTester tester) async {
    // 스낵바 간섭을 피하기 위해 장바구니에 직접 담고 시작.
    Cart.instance.add(sampleMenus.first);
    await tester.pumpWidget(const OvenUpApp());

    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('주문하기'));
    await tester.pumpAndSettle();

    expect(find.text('주문서'), findsOneWidget);
    expect(find.text('수령 방식'), findsOneWidget);
  });
}
