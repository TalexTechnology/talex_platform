import 'package:talex_platform/features/admin/domain/entities/admin_entities.dart';
import 'package:talex_platform/features/admin/domain/services/xebec_interpreter.dart';

/// Presents the existing command-center interpreter as readable Markdown.
abstract final class CommandCenterAnswerer {
  static String present({
    required String question,
    required String locale,
    required AdminMetrics metrics,
    required List<Company> companies,
    required List<Deal> deals,
    required List<ActivityEvent> activity,
    required List<AdminAlert> alerts,
    DateTime? now,
  }) {
    final en = locale.toLowerCase().startsWith('en');
    final body = XebecInterpreter.answer(
      question: question,
      metrics: metrics,
      companies: companies,
      deals: deals,
      activity: activity,
      alerts: alerts,
      now: now,
      locale: locale,
    ).trim();
    final heading = en ? 'Command center' : 'Centro de mando';
    return '**$heading**\n\n$body';
  }
}
