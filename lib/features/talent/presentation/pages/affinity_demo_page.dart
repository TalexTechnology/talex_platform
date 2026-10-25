import 'package:flutter/material.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/presentation/pages/respondent_shell.dart';
import 'package:talex_platform/l10n/l10n.dart';

// Demo público de la encuesta de afinidad (/afinidad/demo): la pantalla real
// del candidato con datos de ejemplo. Se puede completar entera; no guarda
// nada. "Cerrar sesión" vuelve a empezar.
class AffinityDemoPage extends StatefulWidget {
  const AffinityDemoPage({super.key});

  @override
  State<AffinityDemoPage> createState() => _AffinityDemoPageState();
}

class _AffinityDemoPageState extends State<AffinityDemoPage> {
  var _run = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RespondentShell(
      key: ValueKey(_run),
      mustChangePassword: false,
      onDemoSignOut: () => setState(() => _run++),
      demo: RespondentSession(
        company: CompanyProfile(
          id: 'demo',
          name: l10n.affinityDemoCompany,
          description: l10n.affinityDemoCompanyDescription,
        ),
        candidate: TalentCandidate(
          id: 'demo',
          companyId: 'demo',
          vacancyId: 'demo',
          vacancyName: l10n.affinityDemoVacancy,
          email: 'demo@talex.com.co',
          documentNumber: '',
          displayName: l10n.affinityDemoCandidate,
          processStatus: CandidateProcessStatus.pending,
          assessmentKind: AssessmentKind.affinity,
          updatedAt: DateTime(2026),
        ),
      ),
    );
  }
}
