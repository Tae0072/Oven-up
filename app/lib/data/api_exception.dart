/// 서버가 실패 응답을 줄 때 던지는 예외. message에 사용자에게 보여줄 안내가 담긴다.
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}
