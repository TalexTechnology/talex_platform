part of 'talent_bloc.dart';

enum TalentSection { dashboard, vacancies, candidates, reports, team, profile, settings }

sealed class TalentEvent extends Equatable {
  const TalentEvent();
  @override
  List<Object?> get props => [];
}

class TalentLoaded extends TalentEvent {
  const TalentLoaded(this.companyId);
  final String companyId;
  @override
  List<Object?> get props => [companyId];
}

class TalentSectionSelected extends TalentEvent {
  const TalentSectionSelected(this.section);
  final TalentSection section;
  @override
  List<Object?> get props => [section];
}

class TalentProfileSaved extends TalentEvent {
  const TalentProfileSaved(this.profile);
  final CompanyProfile profile;
  @override
  List<Object?> get props => [profile];
}

class TalentVacancyCreated extends TalentEvent {
  const TalentVacancyCreated(this.vacancy);
  final Vacancy vacancy;
  @override
  List<Object?> get props => [vacancy];
}

class TalentRespondentCreated extends TalentEvent {
  const TalentRespondentCreated({
    required this.companyId,
    required this.vacancyId,
    required this.email,
    required this.documentNumber,
    this.displayName,
  });
  final String companyId, vacancyId, email, documentNumber;
  final String? displayName;
  @override
  List<Object?> get props => [companyId, vacancyId, email, documentNumber];
}

class TalentRecruiterInvited extends TalentEvent {
  const TalentRecruiterInvited({
    required this.companyId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.role = UserRole.recruiter,
  });
  final String companyId, email, firstName, lastName;
  final UserRole role;
  @override
  List<Object?> get props => [companyId, email, role];
}

class TalentCandidateStatusUpdated extends TalentEvent {
  const TalentCandidateStatusUpdated({
    required this.candidateId,
    required this.status,
  });
  final String candidateId;
  final CandidateProcessStatus status;
  @override
  List<Object?> get props => [candidateId, status];
}

class TalentRespondentSessionLoaded extends TalentEvent {
  const TalentRespondentSessionLoaded();
}

class TalentAnswerSaved extends TalentEvent {
  const TalentAnswerSaved({
    required this.candidateId,
    required this.questionId,
    required this.value,
  });
  final String candidateId, questionId;
  final int value;
  @override
  List<Object?> get props => [candidateId, questionId, value];
}

class TalentEvaluationCompleted extends TalentEvent {
  const TalentEvaluationCompleted(this.candidateId, {this.locale = 'es'});
  final String candidateId;
  final String locale;
  @override
  List<Object?> get props => [candidateId, locale];
}

class TalentAssessmentKindSelected extends TalentEvent {
  const TalentAssessmentKindSelected({
    required this.candidateId,
    required this.kind,
  });
  final String candidateId;
  final AssessmentKind kind;
  @override
  List<Object?> get props => [candidateId, kind];
}

class TalentCandidateOpened extends TalentEvent {
  const TalentCandidateOpened(this.candidateId);
  final String candidateId;
  @override
  List<Object?> get props => [candidateId];
}

class TalentCandidateClosed extends TalentEvent {
  const TalentCandidateClosed();
}

class TalentAffinityAnalysisRequested extends TalentEvent {
  const TalentAffinityAnalysisRequested(this.candidateId);
  final String candidateId;
  @override
  List<Object?> get props => [candidateId];
}

class TalentAffinityAnalysisPolled extends TalentEvent {
  const TalentAffinityAnalysisPolled(this.candidateId, this.attempt);
  final String candidateId;
  final int attempt;
  @override
  List<Object?> get props => [candidateId, attempt];
}

class TalentCandidateUpdated extends TalentEvent {
  const TalentCandidateUpdated({
    required this.candidateId,
    required this.displayName,
    required this.documentNumber,
    required this.vacancyId,
  });
  final String candidateId, displayName, documentNumber, vacancyId;
  @override
  List<Object?> get props => [candidateId, displayName, documentNumber, vacancyId];
}

class TalentCandidateDeleted extends TalentEvent {
  const TalentCandidateDeleted(this.candidateId);
  final String candidateId;
  @override
  List<Object?> get props => [candidateId];
}

class TalentPasswordChanged extends TalentEvent {
  const TalentPasswordChanged(this.password);
  final String password;
  @override
  List<Object?> get props => [password];
}

class TalentSurveyResultRequested extends TalentEvent {
  const TalentSurveyResultRequested(this.candidateId);
  final String candidateId;
  @override
  List<Object?> get props => [candidateId];
}

class TalentCompanyDnaConfirmed extends TalentEvent {
  const TalentCompanyDnaConfirmed(this.profile);
  final CompanyProfile profile;
  @override
  List<Object?> get props => [profile];
}

class TalentDnaOptionDeleted extends TalentEvent {
  const TalentDnaOptionDeleted({required this.type, required this.label});
  final String type, label;
  @override
  List<Object?> get props => [type, label];
}

class TalentFilterChanged extends TalentEvent {
  const TalentFilterChanged({
    this.vacancyId,
    this.processStatus,
    this.affinity,
    this.clearVacancy = false,
    this.clearProcess = false,
    this.clearAffinity = false,
  });
  final String? vacancyId;
  final CandidateProcessStatus? processStatus;
  final AffinityLevel? affinity;
  final bool clearVacancy;
  final bool clearProcess;
  final bool clearAffinity;
  @override
  List<Object?> get props => [
    vacancyId,
    processStatus,
    affinity,
    clearVacancy,
    clearProcess,
    clearAffinity,
  ];
}
