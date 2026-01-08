import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/data/models/category.dart';

void main() {
  group('Category', () {
    final testCategory = Category(
      id: 'cat-1',
      userId: 'user-123',
      name: 'Alimentation',
      icon: 'restaurant',
      color: '#FF5722',
      isDefault: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    group('fromJson', () {
      test('should create Category from valid JSON', () {
        final json = {
          'id': 'cat-1',
          'user_id': 'user-123',
          'name': 'Transport',
          'icon': 'directions_car',
          'color': '#2196F3',
          'is_default': false,
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final category = Category.fromJson(json);

        expect(category.id, 'cat-1');
        expect(category.userId, 'user-123');
        expect(category.name, 'Transport');
        expect(category.icon, 'directions_car');
        expect(category.color, '#2196F3');
        expect(category.isDefault, false);
      });

      test('should handle null userId', () {
        final json = {
          'id': 'cat-1',
          'name': 'Default Category',
          'icon': 'star',
          'color': '#FFD700',
          'is_default': true,
          'created_at': '2024-01-15T10:00:00.000Z',
          'updated_at': '2024-01-15T10:00:00.000Z',
        };

        final category = Category.fromJson(json);

        expect(category.userId, isNull);
        expect(category.isDefault, true);
      });
    });

    group('toJson', () {
      test('should convert Category to JSON', () {
        final json = testCategory.toJson();

        expect(json['name'], 'Alimentation');
        expect(json['icon'], 'restaurant');
        expect(json['color'], '#FF5722');
        expect(json['is_default'], true);
      });
    });

    group('copyWith', () {
      test('should create copy with updated name', () {
        final copy = testCategory.copyWith(name: 'Restaurant');

        expect(copy.name, 'Restaurant');
        expect(copy.id, testCategory.id);
        expect(copy.icon, testCategory.icon);
        expect(copy.color, testCategory.color);
      });

      test('should create copy with multiple updates', () {
        final copy = testCategory.copyWith(
          name: 'Courses',
          icon: 'shopping_cart',
          color: '#4CAF50',
        );

        expect(copy.name, 'Courses');
        expect(copy.icon, 'shopping_cart');
        expect(copy.color, '#4CAF50');
        expect(copy.id, testCategory.id);
      });
    });

    group('colorValue', () {
      test('should return correct Color from hex string', () {
        final category = Category(
          id: 'cat-1',
          userId: 'user',
          name: 'Test',
          icon: 'star',
          color: '#FF5722',
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final color = category.colorValue;

        expect(color, isA<Color>());
        // #FF5722 = RGB(255, 87, 34)
        expect(color.red, 255);
        expect(color.green, 87);
        expect(color.blue, 34);
      });

      test('should handle hex without hash', () {
        final category = Category(
          id: 'cat-1',
          userId: 'user',
          name: 'Test',
          icon: 'star',
          color: '2196F3',
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final color = category.colorValue;

        // #2196F3 = RGB(33, 150, 243)
        expect(color.red, 33);
        expect(color.green, 150);
        expect(color.blue, 243);
      });
    });

    group('iconData', () {
      test('should return correct IconData for known icon', () {
        final category = Category(
          id: 'cat-1',
          userId: 'user',
          name: 'Food',
          icon: 'restaurant',
          color: '#FF5722',
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(category.iconData, isA<IconData>());
      });
    });

    group('equality', () {
      test('should be equal for same properties', () {
        final category1 = Category(
          id: 'cat-1',
          userId: 'user',
          name: 'Test',
          icon: 'star',
          color: '#FF5722',
          isDefault: false,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );
        final category2 = Category(
          id: 'cat-1',
          userId: 'user',
          name: 'Test',
          icon: 'star',
          color: '#FF5722',
          isDefault: false,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        expect(category1, equals(category2));
      });

      test('should not be equal for different names', () {
        final category1 = Category(
          id: 'cat-1',
          userId: 'user',
          name: 'Test1',
          icon: 'star',
          color: '#FF5722',
          isDefault: false,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );
        final category2 = Category(
          id: 'cat-1',
          userId: 'user',
          name: 'Test2',
          icon: 'star',
          color: '#FF5722',
          isDefault: false,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        expect(category1, isNot(equals(category2)));
      });
    });
  });
}
