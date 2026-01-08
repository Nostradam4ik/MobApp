import 'package:equatable/equatable.dart';

/// Fréquence de rappel
enum ReminderFrequency {
  once,      // Une seule fois
  daily,     // Tous les jours
  weekly,    // Chaque semaine
  monthly,   // Chaque mois
  yearly,    // Chaque année
}

extension ReminderFrequencyExtension on ReminderFrequency {
  String get label {
    switch (this) {
      case ReminderFrequency.once:
        return 'Une fois';
      case ReminderFrequency.daily:
        return 'Quotidien';
      case ReminderFrequency.weekly:
        return 'Hebdomadaire';
      case ReminderFrequency.monthly:
        return 'Mensuel';
      case ReminderFrequency.yearly:
        return 'Annuel';
    }
  }

  String get description {
    switch (this) {
      case ReminderFrequency.once:
        return 'Rappel unique';
      case ReminderFrequency.daily:
        return 'Répéter chaque jour';
      case ReminderFrequency.weekly:
        return 'Répéter chaque semaine';
      case ReminderFrequency.monthly:
        return 'Répéter chaque mois';
      case ReminderFrequency.yearly:
        return 'Répéter chaque année';
    }
  }
}

/// Modèle de rappel de facture
class BillReminder extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final double amount;
  final DateTime dueDate;
  final ReminderFrequency frequency;
  final int reminderDaysBefore; // Nombre de jours avant l'échéance pour le rappel
  final bool isActive;
  final bool isPaid;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BillReminder({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.amount,
    required this.dueDate,
    this.frequency = ReminderFrequency.once,
    this.reminderDaysBefore = 3,
    this.isActive = true,
    this.isPaid = false,
    this.categoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Vérifie si la facture est en retard
  bool get isOverdue {
    if (isPaid) return false;
    return DateTime.now().isAfter(dueDate);
  }

  /// Vérifie si le rappel doit être envoyé aujourd'hui
  bool get shouldRemindToday {
    if (!isActive || isPaid) return false;
    final reminderDate = dueDate.subtract(Duration(days: reminderDaysBefore));
    final now = DateTime.now();
    return now.year == reminderDate.year &&
        now.month == reminderDate.month &&
        now.day == reminderDate.day;
  }

  /// Nombre de jours restants avant l'échéance
  int get daysUntilDue {
    final now = DateTime.now();
    return dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  /// Prochaine date d'échéance basée sur la fréquence
  DateTime get nextDueDate {
    if (frequency == ReminderFrequency.once) return dueDate;

    DateTime next = dueDate;
    final now = DateTime.now();

    while (next.isBefore(now)) {
      switch (frequency) {
        case ReminderFrequency.daily:
          next = next.add(const Duration(days: 1));
          break;
        case ReminderFrequency.weekly:
          next = next.add(const Duration(days: 7));
          break;
        case ReminderFrequency.monthly:
          next = DateTime(next.year, next.month + 1, next.day);
          break;
        case ReminderFrequency.yearly:
          next = DateTime(next.year + 1, next.month, next.day);
          break;
        case ReminderFrequency.once:
          break;
      }
    }

    return next;
  }

  BillReminder copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? amount,
    DateTime? dueDate,
    ReminderFrequency? frequency,
    int? reminderDaysBefore,
    bool? isActive,
    bool? isPaid,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BillReminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      frequency: frequency ?? this.frequency,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      isActive: isActive ?? this.isActive,
      isPaid: isPaid ?? this.isPaid,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'frequency': frequency.name,
      'reminder_days_before': reminderDaysBefore,
      'is_active': isActive,
      'is_paid': isPaid,
      'category_id': categoryId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BillReminder.fromJson(Map<String, dynamic> json) {
    return BillReminder(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date'] as String),
      frequency: ReminderFrequency.values.firstWhere(
        (f) => f.name == json['frequency'],
        orElse: () => ReminderFrequency.once,
      ),
      reminderDaysBefore: json['reminder_days_before'] as int? ?? 3,
      isActive: json['is_active'] as bool? ?? true,
      isPaid: json['is_paid'] as bool? ?? false,
      categoryId: json['category_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        amount,
        dueDate,
        frequency,
        reminderDaysBefore,
        isActive,
        isPaid,
        categoryId,
        createdAt,
        updatedAt,
      ];
}
