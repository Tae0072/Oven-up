// 메뉴 목록 화면 기본 동작 테스트.
// 화면이 뜨고, 첫 메뉴가 보이고, [담기]를 누르면 장바구니 배지가 생기는지 확인한다.

import 'package:flutter_test/flutter_test.dart';

import 'package:oven_up_app/main.dart';

void main() {
  testWidgets('메뉴 목록이 보이고 담기 누르면 장바구니 수가 는다', (WidgetTester tester) async {
    await tester.pumpWidget(const OvenUpApp());

    // 화면 제목과 첫 메뉴가 보인다
    expect(find.text('메뉴'), findsWidgets);
    expect(find.text('LA갈비 바게트 샌드위치'), findsOneWidget);

    // 처음엔 장바구니 배지(숫자 1)가 없다
    expect(find.text('1'), findsNothing);

    // 첫 번째 [담기] 버튼을 누른다
    await tester.tap(find.text('담기').first);
    await tester.pump();

    // 장바구니 배지에 1이 생긴다
    expect(find.text('1'), findsOneWidget);
  });
}
