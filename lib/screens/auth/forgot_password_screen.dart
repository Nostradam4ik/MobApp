import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

/// Écran de récupération de mot de passe
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _emailError;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError = null;
    });

    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'L\'email est requis';
      });
      return false;
    } else if (!_emailController.text.contains('@')) {
      setState(() {
        _emailError = 'Email invalide';
      });
      return false;
    }

    return true;
  }

  Future<void> _resetPassword() async {
    if (!_validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPassword(
      _emailController.text.trim(),
    );

    if (success && mounted) {
      setState(() {
        _emailSent = true;
      });
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
              if (_emailSent) {
                return _buildSuccessState();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Titre
                  Text(
                    'Mot de passe oublié ?',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entrez votre email pour recevoir un lien de réinitialisation.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 32),
                  // Erreur
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
                    label: 'Email',
                    hint: 'votre@email.com',
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    prefixIcon: const Icon(Icons.email_outlined),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _resetPassword(),
                  ),
                  const SizedBox(height: 32),
                  // Bouton
                  CustomButton(
                    text: 'Envoyer le lien',
                    onPressed: _resetPassword,
                    isLoading: authProvider.isLoading,
                    width: double.infinity,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read,
            size: 50,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Email envoyé !',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 16),
        Text(
          'Vérifiez votre boîte de réception et suivez les instructions pour réinitialiser votre mot de passe.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: 'Retour à la connexion',
          onPressed: () => context.pop(),
          width: double.infinity,
        ),
      ],
    );
  }
}
