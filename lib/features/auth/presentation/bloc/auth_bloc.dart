import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talex_platform/core/error/failure.dart';
import 'package:talex_platform/features/auth/domain/entities/auth_user.dart';
import 'package:talex_platform/features/auth/domain/repositories/auth_repository.dart';
import 'package:talex_platform/features/auth/domain/usecases/auth_usecases.dart';
import 'package:talex_platform/features/talent/domain/repositories/talent_repository.dart';
import 'package:talex_platform/features/talent/domain/services/assessment_invite_link.dart';

part 'auth_event.dart';
part 'auth_state.dart';
part 'auth_bloc.g.dart';

final class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SignIn signIn,
    required SignInWithGoogle signInWithGoogle,
    required SignUp signUp,
    required SignOut signOut,
    required GetCurrentUser getCurrentUser,
    required SendPasswordResetEmail sendPasswordResetEmail,
    TalentRepository? talentRepository,
    AuthRepository? authRepository,
  }) : _signIn = signIn,
       _signInWithGoogle = signInWithGoogle,
       _signUp = signUp,
       _signOut = signOut,
       _getCurrentUser = getCurrentUser,
       _sendPasswordResetEmail = sendPasswordResetEmail,
       _talentRepository = talentRepository,
       _authRepository = authRepository,
       super(const AuthState()) {
    on<AuthSessionRequested>(_onSessionRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthInvitePinSubmitted>(_onInvitePinSubmitted);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthRespondentInviteRequested>(_onRespondentInviteRequested);
  }

  final SignIn _signIn;
  final SignInWithGoogle _signInWithGoogle;
  final SignUp _signUp;
  final SignOut _signOut;
  final GetCurrentUser _getCurrentUser;
  final SendPasswordResetEmail _sendPasswordResetEmail;
  final TalentRepository? _talentRepository;
  final AuthRepository? _authRepository;

  Future<void> _onSessionRequested(
    AuthSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (AssessmentInviteLink.tokenFromUri(Uri.base) != null) {
      return;
    }
    emit(state.copyWith(status: AuthStatus.loading, failure: null));
    final result = await _getCurrentUser();
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: AuthStatus.failure,
          failure: failure,
          user: null,
        ),
        (user) => state.copyWith(
          status: user == null
              ? AuthStatus.unauthenticated
              : AuthStatus.authenticated,
          user: user,
          failure: null,
        ),
      ),
    );
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, failure: null));
    final result = await _signIn(
      SignInParams(email: event.email, password: event.password),
    );
    await _emitAuthenticated(emit, result);
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, failure: null));
    final result = await _signUp(
      SignUpParams(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      ),
    );
    await _emitAuthenticated(emit, result, pin: event.pin, createdAccount: true);
  }

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.googleLoading, failure: null));
    final result = await _signInWithGoogle();
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: AuthStatus.googleFailure,
            failure: failure,
            user: null,
          ),
        );
      },
      (user) async {
        if (event.awaitInvitePin && _needsInvitePin(user)) {
          emit(
            state.copyWith(
              status: AuthStatus.needsInvitePin,
              user: user,
              failure: null,
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            failure: null,
          ),
        );
      },
    );
  }

  Future<void> _onInvitePinSubmitted(
    AuthInvitePinSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, failure: null));
    final talent = _talentRepository;
    if (talent == null) {
      emit(
        state.copyWith(
          status: AuthStatus.needsInvitePin,
          failure: const ServerFailure('unexpected'),
        ),
      );
      return;
    }
    final activated = await talent.activateWithPin(pin: event.pin);
    await activated.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: AuthStatus.needsInvitePin,
            failure: failure,
          ),
        );
      },
      (_) async {
        final refreshed = await _getCurrentUser();
        emit(
          refreshed.fold(
            (failure) => state.copyWith(
              status: AuthStatus.failure,
              failure: failure,
            ),
            (user) => state.copyWith(
              status: user == null
                  ? AuthStatus.unauthenticated
                  : AuthStatus.authenticated,
              user: user,
              failure: null,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onRespondentInviteRequested(
    AuthRespondentInviteRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        failure: null,
        user: null,
      ),
    );

    final talent = _talentRepository;
    final auth = _authRepository;

    if (talent == null || auth == null) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          failure: const ServerFailure('unexpected'),
          user: null,
        ),
      );
      return;
    }

    final redeemed = await talent.redeemRespondentInvite(
      token: event.token,
    );

    await redeemed.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: AuthStatus.failure,
            failure: failure,
            user: null,
          ),
        );
      },
      (customToken) async {
        final signedIn = await auth.signInWithCustomToken(
          token: customToken,
        );

        await signedIn.fold(
          (failure) async {
            emit(
              state.copyWith(
                status: AuthStatus.failure,
                failure: failure,
                user: null,
              ),
            );
          },
          (user) async {
            emit(
              state.copyWith(
                status: AuthStatus.authenticated,
                user: user,
                failure: null,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, failure: null));
    final result = await _signOut();
    emit(
      result.fold(
        (failure) =>
            state.copyWith(status: AuthStatus.failure, failure: failure),
        (_) => state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          failure: null,
        ),
      ),
    );
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, failure: null));
    final result = await _sendPasswordResetEmail(
      SendPasswordResetEmailParams(email: event.email),
    );
    emit(
      result.fold(
        (failure) =>
            state.copyWith(status: AuthStatus.failure, failure: failure),
        (_) =>
            state.copyWith(status: AuthStatus.passwordResetSent, failure: null),
      ),
    );
  }

  bool _needsInvitePin(AuthUser user) =>
      !user.isSuperAdmin && !user.isRespondent && !user.isCompanyStaff;

  Future<void> _emitAuthenticated(
    Emitter<AuthState> emit,
    Either<Failure, AuthUser> result, {
    String? pin,
    bool createdAccount = false,
  }) async {
    await result.fold((failure) async {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          failure: failure,
          user: null,
        ),
      );
    }, (user) async {
      var next = user;
      final talent = _talentRepository;
      if (talent != null && pin != null && pin.trim().isNotEmpty) {
        final activated = await talent.activateWithPin(pin: pin.trim());
        final failed = activated.fold((failure) => failure, (_) => null);
        if (failed != null) {
          if (createdAccount) {
            await _authRepository?.discardCurrentUser();
          } else {
            await _signOut();
          }
          emit(
            state.copyWith(
              status: AuthStatus.failure,
              failure: failed,
              user: null,
            ),
          );
          return;
        }
        final refreshed = await _getCurrentUser();
        refreshed.fold((_) {}, (current) {
          if (current != null) next = current;
        });
      }
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: next,
          failure: null,
        ),
      );
    });
  }
}
