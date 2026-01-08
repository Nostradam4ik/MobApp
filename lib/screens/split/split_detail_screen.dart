import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/expense_split.dart';
import '../../services/split_service.dart';

class SplitDetailScreen extends StatefulWidget {
  final ExpenseSplit split;

  const SplitDetailScreen({super.key, required this.split});

  @override
  State<SplitDetailScreen> createState() => _SplitDetailScreenState();
}

class _SplitDetailScreenState extends State<SplitDetailScreen> {
  late ExpenseSplit _split;

  @override
  void initState() {
    super.initState();
    _split = widget.split;
  }

  void _reloadSplit() {
    final updated = SplitService.getSplitById(_split.id);
    if (updated != null) {
      setState(() => _split = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du partage'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Partager'),
                  ],
                ),
              ),
              if (!_split.isFullySettled)
                const PopupMenuItem(
                  value: 'markAll',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Tout marquer payé'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer'),
                  ],
                ),
              ),
            ],
            onSelected: _handleMenuAction,
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

            // Progress
            _buildProgressCard(theme),
            const SizedBox(height: 24),

            // Participants
            Text(
              'Participants',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              _split.participants.length,
              (index) => _buildParticipantCard(
                _split.participants[index],
                theme,
              ),
            ),

            // My share
            if (_split.includeMe) ...[
              const SizedBox(height: 24),
              _buildMyShareCard(theme),
            ],
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
              AppColors.primary.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            Text(
              _split.mode.icon,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              _split.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (_split.description != null) ...[
              const SizedBox(height: 8),
              Text(
                _split.description!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              '${_split.totalAmount.toStringAsFixed(2)}€',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _split.overallStatus.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _split.overallStatus.label,
                    style: TextStyle(
                      color: _getStatusColor(),
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

  Widget _buildProgressCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reçu',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${_split.totalReceived.toStringAsFixed(2)}€',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Reste',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${_split.totalRemaining.toStringAsFixed(2)}€',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _split.recoveryPercentage,
                minHeight: 12,
                backgroundColor: theme.dividerColor,
                valueColor: AlwaysStoppedAnimation(_getStatusColor()),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_split.paidCount} sur ${_split.participantCount} ont payé',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantCard(SplitParticipant participant, ThemeData theme) {
    final isPaid = participant.isFullyPaid;
    final color = isPaid ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: isPaid
              ? const Icon(Icons.check, color: Colors.green)
              : Text(
                  participant.name[0].toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Text(
          participant.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${participant.amount.toStringAsFixed(2)}€'),
            if (participant.paidAmount > 0 && !isPaid)
              Text(
                'Payé: ${participant.paidAmount.toStringAsFixed(2)}€',
                style: TextStyle(color: Colors.green.shade700),
              ),
          ],
        ),
        trailing: isPaid
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Payé ✓',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : ElevatedButton(
                onPressed: () => _markPaid(participant),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Marquer payé'),
              ),
        onLongPress: isPaid ? () => _cancelPayment(participant) : null,
      ),
    );
  }

  Widget _buildMyShareCard(ThemeData theme) {
    return Card(
      color: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ma part',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Montant que je dois payer',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              '${_split.myShare.toStringAsFixed(2)}€',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (_split.isFullySettled) return Colors.green;
    if (_split.totalReceived > 0) return Colors.orange;
    return Colors.grey;
  }

  Future<void> _markPaid(SplitParticipant participant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${participant.name} a payé ?'),
        content: Text(
          'Confirmer le paiement de ${participant.amount.toStringAsFixed(2)}€ ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SplitService.markParticipantPaid(_split.id, participant.id);
      _reloadSplit();

      if (mounted && _split.isFullySettled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tout le monde a payé ! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _cancelPayment(SplitParticipant participant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le paiement ?'),
        content: Text(
          'Annuler le paiement de ${participant.name} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SplitService.cancelPayment(_split.id, participant.id);
      _reloadSplit();
    }
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'share':
        _shareSplit();
        break;
      case 'markAll':
        await SplitService.markAllPaid(_split.id);
        _reloadSplit();
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer ce partage ?'),
            content: const Text('Cette action est irréversible.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await SplitService.deleteSplit(_split.id);
          if (mounted) Navigator.pop(context);
        }
        break;
    }
  }

  void _shareSplit() {
    final buffer = StringBuffer();
    buffer.writeln('💸 ${_split.title}');
    buffer.writeln('Total: ${_split.totalAmount.toStringAsFixed(2)}€');
    buffer.writeln('');
    buffer.writeln('Participants:');

    for (final p in _split.participants) {
      final status = p.isFullyPaid ? '✅' : '⏳';
      buffer.writeln('$status ${p.name}: ${p.amount.toStringAsFixed(2)}€');
    }

    if (_split.includeMe) {
      buffer.writeln('👤 Moi: ${_split.myShare.toStringAsFixed(2)}€');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copié dans le presse-papier !'),
      ),
    );
  }
}
