import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/features/admin/domain/entities/culture_organization_report.dart';
import 'package:talex_platform/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:talex_platform/l10n/l10n.dart';

class CultureTrackingSummary extends StatelessWidget {
  const CultureTrackingSummary({super.key, required this.group});

  final CultureOrganizationGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tracking = group.tracking;
    final labels = AdminLabels(context);
    final date = tracking.sharedConfirmedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            Text('${l10n.cultureTrackingVisits}: ${tracking.visits}'),
            Text('${l10n.cultureTrackingVisitors}: ${tracking.uniqueVisitors}'),
            Text('${l10n.cultureTrackingStarted}: ${tracking.startedVisits}'),
            Text(
              '${l10n.cultureTrackingCompleted}: ${group.surveyRespondents}',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          date == null
              ? l10n.cultureTrackingUnconfirmed
              : '${l10n.cultureTrackingConfirmed}: ${labels.date(date.toLocal())}',
          style: TextStyle(
            color: date == null ? AppColors.textMuted : AppColors.green,
          ),
        ),
        if (tracking.lastVisitAt != null) ...[
          const SizedBox(height: 4),
          Text(
            '${l10n.cultureTrackingLastVisit}: ${labels.date(tracking.lastVisitAt!.toLocal())}',
          ),
        ],
        const SizedBox(height: 4),
        Text(
          l10n.cultureTrackingHelp,
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}
