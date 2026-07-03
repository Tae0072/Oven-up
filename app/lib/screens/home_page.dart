import 'package:flutter/material.dart';

import '../state/auth_store.dart';
import 'group_order_page.dart';
import 'inquiry_list_page.dart';

/// S2. 홈(홈페이지) — 앱을 열면 처음 보이는 대문 화면.
/// 브랜드 소개 + 배너 + 바로가기(메뉴 주문/예약/단체 주문/고객의 소리).
/// (02_화면_정의서 S2)
class HomePage extends StatelessWidget {
  /// "메뉴 주문" 바로가기를 누르면 하단 내비 '메뉴' 탭으로 이동하기 위한 콜백.
  final VoidCallback onGoToMenu;

  const HomePage({super.key, required this.onGoToMenu});

  void _openGroupOrder(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GroupOrderPage()));
  }

  void _openInquiry(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const InquiryListPage()));
  }

  void _reserveInfo(BuildContext context) {
    // 예약 주문은 주문서에서 '예약 주문 + 시간'을 선택하는 흐름이라, 메뉴로 안내한다.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('메뉴를 담고 주문서에서 예약 시간을 정할 수 있어요.'),
        duration: Duration(seconds: 2),
      ));
    onGoToMenu();
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFB5651D);
    return Scaffold(
      appBar: AppBar(title: const Text('오븐업 5VEN UP')),
      body: ListView(
        children: [
          // 대표 배너
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [brand, Color(0xFFD98A45)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListenableBuilder(
                  listenable: AuthStore.instance,
                  builder: (context, _) {
                    final name = AuthStore.instance.user?.name;
                    return Text(
                      name != null && name.isNotEmpty ? '$name 님, 반가워요!' : '반가워요!',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  '갓 구운 바게트 샌드위치,\n오븐업에서 주문하세요',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: onGoToMenu,
                  child: const Text('메뉴 보러 가기'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('무엇을 도와드릴까요?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          // 바로가기 버튼 4개
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _ShortcutCard(
                  icon: Icons.lunch_dining,
                  label: '메뉴 주문',
                  onTap: onGoToMenu,
                ),
                _ShortcutCard(
                  icon: Icons.schedule,
                  label: '예약 주문',
                  onTap: () => _reserveInfo(context),
                ),
                _ShortcutCard(
                  icon: Icons.groups,
                  label: '단체 주문',
                  onTap: () => _openGroupOrder(context),
                ),
                _ShortcutCard(
                  icon: Icons.forum,
                  label: '고객의 소리',
                  onTap: () => _openInquiry(context),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('매장 안내', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Text(
              '명지에코펠리스 건물 내에서는 직배송도 가능해요.\n'
              '(직배송은 샌드위치 2개 이상 주문 시)\n'
              '그 외 지역은 포장(픽업)으로 주문해 주세요.',
              style: TextStyle(color: Colors.grey, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// 홈 바로가기 카드
class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShortcutCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 34, color: const Color(0xFFB5651D)),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
