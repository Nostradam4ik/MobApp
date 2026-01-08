import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/insight.dart';
import '../../providers/insight_provider.dart';
import '../../widgets/common/empty_state.dart';

/// Écran des insights (conseils intelligents)
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conseils'),
        actions: [
          Consumer<InsightProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount > 0) {
                return TextButton(
                  onPressed: provider.markAllAsRead,
                  child: const Text('Tout marquer lu'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<InsightProvider>(
        builder: (context, insightProvider, _) {
          if (insightProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final insights = insightProvider.validInsights;

          if (insights.isEmpty) {
            return EmptyState(
              icon: Icons.lightbulb_outline,
              title: 'Pas de conseils',
              subtitle:
                  'Continuez à utiliser l\'app pour recevoir des conseils personnalisés',
            );
          }

          return RefreshIndicator(
            onRefresh: insightProvider.loadInsights,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: insights.length,
              itemBuilder: (context, index) {
                final insight = insights[index];
                return _buildInsightCard(context, insight, insightProvider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    Insight insight,
    InsightProvider provider,
  ) {
    final config = _getInsightConfig(insight.insightType);

    return Dismissible(
      key: Key(insight.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => provider.dismiss(insight.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () {
            if (!insight.isRead) {
              provider.markAsRead(insight.id);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: config.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    config.icon,
                    color: config.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              insight.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: insight.isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                            ),
                          ),
                          if (!insight.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insight.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _InsightConfig _getInsightConfig(InsightType type) {
    switch (type) {
      case InsightType.warning:
        return _InsightConfig(
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
        );
      case InsightType.tip:
        return _InsightConfig(
          icon: Icons.lightbulb_outline,
          color: AppColors.info,
        );
      case InsightType.achievement:
        return _InsightConfig(
          icon: Icons.emoji_events,
          color: AppColors.success,
        );
      case InsightType.prediction:
        return _InsightConfig(
          icon: Icons.trending_up,
          color: AppColors.primary,
        );
    }
  }
}

class _InsightConfig {
  final IconData icon;
  final Color color;

  _InsightConfig({required this.icon, required this.color});
}
