import 'package:flutter_test/flutter_test.dart';
import 'package:talex_platform/features/talent/domain/services/assessment_invite_link.dart';

void main() {
  group('AssessmentInviteLink', () {
    test('reads the token from a hash route', () {
      expect(
        AssessmentInviteLink.tokenFromUri(
          Uri.parse('https://talex-platform.web.app/#/assessment?token=abc123'),
        ),
        'abc123',
      );
    });

    test('reads the token from a hash fragment string', () {
      expect(
        AssessmentInviteLink.tokenFromFragment('/assessment?token=xyz'),
        'xyz',
      );
    });

    test('ignores other routes', () {
      expect(
        AssessmentInviteLink.tokenFromUri(
          Uri.parse('https://talex-platform.web.app/#/login'),
        ),
        isNull,
      );
    });
  });
}
