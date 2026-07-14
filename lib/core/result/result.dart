sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.failure);

  final AppFailure failure;
}

sealed class AppFailure {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'A network error occurred.']);
}

final class DataParsingFailure extends AppFailure {
  const DataParsingFailure([super.message = 'Received malformed data.']);
}

final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure([super.message = 'Something went wrong.']);
}
