// ============================================================================
// SmartSpend - Écran de sélection de langue
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';

/// Écran de sélection de la langue
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.language ?? 'Language'),
      ),
      body: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          final languages = languageProvider.availableLanguages;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final lang = languages[index];
              final isSelected = lang['code'] == languageProvider.languageCode;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : (isDark ? AppColors.surfaceDark : null),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected
                      ? const BorderSide(color: AppColors.primary, width: 2)
                      : BorderSide.none,
                ),
                child: ListTile(
                  leading: Text(
                    lang['flag'] as String,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(
                    lang['name'] as String,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                    ),
                  ),
                  subtitle: Text(
                    lang['code'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.7)
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () async {
                    await languageProvider.setLanguageCode(lang['code'] as String);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${lang['name']} selected'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
