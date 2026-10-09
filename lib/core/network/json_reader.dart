/// Lenient, typed reads from decoded API JSON. Money can arrive as a number
/// or a numeric string; timestamps as ISO strings; missing keys as null.
///
/// Required reads throw [FormatException] so a data source can turn a broken
/// payload into a `ServerException`.
extension type const JsonReader(Map<String, Object?> json) {
  static JsonReader? maybe(Object? value) =>
      value is Map<String, Object?> ? JsonReader(value) : null;

  static JsonReader of(Object? value) =>
      maybe(value) ?? (throw const FormatException('Expected a JSON object'));

  bool has(String key) => json[key] != null;

  String string(String key) => switch (json[key]) {
    final String s => s,
    final num n => n.toString(),
    _ => throw FormatException('Missing "$key"'),
  };

  String? stringOrNull(String key) => switch (json[key]) {
    final String s when s.isNotEmpty => s,
    final num n => n.toString(),
    _ => null,
  };

  double number(String key, [double fallback = 0]) =>
      numberOrNull(key) ?? fallback;

  double? numberOrNull(String key) => switch (json[key]) {
    final num n => n.toDouble(),
    final String s => double.tryParse(s),
    _ => null,
  };

  int integer(String key, [int fallback = 0]) => intOrNull(key) ?? fallback;

  int? intOrNull(String key) => switch (json[key]) {
    final int n => n,
    final num n => n.round(),
    final String s => int.tryParse(s),
    _ => null,
  };

  bool boolean(String key, [bool fallback = false]) => switch (json[key]) {
    final bool b => b,
    _ => fallback,
  };

  DateTime date(String key) =>
      dateOrNull(key) ?? (throw FormatException('Missing date "$key"'));

  /// ISO timestamps are converted to local time; date-only values
  /// (`2026-11-12`) are read as local calendar dates.
  DateTime? dateOrNull(String key) => switch (json[key]) {
    final String s => DateTime.tryParse(s)?.toLocal(),
    _ => null,
  };

  JsonReader? object(String key) => maybe(json[key]);

  List<JsonReader> objects(String key) => switch (json[key]) {
    final List<Object?> items => [
      for (final item in items)
        if (item is Map<String, Object?>) JsonReader(item),
    ],
    _ => const [],
  };

  List<String> strings(String key) => switch (json[key]) {
    final List<Object?> items => items.whereType<String>().toList(),
    _ => const [],
  };
}

/// Unwraps list endpoints that answer either `[...]` or `{data: [...]}`.
List<JsonReader> readList(Object? json) => switch (json) {
  final List<Object?> items => [
    for (final item in items)
      if (item is Map<String, Object?>) JsonReader(item),
  ],
  final Map<String, Object?> map => JsonReader(map).objects('data'),
  _ => throw const FormatException('Expected a list'),
};
