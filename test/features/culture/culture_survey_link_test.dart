import 'package:flutter_test/flutter_test.dart';
import 'package:talex_platform/features/culture/domain/culture_survey_link.dart';

void main() {
  test('reads the organization id from /cultura/:id', () {
    const id = '2a32deae-b8e4-411f-b0d9-664fd193d62b';
    expect(
      CultureSurveyLink.organizationIdFromUri(
        Uri.parse('https://platform.talex.com.co/cultura/$id'),
      ),
      id,
    );
  });

  test('does not treat other routes as a culture survey', () {
    expect(
      CultureSurveyLink.organizationIdFromUri(
        Uri.parse('https://platform.talex.com.co/login'),
      ),
      isNull,
    );
  });
}
