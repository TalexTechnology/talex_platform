import 'package:flutter_test/flutter_test.dart';
import 'package:talex_platform/core/supabase/supabase_gateway.dart';
import 'package:talex_platform/core/supabase/supabase_session.dart';

void main() {
  test('public entity id prefers the imported Firebase id', () {
    expect(
      publicEntityId({
        'id': '11111111-2222-3333-4444-555555555555',
        'firebase_id': 'acme-firestore',
      }),
      'acme-firestore',
    );
    expect(
      publicEntityId({'id': '11111111-2222-3333-4444-555555555555'}),
      '11111111-2222-3333-4444-555555555555',
    );
  });

  test('clears a minted session on demand', () {
    final store = SupabaseAccessToken(clock: DateTime.now);
    store.clear();
    expect(store.hasToken, isFalse);
  });

  test('uuid detector accepts canonical ids only', () {
    expect(isUuid('11111111-2222-3333-4444-555555555555'), isTrue);
    expect(isUuid('company-from-firestore'), isFalse);
  });
}
