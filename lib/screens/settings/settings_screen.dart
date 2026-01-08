import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/notification_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/subscription_service.dart';
import '../../services/tutorial_service.dart';

/// Écran des paramètres
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = LocalStorageService.areNotificationsEnabled();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: Consumer3<ThemeProvider, AuthProvider, LanguageProvider>(
        builder: (context, themeProvider, auth, languageProvider, _) {
          return ListView(
            children: [
              // Apparence
              _buildSectionHeader(context, 'Apparence'),
              _buildThemeTile(context, themeProvider),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Langue'),
                subtitle: Text(languageProvider.languageName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.languageSettings),
              ),
              ListTile(
                leading: const Icon(Icons.accessibility_new),
                title: const Text('Accessibilité'),
                subtitle: const Text('Daltonisme, taille du texte, contraste'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.accessibility),
              ),

              // Notifications
              _buildSectionHeader(context, 'Notifications'),
              SwitchListTile(
                title: const Text('Notifications'),
                subtitle: const Text('Alertes budget, rappels quotidiens'),
                value: _notificationsEnabled,
                onChanged: (value) async {
                  if (value) {
                    final granted = await NotificationService.requestPermissions();
                    if (granted) {
                      await LocalStorageService.setNotificationsEnabled(true);
                      setState(() => _notificationsEnabled = true);
                    }
                  } else {
                    await LocalStorageService.setNotificationsEnabled(false);
                    setState(() => _notificationsEnabled = false);
                  }
                },
              ),

              // Compte
              _buildSectionHeader(context, 'Compte'),
              ListTile(
                leading: const Icon(Icons.currency_exchange),
                title: const Text('Devise'),
                subtitle: Text(auth.profile?.currency ?? 'EUR'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showCurrencyPicker(context),
              ),
              ListTile(
                leading: const Icon(Icons.work_outline),
                title: const Text('Type de revenu'),
                subtitle: Text(
                  auth.profile?.incomeType.label ?? 'Fixe',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showIncomeTypePicker(context),
              ),

              // À propos
              _buildSectionHeader(context, 'À propos'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                subtitle: Text(AppConfig.version),
              ),
              ListTile(
                leading: const Icon(Icons.school_outlined),
                title: const Text('Revoir le tutoriel'),
                subtitle: const Text('Réafficher le guide de démarrage'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _resetTutorial(context),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Politique de confidentialité'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openUrl(AppConfig.privacyPolicyUrl),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Conditions d\'utilisation'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openUrl(AppConfig.termsOfServiceUrl),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Développé par'),
                subtitle: const Text(AppConfig.authorName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openUrl(AppConfig.authorLinkedIn),
              ),

              // Danger zone
              _buildSectionHeader(context, 'Zone dangereuse'),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: AppColors.error),
                title: const Text(
                  'Supprimer mon compte',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, ThemeProvider provider) {
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: const Text('Thème'),
      subtitle: Text(_getThemeName(provider.themeMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemePicker(context, provider),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Système';
    }
  }

  void _showThemePicker(BuildContext context, ThemeProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_auto),
                title: const Text('Système'),
                trailing: provider.themeMode == ThemeMode.system
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  provider.setThemeMode(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.light_mode),
                title: const Text('Clair'),
                trailing: provider.themeMode == ThemeMode.light
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  provider.setThemeMode(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Sombre'),
                trailing: provider.themeMode == ThemeMode.dark
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  provider.setThemeMode(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppConfig.currencySymbols.entries.map((entry) {
              return ListTile(
                title: Text('${entry.key} (${entry.value})'),
                onTap: () async {
                  final auth = context.read<AuthProvider>();
                  if (auth.profile != null) {
                    final updatedProfile = auth.profile!.copyWith(
                      currency: entry.key,
                      updatedAt: DateTime.now(),
                    );
                    await auth.updateProfile(updatedProfile);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showIncomeTypePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Fixe'),
                subtitle: const Text('Salaire régulier chaque mois'),
                onTap: () async {
                  final auth = context.read<AuthProvider>();
                  if (auth.profile != null) {
                    final updatedProfile = auth.profile!.copyWith(
                      incomeType: IncomeType.fixed,
                      updatedAt: DateTime.now(),
                    );
                    await auth.updateProfile(updatedProfile);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Variable'),
                subtitle: const Text('Revenus fluctuants (freelance, etc.)'),
                onTap: () async {
                  final auth = context.read<AuthProvider>();
                  if (auth.profile != null) {
                    final updatedProfile = auth.profile!.copyWith(
                      incomeType: IncomeType.variable,
                      updatedAt: DateTime.now(),
                    );
                    await auth.updateProfile(updatedProfile);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: 8),
            Text('Supprimer le compte ?'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action est irréversible. Seront supprimés :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• Toutes vos dépenses'),
            Text('• Tous vos budgets'),
            Text('• Tous vos objectifs'),
            Text('• Vos catégories personnalisées'),
            Text('• Vos achievements et streaks'),
            Text('• Votre profil'),
            SizedBox(height: 12),
            Text(
              'Êtes-vous sûr de vouloir continuer ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => _confirmDeleteAccount(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    Navigator.pop(context); // Fermer le premier dialog

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation finale'),
        content: const Text(
          'Tapez "SUPPRIMER" pour confirmer la suppression de votre compte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Je confirme'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Afficher un loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Suppression en cours...'),
          ],
        ),
      ),
    );

    // Réinitialiser les données locales d'abonnement
    await SubscriptionService.deactivatePremium();

    final success = await auth.deleteAccount();

    if (context.mounted) {
      Navigator.pop(context); // Fermer le loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre compte a été supprimé'),
            backgroundColor: AppColors.secondary,
          ),
        );
        // La navigation vers login sera gérée automatiquement par le router
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Erreur lors de la suppression'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _resetTutorial(BuildContext context) async {
    await TutorialService.resetTutorial();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le tutoriel s\'affichera au prochain lancement'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
