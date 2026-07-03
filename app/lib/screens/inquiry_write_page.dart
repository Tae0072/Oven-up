import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../data/inquiry_api.dart';
import '../state/auth_store.dart';

/// 고객의 소리 작성 화면 (05_API §7.1). 제목·내용 필수, 사진 URL은 선택.
class InquiryWritePage extends StatefulWidget {
  const InquiryWritePage({super.key});

  @override
  State<InquiryWritePage> createState() => _InquiryWritePageState();
}

class _InquiryWritePageState extends State<InquiryWritePage> {
  final InquiryApi _api = InquiryApi();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _content = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = AuthStore.instance.token;
    if (token == null) {
      _snack('로그인이 필요해요');
      return;
    }
    final title = _title.text.trim();
    final content = _content.text.trim();
    if (title.isEmpty) {
      _snack('제목을 입력해 주세요');
      return;
    }
    if (content.isEmpty) {
      _snack('내용을 입력해 주세요');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _api.create(token: token, title: title, content: content);
      if (!mounted) return;
      _snack('문의가 등록됐어요. 답변이 등록되면 알려드릴게요.');
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
      appBar: AppBar(title: const Text('문의 작성')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: '제목 *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _content,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: '내용 *',
              hintText: '문의하거나 건의할 내용을 적어 주세요.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('등록'),
          ),
        ],
      ),
    );
  }
}
