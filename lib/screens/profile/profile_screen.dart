import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/subscription_service.dart';

/// Écran de profil - Design Premium
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profil'),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.glassDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => context.push(AppRoutes.settings),
            ),
          ),
        ],
      ),
      body: Consumer3<AuthProvider, AchievementProvider, SubscriptionProvider>(
        builder: (context, auth, achievements, subscription, _) {
          final profile = auth.profile;
          final isPremium = subscription.isPremium;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Header avec fond dégradé
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 80,
                    bottom: 32,
                    left: 24,
                    right: 24,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withOpacity(0.3),
                        AppColors.backgroundDark,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Avatar avec glow
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: AppColors.primaryGradient,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.surfaceDark,
                            child: Text(
                              profile?.initials ?? '?',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                foreground: Paint()
                                  ..shader = LinearGradient(
                                    colors: AppColors.primaryGradient,
                                  ).createShader(
                                    const Rect.fromLTWH(0, 0, 100, 70),
                                  ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Nom
                      Text(
                        profile?.name ?? 'Utilisateur',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondaryDark,
                        ),
                      ),

                      // Premium badge
                      if (isPremium) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.premiumGradient,
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentGold.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.diamond_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Premium',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Stats Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.local_fire_department_rounded,
                          value: '${achievements.currentStreak}',
                          label: 'Streak',
                          gradient: [AppColors.accentGold, AppColors.accent],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.emoji_events_rounded,
                          value: '${achievements.badgeCount}',
                          label: 'Badges',
                          gradient: AppColors.secondaryGradient,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.star_rounded,
                          value: '${achievements.totalScore}',
                          label: 'Points',
                          gradient: AppColors.primaryGradient,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Menu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.emoji_events_rounded,
                        title: 'Mes badges',
                        subtitle: 'Voir vos récompenses',
                        color: AppColors.accentGold,
                        onTap: () => context.push(AppRoutes.achievements),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.category_rounded,
                        title: 'Catégories',
                        subtitle: 'Gérer vos catégories',
                        color: AppColors.accentBlue,
                        onTap: () => context.push(AppRoutes.categories),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'Budgets',
                        subtitle: 'Définir vos limites',
                        color: AppColors.secondary,
                        onTap: () => context.push(AppRoutes.budgets),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.repeat_rounded,
                        title: 'Récurrentes',
                        subtitle: 'Abonnements & loyers',
                        color: AppColors.accent,
                        onTap: () => _navigateToPremiumFeature(
                          context,
                          subscription,
                          PremiumFeature.recurringExpenses,
                          AppRoutes.recurring,
                        ),
                        showProBadge: !isPremium,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.download_rounded,
                        title: 'Exporter',
                        subtitle: 'CSV ou PDF',
                        color: AppColors.primary,
                        onTap: () => _navigateToPremiumFeature(
                          context,
                          subscription,
                          PremiumFeature.exportData,
                          AppRoutes.export,
                        ),
                        showProBadge: !isPremium,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.receipt_long_rounded,
                        title: 'Factures',
                        subtitle: 'Rappels de paiement',
                        color: AppColors.error,
                        onTap: () => context.push(AppRoutes.bills),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.notifications_rounded,
                        title: 'Notifications',
                        subtitle: 'Rappels et alertes',
                        color: AppColors.warning,
                        onTap: () => context.push(AppRoutes.notifications),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.sync_rounded,
                        title: 'Synchronisation',
                        subtitle: 'Mode hors-ligne',
                        color: AppColors.accentBlue,
                        onTap: () => _navigateToPremiumFeature(
                          context,
                          subscription,
                          PremiumFeature.cloudSync,
                          AppRoutes.sync,
                        ),
                        showProBadge: !isPremium,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.insights_rounded,
                        title: 'Graphiques avancés',
                        subtitle: 'Évolution et tendances',
                        color: AppColors.secondary,
                        onTap: () => _navigateToPremiumFeature(
                          context,
                          subscription,
                          PremiumFeature.advancedStats,
                          AppRoutes.advancedStats,
                        ),
                        showProBadge: !isPremium,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.upload_file_rounded,
                        title: 'Importer',
                        subtitle: 'CSV / Relevé bancaire',
                        color: AppColors.success,
                        onTap: () => _navigateToPremiumFeature(
                          context,
                          subscription,
                          PremiumFeature.importCsv,
                          AppRoutes.import,
                        ),
                        showProBadge: !isPremium,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.palette_rounded,
                        title: 'Apparence',
                        subtitle: 'Thème clair/sombre',
                        color: AppColors.accentPink,
                        onTap: () => context.push(AppRoutes.themeSettings),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.currency_exchange_rounded,
                        title: 'Devises',
                        subtitle: 'EUR, USD, GBP...',
                        color: AppColors.accentGold,
                        onTap: () => _navigateToPremiumFeature(
                          context,
                          subscription,
                          PremiumFeature.currencyConversion,
                          AppRoutes.currencySettings,
                        ),
                        showProBadge: !isPremium,
                      ),
                      // Accès écran Premium
                      _buildMenuItem(
                        context,
                        icon: Icons.workspace_premium,
                        title: isPremium ? 'Mon abonnement' : 'Passer à Premium',
                        subtitle: isPremium ? 'Gérer votre abonnement' : 'Débloquez tout',
                        color: AppColors.accentGold,
                        onTap: () => context.push(AppRoutes.premium),
                        showProBadge: false,
                        isGolden: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (!isPremium)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildPremiumCard(context),
                  ),

                const SizedBox(height: 24),

                // Déconnexion
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showLogoutDialog(context, auth),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded, color: AppColors.error),
                              const SizedBox(width: 8),
                              Text(
                                'Se déconnecter',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withOpacity(0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..shader = LinearGradient(colors: gradient)
                    .createShader(const Rect.fromLTWH(0, 0, 50, 30)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPremiumFeature(
    BuildContext context,
    SubscriptionProvider subscription,
    PremiumFeature feature,
    String route,
  ) {
    if (subscription.isPremium) {
      context.push(route);
    } else {
      _showPremiumDialog(context, subscription, feature);
    }
  }

  void _showPremiumDialog(
    BuildContext context,
    SubscriptionProvider subscription,
    PremiumFeature feature,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: AppColors.premiumGradient),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Fonctionnalité Premium',
              style: TextStyle(color: AppColors.textPrimaryDark),
            ),
          ],
        ),
        content: Text(
          subscription.getLimitMessage(feature),
          style: const TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.premiumGradient),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(AppRoutes.premium);
              },
              child: const Text(
                'Voir Premium',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool showProBadge = false,
    bool isGolden = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 0.5,
        ),
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
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showProBadge)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: AppColors.premiumGradient),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: isGolden ? AppColors.accentGold : AppColors.textTertiaryDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
            const Color(0xFF3B0764),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.diamond_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passez à Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Débloquez toutes les fonctionnalités',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPremiumFeature(Icons.psychology_rounded, 'Assistant intelligent avancé'),
          _buildPremiumFeature(Icons.all_inclusive_rounded, 'Objectifs illimités'),
          _buildPremiumFeature(Icons.download_rounded, 'Export PDF/CSV'),
          _buildPremiumFeature(Icons.block_rounded, 'Sans publicités'),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(AppRoutes.premium),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: AppColors.primaryGradient,
                        ).createShader(bounds),
                        child: const Text(
                          '3,99€/mois',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: AppColors.secondaryGradient),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '-50%',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Se déconnecter ?',
          style: TextStyle(color: AppColors.textPrimaryDark),
        ),
        content: const Text(
          'Vous devrez vous reconnecter pour accéder à vos données.',
          style: TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppColors.textSecondaryDark),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await auth.signOut();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
              child: Text(
                'Déconnexion',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
