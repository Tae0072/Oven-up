import 'package:flutter/material.dart';

import '../data/admin_api.dart';
import '../data/api_exception.dart';
import '../models/group_order.dart';
import '../state/auth_store.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';

/// 관리자(사장님) 단체주문 관리 화면. (A7)
class AdminGroupOrdersPage extends StatefulWidget {
  const AdminGroupOrdersPage({super.key});

  @override
  State<AdminGroupOrdersPage> createState() => _AdminGroupOrdersPageState();
}

class _AdminGroupOrdersPageState extends State<AdminGroupOrdersPage> {
  final AdminApi _api = AdminApi();

  List<GroupOrder> _items = const [];
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
      final items = await _api.fetchGroupOrders(token);
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

  Future<void> _manage(GroupOrder g) async {
    String status = kGroupOrderStatuses.contains(g.status) ? g.status : kGroupOrderStatuses.first;
    final memoController = TextEditingController(text: g.adminMemo ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('단체주문 · ${g.headcount}명', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(g.detail, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Text('연락처: ${g.contact}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              const Text('상태', style: TextStyle(fontWeight: FontWeight.w600)),
              Wrap(
                spacing: 8,
                children: kGroupOrderStatuses
                    .map((s) => ChoiceChip(
                          label: Text(s),
                          selected: status == s,
                          onSelected: (_) => setSheet(() => status = s),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: memoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '사장님 메모/답변',
                  hintText: '손님에게 전할 안내를 적어주세요',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(true),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved != true) return;
    final token = AuthStore.instance.token;
    if (token == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.updateGroupOrder(token, g.groupOrderId, status: status, adminMemo: memoController.text.trim());
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('저장했어요.')));
      _load();
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('서버에 연결하지 못했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('단체주문 관리 (사장님)')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    }
    if (_items.isEmpty) return const Center(child: Text('단체주문 문의가 없어요'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final g = _items[i];
          return ListTile(
            title: Text('${g.headcount}명 · ${g.contact}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.detail, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (g.desiredAt != null)
                  Text('희망: ${formatDateTime(g.desiredAt!)}', style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
                if (g.adminMemo != null && g.adminMemo!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('↳ ${g.adminMemo}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.primary, fontSize: 12.5)),
                  ),
              ],
            ),
            isThreeLine: true,
            trailing: Chip(label: Text(g.status), visualDensity: VisualDensity.compact),
            onTap: () => _manage(g),
          );
        },
      ),
    );
  }
}
