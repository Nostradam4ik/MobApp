import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/tag.dart';
import '../../providers/expense_provider.dart';
import '../../services/tag_service.dart';
import 'create_tag_dialog.dart';

class TagDetailScreen extends StatefulWidget {
  final Tag tag;

  const TagDetailScreen({super.key, required this.tag});

  @override
  State<TagDetailScreen> createState() => _TagDetailScreenState();
}

class _TagDetailScreenState extends State<TagDetailScreen> {
  late Tag _tag;
  late TagStats _stats;

  @override
  void initState() {
    super.initState();
    _tag = widget.tag;
    _loadStats();
  }

  void _loadStats() {
    final expenses = context.read<ExpenseProvider>().expenses;
    setState(() {
      _stats = TagService.getTagStats(_tag.id, expenses);
      // Recharger le tag pour avoir les données à jour
      final updatedTag = TagService.getTagById(_tag.id);
      if (updatedTag != null) {
        _tag = updatedTag;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(int.parse(_tag.color.replaceFirst('#', '0xFF')));
    final expenses = context.watch<ExpenseProvider>().expenses;
    final taggedExpenseIds = TagService.getExpenseIdsForTag(_tag.id);
    final taggedExpenses = expenses
        .where((e) => taggedExpenseIds.contains(e.id))
        .toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    return Scaffold(
      appBar: AppBar(
        title: Text(_tag.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editTag,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _buildHeaderCard(theme, color),
            const SizedBox(height: 24),

            // Stats card
            _buildStatsCard(theme, color),
            const SizedBox(height: 24),

            // Expenses list
            if (taggedExpenses.isNotEmpty) ...[
              Text(
                'Dépenses avec ce tag',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...taggedExpenses.take(10).map((expense) => _buildExpenseItem(
                    expense,
                    theme,
                    color,
                  )),
              if (taggedExpenses.length > 10)
                Center(
                  child: TextButton(
                    onPressed: () {
                      context.push('/expenses?tagId=${_tag.id}');
                    },
                    child: Text('Voir les ${taggedExpenses.length - 10} autres'),
                  ),
                ),
            ] else
              _buildNoExpenses(theme, color),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: _tag.icon != null
                    ? Text(_tag.icon!, style: const TextStyle(fontSize: 40))
                    : Icon(Icons.local_offer, color: color, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _tag.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_tag.usageCount} utilisation${_tag.usageCount > 1 ? 's' : ''}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(ThemeData theme, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _buildStatItem(
              theme,
              icon: Icons.receipt_long,
              label: 'Dépenses',
              value: '${_stats.expenseCount}',
              color: color,
            ),
            _buildStatDivider(theme),
            _buildStatItem(
              theme,
              icon: Icons.euro,
              label: 'Total',
              value: '${_stats.totalAmount.toStringAsFixed(0)}€',
              color: color,
            ),
            _buildStatDivider(theme),
            _buildStatItem(
              theme,
              icon: Icons.show_chart,
              label: 'Moyenne',
              value: '${_stats.averageAmount.toStringAsFixed(0)}€',
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 60,
      color: theme.dividerColor,
    );
  }

  Widget _buildExpenseItem(dynamic expense, ThemeData theme, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: expense.category?.icon != null
              ? Text(expense.category!.icon!)
              : Icon(Icons.receipt, color: color),
        ),
        title: Text(
          expense.note ?? expense.category?.name ?? 'Dépense',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatDate(expense.expenseDate),
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          '${expense.amount.toStringAsFixed(2)}€',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          context.push('/expenses/${expense.id}');
        },
      ),
    );
  }

  Widget _buildNoExpenses(ThemeData theme, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: theme.dividerColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune dépense avec ce tag',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez ce tag à vos dépenses\npour les retrouver ici',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return "Aujourd'hui";
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _editTag() async {
    final result = await showDialog<Tag>(
      context: context,
      builder: (context) => CreateTagDialog(tagToEdit: _tag),
    );

    if (result != null) {
      setState(() => _tag = result);
      _loadStats();
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce tag ?'),
        content: Text(
          'Le tag "${_tag.name}" sera supprimé. Cette action est irréversible.\n\n'
          'Les dépenses associées ne seront pas supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await TagService.deleteTag(_tag.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tag "${_tag.name}" supprimé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
