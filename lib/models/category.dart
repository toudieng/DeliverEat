import '../core/config/api_config.dart';

class FoodCategory {
  final String id;
  final String name;
  final String? emoji;
  final String? imageUrl;

  const FoodCategory({required this.id, required this.name, this.emoji, this.imageUrl});

  String get resolvedImageUrl => ApiConfig.resolveMediaUrl(imageUrl);

  factory FoodCategory.fromJson(Map<String, dynamic> json) => FoodCategory(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        emoji: json['emoji'] as String?,
        imageUrl: json['imageUrl'] as String?,
      );
}
