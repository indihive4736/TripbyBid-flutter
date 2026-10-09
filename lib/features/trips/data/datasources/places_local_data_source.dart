import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/new_trip_request.dart';
import '../../domain/entities/trip_request.dart';

/// Which bundled dataset a trip type searches.
enum PlaceKind {
  airport('assets/data/airports.json'),
  station('assets/data/stations.json'),
  city('assets/data/cities.json');

  const PlaceKind(this.asset);

  final String asset;

  static PlaceKind of(TripType type) => switch (type) {
    TripType.flight || TripType.package => airport,
    TripType.train => station,
    TripType.hotel => city,
  };
}

/// One dataset row, with lower-cased search keys and the [Place] it becomes.
final class PlaceRecord {
  const PlaceRecord({
    required this.place,
    required this.code,
    required this.name,
    required this.rank,
    this.city = '',
    this.alt = const [],
    this.country,
  });

  final Place place;
  final String code;
  final String name;
  final String city;
  final List<String> alt;

  /// Lower is more prominent (the datasets are ordered by it).
  final int rank;
  final String? country;
}

/// Searches the airports, stations and cities bundled in `assets/data/`
/// (the web client's datasets). Throws [CacheException] when a dataset
/// cannot be read.
abstract interface class PlacesLocalDataSource {
  Future<List<Place>> search(TripType type, String query);
}

class PlacesLocalDataSourceImpl implements PlacesLocalDataSource {
  /// Loads each dataset lazily, once, through [loadAsset] (the root asset
  /// bundle by default) and parses it off the UI thread.
  PlacesLocalDataSourceImpl({Future<String> Function(String key)? loadAsset})
    : _loadAsset = loadAsset ?? rootBundle.loadString;

  /// Uses already-decoded rows instead of the bundled assets (tests).
  PlacesLocalDataSourceImpl.fromRaw({
    List<Object?> airports = const [],
    List<Object?> stations = const [],
    List<Object?> cities = const [],
  }) : _loadAsset = _noAssets {
    _ready[PlaceKind.airport] = parseAirports(airports);
    _ready[PlaceKind.station] = parseStations(stations);
    _ready[PlaceKind.city] = parseCities(cities);
  }

  static Future<String> _noAssets(String key) =>
      throw StateError('No asset loader');

  final Future<String> Function(String key) _loadAsset;

  /// Parsed datasets, kept for the app's lifetime.
  final _ready = <PlaceKind, List<PlaceRecord>>{};

  /// Loads in progress, shared by concurrent searches.
  final _loading = <PlaceKind, Future<List<PlaceRecord>>>{};

  @override
  Future<List<Place>> search(TripType type, String query) async {
    final kind = PlaceKind.of(type);
    final data = await _dataset(kind);
    return PlaceRanking.rank(data, query, kind: kind);
  }

  Future<List<PlaceRecord>> _dataset(PlaceKind kind) async {
    if (_ready[kind] case final data?) return data;
    try {
      return _ready[kind] = await (_loading[kind] ??= _load(kind));
    } finally {
      // On failure the next search tries again.
      _loading.removeWhere((k, _) => k == kind);
    }
  }

  Future<List<PlaceRecord>> _load(PlaceKind kind) async {
    try {
      final raw = await _loadAsset(kind.asset);
      return await compute(switch (kind) {
        PlaceKind.airport => _decodeAirports,
        PlaceKind.station => _decodeStations,
        PlaceKind.city => _decodeCities,
      }, raw);
    } catch (_) {
      throw const CacheException('Could not load the list of places.');
    }
  }
}

List<PlaceRecord> _decodeAirports(String raw) =>
    parseAirports(jsonDecode(raw) as List<Object?>);

List<PlaceRecord> _decodeStations(String raw) =>
    parseStations(jsonDecode(raw) as List<Object?>);

List<PlaceRecord> _decodeCities(String raw) =>
    parseCities(jsonDecode(raw) as List<Object?>);

/// `[{iata, name, city, country, rank, alt?}]`
@visibleForTesting
List<PlaceRecord> parseAirports(List<Object?> rows) => [
  for (final row in rows.whereType<Map<String, Object?>>())
    if (_str(row['iata']) case final code? when code.isNotEmpty)
      if (_str(row['name']) case final name?)
        PlaceRecord(
          place: Place(
            name: name,
            code: code,
            city: _str(row['city']),
            country: _str(row['country']),
          ),
          code: code.toLowerCase(),
          name: name.toLowerCase(),
          city: _str(row['city'])?.toLowerCase() ?? '',
          alt: _alt(row['alt']),
          rank: _int(row['rank']),
          country: _str(row['country']),
        ),
];

/// `[{name, code}]`, ordered by traffic — the order is the rank.
@visibleForTesting
List<PlaceRecord> parseStations(List<Object?> rows) {
  final records = <PlaceRecord>[];
  for (final row in rows.whereType<Map<String, Object?>>()) {
    final code = _str(row['code'])?.trim();
    final name = _str(row['name'])?.trim();
    if (code == null || code.isEmpty || name == null || name.isEmpty) continue;
    records.add(
      PlaceRecord(
        place: Place(name: titleCase(name), code: code, country: 'IN'),
        code: code.toLowerCase(),
        name: name.toLowerCase(),
        rank: records.length,
        country: 'IN',
      ),
    );
  }
  return records;
}

/// `[{city, country, rank, alt?}]`
@visibleForTesting
List<PlaceRecord> parseCities(List<Object?> rows) => [
  for (final row in rows.whereType<Map<String, Object?>>())
    if (_str(row['city']) case final city? when city.isNotEmpty)
      PlaceRecord(
        place: Place(name: city, city: city, country: _str(row['country'])),
        code: '',
        name: city.toLowerCase(),
        city: city.toLowerCase(),
        alt: _alt(row['alt']),
        rank: _int(row['rank']),
        country: _str(row['country']),
      ),
];

/// `NEW DELHI` → `New Delhi`.
@visibleForTesting
String titleCase(String value) => value
    .toLowerCase()
    .split(' ')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');

String? _str(Object? value) => value is String ? value : null;

int _int(Object? value) => value is num ? value.toInt() : 0;

List<String> _alt(Object? value) => value is List<Object?>
    ? [for (final a in value.whereType<String>()) a.toLowerCase()]
    : const [];

/// The web client's ranking (`rankLocations` in `lib/utils/locations.ts`).
abstract final class PlaceRanking {
  static const maxResults = 50;
  static const previewCount = 8;

  /// Shown first for an empty query, when present in the dataset.
  static const _popularAirports = [
    'del', 'bom', 'blr', 'hyd', 'maa', 'ccu', 'goi', 'cok', //
  ];
  static const _popularCities = [
    'mumbai', 'new delhi', 'bengaluru', 'jaipur', //
    'hyderabad', 'chennai', 'kochi', 'kolkata',
  ];

  /// Exact code beats exact city or name, which beat prefix matches, which
  /// beat substring matches; former names ("Bombay") score a tier lower.
  /// Ties fall back to dataset prominence, then name.
  static List<Place> rank(
    List<PlaceRecord> data,
    String rawQuery, {
    PlaceKind kind = PlaceKind.airport,
  }) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return _popular(data, kind);

    final scored = <(PlaceRecord, int)>[];
    for (final r in data) {
      final score = _score(r, query);
      if (score > 0) scored.add((r, score));
    }
    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      if (byScore != 0) return byScore;
      final byRank = a.$1.rank.compareTo(b.$1.rank);
      if (byRank != 0) return byRank;
      return a.$1.name.compareTo(b.$1.name);
    });
    return [for (final (r, _) in scored.take(maxResults)) r.place];
  }

  static int _score(PlaceRecord r, String q) {
    final alt = _altTier(r.alt, q);
    if (r.code == q) return 100;
    if (r.city.isNotEmpty && r.city == q) return 96;
    if (r.name == q) return 95;
    if (alt == 3) return 90;
    if (r.code.isNotEmpty && r.code.startsWith(q)) return 80;
    if (r.city.isNotEmpty && r.city.startsWith(q)) return 75;
    if (r.name.startsWith(q)) return 70;
    if (alt == 2) return 65;
    if (r.code.contains(q)) return 50;
    if (r.city.contains(q)) return 45;
    if (r.name.contains(q)) return 40;
    if (alt == 1) return 35;
    return 0;
  }

  /// Best of exact (3), prefix (2), substring (1) or none (0).
  static int _altTier(List<String> values, String q) {
    var best = 0;
    for (final v in values) {
      if (v.isEmpty) continue;
      if (v == q) return 3;
      if (v.startsWith(q)) {
        best = 2;
      } else if (best < 1 && v.contains(q)) {
        best = 1;
      }
    }
    return best;
  }

  static List<Place> _popular(List<PlaceRecord> data, PlaceKind kind) {
    final picks = <PlaceRecord>[];
    final curated = switch (kind) {
      PlaceKind.airport => _popularAirports,
      PlaceKind.city => _popularCities,
      PlaceKind.station => const <String>[],
    };
    for (final key in curated) {
      final hit = data.where(
        (r) => kind == PlaceKind.airport ? r.code == key : r.city == key,
      );
      if (hit.isNotEmpty) picks.add(hit.first);
    }
    // Fill up from the head of the dataset, Indian places first.
    final rest = [
      ...data.where((r) => r.country == 'IN'),
      ...data.where((r) => r.country != 'IN'),
    ];
    for (final r in rest) {
      if (picks.length >= previewCount) break;
      if (!picks.contains(r)) picks.add(r);
    }
    return [for (final r in picks.take(previewCount)) r.place];
  }
}
