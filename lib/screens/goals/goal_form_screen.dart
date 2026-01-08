import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/goal_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

/// Écran de formulaire d'objectif
class GoalFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingGoal;

  const GoalFormScreen({super.key, this.existingGoal});

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();
  String _selectedIcon = 'savings';
  String _selectedColor = '#10B981';
  DateTime? _deadline;
  bool _isLoading = false;

  bool get isEditing => widget.existingGoal != null;

  final List<Map<String, dynamic>> _presetGoals = [
    {'title': 'Voyage', 'icon': 'flight', 'color': '#3B82F6'},
    {'title': 'Téléphone', 'icon': 'phone_android', 'color': '#8B5CF6'},
    {'title': 'Urgences', 'icon': 'medical_services', 'color': '#EF4444'},
    {'title': 'Vacances', 'icon': 'beach_access', 'color': '#F59E0B'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingGoal != null) {
      _titleController.text = widget.existingGoal!['title'] ?? '';
      _descriptionController.text = widget.existingGoal!['description'] ?? '';
      _targetController.text =
          widget.existingGoal!['target_amount']?.toString() ?? '';
      _selectedIcon = widget.existingGoal!['icon'] ?? 'savings';
      _selectedColor = widget.existingGoal!['color'] ?? '#10B981';
      if (widget.existingGoal!['deadline'] != null) {
        _deadline = DateTime.parse(widget.existingGoal!['deadline']);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un titre'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final targetText = _targetController.text.replaceAll(',', '.');
    final target = double.tryParse(targetText);

    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un montant cible valide'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<GoalProvider>();
    bool success;

    if (isEditing) {
      final goal = provider.getGoalById(widget.existingGoal!['id']);
      if (goal != null) {
        success = await provider.updateGoal(
          goal.copyWith(
            title: _titleController.text,
            description: _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
            targetAmount: target,
            icon: _selectedIcon,
            color: _selectedColor,
            deadline: _deadline,
          ),
        );
      } else {
        success = false;
      }
    } else {
      success = await provider.createGoal(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        targetAmount: target,
        icon: _selectedIcon,
        color: _selectedColor,
        deadline: _deadline,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier l\'objectif' : 'Nouvel objectif'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Présets
            if (!isEditing) ...[
              Text(
                'Suggestions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetGoals.map((preset) {
                      return ActionChip(
                        label: Text(
                          preset['title'],
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        backgroundColor: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surface,
                        side: BorderSide(
                          color: isDark
                              ? Colors.white24
                              : Colors.black12,
                        ),
                        onPressed: () {
                          setState(() {
                            _titleController.text = preset['title'];
                            _selectedIcon = preset['icon'];
                            _selectedColor = preset['color'];
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Aperçu
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.fromHex(_selectedColor).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getIconData(_selectedIcon),
                  size: 40,
                  color: AppColors.fromHex(_selectedColor),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Titre
            CustomTextField(
              controller: _titleController,
              label: 'Nom de l\'objectif',
              hint: 'Ex: Voyage au Japon',
            ),
            const SizedBox(height: 16),

            // Description
            CustomTextField(
              controller: _descriptionController,
              label: 'Description (optionnel)',
              hint: 'Ex: Voyage prévu pour l\'été 2025',
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Montant cible
            Text(
              'Montant cible',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _targetController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: '1000,00',
                suffixText: '€',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Date limite
            Text(
              'Date limite (optionnel)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDeadline,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Text(
                      _deadline != null
                          ? DateFormat('dd MMMM yyyy', 'fr_FR')
                              .format(_deadline!)
                          : 'Aucune date limite',
                    ),
                    const Spacer(),
                    if (_deadline != null)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _deadline = null),
                      )
                    else
                      const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Couleur
            Text(
              'Couleur',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppColors.categoryColors.map((color) {
                final colorHex = AppColors.toHex(color);
                final isSelected = _selectedColor == colorHex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = colorHex),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Bouton sauvegarder
            CustomButton(
              text: isEditing ? 'Enregistrer' : 'Créer l\'objectif',
              onPressed: _save,
              isLoading: _isLoading,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    const iconMap = {
      'savings': Icons.savings,
      'flight': Icons.flight,
      'phone_android': Icons.phone_android,
      'laptop': Icons.laptop,
      'home': Icons.home,
      'directions_car': Icons.directions_car,
      'school': Icons.school,
      'celebration': Icons.celebration,
      'medical_services': Icons.medical_services,
      'beach_access': Icons.beach_access,
    };
    return iconMap[iconName] ?? Icons.savings;
  }
}
