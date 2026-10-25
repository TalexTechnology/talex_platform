import 'package:flutter/widgets.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_brief.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_reply.dart';

/// Copy for the assistant surface.
///
/// The composer and the command center already choose Spanish or English from
/// the active locale, so this surface follows that same choice instead of
/// growing a second localization pipeline.
class AssistantText {
  const AssistantText(this.english);

  factory AssistantText.of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return AssistantText(code.toLowerCase().startsWith('en'));
  }

  final bool english;

  String get name => 'TaleXito';
  String get openLabel => english ? 'Open TaleXito' : 'Abrir TaleXito';
  String get closeLabel => english ? 'Close' : 'Cerrar';
  String get newConversation =>
      english ? 'New conversation' : 'Nueva conversación';
  String get available => english ? 'Available' : 'Disponible';
  String get consulting => english ? 'Looking it up' : 'Consultando';
  String get writing => english ? 'Writing' : 'Escribiendo';
  String get welcomeTitle =>
      english ? 'Hello, I am TaleXito' : 'Hola, soy TaleXito';
  String get welcomeBody => english
      ? 'I show the answers already saved. If you want to change one, tell me which and I will change it. I do not explain them.'
      : 'Te muestro las respuestas que ya están guardadas. Si quieres cambiar alguna, dime cuál y la cambio. No las explico.';
  String get placeholder => english
      ? 'Ask to see or change a saved answer'
      : 'Pide ver o cambiar una respuesta guardada';
  String get send => english ? 'Send' : 'Enviar';
  String get stop => english ? 'Stop' : 'Detener';
  String get retry => english ? 'Try again' : 'Reintentar';
  String get cancelled => english ? 'Response stopped' : 'Respuesta detenida';
  String get enterHint => english
      ? 'Enter to send · Shift + Enter for a new line'
      : 'Enter para enviar · Shift + Enter para un salto de línea';
  String get emptyThread => english
      ? 'Ask for the saved answers, or tell me which one you want to change.'
      : 'Pide las respuestas guardadas o dime cuál quieres cambiar.';

  List<String> suggestions(AssistantAudience audience) => switch (audience) {
    AssistantAudience.admin =>
      english
          ? const [
              'How is TaleX?',
              'Which companies are at risk?',
              'What commercial opportunities are open?',
              'What needs attention?',
            ]
          : const [
              '¿Cómo está TaleX?',
              '¿Qué empresas están en riesgo?',
              '¿Qué oportunidades comerciales hay?',
              '¿Qué requiere atención?',
            ],
    AssistantAudience.company =>
      english
          ? const [
              'Show me the saved answers',
              'I want to change an answer',
              'Where is the affinity report?',
              'Where is the team?',
            ]
          : const [
              'Muéstrame las respuestas',
              'Quiero cambiar una respuesta',
              '¿Dónde está el reporte de afinidad?',
              '¿Dónde está el equipo?',
            ],
    AssistantAudience.workspace =>
      english
          ? const [
              'What is TaleX?',
              'How do invitations work?',
              'What is affinity?',
              'What results can I see?',
            ]
          : const [
              '¿Qué es TaleX?',
              '¿Cómo funcionan las invitaciones?',
              '¿Qué es la afinidad?',
              '¿Qué resultados puedo ver?',
            ],
  };

  String failure(AssistantFailureKind kind) => switch (kind) {
    AssistantFailureKind.timeout =>
      english
          ? 'That took too long. The workspace data is still here; try again.'
          : 'La consulta tardó demasiado. Los datos siguen aquí; inténtalo de nuevo.',
    AssistantFailureKind.unavailable =>
      english
          ? 'I could not read the workspace data just now.'
          : 'No pude leer los datos del espacio en este momento.',
    AssistantFailureKind.empty =>
      english
          ? 'I did not receive a useful answer. Try another question.'
          : 'No recibí una respuesta útil. Prueba con otra pregunta.',
    AssistantFailureKind.unexpected =>
      english
          ? 'I could not complete that answer.'
          : 'No pude completar esa respuesta.',
  };
}
