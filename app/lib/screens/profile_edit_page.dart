import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../data/auth_api.dart';
import '../state/auth_store.dart';
import '../theme/app_colors.dart';

/// S11. 내 정보 수정 — 프로필(이름·연락처) 수정 + 비밀번호 변경.
/// (02_화면_정의서 S11 / 05_API §2.5)
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final AuthApi _authApi = AuthApi();

  bool _loading = true;
  String? _error;
  String _email = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _savingProfile = false;

  final TextEditingController _currentPwController = TextEditingController();
  final TextEditingController _newPwController = TextEditingController();
  final TextEditingController _newPw2Controller = TextEditingController();
  bool _savingPw = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPwController.dispose();
    _newPwController.dispose();
    _newPw2Controller.dispose();
    super.dispose();
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
    try {
      final p = await _authApi.fetchProfile(token);
      if (!mounted) return;
      setState(() {
        _email = p.email;
        _nameController.text = p.name;
        _phoneController.text = p.phone;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '내 정보를 불러오지 못했어요.';
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final token = AuthStore.instance.token;
    if (token == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack('이름을 입력해 주세요.');
      return;
    }
    setState(() => _savingProfile = true);
    try {
      final updated = await _authApi.updateProfile(
        token: token,
        name: name,
        phone: _phoneController.text.trim(),
      );
      AuthStore.instance.updateName(updated.name);
      if (!mounted) return;
      _snack('저장했어요.');
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('서버에 연결하지 못했어요.');
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    final token = AuthStore.instance.token;
    if (token == null) return;
    final current = _currentPwController.text;
    final next = _newPwController.text;
    final next2 = _newPw2Controller.text;
    if (current.isEmpty || next.isEmpty) {
      _snack('현재/새 비밀번호를 입력해 주세요.');
      return;
    }
    if (next.length < 8) {
      _snack('새 비밀번호는 8자 이상이어야 해요.');
      return;
    }
    if (next != next2) {
      _snack('새 비밀번호 확인이 일치하지 않아요.');
      return;
    }
    setState(() => _savingPw = true);
    try {
      await _authApi.changePassword(token: token, currentPassword: current, newPassword: next);
      if (!mounted) return;
      _currentPwController.clear();
      _newPwController.clear();
      _newPw2Controller.clear();
      _snack('비밀번호를 변경했어요.');
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('서버에 연결하지 못했어요.');
    } finally {
      if (mounted) setState(() => _savingPw = false);
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
      appBar: AppBar(title: const Text('내 정보 수정')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('기본 정보'),
        const SizedBox(height: 8),
        TextField(
          enabled: false,
          controller: TextEditingController(text: _email),
          decoration: const InputDecoration(
            labelText: '이메일 (변경 불가)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '이름',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: '연락처',
            hintText: '010-0000-0000',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _savingProfile ? null : _saveProfile,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: _savingProfile
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('기본 정보 저장'),
        ),

        const Divider(height: 40),

        _sectionTitle('비밀번호 변경'),
        const SizedBox(height: 8),
        TextField(
          controller: _currentPwController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '현재 비밀번호',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _newPwController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '새 비밀번호 (8자 이상)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _newPw2Controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '새 비밀번호 확인',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _savingPw ? null : _changePassword,
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: _savingPw
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('비밀번호 변경'),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
      );
}
