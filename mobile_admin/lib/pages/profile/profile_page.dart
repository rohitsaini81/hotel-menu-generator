import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth_service.dart';
import '../auth/auth_landing_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _name;
  late String _email;
  late String _number;
  late String _googleId;
  late String _picture;
  late bool _isTester;

  @override
  void initState() {
    super.initState();
    final profile = AuthService.currentProfile;
    _name = profile?.name ?? 'Guest';
    _email = profile?.email ?? 'Not available';
    _number = profile?.number ?? 'Not available';
    _googleId = profile?.id ?? 'Not available';
    _picture = profile?.picture ?? '';
    _isTester = profile?.isTester ?? false;
  }

  Future<void> _editField({
    required String title,
    required String currentValue,
    required ValueChanged<String> onSave,
  }) async {
    final controller = TextEditingController(text: currentValue);
    final updated = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: 'Enter $title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (!mounted || updated == null) {
      return;
    }
    final value = updated.trim();
    if (value.isEmpty) {
      return;
    }
    setState(() => onSave(value));
  }

  Future<void> _handleSignOut() async {
    await AuthService.signOut();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthLanding()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPicture = _picture.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton.icon(
            onPressed: _handleSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
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
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: const Color(0xFFE8E0D2),
                            backgroundImage: hasPicture
                                ? NetworkImage(_picture)
                                : null,
                            child: hasPicture
                                ? null
                                : const Icon(
                                    Icons.person_rounded,
                                    size: 42,
                                    color: Color(0xFF725D49),
                                  ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Material(
                              color: const Color(0xFF0F2B3A),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => _editField(
                                  title: 'Profile image URL',
                                  currentValue: _picture,
                                  onSave: (value) => _picture = value,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(7),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _editField(
                          title: 'Name',
                          currentValue: _name,
                          onSave: (value) => _name = value,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Text(
                            _name,
                            style: GoogleFonts.fraunces(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C1A18),
                            ),
                          ),
                        ),
                      ),
                      if (_isTester) ...[
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
                        value: _email,
                        icon: Icons.alternate_email_rounded,
                        onEdit: () => _editField(
                          title: 'Email',
                          currentValue: _email,
                          onSave: (value) => _email = value,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProfileField(
                        label: 'Number',
                        value: _number,
                        icon: Icons.phone_rounded,
                        onEdit: () => _editField(
                          title: 'Number',
                          currentValue: _number,
                          onSave: (value) => _number = value,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProfileField(
                        label: 'User ID',
                        value: _googleId,
                        icon: Icons.badge_outlined,
                        onEdit: () => _editField(
                          title: 'User ID',
                          currentValue: _googleId,
                          onSave: (value) => _googleId = value,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleSignOut,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Sign out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF8D3C25),
                            side: const BorderSide(color: Color(0xFFF0D6BF)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
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
    required this.onEdit,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onEdit;

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
          IconButton(
            tooltip: 'Edit $label',
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_rounded,
              size: 18,
              color: Color(0xFF725D49),
            ),
          ),
        ],
      ),
    );
  }
}
