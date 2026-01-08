import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../services/receipt_scanner_service.dart';

/// Écran de scan de ticket
class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  bool _isLoading = false;
  ReceiptScanResult? _scanResult;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner un ticket'),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _scanResult != null
              ? _buildResultState()
              : _buildInitialState(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Analyse en cours...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Extraction des informations du ticket',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiaryDark,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),

          // Titre
          Text(
            'Scanner un ticket de caisse',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            'Prenez une photo de votre ticket ou sélectionnez une image depuis votre galerie pour extraire automatiquement le montant.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Erreur si présente
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Boutons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Appareil photo',
                  onTap: _scanFromCamera,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Galerie',
                  onTap: _scanFromGallery,
                  isPrimary: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Conseils
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.glassDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: AppColors.accentGold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Conseils pour un meilleur scan',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTip('Assurez-vous que le ticket est bien éclairé'),
                _buildTip('Placez le ticket sur une surface plate'),
                _buildTip('Évitez les reflets et les ombres'),
                _buildTip('Cadrez le total du ticket'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary ? AppColors.primary : AppColors.glassDark,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isPrimary ? Colors.white : AppColors.textPrimaryDark,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultState() {
    final result = _scanResult!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statut
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: result.success
                  ? AppColors.secondary.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.warning,
                  color: result.success ? AppColors.secondary : AppColors.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.success
                        ? 'Ticket analysé avec succès'
                        : 'Analyse partielle - vérifiez les informations',
                    style: TextStyle(
                      color: result.success ? AppColors.secondary : AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Montant total
          if (result.totalAmount != null) ...[
            Text(
              'Montant détecté',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${result.totalAmount!.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Magasin
          if (result.storeName != null) ...[
            _buildInfoRow('Magasin', result.storeName!, Icons.store),
            const SizedBox(height: 12),
          ],

          // Date
          if (result.date != null) ...[
            _buildInfoRow(
              'Date',
              '${result.date!.day.toString().padLeft(2, '0')}/${result.date!.month.toString().padLeft(2, '0')}/${result.date!.year}',
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),
          ],

          // Articles détectés
          if (result.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Articles détectés (${result.items.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.glassDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: result.items.length.clamp(0, 10),
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppColors.divider,
                ),
                itemBuilder: (context, index) {
                  final item = result.items[index];
                  return ListTile(
                    dense: true,
                    title: Text(item.name),
                    trailing: item.price != null
                        ? Text(
                            '${item.price!.toStringAsFixed(2)} €',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Boutons d'action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: result.totalAmount != null ? _useAmount : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Utiliser ce montant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _resetScan,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Scanner un autre ticket'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.glassDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiaryDark,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanFromCamera() async {
    // Vérifier la permission caméra
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _error = 'Permission caméra refusée. Activez-la dans les paramètres.';
      });
      return;
    }

    await _performScan(ReceiptScannerService.scanFromCamera);
  }

  Future<void> _scanFromGallery() async {
    await _performScan(ReceiptScannerService.scanFromGallery);
  }

  Future<void> _performScan(Future<ReceiptScanResult> Function() scanMethod) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await scanMethod();

      setState(() {
        _isLoading = false;
        if (result.success || result.totalAmount != null) {
          _scanResult = result;
          _error = null;
        } else {
          _error = result.error ?? 'Impossible d\'extraire les informations du ticket';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erreur: $e';
      });
    }
  }

  void _useAmount() {
    if (_scanResult?.totalAmount == null) return;

    // Naviguer vers l'écran d'ajout avec le montant pré-rempli
    context.push(AppRoutes.addExpense, extra: {
      'amount': _scanResult!.totalAmount,
      'date': _scanResult!.date,
      'note': _scanResult!.storeName,
    });
  }

  void _resetScan() {
    setState(() {
      _scanResult = null;
      _error = null;
    });
  }
}
