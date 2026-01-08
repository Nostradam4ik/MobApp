import 'package:flutter_test/flutter_test.dart';

// Tests pour la logique des indices de publicités natives
// Ces tests vérifient la logique mathématique pure sans dépendances aux services
void main() {
  group('NativeAdHelper Logic', () {
    // Constantes comme dans NativeAdHelper
    const int adInterval = 5;

    // Fonctions de test qui reproduisent la logique de NativeAdHelper
    int getRealIndex(int listIndex) {
      if (listIndex < adInterval) return listIndex;
      final adsBeforeIndex = listIndex ~/ (adInterval + 1);
      return listIndex - adsBeforeIndex;
    }

    bool isAdIndex(int listIndex) {
      if (listIndex < adInterval) return false;
      return (listIndex + 1) % (adInterval + 1) == 0;
    }

    int getTotalCountWithAds(int itemCount) {
      if (itemCount == 0) return 0;
      final adsCount = itemCount ~/ adInterval;
      return itemCount + adsCount;
    }

    String getAdId(int listIndex) {
      final adNumber = listIndex ~/ (adInterval + 1);
      return 'list_native_ad_$adNumber';
    }

    group('isAdIndex', () {
      test('should return false for indices before first ad position', () {
        for (int i = 0; i < adInterval; i++) {
          expect(isAdIndex(i), false, reason: 'Index $i should not be ad');
        }
      });

      test('should return true for ad positions', () {
        // Avec interval de 5, l'index 5 est une pub (après 5 items)
        expect(isAdIndex(5), true);
        // L'index 11 est aussi une pub (après 10 items + 1 pub)
        expect(isAdIndex(11), true);
        // L'index 17 (après 15 items + 2 pubs)
        expect(isAdIndex(17), true);
      });

      test('should return false for non-ad positions after first ad', () {
        expect(isAdIndex(6), false);
        expect(isAdIndex(7), false);
        expect(isAdIndex(10), false);
        expect(isAdIndex(12), false);
      });
    });

    group('getRealIndex', () {
      test('should return same index before first ad', () {
        for (int i = 0; i < adInterval; i++) {
          expect(getRealIndex(i), i);
        }
      });

      test('should adjust index after ad positions', () {
        // Index 6 dans la liste affichée = index 5 dans la liste originale
        // (car index 5 est une pub)
        expect(getRealIndex(6), 5);
        expect(getRealIndex(7), 6);
        expect(getRealIndex(10), 9);
        // Après la 2ème pub (index 11)
        expect(getRealIndex(12), 10);
        expect(getRealIndex(13), 11);
      });
    });

    group('getTotalCountWithAds', () {
      test('should return 0 for empty list', () {
        expect(getTotalCountWithAds(0), 0);
      });

      test('should return same count for list smaller than interval', () {
        expect(getTotalCountWithAds(1), 1);
        expect(getTotalCountWithAds(3), 3);
        expect(getTotalCountWithAds(4), 4);
      });

      test('should add ads for larger lists', () {
        // 5 items = 1 pub (5 items + 1 ad = 6)
        expect(getTotalCountWithAds(5), 6);
        // 10 items = 2 pubs (10 items + 2 ads = 12)
        expect(getTotalCountWithAds(10), 12);
        // 15 items = 3 pubs
        expect(getTotalCountWithAds(15), 18);
        // 6 items = 1 pub
        expect(getTotalCountWithAds(6), 7);
      });
    });

    group('getAdId', () {
      test('should generate unique ids for different ad positions', () {
        final id1 = getAdId(5);  // Première pub
        final id2 = getAdId(11); // Deuxième pub
        final id3 = getAdId(17); // Troisième pub

        expect(id1, isNot(equals(id2)));
        expect(id2, isNot(equals(id3)));
        expect(id1, contains('native_ad'));
      });

      test('should generate consistent ids for same position', () {
        final id1 = getAdId(5);
        final id2 = getAdId(5);

        expect(id1, equals(id2));
      });

      test('should increment ad number correctly', () {
        expect(getAdId(5), 'list_native_ad_0');
        expect(getAdId(11), 'list_native_ad_1');
        expect(getAdId(17), 'list_native_ad_2');
      });
    });

    group('integration', () {
      test('should correctly map mixed list indices', () {
        // Simuler une liste de 12 items avec des pubs
        // Sans pubs: 0,1,2,3,4,5,6,7,8,9,10,11
        // Avec pubs: 0,1,2,3,4,[AD],5,6,7,8,9,[AD],10,11

        final items = List.generate(12, (i) => 'Item $i');
        final totalCount = getTotalCountWithAds(items.length);

        expect(totalCount, 14); // 12 items + 2 ads

        int itemsFound = 0;
        int adsFound = 0;

        for (int i = 0; i < totalCount; i++) {
          if (isAdIndex(i)) {
            adsFound++;
          } else {
            final realIndex = getRealIndex(i);
            expect(realIndex, lessThan(items.length),
                reason: 'Index $i maps to $realIndex which exceeds ${items.length - 1}');
            itemsFound++;
          }
        }

        expect(itemsFound, 12);
        expect(adsFound, 2);
      });

      test('should handle exact multiple of interval', () {
        // 15 items = exactement 3 multiples de 5
        final items = List.generate(15, (i) => 'Item $i');
        final totalCount = getTotalCountWithAds(items.length);

        expect(totalCount, 18); // 15 + 3 ads

        int itemsFound = 0;
        int adsFound = 0;

        for (int i = 0; i < totalCount; i++) {
          if (isAdIndex(i)) {
            adsFound++;
          } else {
            itemsFound++;
          }
        }

        expect(itemsFound, 15);
        expect(adsFound, 3);
      });

      test('should handle list with 1 item less than interval', () {
        // 4 items = pas de pub
        final items = List.generate(4, (i) => 'Item $i');
        final totalCount = getTotalCountWithAds(items.length);

        expect(totalCount, 4);

        for (int i = 0; i < totalCount; i++) {
          expect(isAdIndex(i), false);
          expect(getRealIndex(i), i);
        }
      });
    });
  });
}
