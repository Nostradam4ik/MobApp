import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Résultat du scan d'un ticket
class ReceiptScanResult {
  final double? totalAmount;
  final DateTime? date;
  final String? storeName;
  final List<ReceiptItem> items;
  final String rawText;
  final bool success;
  final String? error;

  ReceiptScanResult({
    this.totalAmount,
    this.date,
    this.storeName,
    this.items = const [],
    this.rawText = '',
    this.success = false,
    this.error,
  });

  factory ReceiptScanResult.error(String message) {
    return ReceiptScanResult(
      success: false,
      error: message,
    );
  }
}

/// Élément d'un ticket
class ReceiptItem {
  final String name;
  final double? price;
  final int quantity;

  ReceiptItem({
    required this.name,
    this.price,
    this.quantity = 1,
  });
}

/// Service de scan de tickets avec OCR
class ReceiptScannerService {
  ReceiptScannerService._();

  static final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  static final _imagePicker = ImagePicker();

  /// Patterns pour extraire les données
  static final _totalPatterns = [
    RegExp(r'total[:\s]+(\d+[.,]\d{2})', caseSensitive: false),
    RegExp(r'tot[:\s]+(\d+[.,]\d{2})', caseSensitive: false),
    RegExp(r'ttc[:\s]+(\d+[.,]\d{2})', caseSensitive: false),
    RegExp(r'à\s*payer[:\s]+(\d+[.,]\d{2})', caseSensitive: false),
    RegExp(r'montant[:\s]+(\d+[.,]\d{2})', caseSensitive: false),
    RegExp(r'(\d+[.,]\d{2})\s*€?\s*$'),
  ];

  static final _datePatterns = [
    RegExp(r'(\d{2})[/.-](\d{2})[/.-](\d{4})'),
    RegExp(r'(\d{2})[/.-](\d{2})[/.-](\d{2})'),
    RegExp(r'(\d{4})[/.-](\d{2})[/.-](\d{2})'),
  ];

  /// Capture une image depuis la caméra et analyse le ticket
  static Future<ReceiptScanResult> scanFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (image == null) {
        return ReceiptScanResult.error('Capture annulée');
      }

      return await _processImage(File(image.path));
    } catch (e) {
      return ReceiptScanResult.error('Erreur lors de la capture: $e');
    }
  }

  /// Sélectionne une image depuis la galerie et analyse le ticket
  static Future<ReceiptScanResult> scanFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) {
        return ReceiptScanResult.error('Sélection annulée');
      }

      return await _processImage(File(image.path));
    } catch (e) {
      return ReceiptScanResult.error('Erreur lors de la sélection: $e');
    }
  }

  /// Analyse une image de ticket
  static Future<ReceiptScanResult> _processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        return ReceiptScanResult.error('Aucun texte détecté sur l\'image');
      }

      return _parseReceipt(recognizedText.text);
    } catch (e) {
      return ReceiptScanResult.error('Erreur lors de l\'analyse: $e');
    }
  }

  /// Parse le texte du ticket pour extraire les informations
  static ReceiptScanResult _parseReceipt(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // Extraire le total
    double? totalAmount;
    for (final pattern in _totalPatterns) {
      for (final line in lines.reversed) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final amountStr = match.group(1)?.replaceAll(',', '.');
          if (amountStr != null) {
            final amount = double.tryParse(amountStr);
            if (amount != null && amount > 0 && amount < 10000) {
              totalAmount = amount;
              break;
            }
          }
        }
      }
      if (totalAmount != null) break;
    }

    // Si pas de total trouvé, chercher le plus grand montant
    if (totalAmount == null) {
      final amountPattern = RegExp(r'(\d+[.,]\d{2})');
      double maxAmount = 0;
      for (final line in lines) {
        final matches = amountPattern.allMatches(line);
        for (final match in matches) {
          final amountStr = match.group(1)?.replaceAll(',', '.');
          if (amountStr != null) {
            final amount = double.tryParse(amountStr);
            if (amount != null && amount > maxAmount && amount < 10000) {
              maxAmount = amount;
            }
          }
        }
      }
      if (maxAmount > 0) {
        totalAmount = maxAmount;
      }
    }

    // Extraire la date
    DateTime? date;
    for (final pattern in _datePatterns) {
      for (final line in lines) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          try {
            if (match.groupCount >= 3) {
              int day, month, year;
              if (match.group(1)!.length == 4) {
                // Format YYYY-MM-DD
                year = int.parse(match.group(1)!);
                month = int.parse(match.group(2)!);
                day = int.parse(match.group(3)!);
              } else {
                // Format DD-MM-YYYY ou DD-MM-YY
                day = int.parse(match.group(1)!);
                month = int.parse(match.group(2)!);
                year = int.parse(match.group(3)!);
                if (year < 100) year += 2000;
              }

              if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
                date = DateTime(year, month, day);
                break;
              }
            }
          } catch (_) {
            continue;
          }
        }
      }
      if (date != null) break;
    }

    // Extraire le nom du magasin (souvent dans les premières lignes)
    String? storeName;
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i].toUpperCase();
      // Chercher des noms de magasins connus ou des lignes en majuscules
      if (_isStoreName(line)) {
        storeName = lines[i];
        break;
      }
    }

    // Extraire les articles (lignes avec prix)
    final items = <ReceiptItem>[];
    final itemPattern = RegExp(r'(.+?)\s+(\d+[.,]\d{2})\s*€?$');
    for (final line in lines) {
      if (line.toLowerCase().contains('total')) continue;
      if (line.toLowerCase().contains('ttc')) continue;

      final match = itemPattern.firstMatch(line);
      if (match != null) {
        final name = match.group(1)?.trim();
        final priceStr = match.group(2)?.replaceAll(',', '.');
        if (name != null && name.length > 2 && priceStr != null) {
          final price = double.tryParse(priceStr);
          if (price != null && price > 0 && price < 1000) {
            items.add(ReceiptItem(name: name, price: price));
          }
        }
      }
    }

    return ReceiptScanResult(
      totalAmount: totalAmount,
      date: date,
      storeName: storeName,
      items: items,
      rawText: text,
      success: totalAmount != null,
    );
  }

  /// Vérifie si une ligne ressemble à un nom de magasin
  static bool _isStoreName(String line) {
    // Liste de magasins connus
    final knownStores = [
      'CARREFOUR', 'LECLERC', 'AUCHAN', 'LIDL', 'ALDI', 'INTERMARCHE',
      'CASINO', 'MONOPRIX', 'FRANPRIX', 'SIMPLY', 'SUPER U', 'HYPER U',
      'GEANT', 'CORA', 'MATCH', 'PICARD', 'BIOCOOP', 'NATURALIA',
      'SEPHORA', 'FNAC', 'DARTY', 'BOULANGER', 'DECATHLON', 'IKEA',
      'LEROY MERLIN', 'CASTORAMA', 'BRICORAMA', 'MR BRICOLAGE',
      'ZARA', 'H&M', 'PRIMARK', 'KIABI', 'CELIO', 'JULES',
      'STARBUCKS', 'MCDONALD', 'BURGER KING', 'KFC', 'SUBWAY',
      'AMAZON', 'APPLE', 'SAMSUNG',
    ];

    for (final store in knownStores) {
      if (line.contains(store)) return true;
    }

    // Si la ligne est en majuscules et fait entre 3 et 30 caractères
    if (line == line.toUpperCase() &&
        line.length >= 3 &&
        line.length <= 30 &&
        !RegExp(r'\d+[.,]\d{2}').hasMatch(line)) {
      return true;
    }

    return false;
  }

  /// Libère les ressources
  static void dispose() {
    _textRecognizer.close();
  }
}
