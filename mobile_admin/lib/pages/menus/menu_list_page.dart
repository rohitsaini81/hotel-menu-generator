import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../models/menu_models.dart';
import 'menu_editor_page.dart';
import '../profile/profile_page.dart';

class MenuListScreen extends StatefulWidget {
  const MenuListScreen({super.key});

  @override
  State<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends State<MenuListScreen> {
  late Future<List<MenuSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiClient.listMenus();
  }

  void _showCreateMenuSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final nameController = TextEditingController();
        final hoursController = TextEditingController(text: '24/7');
        String selectedCurrency = 'USD';
        const currencies = <String>['USD', 'INR', 'EUR', 'GBP', 'AED'];

        return FractionallySizedBox(
          heightFactor: 0.5,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create Hotel Menu',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Hotel name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Currency',
                            border: OutlineInputBorder(),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedCurrency,
                              items: currencies
                                  .map(
                                    (code) => DropdownMenuItem<String>(
                                      value: code,
                                      child: Text(code),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  selectedCurrency = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: hoursController,
                          decoration: const InputDecoration(
                            labelText: 'Hours',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a hotel name.'),
                            ),
                          );
                          return;
                        }
                        // TODO: Call backend to create menu and navigate to editor.
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Would create menu for "$name" (not wired yet).',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC4532D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menus'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
            },
            icon: const Icon(Icons.account_circle_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<MenuSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load menus: ${snapshot.error}'),
            );
          }
          final menus = snapshot.data ?? [];
          return Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showCreateMenuSheet,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Hotel Menu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC4532D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.12),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: menus.isEmpty
                      ? const Center(child: Text('No menus found.'))
                      : ListView.separated(
                          itemCount: menus.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final menu = menus[index];
                            return InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        MenuEditorScreen(menuId: menu.id),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(18),
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
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            menu.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            menu.createdAtLabel,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
