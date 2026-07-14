/// Outcome of a data operation. Repositories return this instead of throwing,
/// so callers handle [Success] and [Failure] exhaustively in a switch.
sealed class Result<T> {
  const Result();
}

/// The operation completed and produced [value].
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

/// The operation failed; [failure] says why.
final class Failure<T> extends Result<T> {
  const Failure(this.failure);

  final AppFailure failure;
}

/// The closed set of failures a repository can report.
sealed class AppFailure {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The (simulated) network request failed.
final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'A network error occurred.']);
}

/// The payload came back but could not be parsed into models.
final class DataParsingFailure extends AppFailure {
  const DataParsingFailure([super.message = 'Received malformed data.']);
}

/// Anything that is neither a network nor a parsing problem.
final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure([super.message = 'Something went wrong.']);
}
