import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/ai_assistant.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/goal_provider.dart';
import '../../services/ai_assistant_service.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    await AIAssistantService.init();
    final history = AIAssistantService.getHistory();

    setState(() {
      if (history.isEmpty) {
        _messages = [AIAssistantService.getWelcomeMessage()];
      } else {
        _messages = history;
      }
      _isLoading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messageController.clear();
    _focusNode.unfocus();

    // Ajouter le message utilisateur
    setState(() {
      _messages.add(ChatMessage.user(text));
      _isTyping = true;
    });
    _scrollToBottom();

    // Obtenir les données financières
    final expenses = context.read<ExpenseProvider>().expenses;
    final budgets = context.read<BudgetProvider>().budgets;
    final goals = context.read<GoalProvider>().goals;

    // Traiter et obtenir la réponse
    final response = await AIAssistantService.processMessage(
      text,
      expenses: expenses,
      budgets: budgets,
      goals: goals,
    );

    setState(() {
      _messages.add(response);
      _isTyping = false;
    });
    _scrollToBottom();
  }

  Future<void> _handleQuickAction(QuickAction action) async {
    setState(() => _isTyping = true);

    final expenses = context.read<ExpenseProvider>().expenses;
    final budgets = context.read<BudgetProvider>().budgets;
    final goals = context.read<GoalProvider>().goals;

    final response = await AIAssistantService.processQuickAction(
      action.actionType,
      expenses: expenses,
      budgets: budgets,
      goals: goals,
    );

    setState(() {
      _messages.add(response);
      _isTyping = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.2),
                    AppColors.secondary.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.secondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assistant IA'),
                Text(
                  '100% privé • Données locales',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Effacer l\'historique',
            onPressed: _confirmClearHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Privacy banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.green.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.security, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vos données ne quittent jamais votre appareil',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator(theme);
                      }
                      return _buildMessageBubble(_messages[index], theme);
                    },
                  ),
          ),

          // Quick suggestions
          if (_messages.isNotEmpty &&
              _messages.last.type == MessageType.assistant &&
              _messages.last.quickActions != null)
            _buildQuickActions(_messages.last.quickActions!, theme),

          // Input
          _buildInputBar(theme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeData theme) {
    final isUser = message.type == MessageType.user;
    final isAlert = message.type == MessageType.alert;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isAlert
                  ? Colors.orange.withOpacity(0.1)
                  : AppColors.secondary.withOpacity(0.15),
              child: isAlert
                  ? const Text('⚠️', style: TextStyle(fontSize: 14))
                  : const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppColors.secondary,
                    ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : isAlert
                        ? Colors.orange.withOpacity(0.1)
                        : theme.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    )
                  : _buildFormattedContent(message.content, theme),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.person, size: 18, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }

  /// Construit le contenu formaté avec Markdown et barres de progression
  Widget _buildFormattedContent(String content, ThemeData theme) {
    // Convertir les barres de texte en widgets de progression
    final processedContent = _convertProgressBars(content);

    if (processedContent.hasProgressBars) {
      // Si on a des barres de progression, construire un widget mixte
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: processedContent.widgets.map((item) {
          if (item is String) {
            return MarkdownBody(
              data: item,
              styleSheet: _getMarkdownStyleSheet(theme),
              shrinkWrap: true,
            );
          } else {
            return item as Widget;
          }
        }).toList(),
      );
    }

    // Sinon, juste du Markdown
    return MarkdownBody(
      data: content,
      styleSheet: _getMarkdownStyleSheet(theme),
      shrinkWrap: true,
    );
  }

  /// Retourne le style pour le Markdown
  MarkdownStyleSheet _getMarkdownStyleSheet(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return MarkdownStyleSheet(
      p: theme.textTheme.bodyMedium?.copyWith(color: textColor),
      strong: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      em: theme.textTheme.bodyMedium?.copyWith(
        fontStyle: FontStyle.italic,
        color: textColor,
      ),
      h1: theme.textTheme.titleLarge?.copyWith(color: textColor),
      h2: theme.textTheme.titleMedium?.copyWith(color: textColor),
      h3: theme.textTheme.titleSmall?.copyWith(color: textColor),
      listBullet: theme.textTheme.bodyMedium?.copyWith(color: textColor),
      blockquoteDecoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// Convertit les barres de texte (████) en widgets de progression
  _ProcessedContent _convertProgressBars(String content) {
    // Pattern pour détecter les barres de progression: ████████ XX% (XX.XX€)
    final progressPattern = RegExp(r'([█▓░]+)\s*(\d+)%\s*\(([^)]+)\)');

    if (!progressPattern.hasMatch(content)) {
      return _ProcessedContent(widgets: [content], hasProgressBars: false);
    }

    final List<dynamic> widgets = [];
    final lines = content.split('\n');

    for (final line in lines) {
      final match = progressPattern.firstMatch(line);
      if (match != null) {
        // Extraire les informations
        final percentage = int.tryParse(match.group(2)!) ?? 0;
        final amount = match.group(3)!;

        // Trouver le texte avant la barre (ex: "🎯 **Loisirs**")
        final beforeBar = line.substring(0, match.start).trim();

        if (beforeBar.isNotEmpty) {
          widgets.add(beforeBar);
        }

        // Ajouter la barre de progression widget
        widgets.add(_buildProgressBarWidget(percentage, amount));
      } else {
        // Ligne normale, ajouter au markdown
        if (widgets.isNotEmpty && widgets.last is String) {
          widgets[widgets.length - 1] = '${widgets.last}\n$line';
        } else {
          widgets.add(line);
        }
      }
    }

    return _ProcessedContent(widgets: widgets, hasProgressBars: true);
  }

  /// Construit un widget de barre de progression
  Widget _buildProgressBarWidget(int percentage, String amount) {
    // Couleur basée sur le pourcentage
    Color progressColor;
    if (percentage <= 30) {
      progressColor = Colors.green;
    } else if (percentage <= 60) {
      progressColor = AppColors.primary;
    } else if (percentage <= 80) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$percentage%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: progressColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($amount)',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.secondary.withOpacity(0.15),
            child: const Icon(
              Icons.auto_awesome,
              size: 16,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                _buildDot(1),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.3 + (0.7 * (1 - value).abs())),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(List<QuickAction> actions, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: actions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: Text(action.icon),
                label: Text(
                  action.label,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                backgroundColor: isDark
                    ? AppColors.surfaceDark
                    : theme.chipTheme.backgroundColor,
                side: BorderSide(
                  color: isDark
                      ? AppColors.primary.withOpacity(0.3)
                      : Colors.grey.shade300,
                ),
                onPressed: () => _handleQuickAction(action),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Posez votre question...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendMessage(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer l\'historique ?'),
        content: const Text(
          'Cette action supprimera tous les messages. '
          'L\'assistant oubliera notre conversation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AIAssistantService.clearHistory();
      setState(() {
        _messages = [AIAssistantService.getWelcomeMessage()];
      });
    }
  }
}

/// Classe helper pour le contenu traité
class _ProcessedContent {
  final List<dynamic> widgets;
  final bool hasProgressBars;

  _ProcessedContent({
    required this.widgets,
    required this.hasProgressBars,
  });
}
