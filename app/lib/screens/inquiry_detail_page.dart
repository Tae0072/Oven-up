import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../data/inquiry_api.dart';
import '../models/inquiry.dart';
import '../state/auth_store.dart';
import '../utils/format.dart';

/// 고객의 소리 상세 화면 (05_API §7.3). 내 문의 + 사장님 답변.
class InquiryDetailPage extends StatefulWidget {
  final int inquiryId;

  const InquiryDetailPage({super.key, required this.inquiryId});

  @override
  State<InquiryDetailPage> createState() => _InquiryDetailPageState();
}

class _InquiryDetailPageState extends State<InquiryDetailPage> {
  final InquiryApi _api = InquiryApi();

  InquiryDetail? _detail;
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
      final detail = await _api.fetchDetail(token, widget.inquiryId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('문의 상세')),
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
    final detail = _detail!;
    final reply = detail.reply;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(detail.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Chip(
              label: Text(detail.status),
              backgroundColor: detail.status == '답변완료' ? Colors.green.shade100 : null,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        if (detail.createdAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(formatDateTime(detail.createdAt!), style: const TextStyle(color: Colors.grey)),
          ),
        const SizedBox(height: 16),
        Text(detail.content, style: const TextStyle(fontSize: 15, height: 1.5)),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        Text('사장님 답변', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 8),
        if (reply == null)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('아직 답변이 등록되지 않았어요.', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reply.content, style: const TextStyle(fontSize: 15, height: 1.5)),
                  if (reply.createdAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(formatDateTime(reply.createdAt!),
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
