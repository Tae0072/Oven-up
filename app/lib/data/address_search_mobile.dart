import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// 모바일: 다음 우편번호 서비스를 웹뷰 전체 화면으로 띄운다.
Future<String?> pickAddress(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute<String>(builder: (_) => const _AddressSearchPage()),
  );
}

const String _html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>html, body, #box { margin:0; padding:0; width:100%; height:100%; }</style>
</head>
<body>
  <div id="box"></div>
  <script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
  <script>
    new daum.Postcode({
      oncomplete: function (data) {
        window.flutter_inappwebview.callHandler(
            'onAddress', data.roadAddress || data.jibunAddress || '');
      },
      width: '100%',
      height: '100%'
    }).embed(document.getElementById('box'));
  </script>
</body>
</html>
''';

class _AddressSearchPage extends StatelessWidget {
  const _AddressSearchPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('주소 검색')),
      body: InAppWebView(
        initialData: InAppWebViewInitialData(data: _html, baseUrl: WebUri('https://ovenup.local')),
        initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
        onWebViewCreated: (controller) {
          controller.addJavaScriptHandler(
            handlerName: 'onAddress',
            callback: (args) {
              final address = (args.isNotEmpty ? args.first : '') as String;
              Navigator.of(context).pop(address.isEmpty ? null : address);
            },
          );
        },
      ),
    );
  }
}
