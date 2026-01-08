import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

/// Écran d'inscription
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    bool isValid = true;

    if (_nameController.text.isEmpty) {
      setState(() {
        _nameError = 'Le nom est requis';
      });
      isValid = false;
    }

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
    } else if (_passwordController.text.length < 6) {
      setState(() {
        _passwordError = 'Le mot de passe doit faire au moins 6 caractères';
      });
      isValid = false;
    }

    if (_confirmPasswordController.text != _passwordController.text) {
      setState(() {
        _confirmPasswordError = 'Les mots de passe ne correspondent pas';
      });
      isValid = false;
    }

    return isValid;
  }

  Future<void> _register() async {
    if (!_validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte créé ! Vérifiez votre email pour confirmer.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    'Créer un compte',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commencez à gérer vos finances',
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
                  // Nom
                  CustomTextField(
                    controller: _nameController,
                    label: 'Nom',
                    hint: 'Votre nom',
                    errorText: _nameError,
                    prefixIcon: const Icon(Icons.person_outlined),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  // Email
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'votre@email.com',
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    prefixIcon: const Icon(Icons.email_outlined),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  // Mot de passe
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Mot de passe',
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
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  // Confirmer mot de passe
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirmer le mot de passe',
                    hint: '••••••••',
                    obscureText: _obscureConfirmPassword,
                    errorText: _confirmPasswordError,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _register(),
                  ),
                  const SizedBox(height: 32),
                  // Bouton inscription
                  CustomButton(
                    text: 'S\'inscrire',
                    onPressed: _register,
                    isLoading: authProvider.isLoading,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 24),
                  // Connexion
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Déjà un compte ?'),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Se connecter'),
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
