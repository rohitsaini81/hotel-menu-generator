class MenuSummary {
  MenuSummary({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime? createdAt;

  String get createdAtLabel {
    if (createdAt == null) return 'Created at: —';
    return 'Created at: ${createdAt!.toLocal()}'.split('.').first;
  }

  factory MenuSummary.fromJson(Map<String, dynamic> json) {
    final hotel = (json['hotel'] as Map<String, dynamic>? ?? {});
    return MenuSummary(
      id: json['id'].toString(),
      name: (hotel['name'] ?? 'Untitled menu').toString(),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
    );
  }
}

class MenuData {
  MenuData({
    required this.hotel,
    required this.categories,
    required this.items,
    required this.labels,
    required this.categoryAliases,
  });

  final HotelData hotel;
  final List<CategoryData> categories;
  final List<MenuItemData> items;
  final Map<String, String> labels;
  final Map<String, List<String>> categoryAliases;

  factory MenuData.fromJson(Map<String, dynamic> json) {
    final categories = (json['categories'] as List)
        .map((entry) => CategoryData.fromJson(entry as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
    final items = (json['items'] as List)
        .map((entry) => MenuItemData.fromJson(entry as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
    return MenuData(
      hotel: HotelData.fromJson(json['hotel'] as Map<String, dynamic>),
      categories: categories,
      items: items,
      labels: (json['labels'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, value.toString())),
      categoryAliases:
          (json['categoryAliases'] as Map<String, dynamic>? ??
                  json['category_aliases'] as Map<String, dynamic>? ??
                  {})
              .map((key, value) => MapEntry(
                    key,
                    (value as List).map((entry) => entry.toString()).toList(),
                  )),
    );
  }

  String categoryLabel(String id) {
    return categories.firstWhere((cat) => cat.id == id).label;
  }
}

class HotelData {
  HotelData({
    required this.name,
    required this.tagline,
    required this.currency,
    required this.hours,
  });

  final String name;
  final String tagline;
  final String currency;
  final String hours;

  factory HotelData.fromJson(Map<String, dynamic> json) {
    return HotelData(
      name: json['name'] as String,
      tagline: json['tagline'] as String? ?? '',
      currency: json['currency'] as String? ?? 'USD',
      hours: json['hours'] as String? ?? '',
    );
  }
}

class CategoryData {
  CategoryData({required this.id, required this.label});

  final String id;
  final String label;

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label};
  }
}

class MenuItemData {
  MenuItemData({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.tags,
    required this.prep,
    required this.calories,
    required this.keywords,
  });

  final String id;
  final String name;
  final String category;
  final int price;
  final String description;
  final List<String> tags;
  final String prep;
  final int calories;
  final List<String> keywords;

  factory MenuItemData.fromJson(Map<String, dynamic> json) {
    return MenuItemData(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toInt(),
      description: json['description'] as String,
      tags: (json['tags'] as List).map((entry) => entry.toString()).toList(),
      prep: json['prep'] as String? ?? '',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      keywords: (json['keywords'] as List? ?? [])
          .map((entry) => entry.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'tags': tags,
      'prep': prep,
      'calories': calories,
      'keywords': keywords,
    };
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
