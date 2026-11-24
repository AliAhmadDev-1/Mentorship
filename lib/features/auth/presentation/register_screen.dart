import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/app_user.dart';
import '../../../core/utils/result.dart';
import '../../../core/validators/form_validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  UserRole _role = UserRole.mentee;
  Map<String, List<String>> _serverErrors = const {};

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).isLoading;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                Text(
                  'Create account',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        label: 'Find a Mentor',
                        icon: Icons.search_rounded,
                        selected: _role == UserRole.mentee,
                        onTap: () => setState(() => _role = UserRole.mentee),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        label: 'Become a Mentor',
                        icon: Icons.school_rounded,
                        selected: _role == UserRole.mentor,
                        onTap: () => setState(() => _role = UserRole.mentor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _first,
                        hint: 'First name',
                        validator: (value) =>
                            _fieldError('first_name') ??
                            FormValidators.name(value),
                        onChanged: (_) => _clearFieldError('first_name'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _last,
                        hint: 'Last name',
                        validator: (value) =>
                            _fieldError('last_name') ??
                            FormValidators.name(value),
                        onChanged: (_) => _clearFieldError('last_name'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _email,
                  hint: 'Email',
                  prefixIcon: Icons.mail_rounded,
                  validator: (value) =>
                      _fieldError('email') ?? FormValidators.email(value),
                  onChanged: (_) => _clearFieldError('email'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _password,
                  hint: 'Password',
                  prefixIcon: Icons.lock_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) =>
                      _fieldError('password') ?? FormValidators.password(value),
                  onChanged: (_) => _clearFieldError('password'),
                ),
                if (_role == UserRole.mentor) ...[
                  const SizedBox(height: 14),
                  Text(
                    'You will add your professional profile and verification documents next.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (_formError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _formError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                PrimaryButton(
                  label: _role == UserRole.mentor
                      ? 'Continue'
                      : 'Create Account',
                  isLoading: loading,
                  onPressed: loading ? null : _submit,
                ),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/auth/login'),
                    child: const Text('Already have an account? Sign in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _serverErrors = const {});
    final result = await ref
        .read(authProvider.notifier)
        .register(
          _first.text.trim(),
          _last.text.trim(),
          _email.text.trim(),
          _password.text,
          _role,
        );
    if (!mounted) return;
    switch (result) {
      case Success(data: final role):
        context.go(role == UserRole.mentor ? '/mentor/onboarding' : '/home');
      case Failure(error: final error):
        setState(() => _serverErrors = error.fieldErrors);
        _formKey.currentState?.validate();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  String? get _formError {
    final errors = _serverErrors['non_field_errors'] ?? _serverErrors['errors'];
    return errors == null || errors.isEmpty ? null : errors.join('\n');
  }

  String? _fieldError(String field) {
    final errors = _serverErrors[field];
    return errors == null || errors.isEmpty ? null : errors.first;
  }

  void _clearFieldError(String field) {
    if (!_serverErrors.containsKey(field)) return;
    setState(() => _serverErrors = {..._serverErrors}..remove(field));
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    color: selected ? AppColors.primarySoft : null,
    child: Column(
      children: [
        Icon(
          icon,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        ),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center),
      ],
    ),
  );
}
