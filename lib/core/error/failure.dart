import 'package:equatable/equatable.dart';

/// Features can add their own final failures. `base` keeps the type from
/// being implemented as an unrelated class.
abstract base class Failure extends Equatable {
  const Failure(this.message);
  final String message;
  @override
  List<Object> get props => [message];
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
