import 'package:flutter/material.dart';

import '../data/admin_api.dart';
import '../data/api_exception.dart';
import '../state/auth_store.dart';
import '../theme/app_colors.dart';

/// 관리자(사장님) 고객의 소리 답변 화면. (A6)
class AdminInquiriesPage extends StatefulWidget {
  const AdminInquiriesPage({super.key});

  @override
  State<AdminInquiriesPage> createState() => _AdminInquiriesPageState();
}

class _AdminInquiriesPageState extends State<AdminInquiriesPage> {
  final AdminApi _api = AdminApi();

  List<AdminInquiry> _items = const [];
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
      final items = await _api.fetchInquiries(token);
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

  Future<void> _reply(AdminInquiry item) async {
    final controller = TextEditingController(text: item.replyContent ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(item.content, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '답변',
                hintText: '손님에게 전할 답변을 적어주세요',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(sheetContext).pop(true),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('답변 등록'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final token = AuthStore.instance.token;
    if (token == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.replyInquiry(token, item.inquiryId, controller.text.trim());
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('답변을 등록했어요.')));
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
      appBar: AppBar(title: const Text('고객의 소리 (사장님)')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    }
    if (_items.isEmpty) return const Center(child: Text('문의가 없어요'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = _items[i];
          final answered = item.status == '답변완료';
          return ListTile(
            title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (item.replyContent != null && item.replyContent!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('↳ ${item.replyContent}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.primary, fontSize: 12.5)),
                  ),
              ],
            ),
            isThreeLine: item.replyContent != null,
            trailing: Chip(
              label: Text(item.status),
              backgroundColor: answered ? AppColors.bg : null,
              visualDensity: VisualDensity.compact,
            ),
            onTap: () => _reply(item),
          );
        },
      ),
    );
  }
}
