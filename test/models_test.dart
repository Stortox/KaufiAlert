import 'package:flutter_test/flutter_test.dart';
import 'package:kaufi_alert_v2/models/product.dart';
import 'package:kaufi_alert_v2/models/store.dart';

Product _product({String title = 'Apfel', String imageUrl = 'a.png'}) => Product(
  title: title,
  price: '1,99€',
  discount: '-20%',
  basePrice: '',
  oldPrice: '2,49€',
  imageUrl: imageUrl,
  description: '',
  category: 'fruitAndVegetables',
  unit: '',
  gtin: '',
);

void main() {
  group('Product', () {
    test('equality is based on title + imageUrl', () {
      expect(_product(), equals(_product()));
      expect(_product(title: 'Birne'), isNot(equals(_product())));
    });

    test('de-duplicates in a Set (the previously broken behaviour)', () {
      final set = {_product(), _product(), _product(title: 'Birne')};
      expect(set.length, 2);
    });

    test('parses numeric price and discount', () {
      expect(_product().priceValue, 1.99);
      expect(_product().discountValue, 20);
    });

    test('tolerates missing JSON fields', () {
      final p = Product.fromJson({'title': 'X'});
      expect(p.title, 'X');
      expect(p.price, '');
      expect(p.priceValue, 0.0);
    });
  });

  group('Store', () {
    test('round-trips through JSON with [lat, lon] order', () {
      final store = Store.fromJson(Store.fallback.toJson());
      expect(store.position[0], Store.fallback.position[0]);
      expect(store.position[1], Store.fallback.position[1]);
    });

    test('reports Closed for a 0:00-0:00 day', () {
      const store = Store(
        storeId: 'X',
        name: 'X',
        address: 'X',
        // Every weekday closed.
        openingHours:
            'Mon: 0:00-0:00, Tue: 0:00-0:00, Wed: 0:00-0:00, Thu: 0:00-0:00, Fri: 0:00-0:00, Sat: 0:00-0:00, Sun: 0:00-0:00',
        position: [0, 0],
        country: 'DE',
      );
      expect(store.openingHoursForToday(), 'Closed');
    });
  });
}
