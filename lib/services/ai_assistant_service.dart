import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/ai_assistant.dart';
import '../data/models/expense.dart';
import '../data/models/budget.dart';
import '../data/models/goal.dart';
import 'ai_knowledge_base.dart';
import 'ai_nlp_engine.dart';

/// Service d'Assistant IA local - 100% privé, aucune donnée envoyée à l'extérieur
/// Version 2.0 avec NLP avancé, clarification, détection d'anomalies et templates structurés
class AIAssistantService {
  static const String _historyKey = 'ai_chat_history';
  static const String _memoryKey = 'ai_memory';
  static const String _anomalyKey = 'ai_anomaly_history';
  static SharedPreferences? _prefs;
  static List<ChatMessage> _history = [];
  static ConversationContext _context = const ConversationContext();
  static final ConversationMemory _memory = ConversationMemory();
  static List<SpendingAnomaly> _recentAnomalies = [];

  /// Initialise le service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadHistory();
    await _loadAnomalies();
  }

  /// Charge l'historique des conversations
  static Future<void> _loadHistory() async {
    final data = _prefs?.getString(_historyKey);
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      _history = jsonList.map((j) => ChatMessage.fromJson(j)).toList();
      if (_history.length > 50) {
        _history = _history.sublist(_history.length - 50);
      }
    }
  }

  /// Charge l'historique des anomalies
  static Future<void> _loadAnomalies() async {
    final data = _prefs?.getString(_anomalyKey);
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      _recentAnomalies = jsonList.map((j) => SpendingAnomaly.fromJson(j)).toList();
    }
  }

  /// Sauvegarde l'historique
  static Future<void> _saveHistory() async {
    final data = jsonEncode(_history.map((m) => m.toJson()).toList());
    await _prefs?.setString(_historyKey, data);
  }

  /// Sauvegarde les anomalies
  static Future<void> _saveAnomalies() async {
    final data = jsonEncode(_recentAnomalies.map((a) => a.toJson()).toList());
    await _prefs?.setString(_anomalyKey, data);
  }

  /// Obtient l'historique des messages
  static List<ChatMessage> getHistory() => List.unmodifiable(_history);

  /// Efface l'historique
  static Future<void> clearHistory() async {
    _history.clear();
    _context = const ConversationContext();
    _memory.clear();
    await _prefs?.remove(_historyKey);
  }

  /// Génère le message de bienvenue personnalisé
  static ChatMessage getWelcomeMessage() {
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;

    if (hour >= 5 && hour < 12) {
      greeting = 'Bonjour';
      emoji = '☀️';
    } else if (hour >= 12 && hour < 18) {
      greeting = 'Bon après-midi';
      emoji = '🌤️';
    } else if (hour >= 18 && hour < 22) {
      greeting = 'Bonsoir';
      emoji = '🌆';
    } else {
      greeting = 'Bonne nuit';
      emoji = '🌙';
    }

    return ChatMessage.assistant(
      '$greeting ! $emoji\n\n'
      'Je suis **SmartSpend AI**, votre assistant financier personnel.\n\n'
      'Je suis 100% local - vos données ne quittent jamais votre appareil ! 🔒\n\n'
      '**Je peux vous aider à :**\n'
      '• 💰 Analyser vos dépenses en détail\n'
      '• 📊 Suivre votre budget en temps réel\n'
      '• 🎯 Atteindre vos objectifs d\'épargne\n'
      '• 💡 Vous donner des conseils personnalisés\n'
      '• 🔮 Prédire vos dépenses de fin de mois\n'
      '• 🚨 Détecter les anomalies de dépenses\n\n'
      'Posez-moi une question ou choisissez une option ci-dessous !',
      actions: [
        const QuickAction(label: 'Mon résumé', icon: '📊', actionType: 'summary'),
        const QuickAction(label: 'Mes dépenses', icon: '💸', actionType: 'spending'),
        const QuickAction(label: 'Conseils', icon: '💡', actionType: 'advice'),
        const QuickAction(label: 'Prédiction', icon: '🔮', actionType: 'prediction'),
      ],
    );
  }

  /// Traite un message utilisateur et génère une réponse intelligente
  static Future<ChatMessage> processMessage(
    String userMessage, {
    required List<Expense> expenses,
    required List<Budget> budgets,
    required List<Goal> goals,
  }) async {
    // Ajouter le message utilisateur
    final userMsg = ChatMessage.user(userMessage);
    _history.add(userMsg);

    // Analyser avec le moteur NLP amélioré
    final analysis = AINLPEngine.analyzeMessage(userMessage);
    final intent = analysis.intent;
    final confidence = analysis.confidence;
    final entities = analysis.entities;
    final clarificationOptions = analysis.clarificationOptions;
    final detectedExpression = analysis.detectedExpression;

    // Mémoriser l'intention avec les entités
    _memory.addIntent(intent, entities: entities);

    // Créer le snapshot financier
    final snapshot = _createDetailedSnapshot(expenses, budgets, goals);

    // Détecter les anomalies de dépenses
    final anomalies = _detectSpendingAnomalies(expenses, snapshot);
    if (anomalies.isNotEmpty) {
      _recentAnomalies.addAll(anomalies);
      await _saveAnomalies();
    }

    // Vérifier si une clarification est nécessaire
    if (clarificationOptions != null && clarificationOptions.isNotEmpty && confidence < 0.5) {
      final response = _handleClarification(clarificationOptions, userMessage);
      _history.add(response);
      await _saveHistory();
      return response;
    }

    // Générer la réponse appropriée
    final response = await _generateSmartResponse(
      intent: intent,
      confidence: confidence,
      entities: entities,
      userMessage: userMessage,
      snapshot: snapshot,
      expenses: expenses,
      budgets: budgets,
      goals: goals,
      anomalies: anomalies,
      detectedExpression: detectedExpression,
    );

    // Ajouter à l'historique
    _history.add(response);

    // Mettre à jour le contexte
    _context = _context.copyWith(
      recentMessages: _history.length > 10
          ? _history.sublist(_history.length - 10)
          : _history,
      lastIntent: _intentFromString(intent),
    );

    await _saveHistory();
    return response;
  }

  // ==================== DÉTECTION D'ANOMALIES ====================

  /// Détecte les anomalies dans les dépenses
  static List<SpendingAnomaly> _detectSpendingAnomalies(
    List<Expense> expenses,
    FinancialSnapshot snapshot,
  ) {
    final anomalies = <SpendingAnomaly>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Dépenses d'aujourd'hui
    final todayExpenses = expenses.where((e) =>
        e.expenseDate.year == today.year &&
        e.expenseDate.month == today.month &&
        e.expenseDate.day == today.day);

    final todayTotal = todayExpenses.fold(0.0, (sum, e) => sum + e.amount);

    // Dépenses d'hier
    final yesterdayExpenses = expenses.where((e) =>
        e.expenseDate.year == yesterday.year &&
        e.expenseDate.month == yesterday.month &&
        e.expenseDate.day == yesterday.day);

    final yesterdayTotal = yesterdayExpenses.fold(0.0, (sum, e) => sum + e.amount);

    // Anomalie: pic de dépenses (>50% de plus que la moyenne)
    if (todayTotal > snapshot.averageDailySpending * 1.5 && todayTotal > 20) {
      anomalies.add(SpendingAnomaly(
        type: AnomalyType.spike,
        amount: todayTotal,
        expectedAmount: snapshot.averageDailySpending,
        date: today,
        description: 'Pic de dépenses aujourd\'hui (+${((todayTotal / snapshot.averageDailySpending - 1) * 100).toStringAsFixed(0)}% vs moyenne)',
        severity: todayTotal > snapshot.averageDailySpending * 2 ? 'high' : 'medium',
      ));
    }

    // Anomalie: augmentation soudaine jour à jour (>100% de plus qu'hier)
    if (yesterdayTotal > 0 && todayTotal > yesterdayTotal * 2 && todayTotal > 30) {
      anomalies.add(SpendingAnomaly(
        type: AnomalyType.suddenIncrease,
        amount: todayTotal,
        expectedAmount: yesterdayTotal,
        date: today,
        description: 'Augmentation soudaine par rapport à hier',
        severity: 'medium',
      ));
    }

    // Anomalie: dépense inhabituelle (une seule dépense très élevée)
    for (final expense in todayExpenses) {
      if (expense.amount > snapshot.averageDailySpending * 2 && expense.amount > 50) {
        anomalies.add(SpendingAnomaly(
          type: AnomalyType.unusualExpense,
          amount: expense.amount,
          expectedAmount: snapshot.averageDailySpending,
          date: today,
          category: expense.category?.name,
          description: 'Dépense inhabituelle: ${expense.amount.toStringAsFixed(2)}€ (${expense.category?.name ?? "Autre"})',
          severity: expense.amount > snapshot.averageDailySpending * 3 ? 'high' : 'medium',
        ));
      }
    }

    // Anomalie: catégorie en explosion
    final categoryTotals = <String, List<double>>{};
    final last7Days = today.subtract(const Duration(days: 7));

    for (final expense in expenses.where((e) => e.expenseDate.isAfter(last7Days))) {
      final cat = expense.category?.name ?? 'Autre';
      categoryTotals[cat] ??= [];
      categoryTotals[cat]!.add(expense.amount);
    }

    for (final entry in categoryTotals.entries) {
      if (entry.value.length >= 3) {
        final avg = entry.value.sublist(0, entry.value.length - 1)
            .fold(0.0, (sum, v) => sum + v) / (entry.value.length - 1);
        final latest = entry.value.last;

        if (latest > avg * 2 && latest > 30) {
          anomalies.add(SpendingAnomaly(
            type: AnomalyType.categorySpike,
            amount: latest,
            expectedAmount: avg,
            date: today,
            category: entry.key,
            description: 'Catégorie "${entry.key}" en hausse inhabituelle',
            severity: 'low',
          ));
        }
      }
    }

    return anomalies;
  }

  // ==================== SYSTÈME DE CLARIFICATION ====================

  /// Génère un message de clarification
  static ChatMessage _handleClarification(List<String> options, String originalMessage) {
    final buffer = StringBuffer();
    buffer.writeln('🤔 Je ne suis pas sûr de comprendre exactement votre demande.\n');
    buffer.writeln('Vouliez-vous dire :\n');

    for (var i = 0; i < options.length; i++) {
      buffer.writeln('${i + 1}. ${options[i]}');
    }

    buffer.writeln('\nChoisissez une option ou reformulez votre question.');

    return ChatMessage.assistant(
      buffer.toString(),
      actions: options.take(4).map((opt) => QuickAction(
        label: opt.length > 20 ? '${opt.substring(0, 18)}...' : opt,
        icon: _getIconForOption(opt),
        actionType: _getActionTypeForOption(opt),
      )).toList(),
    );
  }

  static String _getIconForOption(String option) {
    if (option.contains('dépense')) return '💸';
    if (option.contains('budget')) return '📊';
    if (option.contains('épargne') || option.contains('objectif')) return '🎯';
    if (option.contains('conseil')) return '💡';
    if (option.contains('catégorie')) return '📂';
    if (option.contains('prédiction')) return '🔮';
    return '📋';
  }

  static String _getActionTypeForOption(String option) {
    if (option.contains('dépense')) return 'spending';
    if (option.contains('budget')) return 'budget';
    if (option.contains('solde') || option.contains('reste')) return 'balance';
    if (option.contains('épargne') || option.contains('objectif')) return 'savings';
    if (option.contains('conseil')) return 'advice';
    if (option.contains('catégorie')) return 'category';
    if (option.contains('prédiction')) return 'prediction';
    if (option.contains('aide') || option.contains('utiliser')) return 'help';
    return 'summary';
  }

  /// Crée un snapshot financier détaillé
  static FinancialSnapshot _createDetailedSnapshot(
    List<Expense> expenses,
    List<Budget> budgets,
    List<Goal> goals,
  ) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    // Dépenses du mois
    final monthExpenses = expenses.where((e) =>
        e.expenseDate.isAfter(startOfMonth.subtract(const Duration(days: 1))));
    final totalSpentThisMonth = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);

    // Dépenses du jour
    final todayExpenses = expenses.where((e) =>
        e.expenseDate.year == now.year &&
        e.expenseDate.month == now.month &&
        e.expenseDate.day == now.day);
    final totalSpentToday = todayExpenses.fold(0.0, (sum, e) => sum + e.amount);

    // Dépenses de la semaine
    final weekExpenses = expenses.where((e) =>
        e.expenseDate.isAfter(startOfWeek.subtract(const Duration(days: 1))));
    final totalSpentThisWeek = weekExpenses.fold(0.0, (sum, e) => sum + e.amount);

    // Moyenne quotidienne
    final daysElapsed = now.day;
    final averageDaily = daysElapsed > 0 ? totalSpentThisMonth / daysElapsed : 0.0;

    // Budget
    final totalBudget = budgets.fold(0.0, (sum, b) => sum + b.monthlyLimit);
    final budgetRemaining = totalBudget - totalSpentThisMonth;
    final budgetUsedPercentage = totalBudget > 0
        ? (totalSpentThisMonth / totalBudget * 100)
        : 0.0;

    // Catégories
    final categoryTotals = <String, double>{};
    for (final expense in monthExpenses) {
      final cat = expense.category?.name ?? 'Autre';
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + expense.amount;
    }

    String topCategory = 'Aucune';
    double topCategoryAmount = 0;
    if (categoryTotals.isNotEmpty) {
      final sorted = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topCategory = sorted.first.key;
      topCategoryAmount = sorted.first.value;
    }

    // Jours restants et prédiction
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysRemaining = endOfMonth.day - now.day;
    final predictedMonthEnd = totalSpentThisMonth + (averageDaily * daysRemaining);

    // Progression épargne
    final savingsProgress = goals.isEmpty
        ? 0.0
        : goals.map((g) => (g.currentAmount / g.targetAmount).clamp(0.0, 1.0))
            .reduce((a, b) => a + b) / goals.length * 100;

    // Alertes intelligentes
    final alerts = _generateSmartAlerts(
      budgetUsedPercentage: budgetUsedPercentage,
      averageDaily: averageDaily,
      totalBudget: totalBudget,
      daysRemaining: daysRemaining,
      topCategory: topCategory,
      topCategoryAmount: topCategoryAmount,
      totalSpentThisMonth: totalSpentThisMonth,
    );

    return FinancialSnapshot(
      totalSpentThisMonth: totalSpentThisMonth,
      totalSpentToday: totalSpentToday,
      averageDailySpending: averageDaily,
      budgetRemaining: budgetRemaining,
      budgetUsedPercentage: budgetUsedPercentage,
      topCategory: topCategory,
      topCategoryAmount: topCategoryAmount,
      daysUntilEndOfMonth: daysRemaining,
      predictedMonthEnd: predictedMonthEnd,
      savingsGoalProgress: savingsProgress,
      alerts: alerts,
    );
  }

  /// Génère des alertes intelligentes
  static List<String> _generateSmartAlerts({
    required double budgetUsedPercentage,
    required double averageDaily,
    required double totalBudget,
    required int daysRemaining,
    required String topCategory,
    required double topCategoryAmount,
    required double totalSpentThisMonth,
  }) {
    final alerts = <String>[];
    final dayOfMonth = DateTime.now().day;
    final expectedPercent = (dayOfMonth / 30) * 100;

    // Alerte budget
    if (budgetUsedPercentage > 100) {
      alerts.add('🚨 Budget dépassé de ${(budgetUsedPercentage - 100).toStringAsFixed(0)}% !');
    } else if (budgetUsedPercentage > 90) {
      alerts.add('⚠️ Budget presque épuisé (${budgetUsedPercentage.toStringAsFixed(0)}%)');
    } else if (budgetUsedPercentage > expectedPercent + 15) {
      alerts.add('📈 Dépenses plus rapides que prévu');
    }

    // Alerte catégorie dominante
    if (totalSpentThisMonth > 0 && topCategoryAmount / totalSpentThisMonth > 0.5) {
      alerts.add('📊 "$topCategory" représente plus de 50% des dépenses');
    }

    // Alerte moyenne quotidienne
    final recommendedDaily = totalBudget > 0 ? totalBudget / 30 : 0;
    if (recommendedDaily > 0 && averageDaily > recommendedDaily * 1.3) {
      alerts.add('💸 Moyenne quotidienne élevée');
    }

    return alerts;
  }

  /// Génère une réponse intelligente basée sur l'analyse
  static Future<ChatMessage> _generateSmartResponse({
    required String intent,
    required double confidence,
    required Map<String, dynamic> entities,
    required String userMessage,
    required FinancialSnapshot snapshot,
    required List<Expense> expenses,
    required List<Budget> budgets,
    required List<Goal> goals,
    required List<SpendingAnomaly> anomalies,
    String? detectedExpression,
  }) async {
    // Simuler un temps de réflexion
    await Future.delayed(Duration(milliseconds: 300 + Random().nextInt(400)));

    // Détecter si l'utilisateur répète sa question
    final isRepeating = _memory.isRepeatingQuestion(intent);

    // Récupérer le sentiment et l'urgence
    final sentiment = entities['sentiment'] as String? ?? 'neutral';
    final urgency = entities['urgency'] as String? ?? 'normal';

    // Si urgence détectée, adapter le ton
    String urgencyPrefix = '';
    if (urgency == 'urgent') {
      urgencyPrefix = '⚡ Je comprends l\'urgence. ';
    }

    // Gérer les différentes intentions
    ChatMessage response;

    switch (intent) {
      case 'greeting':
        response = _handleGreeting(snapshot, entities, anomalies);
        break;

      case 'balance':
        response = _handleBalance(snapshot, budgets, isRepeating);
        break;

      case 'spending':
      case 'spending_today':
      case 'spending_week':
      case 'spending_month':
        response = _handleSpending(intent, snapshot, expenses, entities);
        break;

      case 'budget':
        response = _handleBudget(snapshot, budgets);
        break;

      case 'savings':
        response = _handleSavings(snapshot, goals);
        break;

      case 'advice':
        response = _handleAdvice(snapshot, expenses, budgets, goals, sentiment);
        break;

      case 'category':
        response = _handleCategory(snapshot, expenses, entities);
        break;

      case 'comparison':
        response = _handleComparison(snapshot, expenses);
        break;

      case 'prediction':
        response = _handlePrediction(snapshot, budgets);
        break;

      case 'goal':
        response = _handleGoal(goals, snapshot);
        break;

      case 'thank':
        response = _handleThanks();
        break;

      case 'problem':
        response = _handleProblem(snapshot, expenses, budgets, sentiment);
        break;

      case 'help':
        response = _handleHelp();
        break;

      default:
        response = _handleUnknown(snapshot, userMessage, confidence, anomalies);
    }

    // Ajouter le préfixe d'urgence si nécessaire
    if (urgencyPrefix.isNotEmpty && intent != 'greeting' && intent != 'thank') {
      return ChatMessage.assistant(
        urgencyPrefix + response.content,
        actions: response.quickActions,
      );
    }

    return response;
  }

  // ==================== TEMPLATES DE RÉPONSES STRUCTURÉS ====================

  static ChatMessage _handleGreeting(
    FinancialSnapshot snapshot,
    Map<String, dynamic> entities,
    List<SpendingAnomaly> anomalies,
  ) {
    final sentiment = entities['sentiment'] as String? ?? 'neutral';
    final response = AIKnowledgeBase.greetingResponses[
        Random().nextInt(AIKnowledgeBase.greetingResponses.length)];

    final buffer = StringBuffer(response);

    // Ajouter les anomalies détectées
    if (anomalies.isNotEmpty) {
      buffer.writeln('\n\n🚨 **Alerte détectée :**');
      buffer.writeln(anomalies.first.description);
    }
    // Ou un contexte financier positif
    else if (snapshot.alerts.isNotEmpty) {
      buffer.writeln('\n\n${snapshot.alerts.first}');
    } else if (snapshot.budgetUsedPercentage < 50) {
      buffer.writeln('\n\n✨ Bonne nouvelle : vous gérez bien votre budget ce mois-ci !');
    }

    // Adapter selon le sentiment
    if (sentiment == 'worried' || sentiment == 'concerned') {
      buffer.writeln('\n\nJe vois que quelque chose vous préoccupe. Comment puis-je vous aider ?');
    }

    return ChatMessage.assistant(
      buffer.toString(),
      actions: [
        const QuickAction(label: 'Mon résumé', icon: '📊', actionType: 'summary'),
        const QuickAction(label: 'Conseils', icon: '💡', actionType: 'advice'),
        if (anomalies.isNotEmpty)
          const QuickAction(label: 'Voir l\'alerte', icon: '🚨', actionType: 'anomaly'),
      ],
    );
  }

  static ChatMessage _handleBalance(FinancialSnapshot snapshot, List<Budget> budgets, bool isRepeating) {
    final remaining = snapshot.budgetRemaining;
    final daysLeft = snapshot.daysUntilEndOfMonth;
    final dailyAllowance = AIKnowledgeBase.calculateDailyAllowance(remaining, daysLeft);

    if (budgets.isEmpty) {
      return ChatMessage.assistant(
        _buildResponseTemplate(
          emoji: '📋',
          title: 'Pas de budget défini',
          content: 'Sans budget, il est difficile de savoir combien vous pouvez dépenser.',
          details: AIKnowledgeBase.situationalAdvice['no_budget']!,
          advice: 'Créez un budget pour mieux gérer vos finances.',
        ),
        actions: [
          const QuickAction(label: 'Mes dépenses', icon: '💸', actionType: 'spending'),
        ],
      );
    }

    String status;
    String emoji;
    String advice;
    String healthIcon;

    if (remaining > 0) {
      if (remaining > dailyAllowance * 10) {
        emoji = '✅';
        healthIcon = '💚';
        status = 'Situation confortable';
        advice = 'Vous avez une bonne marge de manœuvre ! Pensez à épargner le surplus.';
      } else if (remaining > dailyAllowance * 5) {
        emoji = '👍';
        healthIcon = '💛';
        status = 'Situation correcte';
        advice = 'Continuez sur cette lancée, restez vigilant.';
      } else {
        emoji = '⚠️';
        healthIcon = '🧡';
        status = 'Attention requise';
        advice = 'Il faut faire attention les prochains jours.';
      }
    } else {
      emoji = '🚨';
      healthIcon = '❤️';
      status = 'Budget dépassé';
      advice = 'Évitez les dépenses non essentielles jusqu\'à la fin du mois.';
    }

    final buffer = StringBuffer();
    buffer.writeln('$emoji **$status**\n');
    buffer.writeln('$healthIcon Il vous reste **${remaining.toStringAsFixed(2)}€** sur votre budget.\n');
    buffer.writeln('📅 **${daysLeft}** jours restants ce mois');
    buffer.writeln('💵 Budget quotidien conseillé : **${dailyAllowance.toStringAsFixed(2)}€/jour**\n');
    buffer.writeln('💡 $advice');

    // Si l'utilisateur répète la question, ajouter plus de détails
    if (isRepeating) {
      buffer.writeln('\n\n📊 **Plus de détails :**');
      buffer.writeln('• Dépensé ce mois : ${snapshot.totalSpentThisMonth.toStringAsFixed(2)}€');
      buffer.writeln('• Moyenne quotidienne : ${snapshot.averageDailySpending.toStringAsFixed(2)}€');
      buffer.writeln('• Prédiction fin de mois : ${snapshot.predictedMonthEnd.toStringAsFixed(2)}€');
    }

    return ChatMessage.assistant(
      buffer.toString(),
      actions: [
        const QuickAction(label: 'Détails', icon: '📊', actionType: 'spending'),
        const QuickAction(label: 'Économiser', icon: '💡', actionType: 'advice'),
      ],
    );
  }

  static ChatMessage _handleSpending(
    String intent,
    FinancialSnapshot snapshot,
    List<Expense> expenses,
    Map<String, dynamic> entities,
  ) {
    final period = entities['period'] as String? ?? _getPeriodFromIntent(intent);
    final category = entities['category'] as String?;

    String title;
    double amount;
    String comparison = '';
    String emoji = '💰';

    switch (period) {
      case 'today':
      case 'spending_today':
        title = 'Aujourd\'hui';
        amount = snapshot.totalSpentToday;
        if (snapshot.averageDailySpending > 0) {
          final diff = ((amount / snapshot.averageDailySpending - 1) * 100);
          if (diff > 10) {
            comparison = '📈 +${diff.toStringAsFixed(0)}% vs moyenne';
            emoji = '⚠️';
          } else if (diff < -10) {
            comparison = '📉 ${diff.toStringAsFixed(0)}% vs moyenne';
            emoji = '✅';
          } else {
            comparison = '➡️ Dans la moyenne';
          }
        }
        break;
      case 'yesterday':
        title = 'Hier';
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        amount = expenses.where((e) =>
            e.expenseDate.year == yesterday.year &&
            e.expenseDate.month == yesterday.month &&
            e.expenseDate.day == yesterday.day)
            .fold(0.0, (sum, e) => sum + e.amount);
        break;
      case 'week':
      case 'spending_week':
        title = 'Cette semaine';
        final startOfWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
        amount = expenses.where((e) => e.expenseDate.isAfter(startOfWeek.subtract(const Duration(days: 1))))
            .fold(0.0, (sum, e) => sum + e.amount);
        break;
      case 'last_week':
        title = 'La semaine dernière';
        final startOfLastWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday + 6));
        final endOfLastWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday));
        amount = expenses.where((e) =>
            e.expenseDate.isAfter(startOfLastWeek.subtract(const Duration(days: 1))) &&
            e.expenseDate.isBefore(endOfLastWeek.add(const Duration(days: 1))))
            .fold(0.0, (sum, e) => sum + e.amount);
        break;
      case 'last_month':
        title = 'Le mois dernier';
        final lastMonth = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
        final endOfLastMonth = DateTime(DateTime.now().year, DateTime.now().month, 0);
        amount = expenses.where((e) =>
            e.expenseDate.isAfter(lastMonth.subtract(const Duration(days: 1))) &&
            e.expenseDate.isBefore(endOfLastMonth.add(const Duration(days: 1))))
            .fold(0.0, (sum, e) => sum + e.amount);
        break;
      default:
        title = 'Ce mois';
        amount = snapshot.totalSpentThisMonth;
    }

    // Filtrer par catégorie si demandé
    if (category != null) {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final categoryExpenses = expenses.where((e) =>
          e.expenseDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          e.category?.name?.toLowerCase() == category.toLowerCase());
      amount = categoryExpenses.fold(0.0, (sum, e) => sum + e.amount);
      title = 'Catégorie "$category"';
      emoji = '📂';
    }

    final buffer = StringBuffer();
    buffer.writeln('$emoji **Dépenses - $title**\n');
    buffer.writeln('💵 Total : **${amount.toStringAsFixed(2)}€**');
    if (comparison.isNotEmpty) {
      buffer.writeln('$comparison');
    }

    if (period != 'today' && period != 'yesterday' && category == null) {
      buffer.writeln('\n📊 **Statistiques du mois :**');
      buffer.writeln('• Total : ${snapshot.totalSpentThisMonth.toStringAsFixed(2)}€');
      buffer.writeln('• Moyenne/jour : ${snapshot.averageDailySpending.toStringAsFixed(2)}€');
      buffer.writeln('• Top catégorie : ${snapshot.topCategory} (${snapshot.topCategoryAmount.toStringAsFixed(2)}€)');
    }

    // Ajouter un conseil contextuel
    buffer.writeln('\n${_getSpendingAdvice(snapshot)}');

    return ChatMessage.assistant(
      buffer.toString(),
      actions: [
        const QuickAction(label: 'Par catégorie', icon: '📂', actionType: 'category'),
        const QuickAction(label: 'Comparer', icon: '📈', actionType: 'comparison'),
        const QuickAction(label: 'Prédiction', icon: '🔮', actionType: 'prediction'),
      ],
    );
  }

  static String _getPeriodFromIntent(String intent) {
    switch (intent) {
      case 'spending_today': return 'today';
      case 'spending_week': return 'week';
      case 'spending_month': return 'month';
      default: return 'month';
    }
  }

  static String _getSpendingAdvice(FinancialSnapshot snapshot) {
    final dayOfMonth = DateTime.now().day;
    final expectedPercent = (dayOfMonth / 30) * 100;

    if (snapshot.budgetUsedPercentage < expectedPercent - 10) {
      return '💚 Excellent ! Vous dépensez moins vite que prévu. Profitez-en pour épargner !';
    } else if (snapshot.budgetUsedPercentage < expectedPercent + 10) {
      return '👍 Bon rythme ! Vous êtes dans les temps pour respecter votre budget.';
    } else if (snapshot.budgetUsedPercentage < 100) {
      return '⚡ Attention ! Vous dépensez plus vite que prévu. Ralentissez un peu.';
    } else {
      return '🚨 Budget dépassé ! Limitez-vous aux dépenses essentielles.';
    }
  }

  static ChatMessage _handleBudget(FinancialSnapshot snapshot, List<Budget> budgets) {
    if (budgets.isEmpty) {
      return ChatMessage.assistant(
        _buildResponseTemplate(
          emoji: '📋',
          title: 'Aucun budget défini',
          content: 'Créer un budget est la première étape vers une meilleure gestion financière.',
          details: AIKnowledgeBase.situationalAdvice['no_budget']!,
          advice: 'Commencez par noter vos revenus et définir une limite réaliste.',
        ),
        actions: [
          const QuickAction(label: 'Mes dépenses', icon: '💸', actionType: 'spending'),
        ],
      );
    }

    final used = snapshot.budgetUsedPercentage;
    final remaining = snapshot.budgetRemaining;
    final totalBudget = remaining + snapshot.totalSpentThisMonth;

    // Barre de progression visuelle
    final progressBar = _createProgressBar(used / 100);

    String status;
    String statusEmoji;
    List<String> adviceList;

    if (used < 80) {
      status = 'En bonne voie';
      statusEmoji = '✅';
      adviceList = AIKnowledgeBase.situationalAdvice['budget_good']!;
    } else if (used < 100) {
      status = 'Attention';
      statusEmoji = '⚠️';
      adviceList = AIKnowledgeBase.situationalAdvice['budget_warning']!;
    } else {
      status = 'Dépassé';
      statusEmoji = '🚨';
      adviceList = AIKnowledgeBase.situationalAdvice['budget_exceeded']!;
    }

    final buffer = StringBuffer();
    buffer.writeln('📊 **État de votre budget** - $statusEmoji $status\n');
    buffer.writeln('$progressBar **${used.toStringAsFixed(0)}%**\n');
    buffer.writeln('💰 Budget total : **${totalBudget.toStringAsFixed(2)}€**');
    buffer.writeln('📤 Dépensé : **${snapshot.totalSpentThisMonth.toStringAsFixed(2)}€**');
    buffer.writeln('💵 Reste : **${remaining.toStringAsFixed(2)}€**');
    buffer.writeln('📅 Jours restants : **${snapshot.daysUntilEndOfMonth}**\n');
    buffer.writeln(adviceList.join('\n'));

    return ChatMessage.assistant(
      buffer.toString(),
      actions: [
        const QuickAction(label: 'Détails', icon: '📂', actionType: 'category'),
        const QuickAction(label: 'Conseils', icon: '💡', actionType: 'advice'),
      ],
    );
  }

  static String _createProgressBar(double ratio) {
    final filled = (ratio * 10).round().clamp(0, 10);
    final empty = 10 - filled;
    return '[${'█' * filled}${'░' * empty}]';
  }

  static ChatMessage _handleSavings(FinancialSnapshot snapshot, List<Goal> goals) {
    if (goals.isEmpty) {
      return ChatMessage.assistant(
        _buildResponseTemplate(
          emoji: '🎯',
          title: 'Objectifs d\'épargne',
          content: 'Vous n\'avez pas encore défini d\'objectif d\'épargne.',
          details: AIKnowledgeBase.situationalAdvice['no_goals']!,
          advice: 'Commencez par un petit objectif réalisable pour rester motivé !',
        ),
        actions: [
          const QuickAction(label: 'Conseils épargne', icon: '💡', actionType: 'advice'),
        ],
      );
    }

    final buffer = StringBuffer('🐷 **Vos objectifs d\'épargne**\n\n');

    for (final goal in goals.take(5)) {
      final progress = (goal.currentAmount / goal.targetAmount * 100).clamp(0, 100);
      final remaining = goal.targetAmount - goal.currentAmount;
      final progressBar = _createProgressBar(progress / 100);

      buffer.writeln('**${goal.title}**');
      buffer.writeln('$progressBar ${progress.toStringAsFixed(0)}%');
      buffer.writeln('${goal.currentAmount.toStringAsFixed(0)}€ / ${goal.targetAmount.toStringAsFixed(0)}€');

      if (remaining > 0) {
        buffer.writeln('Reste : ${remaining.toStringAsFixed(0)}€');
      } else {
        buffer.writeln('✅ Objectif atteint !');
      }
      buffer.writeln('');
    }

    // Ajouter un conseil d'épargne
    final tip = AIKnowledgeBase.savingsTips[Random().nextInt(AIKnowledgeBase.savingsTips.length)];
    buffer.writeln('$tip');

    return ChatMessage.assistant(buffer.toString());
  }

  static ChatMessage _handleAdvice(
    FinancialSnapshot snapshot,
    List<Expense> expenses,
    List<Budget> budgets,
    List<Goal> goals,
    String sentiment,
  ) {
    final recommendations = AIKnowledgeBase.getHealthRecommendations(
      budgetUsedPercent: snapshot.budgetUsedPercentage,
      savingsRate: AIKnowledgeBase.calculateSavingsRate(
        budgets.fold(0.0, (sum, b) => sum + b.monthlyLimit),
        snapshot.totalSpentThisMonth,
      ),
      dayOfMonth: DateTime.now().day,
      hasGoals: goals.isNotEmpty,
      hasBudget: budgets.isNotEmpty,
    );

    final buffer = StringBuffer();

    // Adapter le ton selon le sentiment
    if (sentiment == 'worried' || sentiment == 'concerned') {
      buffer.writeln('🤗 **Ne vous inquiétez pas, voici comment améliorer votre situation :**\n');
    } else if (sentiment == 'happy' || sentiment == 'positive') {
      buffer.writeln('💡 **Excellent ! Voici comment aller encore plus loin :**\n');
    } else {
      buffer.writeln('💡 **Conseils personnalisés pour vous**\n');
    }

    // Ajouter les recommandations principales
    for (final rec in recommendations.take(3)) {
      buffer.writeln('$rec\n');
    }

    // Ajouter un conseil de catégorie si pertinent
    if (snapshot.topCategory != 'Aucune' &&
        AIKnowledgeBase.categoryTips.containsKey(snapshot.topCategory)) {
      buffer.writeln('📂 **Conseils pour "${snapshot.topCategory}"** :');
      final tips = AIKnowledgeBase.categoryTips[snapshot.topCategory]!;
      for (final tip in tips.take(2)) {
        buffer.writeln('$tip');
      }
      buffer.writeln('');
    }

    // Message motivationnel
    buffer.writeln(AIKnowledgeBase.getRandomMotivation());

    return ChatMessage.assistant(
      buffer.toString(),
      actions: [
        const QuickAction(label: 'Plus de conseils', icon: '📚', actionType: 'more_advice'),
        const QuickAction(label: 'Mon budget', icon: '📊', actionType: 'budget'),
      ],
    );
  }

  static ChatMessage _handleCategory(
    FinancialSnapshot snapshot,
    List<Expense> expenses,
    Map<String, dynamic> entities,
  ) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final monthExpenses = expenses.where((e) =>
        e.expenseDate.isAfter(startOfMonth.subtract(const Duration(days: 1))));

    final categoryTotals = <String, double>{};
    for (final expense in monthExpenses) {
      final cat = expense.category?.name ?? 'Autre';
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + expense.amount;
    }

    if (categoryTotals.isEmpty) {
      return ChatMessage.assistant(
        '📂 Aucune dépense enregistrée ce mois-ci.\n\n'
        'Commencez à enregistrer vos dépenses pour voir la répartition !',
      );
    }

    // Si une catégorie spécifique est demandée
    final requestedCategory = entities['category'] as String?;
    if (requestedCategory != null) {
      return _handleSpecificCategory(requestedCategory, expenses, snapshot);
    }

    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buffer = StringBuffer('📂 **Répartition par catégorie**\n\n');

    final icons = ['🥇', '🥈', '🥉', '4️⃣', '5️⃣', '6️⃣', '7️⃣'];
    final total = snapshot.totalSpentThisMonth;

    for (var i = 0; i < min(sorted.length, 7); i++) {
      final entry = sorted[i];
      final percent = (entry.value / total * 100);
      final bar = '█' * (percent / 10).round().clamp(1, 10);

      buffer.writeln('${icons[i]} **${entry.key}**');
      buffer.writeln('   $bar ${percent.toStringAsFixed(0)}% (${entry.value.toStringAsFixed(2)}€)');
    }

    // Identifier les catégories non essentielles
    final nonEssentialTotal = sorted
        .where((e) => AIKnowledgeBase.nonEssentialCategories
            .any((ne) => e.key.toLowerCase().contains(ne.toLowerCase())))
        .fold(0.0, (sum, e) => sum + e.value);

    if (nonEssentialTotal > total * 0.3) {
      buffer.writeln('\n💡 **Observation** : Les dépenses non essentielles représentent '
          '${(nonEssentialTotal / total * 100).toStringAsFixed(0)}% de vos dépenses. '
          'Vous pourriez économiser en les réduisant.');
    }

    return ChatMessage.assistant(buffer.toString());
  }

  static ChatMessage _handleSpecificCategory(
    String category,
    List<Expense> expenses,
    FinancialSnapshot snapshot,
  ) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final categoryExpenses = expenses.where((e) =>
        e.expenseDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
        (e.category?.name?.toLowerCase() ?? '').contains(category.toLowerCase()));

    final total = categoryExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final count = categoryExpenses.length;
    final average = count > 0 ? total / count : 0.0;

    final buffer = StringBuffer();
    buffer.writeln('📂 **Détails : $category**\n');
    buffer.writeln('💵 Total ce mois : **${total.toStringAsFixed(2)}€**');
    buffer.writeln('🧾 Nombre de transactions : **$count**');
    buffer.writeln('📊 Moyenne par transaction : **${average.toStringAsFixed(2)}€**');

    if (snapshot.totalSpentThisMonth > 0) {
      final percent = (total / snapshot.totalSpentThisMonth * 100);
      buffer.writeln('📈 Part du budget : **${percent.toStringAsFixed(0)}%**');
    }

    // Conseils spécifiques
    if (AIKnowledgeBase.categoryTips.containsKey(category)) {
      buffer.writeln('\n💡 **Conseils pour cette catégorie :**');
      for (final tip in AIKnowledgeBase.categoryTips[category]!.take(3)) {
        buffer.writeln('$tip');
      }
    }

    return ChatMessage.assistant(buffer.toString());
  }

  static ChatMessage _handleComparison(FinancialSnapshot snapshot, List<Expense> expenses) {
    final now = DateTime.now();
    final startOfThisMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);

    // Dépenses du mois dernier à la même date
    final lastMonthSameDay = expenses.where((e) =>
        e.expenseDate.isAfter(startOfLastMonth.subtract(const Duration(days: 1))) &&
        e.expenseDate.day <= now.day &&
        e.expenseDate.month == now.month - 1);

    final lastMonthTotal = lastMonthSameDay.fold(0.0, (sum, e) => sum + e.amount);
    final thisMonthTotal = snapshot.totalSpentThisMonth;

    final difference = thisMonthTotal - lastMonthTotal;
    final percentChange = lastMonthTotal > 0
        ? (difference / lastMonthTotal * 100)
        : (thisMonthTotal > 0 ? 100 : 0);

    String trend;
    String emoji;
    String advice;

    if (difference < -50) {
      trend = 'en nette baisse';
      emoji = '📉✅';
      advice = 'Excellent ! Vous maîtrisez mieux vos dépenses ce mois-ci.';
    } else if (difference < 0) {
      trend = 'en légère baisse';
      emoji = '📉';
      advice = 'Bien ! Continuez sur cette lancée.';
    } else if (difference < 50) {
      trend = 'stables';
      emoji = '➡️';
      advice = 'Vos dépenses sont régulières.';
    } else {
      trend = 'en hausse';
      emoji = '📈⚠️';
      advice = 'Attention, vous dépensez plus que le mois dernier.';
    }

    return ChatMessage.assistant(
      '$emoji **Comparaison avec le mois dernier**\n\n'
      '📅 Ce mois (jour ${now.day}) : **${thisMonthTotal.toStringAsFixed(2)}€**\n'
      '📅 Mois dernier (jour ${now.day}) : **${lastMonthTotal.toStringAsFixed(2)}€**\n\n'
      '${difference >= 0 ? '📈' : '📉'} Différence : **${difference >= 0 ? '+' : ''}${difference.toStringAsFixed(2)}€** '
      '(${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(0)}%)\n\n'
      'Vos dépenses sont **$trend**.\n\n'
      '💡 $advice',
      actions: [
        const QuickAction(label: 'Prédiction', icon: '🔮', actionType: 'prediction'),
        const QuickAction(label: 'Conseils', icon: '💡', actionType: 'advice'),
      ],
    );
  }

  static ChatMessage _handlePrediction(FinancialSnapshot snapshot, List<Budget> budgets) {
    final predicted = snapshot.predictedMonthEnd;
    final totalBudget = budgets.fold(0.0, (sum, b) => sum + b.monthlyLimit);
    final overBudget = budgets.isNotEmpty && predicted > totalBudget;
    final dailyNeeded = snapshot.daysUntilEndOfMonth > 0
        ? (totalBudget - snapshot.totalSpentThisMonth) / snapshot.daysUntilEndOfMonth
        : 0;

    final buffer = StringBuffer('🔮 **Prédiction de fin de mois**\n\n');

    buffer.writeln('📊 **Basé sur vos habitudes actuelles :**\n');
    buffer.writeln('• Dépenses actuelles : ${snapshot.totalSpentThisMonth.toStringAsFixed(2)}€');
    buffer.writeln('• Moyenne quotidienne : ${snapshot.averageDailySpending.toStringAsFixed(2)}€');
    buffer.writeln('• Jours restants : ${snapshot.daysUntilEndOfMonth}');
    buffer.writeln('');
    buffer.writeln('🎯 **Estimation fin de mois : ${predicted.toStringAsFixed(2)}€**');
    buffer.writeln('');

    if (budgets.isEmpty) {
      buffer.writeln('ℹ️ Créez un budget pour avoir des alertes de dépassement.');
    } else if (overBudget) {
      final overage = predicted - totalBudget;
      buffer.writeln('⚠️ **Attention !** Vous risquez de dépasser votre budget de ${overage.toStringAsFixed(2)}€.\n');
      buffer.writeln('💡 **Pour rester dans le budget :**');
      buffer.writeln('Limitez vos dépenses à **${dailyNeeded.toStringAsFixed(2)}€/jour** maximum.');
    } else {
      final margin = totalBudget - predicted;
      buffer.writeln('✅ **Bonne nouvelle !** Vous devriez rester dans votre budget.');
      buffer.writeln('Marge estimée : ${margin.toStringAsFixed(2)}€');
    }

    return ChatMessage.assistant(
      buffer.toString(),
      actions: [
        const QuickAction(label: 'Conseils', icon: '💡', actionType: 'advice'),
        const QuickAction(label: 'Mon budget', icon: '📊', actionType: 'budget'),
      ],
    );
  }

  static ChatMessage _handleGoal(List<Goal> goals, FinancialSnapshot snapshot) {
    if (goals.isEmpty) {
      return ChatMessage.assistant(
        _buildResponseTemplate(
          emoji: '🎯',
          title: 'Définir un objectif vous motive !',
          content: 'Vous n\'avez pas encore créé d\'objectif d\'épargne.',
          details: AIKnowledgeBase.situationalAdvice['no_goals']!,
          advice: 'Conseil : Commencez par un objectif de 3 mois de dépenses comme fonds d\'urgence.',
        ),
      );
    }

    final buffer = StringBuffer('🎯 **Progression de vos objectifs**\n\n');

    for (final goal in goals) {
      final progress = (goal.currentAmount / goal.targetAmount * 100).clamp(0, 100);
      final remaining = goal.targetAmount - goal.currentAmount;
      final progressBar = _createProgressBar(progress / 100);

      buffer.writeln('**${goal.title}**');
      buffer.writeln('$progressBar ${progress.toStringAsFixed(0)}%');
      buffer.writeln('${goal.currentAmount.toStringAsFixed(0)}€ / ${goal.targetAmount.toStringAsFixed(0)}€');

      if (progress >= 100) {
        buffer.writeln('🎉 Objectif atteint !');
      } else {
        // Estimer le temps restant
        final monthlySavings = snapshot.budgetRemaining > 0 ? snapshot.budgetRemaining * 0.2 : 50;
        final monthsRemaining = remaining / monthlySavings;
        if (monthsRemaining < 12) {
          buffer.writeln('⏱️ Environ ${monthsRemaining.ceil()} mois restants');
        }
      }
      buffer.writeln('');
    }

    return ChatMessage.assistant(buffer.toString());
  }

  static ChatMessage _handleThanks() {
    final response = AIKnowledgeBase.thankResponses[
        Random().nextInt(AIKnowledgeBase.thankResponses.length)];
    return ChatMessage.assistant(response);
  }

  static ChatMessage _handleProblem(
    FinancialSnapshot snapshot,
    List<Expense> expenses,
    List<Budget> budgets,
    String sentiment,
  ) {
    final buffer = StringBuffer();

    // Adapter le message selon le sentiment
    if (sentiment == 'worried') {
      buffer.writeln('😟 **Je comprends votre inquiétude. Analysons ensemble votre situation.**\n');
    } else {
      buffer.writeln('💪 **Voyons comment améliorer votre situation financière.**\n');
    }

    // Analyser les problèmes potentiels
    final problems = <String>[];

    if (snapshot.budgetUsedPercentage > 100) {
      problems.add('Votre budget est dépassé de ${(snapshot.budgetUsedPercentage - 100).toStringAsFixed(0)}%.');
    }

    if (snapshot.topCategoryAmount > snapshot.totalSpentThisMonth * 0.5) {
      problems.add('La catégorie "${snapshot.topCategory}" représente plus de 50% de vos dépenses.');
    }

    if (snapshot.averageDailySpending > snapshot.budgetRemaining / max(snapshot.daysUntilEndOfMonth, 1)) {
      problems.add('Votre rythme de dépense est trop élevé pour tenir jusqu\'à la fin du mois.');
    }

    if (problems.isNotEmpty) {
      buffer.writeln('📊 **Points identifiés :**');
      for (final problem in problems) {
        buffer.writeln('• $problem');
      }
      buffer.writeln('');
    }

    buffer.writeln('💡 **Actions immédiates recommandées :**\n');
    buffer.writeln(AIKnowledgeBase.situationalAdvice['budget_exceeded']!.skip(1).join('\n'));
    buffer.writeln('');
    buffer.writeln('N\'hésitez pas à me poser des questions, je suis là pour vous aider ! 💪');

    return ChatMessage.assistant(
      buffer.toString(),
      actions: [
        const QuickAction(label: 'Plan d\'économies', icon: '💡', actionType: 'advice'),
        const QuickAction(label: 'Mes catégories', icon: '📂', actionType: 'category'),
      ],
    );
  }

  static ChatMessage _handleHelp() {
    return ChatMessage.assistant(
      '❓ **Comment puis-je vous aider ?**\n\n'
      'Voici ce que je sais faire :\n\n'
      '💰 **Finances**\n'
      '• "Combien me reste-t-il ?" - Voir votre solde\n'
      '• "Mes dépenses" / "Dépenses d\'aujourd\'hui" - Résumé des dépenses\n'
      '• "Mon budget" - État de votre budget\n\n'
      '📊 **Analyse**\n'
      '• "Par catégorie" - Répartition des dépenses\n'
      '• "Compare au mois dernier" - Évolution\n'
      '• "Prédiction" - Estimation fin de mois\n\n'
      '💡 **Conseils**\n'
      '• "Un conseil" - Conseils personnalisés\n'
      '• "Comment économiser ?" - Astuces épargne\n'
      '• "J\'ai un problème" - Aide d\'urgence\n\n'
      '🎯 **Objectifs**\n'
      '• "Mes objectifs" - Suivi épargne\n\n'
      'Je comprends aussi le langage familier : "cb j\'ai", "je suis dans le rouge", "c\'est chaud"...\n\n'
      'Posez votre question naturellement, je ferai de mon mieux pour comprendre ! 😊',
    );
  }

  static ChatMessage _handleUnknown(
    FinancialSnapshot snapshot,
    String userMessage,
    double confidence,
    List<SpendingAnomaly> anomalies,
  ) {
    String response;

    // Si des anomalies sont détectées, les mentionner
    if (anomalies.isNotEmpty) {
      response = '🤔 Je n\'ai pas bien compris votre demande, mais j\'ai détecté quelque chose :\n\n'
          '🚨 ${anomalies.first.description}\n\n'
          'Voulez-vous que j\'analyse cette situation ?';
    } else if (confidence < 0.2) {
      response = '🤔 Je n\'ai pas bien compris votre demande.\n\n'
          'Essayez de formuler différemment, par exemple :\n'
          '• "Combien j\'ai dépensé ce mois ?"\n'
          '• "Quel est mon budget restant ?"\n'
          '• "Donne-moi un conseil"\n\n'
          'Ou utilisez les boutons ci-dessous pour une action rapide.';
    } else {
      response = '🤔 Je ne suis pas sûr de comprendre exactement.\n\n'
          'Voici ce que je peux faire pour vous :\n'
          '• Analyser vos dépenses\n'
          '• Vérifier votre budget\n'
          '• Vous donner des conseils\n'
          '• Faire des prédictions\n\n'
          'Que souhaitez-vous ?';
    }

    return ChatMessage.assistant(
      response,
      actions: [
        const QuickAction(label: 'Mon résumé', icon: '📊', actionType: 'summary'),
        const QuickAction(label: 'Conseils', icon: '💡', actionType: 'advice'),
        const QuickAction(label: 'Aide', icon: '❓', actionType: 'help'),
      ],
    );
  }

  /// Template pour construire des réponses structurées
  static String _buildResponseTemplate({
    required String emoji,
    required String title,
    required String content,
    List<String>? details,
    String? advice,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('$emoji **$title**\n');
    buffer.writeln(content);

    if (details != null && details.isNotEmpty) {
      buffer.writeln('\n');
      for (final detail in details) {
        buffer.writeln(detail);
      }
    }

    if (advice != null) {
      buffer.writeln('\n💡 $advice');
    }

    return buffer.toString();
  }

  /// Convertit une string en UserIntent
  static UserIntent _intentFromString(String intent) {
    switch (intent) {
      case 'greeting': return UserIntent.greeting;
      case 'balance': return UserIntent.askBalance;
      case 'spending': return UserIntent.askSpending;
      case 'budget': return UserIntent.askBudget;
      case 'savings': return UserIntent.askSavings;
      case 'advice': return UserIntent.askAdvice;
      case 'category': return UserIntent.askCategory;
      case 'comparison': return UserIntent.askComparison;
      case 'prediction': return UserIntent.askPrediction;
      case 'goal': return UserIntent.askGoal;
      default: return UserIntent.unknown;
    }
  }

  /// Traite une action rapide
  static Future<ChatMessage> processQuickAction(
    String actionType, {
    required List<Expense> expenses,
    required List<Budget> budgets,
    required List<Goal> goals,
  }) async {
    final snapshot = _createDetailedSnapshot(expenses, budgets, goals);
    await Future.delayed(const Duration(milliseconds: 300));

    switch (actionType) {
      case 'summary':
      case 'spending':
        return _handleSpending('spending', snapshot, expenses, {});
      case 'advice':
      case 'more_advice':
        return _handleAdvice(snapshot, expenses, budgets, goals, 'neutral');
      case 'category':
        return _handleCategory(snapshot, expenses, {});
      case 'prediction':
        return _handlePrediction(snapshot, budgets);
      case 'budget':
        return _handleBudget(snapshot, budgets);
      case 'comparison':
        return _handleComparison(snapshot, expenses);
      case 'balance':
        return _handleBalance(snapshot, budgets, false);
      case 'savings':
        return _handleSavings(snapshot, goals);
      case 'anomaly':
        return _handleAnomalyDetails();
      case 'help':
        return _handleHelp();
      default:
        return _handleHelp();
    }
  }

  /// Affiche les détails des anomalies
  static ChatMessage _handleAnomalyDetails() {
    if (_recentAnomalies.isEmpty) {
      return ChatMessage.assistant(
        '✅ **Aucune anomalie détectée**\n\n'
        'Vos habitudes de dépenses sont régulières. C\'est une bonne chose !\n\n'
        'Je vous alerterai si je détecte un comportement inhabituel.',
      );
    }

    final buffer = StringBuffer('🚨 **Anomalies détectées récemment**\n\n');

    for (final anomaly in _recentAnomalies.take(5)) {
      final severityIcon = anomaly.severity == 'high' ? '🔴'
          : anomaly.severity == 'medium' ? '🟠' : '🟡';

      buffer.writeln('$severityIcon **${anomaly.description}**');
      buffer.writeln('   📅 ${_formatDate(anomaly.date)}');
      buffer.writeln('   💵 Montant : ${anomaly.amount.toStringAsFixed(2)}€');
      buffer.writeln('   📊 Attendu : ~${anomaly.expectedAmount.toStringAsFixed(2)}€');
      buffer.writeln('');
    }

    buffer.writeln('💡 **Que faire ?**');
    buffer.writeln('• Vérifiez si ces dépenses sont exceptionnelles');
    buffer.writeln('• Identifiez les sources de ces pics');
    buffer.writeln('• Ajustez votre budget si nécessaire');

    return ChatMessage.assistant(buffer.toString());
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Aujourd\'hui';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Hier';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ==================== MODÈLES POUR LES ANOMALIES ====================

enum AnomalyType {
  spike,           // Pic de dépenses
  suddenIncrease,  // Augmentation soudaine
  unusualExpense,  // Dépense inhabituelle
  categorySpike,   // Catégorie en explosion
  budgetExceeded,  // Budget dépassé
}

class SpendingAnomaly {
  final AnomalyType type;
  final double amount;
  final double expectedAmount;
  final DateTime date;
  final String? category;
  final String description;
  final String severity; // 'low', 'medium', 'high'

  SpendingAnomaly({
    required this.type,
    required this.amount,
    required this.expectedAmount,
    required this.date,
    this.category,
    required this.description,
    required this.severity,
  });

  Map<String, dynamic> toJson() => {
    'type': type.index,
    'amount': amount,
    'expectedAmount': expectedAmount,
    'date': date.toIso8601String(),
    'category': category,
    'description': description,
    'severity': severity,
  };

  factory SpendingAnomaly.fromJson(Map<String, dynamic> json) => SpendingAnomaly(
    type: AnomalyType.values[json['type'] as int],
    amount: (json['amount'] as num).toDouble(),
    expectedAmount: (json['expectedAmount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    category: json['category'] as String?,
    description: json['description'] as String,
    severity: json['severity'] as String,
  );
}
