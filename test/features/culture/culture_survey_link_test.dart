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

  test('builds the demo link on the current origin', () {
    const id = '2a32deae-b8e4-411f-b0d9-664fd193d62b';
    final url = CultureSurveyLink.demoUrl(
      id,
      base: Uri.parse('https://platform.talex.com.co/#/admin?x=1'),
    );
    expect(url, 'https://platform.talex.com.co/cultura/$id?demo=1');
    expect(CultureSurveyLink.organizationIdFromUri(Uri.parse(url)), id);
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
