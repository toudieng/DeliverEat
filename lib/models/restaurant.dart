import '../core/config/api_config.dart';
import 'menu_item.dart';

class Restaurant {
  final String id;
  final String name;
  final String? imageUrl;
  final double rating;
  final int deliveryTimeMinutes;
  final int deliveryFee;
  final bool isOpen;
  final String? category;
  final String? description;
  final String? address;
  final List<MenuItem> menu;

  const Restaurant({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.rating,
    required this.deliveryTimeMinutes,
    required this.deliveryFee,
    required this.isOpen,
    this.category,
    this.description,
    this.address,
    this.menu = const [],
  });

  String get resolvedImageUrl => ApiConfig.resolveMediaUrl(imageUrl);

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        imageUrl: (json['imageUrl'] ?? json['image']) as String?,
        rating: _asDouble(json['rating']),
        deliveryTimeMinutes: _asInt(json['deliveryTime'] ?? json['deliveryTimeMinutes']),
        deliveryFee: _asInt(json['deliveryFee']),
        isOpen: json['isOpen'] as bool? ?? true,
        category: json['category'] as String?,
        description: json['description'] as String?,
        address: json['address'] as String?,
        menu: _parseMenu(json),
      );

  static List<MenuItem> _parseMenu(Map<String, dynamic> json) {
    final raw = json['menu'];
    if (raw is List) {
      // Either a flat list of items, or a list of { section, items } groups.
      if (raw.isNotEmpty && raw.first is Map && (raw.first as Map).containsKey('items')) {
        final List<MenuItem> items = [];
        for (final group in raw) {
          final section = (group['section'] ?? group['title'] ?? 'Menu').toString();
          final groupItems = (group['items'] as List? ?? [])
              .map((e) => MenuItem.fromJson({...e as Map<String, dynamic>, 'section': section}))
              .toList();
          items.addAll(groupItems);
        }
        return items;
      }
      return raw.map((e) => MenuItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return const [];
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Restaurant copyWith({List<MenuItem>? menu}) => Restaurant(
        id: id,
        name: name,
        imageUrl: imageUrl,
        rating: rating,
        deliveryTimeMinutes: deliveryTimeMinutes,
        deliveryFee: deliveryFee,
        isOpen: isOpen,
        category: category,
        description: description,
        address: address,
        menu: menu ?? this.menu,
      );
}
