import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/constants/app_assets.dart';
import 'package:talex_platform/core/constants/app_colors.dart';
import 'package:talex_platform/core/constants/app_radii.dart';
import 'package:talex_platform/core/di/injection.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/core/widgets/content_width.dart';
import 'package:talex_platform/core/widgets/language_selector.dart';
import 'package:talex_platform/core/widgets/skeleton.dart';
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
    backgroundColor: AppColors.dashboardBackground,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      title: Image.asset(AppAssets.talexLogoHorizontal, height: 28),
      actions: [
        const LanguageSelector(compact: true),
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

    return ContentWidth(
      maxWidth: 720,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: AppColors.ink,
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
                      _StatementCard(text: item.statementA.of(languageCode)),
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
      style: const TextStyle(fontSize: 16, height: 1.45, color: AppColors.ink),
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
  const _FinishedView({required this.session, this.onRequestResult});
  final RespondentSession session;

  /// Si se da, reemplaza la solicitud real de resultados (demo).
  final VoidCallback? onRequestResult;

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
              style: const TextStyle(height: 1.45, color: AppColors.subtitle),
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
                onPressed:
                    onRequestResult ??
                    () => context.read<TalentBloc>().add(
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
