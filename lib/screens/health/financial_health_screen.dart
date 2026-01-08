import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../data/models/financial_health.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/financial_health_service.dart';
import '../../services/bill_reminder_service.dart';

class FinancialHealthScreen extends StatefulWidget {
  const FinancialHealthScreen({super.key});

  @override
  State<FinancialHealthScreen> createState() => _FinancialHealthScreenState();
}

class _FinancialHealthScreenState extends State<FinancialHealthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scoreAnimation;
  FinancialHealth? _health;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadHealth();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHealth() async {
    final expenseProvider = context.read<ExpenseProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final goalProvider = context.read<GoalProvider>();
    final authProvider = context.read<AuthProvider>();

    // Récupérer le revenu mensuel du profil utilisateur
    final monthlyIncome = authProvider.profile?.monthlyIncome;

    final health = FinancialHealthService.calculateHealth(
      expenses: expenseProvider.expenses,
      budgets: budgetProvider.budgets,
      goals: goalProvider.goals,
      billReminders: BillReminderService.getAllReminders(),
      monthlyIncome: monthlyIncome != null && monthlyIncome > 0 ? monthlyIncome : null,
    );

    setState(() {
      _health = health;
      _isLoading = false;
    });

    _scoreAnimation = Tween<double>(
      begin: 0,
      end: health.overallScore.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Santé Financière'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHealth,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Score principal
                    _buildScoreCard(theme),
                    const SizedBox(height: 24),

                    // Message de motivation
                    _buildMotivationCard(theme),
                    const SizedBox(height: 24),

                    // Composants du score
                    Text(
                      'Détail du score',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._health!.components.map((c) => _buildComponentCard(c, theme)),

                    const SizedBox(height: 24),

                    // Conseils prioritaires
                    _buildTipsCard(theme),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildScoreCard(ThemeData theme) {
    final health = _health!;
    final color = Color(int.parse(health.level.color.replaceFirst('#', '0xFF')));

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // Cercle animé du score
            AnimatedBuilder(
              animation: _scoreAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CustomPaint(
                        painter: _ScoreCirclePainter(
                          progress: _scoreAnimation.value / 100,
                          color: color,
                          backgroundColor: theme.dividerColor,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_scoreAnimation.value.toInt()}',
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          'sur 100',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Niveau et trend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  health.level.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 8),
                Text(
                  health.level.label,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (health.trend != 0) ...[
                  const SizedBox(width: 12),
                  Icon(
                    health.trend > 0 ? Icons.trending_up : Icons.trending_down,
                    color: health.trend > 0 ? Colors.green : Colors.red,
                    size: 28,
                  ),
                ],
              ],
            ),

            if (health.trend != 0) ...[
              const SizedBox(height: 8),
              Text(
                health.trend > 0
                    ? '+${health.overallScore - health.previousScore} pts depuis la dernière fois'
                    : '${health.overallScore - health.previousScore} pts depuis la dernière fois',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: health.trend > 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationCard(ThemeData theme) {
    return Card(
      color: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('💬', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _health!.motivationMessage,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentCard(HealthComponent component, ThemeData theme) {
    final color = component.percentage >= 0.7
        ? Colors.green
        : component.percentage >= 0.4
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(component.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        component.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        component.description,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${component.score}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: component.percentage,
                minHeight: 8,
                backgroundColor: theme.dividerColor,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            if (component.tips.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...component.tips.map((tip) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard(ThemeData theme) {
    final tips = FinancialHealthService.getPriorityTips(_health!);

    return Card(
      color: Colors.amber.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tips_and_updates, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Conseils prioritaires',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Comment ça marche ?'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Votre score de santé financière est calculé sur 100 points basé sur 5 critères :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('💰 Budgets (25%) - Respect de vos limites'),
              SizedBox(height: 8),
              Text('🐷 Épargne (25%) - Votre capacité à mettre de côté'),
              SizedBox(height: 8),
              Text('📊 Régularité (20%) - Suivi quotidien des dépenses'),
              SizedBox(height: 8),
              Text('🎯 Objectifs (15%) - Progression vers vos buts'),
              SizedBox(height: 8),
              Text('📋 Factures (15%) - Paiement à temps'),
              SizedBox(height: 16),
              Text(
                'Le score est mis à jour à chaque visite et comparé à la dernière fois pour montrer votre progression.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris !'),
          ),
        ],
      ),
    );
  }
}

/// Painter pour le cercle de score
class _ScoreCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _ScoreCirclePainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreCirclePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
