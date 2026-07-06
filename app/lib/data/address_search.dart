import 'package:flutter/widgets.dart';

import 'address_search_stub.dart'
    if (dart.library.js_interop) 'address_search_web.dart'
    if (dart.library.io) 'address_search_mobile.dart' as impl;

/// 주소 검색창(다음 우편번호 서비스)을 열고, 선택한 주소를 돌려준다.
/// 취소하면 null.
Future<String?> pickAddress(BuildContext context) => impl.pickAddress(context);
