import 'package:talex_platform/features/assistant/domain/entities/assistant_brief.dart';
import 'package:talex_platform/features/invitations/domain/entities/invitation.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/domain/services/dna_catalog.dart';
import 'package:talex_platform/features/talent/domain/services/company_insights.dart';
import 'package:talex_platform/features/talent/presentation/bloc/talent_bloc.dart';

/// Maps data the user can already see into the assistant brief.
///
/// It does not read the network and does not use the sample numbers shown on
/// the generic dashboard.
abstract final class AssistantBriefBuilder {
  static AssistantBrief admin(String locale) =>
      AssistantBrief(audience: AssistantAudience.admin, locale: locale);

  static AssistantBrief workspace({
    required List<Invitation> invitations,
    required String locale,
  }) {
    final pending = invitations
        .where(
          (item) =>
              item.status == InvitationStatus.pending ||
              item.status == InvitationStatus.inProgress,
        )
        .length;
    return AssistantBrief(
      audience: AssistantAudience.workspace,
      locale: locale,
      workspace: WorkspaceFacts(
        invitationCount: invitations.length,
        pendingInvitations: pending,
      ),
    );
  }

  static AssistantBrief company({
    required TalentSnapshot snapshot,
    required TalentViewStatus status,
    required String locale,
    DateTime? now,
  }) {
    final profile = snapshot.profile;
    final insights = CompanyInsights(snapshot, now: now);
    final vacancies = [...snapshot.vacancies]
      ..sort((a, b) {
        if (a.status != b.status) {
          return a.status == VacancyStatus.active ? -1 : 1;
        }
        return a.name.compareTo(b.name);
      });
    return AssistantBrief(
      audience: AssistantAudience.company,
      locale: locale,
      workspace: WorkspaceFacts(
        organization: profile?.name,
        ready: status == TalentViewStatus.success || profile != null,
        hasDna: profile?.hasCompanyDna ?? false,
        dnaSummary: _dna(profile),
        activeVacancies: snapshot.activeVacancies,
        closedVacancies: snapshot.closedVacancies,
        pending: snapshot.pendingAssessments,
        completed: snapshot.completedAssessments,
        highAffinity: snapshot.highCount,
        mediumAffinity: snapshot.mediumCount,
        lowAffinity: snapshot.lowCount,
        teamCount: snapshot.team.length,
        vacancies: [
          for (final vacancy in vacancies.take(8))
            AssistantVacancyFact(
              name: vacancy.name,
              active: vacancy.status == VacancyStatus.active,
              detail: _detail(vacancy),
            ),
        ],
        readyToReview: [
          for (final person in insights.readyToReview.take(8))
            AssistantPersonFact(
              label: _label(person),
              vacancy: person.vacancyName,
            ),
        ],
        stalled: [
          for (final person in insights.stalled.take(8))
            AssistantPersonFact(
              label: _label(person),
              vacancy: person.vacancyName,
            ),
        ],
        values: parseDnaList(profile?.values),
        culture: parseDnaList(profile?.culture),
        standout: parseDnaList(profile?.standoutPeople),
      ),
    );
  }

  static String? _dna(CompanyProfile? profile) {
    if (profile == null) return null;
    final parts = [profile.values, profile.culture, profile.standoutPeople]
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty);
    final summary = parts.take(3).join(' · ');
    if (summary.isEmpty) return null;
    return summary.length > 180 ? summary.substring(0, 180) : summary;
  }

  static String? _detail(Vacancy vacancy) {
    final parts = [vacancy.area, vacancy.seniority, vacancy.workMode]
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty);
    final detail = parts.take(2).join(' · ');
    return detail.isEmpty ? null : detail;
  }

  static String _label(TalentCandidate person) {
    final name = person.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return person.email;
  }
}
