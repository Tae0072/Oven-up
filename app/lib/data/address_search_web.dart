import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';

/// index.html에 정의된 다음 우편번호 열기 함수.
@JS('openDaumPostcode')
external void _openDaumPostcode(JSFunction callback);

/// 웹: 다음 우편번호 팝업을 열고 선택한 주소를 받는다.
Future<String?> pickAddress(BuildContext context) {
  final completer = Completer<String?>();
  void onComplete(JSString address) {
    if (!completer.isCompleted) completer.complete(address.toDart);
  }

  try {
    _openDaumPostcode(onComplete.toJS);
  } catch (_) {
    return Future.value(null);
  }
  return completer.future;
}
