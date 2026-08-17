import '../core/config/api_config.dart';

class MenuItem {
  final String id;
  final String name;
  final String? description;
  final int price;
  final String? imageUrl;
  final String section;
  final bool available;

  const MenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.section,
    this.available = true,
  });

  String get resolvedImageUrl => ApiConfig.resolveMediaUrl(imageUrl);

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        description: json['description'] as String?,
        price: _asInt(json['price']),
        imageUrl: json['imageUrl'] as String?,
        section: (json['section'] ?? json['category'] ?? 'Menu').toString(),
        available: json['available'] as bool? ?? true,
      );

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// Menu items grouped by their [MenuItem.section] for display.
class MenuSection {
  final String title;
  final List<MenuItem> items;

  const MenuSection({required this.title, required this.items});

  static List<MenuSection> groupBySection(List<MenuItem> items) {
    final Map<String, List<MenuItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.section, () => []).add(item);
    }
    return grouped.entries.map((e) => MenuSection(title: e.key, items: e.value)).toList();
  }
}
