import 'package:talex_platform/features/assistant/domain/entities/assistant_brief.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_reply.dart';

/// A grounded answer, plus an optional change to the stored answers.
class AssistantPlan {
  const AssistantPlan({
    required this.markdown,
    this.edit,
    this.keepLocal = false,
  });

  final String markdown;
  final CompanyAnswerEdit? edit;

  /// When true, the model must not rewrite the answer.
  final bool keepLocal;
}

/// Builds a grounded Markdown answer from data the user can already see.
///
/// It does not call a model and does not invent counts, names, or completed actions.
abstract final class AssistantComposer {
  static String compose(AssistantRequest request) => plan(request).markdown;

  static AssistantPlan plan(AssistantRequest request) {
    final brief = request.brief;
    final en = brief.english;
    if (brief.audience == AssistantAudience.workspace) {
      return AssistantPlan(
        markdown: _workspace(request.question, brief.workspace, en),
      );
    }
    final facts = brief.workspace;
    if (facts == null || !facts.ready) {
      return AssistantPlan(
        markdown: en
            ? 'I am still reading your company workspace. Ask me again in a moment and I will use the data that is already in TaleX.'
            : 'Todavía estoy leyendo el espacio de tu empresa. Pregúntame de nuevo en un momento y usaré los datos que ya están en TaleX.',
        keepLocal: true,
      );
    }
    return _company(request.question, facts, en);
  }

  static AssistantPlan _company(String question, WorkspaceFacts facts, bool en) {
    final change = _change(question, facts);
    if (change.attempted) {
      final edit = change.edit;
      final lists = edit == null
          ? _lists(facts)
          : _Lists(edit.values, edit.culture, edit.standout);
      final notice = change.edit != null
          ? ''
          : change.notFound
          ? (en
                ? 'I did not find that answer.\n\n'
                : 'No encontré esa respuesta.\n\n')
          : (en
                ? 'Tell me if it goes in values, culture, or people.\n\n'
                : 'Dime si va en valores, cultura o personal.\n\n');
      return AssistantPlan(
        markdown:
            '$notice${_answers(facts.organization, lists, en, changed: change.edit != null)}',
        edit: change.edit,
        keepLocal: true,
      );
    }
    final query = question.trim().toLowerCase();
    if (_asksWhere(query)) {
      return AssistantPlan(markdown: _guide(query, facts, en));
    }
    if (_has(query, [
      'adn',
      'dna',
      'cultura',
      'culture',
      'valores',
      'values',
      'respuesta',
      'answer',
      'cómo trabaj',
      'como trabaj',
      'how we work',
      'how the company works',
    ])) {
      return AssistantPlan(
        markdown: _answers(facts.organization, _lists(facts), en),
        keepLocal: true,
      );
    }
    if (_has(query, [
      'qué es talexito',
      'que es talexito',
      'what is talexito',
      'qué puedes',
      'que puedes',
      'what can you',
      'quién eres',
      'quien eres',
      'who are you',
    ])) {
      return AssistantPlan(markdown: _about(en, facts: facts));
    }
    if (_has(query, [
      'vacante',
      'vacancy',
      'puesto',
      'candidato',
      'candidate',
      'resultado',
      'result',
      'reporte',
      'report',
      'afinidad',
      'affinity',
      'equipo',
      'team',
      'perfil',
      'profile',
      'invit',
      'invite',
      'configur',
      'setting',
      'panel',
      'proceso',
      'hiring',
    ])) {
      return AssistantPlan(markdown: _guide(query, facts, en));
    }
    return AssistantPlan(markdown: _outside(en));
  }

  static bool _asksWhere(String query) => _has(query, [
    'dónde',
    'donde',
    'where',
    'en qué menú',
    'en que menu',
    'en qué sección',
    'en que seccion',
  ]);

  static String _workspace(String question, WorkspaceFacts? facts, bool en) {
    final query = question.trim().toLowerCase();
    if (_has(query, ['afinidad', 'affinity'])) {
      return _affinityConcept(en);
    }
    if (_has(query, ['invit', 'invite'])) {
      return _invite(facts ?? const WorkspaceFacts(), en, company: false);
    }
    if (_has(query, ['resultado', 'result'])) {
      return _results(en, company: false);
    }
    if (facts != null &&
        facts.invitationCount != null &&
        _has(query, [
          'cuánt',
          'cuant',
          'how many',
          'estado',
          'status',
          'resumen',
        ])) {
      return _invitationSnapshot(facts, en);
    }
    return _outside(en);
  }

  static bool _has(String query, List<String> keys) => keys.any(query.contains);

  static String _name(WorkspaceFacts facts, bool en) =>
      facts.organization?.trim().isNotEmpty == true
      ? facts.organization!.trim()
      : (en ? 'your company' : 'tu empresa');

  static String _affinityConcept(bool en) {
    return en
        ? '## Affinity\n\n'
              'Affinity compares a person\'s survey with the vacancy. '
              'The survey is the same for every company. It supports the conversation and does not decide a hire.\n\n'
              'TaleXito receives the answers. A specialist shares the result later.'
        : '## Afinidad\n\n'
              'La afinidad compara la encuesta de una persona con la vacante. '
              'La encuesta es la misma para todas las empresas. Sirve para orientar la conversación y no decide una contratación.\n\n'
              'TaleXito recibe las respuestas. Una persona especializada comunica el resultado más adelante.';
  }

  static _Lists _lists(WorkspaceFacts facts) {
    final hasStored =
        facts.values.isNotEmpty ||
        facts.culture.isNotEmpty ||
        facts.standout.isNotEmpty;
    if (hasStored) {
      return _Lists(facts.values, facts.culture, facts.standout);
    }
    final summary = facts.dnaSummary?.trim();
    if (summary != null && summary.isNotEmpty) {
      return _Lists([summary], const [], const []);
    }
    return const _Lists([], [], []);
  }

  static String _answers(
    String? organization,
    _Lists lists,
    bool en, {
    bool changed = false,
  }) {
    final name = organization?.trim().isNotEmpty == true
        ? organization!.trim()
        : (en ? 'your company' : 'tu empresa');
    final buffer = StringBuffer();
    if (changed) {
      buffer
        ..writeln(en ? 'Done. The answer is updated.' : 'Listo. Ya quedó el cambio.')
        ..writeln();
    }
    buffer
      ..writeln(en ? '## Answers for $name' : '## Respuestas de $name')
      ..writeln();
    final groups = [
      (en ? 'Values' : 'Valores', lists.values),
      (en ? 'Culture' : 'Cultura', lists.culture),
      (en ? 'People' : 'Personal', lists.standout),
    ];
    final visible = groups.where((group) => group.$2.isNotEmpty).toList();
    if (visible.isEmpty) {
      buffer.writeln(
        en ? 'There are no saved answers yet.' : 'Todavía no hay respuestas guardadas.',
      );
    } else {
      for (final group in visible) {
        buffer.writeln('**${group.$1}**');
        for (final item in group.$2) {
          buffer.writeln('- $item');
        }
        buffer.writeln();
      }
    }
    buffer.write(en ? 'Do you want to change one?' : '¿Quieres cambiar alguna?');
    return buffer.toString().trim();
  }

  static _Change _change(String question, WorkspaceFacts facts) {
    final lists = _lists(facts);
    final values = [...lists.values];
    final culture = [...lists.culture];
    final standout = [...lists.standout];
    final change = _changePattern.firstMatch(question.trim());
    if (change != null) {
      final from = _clean(change.group(1) ?? '');
      final to = _clean(change.group(2) ?? '');
      if (from.isEmpty || to.isEmpty) return const _Change.notFound();
      final replaced =
          _swap(values, from, to) ||
          _swap(culture, from, to) ||
          _swap(standout, from, to);
      if (!replaced) return const _Change.notFound();
      return _Change.saved(values, culture, standout);
    }
    final removal = _removePattern.firstMatch(question.trim());
    if (removal != null) {
      final target = _clean(removal.group(1) ?? '');
      if (target.isEmpty) return const _Change.notFound();
      final removed =
          _drop(values, target) ||
          _drop(culture, target) ||
          _drop(standout, target);
      if (!removed) return const _Change.notFound();
      return _Change.saved(values, culture, standout);
    }
    final addition = _addPattern.firstMatch(question.trim());
    if (addition != null) {
      final text = _clean(addition.group(1) ?? '');
      final group = addition.group(2)?.trim().toLowerCase();
      if (text.isEmpty) return const _Change.notFound();
      if (group == null || group.isEmpty) return const _Change.missing();
      final bucket = switch (group) {
        'cultura' || 'culture' => culture,
        'personal' || 'destacados' || 'people' => standout,
        _ => values,
      };
      if (!bucket.any((item) => item.toLowerCase() == text.toLowerCase())) {
        bucket.add(text);
      }
      return _Change.saved(values, culture, standout);
    }
    return const _Change.none();
  }

  static final RegExp _changePattern = RegExp(
    r'(?:cambia|cambiar|reemplaza|reemplazar|change|replace)\s+(.+?)\s+(?:por|to|for)\s+(.+)$',
    caseSensitive: false,
  );
  static final RegExp _removePattern = RegExp(
    r'(?:quita|quitar|elimina|eliminar|borra|borrar|remove|delete)\s+(.+)$',
    caseSensitive: false,
  );
  static final RegExp _addPattern = RegExp(
    r'(?:agrega|agregar|añade|anade|add)\s+(.+?)(?:\s+(?:a|en|to)\s+(valores|cultura|personal|destacados|values|culture|people))?$',
    caseSensitive: false,
  );

  static String _clean(String raw) => raw
      .trim()
      .replaceAll(RegExp('''^["']+|["']+\$'''), '')
      .replaceAll(RegExp(r'[.?!]+$'), '')
      .trim();

  static bool _swap(List<String> items, String from, String to) {
    final index = items.indexWhere(
      (item) => item.toLowerCase() == from.toLowerCase(),
    );
    if (index < 0) return false;
    items[index] = to;
    return true;
  }

  static bool _drop(List<String> items, String target) {
    final index = items.indexWhere(
      (item) => item.toLowerCase() == target.toLowerCase(),
    );
    if (index < 0) return false;
    items.removeAt(index);
    return true;
  }

  static String _guide(String query, WorkspaceFacts facts, bool en) {
    final lines = <String>[];
    void add(bool match, String line) {
      if (match) lines.add(line);
    }

    add(
      _has(query, ['panel', 'proceso', 'hiring', 'cómo va', 'como va']),
      en
          ? '- **Dashboard**: the overview of the hiring process.'
          : '- **Panel principal**: el estado general del proceso.',
    );
    add(
      _has(query, ['vacante', 'vacancy', 'puesto']),
      en
          ? '- **Vacancy**: the roles, which ones are active, and their description.'
          : '- **Vacante**: los puestos, cuáles están activos y su descripción.',
    );
    add(
      _has(query, ['candidato', 'candidate', 'persona', 'people']),
      en
          ? '- **Candidate**: the people invited and the status of each evaluation.'
          : '- **Candidato**: las personas invitadas y el estado de cada evaluación.',
    );
    add(
      _has(query, ['resultado', 'result', 'reporte', 'report', 'afinidad', 'affinity']),
      en
          ? '- **Results**: the affinity report of a person who already finished. Open that person to read it. TaleXito does not write that analysis.'
          : '- **Resultados**: el reporte de afinidad de quien ya terminó. Ábrelo para leerlo. TaleXito no redacta ese análisis.',
    );
    add(
      _has(query, ['equipo', 'team']),
      en
          ? '- **Team**: the people who use the company workspace.'
          : '- **Equipo**: las personas que usan el espacio de la empresa.',
    );
    add(
      _has(query, ['perfil', 'profile', 'adn', 'dna', 'cultura', 'culture', 'valores', 'values']),
      en
          ? '- **Company profile**: the company data.'
          : '- **Perfil de empresa**: los datos de la empresa.',
    );
    add(
      _has(query, ['invit', 'invite']),
      en
          ? '- **Candidate**: invitations to an evaluation. I cannot send one from the chat.'
          : '- **Candidato**: las invitaciones a una evaluación. Desde el chat no envío ninguna.',
    );
    add(
      _has(query, ['configur', 'setting']),
      en
          ? '- **Settings**: the account and workspace preferences.'
          : '- **Configuración**: la cuenta y las preferencias del espacio.',
    );
    if (lines.isEmpty) {
      lines.add(
        en
            ? '- **Company profile** holds the company data. **Dashboard**, **Vacancy**, **Candidate**, and **Results** hold the rest of the workspace.'
            : '- **Perfil de empresa** guarda los datos de la empresa. **Panel principal**, **Vacante**, **Candidato** y **Resultados** guardan el resto del espacio.',
      );
    }
    final name = _name(facts, en);
    return [
      en ? '## Where to look in $name' : '## Dónde verlo en $name',
      '',
      en
          ? 'I can point you to the screen. From here I only change a saved answer.'
          : 'Puedo indicarte la pantalla. Desde aquí solo cambio una respuesta guardada.',
      '',
      ...lines,
    ].join('\n');
  }

  static String _outside(bool en) => en
      ? 'TaleXito shows the saved answers and changes one when you ask. That question is outside what I do.'
      : 'TaleXito muestra las respuestas guardadas y cambia una cuando se lo pides. Esa pregunta queda por fuera de lo que hago.';

  static String _invite(
    WorkspaceFacts facts,
    bool en, {
    required bool company,
  }) {
    final buffer = StringBuffer()
      ..writeln(en ? '## Invitations' : '## Invitaciones')
      ..writeln()
      ..writeln(
        company
            ? (en
                  ? 'From the company workspace you can invite a person to a vacancy. I cannot send that invitation from the chat.'
                  : 'Desde el espacio de la empresa puedes invitar a una persona a una vacante. Desde el chat no envío esa invitación.')
            : (en
                  ? 'In this workspace you can create an invitation from the roles section. I cannot send it from the chat.'
                  : 'En este espacio puedes crear una invitación desde la sección de roles. Desde el chat no la envío.'),
      );
    if (facts.invitationCount != null) {
      buffer
        ..writeln()
        ..writeln(
          en
              ? 'Recorded invitations: **${facts.invitationCount}**. Pending or in progress: **${facts.pendingInvitations ?? 0}**.'
              : 'Invitaciones registradas: **${facts.invitationCount}**. Pendientes o en curso: **${facts.pendingInvitations ?? 0}**.',
        );
    }
    return buffer.toString().trim();
  }

  static String _results(bool en, {required bool company}) {
    return company
        ? (en
              ? '## Results\n\nOpen a person who already finished the evaluation to read the affinity report. If the analysis has not run, the report will say so. I will not mark it as ready before that.'
              : '## Resultados\n\nAbre a una persona que ya terminó la evaluación para leer el reporte de afinidad. Si el análisis no se ha ejecutado, el reporte lo indica. No lo marcaré como listo antes de eso.')
        : (en
              ? '## Results\n\nResults appear in the company workspace after someone completes an evaluation and the affinity analysis runs. This workspace does not have that report yet.'
              : '## Resultados\n\nLos resultados aparecen en el espacio de la empresa cuando alguien completa la evaluación y se ejecuta el análisis de afinidad. Este espacio todavía no tiene ese reporte.');
  }

  static String _about(bool en, {WorkspaceFacts? facts}) {
    final buffer = StringBuffer()
      ..writeln(en ? '## What I can see' : '## Lo que puedo ver')
      ..writeln()
      ..writeln(
        en
            ? 'I am TaleXito. I show the saved answers and change one when you ask.'
            : 'Soy TaleXito. Muestro las respuestas guardadas y cambio una cuando me lo pides.',
      )
      ..writeln()
      ..writeln(en ? 'I can help you with:' : 'Puedo ayudarte con:')
      ..writeln()
      ..writeln(
        en ? '- The answers already saved' : '- Las respuestas que ya están guardadas',
      )
      ..writeln(
        en
            ? '- Changing one of those answers'
            : '- Cambiar una de esas respuestas',
      );
    if (facts != null && facts.organization != null) {
      buffer
        ..writeln()
        ..writeln(
          en
              ? 'Right now I am looking at **${facts.organization}**.'
              : 'Ahora mismo estoy mirando **${facts.organization}**.',
        );
    }
    return buffer.toString().trim();
  }

  static String _invitationSnapshot(WorkspaceFacts facts, bool en) {
    return en
        ? '## Invitations\n\nThere are **${facts.invitationCount}** invitations in this workspace. **${facts.pendingInvitations ?? 0}** are pending or in progress.\n\nI did not send or cancel any of them.'
        : '## Invitaciones\n\nHay **${facts.invitationCount}** invitaciones en este espacio. **${facts.pendingInvitations ?? 0}** están pendientes o en curso.\n\nNo envié ni cancelé ninguna.';
  }

}

class _Lists {
  const _Lists(this.values, this.culture, this.standout);

  final List<String> values;
  final List<String> culture;
  final List<String> standout;
}

class _Change {
  const _Change.none() : edit = null, notFound = false, attempted = false;

  const _Change.notFound() : edit = null, notFound = true, attempted = true;

  const _Change.missing() : edit = null, notFound = false, attempted = true;

  _Change.saved(List<String> values, List<String> culture, List<String> standout)
    : edit = CompanyAnswerEdit(
        values: values,
        culture: culture,
        standout: standout,
      ),
      notFound = false,
      attempted = true;

  final CompanyAnswerEdit? edit;
  final bool notFound;
  final bool attempted;
}
