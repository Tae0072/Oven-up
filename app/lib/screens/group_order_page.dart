import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../data/group_order_api.dart';
import '../models/group_order.dart';
import '../state/auth_store.dart';
import '../utils/format.dart';

/// 단체 주문 문의 화면 (03_기능 §7 / 05_API §6).
/// 내 단체주문 문의 목록 + 새 문의 작성(우측 하단 버튼). 협의형이라 결제는 없다.
class GroupOrderPage extends StatefulWidget {
  const GroupOrderPage({super.key});

  @override
  State<GroupOrderPage> createState() => _GroupOrderPageState();
}

class _GroupOrderPageState extends State<GroupOrderPage> {
  final GroupOrderApi _api = GroupOrderApi();

  List<GroupOrder> _items = const <GroupOrder>[];
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
      final items = await _api.fetchMine(token);
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

  Future<void> _openForm() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const GroupOrderFormPage()),
    );
    if (created == true) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('단체 주문 문의')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('문의하기'),
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
      return const Center(child: Text('아직 단체주문 문의가 없어요.\n오른쪽 아래 버튼으로 문의해 보세요.', textAlign: TextAlign.center));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => _GroupOrderTile(item: _items[index]),
      ),
    );
  }
}

class _GroupOrderTile extends StatelessWidget {
  final GroupOrder item;

  const _GroupOrderTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      '인원/수량: ${item.headcount}',
      if (item.desiredAt != null) '희망: ${formatDateTime(item.desiredAt!)}',
      if (item.detail.isNotEmpty) item.detail,
      if (item.adminMemo != null && item.adminMemo!.isNotEmpty) '사장님: ${item.adminMemo!}',
    ];
    return ListTile(
      isThreeLine: true,
      title: Row(
        children: [
          Expanded(child: Text('단체주문 #${item.groupOrderId}')),
          Chip(label: Text(item.status), visualDensity: VisualDensity.compact),
        ],
      ),
      subtitle: Text(lines.join('\n')),
    );
  }
}

/// 단체 주문 문의 작성 폼
class GroupOrderFormPage extends StatefulWidget {
  const GroupOrderFormPage({super.key});

  @override
  State<GroupOrderFormPage> createState() => _GroupOrderFormPageState();
}

class _GroupOrderFormPageState extends State<GroupOrderFormPage> {
  final GroupOrderApi _api = GroupOrderApi();
  final TextEditingController _headcount = TextEditingController();
  final TextEditingController _detail = TextEditingController();
  final TextEditingController _contact = TextEditingController();

  DateTime? _desiredAt;
  bool _submitting = false;

  @override
  void dispose() {
    _headcount.dispose();
    _detail.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _pickDesiredAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (!mounted) return;
    setState(() {
      _desiredAt = DateTime(date.year, date.month, date.day, time?.hour ?? 12, time?.minute ?? 0);
    });
  }

  String? _isoDesiredAt() {
    final dt = _desiredAt;
    if (dt == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}T${two(dt.hour)}:${two(dt.minute)}:00';
  }

  Future<void> _submit() async {
    final token = AuthStore.instance.token;
    if (token == null) {
      _snack('로그인이 필요해요');
      return;
    }
    final headcount = int.tryParse(_headcount.text.trim());
    if (headcount == null || headcount <= 0) {
      _snack('인원/수량을 숫자로 입력해 주세요');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _api.create(
        token: token,
        headcount: headcount,
        desiredAtIso: _isoDesiredAt(),
        detail: _detail.text.trim(),
        contact: _contact.text.trim(),
      );
      if (!mounted) return;
      _snack('문의가 접수됐어요. 사장님이 확인 후 연락드릴게요.');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack('서버에 연결하지 못했어요.');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final desiredLabel = _desiredAt == null ? '희망 일시 선택 (선택)' : formatDateTime(_desiredAt!);
    return Scaffold(
      appBar: AppBar(title: const Text('단체 주문 문의하기')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('단체 주문은 협의형이에요. 아래 내용을 남겨 주시면 사장님이 확인 후 연락드립니다.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(
            controller: _headcount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '인원/수량 *',
              hintText: '예: 20',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDesiredAt,
            icon: const Icon(Icons.event),
            label: Align(alignment: Alignment.centerLeft, child: Text(desiredLabel)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _detail,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '요청사항',
              hintText: '예: 회사 워크샵 점심용 샌드위치 20개',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contact,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: '연락처',
              hintText: '예: 010-1234-5678',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('문의 접수'),
          ),
        ],
      ),
    );
  }
}
