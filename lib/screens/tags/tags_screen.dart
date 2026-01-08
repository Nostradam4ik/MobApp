import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/tag.dart';
import '../../providers/expense_provider.dart';
import '../../services/tag_service.dart';
import 'create_tag_dialog.dart';
import 'tag_detail_screen.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  List<Tag> _tags = [];
  String _sortBy = 'name'; // 'name', 'usage', 'date'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    await TagService.init();
    _refreshTags();
    setState(() => _isLoading = false);
  }

  void _refreshTags() {
    var tags = TagService.getAllTags();

    switch (_sortBy) {
      case 'usage':
        tags = List.from(tags)..sort((a, b) => b.usageCount.compareTo(a.usageCount));
        break;
      case 'date':
        tags = List.from(tags)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      default:
        tags = List.from(tags)..sort((a, b) => a.name.compareTo(b.name));
    }

    setState(() => _tags = tags);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Tags'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Trier',
            onSelected: (value) {
              setState(() => _sortBy = value);
              _refreshTags();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      color: _sortBy == 'name' ? AppColors.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Text('Par nom'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'usage',
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: _sortBy == 'usage' ? AppColors.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Text('Par utilisation'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _sortBy == 'date' ? AppColors.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Text('Par date'),
                  ],
                ),
              ),
            ],
          ),
          if (_tags.isEmpty)
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'Ajouter tags suggérés',
              onPressed: _addSuggestedTags,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tags.isEmpty
              ? _buildEmptyState(theme)
              : _buildTagsList(theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTagDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Tag'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.local_offer_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun tag',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez des tags personnalisés pour\nmieux organiser vos dépenses',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _addSuggestedTags,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Ajouter des tags suggérés'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsList(ThemeData theme) {
    final expenses = context.watch<ExpenseProvider>().expenses;

    return RefreshIndicator(
      onRefresh: _loadTags,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tags.length,
        itemBuilder: (context, index) {
          final tag = _tags[index];
          final stats = TagService.getTagStats(tag.id, expenses);
          final color = Color(int.parse(tag.color.replaceFirst('#', '0xFF')));

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openTagDetail(tag),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Tag icon/color
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: tag.icon != null
                            ? Text(tag.icon!, style: const TextStyle(fontSize: 28))
                            : Icon(Icons.local_offer, color: color, size: 28),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Tag info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tag.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${stats.expenseCount} dépense${stats.expenseCount > 1 ? 's' : ''}',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (stats.totalAmount > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Total: ${stats.totalAmount.toStringAsFixed(2)}€',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Usage badge
                    if (tag.usageCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${tag.usageCount}x',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: theme.dividerColor,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCreateTagDialog() async {
    final result = await showDialog<Tag>(
      context: context,
      builder: (context) => const CreateTagDialog(),
    );

    if (result != null) {
      _refreshTags();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tag "${result.name}" créé !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _addSuggestedTags() async {
    await TagService.addSuggestedTags();
    _refreshTags();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tags suggérés ajoutés !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _openTagDetail(Tag tag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TagDetailScreen(tag: tag),
      ),
    ).then((_) => _refreshTags());
  }
}
