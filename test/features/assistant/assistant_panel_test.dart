import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talex_platform/core/error/failure.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_brief.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_reply.dart';
import 'package:talex_platform/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:talex_platform/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:talex_platform/features/assistant/presentation/markdown/assistant_markdown_view.dart';
import 'package:talex_platform/features/assistant/presentation/pages/assistant_panel.dart';

void main() {
  const brief = AssistantBrief(
    audience: AssistantAudience.company,
    locale: 'en',
    workspace: WorkspaceFacts(
      organization: 'Acme',
      activeVacancies: 2,
      completed: 1,
    ),
  );

  testWidgets('markdown tables and code scroll inside a conversation list', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              AssistantMarkdownView(
                data: '''
| Item | Count |
| --- | --- |
| Active vacancies | 2 |

```dart
final total = 2;
```

See [TaleX](https://talex.example)
''',
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Active vacancies'), findsOneWidget);
    expect(find.textContaining('final total'), findsOneWidget);
    expect(find.text('TaleX'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome suggestions send one grounded answer', (tester) async {
    final bloc = AssistantBloc(repository: _Instant());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: bloc,
            child: AssistantPanel(brief: brief, onClose: _noop),
          ),
        ),
      ),
    );
    expect(find.text('Hello, I am TaleXito'), findsOneWidget);
    await tester.tap(find.text('Show me the saved answers'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('Acme'), findsWidgets);
    expect(find.text('Hello, I am TaleXito'), findsNothing);
    expect(
      bloc.state.messages.where((message) => message.role.name == 'user'),
      hasLength(1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('blank input does not start a conversation', (tester) async {
    final bloc = AssistantBloc(repository: _Instant());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: bloc,
            child: AssistantPanel(brief: brief, onClose: _noop),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('assistant-input')),
      '   ',
    );
    await tester.tap(find.byKey(const ValueKey('assistant-send')));
    await tester.pump();
    expect(find.byKey(const ValueKey('assistant-welcome')), findsOneWidget);
    expect(bloc.state.messages, isEmpty);
  });
}

void _noop() {}

class _Instant implements AssistantRepository {
  @override
  Future<Either<Failure, AssistantReply>> reply(
    AssistantRequest request,
  ) async {
    return const Right(
      AssistantReply(
        markdown:
            '## Acme\n\n| Item | Count |\n| --- | --- |\n| Active vacancies | 2 |\n',
      ),
    );
  }
}
