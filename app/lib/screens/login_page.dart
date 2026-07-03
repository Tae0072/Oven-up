import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../data/api_menu_repository.dart';
import '../data/auth_api.dart';
import '../data/menu_repository.dart';
import '../state/auth_store.dart';
import 'main_shell.dart';

/// S1. 로그인 / 회원가입 화면 (02_화면_정의서 S1)
/// - 이메일·비밀번호 로그인 / 회원가입.
/// - 카카오·네이버 소셜 로그인 (지금은 dev mock — 실제 SDK 연결은 이후 단계, 문서 가이드 참고).
///
/// [isGate]가 true면 "앱 진입 관문"으로 동작한다: 로그인 성공 시 홈(MainShell)으로 교체 이동.
/// false면 기존처럼 이전 화면으로 되돌아간다(pop).
class LoginPage extends StatefulWidget {
  final bool isGate;
  final MenuRepository? repository;

  const LoginPage({super.key, this.isGate = false, this.repository});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final AuthApi _authApi = AuthApi();

  bool _isSignup = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isSignup) {
        await _authApi.signup(
          email: _email.text.trim(),
          password: _password.text,
          name: _name.text.trim(),
          phone: _phone.text.trim(),
        );
      }
      final result = await _authApi.login(email: _email.text.trim(), password: _password.text);
      _applyLogin(result);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('서버에 연결하지 못했어요. 서버가 켜져 있는지 확인해 주세요.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// 소셜 로그인 (지금은 dev mock 토큰 사용)
  Future<void> _social(String provider, String devToken) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _authApi.socialLogin(provider: provider, accessToken: devToken);
      _applyLogin(result);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('서버에 연결하지 못했어요. 서버가 켜져 있는지 확인해 주세요.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _applyLogin(AuthResult result) {
    if (!mounted) return;
    AuthStore.instance.setSession(result.token, result.user);
    if (widget.isGate) {
      // 진입 관문: 로그인 성공 → 홈(MainShell)으로 교체 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MainShell(repository: widget.repository ?? ApiMenuRepository()),
        ),
      );
    } else {
      Navigator.of(context).pop(true);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSignup ? '회원가입' : '로그인')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          const Text('오븐업 5VEN UP',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: '이메일', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: '비밀번호 (8자 이상)', border: OutlineInputBorder()),
          ),
          if (_isSignup) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '이름', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: '전화번호', border: OutlineInputBorder()),
            ),
          ],
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
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_isSignup ? '회원가입하고 시작' : '로그인'),
          ),
          TextButton(
            onPressed: _loading
                ? null
                : () => setState(() {
                      _isSignup = !_isSignup;
                      _error = null;
                    }),
            child: Text(_isSignup ? '이미 계정이 있어요 · 로그인' : '계정이 없어요 · 회원가입'),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('또는', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading ? null : () => _social('kakao', '1001:카카오손님'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFEE500),
              foregroundColor: Colors.black87,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('카카오로 시작하기'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _loading ? null : () => _social('naver', '2001:네이버손님'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF03C75A),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('네이버로 시작하기'),
          ),
          const SizedBox(height: 8),
          Text(
            '※ 카카오·네이버는 현재 개발용 임시 로그인입니다. 실제 연결은 앱 등록 후 붙습니다.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
