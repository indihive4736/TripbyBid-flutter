import 'exceptions.dart';
import 'result.dart';

/// Runs a data-layer call and converts any [AppException] it throws into an
/// [Err] — the standard body of a repository method.
Future<Result<T>> guard<T>(Future<T> Function() call) async {
  try {
    return Ok(await call());
  } on AppException catch (e) {
    return Err(e.toFailure());
  }
}
