import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = AuthService.currentProfile;
    final hasPicture = profile != null && profile.picture.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F2E9), Color(0xFFEAF1EA)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 2,
                color: Colors.white.withValues(alpha: 0.95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: const Color(0xFFE8E0D2),
                        backgroundImage: hasPicture
                            ? NetworkImage(profile.picture)
                            : null,
                        child: hasPicture
                            ? null
                            : const Icon(
                                Icons.person_rounded,
                                size: 42,
                                color: Color(0xFF725D49),
                              ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        profile?.name ?? 'Guest',
                        style: GoogleFonts.fraunces(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1C1A18),
                        ),
                      ),
                      if (profile?.isTester == true) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0E5),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Tester account',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFB85E22),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _ProfileField(
                        label: 'Email',
                        value: profile?.email ?? 'Not available',
                        icon: Icons.alternate_email_rounded,
                      ),
                      const SizedBox(height: 12),
                      _ProfileField(
                        label: 'Number',
                        value: profile?.number ?? 'Not available',
                        icon: Icons.phone_rounded,
                      ),
                      const SizedBox(height: 12),
                      _ProfileField(
                        label: 'Google ID',
                        value: profile?.id ?? 'Not available',
                        icon: Icons.badge_outlined,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE5D8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF725D49)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    color: const Color(0xFF85715C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1C1A),
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
