import 'package:flutter/material.dart';

import '../data/admin_api.dart';
import '../data/api_exception.dart';
import '../state/auth_store.dart';
import '../utils/format.dart';

/// A8. 관리자 쿠폰 관리 — 목록 + 발급.
class AdminCouponsPage extends StatefulWidget {
  const AdminCouponsPage({super.key});

  @override
  State<AdminCouponsPage> createState() => _AdminCouponsPageState();
}

class _AdminCouponsPageState extends State<AdminCouponsPage> {
  final AdminApi _api = AdminApi();

  List<AdminCoupon> _items = const <AdminCoupon>[];
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
      final items = await _api.fetchCoupons(token);
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

  Future<void> _openCreate() async {
    final created = await Navigator.of(context)
        .push<bool>(MaterialPageRoute<bool>(builder: (_) => const _CreateCouponPage()));
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('쿠폰 관리 (사장님)')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('쿠폰 발급'),
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
      return const Center(child: Text('발급된 쿠폰이 없어요.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final c = _items[i];
          return ListTile(
            title: Text('${c.code}  ·  ${c.discountText} 할인'),
            subtitle: Text('${c.name}   ·   ${formatPrice(c.minOrderAmount)} 이상'),
            trailing: Chip(
              label: Text(c.active ? '사용가능' : '중지'),
              visualDensity: VisualDensity.compact,
            ),
          );
        },
      ),
    );
  }
}

/// 쿠폰 발급 폼
class _CreateCouponPage extends StatefulWidget {
  const _CreateCouponPage();

  @override
  State<_CreateCouponPage> createState() => _CreateCouponPageState();
}

class _CreateCouponPageState extends State<_CreateCouponPage> {
  final AdminApi _api = AdminApi();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _value = TextEditingController();
  final TextEditingController _minOrder = TextEditingController(text: '0');

  String _type = 'AMOUNT';
  bool _submitting = false;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _value.dispose();
    _minOrder.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = AuthStore.instance.token;
    if (token == null) return;
    final value = int.tryParse(_value.text.trim()) ?? 0;
    if (_code.text.trim().isEmpty || value <= 0) {
      _snack('쿠폰 코드와 할인 값을 입력해 주세요');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _api.createCoupon(
        token,
        code: _code.text.trim(),
        name: _name.text.trim(),
        type: _type,
        value: value,
        minOrderAmount: int.tryParse(_minOrder.text.trim()) ?? 0,
      );
      if (!mounted) return;
      _snack('쿠폰이 발급됐어요');
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
    return Scaffold(
      appBar: AppBar(title: const Text('쿠폰 발급')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
                labelText: '쿠폰 코드 *', hintText: '예: WELCOME3000', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
                labelText: '쿠폰 이름', hintText: '예: 웰컴 3천원 할인', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'AMOUNT', label: Text('정액(원)')),
              ButtonSegment(value: 'PERCENT', label: Text('정률(%)')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _value,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                labelText: _type == 'PERCENT' ? '할인율(%) *' : '할인 금액(원) *',
                border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _minOrder,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: '최소 주문금액(원)', hintText: '예: 10000', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('발급'),
          ),
        ],
      ),
    );
  }
}
