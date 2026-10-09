import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Enforces the dependency rules in CLAUDE.md by reading every import in lib/.
void main() {
  final libDir = Directory('lib');
  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => p.posix.joinAll(p.split(p.relative(f.path))))
      .toList();

  final importPattern = RegExp(
    r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );

  /// Imports of [file], with relative ones resolved to `lib/...` paths.
  List<String> importsOf(String file) => importPattern
      .allMatches(File(file).readAsStringSync())
      .map((m) => m.group(1)!)
      .map((uri) {
        if (uri.startsWith('package:tripbybid/')) {
          return 'lib/${uri.substring('package:tripbybid/'.length)}';
        }
        if (uri.contains(':')) return uri;
        return p.posix.normalize(p.posix.join(p.posix.dirname(file), uri));
      })
      .toList();

  String? featureOf(String path) =>
      RegExp(r'^lib/features/([^/]+)/').firstMatch(path)?.group(1);

  String? layerOf(String path) => RegExp(
    r'^lib/features/[^/]+/(domain|data|presentation)/',
  ).firstMatch(path)?.group(1);

  const pureCore = ['lib/core/error/', 'lib/core/usecase/', 'lib/core/utils/'];
  bool isPure(String path) =>
      layerOf(path) == 'domain' || pureCore.any(path.startsWith);

  test(
    'domain layer (and pure core) imports only dart: and other pure files',
    () {
      final violations = [
        for (final file in files.where(isPure))
          for (final import in importsOf(file))
            if (!import.startsWith('dart:') && !isPure(import))
              '$file → $import',
      ];
      expect(violations, isEmpty, reason: 'Domain must be pure Dart.');
    },
  );

  test('presentation never imports data, data never imports presentation', () {
    final violations = [
      for (final file in files)
        for (final import in importsOf(file))
          if ((layerOf(file) == 'presentation' && layerOf(import) == 'data') ||
              (layerOf(file) == 'data' && layerOf(import) == 'presentation'))
            '$file → $import',
    ];
    expect(violations, isEmpty);
  });

  test("features import only other features' domain layer", () {
    final violations = [
      for (final file in files)
        for (final import in importsOf(file))
          if (featureOf(file) case final from?)
            if (featureOf(import) case final to? when to != from)
              if (layerOf(import) != 'domain') '$file → $import',
    ];
    expect(violations, isEmpty);
  });
}
