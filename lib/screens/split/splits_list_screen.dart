import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/expense_split.dart';
import '../../services/split_service.dart';
import 'split_expense_screen.dart';
import 'split_detail_screen.dart';

class SplitsListScreen extends StatefulWidget {
  const SplitsListScreen({super.key});

  @override
  State<SplitsListScreen> createState() => _SplitsListScreenState();
}

class _SplitsListScreenState extends State<SplitsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ExpenseSplit> _pendingSplits = [];
  List<ExpenseSplit> _settledSplits = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _pendingSplits = SplitService.getPendingSplits();
      _settledSplits = SplitService.getSettledSplits();
      _stats = SplitService.getStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partages'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'En attente (${_pendingSplits.length})'),
            Tab(text: 'Réglés (${_settledSplits.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats header
          _buildStatsHeader(theme),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(theme),
                _buildSettledTab(theme),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewSplit,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau partage'),
      ),
    );
  }

  Widget _buildStatsHeader(ThemeData theme) {
    final toReceive = _stats['totalToReceive'] ?? 0.0;
    final received = _stats['totalReceived'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            AppColors.primary.withOpacity(0.1),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              theme,
              icon: Icons.hourglass_empty,
              iconColor: Colors.orange,
              title: 'À recevoir',
              value: '${toReceive.toStringAsFixed(2)}€',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              theme,
              icon: Icons.check_circle,
              iconColor: Colors.green,
              title: 'Reçu',
              value: '${received.toStringAsFixed(2)}€',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab(ThemeData theme) {
    if (_pendingSplits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💸', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Aucun partage en attente',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Créez un partage pour diviser une dépense',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingSplits.length,
        itemBuilder: (context, index) =>
            _buildSplitCard(_pendingSplits[index], theme),
      ),
    );
  }

  Widget _buildSettledTab(ThemeData theme) {
    if (_settledSplits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📭', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Aucun partage réglé',
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _settledSplits.length,
      itemBuilder: (context, index) =>
          _buildSplitCard(_settledSplits[index], theme, isSettled: true),
    );
  }

  Widget _buildSplitCard(
    ExpenseSplit split,
    ThemeData theme, {
    bool isSettled = false,
  }) {
    final statusColor = split.isFullySettled
        ? Colors.green
        : split.totalReceived > 0
            ? Colors.orange
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openSplitDetail(split),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      split.mode.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          split.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${split.participantCount} personne${split.participantCount > 1 ? 's' : ''}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${split.totalAmount.toStringAsFixed(2)}€',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          split.overallStatus.label,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (!isSettled) ...[
                const SizedBox(height: 16),

                // Progress
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: split.recoveryPercentage,
                          minHeight: 8,
                          backgroundColor: theme.dividerColor,
                          valueColor: AlwaysStoppedAnimation(statusColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${split.paidCount}/${split.participantCount}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Amount to receive
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reste à recevoir',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${split.totalRemaining.toStringAsFixed(2)}€',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],

              // Participants preview
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: split.participants.take(4).map((p) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: p.isFullyPaid
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      child: Icon(
                        p.isFullyPaid ? Icons.check : Icons.person,
                        size: 16,
                        color: p.isFullyPaid ? Colors.green : Colors.grey,
                      ),
                    ),
                    label: Text(
                      p.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSplitDetail(ExpenseSplit split) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SplitDetailScreen(split: split),
      ),
    ).then((_) => _loadData());
  }

  void _createNewSplit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SplitExpenseScreen(),
      ),
    ).then((_) => _loadData());
  }
}
