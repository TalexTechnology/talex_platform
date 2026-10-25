import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_assets.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/core/widgets/content_width.dart';
import 'package:talex_platform/core/widgets/language_selector.dart';
import 'package:talex_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/presentation/bloc/talent_bloc.dart';
import 'package:talex_platform/features/talent/presentation/company_options.dart';
import 'package:talex_platform/features/talent/presentation/pages/talent_password_page.dart';
import 'package:talex_platform/features/talent/presentation/talent_error_message.dart';
import 'package:talex_platform/l10n/l10n.dart';

class RespondentShell extends StatelessWidget {
  const RespondentShell({super.key, required this.mustChangePassword});
  final bool mustChangePassword;

  @override
  Widget build(BuildContext context) {
    if (mustChangePassword) return const TalentPasswordPage();
    return BlocListener<TalentBloc, TalentState>(
      listenWhen: (previous, current) => previous.failure != current.failure,
      listener: (context, state) {
        if (state.failure != null) {
          getIt<NotificationService>().error(
            talentErrorMessage(context.l10n, state.failure!.message),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.dashboardBackground,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Image.asset(AppAssets.talexLogoHorizontal, height: 28),
          actions: [
            const LanguageSelector(compact: true),
            TextButton(
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthSignOutRequested()),
              child: Text(context.l10n.signOut),
            ),
          ],
        ),
        body: const RespondentSurveyView(),
      ),
    );
  }
}

class RespondentSurveyView extends StatefulWidget {
  const RespondentSurveyView({super.key});
  @override
  State<RespondentSurveyView> createState() => _RespondentSurveyViewState();
}

class _RespondentSurveyViewState extends State<RespondentSurveyView> {
  var _started = false;
  var _finishing = false;
  var _index = 0;
  final _picks = <String, int>{};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<TalentBloc, TalentState>(
      listenWhen: (previous, current) =>
          _finishing && current.failure != null,
      listener: (context, state) => setState(() => _finishing = false),
      builder: (context, state) {
        if (state.status == TalentViewStatus.failure &&
            state.respondentSession == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    talentErrorMessage(
                      l10n,
                      state.failure?.message ?? 'errorUnexpected',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<TalentBloc>().add(
                      const TalentRespondentSessionLoaded(),
                    ),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          );
        }
        if (state.status == TalentViewStatus.loading ||
            state.respondentSession == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final session = state.respondentSession!;
        if (session.candidate.evaluationCompleted) {
          return _FinishedView(session: session);
        }
        if (!_started) {
          return _LandingView(
            session: session,
            onStart: () {
              setState(() => _started = true);
            },
          );
        }
        final ids = AssessmentCatalog.allIds;
        final questionId = ids[_index.clamp(0, ids.length - 1)];
        final item = AssessmentCatalog.byId(questionId)!;
        final selected = _picks[questionId] ?? session.answers[questionId];
        final complete = ids.every(
          (id) => (_picks[id] ?? session.answers[id]) != null,
        );
        final labels = assessmentScaleLabels(l10n, item.format);
        final languageCode = l10n.localeName;
        void pick(int value) {
          setState(() => _picks[questionId] = value);
          context.read<TalentBloc>().add(
            TalentAnswerSaved(
              candidateId: session.candidate.id,
              questionId: questionId,
              value: value,
            ),
          );
        }

        return ContentWidth(
          maxWidth: 820,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.questionProgress(_index + 1, ids.length),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.subtitle),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: (_index + 1) / ids.length),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          assessmentInstruction(l10n, item),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (item.isPair)
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _StatementCard(
                                    caption: l10n.assessmentStatementA,
                                    text: item.statementA.of(languageCode),
                                    leaning: selected != null && selected < 3,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatementCard(
                                    caption: l10n.assessmentStatementB,
                                    text: item.statementB!.of(languageCode),
                                    leaning: selected != null && selected > 3,
                                    alignEnd: true,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          _StatementCard(
                            text: item.statementA.of(languageCode),
                            centered: true,
                          ),
                        const SizedBox(height: 20),
                        _SegmentedScale(
                          selected: selected,
                          labels: labels,
                          onSelected: pick,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              item.isPair ? 'A' : labels.first,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.subtitle,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              item.isPair ? 'B' : labels.last,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          selected == null
                              ? (item.isPair
                                    ? l10n.assessmentPairScaleHint
                                    : '')
                              : labels[selected - 1],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: selected == null ? 14 : 16,
                            fontWeight: selected == null
                                ? FontWeight.w400
                                : FontWeight.w600,
                            color: selected == null
                                ? AppColors.muted
                                : AppColors.primaryButton,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _index == 0
                          ? null
                          : () => setState(() => _index -= 1),
                      child: Text(l10n.goBack),
                    ),
                    const Spacer(),
                    if (_index == ids.length - 1)
                      FilledButton(
                        onPressed: complete && !_finishing
                            ? () {
                                setState(() => _finishing = true);
                                context.read<TalentBloc>().add(
                                  TalentEvaluationCompleted(
                                    session.candidate.id,
                                    locale: Localizations.localeOf(
                                      context,
                                    ).languageCode,
                                  ),
                                );
                              }
                            : null,
                        child: _finishing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.finish),
                      )
                    else
                      FilledButton(
                        onPressed: selected == null
                            ? null
                            : () => setState(() => _index += 1),
                        child: Text(l10n.next),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatementCard extends StatelessWidget {
  const _StatementCard({
    required this.text,
    this.caption,
    this.leaning = false,
    this.alignEnd = false,
    this.centered = false,
  });
  final String text;
  final String? caption;
  final bool leaning, alignEnd, centered;

  @override
  Widget build(BuildContext context) {
    final align = centered
        ? TextAlign.center
        : (alignEnd ? TextAlign.end : TextAlign.start);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: leaning ? AppColors.fieldFill : Colors.white,
        borderRadius: AppRadii.border,
        border: Border.all(
          color: leaning ? AppColors.primaryButton : const Color(0xFFD1D1D6),
          width: leaning ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: centered
            ? CrossAxisAlignment.center
            : (alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start),
        children: [
          if (caption != null) ...[
            Text(
              caption!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            text,
            textAlign: align,
            style: const TextStyle(
              fontSize: 17,
              height: 1.4,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rectángulo dividido en tantos recuadros como etiquetas; el valor es 1..n.
class _SegmentedScale extends StatelessWidget {
  const _SegmentedScale({
    required this.selected,
    required this.labels,
    required this.onSelected,
  });
  final int? selected;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFD1D1D6);
    return ClipRRect(
      borderRadius: AppRadii.border,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: AppRadii.border,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: selected == i + 1,
                  label: labels[i],
                  child: Tooltip(
                    message: labels[i],
                    child: Material(
                      color: selected == i + 1
                          ? AppColors.primaryButton
                          : Colors.white,
                      child: InkWell(
                        onTap: () => onSelected(i + 1),
                        child: Container(
                          decoration: BoxDecoration(
                            border: i == 0
                                ? null
                                : const Border(
                                    left: BorderSide(color: borderColor),
                                  ),
                          ),
                          child: selected == i + 1
                              ? const Center(
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LandingView extends StatefulWidget {
  const _LandingView({required this.session, required this.onStart});
  final RespondentSession session;
  final VoidCallback onStart;

  @override
  State<_LandingView> createState() => _LandingViewState();
}

class _LandingViewState extends State<_LandingView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = context.l10n;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.respondentWelcomeTitle),
          content: Text(l10n.respondentWelcomeBody),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryButton,
              ),
              child: Text(l10n.respondentWelcomeAction),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final onStart = widget.onStart;
    final l10n = context.l10n;
    final name = session.candidate.displayName?.trim().isNotEmpty == true
        ? session.candidate.displayName!
        : session.candidate.email;
    final company = session.company;
    final kind = session.candidate.assessmentKind;
    final total = AssessmentCatalog.allIds.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ContentWidth(
        maxWidth: 720,
        child: Column(
          children: [
            Text(
              l10n.respondentHello(name.split(' ').first),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadii.border,
                border: Border.all(color: const Color(0xFFD1D1D6)),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.assessmentKindLabel,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  Chip(label: Text(l10n.assessmentKindAffinity)),
                  const SizedBox(height: 20),
                  if (company != null) ...[
                    Text(
                      l10n.sentByCompany,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      company.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    if (company.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        company.description!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          height: 1.45,
                          color: AppColors.subtitle,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                  Text(
                    session.candidate.vacancyName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.respondentLikertHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.45, color: AppColors.ink),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.respondentDuration,
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.45, color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.respondentQuestionCount(total),
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.45, color: AppColors.ink),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      if (kind != AssessmentKind.affinity) {
                        context.read<TalentBloc>().add(
                          TalentAssessmentKindSelected(
                            candidateId: session.candidate.id,
                            kind: AssessmentKind.affinity,
                          ),
                        );
                      }
                      onStart();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(l10n.startAssessment),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Image.asset(AppAssets.talexMarca, fit: BoxFit.fitWidth),
          ],
        ),
      ),
    );
  }
}

class _FinishedView extends StatelessWidget {
  const _FinishedView({required this.session});
  final RespondentSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final requested = session.candidate.resultRequested;
    return ContentWidth(
      maxWidth: 640,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.assessmentFinishedTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.assessmentFinishedBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                height: 1.45,
                color: AppColors.subtitle,
              ),
            ),
            const SizedBox(height: 24),
            if (requested)
              Text(
                l10n.surveyResultRequested,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: AppColors.ink,
                ),
              )
            else
              FilledButton(
                onPressed: () => context.read<TalentBloc>().add(
                  TalentSurveyResultRequested(session.candidate.id),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(l10n.surveyResultRequest),
              ),
            const SizedBox(height: 28),
            Image.asset(AppAssets.talexMarca, fit: BoxFit.fitWidth),
          ],
        ),
      ),
    );
  }
}
