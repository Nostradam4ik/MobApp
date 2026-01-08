import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/notification_service.dart';

/// Écran de paramètres de notifications
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _dailyReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _budgetAlertsEnabled = true;
  bool _goalAlertsEnabled = true;
  bool _weeklySummaryEnabled = false;
  bool _isLoading = true;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final dailyReminder = await NotificationService.isDailyReminderEnabled();
    final reminderTime = await NotificationService.getReminderTime();
    final budgetAlerts = await NotificationService.areBudgetAlertsEnabled();
    final goalAlerts = await NotificationService.areGoalAlertsEnabled();
    final weeklySummary = await NotificationService.isWeeklySummaryEnabled();

    setState(() {
      _dailyReminderEnabled = dailyReminder;
      _reminderTime = reminderTime;
      _budgetAlertsEnabled = budgetAlerts;
      _goalAlertsEnabled = goalAlerts;
      _weeklySummaryEnabled = weeklySummary;
      _isLoading = false;
    });
  }

  Future<void> _requestPermission() async {
    final granted = await NotificationService.requestPermissions();
    setState(() {
      _permissionGranted = granted;
    });

    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez activer les notifications dans les paramètres'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _toggleDailyReminder(bool value) async {
    if (value && !_permissionGranted) {
      await _requestPermission();
      if (!_permissionGranted) return;
    }

    setState(() => _dailyReminderEnabled = value);
    await NotificationService.setDailyReminderEnabled(value);
  }

  Future<void> _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() => _reminderTime = time);
      await NotificationService.setReminderTime(time);
    }
  }

  Future<void> _toggleBudgetAlerts(bool value) async {
    setState(() => _budgetAlertsEnabled = value);
    await NotificationService.setBudgetAlertsEnabled(value);
  }

  Future<void> _toggleGoalAlerts(bool value) async {
    setState(() => _goalAlertsEnabled = value);
    await NotificationService.setGoalAlertsEnabled(value);
  }

  Future<void> _toggleWeeklySummary(bool value) async {
    if (value && !_permissionGranted) {
      await _requestPermission();
      if (!_permissionGranted) return;
    }

    setState(() => _weeklySummaryEnabled = value);
    await NotificationService.setWeeklySummaryEnabled(value);
  }

  Future<void> _testNotification() async {
    await NotificationService.showNotification(
      id: 9999,
      title: 'Test de notification',
      body: 'Les notifications fonctionnent correctement !',
      payload: 'test',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification de test envoyée'),
          backgroundColor: AppColors.success,
        ),
      );
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
          'Notifications',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.send_rounded, color: AppColors.primary),
            onPressed: _testNotification,
            tooltip: 'Tester',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Section Rappels
                _buildSectionHeader(
                  icon: Icons.access_time_rounded,
                  title: 'Rappels',
                  color: AppColors.primary,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  isDark: isDark,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.notifications_active_rounded,
                      title: 'Rappel quotidien',
                      subtitle: 'Rappel pour noter vos dépenses',
                      value: _dailyReminderEnabled,
                      onChanged: _toggleDailyReminder,
                      isDark: isDark,
                    ),
                    if (_dailyReminderEnabled) ...[
                      Divider(color: isDark ? AppColors.dividerDark : AppColors.divider, height: 1),
                      _buildTimeTile(
                        icon: Icons.schedule_rounded,
                        title: 'Heure du rappel',
                        time: _reminderTime,
                        onTap: _selectReminderTime,
                        isDark: isDark,
                      ),
                    ],
                    Divider(color: isDark ? AppColors.dividerDark : AppColors.divider, height: 1),
                    _buildSwitchTile(
                      icon: Icons.calendar_today_rounded,
                      title: 'Résumé hebdomadaire',
                      subtitle: 'Bilan chaque dimanche à 18h',
                      value: _weeklySummaryEnabled,
                      onChanged: _toggleWeeklySummary,
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Section Alertes
                _buildSectionHeader(
                  icon: Icons.warning_amber_rounded,
                  title: 'Alertes',
                  color: AppColors.warning,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  isDark: isDark,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Alertes budget',
                      subtitle: 'Notification à 75%, 90% et 100%',
                      value: _budgetAlertsEnabled,
                      onChanged: _toggleBudgetAlerts,
                      isDark: isDark,
                    ),
                    Divider(color: isDark ? AppColors.dividerDark : AppColors.divider, height: 1),
                    _buildSwitchTile(
                      icon: Icons.flag_rounded,
                      title: 'Alertes objectifs',
                      subtitle: 'Progression et objectifs atteints',
                      value: _goalAlertsEnabled,
                      onChanged: _toggleGoalAlerts,
                      isDark: isDark,
                    ),
                  ],
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
                          'Les notifications programmées ne fonctionnent que sur mobile (Android/iOS).',
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
                  ? AppColors.primary.withOpacity(0.2)
                  : isDark ? AppColors.backgroundDark : AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: value ? AppColors.primary : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
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
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.4),
            inactiveThumbColor: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            inactiveTrackColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTile({
    required IconData icon,
    required String title,
    required TimeOfDay time,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                timeString,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
