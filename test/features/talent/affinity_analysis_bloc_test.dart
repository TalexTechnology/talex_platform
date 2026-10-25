import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talex_platform/core/error/failure.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/domain/repositories/talent_repository.dart';
import 'package:talex_platform/features/talent/presentation/bloc/talent_bloc.dart';

TalentCandidate _candidate({
  bool completed = true,
  AffinityLevel affinity = AffinityLevel.unknown,
}) => TalentCandidate(
  id: 'c1',
  companyId: 'co1',
  vacancyId: 'v1',
  vacancyName: 'Dev',
  email: 'ana@example.com',
  documentNumber: '123456',
  processStatus: completed
      ? CandidateProcessStatus.completed
      : CandidateProcessStatus.inProgress,
  companyAffinity: affinity,
  evaluationCompleted: completed,
  updatedAt: DateTime(2026),
);

const _completed = AffinityAnalysis(
  status: AffinityAnalysisStatus.completed,
  level: AffinityLevel.high,
  score: 81,
  summary: 'Comparte la preferencia por el trabajo colaborativo.',
);

class _FakeRepository implements TalentRepository {
  AffinityAnalysis stored = const AffinityAnalysis();
  int analysisRequests = 0;

  @override
  Future<Either<Failure, CandidateReport>> loadCandidateReport(
    String candidateId,
  ) async => Right(
    CandidateReport(
      candidate: _candidate(
        affinity: stored.hasResult ? stored.level : AffinityLevel.unknown,
      ),
      analysis: stored,
    ),
  );

  @override
  Future<Either<Failure, AffinityAnalysis>> loadAffinityAnalysis(
    String candidateId,
  ) async => Right(stored);

  @override
  Future<Either<Failure, AffinityAnalysis>> requestAffinityAnalysis(
    String candidateId,
  ) async {
    analysisRequests++;
    stored = _completed;
    return Right(stored);
  }

  @override
  Future<Either<Failure, TalentCandidate>> completeEvaluation(
    String candidateId, {
    String locale = 'es',
  }) async => Right(_candidate());

  @override
  Future<Either<Failure, TalentSnapshot>> loadCompany(String companyId) async =>
      Right(TalentSnapshot(candidates: [_candidate()]));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  test('completing the evaluation updates the session without reloading it', () async {
    final bloc = TalentBloc(repository: _FakeRepository());
    bloc.add(const TalentEvaluationCompleted('c1'));
    await _settle();
    expect(bloc.state.respondentSession?.candidate.evaluationCompleted, isTrue);
    expect(bloc.state.status, isNot(TalentViewStatus.loading));
    await bloc.close();
  });

  test('opening a failed analysis loads a fresh report', () async {
    final repository = _FakeRepository()
      ..stored = const AffinityAnalysis(status: AffinityAnalysisStatus.failed);
    final bloc = TalentBloc(repository: repository);
    bloc.add(const TalentCandidateOpened('c1'));
    await _settle();
    await _settle();
    expect(repository.analysisRequests, 1);
    expect(bloc.state.analysisRunning, isFalse);
    expect(bloc.state.candidateReport?.analysis, _completed);
    expect(bloc.state.candidateReport?.candidate.companyAffinity, AffinityLevel.high);
    await bloc.close();
  });

  test('choosing a section closes the candidate report', () async {
    final repository = _FakeRepository()..stored = _completed;
    final bloc = TalentBloc(repository: repository);
    bloc.add(const TalentCandidateOpened('c1'));
    await _settle();
    expect(bloc.state.candidateReport, isNotNull);

    bloc.add(const TalentSectionSelected(TalentSection.dashboard));
    await _settle();
    expect(bloc.state.section, TalentSection.dashboard);
    expect(bloc.state.candidateReport, isNull);
    await bloc.close();
  });

  test('opening an analysis blocked by missing data requests it again', () async {
    final repository = _FakeRepository()
      ..stored = const AffinityAnalysis(
        status: AffinityAnalysisStatus.insufficientData,
      );
    final bloc = TalentBloc(repository: repository);
    bloc.add(const TalentCandidateOpened('c1'));
    await _settle();
    await _settle();
    expect(repository.analysisRequests, 1);
    expect(bloc.state.candidateReport?.analysis, _completed);
    await bloc.close();
  });

  test('opening a finished report shows it without requesting again', () async {
    final repository = _FakeRepository()..stored = _completed;
    final bloc = TalentBloc(repository: repository);
    bloc.add(const TalentCandidateOpened('c1'));
    await _settle();
    expect(repository.analysisRequests, 0);
    expect(bloc.state.candidateReport?.analysis, _completed);
    await bloc.close();
  });

  test('opening an older completed evaluation requests its analysis', () async {
    final repository = _FakeRepository();
    final bloc = TalentBloc(repository: repository);
    bloc.add(const TalentCandidateOpened('c1'));
    await _settle();
    await _settle();
    expect(repository.analysisRequests, 1);
    expect(bloc.state.candidateReport?.analysis, _completed);
    await bloc.close();
  });

  test('loading the company analyzes unanalyzed evaluations only once', () async {
    final repository = _FakeRepository();
    final bloc = TalentBloc(repository: repository);
    bloc.add(const TalentLoaded('co1'));
    await _settle();
    await _settle();
    expect(repository.analysisRequests, 1);
    await bloc.close();
  });

  test('a pending analysis is refreshed until it finishes', () async {
    final repository = _FakeRepository()
      ..stored = const AffinityAnalysis(status: AffinityAnalysisStatus.pending);
    final bloc = TalentBloc(repository: repository);
    bloc.add(const TalentCandidateOpened('c1'));
    await _settle();
    expect(bloc.state.candidateReport?.analysis.isPending, isTrue);

    repository.stored = _completed;
    bloc.add(const TalentAffinityAnalysisPolled('c1', 1));
    await _settle();
    expect(bloc.state.candidateReport?.analysis, _completed);
    await bloc.close();
  });
}
