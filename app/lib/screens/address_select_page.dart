import 'package:flutter/material.dart';

import '../data/address_api.dart';
import '../data/address_search.dart';
import '../data/api_exception.dart';
import '../state/address_store.dart';
import '../state/auth_store.dart';
import '../theme/app_colors.dart';

/// 주소 선택 화면 (배민식).
/// 등록한 주소 목록에서 고르고, [새 주소 추가]를 누르면 주소 검색창이 뜬다.
class AddressSelectPage extends StatefulWidget {
  const AddressSelectPage({super.key});

  @override
  State<AddressSelectPage> createState() => _AddressSelectPageState();
}

class _AddressSelectPageState extends State<AddressSelectPage> {
  final AddressApi _api = AddressApi();

  List<AddressItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? get _token => AuthStore.instance.token;

  Future<void> _load() async {
    final token = _token;
    if (token == null) return;
    try {
      final list = await _api.fetchAddresses(token);
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '주소 목록을 불러오지 못했어요.';
        });
      }
    }
  }

  void _applyResult(List<AddressItem> list) {
    setState(() => _items = list);
    final selected = list.where((a) => a.selected).toList();
    AddressStore.instance
        .setLocal(selected.isEmpty ? '' : selected.first.address);
  }

  Future<void> _select(AddressItem item) async {
    final token = _token;
    if (token == null) return;
    try {
      _applyResult(await _api.selectAddress(token, item.id));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _snack('주소를 선택하지 못했어요.');
    }
  }

  Future<void> _add() async {
    final picked = await pickAddress(context);
    if (picked == null || picked.isEmpty || !mounted) return;
    // 상세주소(동/호수) 입력 (선택)
    final detailController = TextEditingController();
    final detail = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('상세주소'),
        content: TextField(
          controller: detailController,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: '동/호수 등 (없으면 비워두세요)', border: OutlineInputBorder()),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(detailController.text.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    final full = (detail == null || detail.isEmpty) ? picked : '$picked, $detail';
    final token = _token;
    if (token == null) return;
    try {
      _applyResult(await _api.addAddress(token, full));
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('주소를 추가하지 못했어요.');
    }
  }

  Future<void> _delete(AddressItem item) async {
    final token = _token;
    if (token == null) return;
    try {
      _applyResult(await _api.deleteAddress(token, item.id));
    } catch (_) {
      _snack('주소를 삭제하지 못했어요.');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('주소 선택')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 새 주소 추가
                OutlinedButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('새 주소 추가'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(_error!, style: TextStyle(color: Colors.red[700])),
                  ),
                if (_items.isEmpty && _error == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Center(
                      child: Text('등록된 주소가 없어요.\n새 주소를 추가해 주세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600])),
                    ),
                  ),
                ..._items.map(
                  (item) => Card(
                    elevation: 0,
                    color: item.selected ? AppColors.bg : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: item.selected ? AppColors.primary : const Color(0xFFE3E8E4)),
                    ),
                    child: ListTile(
                      onTap: () => _select(item),
                      leading: Icon(
                        item.selected ? Icons.check_circle : Icons.location_on_outlined,
                        color: item.selected ? AppColors.primary : Colors.grey,
                      ),
                      title: Text(item.address,
                          style: TextStyle(
                              fontWeight: item.selected ? FontWeight.bold : FontWeight.normal)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _delete(item),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
