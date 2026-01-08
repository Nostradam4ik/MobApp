/// Base de connaissances pour l'Assistant IA SmartSpend
/// Contient les règles financières, conseils et patterns de réponse

class AIKnowledgeBase {
  // ==================== RÈGLES FINANCIÈRES ====================

  /// Règle 50/30/20 pour la gestion budgétaire
  static const Map<String, double> budgetRule502030 = {
    'besoins': 0.50, // Loyer, nourriture, transport, factures
    'envies': 0.30, // Loisirs, restaurants, shopping
    'epargne': 0.20, // Épargne, investissement, dettes
  };

  /// Catégories essentielles vs non-essentielles
  static const List<String> essentialCategories = [
    'Loyer',
    'Logement',
    'Alimentation',
    'Courses',
    'Transport',
    'Santé',
    'Assurance',
    'Factures',
    'Électricité',
    'Eau',
    'Internet',
    'Téléphone',
  ];

  static const List<String> nonEssentialCategories = [
    'Restaurant',
    'Loisirs',
    'Shopping',
    'Vêtements',
    'Divertissement',
    'Abonnements',
    'Cadeaux',
    'Vacances',
    'Sport',
    'Beauté',
  ];

  // ==================== PATTERNS DE QUESTIONS ====================

  /// Patterns pour détecter les intentions avec plus de précision
  static const Map<String, List<String>> intentPatterns = {
    'greeting': [
      'bonjour', 'salut', 'hello', 'hey', 'coucou', 'bonsoir', 'bonne nuit',
      'ça va', 'comment ça va', 'quoi de neuf',
    ],
    'balance': [
      'reste', 'solde', 'disponible', 'combien me reste', 'combien j\'ai',
      'reste-t-il', 'ai-je encore', 'budget restant', 'argent disponible',
      'peux dépenser', 'puis-je dépenser', 'marge',
    ],
    'spending': [
      'dépensé', 'depense', 'dépenses', 'combien j\'ai dépensé', 'mes dépenses',
      'total dépenses', 'somme dépensée', 'montant dépensé', 'coûté',
      'payé', 'acheté', 'mes achats',
    ],
    'spending_today': [
      'aujourd\'hui', 'ce jour', 'cette journée', 'depuis ce matin',
    ],
    'spending_week': [
      'cette semaine', 'semaine', '7 jours', 'sept jours',
    ],
    'spending_month': [
      'ce mois', 'mois-ci', 'mensuel', 'du mois',
    ],
    'budget': [
      'budget', 'limite', 'plafond', 'maximum', 'dépassé',
      'respecté', 'tenu', 'suivi budget',
    ],
    'savings': [
      'épargne', 'epargne', 'économies', 'economies', 'économiser',
      'mettre de côté', 'épargner', 'sauver', 'garder',
    ],
    'advice': [
      'conseil', 'astuce', 'aide', 'recommandation', 'suggestion',
      'comment faire', 'que faire', 'améliorer', 'optimiser',
      'réduire', 'économiser', 'tips', 'idée',
    ],
    'category': [
      'catégorie', 'categorie', 'où va', 'où part', 'plus dépensé',
      'répartition', 'distribution', 'ventilation', 'détail',
    ],
    'comparison': [
      'comparé', 'compare', 'par rapport', 'mois dernier', 'semaine dernière',
      'évolution', 'progression', 'tendance', 'historique', 'avant',
    ],
    'prediction': [
      'prédiction', 'prediction', 'prévoir', 'fin du mois', 'estimer',
      'projection', 'futur', 'prévision', 'anticiper',
    ],
    'goal': [
      'objectif', 'goal', 'but', 'cible', 'projet',
      'épargne pour', 'économiser pour',
    ],
    'help': [
      'aide', 'help', 'comment', 'quoi faire', 'capable',
      'fonctionnalité', 'peux-tu', 'sais-tu',
    ],
    'thank': [
      'merci', 'thanks', 'super', 'génial', 'parfait', 'cool',
      'excellent', 'top', 'nickel',
    ],
    'problem': [
      'problème', 'souci', 'difficile', 'galère', 'coincé',
      'dette', 'découvert', 'négatif', 'rouge',
    ],
  };

  // ==================== RÉPONSES CONTEXTUELLES ====================

  /// Messages de salutation variés
  static const List<String> greetingResponses = [
    'Bonjour ! 😊 Comment puis-je vous aider avec vos finances aujourd\'hui ?',
    'Salut ! 👋 Prêt à optimiser votre budget ?',
    'Hello ! Je suis là pour vous aider à gérer votre argent. Que souhaitez-vous savoir ?',
    'Bonjour ! 🌟 Votre assistant financier est à votre service !',
    'Coucou ! Comment puis-je vous aider à mieux gérer vos dépenses ?',
  ];

  /// Messages de remerciement
  static const List<String> thankResponses = [
    'Avec plaisir ! N\'hésitez pas si vous avez d\'autres questions. 😊',
    'Je suis là pour ça ! Bonne gestion de vos finances ! 💪',
    'De rien ! Continuez comme ça, vous êtes sur la bonne voie ! 🌟',
    'Ravi de pouvoir vous aider ! À bientôt ! 👋',
  ];

  // ==================== CONSEILS FINANCIERS ====================

  /// Conseils généraux d'épargne
  static const List<String> savingsTips = [
    '💡 **Règle des 24h** : Attendez 24h avant tout achat non essentiel de plus de 50€.',
    '☕ **Petit plaisir, grande économie** : Un café maison = 3€/jour économisés = 90€/mois !',
    '📱 **Audit d\'abonnements** : Vérifiez vos abonnements mensuels, supprimez les inutilisés.',
    '🛒 **Liste de courses** : Faites une liste et respectez-la pour éviter les achats impulsifs.',
    '💳 **Paiement cash** : Payer en espèces aide à mieux visualiser les dépenses.',
    '🏷️ **Comparateur de prix** : Comparez avant d\'acheter, surtout pour les gros achats.',
    '🍳 **Meal prep** : Préparez vos repas à l\'avance pour économiser sur les restaurants.',
    '🚗 **Covoiturage** : Partagez vos trajets pour diviser les frais d\'essence.',
    '💡 **Énergie** : Éteignez les appareils en veille, économisez jusqu\'à 10% sur l\'électricité.',
    '📦 **Désencombrez** : Vendez ce que vous n\'utilisez plus, c\'est de l\'argent qui dort !',
  ];

  /// Conseils pour réduire les dépenses par catégorie
  static const Map<String, List<String>> categoryTips = {
    'Alimentation': [
      '🥗 Planifiez vos repas pour la semaine',
      '🏷️ Utilisez les promotions et codes promo',
      '🥡 Cuisinez en batch et congelez',
      '🛒 Achetez des marques distributeur',
    ],
    'Restaurant': [
      '🍽️ Limitez-vous à 1-2 sorties par semaine',
      '☕ Privilégiez le déjeuner plutôt que le dîner (moins cher)',
      '📱 Utilisez des apps de réduction (TheFork, etc.)',
    ],
    'Transport': [
      '🚲 Utilisez le vélo pour les courts trajets',
      '🚗 Pensez au covoiturage',
      '🚇 Abonnement transport en commun si régulier',
      '⛽ Comparez les prix d\'essence avec une app',
    ],
    'Loisirs': [
      '🎬 Profitez des jours à tarif réduit',
      '📚 Bibliothèque gratuite plutôt qu\'achat de livres',
      '🏃 Activités gratuites : randonnée, jogging, parcs',
    ],
    'Shopping': [
      '⏰ Attendez les soldes pour les gros achats',
      '🔄 Achetez d\'occasion quand c\'est possible',
      '📋 Faites une liste et attendez 48h avant d\'acheter',
    ],
    'Abonnements': [
      '📊 Listez tous vos abonnements',
      '🔄 Partagez les comptes famille (Netflix, Spotify)',
      '❌ Annulez ceux non utilisés depuis 1 mois',
    ],
  };

  /// Conseils selon la situation financière
  static const Map<String, List<String>> situationalAdvice = {
    'budget_exceeded': [
      '🚨 Votre budget est dépassé. Voici des actions immédiates :',
      '1. Identifiez les dépenses non essentielles de cette semaine',
      '2. Reportez les achats qui peuvent attendre',
      '3. Évitez les restaurants et sorties jusqu\'à la fin du mois',
      '4. Vendez des objets inutilisés pour récupérer de l\'argent',
    ],
    'budget_warning': [
      '⚠️ Attention, vous approchez de votre limite ! Conseils :',
      '1. Limitez les dépenses aux essentiels cette semaine',
      '2. Reportez les achats non urgents au mois prochain',
      '3. Cherchez des alternatives gratuites pour les loisirs',
    ],
    'budget_good': [
      '✅ Vous gérez bien votre budget ! Pour aller plus loin :',
      '1. Profitez de cette marge pour épargner',
      '2. Anticipez les dépenses du mois prochain',
      '3. Constituez un fonds d\'urgence si ce n\'est pas fait',
    ],
    'no_budget': [
      '📋 Vous n\'avez pas de budget défini. C\'est important car :',
      '• Sans limite, on dépense souvent plus que prévu',
      '• Un budget permet de visualiser où va l\'argent',
      '• C\'est la première étape pour économiser',
      '\n💡 Conseil : Commencez par noter vos revenus et fixer une limite réaliste.',
    ],
    'no_goals': [
      '🎯 Définir des objectifs d\'épargne vous motivera !',
      'Exemples d\'objectifs :',
      '• 🆘 Fonds d\'urgence (3-6 mois de dépenses)',
      '• 🏖️ Vacances',
      '• 📱 Nouvel appareil',
      '• 🏠 Projet immobilier',
    ],
    'high_spending': [
      '📈 Vos dépenses sont élevées ce mois-ci.',
      'Analysons ensemble les postes les plus importants.',
      'Voulez-vous voir la répartition par catégorie ?',
    ],
  };

  // ==================== ANALYSE COMPORTEMENTALE ====================

  /// Analyse le pattern de dépenses et retourne des insights
  static String analyzeSpendingPattern({
    required double weekdayAverage,
    required double weekendAverage,
    required String highestDay,
    required double highestDayAmount,
  }) {
    final buffer = StringBuffer();

    if (weekendAverage > weekdayAverage * 1.5) {
      buffer.writeln('📊 **Pattern détecté** : Vous dépensez beaucoup plus le weekend.');
      buffer.writeln('Le weekend représente ${((weekendAverage / (weekdayAverage + weekendAverage)) * 100).toStringAsFixed(0)}% de plus que la semaine.');
      buffer.writeln('\n💡 Conseil : Planifiez vos activités du weekend à l\'avance pour mieux contrôler.');
    } else if (weekdayAverage > weekendAverage * 1.3) {
      buffer.writeln('📊 **Pattern détecté** : Vos dépenses sont concentrées en semaine.');
      buffer.writeln('Peut-être des repas au travail ou des déplacements ?');
      buffer.writeln('\n💡 Conseil : Préparez vos repas à la maison pour économiser.');
    } else {
      buffer.writeln('📊 Vos dépenses sont bien réparties sur la semaine. 👍');
    }

    buffer.writeln('\n📅 Jour le plus dépensier : **$highestDay** (${highestDayAmount.toStringAsFixed(0)}€ en moyenne)');

    return buffer.toString();
  }

  /// Analyse la santé financière et donne des recommandations
  static List<String> getHealthRecommendations({
    required double budgetUsedPercent,
    required double savingsRate,
    required int dayOfMonth,
    required bool hasGoals,
    required bool hasBudget,
  }) {
    final recommendations = <String>[];
    final expectedPercent = (dayOfMonth / 30) * 100;

    // Budget
    if (!hasBudget) {
      recommendations.add('📋 **Priorité 1** : Créez un budget mensuel pour mieux contrôler vos dépenses.');
    } else if (budgetUsedPercent > expectedPercent + 15) {
      recommendations.add('🚨 **Alerte Budget** : Vous dépensez trop vite ! Ralentissez pour tenir jusqu\'à la fin du mois.');
    } else if (budgetUsedPercent < expectedPercent - 10) {
      recommendations.add('💚 **Bon rythme** : Vous êtes en avance sur votre budget. Profitez-en pour épargner !');
    }

    // Épargne
    if (savingsRate < 10) {
      recommendations.add('🐷 **Épargne** : Essayez d\'épargner au moins 10% de vos revenus chaque mois.');
    } else if (savingsRate >= 20) {
      recommendations.add('⭐ **Excellent** : Votre taux d\'épargne de ${savingsRate.toStringAsFixed(0)}% est exemplaire !');
    }

    // Objectifs
    if (!hasGoals) {
      recommendations.add('🎯 **Motivation** : Créez un objectif d\'épargne pour rester motivé.');
    }

    return recommendations;
  }

  // ==================== FORMULES DE CALCUL ====================

  /// Calcule le montant quotidien recommandé
  static double calculateDailyAllowance(double remaining, int daysLeft) {
    if (daysLeft <= 0) return 0;
    return remaining / daysLeft;
  }

  /// Calcule le taux d'épargne
  static double calculateSavingsRate(double income, double expenses) {
    if (income <= 0) return 0;
    return ((income - expenses) / income * 100).clamp(0, 100);
  }

  /// Évalue le score de santé financière
  static int calculateHealthScore({
    required double budgetUsedPercent,
    required double savingsRate,
    required bool hasEmergencyFund,
    required bool trackingConsistently,
  }) {
    int score = 0;

    // Budget (max 30 points)
    if (budgetUsedPercent <= 80) score += 30;
    else if (budgetUsedPercent <= 100) score += 20;
    else score += 5;

    // Épargne (max 30 points)
    if (savingsRate >= 20) score += 30;
    else if (savingsRate >= 10) score += 20;
    else if (savingsRate > 0) score += 10;

    // Fonds d'urgence (max 20 points)
    if (hasEmergencyFund) score += 20;

    // Suivi régulier (max 20 points)
    if (trackingConsistently) score += 20;

    return score;
  }

  // ==================== MESSAGES MOTIVATIONNELS ====================

  static const List<String> motivationalMessages = [
    '💪 Chaque euro économisé vous rapproche de vos objectifs !',
    '🌟 Vous faites du bon travail en suivant vos dépenses !',
    '🚀 La discipline financière d\'aujourd\'hui, c\'est la liberté de demain.',
    '🎯 Petit à petit, l\'oiseau fait son nid... et son épargne !',
    '💡 Gérer son argent, c\'est gérer sa tranquillité d\'esprit.',
    '🌱 Chaque petit geste compte pour votre avenir financier.',
    '⭐ Vous êtes sur la bonne voie, continuez !',
    '🏆 La constance est la clé du succès financier.',
  ];

  /// Retourne un message motivationnel aléatoire
  static String getRandomMotivation() {
    return motivationalMessages[DateTime.now().millisecond % motivationalMessages.length];
  }
}
