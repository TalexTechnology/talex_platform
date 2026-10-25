import 'package:flutter/material.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/features/admin/presentation/pages/admin_my_culture_view.dart';
import 'package:talex_platform/features/admin/presentation/pages/admin_questions_view.dart';
import 'package:talex_platform/l10n/l10n.dart';

// Agrupa las encuestas: la de afinidad candidato vs empresa y "Mi cultura"
// (leads de la landing /micultura por empresa).
class AdminSurveysView extends StatelessWidget {
  const AdminSurveysView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < 720;
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 18 : 40,
              compact ? 12 : 20,
              compact ? 18 : 40,
              0,
            ),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primaryButton,
              indicatorColor: AppColors.primaryButton,
              dividerColor: AppColors.divider,
              tabs: [
                Tab(text: l10n.adminSurveysCultureVs),
                Tab(text: l10n.adminSurveysMyCulture),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: const [AdminQuestionsView(), AdminMyCultureView()],
            ),
          ),
        ],
      ),
    );
  }
}
