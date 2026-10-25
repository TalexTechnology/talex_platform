import 'dart:convert';
import 'dart:math';

/// Hash used by the live Firebase invite flow.
///
/// FNV-1a 32-bit is not a password hash. New Postgres invites should store
/// `pin_algorithm = bfcrypt` via `public.hash_invite_pin`. Do not change this
/// method until an approved cutover invalidates or dual-verifies existing pins.
abstract final class PinHasher {
  static String hash(String pin, String email) {
    final bytes = utf8.encode('${email.trim().toLowerCase()}|$pin');
    var hash = 2166136261;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static String generatePin([Random? random]) {
    final source = random ?? Random.secure();
    while (true) {
      final pin = List.generate(6, (_) => source.nextInt(10)).join();
      if (_isWeak(pin)) continue;
      return pin;
    }
  }

  static bool _isWeak(String pin) {
    if (pin.startsWith('0')) return true;
    if (pin.split('').toSet().length < 3) return true;
    const ascending = '0123456789012345';
    const descending = '9876543210987654';
    return ascending.contains(pin) || descending.contains(pin);
  }
}

abstract final class InvitePin {
  static const lifetime = Duration(minutes: 15);
  static const length = 6;

  static DateTime expiresAt([DateTime? now]) =>
      (now ?? DateTime.now()).add(lifetime);

  static bool isExpired({
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    if (expiresAt != null) return !expiresAt.isAfter(clock);
    if (createdAt != null) return !createdAt.add(lifetime).isAfter(clock);
    return false;
  }
}
