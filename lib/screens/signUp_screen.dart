import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/user_model.dart';
import '../viewmodel/app_viewmodel.dart';
import 'home_screen.dart';

/// Used for sign up, and (isEditing: true) for "Edit details" in settings.
class SignUpScreen extends StatefulWidget {
  final bool isEditing;
  const SignUpScreen({super.key, this.isEditing = false});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _earning = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppViewModel>().user;
    if (widget.isEditing && user != null) {
      _name.text = user.name;
      _age.text = user.age.toString();
      _earning.text = user.yearlyEarning.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _earning.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final user = UserModel(
      name: _name.text.trim(),
      age: int.parse(_age.text.trim()),
      yearlyEarning: double.parse(_earning.text.replaceAll(',', '').trim()),
    );
    await context.read<AppViewModel>().saveUser(user);
    if (!mounted) return;

    if (widget.isEditing) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: widget.isEditing ? AppBar(title: const Text('Edit details')) : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isEditing) ...[
                  const SizedBox(height: 24),
                  Text('Create your profile',
                      style: text.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Tell us a little about you to get started.',
                      style: text.bodyLarge
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 32),
                ] else
                  const SizedBox(height: 8),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _age,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  validator: (v) {
                    final age = int.tryParse((v ?? '').trim());
                    if (age == null || age < 1 || age > 120) {
                      return 'Enter a valid age';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _earning,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Yearly earning',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (v) {
                    final n = double.tryParse(
                        (v ?? '').replaceAll(',', '').trim());
                    if (n == null || n < 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(80)
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.surfaceContainerLow
                  ),
                  child: Text(widget.isEditing ? 'Save changes' : 'Get started'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}