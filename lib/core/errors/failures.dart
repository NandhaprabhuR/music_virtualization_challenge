import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({super.message = 'A server error occurred'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'A cache error occurred'});
}

class NoInternetFailure extends Failure {
  const NoInternetFailure({super.message = 'NO INTERNET CONNECTION'});
}
