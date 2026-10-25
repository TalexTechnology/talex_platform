part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
}

final class AuthSessionRequested extends AuthEvent {
  const AuthSessionRequested();
  @override
  List<Object?> get props => [];
}

final class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});
  final String email;
  final String password;
  @override
  List<Object> get props => [email, password];
}

final class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested({this.awaitInvitePin = false});
  final bool awaitInvitePin;
  @override
  List<Object?> get props => [awaitInvitePin];
}

final class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    this.displayName,
    this.pin,
  });
  final String email;
  final String password;
  final String? displayName;
  final String? pin;
  @override
  List<Object?> get props => [email, password, displayName, pin];
}

final class AuthInvitePinSubmitted extends AuthEvent {
  const AuthInvitePinSubmitted(this.pin);
  final String pin;
  @override
  List<Object> get props => [pin];
}

final class AuthRespondentInviteRequested extends AuthEvent {
  const AuthRespondentInviteRequested(this.token);

  final String token;

  @override
  List<Object> get props => [token];
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
  @override
  List<Object?> get props => [];
}

final class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested({required this.email});
  final String email;
  @override
  List<Object> get props => [email];
}
