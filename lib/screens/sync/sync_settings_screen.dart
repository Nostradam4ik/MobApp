import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../services/sync_service.dart';
import '../../services/offline_database_service.dart';

/// Écran de paramètres de synchronisation
class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  bool _isLoading = false;
  bool _offlineModeEnabled = false;
  DateTime? _lastSyncTime;
  int _pendingSyncCount = 0;
  bool _hasLocalData = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final offlineMode = await SyncService.isOfflineModeEnabled();
      final lastSync = await SyncService.getLastSyncTime();

      // Ces appels peuvent échouer sur web car sqflite n'est pas supporté
      int pendingCount = 0;
      bool hasData = false;
      try {
        pendingCount = await OfflineDatabaseService.getPendingSyncCount();
        hasData = await OfflineDatabaseService.hasLocalData();
      } catch (e) {
        // SQLite non disponible (probablement sur web)
        debugPrint('SQLite not available: $e');
      }

      if (mounted) {
        setState(() {
          _offlineModeEnabled = offlineMode;
          _lastSyncTime = lastSync;
          _pendingSyncCount = pendingCount;
          _hasLocalData = hasData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur de chargement: $e';
        });
      }
    }
  }

  Future<void> _toggleOfflineMode(bool value) async {
    setState(() => _offlineModeEnabled = value);
    await SyncService.setOfflineMode(value);

    if (!value && SyncService.isOnline) {
      // Si on désactive le mode hors-ligne, synchroniser
      await _forceSync();
    }
  }

  Future<void> _forceSync() async {
    setState(() => _isLoading = true);

    final result = await SyncService.forceSync();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppColors.success : AppColors.error,
        ),
      );
    }

    await _loadData();
  }

  Future<void> _initialSync() async {
    setState(() => _isLoading = true);

    try {
      await SyncService.initialSync();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synchronisation initiale terminée'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    await _loadData();
  }

  Future<void> _clearLocalData() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Effacer les données locales ?',
          style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        ),
        content: Text(
          'Cette action supprimera toutes les données hors-ligne. Les données sur le serveur ne seront pas affectées.',
          style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await OfflineDatabaseService.clearAllData();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Données locales effacées'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        title: Text(
          'Synchronisation',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Statut de connexion
                _buildStatusCard(isDark: isDark),
                const SizedBox(height: 20),

                // Mode hors-ligne
                _buildSectionHeader(
                  icon: Icons.cloud_off_rounded,
                  title: 'Mode hors-ligne',
                  color: AppColors.warning,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  isDark: isDark,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.offline_bolt_rounded,
                      title: 'Activer le mode hors-ligne',
                      subtitle: 'Travaillez sans connexion internet',
                      value: _offlineModeEnabled,
                      onChanged: _toggleOfflineMode,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Synchronisation
                _buildSectionHeader(
                  icon: Icons.sync_rounded,
                  title: 'Synchronisation',
                  color: AppColors.primary,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  isDark: isDark,
                  children: [
                    _buildInfoTile(
                      icon: Icons.schedule_rounded,
                      title: 'Dernière synchronisation',
                      value: _lastSyncTime != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(_lastSyncTime!)
                          : 'Jamais',
                      isDark: isDark,
                    ),
                    Divider(color: isDark ? AppColors.dividerDark : AppColors.divider, height: 1),
                    _buildInfoTile(
                      icon: Icons.pending_actions_rounded,
                      title: 'En attente de sync',
                      value: '$_pendingSyncCount opérations',
                      valueColor: _pendingSyncCount > 0 ? AppColors.warning : null,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Actions
                _buildSectionHeader(
                  icon: Icons.settings_rounded,
                  title: 'Actions',
                  color: AppColors.secondary,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                _buildActionButton(
                  icon: Icons.sync_rounded,
                  title: 'Synchroniser maintenant',
                  subtitle: 'Envoyer et recevoir les modifications',
                  color: AppColors.primary,
                  onTap: _forceSync,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                _buildActionButton(
                  icon: Icons.download_rounded,
                  title: 'Synchronisation complète',
                  subtitle: 'Télécharger toutes les données (6 mois)',
                  color: AppColors.secondary,
                  onTap: _initialSync,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                _buildActionButton(
                  icon: Icons.delete_outline_rounded,
                  title: 'Effacer les données locales',
                  subtitle: 'Supprimer le cache hors-ligne',
                  color: AppColors.error,
                  onTap: _clearLocalData,
                  isDark: isDark,
                ),

                const SizedBox(height: 24),

                // Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary.withOpacity(0.8),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Les données sont automatiquement synchronisées toutes les 5 minutes lorsque vous êtes en ligne.',
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusCard({required bool isDark}) {
    final isOnline = SyncService.isOnline && !_offlineModeEnabled;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isOnline
              ? [AppColors.success.withOpacity(0.2), AppColors.success.withOpacity(0.1)]
              : [AppColors.warning.withOpacity(0.2), AppColors.warning.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline
              ? AppColors.success.withOpacity(0.3)
              : AppColors.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOnline
                  ? AppColors.success.withOpacity(0.2)
                  : AppColors.warning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: isOnline ? AppColors.success : AppColors.warning,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'En ligne' : 'Hors-ligne',
                  style: TextStyle(
                    color: isOnline ? AppColors.success : AppColors.warning,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOnline
                      ? 'Toutes les données sont synchronisées'
                      : 'Les modifications seront synchronisées plus tard',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (_hasLocalData)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Cache actif',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard({required List<Widget> children, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: value
                  ? AppColors.warning.withOpacity(0.2)
                  : isDark ? AppColors.backgroundDark : AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: value ? AppColors.warning : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.warning,
            activeTrackColor: AppColors.warning.withOpacity(0.4),
            inactiveThumbColor: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            inactiveTrackColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
              fontSize: 14,
              fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
