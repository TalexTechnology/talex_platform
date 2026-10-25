import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:talex_platform/core/auth/user_role.dart';
import 'package:talex_platform/core/error/exceptions.dart';
import 'package:talex_platform/core/data/http_remote_database.dart';
import 'package:talex_platform/features/auth/data/datasources/google_popup_monitor.dart';
import 'package:talex_platform/features/talent/domain/talent_error_codes.dart';
import 'package:talex_platform/features/auth/data/models/auth_user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthUserModel?> getCurrentUser();
  Future<AuthUserModel> signIn({
    required String email,
    required String password,
  });
  Future<AuthUserModel> signInWithGoogle();
  Future<AuthUserModel> signUp({
    required String email,
    required String password,
    String? displayName,
    String? companyName,
  });
  Future<void> signOut();
  Future<void> discardCurrentUser();
  Future<void> sendPasswordResetEmail(String email);
  Future<AuthUserModel> signInWithCustomToken(String token);
}

final class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  FirebaseAuthRemoteDataSource(
    this._firebaseAuth,
    this._googleSignIn,
    this._firestore,
  );

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;
  Future<void>? _googleInitialization;

  Future<T> _handleFirebaseErrors<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (error) {
      throw ServerException(_firebaseErrorMessage(error.code));
    } on FirebaseException catch (error) {
      throw ServerException(_firestoreErrorMessage(error.code));
    }
  }

  String _firestoreErrorMessage(String code) => switch (code) {
    'permission-denied' =>
      'No tienes permiso para guardar la información del usuario en Firestore.',
    'unavailable' =>
      'Firestore no está disponible temporalmente. Inténtalo nuevamente.',
    'deadline-exceeded' =>
      'Firestore tardó demasiado en responder. Inténtalo nuevamente.',
    'not-found' =>
      'No se encontró la base de datos de Firestore. Verifica su configuración.',
    _ => 'No se pudo guardar la información del usuario. Inténtalo nuevamente.',
  };

  String _firebaseErrorMessage(String code) => switch (code) {
    'user-not-found' =>
      'No existe una cuenta registrada con este correo electrónico.',
    'wrong-password' || 'invalid-credential' =>
      'El correo electrónico o la contraseña son incorrectos.',
    'invalid-email' => 'El correo electrónico no es válido.',
    'user-disabled' =>
      'Esta cuenta está deshabilitada. Comunícate con soporte.',
    'email-already-in-use' =>
      'Ya existe una cuenta registrada con este correo electrónico.',
    'weak-password' => 'La contraseña es muy débil. Usa al menos 6 caracteres.',
    'operation-not-allowed' =>
      'Este método de acceso no está habilitado en Firebase.',
    'configuration-not-found' =>
      'Firebase Authentication no está configurado correctamente para este método de registro.',
    'app-not-authorized' =>
      'Esta aplicación no está autorizada para usar Firebase Authentication.',
    'internal-error' =>
      'Firebase Authentication tuvo un error interno. Inténtalo nuevamente.',
    'too-many-requests' =>
      'Se realizaron demasiados intentos. Espera un momento e inténtalo nuevamente.',
    'network-request-failed' =>
      'No se pudo conectar con Firebase. Revisa tu conexión a internet.',
    'account-exists-with-different-credential' =>
      'Ya existe una cuenta con este correo usando otro método de acceso.',
    'requires-recent-login' =>
      'Por seguridad, vuelve a iniciar sesión antes de continuar.',
    _ => 'No se pudo completar la operación. Inténtalo nuevamente.',
  };

  Future<AuthUserModel> _hydrate(User? user) async {
    if (user == null) {
      throw const ServerException('No se pudo obtener el usuario autenticado.');
    }
    Map<String, dynamic>? data;
    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      data = snapshot.data();
      await _syncOfficialSuperAdmin(user, data);
      await _linkCompanyInvite(user);
      final refreshed = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      data = refreshed.data() ?? data;
    } on FirebaseException {
      data = null;
    }
    return _hydrateFromOperationalDb(user, data);
  }

  Future<AuthUserModel> _hydrateFromOperationalDb(
    User user,
    Map<String, dynamic>? firestore,
  ) async {
    try {
      await HttpRemoteDatabase().rpc(
        'sync_identity_workspace',
        params: {
          'p_organization_id': firestore?['companyId'],
          'p_organization_name': firestore?['companyName'],
          'p_role': firestore?['role'],
        },
      );
      final session = await HttpRemoteDatabase().rpc('current_session_profile');
      final resolved = _userFromSession(user, firestore, session);
      if (resolved == null) {
        throw const ServerException(TalentErrorCodes.apiUnavailable);
      }
      return resolved;
    } on ServerException {
      await _firebaseAuth.signOut();
      rethrow;
    } on Object {
      await _firebaseAuth.signOut();
      throw const ServerException(TalentErrorCodes.apiUnavailable);
    }
  }

  AuthUserModel? _userFromSession(
    User user,
    Map<String, dynamic>? firestore,
    Object? session,
  ) {
    if (session is! Map) return null;
    final payload = Map<String, dynamic>.from(session);
    if (payload.isEmpty) return null;
    var role = UserRoleX.parse(payload['role']);
    if (SuperAdminConfig.matches(user.email)) {
      role = UserRole.superadmin;
    } else if (role == UserRole.superadmin) {
      role = UserRole.user;
    }
    return AuthUserModel(
      id: user.uid,
      email: user.email ?? '${payload['email'] ?? ''}',
      displayName:
          (payload['displayName'] as String?) ??
          (firestore?['displayName'] as String?) ??
          user.displayName,
      companyName: payload['organizationName'] as String?,
      role: role,
      companyId: payload['organizationId'] as String?,
      documentNumber: payload['documentNumber'] as String?,
      mustChangePassword: payload['mustChangePassword'] == true,
      mustReviewCompanyDna: payload['mustReviewCompanyDna'] == true,
    );
  }

  Future<void> _syncOfficialSuperAdmin(
    User user,
    Map<String, dynamic>? data,
  ) async {
    final official = SuperAdminConfig.matches(user.email);
    final current = UserRoleX.parse(data?['role']);
    if (official && current == UserRole.superadmin) return;
    if (!official && current != UserRole.superadmin) return;
    final hasCompany = (data?['companyId'] as String?)?.isNotEmpty == true;
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'role': official
            ? UserRole.superadmin.value
            : (current.isCompanyStaffRole
                  ? current.value
                  : hasCompany
                  ? UserRole.companyAdmin.value
                  : UserRole.user.value),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // El rol operativo lo confirma MySQL; Firestore solo se alinea.
    }
  }

  Future<void> _linkCompanyInvite(User user) async {
    final email = user.email?.trim().toLowerCase();
    if (email == null || !email.contains('@')) return;
    final userRef = _firestore.collection('users').doc(user.uid);
    Map<String, dynamic>? data;
    try {
      data = (await userRef.get()).data();
    } on FirebaseException {
      return;
    }
    final current = UserRoleX.parse(data?['role']);
    if (current == UserRole.superadmin || current == UserRole.respondent) {
      return;
    }
    if (current.isCompanyStaffRole &&
        (data?['companyId'] as String?)?.isNotEmpty == true) {
      return;
    }
    DocumentSnapshot<Map<String, dynamic>> invite;
    try {
      invite = await _firestore
          .collection('activation_invites')
          .doc(email)
          .get();
    } on FirebaseException {
      return;
    }
    if (!invite.exists) return;
    final payload = invite.data() ?? const <String, dynamic>{};
    if (payload['kind'] == 'respondent') return;
    final companyId = payload['companyId'] as String?;
    final role = UserRoleX.parse(payload['role']);
    if (companyId == null || companyId.isEmpty || !role.isCompanyStaffRole) {
      return;
    }
    try {
      final linked = <String, Object?>{
        'uid': user.uid,
        'email': email,
        'role': role.value,
        'companyId': companyId,
        'displayName': [
          payload['firstName'],
          payload['lastName'],
        ].whereType<String>().join(' ').trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      linked['mustReviewCompanyDna'] = false;
      await userRef.set(linked, SetOptions(merge: true));
    } on FirebaseException {
      // Sin permiso se deja el perfil como está; el usuario puede registrarse con el PIN.
    }
  }

  Future<void> _saveUserDocument(
    UserCredential credential, {
    String? displayName,
    String? companyName,
  }) async {
    final user = credential.user;
    if (user == null) {
      throw const ServerException('No se pudo obtener el usuario autenticado.');
    }
    final providers = user.providerData
        .map((provider) => provider.providerId)
        .toSet()
        .toList();
    final createdAt = user.metadata.creationTime;
    final data = <String, Object?>{
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName ?? user.displayName,
      'photoUrl': user.photoURL,
      'phoneNumber': user.phoneNumber,
      'emailVerified': user.emailVerified,
      'isAnonymous': user.isAnonymous,
      'isActive': true,
      'providers': providers,
      'primaryProvider':
          credential.credential?.providerId ??
          (providers.isEmpty ? null : providers.first),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };
    if (companyName != null) {
      data['companyName'] = companyName.trim().isEmpty
          ? null
          : companyName.trim();
    }
    final existing = await _firestore.collection('users').doc(user.uid).get();
    if (!existing.exists) {
      data['role'] = UserRole.user.value;
    }
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }

  Future<void> _saveUserDocumentWithRetry(
    UserCredential credential, {
    String? displayName,
    String? companyName,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _saveUserDocument(
          credential,
          displayName: displayName,
          companyName: companyName,
        );
        return;
      } catch (error) {
        lastError = error;
        if (attempt < 2) {
          await Future<void>.delayed(
            Duration(milliseconds: 250 * (attempt + 1)),
          );
        }
      }
    }
    if (lastError is FirebaseException) {
      throw ServerException(_firestoreErrorMessage(lastError.code));
    }
    if (lastError is ServerException) throw lastError;
    throw const ServerException(
      'La cuenta se creó en Authentication, pero no se pudo guardar el perfil en Firestore. Inicia sesión para reintentarlo.',
    );
  }

  @override
  Future<AuthUserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    return user == null ? null : _hydrate(user);
  }

  @override
  Future<AuthUserModel> signIn({
    required String email,
    required String password,
  }) => _handleFirebaseErrors(() async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _saveUserDocumentWithRetry(credential);
    return _hydrate(credential.user);
  });

  @override
  Future<AuthUserModel> signInWithCustomToken(String token) =>
      _handleFirebaseErrors(() async {
        final credential = await _firebaseAuth.signInWithCustomToken(token);

        return _hydrate(credential.user);
      });

  @override
  Future<AuthUserModel> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'});
        final credential = await monitorGooglePopup(
          () => _firebaseAuth.signInWithPopup(provider),
        );
        await _saveUserDocumentWithRetry(credential);
        return await _hydrate(credential.user);
      }

      await (_googleInitialization ??= _googleSignIn.initialize());
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      await _saveUserDocumentWithRetry(userCredential);
      return await _hydrate(userCredential.user);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'popup-closed-by-user' ||
          error.code == 'cancelled-popup-request') {
        throw const ServerException(
          'Cerraste la ventana de Google antes de completar el inicio de sesión.',
        );
      }
      if (error.code == 'popup-blocked') {
        throw const ServerException(
          'El navegador bloqueó la ventana de Google. Habilita las ventanas emergentes e inténtalo nuevamente.',
        );
      }
      throw const ServerException(
        'No se pudo iniciar sesión con Google. Inténtalo nuevamente.',
      );
    } on FirebaseException catch (error) {
      throw ServerException(_firestoreErrorMessage(error.code));
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const ServerException(
          'Cancelaste el inicio de sesión con Google.',
        );
      }
      throw const ServerException(
        'No se pudo iniciar sesión con Google. Inténtalo nuevamente.',
      );
    } on ServerException {
      rethrow;
    } catch (_) {
      throw const ServerException(
        'No se pudo iniciar sesión con Google. Inténtalo nuevamente.',
      );
    }
  }

  @override
  Future<AuthUserModel> signUp({
    required String email,
    required String password,
    String? displayName,
    String? companyName,
  }) => _handleFirebaseErrors(() async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (displayName != null && displayName.trim().isNotEmpty) {
      try {
        await credential.user?.updateDisplayName(displayName.trim());
      } on FirebaseAuthException {
        // El nombre también se guarda en Firestore; no se elimina la cuenta
        // si Firebase Auth no puede actualizar este dato opcional.
      }
    }
    await _saveUserDocumentWithRetry(
      credential,
      displayName: displayName?.trim(),
      companyName: companyName?.trim(),
    );
    return _hydrate(_firebaseAuth.currentUser);
  });

  @override
  Future<void> signOut() => _handleFirebaseErrors(() async {
    await _firebaseAuth.signOut();
    if (!kIsWeb) await _googleSignIn.signOut();
  });

  @override
  Future<void> discardCurrentUser() => _handleFirebaseErrors(() async {
    await _firebaseAuth.currentUser?.delete();
  });

  @override
  Future<void> sendPasswordResetEmail(String email) => _handleFirebaseErrors(
    () => _firebaseAuth.sendPasswordResetEmail(email: email),
  );
}

/// Implementación temporal reemplazable por Firebase o una API.
final class InMemoryAuthRemoteDataSource implements AuthRemoteDataSource {
  AuthUserModel? _currentUser;

  @override
  Future<AuthUserModel?> getCurrentUser() async => _currentUser;

  @override
  Future<AuthUserModel> signIn({
    required String email,
    required String password,
  }) async {
    _validate(email, password);
    return _currentUser = AuthUserModel(
      id: email,
      email: email,
      role: SuperAdminConfig.matches(email)
          ? UserRole.superadmin
          : UserRole.user,
    );
  }

  @override
  Future<AuthUserModel> signInWithCustomToken(String token) async {
    if (token.trim().isEmpty) {
      throw const ServerException('El enlace de invitación no es válido.');
    }

    return _currentUser = AuthUserModel(
      id: token,
      email: '',
      role: UserRole.respondent,
    );
  }

  @override
  Future<AuthUserModel> signInWithGoogle() async => throw const ServerException(
    'Google Sign-In no está disponible en el modo de memoria.',
  );

  @override
  Future<AuthUserModel> signUp({
    required String email,
    required String password,
    String? displayName,
    String? companyName,
  }) async {
    _validate(email, password);
    return _currentUser = AuthUserModel(
      id: email,
      email: email,
      displayName: displayName,
      companyName: companyName,
      role: SuperAdminConfig.matches(email)
          ? UserRole.superadmin
          : UserRole.user,
    );
  }

  @override
  Future<void> signOut() async => _currentUser = null;

  @override
  Future<void> discardCurrentUser() async => _currentUser = null;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (!_isValidEmail(email)) {
      throw const ServerException('Ingresa un correo válido.');
    }
  }

  void _validate(String email, String password) {
    if (!_isValidEmail(email) || password.length < 6) {
      throw const ServerException(
        'Usa un correo válido y una contraseña de al menos 6 caracteres.',
      );
    }
  }

  bool _isValidEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
}
