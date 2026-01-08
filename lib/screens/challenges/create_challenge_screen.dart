import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/savings_challenge.dart';
import '../../providers/auth_provider.dart';
import '../../services/challenge_service.dart';

class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _daysController = TextEditingController(text: '7');

  ChallengeType _selectedType = ChallengeType.savingsTarget;
  ChallengeDifficulty _selectedDifficulty = ChallengeDifficulty.medium;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Challenge'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type selection
            Text(
              'Type de challenge',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildTypeSelector(theme),
            const SizedBox(height: 24),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Ex: Mon défi épargne',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty == true ? 'Requis' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Décrivez votre objectif',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Duration
            Text(
              'Durée',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _daysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nombre de jours',
                prefixIcon: Icon(Icons.calendar_today),
                suffixText: 'jours',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v?.isEmpty == true) return 'Requis';
                final days = int.tryParse(v!);
                if (days == null || days < 1) return 'Min 1 jour';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Amount (for certain types)
            if (_selectedType == ChallengeType.savingsTarget ||
                _selectedType == ChallengeType.spendingLimit) ...[
              Text(
                _selectedType == ChallengeType.savingsTarget
                    ? 'Objectif d\'épargne'
                    : 'Limite de dépense',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Montant',
                  prefixIcon: Icon(Icons.euro),
                  suffixText: '€',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (_selectedType == ChallengeType.savingsTarget ||
                      _selectedType == ChallengeType.spendingLimit) {
                    if (v?.isEmpty == true) return 'Requis';
                    final amount = double.tryParse(v!);
                    if (amount == null || amount <= 0) return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
            ],

            // Difficulty
            Text(
              'Difficulté',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDifficultySelector(theme),
            const SizedBox(height: 24),

            // XP Preview
            _buildXpPreview(theme),
            const SizedBox(height: 32),

            // Create button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _createChallenge,
                child: const Text(
                  'Créer le Challenge',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ChallengeType.values
          .where((t) => t != ChallengeType.weekly52) // Exclude complex ones
          .map((type) => _buildTypeChip(type, theme))
          .toList(),
    );
  }

  Widget _buildTypeChip(ChallengeType type, ThemeData theme) {
    final isSelected = _selectedType == type;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(type.icon),
          const SizedBox(width: 4),
          Text(type.label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedType = type),
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildDifficultySelector(ThemeData theme) {
    return Row(
      children: ChallengeDifficulty.values.map((difficulty) {
        final isSelected = _selectedDifficulty == difficulty;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDifficulty = difficulty),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.2)
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : theme.dividerColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    difficulty.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    difficulty.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                  Text(
                    'x${difficulty.xpMultiplier}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildXpPreview(ThemeData theme) {
    final baseXp = 100; // Base XP
    final totalXp = baseXp * _selectedDifficulty.xpMultiplier;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 28),
          const SizedBox(width: 8),
          Text(
            'Récompense: +$totalXp XP',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createChallenge() async {
    if (!_formKey.currentState!.validate()) return;

    final days = int.parse(_daysController.text);
    final now = DateTime.now();

    final userId = context.read<AuthProvider>().user?.id ?? '';
    await ChallengeService.createChallenge(
      userId: userId,
      title: _titleController.text,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : _selectedType.description,
      type: _selectedType,
      difficulty: _selectedDifficulty,
      startDate: now,
      endDate: now.add(Duration(days: days)),
      targetAmount: double.tryParse(_amountController.text) ?? 0,
      targetDays: days,
      xpReward: 100,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Challenge créé ! Bonne chance ! 🚀'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}
