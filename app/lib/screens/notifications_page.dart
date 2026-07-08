import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../data/notification_api.dart';
import '../models/app_notification.dart';
import '../state/auth_store.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';

/// 알림 목록 화면 (05_API §9). 주문 상태 변경·결제 등 알림을 보고 읽음 처리.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationApi _api = NotificationApi();

  List<AppNotification> _items = const <AppNotification>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = AuthStore.instance.token;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = '로그인이 필요해요';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.fetchList(token);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '서버에 연결하지 못했어요.';
        _loading = false;
      });
    }
  }

  Future<void> _readOne(AppNotification n) async {
    if (n.read) return;
    final token = AuthStore.instance.token;
    if (token == null) return;
    try {
      await _api.markRead(token, n.notificationId);
      await _load();
    } catch (_) {/* 무시 */}
  }

  Future<void> _readAll() async {
    final token = AuthStore.instance.token;
    if (token == null) return;
    await _api.markAllRead(token);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((n) => !n.read);
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          if (hasUnread)
            TextButton(onPressed: _readAll, child: const Text('모두 읽음')),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    }
    if (_items.isEmpty) {
      return const Center(child: Text('알림이 없어요.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final n = _items[i];
          return ListTile(
            leading: Icon(
              n.type == 'ORDER_PAID' ? Icons.payments : Icons.notifications,
              color: n.read ? Colors.grey : AppColors.primary,
            ),
            title: Text(n.title,
                style: TextStyle(fontWeight: n.read ? FontWeight.normal : FontWeight.bold)),
            subtitle: Text(
              '${n.body}${n.createdAt != null ? '\n${formatDateTime(n.createdAt!)}' : ''}',
            ),
            isThreeLine: true,
            trailing: n.read
                ? null
                : Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
            onTap: () => _readOne(n),
          );
        },
      ),
    );
  }
}
