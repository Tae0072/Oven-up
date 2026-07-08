import 'package:flutter/material.dart';

import '../data/address_search.dart';
import '../data/api_exception.dart';
import '../data/auth_api.dart';
import '../models/auth_user.dart';
import '../state/auth_store.dart';

/// S1-3. 소셜 첫 로그인 온보딩.
/// 1단계: 닉네임 설정 → 2단계: 주소 설정. 끝나면 pop(true).
/// (다음 로그인에도 미설정 상태면 서버가 needsProfile=true 로 알려줘 다시 이 화면이 뜬다)
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final AuthApi _authApi = AuthApi();
  final TextEditingController _nickname = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _addressDetail = TextEditingController();

  /// 주소 검색창 열기
  Future<void> _searchAddress() async {
    final picked = await pickAddress(context);
    if (picked != null && picked.isNotEmpty && mounted) {
      setState(() => _address.text = picked);
    }
  }

  int _step = 0; // 0=닉네임, 1=주소
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nickname.dispose();
    _address.dispose();
    _addressDetail.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    final nickname = _nickname.text.trim();
    if (nickname.isEmpty) {
      setState(() => _error = '닉네임을 입력해 주세요.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authApi.updateProfile(token: AuthStore.instance.token!, nickname: nickname);
      // 홈 인사말 등에 바로 반영되도록 로그인 세션의 이름도 갱신
      final old = AuthStore.instance.user;
      if (old != null) {
        AuthStore.instance.setSession(AuthStore.instance.token!,
            AuthUser(id: old.id, name: nickname, role: old.role));
      }
      if (mounted) setState(() => _step = 1);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = '저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveAddress() async {
    final base = _address.text.trim();
    if (base.isEmpty) {
      setState(() => _error = '주소 검색으로 주소를 선택해 주세요.');
      return;
    }
    final detail = _addressDetail.text.trim();
    final address = detail.isEmpty ? base : '$base, $detail';
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authApi.updateProfile(token: AuthStore.instance.token!, address: address);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = '저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNicknameStep = _step == 0;
    return PopScope(
      canPop: false, // 온보딩 중 뒤로가기 방지 (닉네임→주소까지 마쳐야 함)
      child: Scaffold(
        appBar: AppBar(
          title: Text(isNicknameStep ? '닉네임 설정 (1/2)' : '주소 설정 (2/2)'),
          automaticallyImplyLeading: false,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Text(
              isNicknameStep ? '오븐업에서 사용할\n닉네임을 정해 주세요' : '기본 주소를\n입력해 주세요',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
            ),
            const SizedBox(height: 8),
            Text(
              isNicknameStep
                  ? '주문 화면과 인사말에 이 닉네임이 표시돼요.'
                  : '배달 주문 때 기본 주소로 사용돼요. 나중에 마이페이지에서 바꿀 수 있어요.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 24),
            if (isNicknameStep)
              TextField(
                controller: _nickname,
                autofocus: true,
                maxLength: 20,
                decoration: const InputDecoration(
                    labelText: '닉네임', hintText: '예: 빵순이', border: OutlineInputBorder()),
              )
            else ...[
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
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Colors.red[700])),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : (isNicknameStep ? _saveNickname : _saveAddress),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isNicknameStep ? '다음' : '완료'),
            ),
          ],
        ),
      ),
    );
  }
}
