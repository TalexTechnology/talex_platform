import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:talex_platform/core/error/failure.dart';
import 'package:talex_platform/features/admin/domain/entities/admin_entities.dart';
import 'package:talex_platform/features/admin/domain/repositories/admin_repository.dart';
import 'package:talex_platform/features/assistant/data/datasources/assistant_remote_data_source.dart';
import 'package:talex_platform/features/assistant/data/services/command_center_answerer.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_brief.dart';
import 'package:talex_platform/features/assistant/domain/entities/assistant_reply.dart';
import 'package:talex_platform/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:talex_platform/features/assistant/domain/services/assistant_composer.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  AssistantRepositoryImpl({
    AdminRepository? adminRepository,
    AdminRepository? Function()? readAdminRepository,
    AssistantRemoteDataSource? remote,
    this.remoteEnabled = true,
    this.remoteBudget = const Duration(seconds: 10),
  }) : _readAdminRepository = readAdminRepository ?? (() => adminRepository),
       _remote = remote;

  final AdminRepository? Function() _readAdminRepository;
  final AssistantRemoteDataSource? _remote;
  final bool remoteEnabled;

  /// How long the grounded answer may wait for a model rewrite.
  ///
  /// The workspace answer already exists before this call. If the model is
  /// slow, unavailable, or not deployed, the chat shows that answer instead
  /// of holding the conversation.
  final Duration remoteBudget;
  bool _remoteDisabled = false;

  @override
  Future<Either<Failure, AssistantReply>> reply(
    AssistantRequest request,
  ) async {
    try {
      final prepared = await _reference(
        request,
      ).timeout(const Duration(seconds: 15));
      return await prepared.fold<Future<Either<Failure, AssistantReply>>>(
        (failure) async => Left(failure),
        (preparedReply) async {
          if (preparedReply.keepLocal) {
            return Right(
              AssistantReply(
                markdown: preparedReply.markdown,
                edit: preparedReply.edit,
              ),
            );
          }
          final remoteText = await _remoteText(
            request: request,
            reference: preparedReply.markdown,
            context: preparedReply.context,
          );
          final markdown = _unwrap(remoteText ?? preparedReply.markdown);
          if (markdown.isEmpty) {
            return const Left(AssistantFailure(AssistantFailureKind.empty));
          }
          return Right(
            AssistantReply(markdown: markdown, fromRemote: remoteText != null),
          );
        },
      );
    } on TimeoutException {
      return const Left(AssistantFailure(AssistantFailureKind.timeout));
    } catch (_) {
      return const Left(AssistantFailure(AssistantFailureKind.unexpected));
    }
  }

  Future<Either<Failure, _PreparedReply>> _reference(
    AssistantRequest request,
  ) async {
    if (request.brief.audience == AssistantAudience.admin) {
      return _adminReference(request);
    }
    final plan = AssistantComposer.plan(request);
    final markdown = plan.markdown.trim();
    if (markdown.isEmpty) {
      return const Left(AssistantFailure(AssistantFailureKind.empty));
    }
    return Right(
      _PreparedReply(
        markdown: markdown,
        context: _workspaceContext(request.brief),
        edit: plan.edit,
        keepLocal: plan.keepLocal,
      ),
    );
  }

  Future<Either<Failure, _PreparedReply>> _adminReference(
    AssistantRequest request,
  ) async {
    final admin = _readAdminRepository();
    if (admin == null) {
      return const Left(AssistantFailure(AssistantFailureKind.unexpected));
    }
    final dashboard = await admin.getDashboard();
    final companies = await admin.getCompanies(query: '');
    final deals = await admin.getDeals(query: '');
    return dashboard.fold(
      (_) => const Left(AssistantFailure(AssistantFailureKind.unavailable)),
      (data) => companies.fold(
        (_) => const Left(AssistantFailure(AssistantFailureKind.unavailable)),
        (companyList) => deals.fold(
          (_) => const Left(AssistantFailure(AssistantFailureKind.unavailable)),
          (dealList) {
            final markdown = CommandCenterAnswerer.present(
              question: request.question,
              locale: request.brief.locale,
              metrics: data.metrics,
              companies: companyList,
              deals: dealList,
              activity: data.activity,
              alerts: data.alerts,
            ).trim();
            if (markdown.isEmpty) {
              return const Left(AssistantFailure(AssistantFailureKind.empty));
            }
            return Right(
              _PreparedReply(
                markdown: markdown,
                context: _adminContext(
                  metrics: data.metrics,
                  companies: companyList,
                  deals: dealList,
                  alerts: data.alerts,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<String?> _remoteText({
    required AssistantRequest request,
    required String reference,
    required Map<String, Object?> context,
  }) async {
    final remote = _remote;
    if (!remoteEnabled || remote == null || _remoteDisabled) return null;
    try {
      final text = await remote
          .ask(request: request, reference: reference, context: context)
          .timeout(remoteBudget);
      final clean = text.trim();
      if (clean.isEmpty) return null;
      return clean.length > 12000 ? clean.substring(0, 12000) : clean;
    } on AssistantRemoteException catch (error) {
      if (error.permanent) _remoteDisabled = true;
      return null;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, Object?> _workspaceContext(AssistantBrief brief) {
    final facts = brief.workspace;
    if (facts == null) {
      return {'audience': brief.audience.name, 'locale': brief.locale};
    }
    return {
      'audience': brief.audience.name,
      'locale': brief.locale,
      'organization': facts.organization,
      'dataReady': facts.ready,
      'hasCompanyDna': facts.hasDna,
      'activeVacancies': facts.activeVacancies,
      'closedVacancies': facts.closedVacancies,
      'pending': facts.pending,
      'completedEvaluations': facts.completed,
      'affinity': {
        'high': facts.highAffinity,
        'medium': facts.mediumAffinity,
        'low': facts.lowAffinity,
      },
      'teamCount': facts.teamCount,
      'vacancies': [
        for (final vacancy in facts.vacancies)
          {
            'name': vacancy.name,
            'active': vacancy.active,
            'detail': vacancy.detail,
          },
      ],
      'readyToReview': [
        for (final person in facts.readyToReview)
          {'label': person.label, 'vacancy': person.vacancy},
      ],
      'stalled': [
        for (final person in facts.stalled)
          {'label': person.label, 'vacancy': person.vacancy},
      ],
      'invitationCount': facts.invitationCount,
      'pendingInvitations': facts.pendingInvitations,
    };
  }

  Map<String, Object?> _adminContext({
    required AdminMetrics metrics,
    required List<Company> companies,
    required List<Deal> deals,
    required List<AdminAlert> alerts,
  }) {
    final openDeals = deals.where((deal) => deal.stage != DealStage.client);
    return {
      'audience': AssistantAudience.admin.name,
      'metrics': {
        'totalCompanies': metrics.totalCompanies,
        'activeCompanies': metrics.activeCompanies,
        'evaluatedPeople': metrics.evaluatedPeople,
        'completedEvaluations': metrics.completedEvaluations,
        'affinitiesDetected': metrics.affinitiesDetected,
        'companiesAtRisk': metrics.companiesAtRisk,
        'periodSales': metrics.periodSales,
        'mrr': metrics.mrr,
      },
      'companies': [
        for (final company in companies.take(20))
          {
            'name': company.name,
            'status': company.status.name,
            'completedEvaluations': company.completedEvaluations,
          },
      ],
      'openDeals': openDeals.length,
      'alerts': [
        for (final alert in alerts.take(8))
          {
            'title': alert.title,
            'priority': alert.priority.name,
            'description': alert.description,
          },
      ],
    };
  }

  String _unwrap(String text) {
    final trimmed = text.trim();
    final fence = RegExp(r'^```(?:markdown|md)?\s*([\s\S]*?)\s*```$');
    final match = fence.firstMatch(trimmed);
    if (match == null) return trimmed;
    return match.group(1)?.trim() ?? trimmed;
  }
}

class _PreparedReply {
  const _PreparedReply({
    required this.markdown,
    required this.context,
    this.edit,
    this.keepLocal = false,
  });

  final String markdown;
  final Map<String, Object?> context;
  final CompanyAnswerEdit? edit;
  final bool keepLocal;
}
