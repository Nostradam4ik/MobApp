import 'package:flutter/material.dart';

/// Couleurs de l'application - Design Premium
class AppColors {
  AppColors._();

  // Couleurs principales - Plus vibrantes
  static const Color primary = Color(0xFF7C3AED);  // Violet vibrant
  static const Color primaryLight = Color(0xFFEDE9FE);
  static const Color primaryDark = Color(0xFF5B21B6);

  static const Color secondary = Color(0xFF06D6A0);  // Vert menthe
  static const Color secondaryLight = Color(0xFFD1FAE5);
  static const Color secondaryDark = Color(0xFF059669);

  // Accent colors
  static const Color accent = Color(0xFFFF6B6B);  // Coral
  static const Color accentBlue = Color(0xFF4CC9F0);  // Cyan vif
  static const Color accentGold = Color(0xFFFFD93D);  // Or
  static const Color accentPink = Color(0xFFFF006E);  // Rose vif

  // Fond - Mode clair
  static const Color background = Color(0xFFF8F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Cards - Utilisés dans toute l'app (adaptés dynamiquement selon le thème)
  static const Color cardBackground = Color(0xFF16161F); // Dark par défaut
  static const Color cardBorder = Color(0xFF2D2D3D);

  // Cards - Mode clair
  static const Color cardBackgroundLight = Color(0xFFFFFFFF);
  static const Color cardBorderLight = Color(0xFFE2E8F0);

  // Fond - Mode sombre - Plus profond et moderne
  static const Color backgroundDark = Color(0xFF0D0D12);
  static const Color surfaceDark = Color(0xFF16161F);
  static const Color surfaceVariantDark = Color(0xFF1E1E2D);

  // Glassmorphism colors
  static const Color glassDark = Color(0x1AFFFFFF);
  static const Color glassLight = Color(0x0DFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Texte - Mode clair
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Texte - Mode sombre
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFA0A0B0);
  static const Color textTertiaryDark = Color(0xFF6B6B7B);

  // États
  static const Color error = Color(0xFFFF4757);
  static const Color errorLight = Color(0xFFFFE4E6);
  static const Color warning = Color(0xFFFFBE0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color success = Color(0xFF06D6A0);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color info = Color(0xFF4CC9F0);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Dividers
  static const Color divider = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF2D2D3D);

  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF7C3AED),
    Color(0xFFA855F7),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF06D6A0),
    Color(0xFF00F5D4),
  ];

  static const List<Color> accentGradient = [
    Color(0xFFFF6B6B),
    Color(0xFFFF8E8E),
  ];

  static const List<Color> premiumGradient = [
    Color(0xFFFFD93D),
    Color(0xFFFF6B6B),
    Color(0xFF7C3AED),
  ];

  static const List<Color> darkCardGradient = [
    Color(0xFF1A1A2E),
    Color(0xFF16213E),
  ];

  // Catégories (couleurs prédéfinies) - Plus vibrantes
  static const List<Color> categoryColors = [
    Color(0xFFFF6B6B), // Rouge coral
    Color(0xFFFFBE0B), // Jaune or
    Color(0xFF06D6A0), // Vert menthe
    Color(0xFF4CC9F0), // Cyan
    Color(0xFF7C3AED), // Violet
    Color(0xFFFF006E), // Rose vif
    Color(0xFF3A86FF), // Bleu
    Color(0xFFFF9F1C), // Orange
    Color(0xFF8338EC), // Purple
    Color(0xFF6B7280), // Gris
  ];

  // Graphiques - Couleurs harmonieuses
  static const List<Color> chartColors = [
    Color(0xFF7C3AED), // Violet
    Color(0xFF06D6A0), // Vert
    Color(0xFFFFBE0B), // Jaune
    Color(0xFFFF6B6B), // Rouge
    Color(0xFF4CC9F0), // Cyan
    Color(0xFFFF006E), // Rose
    Color(0xFF3A86FF), // Bleu
    Color(0xFFFF9F1C), // Orange
  ];

  /// Convertit une couleur hex string en Color
  static Color fromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Convertit une Color en hex string
  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}
