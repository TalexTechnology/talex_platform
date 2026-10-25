import 'package:flutter_test/flutter_test.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_brief.dart';
import 'package:talex_platform/features/assistant/domain/services/assistant_composer.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_reply.dart';
import 'package:talex_platform/features/assistant/presentation/markdown/assistant_markdown.dart';

void main() {
  test('parses headings, emphasis, lists, tables, quotes, and code', () {
    final blocks = parseAssistantMarkdown('''
## Vacantes

**Diseño** y *producto*

- Activa
- Cerrada

| Dato | Cantidad |
| --- | --- |
| Activas | 2 |

> Una nota

Código `interno`

```dart
final x = 1;
```

Ver [TaleX](https://talex.example)
''');

    expect(blocks.whereType<MdHeading>().single.level, 2);
    expect(blocks.whereType<MdListBlock>().single.items, hasLength(2));
    final table = blocks.whereType<MdTable>().single;
    expect(table.header, hasLength(2));
    expect(table.rows.single, hasLength(2));
    expect(blocks.whereType<MdQuote>(), hasLength(1));
    expect(blocks.whereType<MdCodeBlock>().single.language, 'dart');
    final link = blocks.whereType<MdParagraph>().last.spans.last;
    expect(link.href, 'https://talex.example');
  });

  test('keeps an unfinished fence and emphasis readable', () {
    final blocks = parseAssistantMarkdown('```dart\nfinal x = 1;');
    expect(blocks.single, isA<MdCodeBlock>());
    expect((blocks.single as MdCodeBlock).code, 'final x = 1;');

    final bold = parseAssistantInline('**todavía');
    expect(bold.single.bold, isTrue);
    expect(bold.single.text, 'todavía');
  });

  test('does not keep an unsafe link target', () {
    final spans = parseAssistantInline('[pulsa](javascript:alert(1))');
    expect(spans.single.text, 'pulsa');
    expect(spans.single.href, isNull);
  });

  test('culture answers stay readable and outside questions stay fixed', () {
    const brief = AssistantBrief(
      audience: AssistantAudience.company,
      locale: 'es',
      workspace: WorkspaceFacts(
        organization: 'Acme',
        hasDna: true,
        dnaSummary: 'Cuidado del equipo',
      ),
    );
    final culture = AssistantComposer.compose(
      const AssistantRequest(
        question: '¿Cuál es la cultura de la empresa?',
        brief: brief,
      ),
    );
    expect(parseAssistantMarkdown(culture).whereType<MdHeading>(), isNotEmpty);
    expect(culture, contains('Respuestas'));
    expect(culture, contains('Acme'));
    expect(culture, contains('Cuidado del equipo'));
    expect(culture.toLowerCase(), isNot(contains('explic')));

    final changed = AssistantComposer.plan(
      const AssistantRequest(
        question: 'cambia Cuidado del equipo por Respeto',
        brief: brief,
      ),
    );
    expect(changed.edit?.values, ['Respeto']);
    expect(changed.markdown, contains('Listo. Ya quedó el cambio.'));
    expect(changed.markdown.toLowerCase(), isNot(contains('explic')));

    final added = AssistantComposer.plan(
      AssistantRequest(
        question: 'agrega Empatía a cultura',
        brief: brief,
      ),
    );
    expect(added.edit?.culture, ['Empatía']);
    expect(added.edit?.values, ['Cuidado del equipo']);

    final outside = AssistantComposer.compose(
      const AssistantRequest(question: '¿Qué tiempo hace hoy?', brief: brief),
    );
    expect(outside, contains('queda por fuera de lo que hago'));
    expect(outside, isNot(contains('Cuidado del equipo')));

    final guide = AssistantComposer.compose(
      const AssistantRequest(question: '¿Dónde veo las vacantes?', brief: brief),
    );
    expect(guide, contains('Vacante'));
  });
}
