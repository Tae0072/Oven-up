import 'package:flutter/material.dart';

import '../data/admin_api.dart';
import '../data/api_exception.dart';
import '../models/menu_item.dart';
import '../state/auth_store.dart';
import '../utils/format.dart';

/// A3. 관리자 메뉴 관리 — 목록 + 품절 토글 + 수정/삭제 + 등록.
class AdminMenusPage extends StatefulWidget {
  const AdminMenusPage({super.key});

  @override
  State<AdminMenusPage> createState() => _AdminMenusPageState();
}

class _AdminMenusPageState extends State<AdminMenusPage> {
  final AdminApi _api = AdminApi();

  List<MenuItem> _items = const <MenuItem>[];
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
      final items = await _api.fetchMenus(token);
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

  Future<void> _toggleSoldOut(MenuItem m, bool soldOut) async {
    final token = AuthStore.instance.token;
    if (token == null) return;
    try {
      await _api.setSoldOut(token, m.id, soldOut);
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _delete(MenuItem m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dc) => AlertDialog(
        title: const Text('메뉴 삭제'),
        content: Text("'${m.name}'을(를) 삭제할까요?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(dc).pop(false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.of(dc).pop(true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    final token = AuthStore.instance.token;
    if (token == null) return;
    try {
      await _api.deleteMenu(token, m.id);
      await _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _openForm({MenuItem? edit}) async {
    final saved = await Navigator.of(context)
        .push<bool>(MaterialPageRoute<bool>(builder: (_) => _MenuFormPage(edit: edit)));
    if (saved == true) _load();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('메뉴 관리 (사장님)')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('메뉴 등록'),
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
      return const Center(child: Text('메뉴가 없어요.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final m = _items[i];
          return ListTile(
            leading: Text(m.emoji, style: const TextStyle(fontSize: 28)),
            title: Text('${m.name}${m.isBest ? '  ⭐' : ''}'),
            subtitle: Text('${m.bread}   ·   ${formatPrice(m.price)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 품절 스위치 (켜면 품절)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('품절', style: TextStyle(fontSize: 10)),
                    Switch(value: m.soldOut, onChanged: (v) => _toggleSoldOut(m, v)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _openForm(edit: m)),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(m)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 메뉴 등록/수정 폼
class _MenuFormPage extends StatefulWidget {
  final MenuItem? edit;

  const _MenuFormPage({this.edit});

  @override
  State<_MenuFormPage> createState() => _MenuFormPageState();
}

class _MenuFormPageState extends State<_MenuFormPage> {
  final AdminApi _api = AdminApi();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _bread;
  late final TextEditingController _emoji;
  bool _best = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _name = TextEditingController(text: e?.name ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _price = TextEditingController(text: e != null ? '${e.price}' : '');
    _bread = TextEditingController(text: e?.bread ?? '바게트');
    _emoji = TextEditingController(text: e?.emoji ?? '🥪');
    _best = e?.isBest ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _bread.dispose();
    _emoji.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = AuthStore.instance.token;
    if (token == null) return;
    final price = int.tryParse(_price.text.trim()) ?? 0;
    if (_name.text.trim().isEmpty || price <= 0) {
      _snack('메뉴 이름과 가격을 입력해 주세요');
      return;
    }
    setState(() => _submitting = true);
    try {
      if (widget.edit == null) {
        await _api.createMenu(token,
            name: _name.text.trim(),
            description: _desc.text.trim(),
            price: price,
            bread: _bread.text.trim(),
            emoji: _emoji.text.trim(),
            best: _best);
      } else {
        await _api.updateMenu(token, widget.edit!.id,
            name: _name.text.trim(),
            description: _desc.text.trim(),
            price: price,
            bread: _bread.text.trim(),
            emoji: _emoji.text.trim(),
            best: _best);
      }
      if (!mounted) return;
      _snack('저장됐어요');
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
    final isEdit = widget.edit != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '메뉴 수정' : '메뉴 등록')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: '메뉴 이름 *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '가격(원) *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bread,
            decoration: const InputDecoration(
                labelText: '빵 종류(카테고리 탭)', hintText: '예: 바게트', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emoji,
            decoration: const InputDecoration(
                labelText: '대표 이모지', hintText: '예: 🥪', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 2,
            decoration: const InputDecoration(labelText: '설명', border: OutlineInputBorder()),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('BEST 메뉴로 표시'),
            value: _best,
            onChanged: (v) => setState(() => _best = v),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(isEdit ? '수정' : '등록'),
          ),
        ],
      ),
    );
  }
}
