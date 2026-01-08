import 'package:intl/intl.dart';
import '../config/app_config.dart';

/// Utilitaires de formatage
class Formatters {
  Formatters._();

  /// Format monétaire
  static String currency(double amount, {String? currency}) {
    final format = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: AppConfig.currencySymbols[currency ?? 'EUR'] ?? '€',
    );
    return format.format(amount);
  }

  /// Format monétaire compact
  static String currencyCompact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M€';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k€';
    }
    return currency(amount);
  }

  /// Format date courte (dd/MM)
  static String dateShort(DateTime date) {
    return DateFormat('dd/MM').format(date);
  }

  /// Format date moyenne (dd MMM)
  static String dateMedium(DateTime date) {
    return DateFormat('dd MMM', 'fr_FR').format(date);
  }

  /// Format date complète (dd MMMM yyyy)
  static String dateFull(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
  }

  /// Format mois (MMMM yyyy)
  static String month(DateTime date) {
    return DateFormat('MMMM yyyy', 'fr_FR').format(date);
  }

  /// Format date relative (Aujourd'hui, Hier, etc.)
  static String dateRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Aujourd\'hui';
    } else if (dateOnly == yesterday) {
      return 'Hier';
    } else if (date.year == now.year) {
      return DateFormat('dd MMM', 'fr_FR').format(date);
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format pourcentage
  static String percentage(double value, {int decimals = 0}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format nombre avec séparateurs
  static String number(num value) {
    return NumberFormat.decimalPattern('fr_FR').format(value);
  }
}
