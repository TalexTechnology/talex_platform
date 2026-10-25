import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:talex_platform/features/talent/domain/services/pin_hasher.dart';

void main() {
  test('generatePin returns six digits without weak patterns', () {
    final random = Random(7);
    final pins = List.generate(2000, (_) => PinHasher.generatePin(random));
    for (final pin in pins) {
      expect(pin, matches(RegExp(r'^[1-9]\d{5}$')));
      expect(pin.split('').toSet().length, greaterThanOrEqualTo(3));
      expect('0123456789012345'.contains(pin), isFalse);
      expect('9876543210987654'.contains(pin), isFalse);
    }
    expect(pins.toSet().length, greaterThan(1990));
  });
}
