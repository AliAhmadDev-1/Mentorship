import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/app_user.dart';
import '../../../core/validators/form_validators.dart';
import '../../../core/utils/result.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  Map<String, List<String>> _serverErrors = const {};

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).isLoading;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 52
                      ? constraints.maxHeight - 52
                      : 0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _LoginHero(),
                          const SizedBox(height: 28),
                          GlassCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Sign in',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 22),
                                AppTextField(
                                  controller: _email,
                                  hint: 'Email',
                                  prefixIcon: Icons.mail_rounded,
                                  validator: (value) =>
                                      _fieldError('email') ??
                                      FormValidators.email(value),
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
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                  validator: (value) =>
                                      _fieldError('password') ??
                                      FormValidators.password(value),
                                  onChanged: (_) =>
                                      _clearFieldError('password'),
                                ),
                                if (_formError != null) ...[
                                  const SizedBox(height: 12),
                                  _FormErrorBanner(message: _formError!),
                                ],
                                const SizedBox(height: 18),
                                PrimaryButton(
                                  label: 'Sign In',
                                  icon: Icons.arrow_forward_rounded,
                                  isLoading: loading,
                                  onPressed: loading
                                      ? null
                                      : () async {
                                          if (!_formKey.currentState!
                                              .validate()) {
                                            return;
                                          }
                                          setState(
                                            () => _serverErrors = const {},
                                          );
                                          final result = await ref
                                              .read(authProvider.notifier)
                                              .login(
                                                _email.text,
                                                _password.text,
                                              );
                                          if (!context.mounted) return;
                                          switch (result) {
                                            case Success(data: final role):
                                              if (role == UserRole.mentor) {
                                                final authState = ref
                                                    .read(authProvider)
                                                    .valueOrNull;
                                                context.go(
                                                  authState?.mentorOnboardingRequired ==
                                                          true
                                                      ? '/mentor/onboarding'
                                                      : '/dashboard',
                                                );
                                              } else {
                                                context.go('/home');
                                              }
                                            case Failure(error: final error):
                                              setState(
                                                () => _serverErrors =
                                                    error.fieldErrors,
                                              );
                                              _formKey.currentState?.validate();
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(error.message),
                                                ),
                                              );
                                          }
                                        },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/auth/register'),
                              child: const Text('New here? Create an account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String? get _formError {
    final errors = _serverErrors['non_field_errors'] ?? _serverErrors['errors'];
    if (errors == null || errors.isEmpty) return null;
    return errors.join('\n');
  }

  String? _fieldError(String field) {
    final errors = _serverErrors[field];
    if (errors == null || errors.isEmpty) return null;
    return errors.first;
  }

  void _clearFieldError(String field) {
    if (!_serverErrors.containsKey(field)) return;
    setState(() {
      _serverErrors = {..._serverErrors}..remove(field);
    });
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bolt_rounded, color: AppColors.darkest),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Micro Mentor', style: textTheme.titleMedium),
              const SizedBox(height: 2),
              Text('Welcome back', style: textTheme.headlineMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormErrorBanner extends StatelessWidget {
  const _FormErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: .24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
