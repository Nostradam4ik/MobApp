import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/savings_challenge.dart';
import '../../services/challenge_service.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final SavingsChallenge challenge;

  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  late SavingsChallenge _challenge;

  @override
  void initState() {
    super.initState();
    _challenge = widget.challenge;
  }

  Color get _statusColor {
    switch (_challenge.status) {
      case ChallengeStatus.completed:
        return Colors.green;
      case ChallengeStatus.failed:
        return Colors.red;
      case ChallengeStatus.abandoned:
        return Colors.grey;
      default:
        return _challenge.isBehindSchedule ? Colors.orange : AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du Challenge'),
        actions: [
          if (_challenge.isActive)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'abandon',
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Abandonner'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'abandon') _abandonChallenge();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _buildHeaderCard(theme),
            const SizedBox(height: 24),

            // Progress section
            _buildProgressSection(theme),
            const SizedBox(height: 24),

            // Stats
            _buildStatsSection(theme),
            const SizedBox(height: 24),

            // Actions
            if (_challenge.isActive) _buildActionsSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _statusColor.withOpacity(0.1),
              _statusColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  _challenge.type.icon,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              _challenge.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              _challenge.description,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _challenge.isCompleted
                        ? Icons.check_circle
                        : _challenge.status == ChallengeStatus.failed
                            ? Icons.cancel
                            : Icons.play_circle,
                    color: _statusColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _challenge.status.label,
                    style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progression',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Circular progress
            Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: _challenge.progress,
                        strokeWidth: 12,
                        backgroundColor: theme.dividerColor,
                        valueColor: AlwaysStoppedAnimation(_statusColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_challenge.progressPercent}%',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _statusColor,
                          ),
                        ),
                        Text(
                          'complété',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Details based on type
            if (_challenge.targetAmount > 0) ...[
              _buildProgressRow(
                theme,
                label: 'Montant actuel',
                value: '${_challenge.currentAmount.toStringAsFixed(2)}€',
                target: '/ ${_challenge.targetAmount.toStringAsFixed(2)}€',
              ),
              const SizedBox(height: 8),
            ],

            if (_challenge.targetDays > 0) ...[
              _buildProgressRow(
                theme,
                label: 'Jours complétés',
                value: '${_challenge.currentDays}',
                target: '/ ${_challenge.targetDays} jours',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(
    ThemeData theme, {
    required String label,
    required String value,
    required String target,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Row(
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _statusColor,
              ),
            ),
            Text(
              target,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoRow(
              theme,
              icon: Icons.category,
              label: 'Type',
              value: _challenge.type.label,
            ),
            const Divider(),

            _buildInfoRow(
              theme,
              icon: Icons.speed,
              label: 'Difficulté',
              value: '${_challenge.difficulty.emoji} ${_challenge.difficulty.label}',
            ),
            const Divider(),

            _buildInfoRow(
              theme,
              icon: Icons.star,
              label: 'Récompense',
              value: '+${_challenge.totalXp} XP',
              valueColor: Colors.amber,
            ),
            const Divider(),

            _buildInfoRow(
              theme,
              icon: Icons.calendar_today,
              label: 'Début',
              value: _formatDate(_challenge.startDate),
            ),
            const Divider(),

            _buildInfoRow(
              theme,
              icon: Icons.event,
              label: 'Fin',
              value: _formatDate(_challenge.endDate),
            ),

            if (_challenge.isActive) ...[
              const Divider(),
              _buildInfoRow(
                theme,
                icon: Icons.timer,
                label: 'Temps restant',
                value: '${_challenge.daysRemaining} jours',
                valueColor: _challenge.daysRemaining <= 3 ? Colors.red : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.textTheme.bodySmall?.color),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(ThemeData theme) {
    return Column(
      children: [
        // Manual progress update for certain types
        if (_challenge.type == ChallengeType.savingsTarget ||
            _challenge.type == ChallengeType.weekly52)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addProgress,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une contribution'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Mark day complete for streak/noSpend
        if (_challenge.type == ChallengeType.streak ||
            _challenge.type == ChallengeType.noSpend)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _markDayComplete,
              icon: const Icon(Icons.check),
              label: const Text('Marquer aujourd\'hui comme réussi'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _addProgress() async {
    final controller = TextEditingController();

    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une contribution'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Montant (€)',
            prefixIcon: Icon(Icons.euro),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (amount != null && amount > 0) {
      await ChallengeService.updateProgress(_challenge.id, addAmount: amount);
      _reloadChallenge();
    }
  }

  Future<void> _markDayComplete() async {
    await ChallengeService.updateProgress(_challenge.id, addDays: 1);
    _reloadChallenge();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bravo ! Journée validée ! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _abandonChallenge() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandonner le challenge ?'),
        content: const Text(
          'Vous perdrez votre progression et votre série sera réinitialisée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ChallengeService.abandonChallenge(_challenge.id);
      if (mounted) Navigator.pop(context);
    }
  }

  void _reloadChallenge() {
    final challenges = ChallengeService.getAllChallenges();
    final updated = challenges.firstWhere(
      (c) => c.id == _challenge.id,
      orElse: () => _challenge,
    );
    setState(() => _challenge = updated);

    // Check if just completed
    if (_challenge.isCompleted) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text('🎉', style: TextStyle(fontSize: 32)),
            SizedBox(width: 8),
            Text('Challenge Réussi !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Félicitations ! Vous avez terminé le challenge "${_challenge.title}" !',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 32),
                  const SizedBox(width: 8),
                  Text(
                    '+${_challenge.totalXp} XP',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Super !'),
          ),
        ],
      ),
    );
  }
}
