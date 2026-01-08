import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/expense_split.dart';
import '../../providers/auth_provider.dart';
import '../../services/split_service.dart';

class SplitExpenseScreen extends StatefulWidget {
  final String? expenseId;
  final String? expenseTitle;
  final double? expenseAmount;

  const SplitExpenseScreen({
    super.key,
    this.expenseId,
    this.expenseTitle,
    this.expenseAmount,
  });

  @override
  State<SplitExpenseScreen> createState() => _SplitExpenseScreenState();
}

class _SplitExpenseScreenState extends State<SplitExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _participantController = TextEditingController();

  SplitMode _selectedMode = SplitMode.equal;
  bool _includeMe = true;
  final List<_ParticipantEntry> _participants = [];
  List<SplitContact> _frequentContacts = [];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.expenseTitle ?? '';
    if (widget.expenseAmount != null) {
      _amountController.text = widget.expenseAmount!.toStringAsFixed(2);
    }
    _loadFrequentContacts();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _participantController.dispose();
    super.dispose();
  }

  void _loadFrequentContacts() {
    setState(() {
      _frequentContacts = SplitService.getFrequentContacts();
    });
  }

  double get _totalAmount => double.tryParse(_amountController.text) ?? 0;

  double get _sharePerPerson {
    if (_totalAmount == 0) return 0;
    final count = _participants.length + (_includeMe ? 1 : 0);
    if (count == 0) return 0;
    return _totalAmount / count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partager une dépense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Ex: Dîner au restaurant',
                prefixIcon: Icon(Icons.receipt),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty == true ? 'Requis' : null,
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Montant total',
                prefixIcon: Icon(Icons.euro),
                suffixText: '€',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v?.isEmpty == true) return 'Requis';
                if (double.tryParse(v!) == null) return 'Montant invalide';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Split mode
            Text(
              'Mode de partage',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildModeSelector(theme),
            const SizedBox(height: 24),

            // Include me
            SwitchListTile(
              title: const Text('M\'inclure dans le partage'),
              subtitle: Text(
                _includeMe
                    ? 'Ma part: ${_sharePerPerson.toStringAsFixed(2)}€'
                    : 'Je suis exclu du partage',
              ),
              value: _includeMe,
              onChanged: (v) => setState(() => _includeMe = v),
            ),
            const SizedBox(height: 16),

            // Participants
            Text(
              'Participants',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Frequent contacts
            if (_frequentContacts.isNotEmpty) ...[
              Text(
                'Contacts fréquents',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _frequentContacts.map((contact) {
                  final isAdded =
                      _participants.any((p) => p.name == contact.name);
                  return ActionChip(
                    avatar: isAdded
                        ? const Icon(Icons.check, size: 18)
                        : const Icon(Icons.person_add, size: 18),
                    label: Text(contact.name),
                    onPressed: isAdded
                        ? null
                        : () => _addParticipant(contact.name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Add participant
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _participantController,
                    decoration: const InputDecoration(
                      labelText: 'Ajouter un participant',
                      hintText: 'Nom',
                      prefixIcon: Icon(Icons.person_add),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (name) {
                      if (name.isNotEmpty) {
                        _addParticipant(name);
                        _participantController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () {
                    if (_participantController.text.isNotEmpty) {
                      _addParticipant(_participantController.text);
                      _participantController.clear();
                    }
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Participants list
            if (_participants.isNotEmpty) ...[
              ..._participants.asMap().entries.map((entry) {
                final index = entry.key;
                final participant = entry.value;
                return _buildParticipantTile(participant, index, theme);
              }),
              const SizedBox(height: 16),
            ],

            // Summary
            if (_participants.isNotEmpty) _buildSummary(theme),
            const SizedBox(height: 24),

            // Create button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _participants.isNotEmpty ? _createSplit : null,
                icon: const Icon(Icons.check),
                label: const Text(
                  'Créer le partage',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SplitMode.values.map((mode) {
        final isSelected = _selectedMode == mode;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mode.icon),
              const SizedBox(width: 4),
              Text(mode.label),
            ],
          ),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedMode = mode),
          selectedColor: AppColors.primary.withOpacity(0.2),
        );
      }).toList(),
    );
  }

  Widget _buildParticipantTile(
    _ParticipantEntry participant,
    int index,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            participant.name[0].toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(participant.name),
        subtitle: _selectedMode == SplitMode.equal
            ? Text('${_sharePerPerson.toStringAsFixed(2)}€')
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedMode != SplitMode.equal)
              SizedBox(
                width: 80,
                child: TextField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    suffixText: '€',
                    isDense: true,
                  ),
                  onChanged: (v) {
                    participant.customAmount = double.tryParse(v) ?? 0;
                  },
                ),
              ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _removeParticipant(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(ThemeData theme) {
    final participantCount = _participants.length + (_includeMe ? 1 : 0);
    final toReceive = _participants.length * _sharePerPerson;

    return Card(
      color: AppColors.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total'),
                Text(
                  '${_totalAmount.toStringAsFixed(2)}€',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$participantCount personnes'),
                Text('${_sharePerPerson.toStringAsFixed(2)}€ / personne'),
              ],
            ),
            if (_includeMe) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ma part'),
                  Text(
                    '${_sharePerPerson.toStringAsFixed(2)}€',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'À recevoir',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${toReceive.toStringAsFixed(2)}€',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addParticipant(String name) {
    if (name.isEmpty) return;
    if (_participants.any(
        (p) => p.name.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce participant existe déjà')),
      );
      return;
    }

    setState(() {
      _participants.add(_ParticipantEntry(name: name));
    });
  }

  void _removeParticipant(int index) {
    setState(() {
      _participants.removeAt(index);
    });
  }

  Future<void> _createSplit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins un participant')),
      );
      return;
    }

    final participants = _participants.map((p) {
      final amount = _selectedMode == SplitMode.equal
          ? _sharePerPerson
          : p.customAmount;
      return SplitParticipant(
        id: const Uuid().v4(),
        name: p.name,
        amount: amount,
      );
    }).toList();

    final userId = context.read<AuthProvider>().user?.id ?? '';
    await SplitService.createSplit(
      expenseId: widget.expenseId ?? const Uuid().v4(),
      userId: userId,
      title: _titleController.text,
      totalAmount: _totalAmount,
      mode: _selectedMode,
      participants: participants,
      includeMe: _includeMe,
      myShare: _includeMe ? _sharePerPerson : 0,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Partage créé ! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }
}

class _ParticipantEntry {
  final String name;
  double customAmount;

  _ParticipantEntry({
    required this.name,
    this.customAmount = 0,
  });
}
