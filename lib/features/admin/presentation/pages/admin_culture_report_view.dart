import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/core/services/pdf_saver.dart';
import 'package:talex_platform/core/widgets/skeleton.dart';
import 'package:talex_platform/core/widgets/talex_ui.dart';
import 'package:talex_platform/features/admin/data/datasources/culture_report_data_source.dart';
import 'package:talex_platform/features/admin/domain/entities/culture_report.dart';
import 'package:talex_platform/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:talex_platform/l10n/l10n.dart';

// Informe de cultura de una empresa, ya analizado por el backend
// (/api/cultura/{id}/informe). Esta vista lo presenta con la voz de TaleX:
// frases cortas, de tú, sin jerga estadística. Los puntajes se leen en
// palabras ("se vive mucho", "lo ven distinto") y los textos técnicos del
// backend se limpian con [plainReportText].
class AdminCultureReportView extends StatefulWidget {
  const AdminCultureReportView({
    super.key,
    required this.organizationId,
    required this.organizationName,
    required this.source,
    required this.onBack,
  });

  final String organizationId;
  final String organizationName;
  final CultureReportDataSource source;
  final VoidCallback onBack;

  @override
  State<AdminCultureReportView> createState() => _AdminCultureReportViewState();
}

class _AdminCultureReportViewState extends State<AdminCultureReportView> {
  late Future<CultureReport> _report = widget.source.report(
    widget.organizationId,
  );

  var _downloading = false;

  void _reload() => setState(() {
    _report = widget.source.report(widget.organizationId);
  });

  Future<void> _downloadPdf() async {
    final l10n = context.l10n;
    final notifications = getIt<NotificationService>();
    setState(() => _downloading = true);
    try {
      final pdf = await widget.source.reportPdf(widget.organizationId);
      savePdfBytes(pdf.bytes, pdf.filename ?? _fallbackFilename());
      notifications.success(l10n.cultureReportDownloaded);
    } catch (_) {
      notifications.error(l10n.cultureReportDownloadError);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  // Si el servidor no expone su nombre de archivo: informe-cultura-<empresa>-<fecha>.pdf
  String _fallbackFilename() {
    final slug = widget.organizationName
        .toLowerCase()
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final date = DateTime.now().toIso8601String().substring(0, 10);
    return 'informe-cultura-${slug.isEmpty ? 'empresa' : slug}-$date.pdf';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < 720;
    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 18 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(l10n.cultureReportBack),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<CultureReport>(
            future: _report,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdminPageHeader(
                      eyebrow: l10n.cultureReportTitle,
                      title: widget.organizationName,
                      subtitle: '',
                    ),
                    const SizedBox(height: 24),
                    const Skeleton(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SkeletonStats(),
                          SizedBox(height: 20),
                          SkeletonList(count: 4, separate: true),
                        ],
                      ),
                    ),
                  ],
                );
              }
              final report = snapshot.data;
              if (snapshot.hasError || report == null) {
                return AdminErrorState(
                  message: l10n.cultureReportError,
                  onRetry: _reload,
                );
              }
              return CultureReportBody(
                report: report,
                fallbackName: widget.organizationName,
                actions: [
                  if (report.hasReport)
                    FilledButton.icon(
                      onPressed: _downloading ? null : _downloadPdf,
                      icon: _downloading
                          ? SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textDimmer,
                              ),
                            )
                          : const Icon(Icons.download_outlined, size: 18),
                      label: Text(
                        _downloading
                            ? l10n.cultureReportDownloading
                            : l10n.cultureReportDownloadPdf,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class CultureReportBody extends StatelessWidget {
  const CultureReportBody({
    super.key,
    required this.report,
    required this.fallbackName,
    this.actions = const [],
  });

  final CultureReport report;
  final String fallbackName;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = report.organizationName.isEmpty
        ? fallbackName
        : report.organizationName;
    final header = AdminPageHeader(
      eyebrow: l10n.cultureReportTitle,
      title: name,
      subtitle: l10n.cultureReportIntro,
      actions: actions,
    );
    if (!report.hasReport) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 24),
          _CoverageRow(report: report),
          const SizedBox(height: 16),
          AdminEmptyState(
            message: l10n.cultureReportPending,
            icon: Icons.hourglass_empty,
          ),
        ],
      );
    }
    const gap = SizedBox(height: 16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 24),
        _Executive(report: report),
        gap,
        _CoverageRow(report: report),
        gap,
        if (report.sections.isNotEmpty) ...[_Sections(report: report), gap],
        _Dna(report: report),
        gap,
        _Mirror(report: report),
        gap,
        _SaidVsDone(report: report),
        gap,
        _Offer(report: report),
        gap,
        _Voice(report: report),
        gap,
        _Hiring(report: report),
        gap,
        if (report.recommendations.isNotEmpty) ...[
          _Recommendations(report: report),
          gap,
        ],
        // Sello TaleX desactivado por ahora; descomentar para mostrarlo.
        // _Seal(report: report),
        // gap,
        _Quality(report: report),
      ],
    );
  }
}

// ── Traducción de datos a palabras ─────────────────────────────────────────

// Sello TaleX desactivado por ahora; descomentar para mostrarlo.
// bool _sealValidated(String status) =>
// status == 'validada' || status == 'validado';

// String _sealLabel(BuildContext context, String status) => _sealValidated(status)
// ? context.l10n.cultureReportSealValidated
// : context.l10n.cultureReportSealInProgress;

// TalexTone _sealTone(String status) =>
// _sealValidated(status) ? TalexTone.green : TalexTone.blue;

(String, TalexTone) _confidence(BuildContext context, String level) {
  final l10n = context.l10n;
  return switch (level) {
    'alto' || 'alta' => (l10n.cultureReportConfidenceHigh, TalexTone.green),
    'medio' || 'media' => (l10n.cultureReportConfidenceMedium, TalexTone.blue),
    _ => (l10n.cultureReportConfidenceLow, TalexTone.neutral),
  };
}

/// Puntaje de -1 a 1 en palabras.
String _levelWords(BuildContext context, double value) {
  final l10n = context.l10n;
  if (value >= 0.3) return l10n.cultureReportLevelHigh;
  if (value >= 0.1) return l10n.cultureReportLevelMid;
  if (value > -0.1) return l10n.cultureReportLevelNeutral;
  if (value > -0.3) return l10n.cultureReportLevelLow;
  return l10n.cultureReportLevelVeryLow;
}

/// Qué tan distinto lo ven líderes y equipo.
(String, TalexTone) _gapWords(BuildContext context, String status) {
  final l10n = context.l10n;
  return switch (status) {
    'alineado' || 'alineada' => (l10n.cultureReportAgree, TalexTone.green),
    'critica' ||
    'crítica' ||
    'alta' => (l10n.cultureReportDifferMuch, TalexTone.warning),
    _ => (l10n.cultureReportDiffer, TalexTone.blue),
  };
}

(String, TalexTone) _verdictWords(BuildContext context, String verdict) {
  final l10n = context.l10n;
  return switch (verdict) {
    'se_vive' => (l10n.cultureReportVerdictLived, TalexTone.green),
    'a_medias' => (l10n.cultureReportVerdictPartial, TalexTone.blue),
    _ => (l10n.cultureReportVerdictWall, TalexTone.warning),
  };
}

// Sello TaleX desactivado por ahora; descomentar para mostrarlo.
// String _conditionWords(BuildContext context, String code) => switch (code) {
// 'alineacion_lideres_empleados' =>
// context.l10n.cultureReportConditionAlignment,
// _ => humanizeReportCode(plainReportText(code)),
// };

// ── Piezas comunes ─────────────────────────────────────────────────────────

class _Block extends StatelessWidget {
  const _Block({
    required this.title,
    required this.children,
    this.help,
    this.trailing,
  });

  final String title;
  final String? help;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => TalexPanel(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TalexSectionTitle(title, trailing: trailing),
        if (help != null) ...[
          const SizedBox(height: 6),
          Text(
            help!,
            style: TextStyle(
              color: AppColors.textDimmer,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 20),
        ...children,
      ],
    ),
  );
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text, {this.strong = false});
  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) => Text(
    plainReportText(text),
    style: TextStyle(
      color: strong ? AppColors.text : AppColors.textMuted,
      fontSize: strong ? 16 : 14.5,
      height: 1.65,
      fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TalexEyebrow(text, color: AppColors.textDimmer),
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text, {this.icon, this.color});
  final String text;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(
            icon ?? Icons.circle,
            size: icon == null ? 6 : 16,
            color: color ?? AppColors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _Paragraph(text)),
      ],
    ),
  );
}

/// Indicador 0–100 con barra y, debajo, qué significa.
class _Score extends StatelessWidget {
  const _Score({required this.label, required this.value, this.caption});

  final String label;
  final int value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final color = value >= 70
        ? AppColors.good
        : value >= 50
        ? AppColors.blue
        : AppColors.warning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
              ),
            ),
            Text(
              '$value%',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            minHeight: 6,
            color: color,
            backgroundColor: AppColors.surface2,
          ),
        ),
        if (caption != null && caption!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            plainReportText(caption!),
            style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
          ),
        ],
      ],
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.icon,
    required this.tone,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final TalexTone tone;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: tone.background,
      borderRadius: AppRadii.border,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: tone.color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: tone.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              _Paragraph(text, strong: true),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PillGroup extends StatelessWidget {
  const _PillGroup({
    required this.label,
    required this.values,
    required this.tone,
    this.icon,
  });

  final String label;
  final List<String> values;
  final TalexTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      _Label(label),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final value in values) TalexPill(value, tone: tone, icon: icon),
        ],
      ),
    ],
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
    ],
  );
}

// ── Bloques ────────────────────────────────────────────────────────────────

class _Executive extends StatelessWidget {
  const _Executive({required this.report});
  final CultureReport report;

  /// Lo más importante, redactado desde los datos y no desde las frases
  /// técnicas del backend (que se usan solo si faltan datos).
  List<String> _keyPoints(BuildContext context) {
    final l10n = context.l10n;
    final points = <String>[
      if (report.dominantValues.isNotEmpty)
        l10n.cultureReportPointLived(report.dominantValues.join(' y ')),
      if (report.mirrorValues.isNotEmpty)
        l10n.cultureReportPointAlignment(report.alignment),
      if (report.cultureStrengthLevel.isNotEmpty) _strength(context),
      // Sello TaleX desactivado por ahora; descomentar para mostrarlo.
      // if (!_sealValidated(report.sealStatus) &&
      // report.requiredSample > 0 &&
      // report.employeeAnswers < report.requiredSample)
      // l10n.cultureReportPointSample(
      // report.employeeAnswers,
      // report.requiredSample,
      // ),
    ];
    return points.isEmpty ? report.keyPoints : points;
  }

  String _strength(BuildContext context) {
    final l10n = context.l10n;
    return switch (report.cultureStrengthLevel) {
      'fuerte' || 'alta' || 'cohesionada' => l10n.cultureReportStrengthStrong,
      'moderada' || 'media' => l10n.cultureReportStrengthMedium,
      _ => l10n.cultureReportStrengthWeak,
    };
  }

  /// El punto para conversar: la mayor diferencia entre líderes y equipo,
  /// contada en palabras.
  String? _talkingPoint(BuildContext context) {
    final values = [
      for (final value in report.mirrorValues)
        if (value.status != 'alineado') value,
    ]..sort((a, b) => b.gap.abs().compareTo(a.gap.abs()));
    if (values.isEmpty) {
      final truth = report.uncomfortableTruth;
      return truth == null ? null : plainReportText(truth);
    }
    final top = values.first;
    return top.gap > 0
        ? context.l10n.cultureReportGapLeadersMore(top.value)
        : context.l10n.cultureReportGapTeamMore(top.value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (confidence, confidenceTone) = _confidence(
      context,
      report.confidence,
    );
    final talkingPoint = _talkingPoint(context);
    return TalexPanel(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Sello TaleX desactivado por ahora; descomentar para mostrarlo.
              // TalexPill(
              // _sealLabel(context, report.sealStatus),
              // tone: _sealTone(report.sealStatus),
              // icon: Icons.verified_outlined,
              // ),
              if (report.confidence.isNotEmpty)
                TalexPill(confidence, tone: confidenceTone),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            plainReportText(report.headline),
            style: TextStyle(
              color: AppColors.text,
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 24),
          _Label(l10n.cultureReportKeyPoints),
          for (final point in _keyPoints(context)) _Bullet(point),
          if (talkingPoint != null) ...[
            const SizedBox(height: 12),
            _Callout(
              icon: Icons.forum_outlined,
              tone: TalexTone.blue,
              title: l10n.cultureReportTruth,
              text: talkingPoint,
            ),
          ],
        ],
      ),
    );
  }
}

class _CoverageRow extends StatelessWidget {
  const _CoverageRow({required this.report});
  final CultureReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final coverage = report.coverage;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        TalexStat(
          label: l10n.cultureReportRespondentsOf(
            coverage.respondents,
            coverage.needed,
          ),
          value: '${coverage.percent.round()}%',
          icon: coverage.reached ? Icons.check : Icons.hourglass_bottom,
          tone: coverage.reached ? TalexTone.green : TalexTone.blue,
          width: 220,
        ),
        if (report.hasReport) ...[
          TalexStat(
            label: l10n.cultureResponsesLeaders,
            value: '${report.leaderAnswers}',
            icon: Icons.workspace_premium_outlined,
            tone: TalexTone.neutral,
            width: 220,
          ),
          TalexStat(
            label: l10n.cultureResponsesEmployees,
            value: '${report.employeeAnswers}',
            icon: Icons.badge_outlined,
            tone: TalexTone.neutral,
            width: 220,
          ),
        ],
      ],
    );
  }
}

class _Sections extends StatelessWidget {
  const _Sections({required this.report});
  final CultureReport report;

  @override
  Widget build(BuildContext context) => _Block(
    title: context.l10n.cultureReportSummary,
    children: [
      for (final (index, (title, summary)) in report.sections.indexed) ...[
        if (index > 0) const TalexDivider(height: 28),
        Text(
          title,
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        _Paragraph(summary),
      ],
    ],
  );
}

class _Dna extends StatelessWidget {
  const _Dna({required this.report});
  final CultureReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final strength = switch (report.cultureStrengthLevel) {
      'fuerte' || 'alta' || 'cohesionada' => l10n.cultureReportStrengthStrong,
      'moderada' || 'media' => l10n.cultureReportStrengthMedium,
      _ => l10n.cultureReportStrengthWeak,
    };
    return _Block(
      title: l10n.cultureReportDna,
      help: l10n.cultureReportDnaHelp,
      children: [
        if (report.archetype.isNotEmpty) ...[
          Text(
            report.archetype,
            style: TextStyle(
              color: AppColors.green,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
        ],
        _Paragraph(report.dnaDescription),
        const SizedBox(height: 20),
        Wrap(
          spacing: 32,
          runSpacing: 20,
          children: [
            _PillGroup(
              label: l10n.cultureReportDominant,
              values: report.dominantValues,
              tone: TalexTone.green,
              icon: Icons.check,
            ),
            _PillGroup(
              label: l10n.cultureReportWeak,
              values: report.weakValues,
              tone: TalexTone.neutral,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _Score(
          label: l10n.cultureReportStrength,
          value: report.cultureStrength,
          caption: strength,
        ),
      ],
    );
  }
}

class _Mirror extends StatelessWidget {
  const _Mirror({required this.report});
  final CultureReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Block(
      title: l10n.cultureReportMirror,
      help: l10n.cultureReportMirrorHelp,
      children: [
        _Score(
          label: l10n.cultureReportAlignment,
          value: report.alignment,
          caption: report.mirrorReading,
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 16,
          children: [
            _Swatch(
              color: AppColors.company,
              label: l10n.cultureResponsesLeaders,
            ),
            _Swatch(
              color: AppColors.slate,
              label: l10n.cultureResponsesEmployees,
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final value in report.mirrorValues) ...[
          _MirrorRow(value: value),
          const SizedBox(height: 16),
        ],
        if (report.blindSpots.isNotEmpty) ...[
          const SizedBox(height: 4),
          _Label(l10n.cultureReportBlindSpots),
          for (final (description, _, impact) in report.blindSpots)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.border,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Paragraph(description, strong: true),
                  if (impact.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _Paragraph(impact),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _MirrorRow extends StatelessWidget {
  const _MirrorRow({required this.value});
  final CultureMirrorValue value;

  @override
  Widget build(BuildContext context) {
    final (gap, tone) = _gapWords(context, value.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                value.value,
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TalexPill(gap, tone: tone),
          ],
        ),
        const SizedBox(height: 8),
        _Diverging(
          value: value.leaders,
          color: AppColors.company,
          words: _levelWords(context, value.leaders),
        ),
        const SizedBox(height: 4),
        _Diverging(
          value: value.employees,
          color: AppColors.slate,
          words: _levelWords(context, value.employees),
        ),
      ],
    );
  }
}

/// Barra divergente (de -1 a 1, cero al centro) con su lectura en palabras.
class _Diverging extends StatelessWidget {
  const _Diverging({
    required this.value,
    required this.color,
    required this.words,
  });

  final double value;
  final Color color;
  final String words;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(-1.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final half = constraints.maxWidth / 2;
              final width = half * clamped.abs();
              return SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Positioned(
                      left: clamped >= 0 ? half : half - width,
                      width: width,
                      top: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Positioned(
                      left: half - 0.5,
                      width: 1,
                      top: 0,
                      bottom: 0,
                      child: ColoredBox(color: AppColors.borderStrong),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: Text(
            words,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}

class _SaidVsDone extends StatelessWidget {
  const _SaidVsDone({required this.report});
  final CultureReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Block(
      title: l10n.cultureReportSaid,
      help: l10n.cultureReportSaidHelp,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 280,
              child: _Score(
                label:
                    '${l10n.cultureReportCoherence} · ${l10n.cultureResponsesLeaders}',
                value: report.leaderCoherence,
              ),
            ),
            SizedBox(
              width: 280,
              child: _Score(
                label:
                    '${l10n.cultureReportCoherence} · ${l10n.cultureResponsesEmployees}',
                value: report.employeeCoherence,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Paragraph(report.saidReading),
        const SizedBox(height: 16),
        for (final value in report.declaredValues)
          Builder(
            builder: (context) {
              final (verdict, tone) = _verdictWords(context, value.verdict);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.border,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value.declared,
                            style: TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (value.talexValue.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              l10n.cultureReportTalexValue(
                                value.talexValue.toLowerCase(),
                              ),
                              style: TextStyle(
                                color: AppColors.textDimmer,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    TalexPill(verdict, tone: tone),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _Offer extends StatelessWidget {
  const _Offer({required this.report});
  final CultureReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Block(
      title: l10n.cultureReportOffer,
      help: l10n.cultureReportOfferHelp,
      children: [
        Wrap(
          spacing: 32,
          runSpacing: 20,
          children: [
            _PillGroup(
              label: l10n.cultureReportOffered,
              values: report.offered,
              tone: TalexTone.green,
              icon: Icons.check,
            ),
            _PillGroup(
              label: l10n.cultureReportNotOffered,
              values: report.notOffered,
              tone: TalexTone.neutral,
            ),
          ],
        ),
        if (report.unconfirmedPromises.isNotEmpty) ...[
          const SizedBox(height: 22),
          _Label(l10n.cultureReportPromises),
          for (final (need, _) in report.unconfirmedPromises)
            _Bullet(
              l10n.cultureReportPromiseLine(need),
              icon: Icons.info_outline,
              color: AppColors.blue,
            ),
        ],
        if (report.sincerityReading != null) ...[
          const SizedBox(height: 12),
          _Label(l10n.cultureReportSincerity),
          _Paragraph(report.sincerityReading!),
        ],
      ],
    );
  }
}

class _Voice extends StatelessWidget {
  const _Voice({required this.report});
  final CultureReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget column(
      String label,
      List<(String, String, num)> items,
      Color color,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(label),
        for (final (quote, _, pct) in items)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.border,
              border: Border(left: BorderSide(color: color, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“$quote”',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.cultureReportVoiceShare('${pct.round()}'),
                  style: TextStyle(color: AppColors.textDimmer, fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
    return _Block(
      title: l10n.cultureReportVoice,
      help: l10n.cultureReportVoiceHelp,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final well = column(
              l10n.cultureReportDoingWell,
              report.doingWell,
              AppColors.green,
            );
            final harder = column(
              l10n.cultureReportDoingBadly,
              report.doingBadly,
              AppColors.slate,
            );
            if (constraints.maxWidth < 760) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [well, const SizedBox(height: 16), harder],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: well),
                const SizedBox(width: 24),
                Expanded(child: harder),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Hiring extends StatelessWidget {
  const _Hiring({required this.report});
  final CultureReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Block(
      title: l10n.cultureReportHiring,
      help: l10n.cultureReportHiringHelp,
      children: [
        _Callout(
          icon: Icons.check,
          tone: TalexTone.green,
          title: l10n.cultureReportThrives,
          text: report.thrivingCandidate,
        ),
        const SizedBox(height: 10),
        _Callout(
          icon: Icons.info_outline,
          tone: TalexTone.neutral,
          title: l10n.cultureReportAtRisk,
          text: report.atRiskCandidate,
        ),
        if (report.hiringRisks.isNotEmpty) ...[
          const SizedBox(height: 24),
          _Label(l10n.cultureReportRisks),
          for (final (risk, probability, _, mitigation) in report.hiringRisks)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _Paragraph(risk, strong: true)),
                      const SizedBox(width: 12),
                      TalexPill(
                        switch (probability) {
                          'alta' => l10n.cultureReportImportant,
                          'media' => l10n.cultureReportToReview,
                          _ => l10n.cultureReportMinor,
                        },
                        tone: switch (probability) {
                          'alta' => TalexTone.warning,
                          'media' => TalexTone.blue,
                          _ => TalexTone.neutral,
                        },
                      ),
                    ],
                  ),
                  if (mitigation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _Paragraph('${l10n.cultureReportMitigation}: $mitigation'),
                  ],
                ],
              ),
            ),
        ],
        if (report.interviewQuestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          _Label(l10n.cultureReportQuestions),
          for (final (index, (question, reveals))
              in report.interviewQuestions.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.blueDim,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Paragraph(question, strong: true),
                        if (reveals.isNotEmpty)
                          Text(
                            plainReportText(reveals),
                            style: TextStyle(
                              color: AppColors.textDimmer,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (report.honestMessage.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Callout(
            icon: Icons.chat_bubble_outline,
            tone: TalexTone.blue,
            title: l10n.cultureReportHonest,
            text: report.honestMessage,
          ),
        ],
      ],
    );
  }
}

class _Recommendations extends StatelessWidget {
  const _Recommendations({required this.report});
  final CultureReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Block(
      title: l10n.cultureReportRecommendations,
      children: [
        for (final (index, (_, action, owner, deadline, success))
            in report.recommendations.indexed) ...[
          if (index > 0) const TalexDivider(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TalexPill(
                l10n.cultureReportPriority(index + 1),
                tone: index == 0 ? TalexTone.green : TalexTone.neutral,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Paragraph(action, strong: true),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (owner.isNotEmpty)
                          '${l10n.cultureReportOwner}: $owner',
                        if (deadline.isNotEmpty)
                          '${l10n.cultureReportDeadline} ${humanizeReportCode(deadline).toLowerCase()}',
                      ].join(' · '),
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    if (success.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.cultureReportSuccess}: ${plainReportText(success)}',
                        style: TextStyle(
                          color: AppColors.textDimmer,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// Sello TaleX desactivado por ahora; descomentar para mostrarlo.
// class _Seal extends StatelessWidget {
// const _Seal({required this.report});
// final CultureReport report;

// @override
// Widget build(BuildContext context) {
// final l10n = context.l10n;
// return _Block(
// title: l10n.cultureReportSeal,
// help: l10n.cultureReportSealHelp,
// trailing: TalexPill(
// _sealLabel(context, report.sealStatus),
// tone: _sealTone(report.sealStatus),
// icon: Icons.verified_outlined,
// ),
// children: [
// if (report.sealText.isNotEmpty) _Paragraph(report.sealText),
// if (report.sealMonths != null && _sealValidated(report.sealStatus)) ...[
// const SizedBox(height: 6),
// Text(
// l10n.cultureReportSealValidity(report.sealMonths!),
// style: TextStyle(color: AppColors.textDimmer, fontSize: 12.5),
// ),
// ],
// if (report.sealMet.isNotEmpty) ...[
// const SizedBox(height: 18),
// _Label(l10n.cultureReportSealMet),
// for (final item in report.sealMet)
// _Bullet(
// _conditionWords(context, item),
// icon: Icons.check,
// color: AppColors.good,
// ),
// ],
// if (report.sealPending.isNotEmpty) ...[
// const SizedBox(height: 10),
// _Label(l10n.cultureReportSealPending),
// for (final item in report.sealPending)
// _Bullet(
// _conditionWords(context, item),
// icon: Icons.schedule,
// color: AppColors.blue,
// ),
// ],
// ],
// );
// }
// }

class _Quality extends StatelessWidget {
  const _Quality({required this.report});
  final CultureReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (confidence, tone) = _confidence(context, report.confidence);
    return _Block(
      title: l10n.cultureReportQuality,
      trailing: report.confidence.isEmpty
          ? null
          : TalexPill(confidence, tone: tone),
      children: [
        if (report.requiredSample > 0)
          _Score(
            label: l10n.cultureReportAnswersOf(
              report.employeeAnswers,
              report.requiredSample,
            ),
            value: report.sampleCoverage.round(),
          ),
        if (report.areaRepresentation.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final (area, staff, answers, _) in report.areaRepresentation)
            _Bullet(
              l10n.cultureReportAreaShare(
                area,
                '${staff.round()}',
                '${answers.round()}',
              ),
            ),
        ],
        if (report.qualityAlerts.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Label(l10n.cultureReportAlerts),
          for (final alert in report.qualityAlerts)
            _Bullet(alert, icon: Icons.info_outline, color: AppColors.blue),
        ],
        if (report.limitations.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Label(l10n.cultureReportLimitations),
          for (final item in report.limitations) _Bullet(item),
        ],
      ],
    );
  }
}
