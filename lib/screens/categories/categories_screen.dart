import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/empty_state.dart';

/// Écran de gestion des catégories
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.categoryForm),
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, _) {
          if (categoryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (categoryProvider.categories.isEmpty) {
            return EmptyState(
              icon: Icons.category,
              title: 'Aucune catégorie',
              subtitle: 'Créez vos catégories personnalisées',
              buttonText: 'Créer une catégorie',
              onButtonPressed: () => context.push(AppRoutes.categoryForm),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (categoryProvider.defaultCategories.isNotEmpty) ...[
                Text(
                  'Catégories par défaut',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...categoryProvider.defaultCategories.map((category) {
                  return _buildCategoryTile(context, category, isDefault: true);
                }),
                const SizedBox(height: 24),
              ],
              if (categoryProvider.userCategories.isNotEmpty) ...[
                Text(
                  'Mes catégories',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...categoryProvider.userCategories.map((category) {
                  return _buildCategoryTile(context, category);
                }),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    dynamic category, {
    bool isDefault = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: category.colorValue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            category.iconData,
            color: category.colorValue,
          ),
        ),
        title: Text(category.name),
        trailing: isDefault
            ? const Chip(
                label: Text('Par défaut'),
                padding: EdgeInsets.zero,
              )
            : IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.push(
                  AppRoutes.categoryForm,
                  extra: category.toJson(),
                ),
              ),
      ),
    );
  }
}
