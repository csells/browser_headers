import 'dart:math';

import 'package:random_user_agents/random_user_agents.dart';

/// Generates randomized but response-stable "browser-like" headers.
///
/// * Always includes a random, realistic User-Agent
/// * Randomly includes coherent optional header groups (e.g. Sec-Fetch-*
///   together)
/// * Avoids changing response semantics (fixed Accept-Language, safe encodings)
/// * Allows caller overrides via [overrides]
abstract class BrowserHeaders {
  BrowserHeaders._(); // prevents instantiation

  static final _rand = Random.secure();

  static Map<String, String> generate({Map<String, String>? baseHeaders}) {
    final ua = RandomUserAgents.random();

    // Always-on core headers
    final headers = <String, String>{
      'User-Agent': ua,
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,'
          'image/webp,image/apng,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
    };

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
      {
        'Referer': _pick([
          'https://www.google.com/',
          'https://www.bing.com/',
          'https://duckduckgo.com/',
          'https://search.yahoo.com/',
        ]),
      },
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
}
