import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talex_platform/core/error/failure.dart';
import 'package:talex_platform/features/assistant/data/datasources/assistant_remote_data_source.dart';
import 'package:talex_platform/features/assistant/data/repositories/assistant_repository_impl.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_brief.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_message.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_reply.dart';
import 'package:talex_platform/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:talex_platform/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:talex_platform/features/assistant/presentation/bloc/assistant_event.dart';
import 'package:talex_platform/features/assistant/presentation/bloc/assistant_state.dart';
import 'package:talex_platform/features/assistant/presentation/brief/assistant_brief_builder.dart';
import 'package:talex_platform/features/invitations/domain/entities/invitation.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/presentation/bloc/talent_bloc.dart';

void main() {
  const brief = AssistantBrief(
    audience: AssistantAudience.company,
    locale: 'es',
    workspace: WorkspaceFacts(organization: 'Acme', activeVacancies: 1),
  );

  test(
    'brief uses real company records and ignores nothing that is not there',
    () {
      final built = AssistantBriefBuilder.company(
        status: TalentViewStatus.success,
        locale: 'es',
        now: DateTime(2026, 10, 19),
        snapshot: TalentSnapshot(
          profile: const CompanyProfile(
            id: 'c',
            name: 'Acme',
            values: 'Cuidado',
            culture: 'Clara',
            standoutPeople: 'Mentores',
          ),
          vacancies: [
            Vacancy(
              id: 'v',
              companyId: 'c',
              name: 'Diseño',
              status: VacancyStatus.active,
              createdAt: DateTime(2026, 1, 1),
              area: 'Producto',
            ),
          ],
          candidates: [
            TalentCandidate(
              id: 'p',
              companyId: 'c',
              vacancyId: 'v',
              vacancyName: 'Diseño',
              email: 'ana@acme.co',
              documentNumber: '1',
              processStatus: CandidateProcessStatus.completed,
              updatedAt: DateTime(2026, 10, 18),
              displayName: 'Ana',
              evaluationCompleted: true,
              companyAffinity: AffinityLevel.high,
            ),
          ],
        ),
      );
      final facts = built.workspace!;
      expect(facts.organization, 'Acme');
      expect(facts.hasDna, isTrue);
      expect(facts.activeVacancies, 1);
      expect(facts.vacancies.single.detail, 'Producto');
      expect(facts.readyToReview.single.label, 'Ana');
      expect(facts.highAffinity, 1);
    },
  );

  test(
    'workspace brief counts invitations without sample dashboard numbers',
    () {
      final built = AssistantBriefBuilder.workspace(
        locale: 'es',
        invitations: [
          Invitation(
            id: '1',
            personName: 'Ana',
            email: 'ana@acme.co',
            assessmentName: 'Afinidad',
            expiresAt: DateTime(2026, 11, 1),
            status: InvitationStatus.pending,
            createdAt: DateTime(2026, 10, 1),
          ),
        ],
      );
      expect(built.workspace!.invitationCount, 1);
      expect(built.workspace!.pendingInvitations, 1);
      expect(built.workspace!.activeVacancies, 0);
    },
  );

  test(
    'repository keeps the grounded answer when the model is unavailable',
    () async {
      final repository = AssistantRepositoryImpl(
        remote: _FailingRemote(),
        remoteBudget: const Duration(milliseconds: 20),
      );
      final result = await repository.reply(
        const AssistantRequest(question: '¿Cómo va el proceso?', brief: brief),
      );
      result.fold((failure) => fail(failure.message), (reply) {
        expect(reply.fromRemote, isFalse);
        expect(reply.markdown, contains('Acme'));
      });
    },
  );

  test('repository uses a remote rewrite when it arrives in time', () async {
    final repository = AssistantRepositoryImpl(
      remote: _FixedRemote('## Desde el modelo\n\nListo.'),
    );
    final result = await repository.reply(
      const AssistantRequest(question: '¿Cómo va el proceso?', brief: brief),
    );
    result.fold(
      (failure) => fail(failure.message),
      (reply) => expect(reply.markdown, contains('Desde el modelo')),
    );
  });

  test('bloc reveals one answer and ignores a duplicate send', () async {
    final gate = _Gate();
    final bloc = AssistantBloc(repository: gate);
    bloc.add(const AssistantMessageSent('¿Cómo va el proceso?', brief));
    bloc.add(const AssistantMessageSent('otra', brief));
    await _until(bloc, (state) => state.messages.length == 2);
    await Future<void>.delayed(Duration.zero);
    expect(gate.calls, 1);
    expect(
      bloc.state.messages.where(
        (message) => message.role == AssistantRole.user,
      ),
      hasLength(1),
    );
    gate.complete(
      const Right(AssistantReply(markdown: '## Listo\n\n**Acme**')),
    );
    await _until(bloc, (state) => state.phase == AssistantPhase.revealing);
    expect(bloc.state.messages.last.text, contains('Acme'));
    await bloc.close();
  });

  test('bloc keeps the visible prefix when a reveal is stopped', () async {
    final bloc = AssistantBloc(
      repository: _Script(
        (_) async =>
            const Right(AssistantReply(markdown: '## Respuesta larga')),
      ),
    );
    bloc.add(const AssistantMessageSent('hola', brief));
    await _until(bloc, (state) => state.phase == AssistantPhase.revealing);
    bloc.add(const AssistantGenerationCancelled(visible: '## Resp'));
    await _until(
      bloc,
      (state) => state.messages.last.status == AssistantMessageStatus.cancelled,
    );
    expect(bloc.state.messages.last.text, '## Resp');
    expect(bloc.state.phase, AssistantPhase.idle);
    await bloc.close();
  });

  test('empty model output becomes a failed message', () async {
    final bloc = AssistantBloc(
      repository: _Script(
        (_) async => const Right(AssistantReply(markdown: '   ')),
      ),
    );
    bloc.add(const AssistantMessageSent('hola', brief));
    await _until(bloc, (state) => state.failure == AssistantFailureKind.empty);
    expect(bloc.state.messages.last.status, AssistantMessageStatus.failed);
    await bloc.close();
  });
}

Future<void> _until(
  AssistantBloc bloc,
  bool Function(AssistantState state) match,
) async {
  if (match(bloc.state)) return;
  await bloc.stream.firstWhere(match).timeout(const Duration(seconds: 2));
}

class _Gate implements AssistantRepository {
  int calls = 0;
  final _result = Completer<Either<Failure, AssistantReply>>();

  void complete(Either<Failure, AssistantReply> value) {
    if (!_result.isCompleted) _result.complete(value);
  }

  @override
  Future<Either<Failure, AssistantReply>> reply(AssistantRequest request) {
    calls++;
    return _result.future;
  }
}

class _Script implements AssistantRepository {
  _Script(this._reply);
  final Future<Either<Failure, AssistantReply>> Function(
    AssistantRequest request,
  )
  _reply;

  @override
  Future<Either<Failure, AssistantReply>> reply(AssistantRequest request) =>
      _reply(request);
}

class _FixedRemote implements AssistantRemoteDataSource {
  _FixedRemote(this.text);
  final String text;

  @override
  Future<String> ask({
    required AssistantRequest request,
    required String reference,
    required Map<String, Object?> context,
  }) async => text;
}

class _FailingRemote implements AssistantRemoteDataSource {
  @override
  Future<String> ask({
    required AssistantRequest request,
    required String reference,
    required Map<String, Object?> context,
  }) async {
    throw const AssistantRemoteException('unavailable', permanent: false);
  }
}
