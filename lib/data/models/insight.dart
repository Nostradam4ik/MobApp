import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

/// Modèle d'insight (conseil intelligent)
class Insight extends Equatable {
  final String id;
  final String userId;
  final InsightType insightType;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final bool isDismissed;
  final int priority;
  final DateTime? validUntil;
  final DateTime createdAt;

  const Insight({
    required this.id,
    required this.userId,
    required this.insightType,
    required this.title,
    required this.message,
    this.data,
    this.isRead = false,
    this.isDismissed = false,
    this.priority = 0,
    this.validUntil,
    required this.createdAt,
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      insightType: _parseInsightType(json['insight_type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      isDismissed: json['is_dismissed'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static InsightType _parseInsightType(String type) {
    return InsightType.values.firstWhere(
      (e) => e.value == type,
      orElse: () => InsightType.tip,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'insight_type': insightType.value,
      'title': title,
      'message': message,
      'data': data,
      'is_read': isRead,
      'is_dismissed': isDismissed,
      'priority': priority,
      'valid_until': validUntil?.toIso8601String().split('T')[0],
    };
  }

  Insight copyWith({
    String? id,
    String? userId,
    InsightType? insightType,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    bool? isDismissed,
    int? priority,
    DateTime? validUntil,
    DateTime? createdAt,
  }) {
    return Insight(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      insightType: insightType ?? this.insightType,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
      priority: priority ?? this.priority,
      validUntil: validUntil ?? this.validUntil,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Vérifie si l'insight est encore valide
  bool get isValid {
    if (isDismissed) return false;
    if (validUntil == null) return true;
    return DateTime.now().isBefore(validUntil!);
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        insightType,
        title,
        message,
        data,
        isRead,
        isDismissed,
        priority,
        validUntil,
        createdAt,
      ];
}
