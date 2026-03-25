int _asInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse('$value') ?? 0;
}

class MenuItemModel {
  const MenuItemModel({
    required this.id,
    required this.name,
    required this.priceCents,
    this.shortDescription,
    this.ingredients,
    this.imageUrl,
    this.categoryName,
    this.active = true,
  });

  final int id;
  final String name;
  final int priceCents;
  final String? shortDescription;
  final String? ingredients;
  final String? imageUrl;
  final String? categoryName;
  final bool active;

  factory MenuItemModel.fromMap(
    Map<String, dynamic> map, {
    String? categoryName,
  }) {
    return MenuItemModel(
      id: _asInt(map['id']),
      name: (map['name'] as String? ?? '').trim(),
      priceCents: _asInt(map['price_cents']),
      shortDescription: (map['short_desc'] as String?)?.trim(),
      ingredients: (map['ingredients'] as String?)?.trim(),
      imageUrl: (map['image_url'] as String?)?.trim(),
      categoryName: categoryName,
      active: map['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'price_cents': priceCents,
      'short_desc': shortDescription,
      'ingredients': ingredients,
      'image_url': imageUrl,
      'category_name': categoryName,
      'active': active,
    };
  }
}

class MenuCategory {
  const MenuCategory({
    required this.name,
    required this.items,
  });

  final String name;
  final List<MenuItemModel> items;

  factory MenuCategory.fromMap(Map<String, dynamic> map) {
    final String categoryName = (map['name'] as String? ?? '').trim();
    final List<dynamic> rawItems =
        List<dynamic>.from(map['items'] as List<dynamic>? ?? <dynamic>[]);

    return MenuCategory(
      name: categoryName,
      items: rawItems
          .map(
            (dynamic item) => MenuItemModel.fromMap(
              Map<String, dynamic>.from(item as Map),
              categoryName: categoryName,
            ),
          )
          .where((MenuItemModel item) => item.active)
          .toList(),
    );
  }
}
