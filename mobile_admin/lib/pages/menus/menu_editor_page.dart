import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api_client.dart';
import '../../models/menu_models.dart';
import '../../utils/menu_helpers.dart';

class MenuEditorScreen extends StatefulWidget {
  const MenuEditorScreen({super.key, required this.menuId});

  final String menuId;

  @override
  State<MenuEditorScreen> createState() => _MenuEditorScreenState();
}

class _MenuEditorScreenState extends State<MenuEditorScreen> {
  MenuData? data;
  String query = '';
  String categoryFilter = 'all';
  String lastEdit = 'Just now';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    final result = await ApiClient.getMenu(widget.menuId);
    setState(() {
      data = result;
      categoryFilter = 'all';
      query = '';
      lastEdit = 'Just now';
      loading = false;
    });
  }

  void _updateLastEdit() {
    final now = TimeOfDay.now();
    setState(() {
      lastEdit = now.format(context);
    });
  }

  Future<void> _openCategoryPicker() async {
    if (data == null) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _CategorySheet(
          categories: data!.categories,
          selected: categoryFilter,
          onSelect: (value) {
            setState(() => categoryFilter = value);
            Navigator.of(context).pop();
          },
          onCreate: () async {
            final created = await _showCategoryDialog();
            if (created == null) return;
            final menu = await ApiClient.createCategory(
              widget.menuId,
              created,
            );
            setState(() {
              data = menu;
              categoryFilter = created.id;
            });
          },
          onEdit: (category) async {
            final updated = await _showCategoryDialog(initial: category);
            if (updated == null) return;
            final menu = await ApiClient.updateCategory(
              widget.menuId,
              category.id,
              updated,
            );
            setState(() {
              data = menu;
              categoryFilter = updated.id;
            });
          },
        );
      },
    );
  }

  Future<CategoryData?> _showCategoryDialog({CategoryData? initial}) async {
    final controller = TextEditingController(text: initial?.label ?? '');
    return showDialog<CategoryData>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(initial == null ? 'New category' : 'Edit category'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Category name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final label = controller.text.trim();
                if (label.isEmpty) return;
                final id = initial?.id ?? slugify(label);
                Navigator.of(context).pop(CategoryData(id: id, label: label));
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<void> _openEditor({MenuItemData? item}) async {
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
          onCreateCategory: () async {
            final created = await _showCategoryDialog();
            if (created == null) return null;
            final menu = await ApiClient.createCategory(
              widget.menuId,
              created,
            );
            setState(() {
              data = menu;
            });
            return created;
          },
          onDelete: item == null
              ? null
              : () async {
                  final menu = await ApiClient.deleteItem(
                    widget.menuId,
                    item.id,
                  );
                  setState(() {
                    data = menu;
                  });
                  _updateLastEdit();
                  Navigator.of(context).pop();
                },
          onSave: (payload) async {
            final menu = item == null
                ? await ApiClient.createItem(widget.menuId, payload)
                : await ApiClient.updateItem(
                    widget.menuId,
                    item.id,
                    payload,
                  );
            setState(() {
              data = menu;
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
    if (loading || data == null) {
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
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back to menus'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0F2B3A),
                    ),
                  ),
                ),
              ),
            ),
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
                  onCategoryTap: _openCategoryPicker,
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
                      style: GoogleFonts.fraunces(
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
    required this.onCategoryTap,
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
  final VoidCallback onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 600;
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
          if (isCompact)
            Column(
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
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hotelHours,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF7E5DD),
                      foregroundColor: const Color(0xFFC4532D),
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: onSync,
                    child: const Text('Sync'),
                  ),
                ),
              ],
            )
          else
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
                        style: GoogleFonts.fraunces(
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
              _StatCard(
                value: totalCategories.toString(),
                label: 'Categories',
              ),
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
          InkWell(
            onTap: onCategoryTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5EF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      categoryFilter == 'all'
                          ? 'All categories'
                          : categories
                              .firstWhere((cat) => cat.id == categoryFilter)
                              .label,
                    ),
                  ),
                  const Icon(Icons.expand_more_rounded),
                ],
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
    required this.onCreateCategory,
  });

  final List<CategoryData> categories;
  final Map<String, String> labels;
  final MenuItemData? initial;
  final ValueChanged<MenuItemData> onSave;
  final VoidCallback? onDelete;
  final Future<CategoryData?> Function() onCreateCategory;

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
  late List<CategoryData> categoryOptions;

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
    categoryOptions = List<CategoryData>.from(widget.categories);
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
                  style: GoogleFonts.fraunces(
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
                  _FieldInput(
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
                    items: categoryOptions,
                    onCreate: () async {
                      final created = await widget.onCreateCategory();
                      if (created == null) return;
                      setState(() {
                        categoryOptions = [...categoryOptions, created];
                        selectedCategory = created.id;
                      });
                    },
                    onChanged: (value) => setState(
                      () => selectedCategory = value,
                    ),
                  ),
                  _FieldInput(
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
                  _FieldInput(
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
                  _FieldInput(
                    label: 'Tags (comma-separated)',
                    controller: tagsController,
                  ),
                  _FieldInput(
                    label: 'Prep time',
                    controller: prepController,
                  ),
                  _FieldInput(
                    label: 'Calories',
                    controller: caloriesController,
                    keyboardType: TextInputType.number,
                  ),
                  _FieldInput(
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

class _FieldInput extends StatelessWidget {
  const _FieldInput({
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
    required this.onCreate,
  });

  final String label;
  final String value;
  final List<CategoryData> items;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onCreate;

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
            items: [
              const DropdownMenuItem(
                value: '__new__',
                child: Text('New Category →'),
              ),
              ...items.map(
                (item) => DropdownMenuItem(
                  value: item.id,
                  child: Text(item.label),
                ),
              ),
            ],
            onChanged: (selection) async {
              if (selection == null) return;
              if (selection == '__new__') {
                await onCreate();
                return;
              }
              onChanged(selection);
            },
          ),
        ),
      ),
    );
  }
}

class _CategorySheet extends StatelessWidget {
  const _CategorySheet({
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.onCreate,
    required this.onEdit,
  });

  final List<CategoryData> categories;
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreate;
  final ValueChanged<CategoryData> onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE2D6C6),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Categories',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                _CategoryTile(
                  label: 'New Category →',
                  selected: false,
                  onTap: onCreate,
                  leadingIcon: Icons.add_circle_outline,
                ),
                _CategoryTile(
                  label: 'All categories',
                  selected: selected == 'all',
                  onTap: () => onSelect('all'),
                ),
                ...categories.map(
                  (category) => _CategoryTile(
                    label: category.label,
                    selected: selected == category.id,
                    onTap: () => onSelect(category.id),
                    onEdit: () => onEdit(category),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onEdit,
    this.leadingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected ? const Color(0xFF0F2B3A) : null,
        ),
      ),
      leading: Icon(
        leadingIcon ??
            (selected ? Icons.radio_button_checked : Icons.radio_button_off),
        color: selected ? const Color(0xFF0F2B3A) : Colors.grey.shade400,
      ),
      trailing: onEdit == null
          ? null
          : IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
      onTap: onTap,
    );
  }
}
