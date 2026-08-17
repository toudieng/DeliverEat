import '../core/config/api_config.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
  });

  String get resolvedAvatarUrl => ApiConfig.resolveMediaUrl(avatarUrl);

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        phone: json['phone'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );

  AppUser copyWith({String? name, String? phone, String? avatarUrl}) => AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}
