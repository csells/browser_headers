import 'package:browser_headers/browser_headers.dart';
import 'package:test/test.dart';

void main() {
  const coreKeys = {'User-Agent', 'Accept', 'Accept-Language'};
  const encodingGroup = {'Accept-Encoding', 'Connection'};
  const fetchGroup = {
    'Cache-Control',
    'Upgrade-Insecure-Requests',
    'Sec-Fetch-Mode',
    'Sec-Fetch-Site',
    'Sec-Fetch-User',
    'Sec-Fetch-Dest',
  };
  const refererKey = 'Referer';

  const plausibleReferers = {
    'https://www.google.com/',
    'https://www.bing.com/',
    'https://duckduckgo.com/',
    'https://search.yahoo.com/',
  };

  const plausibleSearchEngineHosts = {
    'www.google.com',
    'www.bing.com',
    'duckduckgo.com',
    'search.yahoo.com',
  };

  final allowedKeys = <String>{
    ...coreKeys,
    ...encodingGroup,
    ...fetchGroup,
    refererKey,
  };

  group('BrowserHeaders.generate()', () {
    test('always includes core headers with sensible values', () {
      for (var i = 0; i < 100; i++) {
        final h = BrowserHeaders.generate();

        // Core keys present
        expect(h.keys, containsAll(coreKeys));

        // User-Agent should be a non-empty, browser-like UA
        expect(h['User-Agent'], isNotNull);
        expect(h['User-Agent']!.trim(), isNotEmpty);
        // A light sanity check (not too strict)
        expect(h['User-Agent']!.contains('Mozilla/5.0'), isTrue);

        // Accept / Accept-Language fixed values (content-stable)
        expect(h['Accept'], isNotNull);
        expect(h['Accept']!.trim(), isNotEmpty);
        expect(h['Accept-Language'], 'en-US,en;q=0.9');
      }
    });

    test('returns only allowed headers', () {
      for (var i = 0; i < 100; i++) {
        final h = BrowserHeaders.generate();
        for (final k in h.keys) {
          expect(
            allowedKeys.contains(k),
            isTrue,
            reason: 'Unexpected header key: $k',
          );
        }
      }
    });

    test(
      'encoding group is coherent: if Accept-Encoding -> Connection present',
      () {
        for (var i = 0; i < 100; i++) {
          final h = BrowserHeaders.generate();
          final hasEnc = h.containsKey('Accept-Encoding');
          final hasConn = h.containsKey('Connection');
          expect(
            hasEnc == hasConn,
            isTrue,
            reason:
                'Accept-Encoding and Connection should be included/excluded together',
          );
        }
      },
    );

    test('sec-fetch group is coherent: all-or-none', () {
      for (var i = 0; i < 100; i++) {
        final h = BrowserHeaders.generate();
        final present = fetchGroup.where(h.containsKey).toSet();
        expect(
          present.isEmpty || present.length == fetchGroup.length,
          isTrue,
          reason:
              'Sec-Fetch* + (Cache-Control, Upgrade-Insecure-Requests) '
              'must appear together or not at all',
        );
      }
    });

    test('referer, if present, is plausible', () {
      for (var i = 0; i < 100; i++) {
        final h = BrowserHeaders.generate();
        if (h.containsKey(refererKey)) {
          final r = h[refererKey]!;
          expect(r.trim(), isNotEmpty);
          expect(
            plausibleReferers.contains(r),
            isTrue,
            reason: 'Referer not in expected set: $r',
          );
        }
      }
    });

    test('baseHeaders override wins for any key (including User-Agent)', () {
      final base = {
        'User-Agent': 'MyCustomUA/1.0',
        'Accept-Language': 'en-GB,en;q=0.9',
        'Referer': 'https://www.google.com/', // force a known value
      };

      final h = BrowserHeaders.generate(baseHeaders: base);

      // Overrides respected
      expect(h['User-Agent'], equals('MyCustomUA/1.0'));
      expect(h['Accept-Language'], equals('en-GB,en;q=0.9'));
      expect(h['Referer'], equals('https://www.google.com/'));

      // Still must include the other core keys at minimum
      expect(h['Accept'], isNotNull);
      expect(h['Accept']!.trim(), isNotEmpty);
    });

    test('baseHeaders can reduce output to only the needed keys '
        'while keeping core invariants', () {
      // Provide only UA; generator still supplies Accept + Accept-Language.
      final base = {'User-Agent': 'MinimalUA/2.0'};
      final h = BrowserHeaders.generate(baseHeaders: base);

      expect(h['User-Agent'], equals('MinimalUA/2.0'));
      expect(h.keys, containsAll(coreKeys));
      // Ensure no unexpected keys are introduced beyond allowed keys.
      for (final k in h.keys) {
        expect(allowedKeys.contains(k), isTrue);
      }
    });

    test('multiple runs produce variation but remain valid', () {
      final sample = <Map<String, String>>[];
      for (var i = 0; i < 50; i++) {
        sample.add(BrowserHeaders.generate());
      }

      // Expect at least some diversity in outputs
      final uniqueMaps = sample.map((m) => m.toString()).toSet();
      expect(uniqueMaps.length, greaterThan(1));

      // All samples should satisfy invariants
      for (final h in sample) {
        // Core keys present
        expect(h.keys, containsAll(coreKeys));
        // Allowed keys only
        for (final k in h.keys) {
          expect(allowedKeys.contains(k), isTrue);
        }
        // Coherent groups
        final hasEnc = h.containsKey('Accept-Encoding');
        final hasConn = h.containsKey('Connection');
        expect(hasEnc == hasConn, isTrue);

        final present = fetchGroup.where(h.containsKey).toSet();
        expect(present.isEmpty || present.length == fetchGroup.length, isTrue);
      }
    });

    test('refererQuery generates search URLs with encoded query', () {
      for (var i = 0; i < 100; i++) {
        final h = BrowserHeaders.generate(refererQuery: 'test query');
        if (h.containsKey(refererKey)) {
          final referer = h[refererKey]!;
          final uri = Uri.parse(referer);

          // Should be one of the known search engines
          expect(
            plausibleSearchEngineHosts.contains(uri.host),
            isTrue,
            reason: 'Unknown host in referer: ${uri.host}',
          );

          // Should have a query parameter with the search term
          expect(uri.hasQuery, isTrue);

          // Check for appropriate query parameter based on host
          if (uri.host == 'search.yahoo.com') {
            expect(uri.queryParameters.containsKey('p'), isTrue);
            expect(uri.queryParameters['p'], 'test query');
          } else {
            expect(uri.queryParameters.containsKey('q'), isTrue);
            expect(uri.queryParameters['q'], 'test query');
          }
        }
      }
    });

    test('refererQuery properly URL encodes special characters', () {
      const specialQuery = 'zillow 11222 Dilling St, Studio City & more!';
      for (var i = 0; i < 100; i++) {
        final h = BrowserHeaders.generate(refererQuery: specialQuery);
        if (h.containsKey(refererKey)) {
          final referer = h[refererKey]!;
          final uri = Uri.parse(referer);

          // Should parse without errors
          expect(uri.scheme, 'https');

          // Query should be properly decoded back to original
          final queryParam =
              uri.queryParameters['q'] ?? uri.queryParameters['p'];
          expect(queryParam, specialQuery);

          // Raw query should contain URL encoding (spaces as %20 or +)
          expect(
            uri.query.contains('%') || uri.query.contains('+'),
            isTrue,
            reason: 'Query should be URL encoded',
          );
        }
      }
    });

    test('refererQuery null or empty uses default referrers', () {
      // Test with null
      for (var i = 0; i < 50; i++) {
        final h = BrowserHeaders.generate(refererQuery: null);
        if (h.containsKey(refererKey)) {
          final referer = h[refererKey]!;
          expect(
            plausibleReferers.contains(referer),
            isTrue,
            reason: 'Should use default referrers when query is null',
          );
        }
      }

      // Test with empty string
      for (var i = 0; i < 50; i++) {
        final h = BrowserHeaders.generate(refererQuery: '');
        if (h.containsKey(refererKey)) {
          final referer = h[refererKey]!;
          expect(
            plausibleReferers.contains(referer),
            isTrue,
            reason: 'Should use default referrers when query is empty',
          );
        }
      }
    });

    test('refererQuery generates different search engine URLs', () {
      final referers = <String>{};
      for (var i = 0; i < 200; i++) {
        final h = BrowserHeaders.generate(refererQuery: 'test');
        if (h.containsKey(refererKey)) {
          referers.add(h[refererKey]!);
        }
      }

      // Should have generated URLs from multiple search engines
      expect(
        referers.length,
        greaterThan(1),
        reason: 'Should generate URLs from different search engines',
      );
    });

    test('refererQuery with baseHeaders override', () {
      const customReferer = 'https://example.com/custom';
      final h = BrowserHeaders.generate(
        refererQuery: 'test query',
        baseHeaders: {'Referer': customReferer},
      );

      // baseHeaders should override the generated referer
      expect(h['Referer'], customReferer);
    });
  });
}
