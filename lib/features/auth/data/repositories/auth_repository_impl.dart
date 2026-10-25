import 'package:dartz/dartz.dart';
import 'package:talex_platform/core/error/exceptions.dart';
import 'package:talex_platform/core/error/failure.dart';
import 'package:talex_platform/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:talex_platform/features/auth/data/mappers/auth_user_mapper.dart';
import 'package:talex_platform/features/auth/domain/entities/auth_user.dart';
import 'package:talex_platform/features/auth/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._source);

  final AuthRemoteDataSource _source;

  Future<Either<Failure, T>> _guard<T>(
    Future<T> Function() action,
  ) async {
    try {
      return Right(await action());
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (_) {
      return const Left(
        UnexpectedFailure(
          'No se pudo completar la operación. Inténtalo nuevamente.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, AuthUser?>> getCurrentUser() =>
      _guard(() async => (await _source.getCurrentUser())?.toEntity());

  @override
  Future<Either<Failure, AuthUser>> signIn({
    required String email,
    required String password,
  }) =>
      _guard(
        () async =>
            (await _source.signIn(
              email: email,
              password: password,
            ))
                .toEntity(),
      );

  @override
  Future<Either<Failure, AuthUser>> signInWithCustomToken({
    required String token,
  }) =>
      _guard(
        () async =>
            (await _source.signInWithCustomToken(token)).toEntity(),
      );

  @override
  Future<Either<Failure, AuthUser>> signInWithGoogle() =>
      _guard(() async => (await _source.signInWithGoogle()).toEntity());

  @override
  Future<Either<Failure, AuthUser>> signUp({
    required String email,
    required String password,
    String? displayName,
    String? companyName,
  }) =>
      _guard(
        () async =>
            (await _source.signUp(
              email: email,
              password: password,
              displayName: displayName,
              companyName: companyName,
            ))
                .toEntity(),
      );

  @override
  Future<Either<Failure, Unit>> signOut() => _guard(() async {
        await _source.signOut();
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> discardCurrentUser() => _guard(() async {
        await _source.discardCurrentUser();
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) =>
      _guard(() async {
        await _source.sendPasswordResetEmail(email);
        return unit;
      });
}