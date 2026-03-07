import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1B3A2A),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Aurora Bay Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF2F0EA),
        textTheme: GoogleFonts.spaceGroteskTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF2F0EA),
          elevation: 0,
          titleTextStyle: GoogleFonts.playfairDisplay(
            color: const Color(0xFF161512),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF161512)),
        ),
      ),
      home: const AdminHome(),
    );
  }
}

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  MenuData? data;
  String query = '';
  String categoryFilter = 'all';
  String lastEdit = 'Just now';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final raw = await rootBundle.loadString('data/menu.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    setState(() {
      data = MenuData.fromJson(decoded);
      categoryFilter = 'all';
      query = '';
      lastEdit = 'Just now';
    });
  }

  void _updateLastEdit() {
    final now = TimeOfDay.now();
    setState(() {
      lastEdit = now.format(context);
    });
  }

  void _openEditor({MenuItemData? item}) {
    if (data == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return MenuItemEditor(
          categories: data!.categories,
          labels: data!.labels,
          initial: item,
          onDelete: item == null
              ? null
              : () {
                  setState(() {
                    data!.items.removeWhere((entry) => entry.id == item.id);
                  });
                  _updateLastEdit();
                  Navigator.of(context).pop();
                },
          onSave: (payload) {
            setState(() {
              final index = data!.items.indexWhere((entry) => entry.id == payload.id);
              if (index >= 0) {
                data!.items[index] = payload;
              } else {
                data!.items.insert(0, payload);
              }
            });
            _updateLastEdit();
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  List<MenuItemData> _filteredItems() {
    if (data == null) return [];
    final normalized = query.trim().toLowerCase();
    return data!.items.where((item) {
      final matchesCategory =
          categoryFilter == 'all' || item.category == categoryFilter;
      if (!matchesCategory) return false;
      if (normalized.isEmpty) return true;
      final categoryLabel = data!.categoryLabel(item.category).toLowerCase();
      final categoryAliases =
          data!.categoryAliases[item.category]?.join(' ').toLowerCase() ?? '';
      final tagLabels = item.tags
          .map((tag) => data!.labels[tag] ?? tag)
          .join(' ')
          .toLowerCase();
      final keywords = item.keywords.join(' ').toLowerCase();
      final haystack = [
        item.name.toLowerCase(),
        item.description.toLowerCase(),
        categoryLabel,
        categoryAliases,
        tagLabels,
        keywords,
      ].join(' ');
      return haystack.contains(normalized);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final items = _filteredItems();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFC4532D),
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: _HeaderCard(
                  hotelName: data!.hotel.name,
                  hotelHours: data!.hotel.hours,
                  totalItems: data!.items.length,
                  totalCategories: data!.categories.length,
                  lastEdit: lastEdit,
                  onSync: _loadData,
                  onQueryChanged: (value) {
                    setState(() => query = value);
                  },
                  categoryFilter: categoryFilter,
                  categories: data!.categories,
                  onCategoryChanged: (value) {
                    setState(() => categoryFilter = value);
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Items',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openEditor(),
                      child: const Text('New item'),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ItemCard(
                        item: item,
                        label: data!.categoryLabel(item.category),
                        labels: data!.labels,
                        currency: data!.hotel.currency,
                        onEdit: () => _openEditor(item: item),
                      ),
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.hotelName,
    required this.hotelHours,
    required this.totalItems,
    required this.totalCategories,
    required this.lastEdit,
    required this.onSync,
    required this.onQueryChanged,
    required this.categoryFilter,
    required this.categories,
    required this.onCategoryChanged,
  });

  final String hotelName;
  final String hotelHours;
  final int totalItems;
  final int totalCategories;
  final String lastEdit;
  final VoidCallback onSync;
  final ValueChanged<String> onQueryChanged;
  final String categoryFilter;
  final List<CategoryData> categories;
  final ValueChanged<String> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hotel Admin',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2.4,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hotelName,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hotelHours,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7E5DD),
                  foregroundColor: const Color(0xFFC4532D),
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                onPressed: onSync,
                child: const Text('Sync'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatCard(value: totalItems.toString(), label: 'Menu items'),
              const SizedBox(width: 10),
              _StatCard(value: totalCategories.toString(), label: 'Categories'),
              const SizedBox(width: 10),
              _StatCard(value: lastEdit, label: 'Last edit'),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Search items, tags, categories',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF8F5EF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: categoryFilter,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('All categories'),
                  ),
                  ...categories.map(
                    (category) => DropdownMenuItem(
                      value: category.id,
                      child: Text(category.label),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) onCategoryChanged(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5EF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.label,
    required this.labels,
    required this.currency,
    required this.onEdit,
  });

  final MenuItemData item;
  final String label;
  final Map<String, String> labels;
  final String currency;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1B3A2A),
              ),
              child: const Text('Edit'),
            ),
          ),
          Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: item.tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7E5DD),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      labels[tag] ?? tag,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC4532D),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                formatPrice(item.price, currency),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B3A2A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MenuItemEditor extends StatefulWidget {
  const MenuItemEditor({
    super.key,
    required this.categories,
    required this.labels,
    required this.initial,
    required this.onSave,
    required this.onDelete,
  });

  final List<CategoryData> categories;
  final Map<String, String> labels;
  final MenuItemData? initial;
  final ValueChanged<MenuItemData> onSave;
  final VoidCallback? onDelete;

  @override
  State<MenuItemEditor> createState() => _MenuItemEditorState();
}

class _MenuItemEditorState extends State<MenuItemEditor> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController priceController;
  late final TextEditingController descriptionController;
  late final TextEditingController tagsController;
  late final TextEditingController prepController;
  late final TextEditingController caloriesController;
  late final TextEditingController keywordsController;
  String selectedCategory = '';

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    nameController = TextEditingController(text: initial?.name ?? '');
    priceController =
        TextEditingController(text: initial?.price.toString() ?? '');
    descriptionController =
        TextEditingController(text: initial?.description ?? '');
    tagsController = TextEditingController(text: initial?.tags.join(', ') ?? '');
    prepController = TextEditingController(text: initial?.prep ?? '');
    caloriesController =
        TextEditingController(text: initial?.calories.toString() ?? '');
    keywordsController =
        TextEditingController(text: initial?.keywords.join(', ') ?? '');
    selectedCategory = initial?.category ?? widget.categories.first.id;
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    tagsController.dispose();
    prepController.dispose();
    caloriesController.dispose();
    keywordsController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final name = nameController.text.trim();
    final payload = MenuItemData(
      id: widget.initial?.id ?? slugify(name),
      name: name,
      category: selectedCategory,
      price: int.tryParse(priceController.text.trim()) ?? 0,
      description: descriptionController.text.trim(),
      tags: splitList(tagsController.text),
      prep: prepController.text.trim(),
      calories: int.tryParse(caloriesController.text.trim()) ?? 0,
      keywords: splitList(keywordsController.text),
    );
    widget.onSave(payload);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initial == null ? 'Add item' : 'Edit item',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _Field(
                    label: 'Name',
                    controller: nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  _DropdownField(
                    label: 'Category',
                    value: selectedCategory,
                    items: widget.categories,
                    onChanged: (value) =>
                        setState(() => selectedCategory = value),
                  ),
                  _Field(
                    label: 'Price',
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price is required';
                      }
                      return null;
                    },
                  ),
                  _Field(
                    label: 'Description',
                    controller: descriptionController,
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                  _Field(
                    label: 'Tags (comma-separated)',
                    controller: tagsController,
                  ),
                  _Field(
                    label: 'Prep time',
                    controller: prepController,
                  ),
                  _Field(
                    label: 'Calories',
                    controller: caloriesController,
                    keyboardType: TextInputType.number,
                  ),
                  _Field(
                    label: 'Keywords (comma-separated)',
                    controller: keywordsController,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (widget.onDelete != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onDelete,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFC4532D),
                              side: const BorderSide(color: Color(0xFFC4532D)),
                            ),
                            child: const Text('Delete'),
                          ),
                        ),
                      if (widget.onDelete != null) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B3A2A),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save item'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8F5EF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<CategoryData> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8F5EF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            items: items
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(item.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ),
      ),
    );
  }
}

String formatPrice(int value, String currency) {
  const symbols = {
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
  };
  final symbol = symbols[currency] ?? r'$';
  return '$symbol$value';
}

String slugify(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'(^-|-$)+'), '');
}

List<String> splitList(String value) {
  return value
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();
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
    return MenuData(
      hotel: HotelData.fromJson(json['hotel'] as Map<String, dynamic>),
      categories: (json['categories'] as List)
          .map((entry) => CategoryData.fromJson(entry as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List)
          .map((entry) => MenuItemData.fromJson(entry as Map<String, dynamic>))
          .toList(),
      labels: (json['labels'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value.toString())),
      categoryAliases: (json['categoryAliases'] as Map<String, dynamic>? ?? {})
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
      tagline: json['tagline'] as String,
      currency: json['currency'] as String,
      hours: json['hours'] as String,
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
}
