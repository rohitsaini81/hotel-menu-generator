import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F2B3A),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Aurora Bay Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF6F1E8),
        textTheme: GoogleFonts.soraTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF6F1E8),
          elevation: 0,
          titleTextStyle: GoogleFonts.fraunces(
            color: const Color(0xFF1C1A18),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF1C1A18)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFDF9F3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const AuthLanding(),
    );
  }
}

class ApiConfig {
  static const baseUrl = 'https://hotel-menu-generator.onrender.com';
}

class ApiClient {
  static Future<List<MenuSummary>> listMenus() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/menus'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load menus');
    }
    final decoded = jsonDecode(response.body) as List;
    return decoded.map((entry) => MenuSummary.fromJson(entry)).toList();
  }

  static Future<MenuData> getMenu(String menuId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/menus/$menuId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load menu');
    }
    return MenuData.fromJson(jsonDecode(response.body));
  }

  static Future<MenuData> createItem(String menuId, MenuItemData item) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/menus/$menuId/items'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to create item');
    }
    return MenuData.fromJson(jsonDecode(response.body));
  }

  static Future<MenuData> updateItem(
    String menuId,
    String itemId,
    MenuItemData item,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/menus/$menuId/items/$itemId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to update item');
    }
    return MenuData.fromJson(jsonDecode(response.body));
  }

  static Future<MenuData> deleteItem(String menuId, String itemId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/menus/$menuId/items/$itemId'),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to delete item');
    }
    return MenuData.fromJson(jsonDecode(response.body));
  }

  static Future<MenuData> createCategory(
    String menuId,
    CategoryData category,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/menus/$menuId/categories'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(category.toJson()),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to create category');
    }
    return MenuData.fromJson(jsonDecode(response.body));
  }

  static Future<MenuData> updateCategory(
    String menuId,
    String categoryId,
    CategoryData category,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/menus/$menuId/categories/$categoryId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(category.toJson()),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to update category');
    }
    return MenuData.fromJson(jsonDecode(response.body));
  }
}

class AuthLanding extends StatefulWidget {
  const AuthLanding({super.key});

  @override
  State<AuthLanding> createState() => _AuthLandingState();
}

class _AuthLandingState extends State<AuthLanding>
    with SingleTickerProviderStateMixin {
  bool isLogin = true;

  late final AnimationController _bgController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;
    final isCompact = size.width < 520;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Stack(
            children: [
              const _AuroraBackground(),
              _FloatingGlow(
                alignment: Alignment.topLeft,
                color: const Color(0xFF7CD3C6).withOpacity(0.35),
                radius: 210,
                shift: Offset(80 * _bgController.value, 30),
              ),
              _FloatingGlow(
                alignment: Alignment.bottomRight,
                color: const Color(0xFFE58E5E).withOpacity(0.32),
                radius: 240,
                shift: Offset(-60 * _bgController.value, -40),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 16 : 24,
                        vertical: isCompact ? 16 : 24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _BrandPanel(isLogin: isLogin),
                                    ),
                                    const SizedBox(width: 32),
                                    Expanded(
                                      child: _AuthCard(
                                        isLogin: isLogin,
                                        onToggle: () =>
                                            setState(() => isLogin = !isLogin),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _BrandPanel(isLogin: isLogin),
                                    const SizedBox(height: 20),
                                    _AuthCard(
                                      isLogin: isLogin,
                                      onToggle: () =>
                                          setState(() => isLogin = !isLogin),
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
          );
        },
      ),
    );
  }
}

class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF6F1E8),
            Color(0xFFE7EFE7),
            Color(0xFFF3E7DA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _FloatingGlow extends StatelessWidget {
  const _FloatingGlow({
    required this.alignment,
    required this.color,
    required this.radius,
    required this.shift,
  });

  final Alignment alignment;
  final Color color;
  final double radius;
  final Offset shift;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: shift,
        child: Container(
          width: radius,
          height: radius,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.isLogin});

  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 520;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandBadge(isLogin: isLogin),
          const SizedBox(height: 24),
          Text(
            isLogin ? 'Welcome back' : 'Create your admin access',
            style: GoogleFonts.fraunces(
              fontSize: isCompact ? 30 : 38,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1C1A18),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Control menus, pricing, and service moments from one polished space. Built for fast teams and busy lobbies.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          const _MotionBanner(),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _FeatureChip(label: 'Live edits'),
              _FeatureChip(label: 'Role access'),
              _FeatureChip(label: 'Menu sync'),
              _FeatureChip(label: 'Audit logs'),
            ],
          ),
          const SizedBox(height: 20),
          _ActivityLogCard(isLogin: isLogin),
        ],
      ),
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge({required this.isLogin});

  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF0F2B3A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(Icons.hotel_class_rounded, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aurora Bay',
              style: GoogleFonts.fraunces(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              isLogin ? 'Admin Sign In' : 'Admin Sign Up',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE3D8C7)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF5F4A2C),
        ),
      ),
    );
  }
}

class _ActivityLogCard extends StatelessWidget {
  const _ActivityLogCard({required this.isLogin});

  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    final items = isLogin
        ? [
            const _LogEntry(
              icon: Icons.shield_rounded,
              title: '2-factor verified',
              subtitle: 'Front desk · 2 minutes ago',
            ),
            const _LogEntry(
              icon: Icons.wifi_tethering_rounded,
              title: 'Menu sync completed',
              subtitle: 'Pool bar · 9 minutes ago',
            ),
            const _LogEntry(
              icon: Icons.room_service_rounded,
              title: 'New specials published',
              subtitle: 'Rooftop lounge · 28 minutes ago',
            ),
          ]
        : [
            const _LogEntry(
              icon: Icons.task_alt_rounded,
              title: 'Identity review queued',
              subtitle: 'Expected within 6 hours',
            ),
            const _LogEntry(
              icon: Icons.mail_rounded,
              title: 'Welcome kit scheduled',
              subtitle: 'Email delivery in 5 minutes',
            ),
            const _LogEntry(
              icon: Icons.visibility_rounded,
              title: 'Training portal access',
              subtitle: 'Auto-enabled after approval',
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity logs',
                style: GoogleFonts.fraunces(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Live',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  const _LogEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF7E9D6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFC36A2B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.isLogin, required this.onToggle});

  final bool isLogin;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 520;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLogin ? 'Sign in' : 'Sign up',
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _AuthToggle(isLogin: isLogin, onToggle: onToggle),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isLogin ? 'Sign in' : 'Sign up',
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _AuthToggle(isLogin: isLogin, onToggle: onToggle),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            isLogin
                ? 'Use your work email and passcode to access menus.'
                : 'Create credentials and get verified access for your hotel.',
            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: isLogin
                ? const _LoginForm(key: ValueKey('login'))
                : const _SignupForm(key: ValueKey('signup')),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2B3A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {},
            child: Text(isLogin ? 'Enter workspace' : 'Create account'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F2B3A),
              side: const BorderSide(color: Color(0xFFE0D2C1)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {},
            child: const Text('Continue with hotel SSO'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC36A2B),
              side: const BorderSide(color: Color(0xFFF0D6BF)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MenuListScreen()),
              );
            },
            child: const Text('Login as tester'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLogin
                    ? 'New to Aurora Bay? '
                    : 'Already have access? ',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              TextButton(
                onPressed: onToggle,
                child: Text(isLogin ? 'Create account' : 'Sign in instead'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'By continuing, you agree to admin security protocols and device monitoring.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _AuthToggle extends StatelessWidget {
  const _AuthToggle({required this.isLogin, required this.onToggle});

  final bool isLogin;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF2E8D9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          alignment: isLogin ? Alignment.centerLeft : Alignment.centerRight,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          child: Container(
            width: 90,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                isLogin ? 'Login' : 'Sign up',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('login_form'),
      children: const [
        _Field(label: 'Work email', hint: 'manager@aurorabay.com'),
        SizedBox(height: 12),
        _Field(label: 'Passcode', hint: '••••••••', obscure: true),
        SizedBox(height: 12),
        _RowField(),
      ],
    );
  }
}

class _SignupForm extends StatelessWidget {
  const _SignupForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('signup_form'),
      children: const [
        _Field(label: 'Full name', hint: 'Ariella Benson'),
        SizedBox(height: 12),
        _Field(label: 'Work email', hint: 'name@aurorabay.com'),
        SizedBox(height: 12),
        _Field(label: 'Role', hint: 'Food & Beverage Lead'),
        SizedBox(height: 12),
        _Field(label: 'Passcode', hint: 'Create a secure code', obscure: true),
      ],
    );
  }
}

class _RowField extends StatelessWidget {
  const _RowField();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 420;
    final statusChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DACB)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF57B894),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Secure session ready',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          statusChip,
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {},
              child: const Text('Forgot code?'),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: statusChip),
        const SizedBox(width: 12),
        TextButton(
          onPressed: () {},
          child: const Text('Forgot code?'),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    this.obscure = false,
  });

  final String label;
  final String hint;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menus')),
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
          if (menus.isEmpty) {
            return const Center(child: Text('No menus found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: menus.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final menu = menus[index];
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MenuEditorScreen(menuId: menu.id),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

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
                    payload.id,
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
    return MenuData(
      hotel: HotelData.fromJson(json['hotel'] as Map<String, dynamic>),
      categories: (json['categories'] as List)
          .map((entry) => CategoryData.fromJson(entry as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List)
          .map((entry) => MenuItemData.fromJson(entry as Map<String, dynamic>))
          .toList(),
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

class _AuroraBurst extends CustomPainter {
  const _AuroraBurst();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    final center = Offset(size.width * 0.8, size.height * 0.2);
    for (var i = 0; i < 6; i++) {
      paint
        ..color = Colors.white.withOpacity(0.2 + i * 0.1)
        ..strokeWidth = 1 + i.toDouble();
      final radius = 20 + i * 14;
      canvas.drawCircle(center, radius.toDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArcBadge extends StatelessWidget {
  const _ArcBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _AuroraBurst(),
      child: const SizedBox(width: 160, height: 120),
    );
  }
}

class _MotionBanner extends StatelessWidget {
  const _MotionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: 110,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CustomPaint(
                    painter: _WavePainter(),
                  ),
                ),
              ),
              Positioned(
                left: width * 0.12,
                top: 22,
                child: const _ArcBadge(),
              ),
              Positioned(
                right: 22,
                top: 26,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text(
                      'Aurora Bay · Admin',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Priority access enabled',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0F2B3A), Color(0xFF315F4B), Color(0xFFC36A2B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final path = Path()..moveTo(0, size.height * 0.55);
    for (var i = 0; i <= 6; i++) {
      final x = size.width * i / 6;
      final y = size.height * (0.45 + 0.08 * sin(i + 0.6));
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
