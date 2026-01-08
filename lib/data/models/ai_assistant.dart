import 'package:equatable/equatable.dart';

/// Type de message dans le chat
enum MessageType {
  user,
  assistant,
  suggestion,
  alert,
}

/// Message du chat IA
class ChatMessage extends Equatable {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final List<QuickAction>? quickActions;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.metadata,
    this.quickActions,
  });

  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.assistant(String content, {List<QuickAction>? actions}) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.assistant,
      timestamp: DateTime.now(),
      quickActions: actions,
    );
  }

  factory ChatMessage.suggestion(String content, {List<QuickAction>? actions}) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.suggestion,
      timestamp: DateTime.now(),
      quickActions: actions,
    );
  }

  factory ChatMessage.alert(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.alert,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      type: MessageType.values.firstWhere((e) => e.name == json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }

  @override
  List<Object?> get props => [id, content, type, timestamp];
}

/// Action rapide suggérée par l'IA
class QuickAction {
  final String label;
  final String icon;
  final String actionType;
  final Map<String, dynamic>? params;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.actionType,
    this.params,
  });
}

/// Intention détectée dans le message utilisateur
enum UserIntent {
  greeting,
  askBalance,
  askSpending,
  askBudget,
  askSavings,
  askAdvice,
  askCategory,
  askComparison,
  askPrediction,
  askGoal,
  addExpense,
  setBudget,
  createGoal,
  unknown,
}

/// Contexte de conversation pour l'IA
class ConversationContext {
  final List<ChatMessage> recentMessages;
  final UserIntent? lastIntent;
  final String? currentTopic;
  final Map<String, dynamic> userPreferences;

  const ConversationContext({
    this.recentMessages = const [],
    this.lastIntent,
    this.currentTopic,
    this.userPreferences = const {},
  });

  ConversationContext copyWith({
    List<ChatMessage>? recentMessages,
    UserIntent? lastIntent,
    String? currentTopic,
    Map<String, dynamic>? userPreferences,
  }) {
    return ConversationContext(
      recentMessages: recentMessages ?? this.recentMessages,
      lastIntent: lastIntent ?? this.lastIntent,
      currentTopic: currentTopic ?? this.currentTopic,
      userPreferences: userPreferences ?? this.userPreferences,
    );
  }
}

/// Analyse financière pour l'IA
class FinancialSnapshot {
  final double totalSpentThisMonth;
  final double totalSpentToday;
  final double averageDailySpending;
  final double budgetRemaining;
  final double budgetUsedPercentage;
  final String topCategory;
  final double topCategoryAmount;
  final int daysUntilEndOfMonth;
  final double predictedMonthEnd;
  final double savingsGoalProgress;
  final List<String> alerts;
  final List<String> achievements;

  const FinancialSnapshot({
    required this.totalSpentThisMonth,
    required this.totalSpentToday,
    required this.averageDailySpending,
    required this.budgetRemaining,
    required this.budgetUsedPercentage,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.daysUntilEndOfMonth,
    required this.predictedMonthEnd,
    required this.savingsGoalProgress,
    this.alerts = const [],
    this.achievements = const [],
  });
}
