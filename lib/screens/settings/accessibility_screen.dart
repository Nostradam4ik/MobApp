import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/accessibility_provider.dart';
import '../../services/accessibility_service.dart';

/// Écran des paramètres d'accessibilité
class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibilité'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Retour',
        ),
      ),
      body: Consumer<AccessibilityProvider>(
        builder: (context, accessibility, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // En-tête explicatif
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.accessibility_new,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Options d\'accessibilité',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Adaptez l\'application à vos besoins visuels et moteurs',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section Vision
              _buildSectionHeader(context, 'Vision', Icons.visibility),

              const SizedBox(height: 12),

              // Daltonisme
              _buildColorBlindnessCard(context, accessibility, theme, isDark),

              const SizedBox(height: 12),

              // Contraste élevé
              _buildSwitchCard(
                context: context,
                title: 'Contraste élevé',
                subtitle: 'Augmente le contraste des couleurs pour une meilleure lisibilité',
                icon: Icons.contrast,
                value: accessibility.highContrast,
                onChanged: (value) => accessibility.setHighContrast(value),
                theme: theme,
                isDark: isDark,
              ),

              const SizedBox(height: 12),

              // Taille de police
              _buildFontScaleCard(context, accessibility, theme, isDark),

              const SizedBox(height: 24),

              // Section Motricité
              _buildSectionHeader(context, 'Motricité', Icons.touch_app),

              const SizedBox(height: 12),

              // Zones tactiles agrandies
              _buildSwitchCard(
                context: context,
                title: 'Zones tactiles agrandies',
                subtitle: 'Augmente la taille des boutons et zones interactives',
                icon: Icons.pan_tool,
                value: accessibility.largeTouch,
                onChanged: (value) => accessibility.setLargeTouch(value),
                theme: theme,
                isDark: isDark,
              ),

              const SizedBox(height: 12),

              // Réduire les animations
              _buildSwitchCard(
                context: context,
                title: 'Réduire les animations',
                subtitle: 'Désactive ou réduit les animations et transitions',
                icon: Icons.animation,
                value: accessibility.reduceAnimations,
                onChanged: (value) => accessibility.setReduceAnimations(value),
                theme: theme,
                isDark: isDark,
              ),

              const SizedBox(height: 24),

              // Section Lecteur d'écran
              _buildSectionHeader(context, 'Lecteur d\'écran', Icons.record_voice_over),

              const SizedBox(height: 12),

              // Mode lecteur d'écran
              _buildSwitchCard(
                context: context,
                title: 'Optimisé pour lecteur d\'écran',
                subtitle: 'Améliore la compatibilité avec VoiceOver et TalkBack',
                icon: Icons.speaker_notes,
                value: accessibility.screenReaderOptimized,
                onChanged: (value) => accessibility.setScreenReaderOptimized(value),
                theme: theme,
                isDark: isDark,
              ),

              const SizedBox(height: 24),

              // Prévisualisation
              _buildPreviewSection(context, accessibility, theme, isDark),

              const SizedBox(height: 24),

              // Bouton de réinitialisation
              OutlinedButton.icon(
                onPressed: () => _showResetConfirmation(context, accessibility),
                icon: const Icon(Icons.restore),
                label: const Text('Réinitialiser les paramètres'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildColorBlindnessCard(
    BuildContext context,
    AccessibilityProvider accessibility,
    ThemeData theme,
    bool isDark,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.palette,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode daltonien',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Adapte les couleurs à votre vision',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...ColorBlindnessType.values.map((type) {
              final isSelected = accessibility.colorBlindnessType == type;
              return Semantics(
                label: '${AccessibilityService.getColorBlindnessName(type)}: ${AccessibilityService.getColorBlindnessDescription(type)}',
                selected: isSelected,
                child: RadioListTile<ColorBlindnessType>(
                  title: Text(
                    AccessibilityService.getColorBlindnessName(type),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    AccessibilityService.getColorBlindnessDescription(type),
                    style: theme.textTheme.bodySmall,
                  ),
                  value: type,
                  groupValue: accessibility.colorBlindnessType,
                  onChanged: (value) {
                    if (value != null) {
                      accessibility.setColorBlindnessType(value);
                    }
                  },
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFontScaleCard(
    BuildContext context,
    AccessibilityProvider accessibility,
    ThemeData theme,
    bool isDark,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.text_fields,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Taille du texte',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ajustez la taille de police',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${(accessibility.fontScale * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('A', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Semantics(
                    label: 'Curseur de taille de texte, actuellement à ${(accessibility.fontScale * 100).round()}%',
                    child: Slider(
                      value: accessibility.fontScale,
                      min: 0.8,
                      max: 2.0,
                      divisions: 12,
                      activeColor: AppColors.primary,
                      onChanged: (value) => accessibility.setFontScale(value),
                    ),
                  ),
                ),
                const Text('A', style: TextStyle(fontSize: 24)),
              ],
            ),
            const SizedBox(height: 8),
            // Aperçu de la taille
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Aperçu: Ceci est un exemple de texte avec la taille sélectionnée.',
                style: TextStyle(
                  fontSize: 14 * accessibility.fontScale,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Semantics(
        label: '$title: $subtitle. Actuellement ${value ? 'activé' : 'désactivé'}',
        toggled: value,
        child: SwitchListTile(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _buildPreviewSection(
    BuildContext context,
    AccessibilityProvider accessibility,
    ThemeData theme,
    bool isDark,
  ) {
    // Couleurs de test
    final testColors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Prévisualisation des couleurs',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: testColors.map((color) {
                final adaptedColor = accessibility.adaptColor(color);
                return Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: adaptedColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getColorName(color),
                      style: TextStyle(
                        fontSize: 10 * accessibility.fontScale,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            if (accessibility.colorBlindnessType != ColorBlindnessType.none) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Les couleurs sont adaptées pour le mode ${AccessibilityService.getColorBlindnessName(accessibility.colorBlindnessType)}',
                        style: TextStyle(
                          fontSize: 12 * accessibility.fontScale,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getColorName(Color color) {
    if (color == Colors.red) return 'Rouge';
    if (color == Colors.green) return 'Vert';
    if (color == Colors.blue) return 'Bleu';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.purple) return 'Violet';
    return 'Couleur';
  }

  void _showResetConfirmation(BuildContext context, AccessibilityProvider accessibility) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser ?'),
        content: const Text(
          'Tous les paramètres d\'accessibilité seront remis à leurs valeurs par défaut.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              accessibility.resetAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paramètres réinitialisés'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }
}
