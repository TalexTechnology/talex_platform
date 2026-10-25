import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:talex_platform/core/auth/user_role.dart';
import 'package:talex_platform/core/data/http_remote_database.dart';
import 'package:talex_platform/core/data/remote_database.dart';
import 'package:talex_platform/core/error/exceptions.dart';
import 'package:talex_platform/core/supabase/supabase_gateway.dart';
import 'package:talex_platform/features/talent/data/datasources/talent_data_source.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/domain/services/dna_catalog.dart';
import 'package:talex_platform/features/talent/domain/services/pin_hasher.dart';
import 'package:talex_platform/features/talent/domain/talent_error_codes.dart';

final class SupabaseTalentDataSource implements TalentDataSource {
  SupabaseTalentDataSource(
    this._auth,
    this._storage,
    this._functions, {
    RemoteDatabase? database,
  }) : _db = database ?? HttpRemoteDatabase();

  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  final RemoteDatabase _db;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const ServerException(TalentErrorCodes.needSignIn);
    return uid;
  }

  Future<Map<String, dynamic>> _orgRow(String id) async {
    if (isUuid(id)) {
      final row = await _db
          .from('organizations')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row != null) return row;
    }
    final row = await _db
        .from('organizations')
        .select()
        .eq('firebase_id', id)
        .maybeSingle();
    if (row == null) {
      throw const ServerException(TalentErrorCodes.companyNotFound);
    }
    return row;
  }

  Future<Map<String, dynamic>> _applicationRow(String id) async {
    if (isUuid(id)) {
      final row = await _db
          .from('applications')
          .select('*, persons(*)')
          .eq('id', id)
          .maybeSingle();
      if (row != null) return row;
    }
    final row = await _db
        .from('applications')
        .select('*, persons(*)')
        .eq('firebase_candidate_id', id)
        .maybeSingle();
    if (row == null) {
      throw const ServerException(TalentErrorCodes.assessmentMissing);
    }
    return row;
  }

  Future<Map<String, dynamic>?> _cultureFor(String organizationId) async {
    try {
      final survey = await _db.rpc(
        'organization_survey_culture',
        params: {'p_organization_id': organizationId},
      );
      if (survey is Map &&
          ((survey['respondentCount'] as num?) ?? 0).toInt() > 0) {
        return Map<String, dynamic>.from(survey);
      }
    } on Object {
      // Fall back to the last stored snapshot.
    }
    return _db
        .from('organization_culture_versions')
        .select()
        .eq('organization_id', organizationId)
        .eq('is_current', true)
        .maybeSingle();
  }

  CompanyProfile _companyProfile(
    Map<String, dynamic> org, [
    Map<String, dynamic>? culture,
    List<DnaCatalogEntry> catalog = const [],
  ]) {
    List<String> list(Object? value) => [
      if (value is List)
        for (final item in value)
          if ('$item'.trim().isNotEmpty) '$item'.trim(),
    ];
    return CompanyProfile(
      id: publicEntityId(org),
      name: (org['name'] as String?) ?? 'Empresa',
      nit: org['nit'] as String?,
      logoUrl: org['logo_url'] as String?,
      sector: org['sector'] as String?,
      size: org['size_label'] as String?,
      city: org['city'] as String?,
      country: org['country'] as String?,
      region: org['region'] as String?,
      website: org['website'] as String?,
      description: org['description'] as String?,
      values: joinDnaList(list(culture?['values_list'])),
      culture: joinDnaList(list(culture?['culture_list'])),
      standoutPeople: joinDnaList(list(culture?['standout_list'])),
      soughtCharacteristics: culture?['sought_characteristics'] as String?,
      customValues: catalog
          .where((item) => item.type == DnaCatalogType.values)
          .map((item) => item.labelEs)
          .toList(),
      customCulture: catalog
          .where((item) => item.type == DnaCatalogType.culture)
          .map((item) => item.labelEs)
          .toList(),
      customStandout: catalog
          .where((item) => item.type == DnaCatalogType.standout)
          .map((item) => item.labelEs)
          .toList(),
      customAreas: catalog
          .where((item) => item.type == DnaCatalogType.area)
          .map((item) => item.labelEs)
          .toList(),
    );
  }

  Vacancy _vacancy(Map<String, dynamic> row) {
    return Vacancy(
      id: publicEntityId(row),
      companyId: '${row['organization_id']}',
      name: (row['name'] as String?) ?? '',
      status: row['status'] == VacancyStatus.closed.name
          ? VacancyStatus.closed
          : VacancyStatus.active,
      createdAt: parseSupabaseDate(row['created_at']),
      area: row['area'] as String?,
      description: row['description'] as String?,
      city: row['city'] as String?,
      country: row['country'] as String?,
      region: row['region'] as String?,
      workMode: row['work_mode'] as String?,
      contractType: row['contract_type'] as String?,
      seniority: row['seniority'] as String?,
      roleProfile: row['role_profile'] as String?,
    );
  }

  TalentCandidate _candidate(Map<String, dynamic> row) {
    final person = row['persons'];
    final personMap = person is Map<String, dynamic>
        ? person
        : person is Map
        ? Map<String, dynamic>.from(person)
        : const <String, dynamic>{};
    return TalentCandidate(
      id: publicEntityId(row, firebaseKey: 'firebase_candidate_id'),
      companyId: publicEntityId(
        {'id': row['organization_id'], 'firebase_id': row['organization_firebase_id']},
      ),
      vacancyId: '${row['vacancy_id'] ?? ''}',
      vacancyName: (row['vacancy_name'] as String?) ?? '',
      email: (personMap['email'] as String?) ?? '',
      documentNumber: (personMap['document_number'] as String?) ?? '',
      displayName: personMap['display_name'] as String?,
      processStatus: CandidateProcessStatus.values.firstWhere(
        (item) => item.name == row['process_status'],
        orElse: () => CandidateProcessStatus.pending,
      ),
      companyAffinity: AffinityLevel.values.firstWhere(
        (item) => item.name == row['company_affinity'],
        orElse: () => AffinityLevel.unknown,
      ),
      vacancyAffinity: AffinityLevel.values.firstWhere(
        (item) => item.name == row['vacancy_affinity'],
        orElse: () => AffinityLevel.unknown,
      ),
      evaluationCompleted: row['evaluation_completed'] == true,
      resultRequested: row['result_requested'] == true,
      assessmentKind: AssessmentKind.values
          .where((item) => item.name == row['assessment_kind'])
          .firstOrNull,
      affinityAnalyzed: row['affinity_analyzed'] == true,
      updatedAt: parseSupabaseDate(row['updated_at']),
    );
  }

  Future<List<DnaCatalogEntry>> _catalog() async {
    try {
      final rows = await _db
          .from('dna_catalog_entries')
          .select('type, label_es, label_en');
      final items = [
        for (final row in rows)
          DnaCatalogEntry(
            type: '${row['type'] ?? ''}',
            labelEs: '${row['label_es'] ?? ''}',
            labelEn: row['label_en'] as String?,
          ),
      ].where((item) => item.type.isNotEmpty && item.labelEs.isNotEmpty);
      if (items.isNotEmpty) return items.toList();
    } on Object {
      // Fall through to the compiled catalog.
    }
    return [
      for (final item in allDnaPresets)
        DnaCatalogEntry(type: item.type, labelEs: item.es, labelEn: item.en),
    ];
  }

  Future<String?> _uploadLogo(String companyId, Uint8List bytes, String? type) async {
    try {
      final ref = _storage.ref('company_logos/$companyId');
      await ref
          .putData(bytes, SettableMetadata(contentType: type ?? 'image/png'))
          .timeout(const Duration(seconds: 15));
      return await ref.getDownloadURL().timeout(const Duration(seconds: 8));
    } on Object {
      return null;
    }
  }

  Future<void> _requestAffinityAnalysis(String candidateId) async {
    try {
      await _functions
          .httpsCallable(
            'analyzeCandidateAffinity',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
          )
          .call({'candidateId': candidateId});
    } on Object {
      // The report can be requested again from the candidate screen.
    }
  }

  @override
  Future<TalentSnapshot> loadCompany(String companyId) => guardSupabase(() async {
    final org = await _orgRow(companyId);
    if (org['archived'] == true ||
        org['status'] == 'inactive' ||
        org['status'] == 'suspended') {
      throw const ServerException(TalentErrorCodes.companyDisabled);
    }
    final orgId = org['id'];
    final culture = await _cultureFor('$orgId');
    final vacancies = List<Map<String, dynamic>>.from(
      await _db.from('vacancies').select().eq('organization_id', orgId),
    );
    final applications = List<Map<String, dynamic>>.from(
      await _db
          .from('applications')
          .select('*, persons(*)')
          .eq('organization_id', orgId),
    );
    final invites = List<Map<String, dynamic>>.from(
      await _db.from('activation_invites').select().eq('organization_id', orgId),
    );
    final catalog = await _catalog();
    return TalentSnapshot(
      profile: _companyProfile(org, culture, catalog),
      vacancies: [for (final row in vacancies) _vacancy(row)],
      candidates: [
        for (final row in applications)
          _candidate({
            ...row,
            'organization_firebase_id': org['firebase_id'],
          }),
      ],
      dnaCatalog: catalog,
      team: [
        for (final row in invites)
          if (isCompanyStaffInvite(
            kind: row['kind'] as String?,
            role: row['role'] as String?,
          ))
            TeamMember(
              email: (row['email'] as String?) ?? '',
              role: (row['role'] as String?) ?? UserRole.recruiter.value,
              inviteUsed: row['used'] == true,
              displayName: [
                row['first_name'],
                row['last_name'],
              ].whereType<String>().join(' ').trim(),
            ),
      ],
    );
  });

  @override
  Future<void> saveCompanyProfile(CompanyProfile profile) =>
      guardSupabase(() async {
        await _db.rpc(
          'save_organization_profile',
          params: {
            'p_organization_id': profile.id,
            'p_name': profile.name,
            'p_nit': profile.nit,
            'p_logo_url': profile.logoUrl,
            'p_sector': profile.sector,
            'p_size': profile.size,
            'p_city': profile.city,
            'p_country': profile.country,
            'p_region': profile.region,
            'p_website': profile.website,
            'p_description': profile.description,
            'p_values': parseDnaList(profile.values),
            'p_culture': parseDnaList(profile.culture),
            'p_standout': parseDnaList(profile.standoutPeople),
            'p_sought': profile.soughtCharacteristics,
          },
        );
      });

  @override
  Future<void> createVacancy(Vacancy vacancy) => guardSupabase(() async {
    final org = await _orgRow(vacancy.companyId);
    await _db.from('vacancies').insert({
      'organization_id': org['id'],
      'name': vacancy.name.trim(),
      'status': VacancyStatus.active.name,
      'area': vacancy.area,
      'description': vacancy.description,
      'city': vacancy.city,
      'country': vacancy.country,
      'region': vacancy.region,
      'work_mode': vacancy.workMode,
      'contract_type': vacancy.contractType,
      'seniority': vacancy.seniority,
      'role_profile': vacancy.roleProfile,
    });
  });

  @override
  Future<String> createRespondent({
    required String companyId,
    required String vacancyId,
    required String email,
    required String documentNumber,
    String? displayName,
  }) => guardSupabase(() async {
    final result = await _db.rpc(
      'create_respondent_application',
      params: {
        'p_organization_id': companyId,
        'p_vacancy_id': vacancyId,
        'p_email': email,
        'p_document_number': documentNumber,
        'p_display_name': displayName,
        'p_token': '',
      },
    );
    final data = Map<String, dynamic>.from(result as Map);
    return '${data['token']}';
  });

  @override
  Future<String> provisionCompany({
    required CompanyProfile profile,
    required String recruiterFirstName,
    required String recruiterLastName,
    required String recruiterEmail,
    Uint8List? logoBytes,
    String? logoContentType,
  }) => guardSupabase(() async {
    final pin = PinHasher.generatePin();
    final result = await _db.rpc(
      'provision_organization',
      params: {
        'p_name': profile.name,
        'p_recruiter_email': recruiterEmail,
        'p_recruiter_first_name': recruiterFirstName,
        'p_recruiter_last_name': recruiterLastName,
        'p_pin': pin,
        'p_nit': profile.nit,
        'p_logo_url': profile.logoUrl,
        'p_sector': profile.sector,
        'p_size': profile.size,
        'p_city': profile.city,
        'p_country': profile.country,
        'p_region': profile.region,
        'p_website': profile.website,
        'p_description': profile.description,
        'p_values': parseDnaList(profile.values),
        'p_culture': parseDnaList(profile.culture),
        'p_standout': parseDnaList(profile.standoutPeople),
        'p_sought': profile.soughtCharacteristics,
      },
    );
    final data = Map<String, dynamic>.from(result as Map);
    final organizationId = '${data['organizationId']}';
    if (logoBytes != null && logoBytes.isNotEmpty) {
      final uploaded = await _uploadLogo(
        organizationId,
        logoBytes,
        logoContentType,
      );
      if (uploaded != null) {
        await _db
            .from('organizations')
            .update({'logo_url': uploaded})
            .eq(
              isUuid(organizationId) ? 'id' : 'firebase_id',
              organizationId,
            );
      }
    }
    return '${data['pin'] ?? pin}';
  });

  @override
  Future<void> activateWithPin({required String pin}) =>
      guardSupabase(() async {
        await _db.rpc('activate_invite_pin', params: {'p_pin': pin});
      });

  @override
  Future<String> redeemRespondentInvite({required String token}) async {
    try {
      final result = await _functions
          .httpsCallable(
            'redeemRespondentInvite',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
          )
          .call({'token': token.trim()});
      final data = Map<String, dynamic>.from(result.data as Map);
      final customToken = data['customToken'] as String?;
      if (customToken == null || customToken.isEmpty) {
        throw const ServerException(TalentErrorCodes.inviteInvalid);
      }
      return customToken;
    } on FirebaseFunctionsException catch (error) {
      throw ServerException(error.message ?? TalentErrorCodes.inviteInvalid);
    }
  }

  @override
  Future<String> inviteRecruiter({
    required String companyId,
    required String email,
    required String firstName,
    required String lastName,
    UserRole role = UserRole.recruiter,
  }) => guardSupabase(() async {
    final pin = PinHasher.generatePin();
    final result = await _db.rpc(
      'create_staff_invite',
      params: {
        'p_organization_id': companyId,
        'p_email': email,
        'p_first_name': firstName,
        'p_last_name': lastName,
        'p_role': role.value,
        'p_pin': pin,
      },
    );
    final data = Map<String, dynamic>.from(result as Map);
    return '${data['pin'] ?? pin}';
  });

  @override
  Future<void> updateCandidateStatus({
    required String candidateId,
    required CandidateProcessStatus status,
  }) => guardSupabase(() async {
    final app = await _applicationRow(candidateId);
    await _db
        .from('applications')
        .update({'process_status': status.name})
        .eq('id', app['id']);
  });

  @override
  Future<void> updateCandidate({
    required String candidateId,
    required String displayName,
    required String documentNumber,
    required String vacancyId,
  }) => guardSupabase(() async {
    final app = await _applicationRow(candidateId);
    final person = Map<String, dynamic>.from(app['persons'] as Map? ?? {});
    if (person['id'] != null) {
      await _db
          .from('persons')
          .update({
            'display_name': displayName.trim(),
            'document_number': documentNumber.trim(),
          })
          .eq('id', person['id']);
    }
    final vacancy = isUuid(vacancyId)
        ? await _db.from('vacancies').select().eq('id', vacancyId).maybeSingle()
        : await _db
              .from('vacancies')
              .select()
              .eq('firebase_id', vacancyId)
              .maybeSingle();
    await _db
        .from('applications')
        .update({
          if (vacancy != null) 'vacancy_id': vacancy['id'],
          if (vacancy != null) 'vacancy_name': vacancy['name'],
        })
        .eq('id', app['id']);
  });

  @override
  Future<void> deleteCandidate(String candidateId) => guardSupabase(() async {
    final app = await _applicationRow(candidateId);
    await _db.from('applications').delete().eq('id', app['id']);
  });

  @override
  Future<RespondentSession> loadRespondentSession() => guardSupabase(() async {
    final session = await _db.rpc('current_session_profile');
    final payload = session == null
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(session as Map);
    final applicationId = '${payload['applicationId'] ?? ''}';
    if (applicationId.isEmpty) {
      throw const ServerException(TalentErrorCodes.assessmentMissing);
    }
    final app = await _applicationRow(applicationId);
    final org = await _orgRow('${app['organization_id']}');
    final culture = await _cultureFor('${org['id']}');
    final answers = await _answersFor(app['id'] as String);
    return RespondentSession(
      candidate: _candidate({
        ...app,
        'organization_firebase_id': org['firebase_id'],
      }),
      answers: answers,
      company: _companyProfile(org, culture),
    );
  });

  Future<Map<String, int>> _answersFor(String applicationId) async {
    final session = await _db
        .from('survey_sessions')
        .select('id')
        .eq('application_id', applicationId)
        .eq('purpose', 'affinity')
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (session == null) return const {};
    final rows = await _db
        .from('survey_answers')
        .select('question_code, value_int')
        .eq('session_id', session['id']);
    final answers = <String, int>{};
    for (final row in rows) {
      final code = '${row['question_code'] ?? ''}';
      final value = row['value_int'];
      if (code.isNotEmpty && value is num) answers[code] = value.toInt();
    }
    return answers;
  }

  @override
  Future<void> saveAnswer({
    required String candidateId,
    required String questionId,
    required int value,
  }) => guardSupabase(() async {
    await _db.rpc(
      'save_affinity_answer',
      params: {
        'p_application_id': candidateId,
        'p_question_code': questionId,
        'p_value': value,
      },
    );
  });

  @override
  Future<TalentCandidate> completeEvaluation(String candidateId) =>
      guardSupabase(() async {
        final app = await _applicationRow(candidateId);
        final answers = await _answersFor(app['id'] as String);
        final vacancyLevel = affinityLevelFromAverage(
          capabilitiesAverage(answers),
        );
        await _db.rpc(
          'complete_affinity_evaluation',
          params: {
            'p_application_id': candidateId,
            'p_vacancy_affinity': vacancyLevel.name,
            'p_dimension_scores': {
              'values': pairDimensionScores(answers, AssessmentBlock.workValues),
              'needs': pairDimensionScores(answers, AssessmentBlock.needs),
              'capabilities': capabilitiesAverage(answers),
            },
          },
        );
        await _requestAffinityAnalysis(
          publicEntityId(app, firebaseKey: 'firebase_candidate_id'),
        );
        final candidate = _candidate(app);
        return TalentCandidate(
          id: candidate.id,
          companyId: candidate.companyId,
          vacancyId: candidate.vacancyId,
          vacancyName: candidate.vacancyName,
          email: candidate.email,
          documentNumber: candidate.documentNumber,
          displayName: candidate.displayName,
          processStatus: CandidateProcessStatus.completed,
          companyAffinity: candidate.companyAffinity,
          vacancyAffinity: vacancyLevel,
          evaluationCompleted: true,
          assessmentKind: candidate.assessmentKind,
          resultRequested: candidate.resultRequested,
          updatedAt: DateTime.now(),
        );
      });

  @override
  Future<void> requestSurveyResult(String candidateId) =>
      guardSupabase(() async {
        final app = await _applicationRow(candidateId);
        await _db
            .from('applications')
            .update({
              'result_requested': true,
              'result_requested_at': DateTime.now().toIso8601String(),
            })
            .eq('id', app['id']);
      });

  @override
  Future<CandidateReport> loadCandidateReport(String candidateId) =>
      guardSupabase(() async {
        final app = await _applicationRow(candidateId);
        final org = await _orgRow('${app['organization_id']}');
        final culture = await _cultureFor('${org['id']}');
        Map<String, dynamic>? vacancy;
        if (app['vacancy_id'] != null) {
          vacancy = await _db
              .from('vacancies')
              .select()
              .eq('id', app['vacancy_id'])
              .maybeSingle();
        }
        return CandidateReport(
          candidate: _candidate({
            ...app,
            'organization_firebase_id': org['firebase_id'],
          }),
          answers: await _answersFor(app['id'] as String),
          company: _companyProfile(org, culture),
          vacancy: vacancy == null ? null : _vacancy(vacancy),
          analysis: await loadAffinityAnalysis(candidateId),
        );
      });

  @override
  Future<AffinityAnalysis> loadAffinityAnalysis(String candidateId) =>
      guardSupabase(() async {
        final app = await _applicationRow(candidateId);
        final row = await _db
            .from('evaluation_reports')
            .select()
            .eq('application_id', app['id'])
            .maybeSingle();
        return row == null ? const AffinityAnalysis() : _analysis(row);
      });

  AffinityAnalysis _analysis(Map<String, dynamic> data) {
    AffinityLevel level(Object? value) => AffinityLevel.values.firstWhere(
      (item) => item.name == value,
      orElse: () => AffinityLevel.unknown,
    );
    List<AffinityInsight> insights(Object? value) => [
      if (value is List)
        for (final item in value.whereType<Map>())
          if ('${item['aspect'] ?? item['aspecto'] ?? ''}'.trim().isNotEmpty)
            AffinityInsight(
              aspect: '${item['aspect'] ?? item['aspecto']}'.trim(),
              evidence: '${item['evidence'] ?? item['evidencia'] ?? ''}'.trim(),
            ),
    ];
    List<String> strings(Object? value) => [
      if (value is List)
        for (final item in value)
          if ('$item'.trim().isNotEmpty) '$item'.trim(),
    ];
    return AffinityAnalysis(
      status: switch (data['status']) {
        'pending' => AffinityAnalysisStatus.pending,
        'completed' => AffinityAnalysisStatus.completed,
        'failed' => AffinityAnalysisStatus.failed,
        'insufficient_data' || 'insufficientData' =>
          AffinityAnalysisStatus.insufficientData,
        _ => AffinityAnalysisStatus.none,
      },
      level: level(data['level']),
      score: (data['score'] as num?)?.toInt(),
      confidence: level(data['confidence']),
      summary: '${data['summary'] ?? ''}'.trim(),
      alignments: insights(data['alignments']),
      differences: insights(data['differences']),
      conversationTopics: strings(
        data['conversation_topics'] ?? data['conversationTopics'],
      ),
      guidance: '${data['guidance'] ?? ''}'.trim(),
      dataGaps: strings(data['data_gaps'] ?? data['dataGaps']),
      errorCode: (data['error_code'] ?? data['error']) as String?,
      analyzedAt: parseOptionalSupabaseDate(
        data['analyzed_at'] ?? data['analyzedAt'],
      ),
    );
  }

  @override
  Future<AffinityAnalysis> requestAffinityAnalysis(String candidateId) =>
      guardSupabase(() async {
        try {
          await _functions
              .httpsCallable(
                'analyzeCandidateAffinity',
                options: HttpsCallableOptions(
                  timeout: const Duration(seconds: 120),
                ),
              )
              .call({'candidateId': candidateId});
        } on FirebaseFunctionsException catch (error) {
          if (error.code == 'permission-denied') {
            throw const ServerException(TalentErrorCodes.permissionDenied);
          }
        }
        return loadAffinityAnalysis(candidateId);
      });

  @override
  Future<void> saveAssessmentKind({
    required String candidateId,
    required AssessmentKind kind,
  }) => guardSupabase(() async {
    final app = await _applicationRow(candidateId);
    await _db
        .from('applications')
        .update({'assessment_kind': kind.name})
        .eq('id', app['id']);
  });

  @override
  Future<void> changePassword(String newPassword) => guardSupabase(() async {
    await _auth.currentUser?.updatePassword(newPassword);
    await _db
        .from('profiles')
        .update({'must_change_password': false})
        .eq('firebase_uid', _uid);
  });

  @override
  Future<List<DnaCatalogEntry>> loadDnaCatalog() => guardSupabase(_catalog);

  @override
  Future<void> deleteDnaCatalogOption({
    required String type,
    required String label,
  }) => guardSupabase(() async {
    if (isDnaPresetLabel(type, label)) return;
    await _db
        .from('dna_catalog_entries')
        .delete()
        .eq('type', type)
        .eq('label_es', label)
        .eq('source', 'company');
  });
}
