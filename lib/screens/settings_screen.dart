import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../viewmodel/app_viewmodel.dart';
import 'signUp_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();
    final scheme = Theme.of(context).colorScheme;
    final user = vm.user;

    final path = vm.profileImagePath;
    final image = (path != null && File(path).existsSync())
        ? FileImage(File(path))
        : null;
    final initial = (user?.name.isNotEmpty ?? false)
        ? user!.name[0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Settings',
          style: GoogleFonts.lobster(textStyle:  TextStyle(fontSize: 32, color: Theme.of(context).colorScheme.primary)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ---------- Profile ----------
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage: image,
                  child: image == null
                      ? Text(
                          initial,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: scheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () => _pickImage(context, vm),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: scheme.primary,
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              user?.name ?? '',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (user != null)
            Center(
              child: Text(
                'Age ${user.age} · Earns ${_money(user.yearlyEarning)} / year',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          if (image != null)
            Center(
              child: TextButton(
                onPressed: () => _removeImage(vm),
                child: const Text('Remove photo'),
              ),
            ),
          const SizedBox(height: 16),

          // ---------- Account ----------
          const _SectionTitle('Account'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit details'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SignUpScreen(isEditing: true),
                ),
              ),
            ),
          ),

          // ---------- Appearance ----------
          const _SectionTitle('Appearance'),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {vm.themeMode},
              onSelectionChanged: (s) => vm.setThemeMode(s.first),
            ),
          ),

          // ---------- Security ----------
          const _SectionTitle('Security'),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Biometric protection'),
              subtitle: const Text(
                'Require fingerprint / face to unlock the app and view card details.',
              ),
              value: vm.biometricEnabled,
              onChanged: (v) async {
                final ok = await vm.setBiometricEnabled(v);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Couldn't change this setting. Make sure a fingerprint, face or screen lock is set up.",
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, AppViewModel vm) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    // Copy into app storage: picker cache paths can disappear.
    final dir = await getApplicationDocumentsDirectory();
    final saved = await File(picked.path).copy(
      p.join(dir.path, 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg'),
    );

    final old = vm.profileImagePath;
    await vm.setProfileImage(saved.path);
    if (old != null && File(old).existsSync()) await File(old).delete();
  }

  Future<void> _removeImage(AppViewModel vm) async {
    final old = vm.profileImagePath;
    await vm.setProfileImage(null);
    if (old != null && File(old).existsSync()) await File(old).delete();
  }

  String _money(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
