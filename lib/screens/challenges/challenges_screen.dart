import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/savings_challenge.dart';
import '../../providers/auth_provider.dart';
import '../../services/challenge_service.dart';
import 'challenge_detail_screen.dart';
import 'create_challenge_screen.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SavingsChallenge> _challenges = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _challenges = ChallengeService.getAllChallenges();
      _stats = ChallengeService.getStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En cours'),
            Tab(text: 'Terminés'),
            Tab(text: 'Templates'),
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
                _buildActiveTab(theme),
                _buildCompletedTab(theme),
                _buildTemplatesTab(theme),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCustomChallenge,
        icon: const Icon(Icons.add),
        label: const Text('Créer'),
      ),
    );
  }

  Widget _buildStatsHeader(ThemeData theme) {
    final level = _stats['level'] ?? 1;
    final xp = _stats['totalXp'] ?? 0;
    final streak = _stats['streak'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
          ],
        ),
      ),
      child: Row(
        children: [
          // Niveau
          _buildStatItem(
            icon: '⭐',
            value: 'Niveau $level',
            label: '$xp XP',
            theme: theme,
          ),
          const Spacer(),

          // Série
          _buildStatItem(
            icon: '🔥',
            value: '$streak',
            label: 'Série',
            theme: theme,
          ),
          const Spacer(),

          // Taux de succès
          _buildStatItem(
            icon: '🏆',
            value: '${_stats['successRate'] ?? 0}%',
            label: 'Succès',
            theme: theme,
          ),
          const Spacer(),

          // Complétés
          _buildStatItem(
            icon: '✅',
            value: '${_stats['completed'] ?? 0}',
            label: 'Terminés',
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String value,
    required String label,
    required ThemeData theme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildActiveTab(ThemeData theme) {
    final active = _challenges
        .where((c) => c.status == ChallengeStatus.active)
        .toList();

    if (active.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Aucun challenge en cours',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez un challenge pour gagner des XP !',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(2),
              icon: const Icon(Icons.explore),
              label: const Text('Voir les templates'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: active.length,
      itemBuilder: (context, index) => _buildChallengeCard(active[index], theme),
    );
  }

  Widget _buildCompletedTab(ThemeData theme) {
    final completed = _challenges
        .where((c) =>
            c.status == ChallengeStatus.completed ||
            c.status == ChallengeStatus.failed)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (completed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📭', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Historique vide',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Vos challenges terminés apparaîtront ici',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completed.length,
      itemBuilder: (context, index) =>
          _buildChallengeCard(completed[index], theme, showStatus: true),
    );
  }

  Widget _buildTemplatesTab(ThemeData theme) {
    final templates = ChallengeTemplates.templates;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) =>
          _buildTemplateCard(templates[index], theme),
    );
  }

  Widget _buildChallengeCard(
    SavingsChallenge challenge,
    ThemeData theme, {
    bool showStatus = false,
  }) {
    final color = challenge.isCompleted
        ? Colors.green
        : challenge.status == ChallengeStatus.failed
            ? Colors.red
            : challenge.isBehindSchedule
                ? Colors.orange
                : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openChallengeDetail(challenge),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    challenge.type.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          challenge.description,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (showStatus)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        challenge.status.label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: challenge.progress,
                        minHeight: 8,
                        backgroundColor: theme.dividerColor,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${challenge.progressPercent}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    challenge.isActive
                        ? '${challenge.daysRemaining} jours restants'
                        : 'Terminé',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    challenge.difficulty.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${challenge.totalXp} XP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template, ThemeData theme) {
    final type = template['type'] as ChallengeType;
    final difficulty = template['difficulty'] as ChallengeDifficulty;
    final xp = template['xpReward'] as int? ?? 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _startTemplateChallenge(template),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    type.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template['title'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template['description'] as String,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${difficulty.emoji} ${difficulty.label}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+${xp * difficulty.xpMultiplier} XP',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill, color: AppColors.primary, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _openChallengeDetail(SavingsChallenge challenge) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeDetailScreen(challenge: challenge),
      ),
    ).then((_) => _loadData());
  }

  Future<void> _startTemplateChallenge(Map<String, dynamic> template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text((template['type'] as ChallengeType).icon),
            const SizedBox(width: 8),
            Expanded(child: Text(template['title'] as String)),
          ],
        ),
        content: Text(
          'Voulez-vous commencer ce challenge ?\n\n${template['description']}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Commencer !'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final userId = context.read<AuthProvider>().user?.id ?? '';
      await ChallengeService.createFromTemplate(
        userId: userId,
        template: template,
      );
      _loadData();
      _tabController.animateTo(0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Challenge "${template['title']}" démarré ! 🚀'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _createCustomChallenge() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateChallengeScreen(),
      ),
    ).then((_) => _loadData());
  }
}
