import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talex_platform/core/data/http_remote_database.dart';
import 'package:talex_platform/core/data/remote_database.dart';
import 'package:talex_platform/core/locale/locale_cubit.dart';
import 'package:talex_platform/core/location/location_catalog.dart';
import 'package:talex_platform/core/services/notification_service.dart';
import 'package:talex_platform/features/admin/data/datasources/admin_data_source.dart';
import 'package:talex_platform/features/admin/data/datasources/assessment_question_data_source.dart';
import 'package:talex_platform/features/admin/data/datasources/supabase_admin_data_source.dart';
import 'package:talex_platform/features/admin/data/datasources/supabase_assessment_question_data_source.dart';
import 'package:talex_platform/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:talex_platform/features/admin/domain/repositories/admin_repository.dart';
import 'package:talex_platform/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:talex_platform/features/assistant/data/datasources/assistant_remote_data_source.dart';
import 'package:talex_platform/features/assistant/data/repositories/assistant_repository_impl.dart';
import 'package:talex_platform/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:talex_platform/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:talex_platform/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:talex_platform/features/auth/data/services/password_recovery_service.dart';
import 'package:talex_platform/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:talex_platform/features/auth/domain/repositories/auth_repository.dart';
import 'package:talex_platform/features/auth/domain/usecases/auth_usecases.dart';
import 'package:talex_platform/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:talex_platform/features/invitations/data/datasources/invitation_data_source.dart';
import 'package:talex_platform/features/invitations/data/repositories/invitation_repository_impl.dart';
import 'package:talex_platform/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:talex_platform/features/invitations/domain/usecases/invitation_usecases.dart';
import 'package:talex_platform/features/invitations/presentation/bloc/invitation_bloc.dart';
import 'package:talex_platform/features/talent/data/datasources/supabase_talent_data_source.dart';
import 'package:talex_platform/features/talent/data/datasources/talent_data_source.dart';
import 'package:talex_platform/features/talent/data/repositories/talent_repository_impl.dart';
import 'package:talex_platform/features/talent/data/services/invite_email_service.dart';
import 'package:talex_platform/features/talent/domain/repositories/talent_repository.dart';
import 'package:talex_platform/features/talent/presentation/bloc/talent_bloc.dart';

final getIt = GetIt.instance;

RemoteDatabase resolveRemoteDatabase() => HttpRemoteDatabase();

Future<void> configureDependencies() async {
  if (getIt.isRegistered<NotificationService>()) {
    await getIt.reset();
  }
  final prefs = await SharedPreferences.getInstance();
  getIt
    ..registerLazySingleton(() => prefs)
    ..registerLazySingleton(() => LocaleCubit(getIt()))
    ..registerLazySingleton(NotificationService.new)
    ..registerLazySingleton(() => FirebaseAuth.instance)
    ..registerLazySingleton(() => FirebaseFirestore.instance)
    ..registerLazySingleton(() => FirebaseStorage.instance)
    ..registerLazySingleton(
      () => FirebaseFunctions.instanceFor(region: 'us-central1'),
    )
    ..registerLazySingleton(() => LocationCatalog())
    ..registerLazySingleton(() => InviteEmailService(getIt()))
    ..registerLazySingleton(() => PasswordRecoveryService(getIt()))
    ..registerLazySingleton(() => GoogleSignIn.instance)
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => FirebaseAuthRemoteDataSource(getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt()))
    ..registerLazySingleton(() => SignIn(getIt()))
    ..registerLazySingleton(() => SignInWithGoogle(getIt()))
    ..registerLazySingleton(() => SignUp(getIt()))
    ..registerLazySingleton(() => SignOut(getIt()))
    ..registerLazySingleton(() => GetCurrentUser(getIt()))
    ..registerLazySingleton(() => SendPasswordResetEmail(getIt()))
    ..registerFactory(
      () => AuthBloc(
        signIn: getIt(),
        signInWithGoogle: getIt(),
        signUp: getIt(),
        signOut: getIt(),
        getCurrentUser: getIt(),
        sendPasswordResetEmail: getIt(),
        talentRepository: getIt(),
        authRepository: getIt(),
      ),
    );
  configureInvitationDependencies();
  configureAdminDependencies();
  configureTalentDependencies();
  configureAssistantDependencies();
}

void configureAdminDependencies() {
  if (getIt.isRegistered<AdminBloc>()) return;
  getIt
    ..registerLazySingleton<AdminDataSource>(
      () => SupabaseAdminDataSource(getIt(), database: resolveRemoteDatabase()),
    )
    ..registerLazySingleton<AssessmentQuestionDataSource>(
      () => SupabaseAssessmentQuestionDataSource(
        database: resolveRemoteDatabase(),
      ),
    )
    ..registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl(getIt()))
    ..registerFactory(() => AdminBloc(repository: getIt()));
}

void configureTalentDependencies() {
  if (getIt.isRegistered<TalentBloc>()) return;
  getIt
    ..registerLazySingleton<TalentDataSource>(
      () => SupabaseTalentDataSource(
        getIt(),
        getIt(),
        getIt(),
        database: resolveRemoteDatabase(),
      ),
    )
    ..registerLazySingleton<TalentRepository>(
      () => TalentRepositoryImpl(getIt(), getIt()),
    )
    ..registerFactory(() => TalentBloc(repository: getIt()));
}

void configureAssistantDependencies() {
  if (getIt.isRegistered<AssistantRepository>()) return;
  getIt
    ..registerLazySingleton<AssistantRemoteDataSource>(
      () => CallableAssistantDataSource(getIt()),
    )
    ..registerLazySingleton<AssistantRepository>(
      () => AssistantRepositoryImpl(
        readAdminRepository: () => getIt.isRegistered<AdminRepository>()
            ? getIt<AdminRepository>()
            : null,
        remote: getIt<AssistantRemoteDataSource>(),
      ),
    )
    ..registerFactory(() => AssistantBloc(repository: getIt()));
}

void configureInvitationDependencies() {
  if (getIt.isRegistered<InvitationBloc>()) return;
  getIt
    ..registerLazySingleton<InvitationDataSource>(
      InMemoryInvitationDataSource.new,
    )
    ..registerLazySingleton<InvitationRepository>(
      () => InvitationRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => GetInvitations(getIt()))
    ..registerLazySingleton(() => CreateInvitation(getIt()))
    ..registerLazySingleton(() => ResendInvitation(getIt()))
    ..registerLazySingleton(() => CancelInvitation(getIt()))
    ..registerFactory(
      () => InvitationBloc(
        getInvitations: getIt(),
        createInvitation: getIt(),
        resendInvitation: getIt(),
        cancelInvitation: getIt(),
      ),
    );
}
