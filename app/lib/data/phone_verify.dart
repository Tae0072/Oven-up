import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'firebase_setup.dart';

/// 휴대폰 번호 SMS 인증 (Firebase 전화 인증).
/// 흐름: [sendCode] → 문자로 6자리 코드 수신 → [confirmCode].
/// 인증용 Firebase 로그인은 확인 직후 바로 로그아웃한다(우리 서비스 로그인과 무관).
class PhoneVerify {
  ConfirmationResult? _webConfirm; // 웹 흐름
  String? _verificationId; // 모바일 흐름

  /// 010-1234-5678 → +821012345678 (국제 형식)
  static String toE164(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('82')) return '+$digits';
    if (digits.startsWith('0')) return '+82${digits.substring(1)}';
    return '+82$digits';
  }

  static String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return '전화번호 형식이 올바르지 않아요. (예: 010-1234-5678)';
      case 'too-many-requests':
        return '요청이 너무 많아요. 잠시 후 다시 시도해 주세요.';
      case 'quota-exceeded':
        return '오늘 보낼 수 있는 인증 문자를 모두 사용했어요. 내일 다시 시도해 주세요.';
      case 'invalid-verification-code':
        return '인증번호가 올바르지 않아요.';
      case 'session-expired':
      case 'code-expired':
        return '인증번호가 만료됐어요. 다시 받아 주세요.';
      default:
        return '인증에 실패했어요. (${e.code})';
    }
  }

  /// 인증 문자 발송.
  /// - onCodeSent: 문자가 발송되어 코드 입력을 기다리는 상태
  /// - onVerified: (안드로이드) 문자를 자동으로 읽어 인증까지 끝난 상태
  /// - onError: 실패 사유 메시지
  Future<void> sendCode(
    String rawPhone, {
    required VoidCallback onCodeSent,
    required VoidCallback onVerified,
    required void Function(String message) onError,
  }) async {
    if (!await ensureFirebase()) {
      onError('인증 서비스에 연결하지 못했어요.');
      return;
    }
    final phone = toE164(rawPhone);
    final auth = FirebaseAuth.instance;
    if (kIsWeb) {
      try {
        _webConfirm = await auth.signInWithPhoneNumber(phone);
        onCodeSent();
      } on FirebaseAuthException catch (e) {
        onError(_message(e));
      } catch (e) {
        onError('인증 문자를 보내지 못했어요.');
      }
      return;
    }
    await auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await auth.signInWithCredential(credential);
          await auth.signOut();
          onVerified();
        } catch (_) {/* 자동 인증 실패 시 수동 입력으로 진행 */}
      },
      verificationFailed: (FirebaseAuthException e) => onError(_message(e)),
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// 받은 6자리 코드 확인. 성공하면 true.
  Future<bool> confirmCode(String code, {required void Function(String message) onError}) async {
    final auth = FirebaseAuth.instance;
    try {
      if (kIsWeb) {
        if (_webConfirm == null) return false;
        await _webConfirm!.confirm(code);
      } else {
        if (_verificationId == null) return false;
        await auth.signInWithCredential(PhoneAuthProvider.credential(
            verificationId: _verificationId!, smsCode: code));
      }
      await auth.signOut();
      return true;
    } on FirebaseAuthException catch (e) {
      onError(_message(e));
      return false;
    } catch (_) {
      onError('인증에 실패했어요. 다시 시도해 주세요.');
      return false;
    }
  }
}
