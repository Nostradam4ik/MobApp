import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/bill_reminder.dart';
import '../../services/bill_reminder_service.dart';

/// Écran de gestion des rappels de factures
class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BillReminder> _activeReminders = [];
  List<BillReminder> _overdueReminders = [];
  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReminders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReminders() {
    setState(() {
      _activeReminders = BillReminderService.getActiveReminders();
      _overdueReminders = BillReminderService.getOverdueReminders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes factures'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('À venir'),
                  if (_activeReminders.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_activeReminders.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('En retard'),
                  if (_overdueReminders.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_overdueReminders.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRemindersList(_activeReminders, isOverdue: false),
          _buildRemindersList(_overdueReminders, isOverdue: true),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildRemindersList(List<BillReminder> reminders, {required bool isOverdue}) {
    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOverdue ? Icons.check_circle_outline : Icons.event_note_outlined,
              size: 64,
              color: AppColors.textTertiaryDark,
            ),
            const SizedBox(height: 16),
            Text(
              isOverdue
                  ? 'Aucune facture en retard'
                  : 'Aucun rappel de facture',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isOverdue
                  ? 'Vos paiements sont à jour !'
                  : 'Ajoutez un rappel pour ne rien oublier',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiaryDark,
                  ),
            ),
          ],
        ),
      );
    }

    // Calculer le total
    final total = reminders.fold(0.0, (sum, r) => sum + r.amount);

    return Column(
      children: [
        // Total
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isOverdue
                  ? [AppColors.error, AppColors.error.withValues(alpha: 0.7)]
                  : AppColors.primaryGradient,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOverdue ? 'Total en retard' : 'Total à venir',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isOverdue ? Icons.warning : Icons.receipt_long,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),

        // Liste
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              return _buildReminderCard(reminders[index], isOverdue: isOverdue);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(BillReminder reminder, {required bool isOverdue}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue
              ? AppColors.error.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showEditReminderDialog(reminder),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (reminder.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            reminder.description!,
                            style: TextStyle(
                              color: AppColors.textSecondaryDark,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    currencyFormat.format(reminder.amount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isOverdue ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Fréquence
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.glassDark,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.repeat, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          reminder.frequency.label,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Date d'échéance
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.glassDark,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: isOverdue ? AppColors.error : null,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(reminder.nextDueDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? AppColors.error : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Bouton marquer comme payé
                  TextButton.icon(
                    onPressed: () => _markAsPaid(reminder),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Payé'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _markAsPaid(BillReminder reminder) async {
    await BillReminderService.markAsPaid(reminder.id);
    _loadReminders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${reminder.title} marqué comme payé'),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  void _showAddReminderDialog() {
    _showReminderFormDialog(null);
  }

  void _showEditReminderDialog(BillReminder reminder) {
    _showReminderFormDialog(reminder);
  }

  void _showReminderFormDialog(BillReminder? existingReminder) {
    final titleController = TextEditingController(
      text: existingReminder?.title ?? '',
    );
    final descriptionController = TextEditingController(
      text: existingReminder?.description ?? '',
    );
    final amountController = TextEditingController(
      text: existingReminder?.amount.toStringAsFixed(2) ?? '',
    );
    DateTime selectedDate = existingReminder?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    ReminderFrequency selectedFrequency = existingReminder?.frequency ?? ReminderFrequency.monthly;
    int reminderDays = existingReminder?.reminderDaysBefore ?? 3;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingReminder == null ? 'Nouveau rappel' : 'Modifier le rappel'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre *',
                        hintText: 'Ex: Électricité, Internet...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Ex: Facture EDF mensuelle',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Montant *',
                        suffixText: '€',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date d\'échéance'),
                      subtitle: Text(_formatDate(selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ReminderFrequency>(
                      value: selectedFrequency,
                      decoration: const InputDecoration(
                        labelText: 'Fréquence',
                      ),
                      items: ReminderFrequency.values.map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Text(f.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedFrequency = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: reminderDays,
                      decoration: const InputDecoration(
                        labelText: 'Rappeler avant l\'échéance',
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 jour avant')),
                        DropdownMenuItem(value: 3, child: Text('3 jours avant')),
                        DropdownMenuItem(value: 5, child: Text('5 jours avant')),
                        DropdownMenuItem(value: 7, child: Text('1 semaine avant')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            reminderDays = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                if (existingReminder != null)
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await BillReminderService.deleteReminder(existingReminder.id);
                      _loadReminders();
                    },
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    child: const Text('Supprimer'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final amount = double.tryParse(
                      amountController.text.replaceAll(',', '.'),
                    );

                    if (title.isEmpty || amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez remplir les champs requis'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    final reminder = BillReminder(
                      id: existingReminder?.id ?? const Uuid().v4(),
                      userId: existingReminder?.userId ?? '',
                      title: title,
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      amount: amount,
                      dueDate: selectedDate,
                      frequency: selectedFrequency,
                      reminderDaysBefore: reminderDays,
                      isActive: true,
                      isPaid: false,
                      createdAt: existingReminder?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    if (existingReminder != null) {
                      await BillReminderService.updateReminder(reminder);
                    } else {
                      await BillReminderService.addReminder(reminder);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      _loadReminders();
                    }
                  },
                  child: Text(existingReminder == null ? 'Ajouter' : 'Sauvegarder'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
