import 'dart:math';
import 'ai_knowledge_base.dart';

/// Moteur NLP local avancé avec fuzzy matching et détection intelligente
class AINLPEngine {
  // ==================== SYNONYMES ET VARIATIONS ====================

  /// Dictionnaire de synonymes pour améliorer la compréhension
  static const Map<String, List<String>> synonyms = {
    // Argent
    'argent': ['sous', 'thune', 'fric', 'blé', 'pognon', 'cash', 'monnaie', 'euros', 'euro', '€'],
    'dépense': ['achat', 'paiement', 'frais', 'coût', 'cout', 'depense', 'depenses', 'dépenses'],
    'économie': ['épargne', 'epargne', 'economies', 'économies', 'economie'],
    'budget': ['limite', 'plafond', 'enveloppe', 'allocation'],

    // Temps
    'aujourd\'hui': ['ce jour', 'maintenant', 'auj', 'today', 'jour'],
    'semaine': ['7 jours', 'sept jours', 'hebdo', 'hebdomadaire'],
    'mois': ['mensuel', '30 jours', 'trente jours', 'ce mois-ci', 'mois-ci'],
    'année': ['annee', 'an', 'annuel', '12 mois', 'douze mois'],

    // Actions
    'voir': ['montrer', 'afficher', 'consulter', 'regarder', 'check'],
    'ajouter': ['créer', 'creer', 'nouveau', 'nouvelle', 'faire', 'mettre'],
    'supprimer': ['effacer', 'enlever', 'retirer', 'delete'],
    'modifier': ['changer', 'éditer', 'editer', 'update', 'mettre à jour'],

    // Questions
    'combien': ['quel montant', 'quelle somme', 'le total'],
    'où': ['ou', 'quel endroit', 'dans quoi'],
    'pourquoi': ['pour quelle raison', 'comment ça se fait'],
    'comment': ['de quelle manière', 'par quel moyen'],

    // États
    'reste': ['disponible', 'restant', 'encore', 'il me reste'],
    'dépensé': ['utilisé', 'consommé', 'payé', 'sorti'],
    'économisé': ['épargné', 'mis de côté', 'gardé', 'sauvé'],
  };

  /// Expressions courantes et leurs intentions
  static const Map<String, String> commonExpressions = {
    // Salutations
    'yo': 'greeting',
    'coucou': 'greeting',
    'wesh': 'greeting',
    'slt': 'greeting',
    'bjr': 'greeting',
    'bsr': 'greeting',

    // Questions rapides
    'cb': 'balance', // combien
    'cmb': 'balance',
    'il me reste cb': 'balance',
    'j\'ai cb': 'balance',
    'jai cb': 'balance',
    'j ai cb': 'balance',

    // Abréviations
    'dep': 'spending',
    'deps': 'spending',
    'mes dep': 'spending',

    // Expressions familières
    'je suis dans le rouge': 'problem',
    'je suis à sec': 'problem',
    'je suis fauché': 'problem',
    'j\'ai plus rien': 'problem',
    'fin de mois difficile': 'problem',
    'je galère': 'problem',
    'c\'est chaud': 'problem',
    'c\'est la merde': 'problem',

    // Positif
    'ça roule': 'greeting',
    'nickel': 'thank',
    'au top': 'thank',
    'trop bien': 'thank',
  };

  /// Fautes d'orthographe courantes
  static const Map<String, String> commonTypos = {
    'depense': 'dépense',
    'depenser': 'dépenser',
    'argant': 'argent',
    'budjet': 'budget',
    'economie': 'économie',
    'economiser': 'économiser',
    'epargne': 'épargne',
    'aujourdhui': 'aujourd\'hui',
    'aujour\'hui': 'aujourd\'hui',
    'aujorud\'hui': 'aujourd\'hui',
    'combian': 'combien',
    'conbien': 'combien',
    'consiel': 'conseil',
    'conceil': 'conseil',
    'bonjur': 'bonjour',
    'bonsoir': 'bonsoir',
    'semaien': 'semaine',
    'samaine': 'semaine',
    'categorie': 'catégorie',
    'repartition': 'répartition',
    'objectifs': 'objectif',
    'prevision': 'prévision',
    'prediciton': 'prédiction',
  };

  // ==================== ANALYSE PRINCIPALE ====================

  /// Analyse complète du message avec fuzzy matching
  static ({
    String intent,
    double confidence,
    Map<String, dynamic> entities,
    List<String>? clarificationOptions,
    String? detectedExpression,
  }) analyzeMessage(String message) {
    // Pré-traitement
    var processedMessage = _preProcessMessage(message);
    final normalizedMessage = _normalizeText(processedMessage);
    final tokens = _tokenize(normalizedMessage);

    // Vérifier les expressions courantes d'abord
    final expressionIntent = _checkCommonExpressions(message.toLowerCase());
    if (expressionIntent != null) {
      return (
        intent: expressionIntent.intent,
        confidence: expressionIntent.confidence,
        entities: _extractEntities(normalizedMessage, tokens),
        clarificationOptions: null,
        detectedExpression: expressionIntent.expression,
      );
    }

    // Calculer les scores d'intention avec fuzzy matching
    final intentScores = <String, double>{};

    for (final entry in AIKnowledgeBase.intentPatterns.entries) {
      final score = _calculateIntentScoreAdvanced(normalizedMessage, tokens, entry.value);
      if (score > 0) {
        intentScores[entry.key] = score;
      }
    }

    // Trouver les meilleures intentions
    final sortedIntents = intentScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String bestIntent = 'unknown';
    double bestScore = 0.0;
    List<String>? clarificationOptions;

    if (sortedIntents.isNotEmpty) {
      bestIntent = sortedIntents.first.key;
      bestScore = sortedIntents.first.value;

      // Vérifier s'il y a ambiguïté (scores proches)
      if (sortedIntents.length > 1) {
        final secondScore = sortedIntents[1].value;
        if (secondScore > 0.3 && (bestScore - secondScore) < 0.2) {
          // Ambiguïté détectée - proposer clarification
          clarificationOptions = _generateClarificationOptions(
            sortedIntents.take(3).map((e) => e.key).toList(),
          );
        }
      }
    }

    // Combiner les intentions temporelles
    bestIntent = _combineTemporalIntents(bestIntent, intentScores);

    // Si score trop bas, tenter la récupération
    if (bestScore < 0.3) {
      final recovered = _attemptIntentRecovery(normalizedMessage, tokens);
      if (recovered != null) {
        bestIntent = recovered.intent;
        bestScore = recovered.confidence;
      }
    }

    // Extraire les entités
    final entities = _extractEntities(normalizedMessage, tokens);

    return (
      intent: bestIntent,
      confidence: bestScore.clamp(0.0, 1.0),
      entities: entities,
      clarificationOptions: clarificationOptions,
      detectedExpression: null,
    );
  }

  // ==================== PRÉ-TRAITEMENT ====================

  /// Pré-traite le message (corrections, expansions)
  static String _preProcessMessage(String message) {
    var processed = message.toLowerCase().trim();

    // Corriger les fautes courantes
    for (final entry in commonTypos.entries) {
      processed = processed.replaceAll(entry.key, entry.value);
    }

    // Étendre les abréviations
    processed = processed
        .replaceAll('cb', 'combien')
        .replaceAll('cmb', 'combien')
        .replaceAll('auj', 'aujourd\'hui')
        .replaceAll('slt', 'salut')
        .replaceAll('bjr', 'bonjour')
        .replaceAll('bsr', 'bonsoir')
        .replaceAll('svp', 's\'il vous plaît')
        .replaceAll('stp', 's\'il te plaît')
        .replaceAll('pk', 'pourquoi')
        .replaceAll('pcq', 'parce que')
        .replaceAll('jsp', 'je ne sais pas')
        .replaceAll('jpp', 'j\'en peux plus');

    return processed;
  }

  /// Normalise le texte (minuscules, suppression accents, etc.)
  static String _normalizeText(String text) {
    var normalized = text.toLowerCase().trim();

    // Remplacer les accents
    final accents = {
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'à': 'a', 'â': 'a', 'ä': 'a',
      'ù': 'u', 'û': 'u', 'ü': 'u',
      'ô': 'o', 'ö': 'o',
      'î': 'i', 'ï': 'i',
      'ç': 'c',
    };

    for (final entry in accents.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }

    // Supprimer la ponctuation excessive
    normalized = normalized.replaceAll(RegExp(r'[!?.,;:]+'), ' ');

    return normalized;
  }

  /// Tokenize le texte en mots
  static List<String> _tokenize(String text) {
    return text
        .split(RegExp(r'\s+'))
        .where((token) => token.length > 1)
        .toList();
  }

  // ==================== DÉTECTION D'EXPRESSIONS ====================

  /// Vérifie les expressions courantes
  static ({String intent, double confidence, String expression})? _checkCommonExpressions(String text) {
    // Vérification exacte
    if (commonExpressions.containsKey(text.trim())) {
      return (
        intent: commonExpressions[text.trim()]!,
        confidence: 0.95,
        expression: text.trim(),
      );
    }

    // Vérification partielle
    for (final entry in commonExpressions.entries) {
      if (text.contains(entry.key)) {
        return (
          intent: entry.value,
          confidence: 0.85,
          expression: entry.key,
        );
      }
    }

    return null;
  }

  // ==================== CALCUL DE SCORE AVANCÉ ====================

  /// Calcule le score d'intention avec fuzzy matching
  static double _calculateIntentScoreAdvanced(String text, List<String> tokens, List<String> patterns) {
    double score = 0.0;
    int exactMatches = 0;
    int fuzzyMatches = 0;
    int synonymMatches = 0;

    for (final pattern in patterns) {
      final normalizedPattern = _normalizeText(pattern);

      // 1. Correspondance exacte (score le plus élevé)
      if (text.contains(normalizedPattern)) {
        score += 1.0;
        exactMatches++;
        continue;
      }

      // 2. Correspondance par synonyme
      if (_matchesSynonym(text, tokens, pattern)) {
        score += 0.8;
        synonymMatches++;
        continue;
      }

      // 3. Fuzzy matching avec distance de Levenshtein
      double bestFuzzyScore = 0.0;
      for (final token in tokens) {
        final distance = _levenshteinDistance(token, normalizedPattern);
        final maxLen = max(token.length, normalizedPattern.length);
        if (maxLen > 0) {
          final similarity = 1.0 - (distance / maxLen);
          if (similarity > 0.7 && similarity > bestFuzzyScore) {
            bestFuzzyScore = similarity;
          }
        }
      }

      if (bestFuzzyScore > 0) {
        score += bestFuzzyScore * 0.6;
        fuzzyMatches++;
        continue;
      }

      // 4. Correspondance par préfixe (dernier recours)
      for (final token in tokens) {
        if (token.length >= 3 && normalizedPattern.length >= 3) {
          if (token.startsWith(normalizedPattern.substring(0, 3)) ||
              normalizedPattern.startsWith(token.substring(0, 3))) {
            score += 0.3;
            break;
          }
        }
      }
    }

    // Normaliser et ajuster le score
    if (patterns.isNotEmpty) {
      score = score / patterns.length;

      // Bonus pour les correspondances exactes multiples
      if (exactMatches > 1) {
        score += 0.15 * (exactMatches - 1);
      }

      // Petit bonus pour les synonymes
      if (synonymMatches > 0) {
        score += 0.05 * synonymMatches;
      }
    }

    return score;
  }

  /// Vérifie si un mot correspond via synonyme
  static bool _matchesSynonym(String text, List<String> tokens, String pattern) {
    // Trouver les synonymes du pattern
    for (final entry in synonyms.entries) {
      if (entry.key == pattern || entry.value.contains(pattern)) {
        // Vérifier si un synonyme est dans le texte
        if (text.contains(entry.key)) return true;
        for (final syn in entry.value) {
          if (text.contains(syn)) return true;
        }
      }
    }
    return false;
  }

  /// Distance de Levenshtein (édition minimale entre deux chaînes)
  static int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final m = s1.length;
    final n = s2.length;

    // Utiliser deux lignes au lieu de toute la matrice (optimisation mémoire)
    var prevRow = List<int>.generate(n + 1, (i) => i);
    var currRow = List<int>.filled(n + 1, 0);

    for (var i = 1; i <= m; i++) {
      currRow[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        currRow[j] = [
          prevRow[j] + 1,      // Suppression
          currRow[j - 1] + 1,   // Insertion
          prevRow[j - 1] + cost // Substitution
        ].reduce(min);
      }
      // Échanger les lignes
      final temp = prevRow;
      prevRow = currRow;
      currRow = temp;
    }

    return prevRow[n];
  }

  /// Calcule la similarité entre deux mots (0.0 à 1.0)
  static double wordSimilarity(String word1, String word2) {
    if (word1 == word2) return 1.0;
    if (word1.isEmpty || word2.isEmpty) return 0.0;

    final distance = _levenshteinDistance(word1, word2);
    final maxLen = max(word1.length, word2.length);
    return 1.0 - (distance / maxLen);
  }

  // ==================== COMBINAISON D'INTENTIONS ====================

  /// Combine les intentions temporelles
  static String _combineTemporalIntents(String bestIntent, Map<String, double> intentScores) {
    if (bestIntent == 'spending') {
      if (intentScores.containsKey('spending_today') &&
          intentScores['spending_today']! > 0.3) {
        return 'spending_today';
      } else if (intentScores.containsKey('spending_week') &&
                 intentScores['spending_week']! > 0.3) {
        return 'spending_week';
      } else if (intentScores.containsKey('spending_month') &&
                 intentScores['spending_month']! > 0.3) {
        return 'spending_month';
      }
    }
    return bestIntent;
  }

  // ==================== RÉCUPÉRATION D'INTENTION ====================

  /// Tente de récupérer une intention quand le score est trop bas
  static ({String intent, double confidence})? _attemptIntentRecovery(
    String text,
    List<String> tokens,
  ) {
    // Patterns de récupération basés sur la structure de la phrase
    final recoveryPatterns = <RegExp, (String, double)>{
      // Questions sur l'argent
      RegExp(r'(combien|cb|cmb).*(reste|disponible|ai)'): ('balance', 0.7),
      RegExp(r'(il me reste|ai encore|reste-t-il)'): ('balance', 0.65),

      // Dépenses
      RegExp(r'(combien|cb).*(depense|paye|sorti)'): ('spending', 0.7),
      RegExp(r'(ou).*(argent|va|part)'): ('category', 0.65),
      RegExp(r'(mes|les).*(depenses|achats|paiements)'): ('spending', 0.6),

      // Conseil
      RegExp(r'(comment|que).*(faire|economiser|reduire|ameliorer)'): ('advice', 0.65),
      RegExp(r'(aide|help|besoin).*(conseil|aide|astuce)'): ('advice', 0.6),
      RegExp(r'(des|un|une).*(conseil|astuce|idee|tip)'): ('advice', 0.55),

      // Budget
      RegExp(r'(mon|le).*(budget|limite|plafond)'): ('budget', 0.6),
      RegExp(r'(depasse|explose|grille).*(budget|limite)'): ('budget', 0.7),

      // Épargne
      RegExp(r'(economiser|epargner|mettre de cote)'): ('savings', 0.65),
      RegExp(r'(mes|mon).*(economies|epargne|objectif)'): ('savings', 0.6),

      // Problème
      RegExp(r'(probleme|souci|galere|difficile|stresse)'): ('problem', 0.55),
      RegExp(r'(je suis|c est).*(rouge|fauche|sec|mort)'): ('problem', 0.7),
    };

    for (final entry in recoveryPatterns.entries) {
      if (entry.key.hasMatch(text)) {
        final result = entry.value;
        return (intent: result.$1, confidence: result.$2);
      }
    }

    // Dernier recours: mots-clés isolés
    final keywordIntents = {
      'reste': 'balance',
      'solde': 'balance',
      'depenses': 'spending',
      'budget': 'budget',
      'economie': 'savings',
      'conseil': 'advice',
      'aide': 'help',
      'merci': 'thank',
    };

    for (final token in tokens) {
      if (keywordIntents.containsKey(token)) {
        return (intent: keywordIntents[token]!, confidence: 0.45);
      }
    }

    return null;
  }

  // ==================== CLARIFICATION ====================

  /// Génère des options de clarification
  static List<String> _generateClarificationOptions(List<String> ambiguousIntents) {
    final options = <String>[];

    final intentLabels = {
      'spending': 'Voir mes dépenses',
      'spending_today': 'Dépenses d\'aujourd\'hui',
      'spending_week': 'Dépenses de la semaine',
      'spending_month': 'Dépenses du mois',
      'balance': 'Mon solde restant',
      'budget': 'État de mon budget',
      'savings': 'Mon épargne',
      'advice': 'Obtenir des conseils',
      'category': 'Répartition par catégorie',
      'comparison': 'Comparaison temporelle',
      'prediction': 'Prédiction fin de mois',
      'goal': 'Mes objectifs',
      'help': 'Comment utiliser l\'app',
    };

    for (final intent in ambiguousIntents) {
      if (intentLabels.containsKey(intent)) {
        options.add(intentLabels[intent]!);
      }
    }

    return options;
  }

  // ==================== EXTRACTION D'ENTITÉS ====================

  /// Extrait les entités améliorées
  static Map<String, dynamic> _extractEntities(String text, List<String> tokens) {
    final entities = <String, dynamic>{};

    // Extraire les montants (plus de formats supportés)
    entities.addAll(_extractAmounts(text));

    // Extraire les périodes
    entities.addAll(_extractPeriods(text));

    // Extraire les catégories
    entities.addAll(_extractCategories(text));

    // Extraire les pourcentages
    entities.addAll(_extractPercentages(text));

    // Détecter le sentiment
    entities['sentiment'] = _detectSentiment(text);

    // Détecter l'urgence
    entities['urgency'] = _detectUrgency(text);

    return entities;
  }

  /// Extrait les montants
  static Map<String, dynamic> _extractAmounts(String text) {
    final entities = <String, dynamic>{};

    // Patterns pour les montants
    final patterns = [
      RegExp(r'(\d+(?:[.,]\d{1,2})?)\s*(?:€|euros?|eur)', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d{1,2})?)\s*(?:balles?|boules?)', caseSensitive: false),
      RegExp(r'(?:de\s+)?(\d+(?:[.,]\d{1,2})?)\s*(?:€|euros?)?', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final amount = double.tryParse(match.group(1)!.replaceAll(',', '.'));
        if (amount != null && amount > 0) {
          entities['amount'] = amount;
          break;
        }
      }
    }

    return entities;
  }

  /// Extrait les périodes
  static Map<String, dynamic> _extractPeriods(String text) {
    final entities = <String, dynamic>{};

    // Aujourd'hui
    if (RegExp(r"aujourd'?hui|ce jour|maintenant|auj").hasMatch(text)) {
      entities['period'] = 'today';
    }
    // Cette semaine
    else if (RegExp(r'cette semaine|semaine|7 jours|sept jours|hebdo').hasMatch(text)) {
      entities['period'] = 'week';
    }
    // Ce mois
    else if (RegExp(r'ce mois|mois-ci|mensuel|30 jours').hasMatch(text)) {
      entities['period'] = 'month';
    }
    // Cette année
    else if (RegExp(r'cette année|annee|an |annuel|12 mois').hasMatch(text)) {
      entities['period'] = 'year';
    }
    // Hier
    else if (RegExp(r'hier').hasMatch(text)) {
      entities['period'] = 'yesterday';
    }
    // Semaine dernière
    else if (RegExp(r'semaine dernière|semaine passée').hasMatch(text)) {
      entities['period'] = 'last_week';
    }
    // Mois dernier
    else if (RegExp(r'mois dernier|mois passé|mois précédent').hasMatch(text)) {
      entities['period'] = 'last_month';
    }

    return entities;
  }

  /// Extrait les catégories
  static Map<String, dynamic> _extractCategories(String text) {
    final entities = <String, dynamic>{};

    final allCategories = [
      ...AIKnowledgeBase.essentialCategories,
      ...AIKnowledgeBase.nonEssentialCategories,
    ];

    // Recherche exacte
    for (final category in allCategories) {
      if (text.contains(category.toLowerCase())) {
        entities['category'] = category;
        return entities;
      }
    }

    // Recherche fuzzy
    final tokens = text.split(RegExp(r'\s+'));
    for (final token in tokens) {
      if (token.length < 4) continue;

      for (final category in allCategories) {
        final similarity = wordSimilarity(token, category.toLowerCase());
        if (similarity > 0.75) {
          entities['category'] = category;
          entities['categoryConfidence'] = similarity;
          return entities;
        }
      }
    }

    return entities;
  }

  /// Extrait les pourcentages
  static Map<String, dynamic> _extractPercentages(String text) {
    final entities = <String, dynamic>{};

    final percentageMatch = RegExp(r'(\d+)\s*(?:%|pour ?cent|pourcent)').firstMatch(text);
    if (percentageMatch != null) {
      entities['percentage'] = int.tryParse(percentageMatch.group(1)!);
    }

    return entities;
  }

  // ==================== ANALYSE DE SENTIMENT ====================

  /// Détecte le sentiment du message
  static String _detectSentiment(String text) {
    final positiveWords = [
      'bien', 'super', 'genial', 'content', 'heureux', 'top', 'excellent',
      'parfait', 'nickel', 'cool', 'chouette', 'formidable', 'bravo', 'youpi',
      'merci', 'thanks', 'yes', 'oui', 'ok', 'génial',
    ];

    final negativeWords = [
      'mal', 'probleme', 'difficile', 'galere', 'souci', 'inquiet', 'stress',
      'dette', 'merde', 'nul', 'horrible', 'catastrophe', 'panique', 'aide',
      'rouge', 'fauché', 'sec', 'mort', 'foutu', 'grillé', 'explosé',
    ];

    final questionWords = [
      'comment', 'pourquoi', 'quand', 'combien', 'quel', 'quelle', 'où', 'ou',
      'est-ce', 'puis-je', 'peux-tu', 'sais-tu', 'c\'est quoi',
    ];

    int positiveScore = 0;
    int negativeScore = 0;
    int questionScore = 0;

    for (final word in positiveWords) {
      if (text.contains(word)) positiveScore++;
    }
    for (final word in negativeWords) {
      if (text.contains(word)) negativeScore++;
    }
    for (final word in questionWords) {
      if (text.contains(word)) questionScore++;
    }

    // Détecter les négations qui inversent le sentiment
    if (RegExp(r'pas\s+(?:bien|super|top|content)').hasMatch(text)) {
      positiveScore--;
      negativeScore++;
    }

    if (questionScore > 0 && positiveScore == 0 && negativeScore == 0) {
      return 'curious';
    }
    if (negativeScore > positiveScore + 1) return 'worried';
    if (negativeScore > positiveScore) return 'concerned';
    if (positiveScore > negativeScore + 1) return 'happy';
    if (positiveScore > negativeScore) return 'positive';

    return 'neutral';
  }

  /// Détecte l'urgence du message
  static String _detectUrgency(String text) {
    final urgentWords = [
      'urgent', 'vite', 'rapidement', 'maintenant', 'immédiatement',
      'tout de suite', 'asap', 'help', 'sos', 'au secours', 'panique',
    ];

    final importantWords = [
      'important', 'besoin', 'dois', 'faut', 'nécessaire', 'obligé',
    ];

    for (final word in urgentWords) {
      if (text.contains(word)) return 'urgent';
    }
    for (final word in importantWords) {
      if (text.contains(word)) return 'important';
    }

    // Détecter l'exclamation multiple comme urgence
    if (RegExp(r'!{2,}').hasMatch(text)) return 'urgent';

    return 'normal';
  }

  // ==================== GÉNÉRATION DE SUGGESTIONS ====================

  /// Génère des suggestions contextuelles
  static List<String> generateSuggestions(String lastIntent, Map<String, dynamic> context) {
    // Suggestions basées sur l'historique
    final recentIntents = context['recentIntents'] as List<String>? ?? [];

    // Éviter de répéter les mêmes suggestions
    final usedSuggestions = context['usedSuggestions'] as Set<String>? ?? {};

    final suggestions = <String>[];

    switch (lastIntent) {
      case 'spending':
      case 'spending_today':
      case 'spending_week':
      case 'spending_month':
        suggestions.addAll([
          'Répartition par catégorie',
          'Comparer au mois dernier',
          'Mes plus grosses dépenses',
          'Où puis-je économiser ?',
        ]);
        break;

      case 'budget':
        suggestions.addAll([
          'Comment économiser plus ?',
          'Prédiction fin de mois',
          'Conseils personnalisés',
          'Voir mes catégories',
        ]);
        break;

      case 'savings':
        suggestions.addAll([
          'Créer un objectif',
          'Astuces pour épargner',
          'Mon taux d\'épargne',
          'Simuler une économie',
        ]);
        break;

      case 'advice':
        suggestions.addAll([
          'Analyser mes dépenses',
          'Plan d\'économies',
          'Mes points faibles',
          'Comparaison mensuelle',
        ]);
        break;

      case 'balance':
        suggestions.addAll([
          'Mes dépenses du mois',
          'État de mon budget',
          'Prédiction fin de mois',
          'Mes objectifs',
        ]);
        break;

      case 'category':
        suggestions.addAll([
          'Détail de la catégorie',
          'Comparer les catégories',
          'Tendance mensuelle',
          'Conseils pour réduire',
        ]);
        break;

      case 'problem':
        suggestions.addAll([
          'Plan d\'action',
          'Où réduire en urgence',
          'Créer un budget strict',
          'Conseils de survie',
        ]);
        break;

      default:
        // Suggestions de base variées
        if (!recentIntents.contains('spending')) {
          suggestions.add('Mes dépenses');
        }
        if (!recentIntents.contains('balance')) {
          suggestions.add('Mon solde');
        }
        if (!recentIntents.contains('advice')) {
          suggestions.add('Un conseil');
        }
        suggestions.add('Mon résumé');
    }

    // Filtrer les suggestions déjà utilisées récemment
    return suggestions.where((s) => !usedSuggestions.contains(s)).take(3).toList();
  }

  /// Calcule la similarité entre deux textes (Jaccard amélioré)
  static double calculateSimilarity(String text1, String text2) {
    final tokens1 = _tokenize(_normalizeText(text1)).toSet();
    final tokens2 = _tokenize(_normalizeText(text2)).toSet();

    if (tokens1.isEmpty || tokens2.isEmpty) return 0.0;

    final intersection = tokens1.intersection(tokens2).length;
    final union = tokens1.union(tokens2).length;

    // Jaccard similarity avec bonus pour correspondances exactes
    double similarity = intersection / union;

    // Bonus si le texte plus court est entièrement contenu
    final smaller = tokens1.length < tokens2.length ? tokens1 : tokens2;
    final containedRatio = intersection / smaller.length;
    if (containedRatio > 0.8) {
      similarity += 0.1;
    }

    return similarity.clamp(0.0, 1.0);
  }
}

/// Classe améliorée pour gérer le contexte de conversation
class ConversationMemory {
  final List<String> _recentIntents = [];
  final Map<String, dynamic> _userPreferences = {};
  final Map<String, int> _topicFrequency = {};
  final List<Map<String, dynamic>> _conversationHistory = [];
  final Set<String> _usedSuggestions = {};
  DateTime? _lastInteraction;

  /// Ajoute une intention au contexte
  void addIntent(String intent, {Map<String, dynamic>? entities}) {
    _recentIntents.add(intent);
    if (_recentIntents.length > 10) {
      _recentIntents.removeAt(0);
    }

    _topicFrequency[intent] = (_topicFrequency[intent] ?? 0) + 1;

    _conversationHistory.add({
      'intent': intent,
      'entities': entities,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (_conversationHistory.length > 20) {
      _conversationHistory.removeAt(0);
    }

    _lastInteraction = DateTime.now();
  }

  /// Marque une suggestion comme utilisée
  void markSuggestionUsed(String suggestion) {
    _usedSuggestions.add(suggestion);
    // Nettoyer les anciennes après 5 suggestions
    if (_usedSuggestions.length > 5) {
      _usedSuggestions.remove(_usedSuggestions.first);
    }
  }

  /// Obtient le contexte pour la génération de suggestions
  Map<String, dynamic> getSuggestionContext() {
    return {
      'recentIntents': _recentIntents,
      'usedSuggestions': _usedSuggestions,
      'mostFrequentTopic': getMostFrequentTopic(),
    };
  }

  /// Obtient le sujet le plus fréquent
  String? getMostFrequentTopic() {
    if (_topicFrequency.isEmpty) return null;

    return _topicFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Vérifie si l'utilisateur répète une question
  bool isRepeatingQuestion(String intent) {
    if (_recentIntents.length < 2) return false;
    return _recentIntents.last == intent;
  }

  /// Compte les répétitions d'un sujet
  int getRepetitionCount(String intent) {
    return _topicFrequency[intent] ?? 0;
  }

  /// Vérifie si c'est une nouvelle session
  bool isNewSession() {
    if (_lastInteraction == null) return true;
    return DateTime.now().difference(_lastInteraction!).inMinutes > 30;
  }

  /// Obtient le dernier intent
  String? getLastIntent() {
    return _recentIntents.isNotEmpty ? _recentIntents.last : null;
  }

  /// Obtient les intentions récentes
  List<String> getRecentIntents() => List.unmodifiable(_recentIntents);

  /// Définit une préférence utilisateur
  void setPreference(String key, dynamic value) {
    _userPreferences[key] = value;
  }

  /// Obtient une préférence utilisateur
  dynamic getPreference(String key) => _userPreferences[key];

  /// Obtient l'historique de conversation
  List<Map<String, dynamic>> getConversationHistory() {
    return List.unmodifiable(_conversationHistory);
  }

  /// Réinitialise la mémoire
  void clear() {
    _recentIntents.clear();
    _userPreferences.clear();
    _topicFrequency.clear();
    _conversationHistory.clear();
    _usedSuggestions.clear();
    _lastInteraction = null;
  }
}
