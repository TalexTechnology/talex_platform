import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/presentation/company_options.dart';
import 'package:talex_platform/l10n/app_localizations.dart';

class CandidateReportPdf {
  const CandidateReportPdf();

  Future<Uint8List> build({
    required AppLocalizations l10n,
    required CandidateReport report,
    required String processLabel,
    required String Function(AffinityLevel) affinityLabel,
  }) async {
    final candidate = report.candidate;
    final analysis = report.analysis;
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 40),
        ),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'TaleX',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF1D7BD6),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              l10n.candidateResultTitle,
              style: pw.TextStyle(fontSize: 12, color: PdfColor.fromInt(0xFF76777C)),
            ),
            pw.Divider(color: PdfColor.fromInt(0xFF1D7BD6)),
          ],
        ),
        build: (_) => [
          pw.Text(
            candidate.displayName?.trim().isNotEmpty == true
                ? candidate.displayName!
                : candidate.email,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          _row(l10n.emailAddress, candidate.email),
          _row(l10n.documentNumber, candidate.documentNumber),
          _row(l10n.vacancy, candidate.vacancyName),
          if (report.company != null) _row(l10n.companyName, report.company!.name),
          _row(l10n.candidateProcessStatus, processLabel),
          _row(l10n.assessmentKindLabel, l10n.assessmentKindAffinity),
          pw.SizedBox(height: 16),
          pw.Text(
            l10n.affinityWithCompany,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.Text(
            [
              affinityLabel(
                analysis.hasResult ? analysis.level : candidate.companyAffinity,
              ),
              if (analysis.hasResult && analysis.score != null)
                l10n.affinityScoreValue(analysis.score!),
            ].join(' · '),
          ),
          pw.Text(
            affinityAnalysisMessage(
              l10n,
              analysis,
              evaluationCompleted: candidate.evaluationCompleted,
            ),
            style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
          ),
          if (analysis.hasResult) ...[
            ..._insights(l10n.affinityAlignmentsTitle, analysis.alignments),
            ..._insights(l10n.affinityDifferencesTitle, analysis.differences),
            ..._items(l10n.affinityTopicsTitle, analysis.conversationTopics),
            if (analysis.guidance.trim().isNotEmpty)
              ..._items(l10n.affinityGuidanceTitle, [analysis.guidance.trim()]),
          ],
          pw.SizedBox(height: 8),
          pw.Text(
            l10n.affinityMockNote,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromInt(0xFF76777C),
            ),
          ),
          if (report.vacancy?.description?.trim().isNotEmpty == true) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              l10n.description,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(report.vacancy!.description!),
          ],
          if (report.vacancy?.roleProfile?.trim().isNotEmpty == true) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              l10n.roleProfile,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(report.vacancy!.roleProfile!),
          ],
          pw.SizedBox(height: 20),
          pw.Text(
            l10n.fullSummaryTitle,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          for (final id in AssessmentCatalog.allIds)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    assessmentQuestionLabel(l10n, id),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                  ),
                  pw.Text(
                    report.answers[id] == null
                        ? l10n.noData
                        : assessmentAnswerLabel(l10n, id, report.answers[id]!),
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    return doc.save();
  }

  List<pw.Widget> _heading(String title) => [
    pw.SizedBox(height: 10),
    pw.Text(
      title,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
    ),
    pw.SizedBox(height: 4),
  ];

  List<pw.Widget> _insights(String title, List<AffinityInsight> insights) => [
    if (insights.isNotEmpty) ..._heading(title),
    for (final item in insights)
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.RichText(
          text: pw.TextSpan(
            style: const pw.TextStyle(fontSize: 11),
            children: [
              pw.TextSpan(
                text: '- ${item.aspect}. ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.TextSpan(text: item.evidence),
            ],
          ),
        ),
      ),
  ];

  List<pw.Widget> _items(String title, List<String> items) => [
    if (items.isNotEmpty) ..._heading(title),
    for (final item in items)
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Text('- $item', style: const pw.TextStyle(fontSize: 11)),
      ),
  ];

  pw.Widget _row(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TextSpan(text: value),
        ],
      ),
    ),
  );
}
