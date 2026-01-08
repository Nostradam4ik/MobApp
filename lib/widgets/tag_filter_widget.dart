import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../data/models/tag.dart';
import '../services/tag_service.dart';

/// Widget pour filtrer les dépenses par tags
class TagFilterWidget extends StatelessWidget {
  final List<String> selectedTagIds;
  final ValueChanged<List<String>> onFilterChanged;
  final bool matchAll;
  final ValueChanged<bool>? onMatchAllChanged;

  const TagFilterWidget({
    super.key,
    required this.selectedTagIds,
    required this.onFilterChanged,
    this.matchAll = false,
    this.onMatchAllChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allTags = TagService.getAllTags();

    if (allTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.filter_list, size: 18),
            const SizedBox(width: 8),
            Text(
              'Filtrer par tag',
              style: theme.textTheme.titleSmall,
            ),
            const Spacer(),
            if (selectedTagIds.isNotEmpty)
              TextButton(
                onPressed: () => onFilterChanged([]),
                child: const Text('Effacer'),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Tags chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: allTags.map((tag) {
              final isSelected = selectedTagIds.contains(tag.id);
              final color = Color(
                int.parse(tag.color.replaceFirst('#', '0xFF')),
              );

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  showCheckmark: false,
                  avatar: tag.icon != null
                      ? Text(tag.icon!, style: const TextStyle(fontSize: 14))
                      : null,
                  label: Text(tag.name),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontSize: 12,
                  ),
                  backgroundColor: color.withOpacity(0.1),
                  selectedColor: color,
                  side: BorderSide(
                    color: isSelected ? color : color.withOpacity(0.3),
                  ),
                  onSelected: (_) {
                    final newSelected = List<String>.from(selectedTagIds);
                    if (isSelected) {
                      newSelected.remove(tag.id);
                    } else {
                      newSelected.add(tag.id);
                    }
                    onFilterChanged(newSelected);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // Match all toggle
        if (selectedTagIds.length > 1 && onMatchAllChanged != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Doit avoir'),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('au moins un'),
                selected: !matchAll,
                onSelected: (_) => onMatchAllChanged!(false),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('tous'),
                selected: matchAll,
                onSelected: (_) => onMatchAllChanged!(true),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Bottom sheet pour filtrer par tags
class TagFilterBottomSheet extends StatefulWidget {
  final List<String> initialSelection;
  final bool initialMatchAll;

  const TagFilterBottomSheet({
    super.key,
    this.initialSelection = const [],
    this.initialMatchAll = false,
  });

  static Future<TagFilterResult?> show(
    BuildContext context, {
    List<String> initialSelection = const [],
    bool initialMatchAll = false,
  }) {
    return showModalBottomSheet<TagFilterResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TagFilterBottomSheet(
        initialSelection: initialSelection,
        initialMatchAll: initialMatchAll,
      ),
    );
  }

  @override
  State<TagFilterBottomSheet> createState() => _TagFilterBottomSheetState();
}

class _TagFilterBottomSheetState extends State<TagFilterBottomSheet> {
  late List<String> _selectedTagIds;
  late bool _matchAll;

  @override
  void initState() {
    super.initState();
    _selectedTagIds = List.from(widget.initialSelection);
    _matchAll = widget.initialMatchAll;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allTags = TagService.getAllTags();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.filter_list),
                const SizedBox(width: 8),
                Text(
                  'Filtrer par tags',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_selectedTagIds.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedTagIds.clear();
                        _matchAll = false;
                      });
                    },
                    child: const Text('Effacer'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tags grid
          if (allTags.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 48,
                    color: theme.dividerColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun tag créé',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Créez des tags pour filtrer vos dépenses',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allTags.map((tag) {
                  final isSelected = _selectedTagIds.contains(tag.id);
                  final color = Color(
                    int.parse(tag.color.replaceFirst('#', '0xFF')),
                  );

                  return FilterChip(
                    selected: isSelected,
                    showCheckmark: true,
                    checkmarkColor: Colors.white,
                    avatar: tag.icon != null
                        ? Text(tag.icon!, style: const TextStyle(fontSize: 16))
                        : null,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(tag.name),
                        if (tag.usageCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${tag.usageCount})',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? Colors.white.withOpacity(0.7)
                                  : color.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : color,
                    ),
                    backgroundColor: color.withOpacity(0.1),
                    selectedColor: color,
                    side: BorderSide(
                      color: isSelected ? color : color.withOpacity(0.3),
                    ),
                    onSelected: (_) {
                      setState(() {
                        if (isSelected) {
                          _selectedTagIds.remove(tag.id);
                        } else {
                          _selectedTagIds.add(tag.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),

          // Match all toggle
          if (_selectedTagIds.length > 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune, size: 20),
                    const SizedBox(width: 8),
                    const Text('Mode de filtre'),
                    const Spacer(),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('OU'),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('ET'),
                        ),
                      ],
                      selected: {_matchAll},
                      onSelectionChanged: (value) {
                        setState(() => _matchAll = value.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Apply button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    TagFilterResult(
                      tagIds: _selectedTagIds,
                      matchAll: _matchAll,
                    ),
                  );
                },
                child: Text(
                  _selectedTagIds.isEmpty
                      ? 'Afficher tout'
                      : 'Appliquer (${_selectedTagIds.length} tag${_selectedTagIds.length > 1 ? 's' : ''})',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Résultat du filtre de tags
class TagFilterResult {
  final List<String> tagIds;
  final bool matchAll;

  const TagFilterResult({
    required this.tagIds,
    required this.matchAll,
  });
}
