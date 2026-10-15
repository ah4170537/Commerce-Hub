import 'package:commerce_hub/services/customers_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoreCustomer.fromDocument', () {
    test('reads customer profile fields and keeps all document details', () {
      final customer = StoreCustomer.fromDocument('user-123', {
        'fullName': '  Alex Rivera ',
        'email': 'alex@example.com',
        'phoneNumber': '+1 555 0100',
        'photoURL': 'https://example.com/alex.jpg',
        'shippingAddress': {
          'address': '42 Main Street',
          'city': 'Springfield',
          'country': 'USA',
        },
      });

      expect(customer.id, 'user-123');
      expect(customer.name, 'Alex Rivera');
      expect(customer.email, 'alex@example.com');
      expect(customer.phone, '+1 555 0100');
      expect(customer.imageUrl, 'https://example.com/alex.jpg');
      expect(customer.details['shippingAddress'], {
        'address': '42 Main Street',
        'city': 'Springfield',
        'country': 'USA',
      });
    });

    test('supports alternate profile fields and missing optional values', () {
      final customer = StoreCustomer.fromDocument('user-456', {
        'displayName': 'Sam',
        'profileImageUrl': 'https://example.com/sam.jpg',
      });

      expect(customer.name, 'Sam');
      expect(customer.email, isNull);
      expect(customer.phone, isNull);
      expect(customer.imageUrl, 'https://example.com/sam.jpg');
      expect(customer.createdAt, isNull);
    });

    test('reads the users collection profile fields', () {
      final customer = StoreCustomer.fromDocument('user-789', {
        'name': 'Casey',
        'email': 'casey@example.com',
        'phone': '+1 555 0100',
        'profileImageUrl': 'https://example.com/profile.jpg',
      });

      expect(customer.name, 'Casey');
      expect(customer.email, 'casey@example.com');
      expect(customer.phone, '+1 555 0100');
      expect(customer.imageUrl, 'https://example.com/profile.jpg');
    });

    test('does not assign a display name when the record has none', () {
      final customer = StoreCustomer.fromDocument('user-no-name', {
        'email': 'no-name@example.com',
        'profileImageUrl': 'https://example.com/no-name.jpg',
      });

      expect(customer.name, isEmpty);
      expect(customer.imageUrl, 'https://example.com/no-name.jpg');
    });
  });
}
