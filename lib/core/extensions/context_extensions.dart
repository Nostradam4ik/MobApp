import 'package:flutter/material.dart';

/// Extensions sur BuildContext
extension ContextExtensions on BuildContext {
  /// Accès au thème
  ThemeData get theme => Theme.of(this);

  /// Accès au color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Accès aux text styles
  TextTheme get textTheme => theme.textTheme;

  /// Accès à MediaQuery
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Largeur de l'écran
  double get screenWidth => mediaQuery.size.width;

  /// Hauteur de l'écran
  double get screenHeight => mediaQuery.size.height;

  /// Padding safe area
  EdgeInsets get safeAreaPadding => mediaQuery.padding;

  /// Vérifie si le mode sombre est actif
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// Affiche un snackbar
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Affiche un snackbar de succès
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }

  /// Affiche un snackbar d'erreur
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.red);
  }

  /// Ferme le clavier
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}
