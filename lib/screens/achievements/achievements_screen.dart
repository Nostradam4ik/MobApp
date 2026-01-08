import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/achievement.dart';
import '../../providers/achievement_provider.dart';

/// Écran des achievements (badges)
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges'),
      ),
      body: Consumer<AchievementProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats en haut
                _buildStatsHeader(context, provider),
                const SizedBox(height: 24),

                // Badges obtenus
                if (provider.achievements.isNotEmpty) ...[
                  Text(
                    'Obtenus (${provider.achievements.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildBadgeGrid(
                    context,
                    provider.achievements.map((a) => _BadgeData(
                      title: a.title,
                      description: a.description ?? '',
                      icon: a.iconData,
                      points: a.points,
                      isEarned: true,
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Badges à débloquer
                if (provider.lockedAchievements.isNotEmpty) ...[
                  Text(
                    'À débloquer (${provider.lockedAchievements.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildBadgeGrid(
                    context,
                    provider.lockedAchievements.map((a) => _BadgeData(
                      title: a.title,
                      description: a.description,
                      icon: a.iconData,
                      points: a.points,
                      isEarned: false,
                    )).toList(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, AchievementProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            icon: Icons.emoji_events,
            value: '${provider.badgeCount}',
            label: 'Badges',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white24,
          ),
          _buildStatItem(
            context,
            icon: Icons.star,
            value: '${provider.totalScore}',
            label: 'Points',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white24,
          ),
          _buildStatItem(
            context,
            icon: Icons.local_fire_department,
            value: '${provider.longestStreak}',
            label: 'Record',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeGrid(BuildContext context, List<_BadgeData> badges) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _buildBadgeCard(context, badge);
      },
    );
  }

  Widget _buildBadgeCard(BuildContext context, _BadgeData badge) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(context, badge),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: badge.isEarned
              ? AppColors.warningLight
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: badge.isEarned
              ? Border.all(color: AppColors.warning, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              badge.icon,
              size: 32,
              color: badge.isEarned
                  ? AppColors.warning
                  : AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              badge.title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: badge.isEarned ? FontWeight.bold : FontWeight.normal,
                color: badge.isEarned ? null : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (badge.isEarned) ...[
              const SizedBox(height: 4),
              Text(
                '+${badge.points} pts',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBadgeDetail(BuildContext context, _BadgeData badge) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: badge.isEarned
                      ? AppColors.warningLight
                      : AppColors.divider,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  badge.icon,
                  size: 40,
                  color: badge.isEarned
                      ? AppColors.warning
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                badge.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                badge.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (badge.isEarned)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+${badge.points} points',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const Text(
                  'Non débloqué',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _BadgeData {
  final String title;
  final String description;
  final IconData icon;
  final int points;
  final bool isEarned;

  _BadgeData({
    required this.title,
    required this.description,
    required this.icon,
    required this.points,
    required this.isEarned,
  });
}
