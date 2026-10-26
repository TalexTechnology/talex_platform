part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  loading,
  googleLoading,
  googleFailure,
  authenticated,
  unauthenticated,
  passwordResetSent,
  needsInvitePin,
  failure,
}

@CopyWith()
class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.initial, this.failure, this.user});
  final AuthStatus status;
  final Failure? failure;
  final AuthUser? user;
  @override
  List<Object?> get props => [status, failure, user];
}
