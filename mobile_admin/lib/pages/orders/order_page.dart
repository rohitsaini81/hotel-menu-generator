import 'package:flutter/material.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final List<_OrderRecord> _orders = [
    _OrderRecord(
      id: '#RB-2048',
      guest: 'Room 804 • Priya Sharma',
      items: '1x Club sandwich, 2x cold brew, 1x fruit plate',
      status: 'Preparing',
      time: 'Placed 4 min ago',
      priority: 'High',
    ),
    _OrderRecord(
      id: '#RB-2047',
      guest: 'Pool deck • Liam Carter',
      items: '2x Caesar salad, 1x sparkling water',
      status: 'Ready',
      time: 'Placed 12 min ago',
      priority: 'Normal',
    ),
    _OrderRecord(
      id: '#RB-2046',
      guest: 'Suite 1203 • Aanya Patel',
      items: '1x pasta primavera, 1x tiramisu',
      status: 'Delivered',
      time: 'Placed 28 min ago',
      priority: 'Low',
    ),
  ];

  Color _statusColor(String status) {
    switch (status) {
      case 'Preparing':
        return const Color(0xFFC4532D);
      case 'Ready':
        return const Color(0xFF287D5A);
      case 'Delivered':
        return const Color(0xFF4E6470);
      case 'Pending':
        return const Color(0xFF83663A);
      default:
        return const Color(0xFF7A6F63);
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFB23A30);
      case 'Normal':
        return const Color(0xFF34699A);
      case 'Low':
        return const Color(0xFF5E7D57);
      default:
        return const Color(0xFF7A6F63);
    }
  }

  Future<void> _showOrderActions(_OrderRecord order) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.id,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.guest,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.sync_alt_rounded,
                  title: 'Change order status',
                  subtitle: 'Update kitchen or delivery progress',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _changeStatus(order);
                  },
                ),
                _ActionTile(
                  icon: Icons.flag_rounded,
                  title: 'Set priority',
                  subtitle: 'Adjust urgency for this order',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _setPriority(order);
                  },
                ),
                _ActionTile(
                  icon: Icons.drive_file_rename_outline_rounded,
                  title: 'Rename order',
                  subtitle: 'Edit the guest or location label',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _renameOrder(order);
                  },
                ),
                _ActionTile(
                  icon: Icons.archive_outlined,
                  title: 'Archive order',
                  subtitle: 'Remove it from active orders',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _archiveOrder(order);
                  },
                ),
                _ActionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete order',
                  subtitle: 'Permanently remove this test order',
                  destructive: true,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _deleteOrder(order);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _changeStatus(_OrderRecord order) async {
    const statuses = ['Pending', 'Preparing', 'Ready', 'Delivered'];
    final nextStatus = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change order status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: statuses
                .map(
                  (status) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(status),
                    trailing: order.status == status
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () => Navigator.of(dialogContext).pop(status),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (!mounted || nextStatus == null) return;
    setState(() {
      order.status = nextStatus;
    });
  }

  Future<void> _setPriority(_OrderRecord order) async {
    const priorities = ['High', 'Normal', 'Low', 'Clear'];
    final nextPriority = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Set priority'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: priorities
                .map(
                  (priority) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(priority),
                    trailing: ((order.priority ?? 'Clear') == priority)
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () => Navigator.of(
                      dialogContext,
                    ).pop(priority == 'Clear' ? null : priority),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (!mounted) return;
    setState(() {
      order.priority = nextPriority;
    });
  }

  Future<void> _renameOrder(_OrderRecord order) async {
    final controller = TextEditingController(text: order.guest);
    final updatedLabel = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename order'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter guest or location',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (!mounted || updatedLabel == null || updatedLabel.isEmpty) return;
    setState(() {
      order.guest = updatedLabel;
    });
  }

  void _archiveOrder(_OrderRecord order) {
    setState(() {
      _orders.remove(order);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${order.id} archived')),
    );
  }

  Future<void> _deleteOrder(_OrderRecord order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete order'),
          content: Text('Delete ${order.id}? This only affects test data.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      _orders.remove(order);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${order.id} deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF9F3),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE7DED2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active room-service orders',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Track new orders, kitchen progress, and delivery status.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _orders.isEmpty
                  ? const Center(child: Text('No active orders found.'))
                  : ListView.separated(
                      itemCount: _orders.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final statusColor = _statusColor(order.status);
                        final priorityColor = order.priority == null
                            ? null
                            : _priorityColor(order.priority!);
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _showOrderActions(order),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          order.id,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.more_horiz_rounded),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _Badge(
                                        label: order.status,
                                        color: statusColor,
                                      ),
                                      if (order.priority != null)
                                        _Badge(
                                          label: '${order.priority} priority',
                                          color: priorityColor!,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    order.guest,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    order.items,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    order.time,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFB23A30) : const Color(0xFF1C1A18);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
    );
  }
}

class _OrderRecord {
  _OrderRecord({
    required this.id,
    required this.guest,
    required this.items,
    required this.status,
    required this.time,
    this.priority,
  });

  final String id;
  String guest;
  final String items;
  String status;
  final String time;
  String? priority;
}
