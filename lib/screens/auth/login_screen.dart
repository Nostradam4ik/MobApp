import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../l10n/app_localizations.dart';

/// Écran de connexion
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    bool isValid = true;

    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'L\'email est requis';
      });
      isValid = false;
    } else if (!_emailController.text.contains('@')) {
      setState(() {
        _emailError = 'Email invalide';
      });
      isValid = false;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Le mot de passe est requis';
      });
      isValid = false;
    }

    return isValid;
  }

  Future<void> _login() async {
    if (!_validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      // Rafraîchir le statut de l'abonnement après connexion
      context.read<SubscriptionProvider>().refresh();
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Logo
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Titre
                  Text(
                    l10n?.welcomeBack ?? 'Welcome back!',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.signInToContinue ?? 'Sign in to continue',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 32),
                  // Erreur globale
                  if (authProvider.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authProvider.error!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Email
                  CustomTextField(
                    controller: _emailController,
                    label: l10n?.email ?? 'Email',
                    hint: 'your@email.com',
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    prefixIcon: const Icon(Icons.email_outlined),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  // Mot de passe
                  CustomTextField(
                    controller: _passwordController,
                    label: l10n?.password ?? 'Password',
                    hint: '••••••••',
                    obscureText: _obscurePassword,
                    errorText: _passwordError,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                  ),
                  // Mot de passe oublié
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.forgotPassword),
                      child: Text(l10n?.forgotPassword ?? 'Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Bouton connexion
                  CustomButton(
                    text: l10n?.login ?? 'Sign in',
                    onPressed: _login,
                    isLoading: authProvider.isLoading,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 24),
                  // Inscription
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n?.noAccount ?? 'No account yet?'),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.register),
                        child: Text(l10n?.register ?? 'Sign up'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
