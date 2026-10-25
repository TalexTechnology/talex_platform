import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:talex_platform/core/auth/user_role.dart';
import 'package:talex_platform/core/error/exceptions.dart';
import 'package:talex_platform/features/talent/domain/entities/talent_entities.dart';
import 'package:talex_platform/features/talent/domain/services/dna_catalog.dart';
import 'package:talex_platform/features/talent/domain/services/pin_hasher.dart';
import 'package:talex_platform/features/talent/domain/talent_error_codes.dart';
import 'package:crypto/crypto.dart';
import 'package:cloud_functions/cloud_functions.dart';

abstract interface class TalentDataSource {
  Future<TalentSnapshot> loadCompany(String companyId);
  Future<void> saveCompanyProfile(CompanyProfile profile);
  Future<void> createVacancy(Vacancy vacancy);
  Future<String> createRespondent({
    required String companyId,
    required String vacancyId,
    required String email,
    required String documentNumber,
    String? displayName,
  });
  Future<String> provisionCompany({
    required CompanyProfile profile,
    required String recruiterFirstName,
    required String recruiterLastName,
    required String recruiterEmail,
    Uint8List? logoBytes,
    String? logoContentType,
  });
  Future<void> activateWithPin({required String pin});
  Future<String> redeemRespondentInvite({required String token});
  Future<String> inviteRecruiter({
    required String companyId,
    required String email,
    required String firstName,
    required String lastName,
    UserRole role = UserRole.recruiter,
  });
  Future<void> updateCandidateStatus({
    required String candidateId,
    required CandidateProcessStatus status,
  });
  Future<void> updateCandidate({
    required String candidateId,
    required String displayName,
    required String documentNumber,
    required String vacancyId,
  });
  Future<void> deleteCandidate(String candidateId);
  Future<RespondentSession> loadRespondentSession();
  Future<void> saveAnswer({
    required String candidateId,
    required String questionId,
    required int value,
  });
  Future<TalentCandidate> completeEvaluation(String candidateId);
  Future<void> requestSurveyResult(String candidateId);
  Future<CandidateReport> loadCandidateReport(String candidateId);
  Future<AffinityAnalysis> loadAffinityAnalysis(String candidateId);
  Future<AffinityAnalysis> requestAffinityAnalysis(String candidateId);
  Future<void> saveAssessmentKind({
    required String candidateId,
    required AssessmentKind kind,
  });
  Future<void> changePassword(String newPassword);
  Future<List<DnaCatalogEntry>> loadDnaCatalog();
  Future<void> deleteDnaCatalogOption({
    required String type,
    required String label,
  });
}

final class FirebaseTalentDataSource implements TalentDataSource {
  FirebaseTalentDataSource(
    this._auth,
    this._firestore,
    this._storage,
    this._functions,
  );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;

  String _generateInviteToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(
      32,
      (_) => random.nextInt(256),
    );
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _hashInviteToken(String token) {
    return sha256.convert(utf8.encode(token)).toString();
  }

  CollectionReference<Map<String, dynamic>> get _companies =>
      _firestore.collection('companies');
  CollectionReference<Map<String, dynamic>> get _vacancies =>
      _firestore.collection('vacancies');
  CollectionReference<Map<String, dynamic>> get _candidates =>
      _firestore.collection('candidates');
  CollectionReference<Map<String, dynamic>> get _invites =>
      _firestore.collection('activation_invites');
  CollectionReference<Map<String, dynamic>> get _evaluations =>
      _firestore.collection('evaluations');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _dnaCatalog =>
      _firestore.collection('dna_catalog');
  CollectionReference<Map<String, dynamic>> get _affinityAnalyses =>
      _firestore.collection('affinity_analyses');

  final _candidateCompanies = <String, String?>{};

  @override
  Future<String> redeemRespondentInvite({
    required String token,
  }) async {
    final callable = _functions.httpsCallable(
      'redeemRespondentInvite',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 30),
      ),
    );

    try {
      final result = await callable.call({
        'token': token.trim(),
      });

      final data = Map<String, dynamic>.from(
        result.data as Map,
      );

      final customToken = data['customToken'] as String?;

      if (customToken == null || customToken.isEmpty) {
        throw const ServerException(
          TalentErrorCodes.inviteInvalid,
        );
      }

      return customToken;
    } on FirebaseFunctionsException catch (error) {
      switch (error.code) {
        case 'not-found':
          throw const ServerException(
            TalentErrorCodes.inviteInvalid,
          );

        case 'failed-precondition':
          throw ServerException(
            error.message ?? TalentErrorCodes.inviteInvalid,
          );

        case 'invalid-argument':
          throw const ServerException(
            TalentErrorCodes.inviteInvalid,
          );

        default:
          rethrow;
      }
    }
  }

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const ServerException(TalentErrorCodes.needSignIn);
    return uid;
  }

  String get _email {
    final email = _auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      throw const ServerException(TalentErrorCodes.needAuthEmail);
    }
    return email.toLowerCase();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ServerException {
      rethrow;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const ServerException(TalentErrorCodes.permissionDenied);
      }
      throw const ServerException(TalentErrorCodes.unexpected);
    }
  }

  Future<String?> _uploadCompanyLogo({
    required String companyId,
    required Uint8List bytes,
    String? contentType,
  }) async {
    try {
      final ref = _storage.ref('company_logos/$companyId');
      await ref
          .putData(
            bytes,
            SettableMetadata(contentType: contentType ?? 'image/png'),
          )
          .timeout(const Duration(seconds: 15));
      return await ref.getDownloadURL().timeout(const Duration(seconds: 8));
    } catch (_) {
      return null;
    }
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  AssessmentKind? _assessmentKind(Object? value) {
    for (final item in AssessmentKind.values) {
      if (item.name == value) return item;
    }
    return null;
  }

  Map<String, int> _answers(Object? raw) {
    final answers = <String, int>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final value = entry.value;
        if (value is num) answers[entry.key.toString()] = value.toInt();
      }
    }
    return answers;
  }

  DateTime _date(Object? value) {
    return _optionalDate(value) ?? DateTime.now();
  }

  DateTime? _optionalDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  DnaCatalogEntry _dnaEntry(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return DnaCatalogEntry(
      type: (data['type'] as String?) ?? '',
      labelEs: (data['labelEs'] as String?) ?? (data['label'] as String?) ?? '',
      labelEn: data['labelEn'] as String?,
    );
  }

  Future<List<DnaCatalogEntry>> _loadDnaCatalog() async {
    try {
      var snapshot = await _dnaCatalog.get();
      final existing = {for (final doc in snapshot.docs) doc.id};
      final missing = allDnaPresets
          .where((item) => !existing.contains('${item.type}_${item.key}'))
          .toList();
      if (missing.isNotEmpty) {
        final batch = _firestore.batch();
        for (final item in missing) {
          batch.set(_dnaCatalog.doc('${item.type}_${item.key}'), {
            'type': item.type,
            'key': item.key,
            'labelEs': item.es,
            'labelEn': item.en,
            'source': 'seed',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
        snapshot = await _dnaCatalog.get();
      }
      return snapshot.docs
          .map(_dnaEntry)
          .where((item) => item.type.isNotEmpty && item.labelEs.isNotEmpty)
          .toList();
    } catch (_) {
      return [
        for (final item in allDnaPresets)
          DnaCatalogEntry(
            type: item.type,
            labelEs: item.es,
            labelEn: item.en,
          ),
      ];
    }
  }

  Future<void> _upsertDnaOption(
    String type,
    String? label,
    String companyId,
  ) async {
    final trimmed = label?.trim() ?? '';
    if (trimmed.isEmpty) return;
    if (isDnaPresetLabel(type, trimmed)) return;
    final ref = _dnaCatalog.doc(dnaCatalogDocId(type, trimmed));
    try {
      final existing = await ref.get();
      if (existing.exists) return;
      await ref.set({
        'type': type,
        'labelEs': trimmed,
        'labelEn': trimmed,
        'source': 'company',
        'companyId': companyId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  CompanyProfile _profile(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return CompanyProfile(
      id: doc.id,
      name: (data['name'] as String?) ?? 'Empresa',
      nit: data['nit'] as String?,
      logoUrl: data['logoUrl'] as String?,
      sector: data['sector'] as String?,
      size: data['size'] as String?,
      city: data['city'] as String?,
      country: data['country'] as String?,
      region: data['region'] as String?,
      website: data['website'] as String?,
      description: data['description'] as String?,
      values: joinDnaList([
        ..._stringList(data['valuesList']),
        ...parseDnaList(data['valuesText'] as String?),
      ]),
      culture: joinDnaList([
        ..._stringList(data['cultureList']),
        ...parseDnaList(data['culture'] as String?),
      ]),
      standoutPeople: joinDnaList([
        ..._stringList(data['standoutList']),
        ...parseDnaList(data['standoutPeople'] as String?),
      ]),
      soughtCharacteristics: data['soughtCharacteristics'] as String?,
      customValues: _stringList(data['customValues']),
      customCulture: _stringList(data['customCulture']),
      customStandout: _stringList(data['customStandout']),
      customAreas: _stringList(data['customAreas']),
    );
  }

  Vacancy _vacancy(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Vacancy(
      id: doc.id,
      companyId: (data['companyId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      status: data['status'] == VacancyStatus.closed.name
          ? VacancyStatus.closed
          : VacancyStatus.active,
      createdAt: _date(data['createdAt']),
      area: data['area'] as String?,
      description: data['description'] as String?,
      city: data['city'] as String?,
      country: data['country'] as String?,
      region: data['region'] as String?,
      workMode: data['workMode'] as String?,
      contractType: data['contractType'] as String?,
      seniority: data['seniority'] as String?,
      roleProfile: data['roleProfile'] as String?,
    );
  }

  TalentCandidate _candidate(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return TalentCandidate(
      id: doc.id,
      companyId: (data['companyId'] as String?) ?? '',
      vacancyId: (data['vacancyId'] as String?) ?? '',
      vacancyName: (data['vacancyName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      documentNumber: (data['documentNumber'] as String?) ?? '',
      displayName: data['displayName'] as String?,
      processStatus: CandidateProcessStatus.values.firstWhere(
        (item) => item.name == data['processStatus'],
        orElse: () => CandidateProcessStatus.pending,
      ),
      companyAffinity: AffinityLevel.values.firstWhere(
        (item) => item.name == data['companyAffinity'],
        orElse: () => AffinityLevel.unknown,
      ),
      vacancyAffinity: AffinityLevel.values.firstWhere(
        (item) => item.name == data['vacancyAffinity'],
        orElse: () => AffinityLevel.unknown,
      ),
      evaluationCompleted: data['evaluationCompleted'] == true,
      resultRequested: data['resultRequested'] == true,
      assessmentKind: _assessmentKind(data['assessmentKind']),
      affinityAnalyzed: data['affinityStatus'] is String,
      updatedAt: _date(data['updatedAt']),
    );
  }

  Future<String> _writeInvite({
    required String email,
    required String companyId,
    required InviteKind kind,
    required UserRole role,
    String? firstName,
    String? lastName,
    String? documentNumber,
    String? candidateId,
  }) async {
    final secret = PinHasher.generatePin();
    await _invites.doc(email.trim().toLowerCase()).set({
      'email': email.trim().toLowerCase(),
      'companyId': companyId,
      'kind': kind.name,
      'role': role.value,
      'pinHash': PinHasher.hash(secret, email),
      'firstName': firstName,
      'lastName': lastName,
      'documentNumber': documentNumber,
      'candidateId': candidateId,
      'used': false,
      'createdAt': FieldValue.serverTimestamp(),
      'pinExpiresAt': Timestamp.fromDate(InvitePin.expiresAt()),
    });
    return secret;
  }

    Future<String> _writeRespondentInvite({
    required String email,
    required String companyId,
    required String vacancyId,
    String? firstName,
    String? lastName,
    String? documentNumber,
    String? candidateId,
  }) async {
    final token = _generateInviteToken();
    final tokenHash = _hashInviteToken(token);

    await _invites.doc(email.trim().toLowerCase()).set({
      'email': email.trim().toLowerCase(),
      'companyId': companyId,
      'vacancyId': vacancyId,
      'kind': InviteKind.respondent.name,
      'role': UserRole.respondent.value,
      'tokenHash': tokenHash,
      'tokenExpiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 14)),
      ),
      'firstName': firstName,
      'lastName': lastName,
      'documentNumber': documentNumber,
      'candidateId': candidateId,
      'used': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return token;
  }

  @override
  Future<TalentSnapshot> loadCompany(String companyId) => _guard(() async {
    final profileDoc = await _companies.doc(companyId).get();
    if (!profileDoc.exists) {
      throw const ServerException(TalentErrorCodes.companyNotFound);
    }
    final data = profileDoc.data();
    if (data?['archived'] == true ||
        data?['status'] == 'inactive' ||
        data?['status'] == 'suspended') {
      throw const ServerException(TalentErrorCodes.companyDisabled);
    }
    final vacancies = await _vacancies.where('companyId', isEqualTo: companyId).get();
    final candidates = await _candidates.where('companyId', isEqualTo: companyId).get();
    final invites = await _invites.where('companyId', isEqualTo: companyId).get();
    final dnaCatalog = await _loadDnaCatalog();
    return TalentSnapshot(
      profile: _profile(profileDoc),
      vacancies: vacancies.docs.map(_vacancy).toList(),
      candidates: candidates.docs.map(_candidate).toList(),
      dnaCatalog: dnaCatalog,
      team: invites.docs
          .map((doc) {
            final data = doc.data();
            if (!isCompanyStaffInvite(
              kind: data['kind'] as String?,
              role: data['role'] as String?,
            )) {
              return null;
            }
            return TeamMember(
              email: (data['email'] as String?) ?? doc.id,
              role: (data['role'] as String?) ?? UserRole.recruiter.value,
              inviteUsed: data['used'] == true,
              displayName: [data['firstName'], data['lastName']]
                  .whereType<String>()
                  .where((item) => item.trim().isNotEmpty)
                  .join(' '),
            );
          })
          .whereType<TeamMember>()
          .toList(),
    );
  });

  @override
  Future<void> saveCompanyProfile(CompanyProfile profile) => _guard(() async {
    final values = parseDnaList(profile.values);
    final culture = parseDnaList(profile.culture);
    final standout = parseDnaList(profile.standoutPeople);
    await _companies.doc(profile.id).set({
      'name': profile.name,
      'nameLower': profile.name.toLowerCase(),
      'nit': profile.nit,
      'logoUrl': profile.logoUrl,
      'sector': profile.sector,
      'size': profile.size,
      'city': profile.city,
      'country': profile.country,
      'region': profile.region,
      'website': profile.website,
      'description': profile.description,
      'valuesText': joinDnaList(values),
      'valuesList': values,
      'culture': joinDnaList(culture),
      'cultureList': culture,
      'standoutPeople': joinDnaList(standout),
      'standoutList': standout,
      'soughtCharacteristics': profile.soughtCharacteristics,
      'updatedAt': FieldValue.serverTimestamp(),
      if (values.isNotEmpty) 'customValues': FieldValue.arrayUnion(values),
      if (culture.isNotEmpty) 'customCulture': FieldValue.arrayUnion(culture),
      if (standout.isNotEmpty) 'customStandout': FieldValue.arrayUnion(standout),
      if (profile.customAreas.isNotEmpty)
        'customAreas': FieldValue.arrayUnion(profile.customAreas),
    }, SetOptions(merge: true));
    await _users.doc(_uid).set({
      'mustReviewCompanyDna': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    for (final item in values) {
      await _upsertDnaOption(DnaCatalogType.values, item, profile.id);
    }
    for (final item in culture) {
      await _upsertDnaOption(DnaCatalogType.culture, item, profile.id);
    }
    for (final item in standout) {
      await _upsertDnaOption(DnaCatalogType.standout, item, profile.id);
    }
  });

  @override
  Future<void> createVacancy(Vacancy vacancy) => _guard(() async {
    await _vacancies.add({
      'companyId': vacancy.companyId,
      'name': vacancy.name.trim(),
      'status': VacancyStatus.active.name,
      'area': vacancy.area,
      'description': vacancy.description,
      'city': vacancy.city,
      'country': vacancy.country,
      'region': vacancy.region,
      'workMode': vacancy.workMode,
      'contractType': vacancy.contractType,
      'seniority': vacancy.seniority,
      'roleProfile': vacancy.roleProfile,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _uid,
    });
    final area = vacancy.area?.trim();
    if (area != null && area.isNotEmpty) {
      await _companies.doc(vacancy.companyId).set({
        'customAreas': FieldValue.arrayUnion([area]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _upsertDnaOption(DnaCatalogType.area, area, vacancy.companyId);
    }
  });

  @override
  Future<String> createRespondent({
    required String companyId,
    required String vacancyId,
    required String email,
    required String documentNumber,
    String? displayName,
  }) => _guard(() async {
    final vacancy = _vacancy(await _vacancies.doc(vacancyId).get());
    final existing = await _candidates
        .where('companyId', isEqualTo: companyId)
        .where('email', isEqualTo: email.trim().toLowerCase())
        .where('vacancyId', isEqualTo: vacancyId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return _writeRespondentInvite(
        email: email,
        companyId: companyId,
        vacancyId: vacancyId,
        firstName: displayName?.trim().split(' ').first,
        lastName: displayName != null && displayName.trim().contains(' ')
            ? displayName.trim().split(' ').skip(1).join(' ')
            : null,
        documentNumber: documentNumber,
        candidateId: existing.docs.first.id,
      );
    }
    final doc = await _candidates.add({
      'companyId': companyId,
      'vacancyId': vacancyId,
      'vacancyName': vacancy.name,
      'email': email.trim().toLowerCase(),
      'documentNumber': documentNumber.trim(),
      'displayName': displayName,
      'processStatus': CandidateProcessStatus.pending.name,
      'companyAffinity': AffinityLevel.unknown.name,
      'vacancyAffinity': AffinityLevel.unknown.name,
      'evaluationCompleted': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return _writeRespondentInvite(
      email: email,
      companyId: companyId,
      vacancyId: vacancyId,
      firstName: displayName?.trim().split(' ').first,
      lastName: displayName != null && displayName.trim().contains(' ')
          ? displayName.trim().split(' ').skip(1).join(' ')
          : null,
      documentNumber: documentNumber,
      candidateId: doc.id,
    );
  });

  @override
  Future<String> provisionCompany({
    required CompanyProfile profile,
    required String recruiterFirstName,
    required String recruiterLastName,
    required String recruiterEmail,
    Uint8List? logoBytes,
    String? logoContentType,
  }) => _guard(() async {
    final values = parseDnaList(profile.values);
    final culture = parseDnaList(profile.culture);
    final standout = parseDnaList(profile.standoutPeople);
    final company = await _companies.add({
      'name': profile.name.trim(),
      'nameLower': profile.name.trim().toLowerCase(),
      'nit': profile.nit,
      'logoUrl': profile.logoUrl,
      'sector': profile.sector,
      'size': profile.size,
      'city': profile.city,
      'country': profile.country,
      'region': profile.region,
      'website': profile.website,
      'description': profile.description,
      'valuesText': joinDnaList(values),
      'valuesList': values,
      'culture': joinDnaList(culture),
      'cultureList': culture,
      'standoutPeople': joinDnaList(standout),
      'standoutList': standout,
      'status': 'onboarding',
      'archived': false,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivityAt': FieldValue.serverTimestamp(),
      'createdBy': _uid,
    });
    for (final item in values) {
      await _upsertDnaOption(DnaCatalogType.values, item, company.id);
    }
    for (final item in culture) {
      await _upsertDnaOption(DnaCatalogType.culture, item, company.id);
    }
    for (final item in standout) {
      await _upsertDnaOption(DnaCatalogType.standout, item, company.id);
    }
    var logoUrl = profile.logoUrl?.trim();
    if (logoUrl != null && logoUrl.isEmpty) logoUrl = null;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      final uploaded = await _uploadCompanyLogo(
        companyId: company.id,
        bytes: logoBytes,
        contentType: logoContentType,
      );
      if (uploaded != null) logoUrl = uploaded;
    }
    if (logoUrl != null) {
      await company.set({'logoUrl': logoUrl}, SetOptions(merge: true));
    }
    return _writeInvite(
      email: recruiterEmail,
      companyId: company.id,
      kind: InviteKind.recruiter,
      role: UserRole.companyAdmin,
      firstName: recruiterFirstName,
      lastName: recruiterLastName,
    );
  });

  @override
  Future<void> activateWithPin({required String pin}) => _guard(() async {
    await _completeInvite(secret: pin, requireMatch: true);
  });


  Future<void> _completeInvite({
    required String secret,
    InviteKind? expectedKind,
    required bool requireMatch,
  }) async {
    final invite = await _invites.doc(_email).get();
    if (!invite.exists) {
      if (requireMatch) throw const ServerException(TalentErrorCodes.inviteMissing);
      return;
    }
    final data = invite.data()!;
    if (data['used'] == true) {
      if (requireMatch) throw const ServerException(TalentErrorCodes.inviteUsed);
      return;
    }
    final kind = data['kind'] == InviteKind.respondent.name
        ? InviteKind.respondent
        : InviteKind.recruiter;
    if (expectedKind != null && kind != expectedKind) {
      if (requireMatch) throw const ServerException(TalentErrorCodes.invalidPin);
      return;
    }
    if (data['pinHash'] != PinHasher.hash(secret.trim(), _email)) {
      if (requireMatch) throw const ServerException(TalentErrorCodes.invalidPin);
      return;
    }
    if (InvitePin.isExpired(
      expiresAt: _optionalDate(data['pinExpiresAt']),
      createdAt: _optionalDate(data['createdAt']),
    )) {
      if (requireMatch) throw const ServerException(TalentErrorCodes.pinExpired);
      return;
    }
    final role = UserRoleX.parse(data['role']);
    await _users.doc(_uid).set({
      'role': role.value,
      'companyId': data['companyId'],
      'candidateId': data['candidateId'],
      'documentNumber': data['documentNumber'],
      'mustChangePassword': false,
      'mustReviewCompanyDna': false,
      'activationPinHash': PinHasher.hash(secret.trim(), _email),
      'displayName': [
        data['firstName'],
        data['lastName'],
      ].whereType<String>().join(' ').trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _invites.doc(_email).set({
      'used': true,
      'activatedAt': FieldValue.serverTimestamp(),
      'activatedBy': _uid,
    }, SetOptions(merge: true));
  }

  @override
  Future<String> inviteRecruiter({
    required String companyId,
    required String email,
    required String firstName,
    required String lastName,
    UserRole role = UserRole.recruiter,
  }) => _guard(
    () => _writeInvite(
      email: email,
      companyId: companyId,
      kind: InviteKind.recruiter,
      role: role,
      firstName: firstName,
      lastName: lastName,
    ),
  );

  @override
  Future<void> updateCandidateStatus({
    required String candidateId,
    required CandidateProcessStatus status,
  }) => _guard(() async {
    await _candidates.doc(candidateId).set({
      'processStatus': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  });

  @override
  Future<void> updateCandidate({
    required String candidateId,
    required String displayName,
    required String documentNumber,
    required String vacancyId,
  }) => _guard(() async {
    final candidateRef = _candidates.doc(candidateId);
    final candidate = await candidateRef.get();
    final vacancy = _vacancy(await _vacancies.doc(vacancyId).get());
    final name = displayName.trim();
    await candidateRef.set({
      'displayName': name,
      'documentNumber': documentNumber.trim(),
      'vacancyId': vacancyId,
      'vacancyName': vacancy.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    final email = (candidate.data()?['email'] as String?)?.trim().toLowerCase();
    if (email == null || email.isEmpty) return;
    final inviteRef = _invites.doc(email);
    final invite = await _readInvite(inviteRef);
    if (invite?['candidateId'] != candidateId) return;
    final parts = name.split(' ');
    await inviteRef.set({
      'firstName': parts.first,
      'lastName': parts.length > 1 ? parts.skip(1).join(' ') : null,
      'documentNumber': documentNumber.trim(),
      'vacancyId': vacancyId,
    }, SetOptions(merge: true));
  });

  @override
  Future<void> deleteCandidate(String candidateId) => _guard(() async {
    final candidateRef = _candidates.doc(candidateId);
    final candidate = await candidateRef.get();
    if (!candidate.exists) return;
    final email = (candidate.data()?['email'] as String?)?.trim().toLowerCase();
    await _evaluations.doc(candidateId).delete();
    if (email != null && email.isNotEmpty) {
      final inviteRef = _invites.doc(email);
      final invite = await _readInvite(inviteRef);
      if (invite?['candidateId'] == candidateId) {
        await inviteRef.delete();
      }
    }
    await candidateRef.delete();
  });

  Future<Map<String, dynamic>?> _readInvite(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      return (await ref.get()).data();
    } on FirebaseException {
      return null;
    }
  }

  @override
  Future<RespondentSession> loadRespondentSession() => _guard(() async {
    final user = await _users.doc(_uid).get();
    var candidateId = user.data()?['candidateId'] as String?;
    if (candidateId == null || candidateId.isEmpty) {
      final found = await _candidates
          .where('email', isEqualTo: _email)
          .limit(1)
          .get();
      if (found.docs.isEmpty) {
        throw const ServerException(TalentErrorCodes.assessmentMissing);
      }
      candidateId = found.docs.first.id;
      final candidateData = found.docs.first.data();
      await _users.doc(_uid).set({
        'candidateId': candidateId,
        if ((user.data()?['companyId'] as String?) == null ||
            (user.data()?['companyId'] as String?)!.isEmpty)
          'companyId': candidateData['companyId'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    Future<CompanyProfile?> loadCompany(String companyId) async {
      if (companyId.isEmpty) return null;
      try {
        final companyDoc = await _companies.doc(companyId).get();
        return companyDoc.exists ? _profile(companyDoc) : null;
      } on FirebaseException {
        return null;
      }
    }

    Future<Map<String, dynamic>?> loadEvaluation() async {
      try {
        return (await _evaluations.doc(candidateId).get()).data();
      } on FirebaseException {
        return null;
      }
    }

    final userCompanyId = user.data()?['companyId'] as String?;
    final results = await Future.wait<Object?>([
      _candidates.doc(candidateId).get(),
      loadEvaluation(),
      if (userCompanyId != null && userCompanyId.isNotEmpty)
        loadCompany(userCompanyId),
    ]);
    final candidate = _candidate(
      results[0]! as DocumentSnapshot<Map<String, dynamic>>,
    );
    final evaluation = results[1] as Map<String, dynamic>?;
    final company = results.length > 2
        ? results[2] as CompanyProfile?
        : await loadCompany(candidate.companyId);
    _candidateCompanies[candidate.id] = candidate.companyId;
    final answers = _answers(evaluation?['answers']);
    final evaluationKind = _assessmentKind(evaluation?['assessmentKind']);
    return RespondentSession(
      candidate: TalentCandidate(
        id: candidate.id,
        companyId: candidate.companyId,
        vacancyId: candidate.vacancyId,
        vacancyName: candidate.vacancyName,
        email: candidate.email,
        documentNumber: candidate.documentNumber,
        displayName: candidate.displayName,
        processStatus: candidate.processStatus,
        companyAffinity: candidate.companyAffinity,
        vacancyAffinity: candidate.vacancyAffinity,
        evaluationCompleted: candidate.evaluationCompleted,
        assessmentKind: candidate.assessmentKind ?? evaluationKind,
        updatedAt: candidate.updatedAt,
      ),
      answers: answers,
      company: company,
    );
  });

  @override
  Future<void> saveAnswer({
    required String candidateId,
    required String questionId,
    required int value,
  }) => _guard(() async {
    final companyId = _candidateCompanies.containsKey(candidateId)
        ? _candidateCompanies[candidateId]
        : _candidateCompanies[candidateId] =
              (await _candidates.doc(candidateId).get()).data()?['companyId']
                  as String?;
    final batch = _firestore.batch()
      ..set(_evaluations.doc(candidateId), {
        'candidateId': candidateId,
        'companyId': companyId,
        'answers': {questionId: value},
        'updatedAt': FieldValue.serverTimestamp(),
        'respondentId': _uid,
      }, SetOptions(merge: true))
      ..set(_candidates.doc(candidateId), {
        'processStatus': CandidateProcessStatus.inProgress.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    await batch.commit();
  });

  @override
  Future<TalentCandidate> completeEvaluation(String candidateId) =>
      _guard(() async {
        final snapshots = await Future.wait([
          _evaluations.doc(candidateId).get(),
          _candidates.doc(candidateId).get(),
        ]);
        final answers = _answers(snapshots[0].data()?['answers']);
        final candidateData = snapshots[1].data() ?? const <String, dynamic>{};
        // La afinidad con la empresa la calcula el backend al detectar la
        // evaluación completa; aquí solo se cierra la evaluación.
        final vacancyLevel = affinityLevelFromAverage(
          capabilitiesAverage(answers),
        );
        final batch = _firestore.batch()
          ..set(_candidates.doc(candidateId), {
            'processStatus': CandidateProcessStatus.completed.name,
            'evaluationCompleted': true,
            'vacancyAffinity': vacancyLevel.name,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          ..set(_evaluations.doc(candidateId), {
            'companyId': candidateData['companyId'],
            'completed': true,
            'completedAt': FieldValue.serverTimestamp(),
            'dimensionScores': {
              'values': pairDimensionScores(answers, AssessmentBlock.workValues),
              'needs': pairDimensionScores(answers, AssessmentBlock.needs),
              'capabilities': capabilitiesAverage(answers),
            },
          }, SetOptions(merge: true));
        await batch.commit();
        final candidate = _candidate(snapshots[1]);
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
  Future<void> requestSurveyResult(String candidateId) => _guard(() async {
    final candidateSnap = await _candidates.doc(candidateId).get();
    final data = candidateSnap.data() ?? const <String, dynamic>{};
    final companyId = data['companyId'] as String?;
    String? companyName;
    if (companyId != null && companyId.isNotEmpty) {
      final company = await _firestore.collection('companies').doc(companyId).get();
      companyName = company.data()?['name'] as String?;
    }
    final batch = _firestore.batch()
      ..set(_candidates.doc(candidateId), {
        'resultRequested': true,
        'resultRequestedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true))
      ..set(_firestore.collection('survey_result_requests').doc(candidateId), {
        'candidateId': candidateId,
        'companyId': companyId,
        'companyName': companyName,
        'displayName': data['displayName'] ?? data['email'],
        'email': data['email'],
        'vacancyName': data['vacancyName'],
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    await batch.commit();
  });

  @override
  Future<CandidateReport> loadCandidateReport(String candidateId) =>
      _guard(() async {
        final snapshots = await Future.wait([
          _candidates.doc(candidateId).get(),
          _evaluations.doc(candidateId).get(),
        ]);
        final candidate = _candidate(snapshots[0]);
        final related = await Future.wait<Object?>([
          candidate.companyId.isEmpty
              ? Future.value()
              : _companies.doc(candidate.companyId).get(),
          candidate.vacancyId.isEmpty
              ? Future.value()
              : _vacancies.doc(candidate.vacancyId).get(),
          _readAffinityAnalysis(candidateId),
        ]);
        final companyDoc =
            related[0] as DocumentSnapshot<Map<String, dynamic>>?;
        final vacancyDoc =
            related[1] as DocumentSnapshot<Map<String, dynamic>>?;
        return CandidateReport(
          candidate: candidate,
          answers: _answers(snapshots[1].data()?['answers']),
          company: companyDoc != null && companyDoc.exists
              ? _profile(companyDoc)
              : null,
          vacancy: vacancyDoc != null && vacancyDoc.exists
              ? _vacancy(vacancyDoc)
              : null,
          analysis: related[2]! as AffinityAnalysis,
        );
      });

  @override
  Future<AffinityAnalysis> loadAffinityAnalysis(String candidateId) =>
      _guard(() => _readAffinityAnalysis(candidateId));

  @override
  Future<AffinityAnalysis> requestAffinityAnalysis(String candidateId) =>
      _guard(() async {
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
        return _readAffinityAnalysis(candidateId);
      });

  Future<AffinityAnalysis> _readAffinityAnalysis(String candidateId) async {
    try {
      final doc = await _affinityAnalyses.doc(candidateId).get();
      final data = doc.data();
      return data == null ? const AffinityAnalysis() : _affinityAnalysis(data);
    } on FirebaseException {
      return const AffinityAnalysis();
    }
  }

  AffinityAnalysis _affinityAnalysis(Map<String, dynamic> data) {
    AffinityLevel level(Object? value) => AffinityLevel.values.firstWhere(
      (item) => item.name == value,
      orElse: () => AffinityLevel.unknown,
    );
    List<AffinityInsight> insights(Object? value) => [
      if (value is List)
        for (final item in value.whereType<Map>())
          if ('${item['aspect'] ?? ''}'.trim().isNotEmpty)
            AffinityInsight(
              aspect: '${item['aspect']}'.trim(),
              evidence: '${item['evidence'] ?? ''}'.trim(),
            ),
    ];
    return AffinityAnalysis(
      status: switch (data['status']) {
        'pending' => AffinityAnalysisStatus.pending,
        'completed' => AffinityAnalysisStatus.completed,
        'failed' => AffinityAnalysisStatus.failed,
        'insufficient_data' => AffinityAnalysisStatus.insufficientData,
        _ => AffinityAnalysisStatus.none,
      },
      level: level(data['level']),
      score: (data['score'] as num?)?.toInt(),
      confidence: level(data['confidence']),
      summary: (data['summary'] as String?)?.trim() ?? '',
      alignments: insights(data['alignments']),
      differences: insights(data['differences']),
      conversationTopics: _stringList(data['conversationTopics']),
      guidance: (data['guidance'] as String?)?.trim() ?? '',
      dataGaps: _stringList(data['dataGaps']),
      errorCode: data['error'] as String?,
      analyzedAt: _optionalDate(data['analyzedAt']),
    );
  }

  @override
  Future<void> saveAssessmentKind({
    required String candidateId,
    required AssessmentKind kind,
  }) => _guard(() async {
    final candidate = await _candidates.doc(candidateId).get();
    await _candidates.doc(candidateId).set({
      'assessmentKind': kind.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _evaluations.doc(candidateId).set({
      'candidateId': candidateId,
      'companyId': candidate.data()?['companyId'],
      'assessmentKind': kind.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'respondentId': _uid,
    }, SetOptions(merge: true));
  });

  @override
  Future<void> changePassword(String newPassword) => _guard(() async {
    await _auth.currentUser?.updatePassword(newPassword);
    await _users.doc(_uid).set({
      'mustChangePassword': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  });

  @override
  Future<List<DnaCatalogEntry>> loadDnaCatalog() => _guard(_loadDnaCatalog);

  @override
  Future<void> deleteDnaCatalogOption({
    required String type,
    required String label,
  }) => _guard(() async {
    if (isDnaPresetLabel(type, label)) return;
    await _dnaCatalog.doc(dnaCatalogDocId(type, label)).delete();
  });
}
