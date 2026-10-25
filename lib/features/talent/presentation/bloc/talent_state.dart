part of 'talent_bloc.dart';

enum TalentViewStatus { initial, loading, success, failure }

enum TalentCandidateNotice { updated, deleted }

class TalentState extends Equatable {
  const TalentState({
    this.status = TalentViewStatus.initial,
    this.section = TalentSection.dashboard,
    this.companyId,
    this.snapshot = const TalentSnapshot(),
    this.respondentSession,
    this.generatedPin,
    this.respondentInvited = false,
    this.failure,
    this.passwordChanged = false,
    this.dnaConfirmed = false,
    this.vacancyFilterId,
    this.processFilter,
    this.affinityFilter,
    this.candidateReport,
    this.candidateNotice,
    this.analysisRunning = false,
  });

  final TalentViewStatus status;
  final TalentSection section;
  final String? companyId;
  final TalentSnapshot snapshot;
  final RespondentSession? respondentSession;
  final String? generatedPin;
  final bool respondentInvited;
  final Failure? failure;
  final bool passwordChanged;
  final bool dnaConfirmed;
  final String? vacancyFilterId;
  final CandidateProcessStatus? processFilter;
  final AffinityLevel? affinityFilter;
  final CandidateReport? candidateReport;
  final TalentCandidateNotice? candidateNotice;
  final bool analysisRunning;

  List<TalentCandidate> get filteredCandidates {
    var items = snapshot.candidates;
    if (vacancyFilterId != null) {
      items = items.where((item) => item.vacancyId == vacancyFilterId).toList();
    }
    if (processFilter != null) {
      items = items.where((item) => item.processStatus == processFilter).toList();
    }
    if (affinityFilter != null) {
      items = items
          .where((item) => item.companyAffinity == affinityFilter)
          .toList();
    }
    return items;
  }

  TalentState copyWith({
    TalentViewStatus? status,
    TalentSection? section,
    String? companyId,
    TalentSnapshot? snapshot,
    RespondentSession? respondentSession,
    String? generatedPin,
    bool? respondentInvited,
    Failure? failure,
    bool? passwordChanged,
    bool? dnaConfirmed,
    String? vacancyFilterId,
    CandidateProcessStatus? processFilter,
    AffinityLevel? affinityFilter,
    CandidateReport? candidateReport,
    bool clearCandidateReport = false,
    TalentCandidateNotice? candidateNotice,
    bool? analysisRunning,
  }) => TalentState(
    status: status ?? this.status,
    section: section ?? this.section,
    companyId: companyId ?? this.companyId,
    snapshot: snapshot ?? this.snapshot,
    respondentSession: respondentSession ?? this.respondentSession,
    generatedPin: generatedPin,
    respondentInvited: respondentInvited ?? this.respondentInvited,
    failure: failure,
    passwordChanged: passwordChanged ?? this.passwordChanged,
    dnaConfirmed: dnaConfirmed ?? this.dnaConfirmed,
    vacancyFilterId: vacancyFilterId ?? this.vacancyFilterId,
    processFilter: processFilter ?? this.processFilter,
    affinityFilter: affinityFilter ?? this.affinityFilter,
    candidateReport: clearCandidateReport
        ? null
        : (candidateReport ?? this.candidateReport),
    candidateNotice: candidateNotice,
    analysisRunning: analysisRunning ?? this.analysisRunning,
  );

  @override
  List<Object?> get props => [
    status,
    section,
    companyId,
    snapshot,
    respondentSession,
    generatedPin,
    respondentInvited,
    failure,
    passwordChanged,
    dnaConfirmed,
    vacancyFilterId,
    processFilter,
    affinityFilter,
    candidateReport,
    candidateNotice,
    analysisRunning,
  ];
}
