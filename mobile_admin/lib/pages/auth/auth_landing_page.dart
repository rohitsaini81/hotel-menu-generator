import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/auth_service.dart';
import '../menus/menu_list_page.dart';

class AuthLanding extends StatefulWidget {
  const AuthLanding({super.key});

  @override
  State<AuthLanding> createState() => _AuthLandingState();
}

class _AuthLandingState extends State<AuthLanding>
    with SingleTickerProviderStateMixin {
  bool isLogin = true;
  bool _isAuthBusy = false;
  late final StreamSubscription<GoogleSignInAccount?> _googleUserSubscription;

  late final AnimationController _bgController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    AuthService.ensureInitialized();
    _googleUserSubscription = AuthService.onCurrentUserChanged.listen((
      account,
    ) {
      if (!kIsWeb || account == null) {
        return;
      }
      _handleGoogleAccount(account);
    });
  }

  @override
  void dispose() {
    _googleUserSubscription.cancel();
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
                                        isBusy: _isAuthBusy,
                                        onGoogleLogin: _handleGoogleLogin,
                                        onTesterLogin: _handleTesterLogin,
                                        onToggle: () =>
                                            setState(() => isLogin = !isLogin),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _BrandPanel(isLogin: isLogin),
                                    const SizedBox(height: 20),
                                    _AuthCard(
                                      isLogin: isLogin,
                                      isBusy: _isAuthBusy,
                                      onGoogleLogin: _handleGoogleLogin,
                                      onTesterLogin: _handleTesterLogin,
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

  Future<void> _handleGoogleLogin() async {
    if (_isAuthBusy) {
      return;
    }
    setState(() => _isAuthBusy = true);
    try {
      await AuthService.signInWithGoogle();
      if (!mounted) {
        return;
      }
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const MenuListScreen()));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAuthBusy = false);
      }
    }
  }

  Future<void> _handleTesterLogin() async {
    AuthService.signInAsTester();
    if (!mounted) {
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MenuListScreen()));
  }

  Future<void> _handleGoogleAccount(GoogleSignInAccount account) async {
    if (_isAuthBusy) {
      return;
    }
    setState(() => _isAuthBusy = true);
    try {
      await AuthService.authenticateAccount(account);
      if (!mounted) {
        return;
      }
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const MenuListScreen()));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAuthBusy = false);
      }
    }
  }
}

class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF6F1E8), Color(0xFFE7EFE7), Color(0xFFF3E7DA)],
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
            gradient: RadialGradient(colors: [color, Colors.transparent]),
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
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
  const _AuthCard({
    required this.isLogin,
    required this.onToggle,
    required this.onGoogleLogin,
    required this.onTesterLogin,
    required this.isBusy,
  });

  final bool isLogin;
  final VoidCallback onToggle;
  final VoidCallback onGoogleLogin;
  final VoidCallback onTesterLogin;
  final bool isBusy;

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
              foregroundColor: const Color(0xFF2B2B2B),
              side: const BorderSide(color: Color(0xFFE7E0D4)),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
<<<<<<< HEAD
            onPressed: (isBusy || ApiConfig.googleClientId.isEmpty)
                ? null
                : onGoogleLogin,
=======
            onPressed: isBusy ? null : onGoogleLogin,
>>>>>>> 6b956daa77f60e135a7b547b23277d6eaff7a888
            child: isBusy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue with Google'),
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
            onPressed: onTesterLogin,
            child: const Text('Login as tester'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLogin ? 'New to Aurora Bay? ' : 'Already have access? ',
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
          const Text('Secure session ready', style: TextStyle(fontSize: 12)),
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
        TextButton(onPressed: () {}, child: const Text('Forgot code?')),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.hint, this.obscure = false});

  final String label;
  final String hint;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
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
                  child: CustomPaint(painter: _WavePainter()),
                ),
              ),
              Positioned(left: width * 0.12, top: 22, child: const _ArcBadge()),
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
