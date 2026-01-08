import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service de reconnaissance vocale pour ajouter des dépenses
/// Utilise speech_to_text pour la reconnaissance vocale
class VoiceService {
  static VoiceService? _instance;

  bool _isInitialized = false;
  bool _isListening = false;
  String _lastRecognizedText = '';

  // Callbacks
  final _onResultCallbacks = <void Function(VoiceResult)>[];
  final _onStatusCallbacks = <void Function(VoiceStatus)>[];
  final _onErrorCallbacks = <void Function(String)>[];

  VoiceService._();

  static VoiceService getInstance() {
    _instance ??= VoiceService._();
    return _instance!;
  }

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastRecognizedText => _lastRecognizedText;

  /// Initialise le service de reconnaissance vocale
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Note: L'implémentation réelle utilisera speech_to_text
      // Pour l'instant, on simule l'initialisation
      _isInitialized = true;
      return true;
    } catch (e) {
      _notifyError('Erreur d\'initialisation: $e');
      return false;
    }
  }

  /// Démarre l'écoute vocale
  Future<bool> startListening({
    String locale = 'fr-FR',
    Duration? listenFor,
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return false;
    }

    if (_isListening) return true;

    try {
      _isListening = true;
      _notifyStatus(VoiceStatus.listening);

      // Timeout automatique si spécifié
      if (listenFor != null) {
        Future.delayed(listenFor, () {
          if (_isListening) {
            stopListening();
          }
        });
      }

      return true;
    } catch (e) {
      _isListening = false;
      _notifyError('Erreur de démarrage: $e');
      return false;
    }
  }

  /// Arrête l'écoute vocale
  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;
    _notifyStatus(VoiceStatus.notListening);
  }

  /// Annule l'écoute en cours
  Future<void> cancel() async {
    _isListening = false;
    _lastRecognizedText = '';
    _notifyStatus(VoiceStatus.cancelled);
  }

  /// Parse le texte reconnu pour extraire les données de dépense
  ExpenseVoiceData? parseExpenseFromVoice(String text) {
    final parser = VoiceExpenseParser();
    return parser.parse(text);
  }

  // ==================== CALLBACKS ====================

  void addResultListener(void Function(VoiceResult) callback) {
    _onResultCallbacks.add(callback);
  }

  void removeResultListener(void Function(VoiceResult) callback) {
    _onResultCallbacks.remove(callback);
  }

  void addStatusListener(void Function(VoiceStatus) callback) {
    _onStatusCallbacks.add(callback);
  }

  void removeStatusListener(void Function(VoiceStatus) callback) {
    _onStatusCallbacks.remove(callback);
  }

  void addErrorListener(void Function(String) callback) {
    _onErrorCallbacks.add(callback);
  }

  void removeErrorListener(void Function(String) callback) {
    _onErrorCallbacks.remove(callback);
  }

  void _notifyResult(VoiceResult result) {
    _lastRecognizedText = result.text;
    for (final callback in _onResultCallbacks) {
      callback(result);
    }
  }

  void _notifyStatus(VoiceStatus status) {
    for (final callback in _onStatusCallbacks) {
      callback(status);
    }
  }

  void _notifyError(String error) {
    for (final callback in _onErrorCallbacks) {
      callback(error);
    }
  }

  /// Simule un résultat vocal (pour les tests)
  @visibleForTesting
  void simulateResult(String text, {bool isFinal = true}) {
    _notifyResult(VoiceResult(
      text: text,
      confidence: 0.9,
      isFinal: isFinal,
    ));
  }

  void dispose() {
    _onResultCallbacks.clear();
    _onStatusCallbacks.clear();
    _onErrorCallbacks.clear();
    _isInitialized = false;
    _isListening = false;
  }
}

/// Parser pour extraire les données de dépense d'un texte vocal
class VoiceExpenseParser {
  // Patterns pour les montants
  static final _amountPatterns = [
    RegExp(r'(\d+(?:[.,]\d{1,2})?)\s*(?:euros?|€)', caseSensitive: false),
    RegExp(r'(\d+(?:[.,]\d{1,2})?)\s*(?:dollars?|\$)', caseSensitive: false),
    RegExp(r'(\d+(?:[.,]\d{1,2})?)(?:\s|$)'),
  ];

  // Mots-clés pour les catégories
  static final _categoryKeywords = <String, List<String>>{
    'Alimentation': ['courses', 'supermarché', 'nourriture', 'alimentaire', 'marché'],
    'Restaurant': ['restaurant', 'resto', 'manger', 'déjeuner', 'dîner', 'repas'],
    'Transport': ['transport', 'métro', 'bus', 'train', 'taxi', 'uber', 'essence', 'carburant'],
    'Loisirs': ['cinéma', 'film', 'concert', 'sortie', 'loisir', 'divertissement'],
    'Shopping': ['vêtements', 'habits', 'shopping', 'achat', 'magasin'],
    'Santé': ['pharmacie', 'médecin', 'docteur', 'santé', 'médicament'],
    'Logement': ['loyer', 'électricité', 'eau', 'gaz', 'facture'],
    'Café': ['café', 'coffee', 'starbucks'],
  };

  // Mots-clés temporels
  static final _dateKeywords = <String, int>{
    'aujourd\'hui': 0,
    'hier': -1,
    'avant-hier': -2,
    'lundi': -1, // Dernier lundi
    'mardi': -1,
    'mercredi': -1,
    'jeudi': -1,
    'vendredi': -1,
    'samedi': -1,
    'dimanche': -1,
  };

  /// Parse un texte vocal pour extraire les données de dépense
  ExpenseVoiceData? parse(String text) {
    if (text.isEmpty) return null;

    final lowerText = text.toLowerCase().trim();

    // Extraire le montant
    double? amount;
    for (final pattern in _amountPatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(',', '.');
        amount = double.tryParse(amountStr);
        if (amount != null) break;
      }
    }

    // Extraire la catégorie
    String? category;
    double categoryConfidence = 0;
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          category = entry.key;
          categoryConfidence = 0.8;
          break;
        }
      }
      if (category != null) break;
    }

    // Extraire la date
    DateTime date = DateTime.now();
    for (final entry in _dateKeywords.entries) {
      if (lowerText.contains(entry.key)) {
        date = DateTime.now().add(Duration(days: entry.value));
        break;
      }
    }

    // Extraire la note (le reste du texte)
    String? note = _extractNote(text, amount, category);

    // Vérifier si on a au moins un montant
    if (amount == null) {
      return ExpenseVoiceData(
        rawText: text,
        isValid: false,
        errorMessage: 'Aucun montant détecté',
      );
    }

    return ExpenseVoiceData(
      rawText: text,
      amount: amount,
      category: category,
      categoryConfidence: categoryConfidence,
      note: note,
      date: date,
      isValid: true,
    );
  }

  String? _extractNote(String text, double? amount, String? category) {
    var note = text;

    // Retirer le montant
    if (amount != null) {
      note = note.replaceAll(RegExp(r'\d+(?:[.,]\d{1,2})?\s*(?:euros?|€)?', caseSensitive: false), '');
    }

    // Retirer les mots-clés de catégorie
    if (category != null) {
      for (final keyword in _categoryKeywords[category]!) {
        note = note.replaceAll(RegExp(keyword, caseSensitive: false), '');
      }
    }

    // Nettoyer
    note = note.replaceAll(RegExp(r'\s+'), ' ').trim();

    return note.isNotEmpty ? note : null;
  }

  /// Génère des suggestions basées sur l'historique
  List<String> getSuggestions(List<ExpenseVoiceData> history) {
    if (history.isEmpty) {
      return [
        'Dis par exemple: "15 euros au restaurant"',
        '"Courses 45 euros hier"',
        '"Café 3,50 euros"',
      ];
    }

    // Analyser l'historique pour des suggestions personnalisées
    final categoryCounts = <String, int>{};
    for (final data in history) {
      if (data.category != null) {
        categoryCounts[data.category!] = (categoryCounts[data.category!] ?? 0) + 1;
      }
    }

    final topCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return topCategories.take(3).map((e) => 'Dépense ${e.key}?').toList();
  }
}

/// Résultat de reconnaissance vocale
class VoiceResult {
  final String text;
  final double confidence;
  final bool isFinal;

  const VoiceResult({
    required this.text,
    required this.confidence,
    required this.isFinal,
  });
}

/// Statut du service vocal
enum VoiceStatus {
  notListening,
  listening,
  processing,
  done,
  cancelled,
  error,
}

/// Données de dépense extraites du vocal
class ExpenseVoiceData {
  final String rawText;
  final double? amount;
  final String? category;
  final double categoryConfidence;
  final String? note;
  final DateTime? date;
  final bool isValid;
  final String? errorMessage;

  const ExpenseVoiceData({
    required this.rawText,
    this.amount,
    this.category,
    this.categoryConfidence = 0,
    this.note,
    this.date,
    required this.isValid,
    this.errorMessage,
  });

  /// Génère un message de confirmation
  String get confirmationMessage {
    if (!isValid) return errorMessage ?? 'Données invalides';

    final parts = <String>[];
    if (amount != null) {
      parts.add('${amount!.toStringAsFixed(2)}€');
    }
    if (category != null) {
      parts.add('dans $category');
    }
    if (note != null && note!.isNotEmpty) {
      parts.add('"$note"');
    }
    if (date != null) {
      final now = DateTime.now();
      final diff = now.difference(date!).inDays;
      if (diff == 0) {
        parts.add('aujourd\'hui');
      } else if (diff == 1) {
        parts.add('hier');
      }
    }

    return parts.join(' ');
  }

  @override
  String toString() => 'ExpenseVoiceData(amount: $amount, category: $category, isValid: $isValid)';
}
