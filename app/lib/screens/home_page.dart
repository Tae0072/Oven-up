import 'package:flutter/material.dart';

import '../data/notification_api.dart';
import '../state/auth_store.dart';
import '../theme/app_colors.dart';
import '../widgets/address_title.dart';
import 'group_order_page.dart';
import 'inquiry_list_page.dart';
import 'notifications_page.dart';
import 'reservation_page.dart';

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

  void _openReservation(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ReservationPage(onGoToMenu: onGoToMenu),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 좌측 상단: 로고 / 상단 중앙: 주소 선택
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => const Icon(Icons.bakery_dining),
          ),
        ),
        centerTitle: true,
        title: const AddressTitle(),
        actions: const [NotificationBell()],
      ),
      body: ListView(
        children: [
          // 대표 배너
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
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
                  onTap: () => _openReservation(context),
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
              Icon(icon, size: 34, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 홈 상단 알림 종 아이콘 + 안읽음 배지
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final NotificationApi _api = NotificationApi();
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final token = AuthStore.instance.token;
    if (token == null) return;
    final c = await _api.unreadCount(token);
    if (!mounted) return;
    setState(() => _unread = c);
  }

  Future<void> _open() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsPage()),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: '알림',
          onPressed: _open,
        ),
        if (_unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text(
                  _unread > 99 ? '99+' : '$_unread',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
