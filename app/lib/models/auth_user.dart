/// 로그인한 회원 정보(요약). 05_API §2.2 user
class AuthUser {
  final int id;
  final String name;
  final String role;

  const AuthUser({required this.id, required this.name, required this.role});

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: (json['id'] as num).toInt(),
        name: (json['name'] as String?) ?? '',
        role: (json['role'] as String?) ?? 'USER',
      );
}
