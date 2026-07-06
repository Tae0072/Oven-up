import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../data/auth_api.dart';
import '../state/auth_store.dart';

/// S1-2. 회원가입 전용 페이지.
/// 아이디·비밀번호·전화번호·이메일·주소를 입력받아 가입하고, 성공하면 바로 로그인까지 마친다.
/// 성공 시 true를 돌려주며 pop 된다 (호출한 로그인 화면이 이어서 홈으로 이동).
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final AuthApi _authApi = AuthApi();

  final TextEditingController _loginId = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _passwordConfirm = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _address = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _loginId.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_loginId.text.trim().isEmpty) return '아이디를 입력해 주세요.';
    if (_password.text.length < 8) return '비밀번호는 8자 이상이어야 해요.';
    if (_password.text != _passwordConfirm.text) return '비밀번호가 서로 달라요.';
    if (_phone.text.trim().isEmpty) return '전화번호를 입력해 주세요.';
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) return '올바른 이메일을 입력해 주세요.';
    if (_address.text.trim().isEmpty) return '주소를 입력해 주세요.';
    return null;
  }

  Future<void> _submit() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authApi.signup(
        loginId: _loginId.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        phone: _phone.text.trim(),
        address: _address.text.trim(),
      );
      // 가입 성공 → 바로 로그인까지 마친다
      final result =
          await _authApi.login(email: _loginId.text.trim(), password: _password.text);
      if (!mounted) return;
      AuthStore.instance.setSession(result.token, result.user);
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = '서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('오븐업에 오신 걸 환영해요!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('아래 정보만 입력하면 바로 주문할 수 있어요.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 20),
          TextField(
            controller: _loginId,
            decoration: const InputDecoration(
                labelText: '아이디', hintText: '로그인에 사용할 아이디', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration:
                const InputDecoration(labelText: '비밀번호 (8자 이상)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordConfirm,
            obscureText: true,
            decoration:
                const InputDecoration(labelText: '비밀번호 확인', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: '전화번호', hintText: '010-0000-0000', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
                labelText: '이메일', hintText: 'example@email.com', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            decoration: const InputDecoration(
                labelText: '주소',
                hintText: '예: 명지에코펠리스 305호',
                border: OutlineInputBorder()),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.red[700])),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _submit,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('가입하고 시작하기'),
          ),
        ],
      ),
    );
  }
}
