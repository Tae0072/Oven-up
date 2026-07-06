import 'package:flutter/material.dart';

import '../data/address_search.dart';
import '../data/api_exception.dart';
import '../data/auth_api.dart';
import '../data/phone_verify.dart';
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
  final TextEditingController _smsCode = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _addressDetail = TextEditingController();

  final PhoneVerify _phoneVerify = PhoneVerify();
  bool _codeSent = false; // 인증 문자를 보낸 상태
  bool _phoneVerified = false; // 인증 완료
  bool _phoneBusy = false; // 발송/확인 진행 중

  bool _loading = false;
  String? _error;

  /// 인증 문자 발송 (재전송 포함)
  Future<void> _sendSmsCode() async {
    final phone = _phone.text.trim();
    if (phone.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
      setState(() => _error = '휴대폰 번호를 정확히 입력해 주세요.');
      return;
    }
    setState(() {
      _phoneBusy = true;
      _error = null;
    });
    await _phoneVerify.sendCode(
      phone,
      onCodeSent: () {
        if (mounted) {
          setState(() {
            _phoneBusy = false;
            _codeSent = true;
          });
        }
      },
      onVerified: () {
        // 안드로이드가 문자를 자동으로 읽은 경우
        if (mounted) {
          setState(() {
            _phoneBusy = false;
            _codeSent = false;
            _phoneVerified = true;
          });
        }
      },
      onError: (msg) {
        if (mounted) {
          setState(() {
            _phoneBusy = false;
            _error = msg;
          });
        }
      },
    );
  }

  /// 입력한 인증번호 확인
  Future<void> _confirmSmsCode() async {
    final code = _smsCode.text.trim();
    if (code.length < 6) {
      setState(() => _error = '문자로 받은 6자리 인증번호를 입력해 주세요.');
      return;
    }
    setState(() {
      _phoneBusy = true;
      _error = null;
    });
    final ok = await _phoneVerify.confirmCode(code, onError: (msg) {
      if (mounted) setState(() => _error = msg);
    });
    if (!mounted) return;
    setState(() {
      _phoneBusy = false;
      if (ok) {
        _phoneVerified = true;
        _codeSent = false;
      }
    });
  }

  /// 주소 검색창 열기
  Future<void> _searchAddress() async {
    final picked = await pickAddress(context);
    if (picked != null && picked.isNotEmpty && mounted) {
      setState(() => _address.text = picked);
    }
  }

  @override
  void dispose() {
    _loginId.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    _phone.dispose();
    _smsCode.dispose();
    _email.dispose();
    _address.dispose();
    _addressDetail.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_loginId.text.trim().isEmpty) return '아이디를 입력해 주세요.';
    if (_password.text.length < 8) return '비밀번호는 8자 이상이어야 해요.';
    if (_password.text != _passwordConfirm.text) return '비밀번호가 서로 달라요.';
    if (_phone.text.trim().isEmpty) return '전화번호를 입력해 주세요.';
    if (!_phoneVerified) return '휴대폰 번호 인증을 완료해 주세요.';
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) return '올바른 이메일을 입력해 주세요.';
    if (_address.text.trim().isEmpty) return '주소 검색으로 주소를 선택해 주세요.';
    return null;
  }

  String get _fullAddress {
    final detail = _addressDetail.text.trim();
    return detail.isEmpty ? _address.text.trim() : '${_address.text.trim()}, $detail';
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
        address: _fullAddress,
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
          // ── 휴대폰 번호 + 인증 ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  enabled: !_phoneVerified,
                  onChanged: (_) {
                    if (_codeSent || _phoneVerified) {
                      setState(() {
                        _codeSent = false;
                        _phoneVerified = false;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: '휴대폰 번호',
                    hintText: '010-0000-0000',
                    border: const OutlineInputBorder(),
                    suffixIcon: _phoneVerified
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 56,
                child: FilledButton.tonal(
                  onPressed: (_phoneBusy || _phoneVerified) ? null : _sendSmsCode,
                  child: Text(_phoneVerified
                      ? '인증완료'
                      : (_codeSent ? '재전송' : '인증번호 받기')),
                ),
              ),
            ],
          ),
          if (_codeSent && !_phoneVerified) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _smsCode,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                        labelText: '인증번호 6자리',
                        counterText: '',
                        border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: FilledButton.tonal(
                    onPressed: _phoneBusy ? null : _confirmSmsCode,
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('문자로 받은 인증번호를 입력해 주세요.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
                labelText: '이메일', hintText: 'example@email.com', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          // ── 주소: 검색창으로 선택 ──
          TextField(
            controller: _address,
            readOnly: true,
            onTap: _searchAddress,
            decoration: const InputDecoration(
              labelText: '주소',
              hintText: '눌러서 주소 검색',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressDetail,
            decoration: const InputDecoration(
                labelText: '상세주소 (동/호수 등)',
                hintText: '예: 305호',
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
