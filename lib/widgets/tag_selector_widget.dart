import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../data/models/tag.dart';
import '../services/tag_service.dart';
import '../screens/tags/create_tag_dialog.dart';

/// Widget pour sélectionner des tags pour une dépense
class TagSelectorWidget extends StatefulWidget {
  final List<String> selectedTagIds;
  final ValueChanged<List<String>> onTagsChanged;
  final String? expenseNote;

  const TagSelectorWidget({
    super.key,
    required this.selectedTagIds,
    required this.onTagsChanged,
    this.expenseNote,
  });

  @override
  State<TagSelectorWidget> createState() => _TagSelectorWidgetState();
}

class _TagSelectorWidgetState extends State<TagSelectorWidget> {
  List<Tag> _allTags = [];
  List<Tag> _suggestedTags = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  @override
  void didUpdateWidget(TagSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenseNote != widget.expenseNote) {
      _updateSuggestions();
    }
  }

  Future<void> _loadTags() async {
    await TagService.init();
    setState(() {
      _allTags = TagService.getAllTags();
    });
    _updateSuggestions();
  }

  void _updateSuggestions() {
    if (widget.expenseNote != null && widget.expenseNote!.isNotEmpty) {
      setState(() {
        _suggestedTags = TagService.suggestTagsForNote(widget.expenseNote!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedTags = _allTags
        .where((t) => widget.selectedTagIds.contains(t.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.local_offer_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tags',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                if (selectedTags.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${selectedTags.length}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.dividerColor,
                ),
              ],
            ),
          ),
        ),

        // Selected tags preview (always visible)
        if (selectedTags.isNotEmpty && !_isExpanded)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: selectedTags.map((tag) {
              final color = Color(
                int.parse(tag.color.replaceFirst('#', '0xFF')),
              );
              return Chip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                avatar: tag.icon != null
                    ? Text(tag.icon!, style: const TextStyle(fontSize: 14))
                    : null,
                label: Text(
                  tag.name,
                  style: TextStyle(color: color, fontSize: 12),
                ),
                backgroundColor: color.withOpacity(0.1),
                side: BorderSide(color: color.withOpacity(0.3)),
                deleteIcon: Icon(Icons.close, size: 16, color: color),
                onDeleted: () => _toggleTag(tag.id),
              );
            }).toList(),
          ),

        // Expanded content
        if (_isExpanded) ...[
          const SizedBox(height: 8),

          // Suggestions
          if (_suggestedTags.isNotEmpty) ...[
            Text(
              'Suggestions',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestedTags.map((tag) {
                final isSelected = widget.selectedTagIds.contains(tag.id);
                final color = Color(
                  int.parse(tag.color.replaceFirst('#', '0xFF')),
                );
                return _buildTagChip(tag, isSelected, color);
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // All tags
          if (_allTags.isNotEmpty) ...[
            Text(
              'Tous les tags',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._allTags.map((tag) {
                  final isSelected = widget.selectedTagIds.contains(tag.id);
                  final color = Color(
                    int.parse(tag.color.replaceFirst('#', '0xFF')),
                  );
                  return _buildTagChip(tag, isSelected, color);
                }),
                // Bouton ajouter
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Nouveau'),
                  onPressed: _createNewTag,
                ),
              ],
            ),
          ] else ...[
            // Aucun tag
            Center(
              child: Column(
                children: [
                  Text(
                    'Aucun tag créé',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _createNewTag,
                    icon: const Icon(Icons.add),
                    label: const Text('Créer un tag'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildTagChip(Tag tag, bool isSelected, Color color) {
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: tag.icon != null
          ? Text(tag.icon!, style: const TextStyle(fontSize: 16))
          : null,
      label: Text(tag.name),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : color,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color,
      side: BorderSide(
        color: isSelected ? color : color.withOpacity(0.3),
      ),
      onSelected: (_) => _toggleTag(tag.id),
    );
  }

  void _toggleTag(String tagId) {
    final newSelected = List<String>.from(widget.selectedTagIds);
    if (newSelected.contains(tagId)) {
      newSelected.remove(tagId);
    } else {
      newSelected.add(tagId);
    }
    widget.onTagsChanged(newSelected);
  }

  Future<void> _createNewTag() async {
    final result = await showDialog<Tag>(
      context: context,
      builder: (context) => const CreateTagDialog(),
    );

    if (result != null) {
      setState(() {
        _allTags = TagService.getAllTags();
      });
      // Auto-select the new tag
      _toggleTag(result.id);
    }
  }
}

/// Version compacte pour affichage dans les listes
class TagsDisplayWidget extends StatelessWidget {
  final String expenseId;
  final int maxVisible;

  const TagsDisplayWidget({
    super.key,
    required this.expenseId,
    this.maxVisible = 3,
  });

  @override
  Widget build(BuildContext context) {
    final tags = TagService.getTagsForExpense(expenseId);
    if (tags.isEmpty) return const SizedBox.shrink();

    final visibleTags = tags.take(maxVisible).toList();
    final remaining = tags.length - maxVisible;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...visibleTags.map((tag) {
          final color = Color(
            int.parse(tag.color.replaceFirst('#', '0xFF')),
          );
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tag.icon != null) ...[
                  Text(tag.icon!, style: const TextStyle(fontSize: 10)),
                  const SizedBox(width: 4),
                ],
                Text(
                  tag.name,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+$remaining',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
