import 'package:flutter/material.dart';
import 'package:talex_platform/features/culture/data/culture_survey_api.dart';

class CompanyCultureSurveyPage extends StatefulWidget {
  const CompanyCultureSurveyPage({super.key, required this.organizationId});

  static const routeName = '/cultura';

  final String organizationId;

  @override
  State<CompanyCultureSurveyPage> createState() =>
      _CompanyCultureSurveyPageState();
}

class _CompanyCultureSurveyPageState extends State<CompanyCultureSurveyPage> {
  final _api = CultureSurveyApi();
  Map<String, dynamic>? _survey;
  Object? _error;
  var _index = 0;
  var _submitting = false;
  var _done = false;
  final _answers = <String, Map<String, dynamic>>{};
  final _text = TextEditingController();

  List<Map<String, dynamic>> get _questions {
    final rows = _survey?['questions'];
    if (rows is! List) return const [];
    return [
      for (final row in rows)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }

  Map<String, dynamic>? get _current =>
      _index < _questions.length ? _questions[_index] : null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final survey = await _api.load(widget.organizationId);
      if (!mounted) return;
      setState(() => _survey = survey);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  Future<void> _next() async {
    final question = _current;
    if (question == null) return;
    final id = '${question['id']}';
    final format = '${question['format']}';
    final required = question['required'] != false;
    if (format == 'text') {
      final value = _text.text.trim();
      if (required && value.isEmpty) return;
      _answers[id] = {'value_text': value};
    } else if (required && _answers[id] == null) {
      return;
    }
    if (_index < _questions.length - 1) {
      setState(() {
        _index += 1;
        _text.text = '${_answers['${_questions[_index]['id']}']?['value_text'] ?? ''}';
      });
      return;
    }
    setState(() => _submitting = true);
    try {
      await _api.submit(widget.organizationId, _answers);
      if (!mounted) return;
      setState(() => _done = true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF17202A);
    const cream = Color(0xFFF3EFE6);
    const gold = Color(0xFF8A6A32);
    return Scaffold(
      backgroundColor: cream,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 80),
            children: [
              const Text(
                'TALEX · DIAGNÓSTICO CULTURAL',
                style: TextStyle(
                  letterSpacing: 2.2,
                  fontSize: 12,
                  color: Color(0xFF7A715F),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),
              if (_error != null)
                _Message(
                  title: 'No pudimos abrir el diagnóstico',
                  body: _error.toString(),
                )
              else if (_survey == null)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_done)
                const _Message(
                  title: 'Gracias por su tiempo',
                  body:
                      'Sus respuestas ya quedan en el diagnóstico de la organización. Puede cerrar esta página.',
                )
              else if (_questions.isEmpty)
                const _Message(
                  title: 'El diagnóstico aún no está publicado',
                  body:
                      'El equipo TaleX está cargando las preguntas. Vuelva a este enlace en un momento.',
                )
              else ...[
                Text(
                  '${_survey?['intro'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.55,
                    color: Color(0xFF3D4550),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${_index + 1} / ${_questions.length}',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 20),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE4DDD0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: _QuestionBody(
                      question: _current!,
                      selected: _answers['${_current!['id']}']?['value_int'] as int?,
                      controller: _text,
                      ink: ink,
                      gold: gold,
                      onSelect: (value) {
                        setState(() {
                          _answers['${_current!['id']}'] = {'value_int': value};
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: _index == 0 || _submitting
                          ? null
                          : () {
                              setState(() {
                                _index -= 1;
                                _text.text =
                                    '${_answers['${_questions[_index]['id']}']?['value_text'] ?? ''}';
                              });
                            },
                      child: const Text('Anterior'),
                    ),
                    const Spacer(),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF102033),
                        foregroundColor: const Color(0xFFF7F2E8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                      ),
                      onPressed: _submitting ? null : _next,
                      child: Text(
                        _index == _questions.length - 1
                            ? 'Enviar respuestas'
                            : 'Continuar',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionBody extends StatelessWidget {
  const _QuestionBody({
    required this.question,
    required this.selected,
    required this.controller,
    required this.onSelect,
    required this.ink,
    required this.gold,
  });

  final Map<String, dynamic> question;
  final int? selected;
  final TextEditingController controller;
  final ValueChanged<int> onSelect;
  final Color ink;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    final options = question['options'] is List
        ? [for (final item in question['options'] as List) '$item']
        : const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${question['sectionTitle'] ?? ''}'.toUpperCase(),
          style: TextStyle(
            color: gold,
            letterSpacing: 1.6,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${question['statement'] ?? ''}',
          style: TextStyle(
            color: ink,
            fontSize: 26,
            height: 1.3,
            fontWeight: FontWeight.w500,
          ),
        ),
        if ('${question['instruction'] ?? ''}'.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            '${question['instruction']}',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
        const SizedBox(height: 20),
        if ('${question['format']}' == 'text')
          TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFFFBFAF6),
              border: OutlineInputBorder(),
            ),
          )
        else
          for (final (index, label) in options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RadioListTile<int>(
                value: index + 1,
                groupValue: selected,
                onChanged: (value) {
                  if (value != null) onSelect(value);
                },
                title: Text(label),
                tileColor: const Color(0xFFFBFAF6),
              ),
            ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4DDD0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: const TextStyle(
                fontSize: 18,
                height: 1.5,
                color: Color(0xFF3D4550),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
