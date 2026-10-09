import '../error/exceptions.dart';

/// Runs [parse] on a response body, turning malformed payloads into a
/// [ServerException] instead of a crash.
T parseResponse<T>(T Function() parse) {
  try {
    return parse();
  } on FormatException {
    throw const ServerException('Unexpected response from server.');
  } on TypeError {
    throw const ServerException('Unexpected response from server.');
  }
}
