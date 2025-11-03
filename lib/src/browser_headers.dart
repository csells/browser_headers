import 'dart:math';

import 'package:random_user_agents/random_user_agents.dart';

/// Generates randomized but response-stable "browser-like" headers.
///
/// * Always includes a random, realistic User-Agent
/// * Randomly includes coherent optional header groups (e.g. Sec-Fetch-*
///   together)
/// * Avoids changing response semantics (fixed Accept-Language, safe encodings)
abstract class BrowserHeaders {
  BrowserHeaders._(); // prevents instantiation

  static final _rand = Random.secure();

  /// Generates a map of browser-like headers.
  ///
  /// [baseHeaders] can be used to override the default headers.
  /// [refererQuery] can be used to generate a referrer URL with a query string.
  static Map<String, String> generate({
    Map<String, String>? baseHeaders,
    String? refererQuery,
  }) {
    final ua = RandomUserAgents.random();

    // Always-on core headers
    final headers = <String, String>{
      'User-Agent': ua,
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,'
          'image/webp,image/apng,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
    };

    // Build referrer URLs with optional query string
    final referrers = refererQuery != null && refererQuery.isNotEmpty
        ? _buildReferrersWithQuery(refererQuery)
        : [
            'https://www.google.com/',
            'https://www.bing.com/',
            'https://duckduckgo.com/',
            'https://search.yahoo.com/',
          ];

    // Optional groups that can appear together
    final maybe = <Map<String, String>>[
      // Encodings + connection
      {
        'Accept-Encoding': _pick(['gzip, deflate, br', 'gzip, deflate', 'br']),
        'Connection': _pick(['keep-alive', 'Keep-Alive']),
      },
      // Cache + upgrade + sec-fetch group
      {
        'Cache-Control': 'max-age=0',
        'Upgrade-Insecure-Requests': '1',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Sec-Fetch-User': '?1',
        'Sec-Fetch-Dest': 'document',
      },
      // A referer group
      {'Referer': _pick(referrers)},
    ];

    // Randomly include some of the optional groups
    for (final group in maybe) {
      if (_rand.nextBool()) headers.addAll(group);
    }

    // Caller overrides always win
    if (baseHeaders != null && baseHeaders.isNotEmpty) {
      headers.addAll(baseHeaders);
    }

    return headers;
  }

  static T _pick<T>(List<T> list) => list[_rand.nextInt(list.length)];

  static List<String> _buildReferrersWithQuery(String query) {
    final encoded = Uri.encodeQueryComponent(query);
    return [
      'https://www.google.com/search?q=$encoded',
      'https://www.bing.com/search?q=$encoded',
      'https://duckduckgo.com/?q=$encoded',
      'https://search.yahoo.com/search?p=$encoded',
    ];
  }
}
