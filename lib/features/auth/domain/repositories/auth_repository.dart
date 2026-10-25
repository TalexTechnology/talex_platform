import 'package:dartz/dartz.dart';
import 'package:talex_platform/core/error/failure.dart';
import 'package:talex_platform/features/auth/domain/entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, AuthUser?>> getCurrentUser();

  Future<Either<Failure, AuthUser>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthUser>> signInWithCustomToken({
    required String token,
  });

  Future<Either<Failure, AuthUser>> signInWithGoogle();

  Future<Either<Failure, AuthUser>> signUp({
    required String email,
    required String password,
    String? displayName,
    String? companyName,
  });

  Future<Either<Failure, Unit>> signOut();

  Future<Either<Failure, Unit>> discardCurrentUser();

  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email);
}