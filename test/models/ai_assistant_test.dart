import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/ai_assistant.dart';

void main() {
  group('MessageType', () {
    test('should have 4 types', () {
      expect(MessageType.values.length, 4);
    });

    test('should have correct types', () {
      expect(MessageType.user, isNotNull);
      expect(MessageType.assistant, isNotNull);
      expect(MessageType.suggestion, isNotNull);
      expect(MessageType.alert, isNotNull);
    });
  });

  group('ChatMessage', () {
    group('factory constructors', () {
      test('ChatMessage.user should create user message', () {
        final message = ChatMessage.user('Hello');

        expect(message.content, 'Hello');
        expect(message.type, MessageType.user);
        expect(message.id, isNotEmpty);
        expect(message.timestamp, isNotNull);
        expect(message.quickActions, isNull);
      });

      test('ChatMessage.assistant should create assistant message', () {
        final message = ChatMessage.assistant('Response');

        expect(message.content, 'Response');
        expect(message.type, MessageType.assistant);
        expect(message.id, isNotEmpty);
        expect(message.timestamp, isNotNull);
      });

      test('ChatMessage.assistant should accept quick actions', () {
        final actions = [
          const QuickAction(
            label: 'Add expense',
            icon: '💰',
            actionType: 'add_expense',
          ),
        ];
        final message = ChatMessage.assistant('Response', actions: actions);

        expect(message.quickActions, isNotNull);
        expect(message.quickActions!.length, 1);
        expect(message.quickActions![0].label, 'Add expense');
      });

      test('ChatMessage.suggestion should create suggestion message', () {
        final message = ChatMessage.suggestion('Try this');

        expect(message.content, 'Try this');
        expect(message.type, MessageType.suggestion);
      });

      test('ChatMessage.alert should create alert message', () {
        final message = ChatMessage.alert('Warning!');

        expect(message.content, 'Warning!');
        expect(message.type, MessageType.alert);
      });
    });

    group('toJson', () {
      test('should convert ChatMessage to JSON', () {
        final message = ChatMessage(
          id: 'msg-123',
          content: 'Test content',
          type: MessageType.user,
          timestamp: DateTime(2024, 1, 15, 10, 0, 0),
          metadata: {'key': 'value'},
        );

        final json = message.toJson();

        expect(json['id'], 'msg-123');
        expect(json['content'], 'Test content');
        expect(json['type'], 'user');
        expect(json['timestamp'], isA<String>());
        expect(json['metadata'], {'key': 'value'});
      });
    });

    group('fromJson', () {
      test('should create ChatMessage from JSON', () {
        final json = {
          'id': 'msg-123',
          'content': 'Test content',
          'type': 'assistant',
          'timestamp': '2024-01-15T10:00:00.000Z',
          'metadata': {'key': 'value'},
        };

        final message = ChatMessage.fromJson(json);

        expect(message.id, 'msg-123');
        expect(message.content, 'Test content');
        expect(message.type, MessageType.assistant);
        expect(message.metadata, {'key': 'value'});
      });

      test('should parse all message types', () {
        for (final type in MessageType.values) {
          final json = {
            'id': 'msg-1',
            'content': 'Test',
            'type': type.name,
            'timestamp': '2024-01-15T10:00:00.000Z',
          };

          final message = ChatMessage.fromJson(json);
          expect(message.type, type);
        }
      });
    });

    group('equality', () {
      test('should be equal for same id, content, type, timestamp', () {
        final timestamp = DateTime(2024, 1, 15, 10, 0, 0);
        final message1 = ChatMessage(
          id: 'msg-1',
          content: 'Test',
          type: MessageType.user,
          timestamp: timestamp,
        );

        final message2 = ChatMessage(
          id: 'msg-1',
          content: 'Test',
          type: MessageType.user,
          timestamp: timestamp,
        );

        expect(message1, equals(message2));
      });
    });
  });

  group('QuickAction', () {
    test('should create QuickAction with all fields', () {
      const action = QuickAction(
        label: 'Add expense',
        icon: '💰',
        actionType: 'add_expense',
        params: {'amount': 50.0},
      );

      expect(action.label, 'Add expense');
      expect(action.icon, '💰');
      expect(action.actionType, 'add_expense');
      expect(action.params, {'amount': 50.0});
    });

    test('should create QuickAction without params', () {
      const action = QuickAction(
        label: 'View stats',
        icon: '📊',
        actionType: 'view_stats',
      );

      expect(action.params, isNull);
    });
  });

  group('UserIntent', () {
    test('should have all expected intents', () {
      expect(UserIntent.values.length, 14);
    });

    test('should have specific intents', () {
      expect(UserIntent.greeting, isNotNull);
      expect(UserIntent.askBalance, isNotNull);
      expect(UserIntent.askSpending, isNotNull);
      expect(UserIntent.askBudget, isNotNull);
      expect(UserIntent.askSavings, isNotNull);
      expect(UserIntent.askAdvice, isNotNull);
      expect(UserIntent.askCategory, isNotNull);
      expect(UserIntent.askComparison, isNotNull);
      expect(UserIntent.askPrediction, isNotNull);
      expect(UserIntent.askGoal, isNotNull);
      expect(UserIntent.addExpense, isNotNull);
      expect(UserIntent.setBudget, isNotNull);
      expect(UserIntent.createGoal, isNotNull);
      expect(UserIntent.unknown, isNotNull);
    });
  });

  group('ConversationContext', () {
    test('should create with default values', () {
      const context = ConversationContext();

      expect(context.recentMessages, isEmpty);
      expect(context.lastIntent, isNull);
      expect(context.currentTopic, isNull);
      expect(context.userPreferences, isEmpty);
    });

    test('should create with all fields', () {
      final messages = [ChatMessage.user('Hello')];
      final context = ConversationContext(
        recentMessages: messages,
        lastIntent: UserIntent.greeting,
        currentTopic: 'budgets',
        userPreferences: {'currency': 'EUR'},
      );

      expect(context.recentMessages.length, 1);
      expect(context.lastIntent, UserIntent.greeting);
      expect(context.currentTopic, 'budgets');
      expect(context.userPreferences, {'currency': 'EUR'});
    });

    group('copyWith', () {
      test('should create copy with updated lastIntent', () {
        const context = ConversationContext(lastIntent: UserIntent.greeting);
        final copy = context.copyWith(lastIntent: UserIntent.askBudget);

        expect(copy.lastIntent, UserIntent.askBudget);
      });

      test('should create copy with updated messages', () {
        const context = ConversationContext();
        final messages = [ChatMessage.user('Test')];
        final copy = context.copyWith(recentMessages: messages);

        expect(copy.recentMessages.length, 1);
      });

      test('should preserve other fields when updating one', () {
        final context = ConversationContext(
          lastIntent: UserIntent.greeting,
          currentTopic: 'savings',
          userPreferences: {'key': 'value'},
        );

        final copy = context.copyWith(currentTopic: 'expenses');

        expect(copy.currentTopic, 'expenses');
        expect(copy.lastIntent, UserIntent.greeting);
        expect(copy.userPreferences, {'key': 'value'});
      });
    });
  });

  group('FinancialSnapshot', () {
    test('should create with all required fields', () {
      const snapshot = FinancialSnapshot(
        totalSpentThisMonth: 1500.0,
        totalSpentToday: 50.0,
        averageDailySpending: 75.0,
        budgetRemaining: 500.0,
        budgetUsedPercentage: 75.0,
        topCategory: 'Alimentation',
        topCategoryAmount: 400.0,
        daysUntilEndOfMonth: 10,
        predictedMonthEnd: 2000.0,
        savingsGoalProgress: 60.0,
      );

      expect(snapshot.totalSpentThisMonth, 1500.0);
      expect(snapshot.totalSpentToday, 50.0);
      expect(snapshot.averageDailySpending, 75.0);
      expect(snapshot.budgetRemaining, 500.0);
      expect(snapshot.budgetUsedPercentage, 75.0);
      expect(snapshot.topCategory, 'Alimentation');
      expect(snapshot.topCategoryAmount, 400.0);
      expect(snapshot.daysUntilEndOfMonth, 10);
      expect(snapshot.predictedMonthEnd, 2000.0);
      expect(snapshot.savingsGoalProgress, 60.0);
      expect(snapshot.alerts, isEmpty);
      expect(snapshot.achievements, isEmpty);
    });

    test('should create with alerts and achievements', () {
      const snapshot = FinancialSnapshot(
        totalSpentThisMonth: 1500.0,
        totalSpentToday: 50.0,
        averageDailySpending: 75.0,
        budgetRemaining: 500.0,
        budgetUsedPercentage: 75.0,
        topCategory: 'Alimentation',
        topCategoryAmount: 400.0,
        daysUntilEndOfMonth: 10,
        predictedMonthEnd: 2000.0,
        savingsGoalProgress: 60.0,
        alerts: ['Budget alert', 'Spending warning'],
        achievements: ['First expense', 'Weekly streak'],
      );

      expect(snapshot.alerts.length, 2);
      expect(snapshot.achievements.length, 2);
      expect(snapshot.alerts, contains('Budget alert'));
      expect(snapshot.achievements, contains('First expense'));
    });
  });
}
