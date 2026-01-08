import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/tag.dart';
import '../../services/tag_service.dart';

class CreateTagDialog extends StatefulWidget {
  final Tag? tagToEdit;

  const CreateTagDialog({super.key, this.tagToEdit});

  @override
  State<CreateTagDialog> createState() => _CreateTagDialogState();
}

class _CreateTagDialogState extends State<CreateTagDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedColor = Tag.predefinedColors[0];
  String? _selectedIcon;

  bool get isEditing => widget.tagToEdit != null;

  @override
  void initState() {
    super.initState();
    if (widget.tagToEdit != null) {
      _nameController.text = widget.tagToEdit!.name;
      _selectedColor = widget.tagToEdit!.color;
      _selectedIcon = widget.tagToEdit!.icon;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(int.parse(_selectedColor.replaceFirst('#', '0xFF')));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _selectedIcon != null
                          ? Text(_selectedIcon!, style: const TextStyle(fontSize: 24))
                          : Icon(Icons.local_offer, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Modifier le tag' : 'Nouveau tag',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Nom du tag
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du tag',
                    hintText: 'Ex: Urgent, Récurrent...',
                    prefixIcon: Icon(Icons.label),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) {
                    if (v?.trim().isEmpty == true) return 'Nom requis';
                    if (v!.length > 20) return 'Max 20 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Sélection de couleur
                Text(
                  'Couleur',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Tag.predefinedColors.map((colorHex) {
                    final isSelected = colorHex == _selectedColor;
                    final c = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = colorHex),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Sélection d'icône
                Text(
                  'Icône (optionnel)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Option sans icône
                    GestureDetector(
                      onTap: () => setState(() => _selectedIcon = null),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _selectedIcon == null
                              ? color.withOpacity(0.2)
                              : theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedIcon == null
                                ? color
                                : theme.dividerColor,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.block, size: 20),
                        ),
                      ),
                    ),
                    // Icônes disponibles
                    ...Tag.suggestedIcons.map((icon) {
                      final isSelected = icon == _selectedIcon;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.2)
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : theme.dividerColor,
                            ),
                          ),
                          child: Center(
                            child: Text(icon, style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 32),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveTag,
                        child: Text(isEditing ? 'Modifier' : 'Créer'),
                      ),
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

  Future<void> _saveTag() async {
    if (!_formKey.currentState!.validate()) return;

    Tag result;

    if (isEditing) {
      result = (await TagService.updateTag(
        widget.tagToEdit!.id,
        name: _nameController.text.trim(),
        color: _selectedColor,
        icon: _selectedIcon,
      ))!;
    } else {
      result = await TagService.createTag(
        name: _nameController.text.trim(),
        color: _selectedColor,
        icon: _selectedIcon,
      );
    }

    if (mounted) {
      Navigator.pop(context, result);
    }
  }
}
