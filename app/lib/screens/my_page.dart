import 'package:flutter/material.dart';

import '../data/api_menu_repository.dart';
import '../data/menu_repository.dart';
import '../state/auth_store.dart';
import 'group_order_page.dart';
import 'inquiry_list_page.dart';
import 'login_page.dart';
import 'order_history_page.dart';

/// S12. 마이페이지 — 내 정보 + 주문 내역·단체 주문·고객의 소리 + 로그아웃.
/// (02_화면_정의서 S12)
class MyPage extends StatelessWidget {
  /// 로그아웃 후 다시 로그인하면 홈으로 돌아오기 위해 저장소를 넘겨받는다.
  final MenuRepository? repository;

  const MyPage({super.key, this.repository});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('로그아웃')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    AuthStore.instance.logout();
    // 로그인 화면(게이트)으로 되돌아간다. 이전 화면들은 모두 제거.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LoginPage(repository: repository ?? ApiMenuRepository(), isGate: true),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: ListenableBuilder(
        listenable: AuthStore.instance,
        builder: (context, _) {
          final user = AuthStore.instance.user;
          final isAdmin = user?.role == 'ADMIN';
          return ListView(
            children: [
              // 내 정보 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 26, child: Icon(Icons.person)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name.isNotEmpty == true ? '${user!.name} 님' : '손님',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (isAdmin)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('관리자(사장님)', style: TextStyle(color: Color(0xFFB5651D))),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('주문 내역'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _push(context, const OrderHistoryPage()),
              ),
              ListTile(
                leading: const Icon(Icons.groups),
                title: const Text('단체 주문 문의'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _push(context, const GroupOrderPage()),
              ),
              ListTile(
                leading: const Icon(Icons.forum),
                title: const Text('고객의 소리'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _push(context, const InquiryListPage()),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red[700]),
                title: Text('로그아웃', style: TextStyle(color: Colors.red[700])),
                onTap: () => _logout(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
