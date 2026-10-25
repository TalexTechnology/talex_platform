import 'package:talex_platform/features/admin/domain/entities/admin_entities.dart';

abstract final class XebecInterpreter {
  static String answer({
    required String question,
    required AdminMetrics metrics,
    required List<Company> companies,
    required List<Deal> deals,
    required List<ActivityEvent> activity,
    required List<AdminAlert> alerts,
    DateTime? now,
    String locale = 'es',
  }) {
    final en = locale.toLowerCase().startsWith('en');
    final query = question.trim().toLowerCase();
    if (query.isEmpty) {
      return en
          ? 'Ask me about TaleX health, companies at risk, or opportunities.'
          : 'Pregúntame por el estado de TaleX, empresas en riesgo u oportunidades.';
    }
    final clock = now ?? DateTime.now();
    if (_matches(query, [
      'cómo está',
      'como esta',
      'estado',
      'resumen',
      'how is',
      'overview',
      'summary',
      'status',
    ])) {
      return _overview(metrics, alerts, en);
    }
    if (_matches(query, [
      'atención',
      'atencion',
      'requieren',
      'prioriz',
      'attention',
      'priority',
    ])) {
      return _attention(alerts, en);
    }
    if (_matches(query, [
      'más activa',
      'mas activa',
      'activa',
      'most active',
      'busiest',
    ])) {
      return _mostActive(companies, en);
    }
    if (_matches(query, [
      'evaluaciones',
      'semana',
      'complet',
      'evaluation',
    ])) {
      return en
          ? '${metrics.completedEvaluations} evaluations were completed in the visible period. '
                '${metrics.affinitiesDetected} affinities were detected.'
          : 'Se completaron ${metrics.completedEvaluations} evaluaciones en el periodo visible. '
                'Las afinidades detectadas son ${metrics.affinitiesDetected}.';
    }
    if (_matches(query, ['riesgo', 'inactiv', 'risk'])) {
      return _risk(companies, clock, en);
    }
    if (_matches(query, [
      'oportun',
      'pipeline',
      'comercial',
      'opportunity',
      'commercial',
    ])) {
      return _pipeline(deals, en);
    }
    if (_matches(query, ['expandir', 'expansión', 'expansion', 'expand'])) {
      final expansion = alerts.where(
        (item) => item.type == AlertType.opportunity,
      );
      if (expansion.isEmpty) {
        return en
            ? 'There are no expansion signals calculated from the current activity.'
            : 'Aún no hay señales de expansión calculadas con la actividad actual.';
      }
      return expansion.map((item) => item.description).join(' ');
    }
    if (_matches(query, ['hoy', 'ocurrió', 'ocurrio', 'today'])) {
      return _today(activity, clock, en);
    }
    if (_matches(query, ['vend', 'mrr', 'ingreso', 'sales', 'revenue'])) {
      return en
          ? 'Period sales: ${_money(metrics.periodSales)}. '
                'Recorded recurring MRR: ${_money(metrics.mrr)}. '
                'Total companies: ${metrics.totalCompanies}.'
          : 'Ventas del periodo: ${_money(metrics.periodSales)}. '
                'MRR recurrente registrado: ${_money(metrics.mrr)}. '
                'Empresas totales: ${metrics.totalCompanies}.';
    }
    return _overview(metrics, alerts, en);
  }

  static bool _matches(String query, List<String> keys) =>
      keys.any(query.contains);

  static String _overview(
    AdminMetrics metrics,
    List<AdminAlert> alerts,
    bool en,
  ) {
    if (metrics.totalCompanies == 0) {
      return en
          ? 'TaleX does not have any companies in the command center yet. '
                'When companies, processes, and evaluations exist, I can summarize the real status.'
          : 'TaleX todavía no tiene empresas registradas en el centro de mando. '
                'Cuando existan compañías, procesos y evaluaciones, podré resumir el estado real.';
    }
    final attention = alerts.where(
      (item) => item.priority == AlertPriority.high,
    );
    final attentionText = attention.isEmpty
        ? (en
              ? 'There are no high-priority alerts.'
              : 'No hay alertas de alta prioridad.')
        : (en
              ? 'There are ${attention.length} high-priority alerts.'
              : 'Hay ${attention.length} alertas de alta prioridad.');
    return en
        ? 'TaleX has ${metrics.totalCompanies} companies '
              '(${metrics.activeCompanies} active). '
              '${metrics.evaluatedPeople} people were evaluated and '
              '${metrics.completedEvaluations} evaluations are completed. '
              '$attentionText'
        : 'TaleX tiene ${metrics.totalCompanies} empresas '
              '(${metrics.activeCompanies} activas). '
              '${metrics.evaluatedPeople} personas fueron evaluadas y '
              '${metrics.completedEvaluations} evaluaciones están completadas. '
              '$attentionText';
  }

  static String _attention(List<AdminAlert> alerts, bool en) {
    if (alerts.isEmpty) {
      return en
          ? 'No companies need attention according to the recorded activity.'
          : 'No hay empresas que requieran atención según la actividad registrada.';
    }
    final names = alerts.take(3).map((item) => item.title).join(', ');
    return en ? 'Prioritize: $names.' : 'Prioriza: $names.';
  }

  static String _mostActive(List<Company> companies, bool en) {
    if (companies.isEmpty) {
      return en
          ? 'There are no companies to compare yet.'
          : 'Todavía no hay empresas para comparar actividad.';
    }
    final ranked = [...companies]..sort(
      (a, b) => b.completedEvaluations.compareTo(a.completedEvaluations),
    );
    final top = ranked.first;
    if (top.completedEvaluations == 0) {
      return en
          ? 'No company has completed evaluations yet.'
          : 'Ninguna empresa tiene evaluaciones completadas todavía.';
    }
    return en
        ? 'The most active company by completed evaluations is ${top.name} '
              '(${top.completedEvaluations}).'
        : 'La empresa más activa por evaluaciones completadas es ${top.name} '
              '(${top.completedEvaluations}).';
  }

  static String _risk(List<Company> companies, DateTime clock, bool en) {
    final risky = companies.where((company) {
      final last = company.lastActivityAt ?? company.createdAt;
      return company.status == CompanyStatus.atRisk ||
          clock.difference(last).inDays >= 14;
    }).toList();
    if (risky.isEmpty) {
      return en
          ? 'No clients are at risk under the current inactivity criteria.'
          : 'No hay clientes en riesgo con los criterios actuales de inactividad.';
    }
    final names = risky.map((item) => item.name).join(', ');
    return en ? 'At risk: $names.' : 'En riesgo: $names.';
  }

  static String _pipeline(List<Deal> deals, bool en) {
    final open = deals.where((deal) => deal.stage != DealStage.client).toList();
    if (open.isEmpty) {
      return en
          ? 'There are no open opportunities in the pipeline.'
          : 'No hay oportunidades abiertas en el pipeline.';
    }
    final value = open.fold<double>(
      0,
      (acc, deal) => acc + (deal.estimatedValue ?? 0),
    );
    if (en) {
      return 'There are ${open.length} open opportunities'
          '${value <= 0 ? '.' : ' worth an estimated ${_money(value)}.'}';
    }
    return 'Hay ${open.length} oportunidades abiertas'
        '${value <= 0 ? '.' : ' por ${_money(value)} estimados.'}';
  }

  static String _today(List<ActivityEvent> activity, DateTime clock, bool en) {
    final today = activity.where(
      (item) =>
          item.createdAt.year == clock.year &&
          item.createdAt.month == clock.month &&
          item.createdAt.day == clock.day,
    );
    if (today.isEmpty) {
      return en
          ? 'There is no activity recorded today yet.'
          : 'Hoy no hay actividad registrada todavía.';
    }
    final names = today.map((item) => item.entityName).take(5).join(', ');
    return en ? 'Today: $names.' : 'Hoy: $names.';
  }

  static String _money(double value) => '\$${value.toStringAsFixed(0)}';
}
