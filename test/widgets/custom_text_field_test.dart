// ============================================================================
// SmartSpend - Widget Tests: CustomTextField
// Développé par: Andrii Zhmuryk
// LinkedIn: https://www.linkedin.com/in/andrii-zhmuryk-5a3a972b4/
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/widgets/common/custom_text_field.dart';

void main() {
  group('CustomTextField Widget', () {
    testWidgets('affiche le label correctement', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: TextEditingController(),
              label: 'Email',
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('affiche le hint correctement', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: TextEditingController(),
              label: 'Email',
              hint: 'votre@email.com',
            ),
          ),
        ),
      );

      expect(find.text('votre@email.com'), findsOneWidget);
    });

    testWidgets('affiche le texte d\'erreur', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: TextEditingController(),
              label: 'Email',
              errorText: 'Email invalide',
            ),
          ),
        ),
      );

      expect(find.text('Email invalide'), findsOneWidget);
    });

    testWidgets('masque le texte quand obscureText est true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: TextEditingController(),
              label: 'Mot de passe',
              obscureText: true,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
    });

    testWidgets('affiche le prefixIcon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: TextEditingController(),
              label: 'Email',
              prefixIcon: const Icon(Icons.email),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('affiche le suffixIcon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: TextEditingController(),
              label: 'Mot de passe',
              suffixIcon: IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('utilise le bon keyboardType', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: TextEditingController(),
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, TextInputType.emailAddress);
    });

    testWidgets('appelle onSubmitted quand soumis', (tester) async {
      String? submittedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: TextEditingController(),
              label: 'Test',
              onSubmitted: (value) {
                submittedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test value');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submittedValue, 'test value');
    });

    testWidgets('met à jour le controller quand le texte change', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: controller,
              label: 'Test',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'new text');
      await tester.pump();

      expect(controller.text, 'new text');
    });

    testWidgets('respecte le textInputAction', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: TextEditingController(),
              label: 'Test',
              textInputAction: TextInputAction.next,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.textInputAction, TextInputAction.next);
    });
  });
}
