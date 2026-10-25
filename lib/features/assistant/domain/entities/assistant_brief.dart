import 'package:equatable/equatable.dart';

enum AssistantAudience { admin, company, workspace }

class AssistantVacancyFact extends Equatable {
  const AssistantVacancyFact({
    required this.name,
    required this.active,
    this.detail,
  });

  final String name;
  final bool active;
  final String? detail;

  @override
  List<Object?> get props => [name, active, detail];
}

class AssistantPersonFact extends Equatable {
  const AssistantPersonFact({required this.label, required this.vacancy});

  final String label;
  final String vacancy;

  @override
  List<Object?> get props => [label, vacancy];
}

class WorkspaceFacts extends Equatable {
  const WorkspaceFacts({
    this.organization,
    this.ready = true,
    this.hasDna = false,
    this.dnaSummary,
    this.activeVacancies = 0,
    this.closedVacancies = 0,
    this.pending = 0,
    this.completed = 0,
    this.highAffinity = 0,
    this.mediumAffinity = 0,
    this.lowAffinity = 0,
    this.teamCount = 0,
    this.vacancies = const [],
    this.readyToReview = const [],
    this.stalled = const [],
    this.invitationCount,
    this.pendingInvitations,
    this.values = const [],
    this.culture = const [],
    this.standout = const [],
  });

  final String? organization;
  final bool ready;
  final bool hasDna;
  final String? dnaSummary;
  final int activeVacancies;
  final int closedVacancies;
  final int pending;
  final int completed;
  final int highAffinity;
  final int mediumAffinity;
  final int lowAffinity;
  final int teamCount;
  final List<AssistantVacancyFact> vacancies;
  final List<AssistantPersonFact> readyToReview;
  final List<AssistantPersonFact> stalled;
  final int? invitationCount;
  final int? pendingInvitations;
  final List<String> values;
  final List<String> culture;
  final List<String> standout;

  @override
  List<Object?> get props => [
    organization,
    ready,
    hasDna,
    dnaSummary,
    activeVacancies,
    closedVacancies,
    pending,
    completed,
    highAffinity,
    mediumAffinity,
    lowAffinity,
    teamCount,
    vacancies,
    readyToReview,
    stalled,
    invitationCount,
    pendingInvitations,
    values,
    culture,
    standout,
  ];
}

class AssistantBrief extends Equatable {
  const AssistantBrief({
    required this.audience,
    required this.locale,
    this.workspace,
  });

  final AssistantAudience audience;
  final String locale;
  final WorkspaceFacts? workspace;

  bool get english => locale.toLowerCase().startsWith('en');

  @override
  List<Object?> get props => [audience, locale, workspace];
}
