import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tripbybid/core/error/exceptions.dart';
import 'package:tripbybid/features/trips/data/datasources/places_local_data_source.dart';
import 'package:tripbybid/features/trips/domain/entities/new_trip_request.dart';
import 'package:tripbybid/features/trips/domain/entities/trip_request.dart';

void main() {
  // A tiny dataset that exercises every scoring tier.
  final airports = <Object?>[
    {
      'iata': 'BOM',
      'name': 'Chhatrapati Shivaji Maharaj International Airport',
      'city': 'Mumbai',
      'country': 'IN',
      'rank': 0,
      'alt': ['Bombay', 'Sahar'],
    },
    {
      'iata': 'DEL',
      'name': 'Indira Gandhi International Airport',
      'city': 'New Delhi',
      'country': 'IN',
      'rank': 0,
    },
    {
      'iata': 'DXB',
      'name': 'Dubai International Airport',
      'city': 'Dubai',
      'country': 'AE',
      'rank': 0,
    },
    {
      'iata': 'DWC',
      'name': 'Al Maktoum International Airport',
      'city': 'Dubai',
      'country': 'AE',
      'rank': 1,
      'alt': ['Dubai World Central'],
    },
    {
      'iata': 'MUN',
      'name': 'Maturin Airport',
      'city': 'Maturin',
      'country': 'VE',
      'rank': 3,
    },
    {
      'iata': 'IXD',
      'name': 'Delhi Road Airfield',
      'city': 'Prayagraj',
      'country': 'IN',
      'rank': 2,
    },
  ];

  final stations = <Object?>[
    {'name': 'NEW DELHI', 'code': 'NDLS'},
    {'name': 'MUMBAI CENTRAL', 'code': 'MMCT'},
    {'name': 'DELHI JN', 'code': 'DLI'},
  ];

  final cities = <Object?>[
    {
      'city': 'Mumbai',
      'country': 'IN',
      'rank': 0,
      'alt': ['Bombay'],
    },
    {'city': 'Goa Velha', 'country': 'IN', 'rank': 2},
    {'city': 'Dubai', 'country': 'AE', 'rank': 0},
  ];

  final source = PlacesLocalDataSourceImpl.fromRaw(
    airports: airports,
    stations: stations,
    cities: cities,
  );

  Future<List<String?>> codes(String query) async => [
    for (final p in await source.search(TripType.flight, query)) p.code,
  ];

  group('airport ranking', () {
    test('an exact code wins', () async {
      expect((await codes('dxb')).first, 'DXB');
      expect((await codes('BOM')).first, 'BOM');
    });

    test('exact city beats name and prefix matches', () async {
      // "dubai": city exact for DXB and DWC (tie broken by rank).
      expect(await codes('dubai'), ['DXB', 'DWC']);
    });

    test('city prefix beats a name substring', () async {
      // DEL (city "new delhi" contains) vs IXD (name starts with "delhi").
      expect(await codes('delhi'), ['IXD', 'DEL']);
      expect(await codes('new d'), ['DEL']);
    });

    test('code prefix beats city prefix', () async {
      // "mu": MUN code prefix (80) beats Mumbai city prefix (75).
      expect(await codes('mu'), ['MUN', 'BOM']);
    });

    test('former names match a tier below current ones', () async {
      expect(await codes('bombay'), ['BOM']);
      expect(await codes('world'), ['DWC']);
    });

    test('maps rows to places', () async {
      final [place] = await source.search(TripType.flight, 'bom');
      expect(
        place,
        const Place(
          name: 'Chhatrapati Shivaji Maharaj International Airport',
          code: 'BOM',
          city: 'Mumbai',
          country: 'IN',
        ),
      );
    });

    test('an empty query lists popular Indian airports first', () async {
      final popular = await codes('  ');
      expect(popular.take(2), ['DEL', 'BOM']);
      expect(popular.length, airports.length);
      // Indian airports before the rest.
      expect(popular.indexOf('IXD'), lessThan(popular.indexOf('DXB')));
    });

    test('returns at most 50 results', () {
      final many = [
        for (var i = 0; i < 80; i++)
          PlaceRecord(
            place: Place(name: 'Airport $i', code: 'A$i'),
            code: 'a$i',
            name: 'airport $i',
            rank: 0,
          ),
      ];
      expect(PlaceRanking.rank(many, 'airport'), hasLength(50));
    });
  });

  group('stations', () {
    test('title-cases names and keeps traffic order on ties', () async {
      final results = await source.search(TripType.train, 'delhi');
      expect([for (final p in results) p.code], ['DLI', 'NDLS']);
      expect(results.last.name, 'New Delhi');
    });

    test('an empty query lists the busiest stations', () async {
      final results = await source.search(TripType.train, '');
      expect(
        results.first,
        const Place(name: 'New Delhi', code: 'NDLS', country: 'IN'),
      );
    });
  });

  group('cities', () {
    test('become places named after the city with its country', () async {
      final results = await source.search(TripType.hotel, 'bombay');
      expect(results, [
        const Place(name: 'Mumbai', city: 'Mumbai', country: 'IN'),
      ]);
    });

    test('rank prefix matches before substrings', () async {
      final results = await source.search(TripType.hotel, 'goa');
      expect(results.single.name, 'Goa Velha');
    });
  });

  test('titleCase', () {
    expect(titleCase('NEW DELHI'), 'New Delhi');
    expect(titleCase('H  NIZAMUDDIN'), 'H Nizamuddin');
  });

  group('bundled assets', () {
    final fromDisk = PlacesLocalDataSourceImpl(
      loadAsset: (key) => File(key).readAsString(),
    );

    test('find the big airports and stations', () async {
      final del = await fromDisk.search(TripType.flight, 'del');
      expect(del.first.code, 'DEL');
      final bombay = await fromDisk.search(TripType.flight, 'bombay');
      expect(bombay.first.code, 'BOM');
      final ndls = await fromDisk.search(TripType.train, 'ndls');
      expect(
        ndls.first,
        const Place(name: 'New Delhi', code: 'NDLS', country: 'IN'),
      );
      final popular = await fromDisk.search(TripType.hotel, '');
      expect(popular, hasLength(8));
      expect(popular.first.name, 'Mumbai');
    });

    test('a missing asset becomes a CacheException, and is retried', () async {
      var calls = 0;
      final broken = PlacesLocalDataSourceImpl(
        loadAsset: (key) async {
          calls++;
          throw Exception('missing');
        },
      );
      await expectLater(
        broken.search(TripType.flight, 'x'),
        throwsA(isA<CacheException>()),
      );
      await expectLater(
        broken.search(TripType.flight, 'x'),
        throwsA(isA<CacheException>()),
      );
      expect(calls, 2);
    });
  });
}
