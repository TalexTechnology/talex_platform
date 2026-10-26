import 'package:flutter/material.dart';
import 'package:talex_platform/core/widgets/theme_toggle_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/theme/talex_theme.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/core/widgets/content_width.dart';
import 'package:talex_platform/core/widgets/language_selector.dart';
import 'package:talex_platform/core/widgets/skeleton.dart';
import 'package:talex_platform/core/widgets/talex_logo.dart';
import 'package:talex_platform/core/widgets/talex_ui.dart';
import 'package:talex_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/presentation/bloc/talent_bloc.dart';
import 'package:talex_platform/features/talent/presentation/company_options.dart';
import 'package:talex_platform/features/talent/presentation/pages/talent_password_page.dart';
import 'package:talex_platform/features/talent/presentation/talent_error_message.dart';
import 'package:talex_platform/features/talent/presentation/widgets/assessment_answer_widgets.dart';
import 'package:talex_platform/l10n/l10n.dart';

class RespondentShell extends StatelessWidget {
  const RespondentShell({
    super.key,
    required this.mustChangePassword,
    this.demo,
    this.onDemoSignOut,
  });
  final bool mustChangePassword;

  /// Con [demo] la pantalla funciona igual pero sin sesión ni guardado; la
  /// usa el demo público de la encuesta. "Cerrar sesión" llama a
  /// [onDemoSignOut].
  final RespondentSession? demo;
  final VoidCallback? onDemoSignOut;

  @override
  Widget build(BuildContext context) {
    if (mustChangePassword) return const TalentPasswordPage();
    if (demo != null) return _scaffold(context);
    return BlocListener<TalentBloc, TalentState>(
      listenWhen: (previous, current) => previous.failure != current.failure,
      listener: (context, state) {
        if (state.failure != null) {
          getIt<NotificationService>().error(
            talentErrorMessage(context.l10n, state.failure!.message),
          );
        }
      },
      child: _scaffold(context),
    );
  }

  Widget _scaffold(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 64,
      title: const TalexLogo(width: 110, height: 32),
      actions: [
        const LanguageSelector(compact: true),
        const SizedBox(width: 12),
        const ThemeToggleButton(size: 36),
        const SizedBox(width: 4),
        TextButton(
          onPressed: demo != null
              ? onDemoSignOut
              : () =>
                    context.read<AuthBloc>().add(const AuthSignOutRequested()),
          child: Text(context.l10n.signOut),
        ),
      ],
    ),
    body: RespondentSurveyView(demo: demo),
  );
}

class RespondentSurveyView extends StatefulWidget {
  const RespondentSurveyView({super.key, this.demo});
  final RespondentSession? demo;
  @override
  State<RespondentSurveyView> createState() => _RespondentSurveyViewState();
}

class _RespondentSurveyViewState extends State<RespondentSurveyView> {
  var _started = false;
  var _finishing = false;
  var _index = 0;
  final _picks = <String, int>{};
  var _demoFinished = false;
  var _demoResultRequested = false;

  bool get _isDemo => widget.demo != null;

  RespondentSession _demoSession() {
    final demo = widget.demo!;
    final candidate = demo.candidate;
    return RespondentSession(
      company: demo.company,
      answers: demo.answers,
      candidate: TalentCandidate(
        id: candidate.id,
        companyId: candidate.companyId,
        vacancyId: candidate.vacancyId,
        vacancyName: candidate.vacancyName,
        email: candidate.email,
        documentNumber: candidate.documentNumber,
        processStatus: candidate.processStatus,
        updatedAt: candidate.updatedAt,
        displayName: candidate.displayName,
        assessmentKind: candidate.assessmentKind,
        evaluationCompleted: _demoFinished,
        resultRequested: _demoResultRequested,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDemo) return _survey(context, _demoSession());
    final l10n = context.l10n;
    return BlocConsumer<TalentBloc, TalentState>(
      listenWhen: (previous, current) => _finishing && current.failure != null,
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
          return const SkeletonCenteredCard();
        }
        return _survey(context, state.respondentSession!);
      },
    );
  }

  Widget _survey(BuildContext context, RespondentSession session) {
    final l10n = context.l10n;
    if (session.candidate.evaluationCompleted) {
      return _FinishedView(
        session: session,
        onRequestResult: _isDemo
            ? () => setState(() => _demoResultRequested = true)
            : null,
      );
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
      if (_isDemo) return;
      context.read<TalentBloc>().add(
        TalentAnswerSaved(
          candidateId: session.candidate.id,
          questionId: questionId,
          value: value,
        ),
      );
    }

    // El formulario de preguntas conserva su diseño claro original.
    return Theme(
      data: talexLegacyTheme(),
      child: ColoredBox(
        color: LegacyColors.background,
        child: ContentWidth(
          maxWidth: 720,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.questionProgress(_index + 1, ids.length),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: LegacyColors.subtitle),
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
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            color: LegacyColors.ink,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (item.isPair)
                          PairAnswer(
                            statementA: item.statementA.of(languageCode),
                            statementB: item.statementB!.of(languageCode),
                            labels: labels,
                            selected: selected,
                            onSelected: pick,
                            hint: l10n.assessmentPairScaleHint,
                          )
                        else ...[
                          _StatementCard(
                            text: item.statementA.of(languageCode),
                          ),
                          const SizedBox(height: 16),
                          FrequencyAnswer(
                            labels: labels,
                            selected: selected,
                            onSelected: pick,
                          ),
                        ],
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
                                if (_isDemo) {
                                  setState(() => _demoFinished = true);
                                  return;
                                }
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
        ),
      ),
    );
  }
}

class _StatementCard extends StatelessWidget {
  const _StatementCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFDCE4EE)),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 16,
        height: 1.45,
        color: LegacyColors.ink,
      ),
    ),
  );
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
    return TalexGlow(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
        child: ContentWidth(
          maxWidth: 680,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TalexEyebrow(l10n.assessmentKindAffinity),
              const SizedBox(height: 16),
              Text(
                l10n.respondentHello(name.split(' ').first),
                style: TextStyle(
                  fontSize: 44,
                  height: 1.02,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 32),
              TalexPanel(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (company != null) ...[
                      Text(
                        l10n.sentByCompany,
                        style: TextStyle(
                          color: AppColors.textDimmer,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        company.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          color: AppColors.text,
                        ),
                      ),
                      if (company.description?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 10),
                        Text(
                          company.description!,
                          style: TextStyle(
                            height: 1.65,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TalexPill(
                          session.candidate.vacancyName,
                          icon: Icons.work_outline,
                        ),
                        TalexPill(
                          l10n.respondentQuestionCount(total),
                          tone: TalexTone.neutral,
                          icon: Icons.format_list_numbered,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const TalexDivider(),
                    const SizedBox(height: 24),
                    _InfoLine(
                      icon: Icons.tune,
                      text: l10n.respondentLikertHint,
                    ),
                    const SizedBox(height: 14),
                    _InfoLine(
                      icon: Icons.schedule_outlined,
                      text: l10n.respondentDuration,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(l10n.startAssessment),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TalexIconBadge(icon, size: 32),
      const SizedBox(width: 14),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            text,
            style: TextStyle(height: 1.55, color: AppColors.textMuted),
          ),
        ),
      ),
    ],
  );
}

class _FinishedView extends StatelessWidget {
  const _FinishedView({required this.session, this.onRequestResult});
  final RespondentSession session;

  /// Si se da, reemplaza la solicitud real de resultados (demo).
  final VoidCallback? onRequestResult;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final requested = session.candidate.resultRequested;
    return TalexGlow(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ContentWidth(
            maxWidth: 560,
            child: TalexPanel(
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
              child: Column(
                children: [
                  const TalexIconBadge(
                    Icons.check,
                    tone: TalexTone.green,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.assessmentFinishedTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.assessmentFinishedBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.65,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (requested)
                    TalexPill(
                      l10n.surveyResultRequested,
                      tone: TalexTone.green,
                      icon: Icons.mark_email_read_outlined,
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed:
                            onRequestResult ??
                            () => context.read<TalentBloc>().add(
                              TalentSurveyResultRequested(session.candidate.id),
                            ),
                        child: Text(l10n.surveyResultRequest),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
