import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/auth/user_role.dart';
import 'package:talex_platform/core/error/failure.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/domain/repositories/talent_repository.dart';

part 'talent_event.dart';
part 'talent_state.dart';

class TalentBloc extends Bloc<TalentEvent, TalentState> {
  TalentBloc({required TalentRepository repository})
    : _repository = repository,
      super(const TalentState()) {
    on<TalentLoaded>(_onLoad);
    on<TalentSectionSelected>(_onSection);
    on<TalentProfileSaved>(_onSaveProfile);
    on<TalentVacancyCreated>(_onVacancy);
    on<TalentRespondentCreated>(_onRespondent);
    on<TalentRecruiterInvited>(_onInvite);
    on<TalentCandidateStatusUpdated>(_onStatus);
    on<TalentRespondentSessionLoaded>(_onRespondentSession);
    on<TalentAnswerSaved>(_onAnswer);
    on<TalentEvaluationCompleted>(_onComplete);
    on<TalentSurveyResultRequested>(_onSurveyResultRequested);
    on<TalentPasswordChanged>(_onPassword);
    on<TalentCompanyDnaConfirmed>(_onDnaConfirmed);
    on<TalentFilterChanged>(_onFilter);
    on<TalentAssessmentKindSelected>(_onAssessmentKind);
    on<TalentCandidateOpened>(_onCandidateOpened);
    on<TalentCandidateClosed>(_onCandidateClosed);
    on<TalentCandidateUpdated>(_onCandidateUpdated);
    on<TalentCandidateDeleted>(_onCandidateDeleted);
    on<TalentDnaOptionDeleted>(_onDnaOptionDeleted);
    on<TalentAffinityAnalysisRequested>(_onAnalysisRequested);
    on<TalentAffinityAnalysisPolled>(_onAnalysisPolled);
  }

  static const _analysisPollInterval = Duration(seconds: 5);
  static const _analysisPollLimit = 18;
  static const _backfillLimit = 20;

  final TalentRepository _repository;
  final _backfillAttempted = <String>{};
  Timer? _analysisPoll;

  @override
  Future<void> close() {
    _analysisPoll?.cancel();
    return super.close();
  }

  void _pollAnalysis(CandidateReport report, [int attempt = 0]) {
    _analysisPoll?.cancel();
    if (!report.analysis.isPending || attempt >= _analysisPollLimit) return;
    _analysisPoll = Timer(
      _analysisPollInterval,
      () => add(TalentAffinityAnalysisPolled(report.candidate.id, attempt + 1)),
    );
  }

  Future<void> _onLoad(TalentLoaded event, Emitter<TalentState> emit) async {
    emit(state.copyWith(status: TalentViewStatus.loading, companyId: event.companyId));
    final result = await _repository.loadCompany(event.companyId);
    result.fold(
      (failure) => emit(state.copyWith(status: TalentViewStatus.failure, failure: failure)),
      (snapshot) {
        emit(
          state.copyWith(
            status: TalentViewStatus.success,
            snapshot: snapshot,
            generatedPin: null,
            respondentInvited: false,
            failure: null,
          ),
        );
        unawaited(_backfillAnalyses(event.companyId, snapshot.candidates));
      },
    );
  }

  /// Analiza en segundo plano las evaluaciones completadas antes de que
  /// existiera el análisis de afinidad. Cada candidato se intenta una vez.
  Future<void> _backfillAnalyses(
    String companyId,
    List<TalentCandidate> candidates,
  ) async {
    final pending = candidates
        .where(
          (item) =>
              item.evaluationCompleted &&
              !item.affinityAnalyzed &&
              _backfillAttempted.add(item.id),
        )
        .take(_backfillLimit)
        .toList();
    if (pending.isEmpty) return;
    for (final candidate in pending) {
      if (isClosed) return;
      await _repository.requestAffinityAnalysis(candidate.id);
    }
    if (!isClosed && state.companyId == companyId) add(TalentLoaded(companyId));
  }

  Future<void> _onSection(
    TalentSectionSelected event,
    Emitter<TalentState> emit,
  ) async {
    _analysisPoll?.cancel();
    emit(
      state.copyWith(
        section: event.section,
        clearCandidateReport: true,
        analysisRunning: false,
      ),
    );
  }

  Future<void> _onSaveProfile(
    TalentProfileSaved event,
    Emitter<TalentState> emit,
  ) async {
    final result = await _repository.saveCompanyProfile(event.profile);
    await result.fold(
      (failure) async => emit(state.copyWith(failure: failure)),
      (_) async => add(TalentLoaded(event.profile.id)),
    );
  }

  Future<void> _onVacancy(
    TalentVacancyCreated event,
    Emitter<TalentState> emit,
  ) async {
    final result = await _repository.createVacancy(event.vacancy);
    await result.fold(
      (failure) async => emit(state.copyWith(failure: failure)),
      (_) async => add(TalentLoaded(event.vacancy.companyId)),
    );
  }

  Future<void> _onRespondent(
    TalentRespondentCreated event,
    Emitter<TalentState> emit,
  ) async {
    final result = await _repository.createRespondent(
      companyId: event.companyId,
      vacancyId: event.vacancyId,
      email: event.email,
      documentNumber: event.documentNumber,
      displayName: event.displayName,
    );
    await result.fold(
      (failure) async => emit(state.copyWith(failure: failure)),
      (password) async {
        emit(state.copyWith(respondentInvited: true, failure: null));
        add(TalentLoaded(event.companyId));
      },
    );
  }

  Future<void> _onInvite(
    TalentRecruiterInvited event,
    Emitter<TalentState> emit,
  ) async {
    final result = await _repository.inviteRecruiter(
      companyId: event.companyId,
      email: event.email,
      firstName: event.firstName,
      lastName: event.lastName,
      role: event.role,
    );
    await result.fold(
      (failure) async => emit(state.copyWith(failure: failure)),
      (pin) async {
        emit(state.copyWith(generatedPin: pin, failure: null));
        add(TalentLoaded(event.companyId));
      },
    );
  }

  Future<void> _onStatus(
    TalentCandidateStatusUpdated event,
    Emitter<TalentState> emit,
  ) async {
    final result = await _repository.updateCandidateStatus(
      candidateId: event.candidateId,
      status: event.status,
    );
    await result.fold(
      (failure) async => emit(state.copyWith(failure: failure)),
      (_) async {
        if (state.companyId != null) add(TalentLoaded(state.companyId!));
      },
    );
  }

  Future<void> _onRespondentSession(
    TalentRespondentSessionLoaded event,
    Emitter<TalentState> emit,
  ) async {
    emit(state.copyWith(status: TalentViewStatus.loading));
    final result = await _repository.loadRespondentSession();
    result.fold(
      (failure) => emit(state.copyWith(status: TalentViewStatus.failure, failure: failure)),
      (session) => emit(
        state.copyWith(
          status: TalentViewStatus.success,
          respondentSession: session,
          failure: null,
        ),
      ),
    );
  }

  Future<void> _onAnswer(
    TalentAnswerSaved event,
    Emitter<TalentState> emit,
  ) async {
    final current = Map<String, int>.from(state.respondentSession?.answers ?? {});
    current[event.questionId] = event.value;
    final session = state.respondentSession;
    if (session != null) {
      emit(
        state.copyWith(
          respondentSession: RespondentSession(
            candidate: session.candidate,
            answers: current,
            company: session.company,
          ),
        ),
      );
    }
    await _repository.saveAnswer(
      candidateId: event.candidateId,
      questionId: event.questionId,
      value: event.value,
    );
  }

  Future<void> _onComplete(
    TalentEvaluationCompleted event,
    Emitter<TalentState> emit,
  ) async {
    final result = await _repository.completeEvaluation(
      event.candidateId,
      locale: event.locale,
    );
    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (candidate) {
        final session = state.respondentSession;
        emit(
          state.copyWith(
            respondentSession: RespondentSession(
              candidate: candidate,
              answers: session?.answers ?? const {},
              company: session?.company,
            ),
            failure: null,
          ),
        );
      },
    );
  }

  Future<void> _onSurveyResultRequested(
    TalentSurveyResultRequested event,
    Emitter<TalentState> emit,
  ) async {
    final session = state.respondentSession;
    if (session == null || session.candidate.resultRequested) return;
    final result = await _repository.requestSurveyResult(event.candidateId);
    result.fold((failure) => emit(state.copyWith(failure: failure)), (_) {
      final current = state.respondentSession;
      if (current == null) return;
      final person = current.candidate;
      emit(
        state.copyWith(
          failure: null,
          respondentSession: RespondentSession(
            candidate: TalentCandidate(
              id: person.id,
              companyId: person.companyId,
              vacancyId: person.vacancyId,
              vacancyName: person.vacancyName,
              email: person.email,
              documentNumber: person.documentNumber,
              displayName: person.displayName,
              processStatus: person.processStatus,
              companyAffinity: person.companyAffinity,
              vacancyAffinity: person.vacancyAffinity,
              evaluationCompleted: person.evaluationCompleted,
              resultRequested: true,
              assessmentKind: person.assessmentKind,
              affinityAnalyzed: person.affinityAnalyzed,
              updatedAt: person.updatedAt,
            ),
            answers: current.answers,
            company: current.company,
          ),
        ),
      );
    });
  }

  Future<void> _onPassword(
    TalentPasswordChanged event,
    Emitter<TalentState> emit,
  ) async {
    final result = await _repository.changePassword(event.password);
    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (_) => emit(state.copyWith(passwordChanged: true, failure: null)),
    );
  }

  Future<void> _onDnaConfirmed(
    TalentCompanyDnaConfirmed event,
    Emitter<TalentState> emit,
  ) async {
    final result = await _repository.saveCompanyProfile(event.profile);
    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (_) => emit(state.copyWith(dnaConfirmed: true, failure: null)),
    );
  }

  Future<void> _onFilter(
    TalentFilterChanged event,
    Emitter<TalentState> emit,
  ) async {
    emit(
      TalentState(
        status: state.status,
        section: state.section,
        companyId: state.companyId,
        snapshot: state.snapshot,
        respondentSession: state.respondentSession,
        generatedPin: state.generatedPin,
        respondentInvited: state.respondentInvited,
        failure: state.failure,
        passwordChanged: state.passwordChanged,
        dnaConfirmed: state.dnaConfirmed,
        vacancyFilterId: event.clearVacancy
            ? null
            : (event.vacancyId ?? state.vacancyFilterId),
        processFilter: event.clearProcess
            ? null
            : (event.processStatus ?? state.processFilter),
        affinityFilter: event.clearAffinity
            ? null
            : (event.affinity ?? state.affinityFilter),
        candidateReport: state.candidateReport,
        analysisRunning: state.analysisRunning,
      ),
    );
  }

  Future<void> _onAssessmentKind(
    TalentAssessmentKindSelected event,
    Emitter<TalentState> emit,
  ) async {
    final session = state.respondentSession;
    if (session != null) {
      emit(
        state.copyWith(
          respondentSession: RespondentSession(
            candidate: TalentCandidate(
              id: session.candidate.id,
              companyId: session.candidate.companyId,
              vacancyId: session.candidate.vacancyId,
              vacancyName: session.candidate.vacancyName,
              email: session.candidate.email,
              documentNumber: session.candidate.documentNumber,
              displayName: session.candidate.displayName,
              processStatus: session.candidate.processStatus,
              companyAffinity: session.candidate.companyAffinity,
              vacancyAffinity: session.candidate.vacancyAffinity,
              evaluationCompleted: session.candidate.evaluationCompleted,
              resultRequested: session.candidate.resultRequested,
              assessmentKind: event.kind,
              updatedAt: session.candidate.updatedAt,
            ),
            answers: session.answers,
            company: session.company,
          ),
        ),
      );
    }
    await _repository.saveAssessmentKind(
      candidateId: event.candidateId,
      kind: event.kind,
    );
  }

  Future<void> _onCandidateOpened(
    TalentCandidateOpened event,
    Emitter<TalentState> emit,
  ) async {
    final result = await _repository.loadCandidateReport(event.candidateId);
    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (report) {
        emit(state.copyWith(candidateReport: report, failure: null));
        final status = report.analysis.status;
        final needsAnalysis = report.candidate.evaluationCompleted &&
            (status == AffinityAnalysisStatus.none ||
                status == AffinityAnalysisStatus.failed ||
                status == AffinityAnalysisStatus.insufficientData);
        if (needsAnalysis) {
          add(TalentAffinityAnalysisRequested(report.candidate.id));
        } else {
          _pollAnalysis(report);
        }
      },
    );
  }

  Future<void> _onCandidateClosed(
    TalentCandidateClosed event,
    Emitter<TalentState> emit,
  ) async {
    _analysisPoll?.cancel();
    emit(state.copyWith(clearCandidateReport: true));
  }

  CandidateReport? _openReport(String candidateId) {
    final report = state.candidateReport;
    return report?.candidate.id == candidateId ? report : null;
  }

  CandidateReport _withAnalysis(CandidateReport report, AffinityAnalysis analysis) =>
      CandidateReport(
        candidate: report.candidate,
        answers: report.answers,
        company: report.company,
        vacancy: report.vacancy,
        analysis: analysis,
      );

  Future<void> _reloadAfterAnalysis(
    String candidateId,
    Emitter<TalentState> emit,
  ) async {
    final result = await _repository.loadCandidateReport(candidateId);
    result.fold((_) {}, (report) {
      if (_openReport(candidateId) != null) {
        emit(state.copyWith(candidateReport: report));
      }
    });
    if (state.companyId != null) add(TalentLoaded(state.companyId!));
  }

  Future<void> _onAnalysisRequested(
    TalentAffinityAnalysisRequested event,
    Emitter<TalentState> emit,
  ) async {
    final report = _openReport(event.candidateId);
    if (report == null || state.analysisRunning) return;
    _analysisPoll?.cancel();
    emit(
      state.copyWith(
        analysisRunning: true,
        candidateReport: _withAnalysis(
          report,
          const AffinityAnalysis(status: AffinityAnalysisStatus.pending),
        ),
      ),
    );
    final result = await _repository.requestAffinityAnalysis(event.candidateId);
    emit(state.copyWith(analysisRunning: false));
    await result.fold(
      (failure) async {
        final open = _openReport(event.candidateId);
        emit(
          state.copyWith(
            failure: failure,
            candidateReport: open == null
                ? null
                : _withAnalysis(open, report.analysis),
          ),
        );
      },
      (_) => _reloadAfterAnalysis(event.candidateId, emit),
    );
  }

  Future<void> _onAnalysisPolled(
    TalentAffinityAnalysisPolled event,
    Emitter<TalentState> emit,
  ) async {
    final report = _openReport(event.candidateId);
    if (report == null || state.analysisRunning) return;
    final result = await _repository.loadAffinityAnalysis(event.candidateId);
    await result.fold((_) async {}, (analysis) async {
      final open = _openReport(event.candidateId);
      if (open == null) return;
      if (analysis.isPending) {
        _pollAnalysis(_withAnalysis(open, analysis), event.attempt);
        return;
      }
      await _reloadAfterAnalysis(event.candidateId, emit);
    });
  }

  Future<void> _onCandidateUpdated(
    TalentCandidateUpdated event,
    Emitter<TalentState> emit,
  ) async {
    final result = await _repository.updateCandidate(
      candidateId: event.candidateId,
      displayName: event.displayName,
      documentNumber: event.documentNumber,
      vacancyId: event.vacancyId,
    );
    await result.fold(
      (failure) async => emit(state.copyWith(failure: failure)),
      (_) async {
        final report = await _repository.loadCandidateReport(event.candidateId);
        report.fold(
          (failure) => emit(state.copyWith(failure: failure)),
          (value) => emit(
            state.copyWith(
              candidateReport: value,
              candidateNotice: TalentCandidateNotice.updated,
              failure: null,
            ),
          ),
        );
        if (state.companyId != null) add(TalentLoaded(state.companyId!));
      },
    );
  }

  Future<void> _onCandidateDeleted(
    TalentCandidateDeleted event,
    Emitter<TalentState> emit,
  ) async {
    final result = await _repository.deleteCandidate(event.candidateId);
    await result.fold(
      (failure) async => emit(state.copyWith(failure: failure)),
      (_) async {
        emit(
          state.copyWith(
            clearCandidateReport: true,
            candidateNotice: TalentCandidateNotice.deleted,
            failure: null,
          ),
        );
        if (state.companyId != null) add(TalentLoaded(state.companyId!));
      },
    );
  }

  Future<void> _onDnaOptionDeleted(
    TalentDnaOptionDeleted event,
    Emitter<TalentState> emit,
  ) async {
    final result = await _repository.deleteDnaCatalogOption(
      type: event.type,
      label: event.label,
    );
    await result.fold(
      (failure) async => emit(state.copyWith(failure: failure)),
      (_) async {
        if (state.companyId != null) add(TalentLoaded(state.companyId!));
      },
    );
  }
}
