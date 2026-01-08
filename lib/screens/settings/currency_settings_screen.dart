import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../services/currency_service.dart';

/// Écran de paramètres des devises
class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  bool _isLoading = false;
  bool _isRefreshing = false;
  DateTime? _lastUpdate;
  Currency _selectedCurrency = CurrencyService.primaryCurrency;

  @override
  void initState() {
    super.initState();
    _loadLastUpdate();
  }

  Future<void> _loadLastUpdate() async {
    final lastUpdate = await CurrencyService.getLastUpdate();
    setState(() => _lastUpdate = lastUpdate);
  }

  Future<void> _selectCurrency(Currency currency) async {
    setState(() {
      _isLoading = true;
      _selectedCurrency = currency;
    });

    await CurrencyService.setPrimaryCurrency(currency);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Devise changée en ${currency.name}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _refreshRates() async {
    setState(() => _isRefreshing = true);

    final success = await CurrencyService.refreshExchangeRates();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Taux de change mis à jour'
                : 'Impossible de mettre à jour les taux',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }

    await _loadLastUpdate();
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        title: Text(
          'Devises',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(
                    Icons.refresh_rounded,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
            onPressed: _isRefreshing ? null : _refreshRates,
            tooltip: 'Actualiser les taux',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Devise actuelle
                _buildCurrentCurrencyCard(isDark),
                const SizedBox(height: 24),

                // Convertisseur rapide
                _buildSectionHeader(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Convertisseur',
                  color: AppColors.secondary,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildConverterCard(isDark),
                const SizedBox(height: 24),

                // Sélection de devise
                _buildSectionHeader(
                  icon: Icons.currency_exchange_rounded,
                  title: 'Devise principale',
                  color: AppColors.primary,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildCurrencyList(isDark),
                const SizedBox(height: 24),

                // Taux de change
                _buildSectionHeader(
                  icon: Icons.trending_up_rounded,
                  title: 'Taux de change',
                  color: AppColors.accent,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                if (_lastUpdate != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Dernière mise à jour: ${DateFormat('dd/MM/yyyy HH:mm').format(_lastUpdate!)}',
                      style: TextStyle(
                        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                _buildExchangeRatesCard(isDark),
              ],
            ),
    );
  }

  Widget _buildCurrentCurrencyCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _selectedCurrency.flag,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCurrency.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _selectedCurrency.name,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _selectedCurrency.symbol,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConverterCard(bool isDark) {
    final amountController = TextEditingController(text: '100');
    Currency fromCurrency = _selectedCurrency;
    Currency toCurrency = CurrencyService.supportedCurrencies
        .firstWhere((c) => c.code != _selectedCurrency.code);

    return StatefulBuilder(
      builder: (context, setLocalState) {
        final amount = double.tryParse(amountController.text) ?? 0;
        final converted = CurrencyService.convert(
          amount,
          fromCurrency.code,
          toCurrency.code,
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
            ),
          ),
          child: Column(
            children: [
              // Montant source
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                        ),
                      ),
                      onChanged: (_) => setLocalState(() {}),
                    ),
                  ),
                  _buildCurrencyDropdown(
                    fromCurrency,
                    (c) => setLocalState(() => fromCurrency = c),
                    isDark,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Icône swap
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? AppColors.dividerDark : AppColors.divider)),
                  IconButton(
                    icon: Icon(
                      Icons.swap_vert_rounded,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setLocalState(() {
                        final temp = fromCurrency;
                        fromCurrency = toCurrency;
                        toCurrency = temp;
                      });
                    },
                  ),
                  Expanded(child: Divider(color: isDark ? AppColors.dividerDark : AppColors.divider)),
                ],
              ),
              const SizedBox(height: 8),
              // Résultat
              Row(
                children: [
                  Expanded(
                    child: Text(
                      converted.toStringAsFixed(2),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildCurrencyDropdown(
                    toCurrency,
                    (c) => setLocalState(() => toCurrency = c),
                    isDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Taux
              Text(
                '1 ${fromCurrency.code} = ${CurrencyService.getExchangeRate(fromCurrency.code, toCurrency.code).toStringAsFixed(4)} ${toCurrency.code}',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrencyDropdown(Currency selected, Function(Currency) onChanged, bool isDark) {
    return PopupMenuButton<Currency>(
      initialValue: selected,
      onSelected: onChanged,
      itemBuilder: (context) => CurrencyService.supportedCurrencies
          .map(
            (c) => PopupMenuItem(
              value: c,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c.flag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(c.code),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selected.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              selected.code,
              style: TextStyle(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ],
        ),
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

  Widget _buildCurrencyList(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
        ),
      ),
      child: Column(
        children: CurrencyService.supportedCurrencies.asMap().entries.map((entry) {
          final index = entry.key;
          final currency = entry.value;
          final isSelected = currency.code == _selectedCurrency.code;
          final isLast = index == CurrencyService.supportedCurrencies.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: () => _selectCurrency(currency),
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(16) : Radius.zero,
                  bottom: isLast ? const Radius.circular(16) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(currency.flag, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currency.code,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              currency.name,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currency.symbol,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        )
                      else
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiary,
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  color: isDark ? AppColors.dividerDark : AppColors.divider,
                  height: 1,
                  indent: 56,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExchangeRatesCard(bool isDark) {
    final rates = CurrencyService.exchangeRates;
    final baseCurrency = _selectedCurrency;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
        ),
      ),
      child: Column(
        children: CurrencyService.supportedCurrencies
            .where((c) => c.code != baseCurrency.code)
            .toList()
            .asMap()
            .entries
            .map((entry) {
          final index = entry.key;
          final currency = entry.value;
          final rate = CurrencyService.getExchangeRate(baseCurrency.code, currency.code);
          final isLast = index == CurrencyService.supportedCurrencies.length - 2;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(currency.flag, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        currency.code,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '1 ${baseCurrency.code} = ${rate.toStringAsFixed(4)}',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  color: isDark ? AppColors.dividerDark : AppColors.divider,
                  height: 1,
                  indent: 48,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
