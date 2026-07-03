import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../data/inquiry_api.dart';
import '../models/inquiry.dart';
import '../state/auth_store.dart';
import '../utils/format.dart';
import 'inquiry_detail_page.dart';
import 'inquiry_write_page.dart';

/// 고객의 소리 목록 화면 (03_기능 §8 / 05_API §7). 본인 글만.
class InquiryListPage extends StatefulWidget {
  const InquiryListPage({super.key});

  @override
  State<InquiryListPage> createState() => _InquiryListPageState();
}

class _InquiryListPageState extends State<InquiryListPage> {
  final InquiryApi _api = InquiryApi();

  List<InquirySummary> _items = const <InquirySummary>[];
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

  Future<void> _openWrite() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const InquiryWritePage()),
    );
    if (created == true) {
      _load();
    }
  }

  void _openDetail(int inquiryId) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => InquiryDetailPage(inquiryId: inquiryId)))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('고객의 소리')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openWrite,
        icon: const Icon(Icons.edit),
        label: const Text('문의 작성'),
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
      return const Center(child: Text('아직 작성한 문의가 없어요.\n오른쪽 아래 버튼으로 문의를 남겨 보세요.', textAlign: TextAlign.center));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _items[index];
          final answered = item.status == '답변완료';
          return ListTile(
            title: Text(item.title),
            subtitle: item.createdAt != null ? Text(formatDateTime(item.createdAt!)) : null,
            trailing: Chip(
              label: Text(item.status),
              backgroundColor: answered ? Colors.green.shade100 : null,
              visualDensity: VisualDensity.compact,
            ),
            onTap: () => _openDetail(item.inquiryId),
          );
        },
      ),
    );
  }
}
