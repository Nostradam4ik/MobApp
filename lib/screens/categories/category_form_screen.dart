import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/category.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

/// Écran de formulaire de catégorie
class CategoryFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingCategory;

  const CategoryFormScreen({super.key, this.existingCategory});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _nameController = TextEditingController();
  String _selectedIcon = 'category';
  String _selectedColor = '#6366F1';
  bool _isLoading = false;

  bool get isEditing => widget.existingCategory != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingCategory != null) {
      _nameController.text = widget.existingCategory!['name'] ?? '';
      _selectedIcon = widget.existingCategory!['icon'] ?? 'category';
      _selectedColor = widget.existingCategory!['color'] ?? '#6366F1';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un nom'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<CategoryProvider>();
    bool success;

    if (isEditing) {
      final category = Category.fromJson(widget.existingCategory!);
      success = await provider.updateCategory(
        category.copyWith(
          name: _nameController.text,
          icon: _selectedIcon,
          color: _selectedColor,
        ),
      );
    } else {
      success = await provider.createCategory(
        name: _nameController.text,
        icon: _selectedIcon,
        color: _selectedColor,
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
        title: Text(isEditing ? 'Modifier la catégorie' : 'Nouvelle catégorie'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Category.getIconData(_selectedIcon),
                  size: 40,
                  color: AppColors.fromHex(_selectedColor),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Nom
            CustomTextField(
              controller: _nameController,
              label: 'Nom de la catégorie',
              hint: 'Ex: Restaurants',
            ),
            const SizedBox(height: 24),

            // Icône
            Text(
              'Icône',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Category.availableIcons.map((iconName) {
                final isSelected = _selectedIcon == iconName;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = iconName),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.fromHex(_selectedColor).withOpacity(0.15)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: AppColors.fromHex(_selectedColor),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Icon(
                      Category.getIconData(iconName),
                      color: isSelected
                          ? AppColors.fromHex(_selectedColor)
                          : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Bouton sauvegarder
            CustomButton(
              text: isEditing ? 'Enregistrer' : 'Créer la catégorie',
              onPressed: _save,
              isLoading: _isLoading,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
