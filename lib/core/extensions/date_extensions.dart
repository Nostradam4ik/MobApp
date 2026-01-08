/// Extensions sur DateTime
extension DateTimeExtensions on DateTime {
  /// Début de la journée
  DateTime get startOfDay => DateTime(year, month, day);

  /// Fin de la journée
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  /// Début du mois
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Fin du mois
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59);

  /// Début de la semaine (lundi)
  DateTime get startOfWeek {
    final difference = weekday - 1;
    return subtract(Duration(days: difference)).startOfDay;
  }

  /// Fin de la semaine (dimanche)
  DateTime get endOfWeek {
    final difference = 7 - weekday;
    return add(Duration(days: difference)).endOfDay;
  }

  /// Vérifie si c'est aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Vérifie si c'est hier
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Vérifie si c'est ce mois
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Vérifie si c'est cette année
  bool get isThisYear {
    return year == DateTime.now().year;
  }

  /// Vérifie si c'est le même jour qu'une autre date
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Vérifie si c'est le même mois qu'une autre date
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }

  /// Nombre de jours dans le mois
  int get daysInMonth => DateTime(year, month + 1, 0).day;

  /// Jours restants dans le mois
  int get remainingDaysInMonth => daysInMonth - day;

  /// Format ISO date only
  String get isoDateOnly => toIso8601String().split('T')[0];
}
