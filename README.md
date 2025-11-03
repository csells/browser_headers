# browser_headers

Generates randomized but response-stable "browser-like" HTTP headers for Dart
applications. Perfect for extracting data from the web.

## Features

- **Always includes a random, realistic User-Agent** - Uses realistic browser
  user agents
- **Randomly includes coherent optional header groups** - Groups like
  `Sec-Fetch-*` appear together naturally
- **Avoids changing response semantics** - Fixed `Accept-Language`, safe
  encodings
- **Supports search referrers** - Generate search engine referrer URLs with
  properly encoded queries
- **Allows caller overrides** - Override any generated header via `baseHeaders`

## Usage

### Basic usage

```dart
import 'package:browser_headers/browser_headers.dart';
import 'package:http/http.dart' as http;

void main() async {
  // Generate browser-like headers
  final headers = BrowserHeaders.generate();

  final response = await http.get(
    Uri.parse('https://example.com'),
    headers: headers,
  );

  print('Status: ${response.statusCode}');
}
```

### With search referrer

Generate headers with a referrer that looks like it came from a search engine:

```dart
final headers = BrowserHeaders.generate(
  refererQuery: 'zillow 11222 Dilling Street',
);

// The Referer header will be one of:
// - https://www.google.com/search?q=zillow%2011222%20Dilling%20Street
// - https://www.bing.com/search?q=zillow%2011222%20Dilling%20Street
// - https://duckduckgo.com/?q=zillow%2011222%20Dilling%20Street
// - https://search.yahoo.com/search?p=zillow%2011222%20Dilling%20Street
```

The query string is properly URL encoded and uses the correct query parameter
for each search engine (`q` for most, `p` for Yahoo).

### With custom overrides

Override any generated header:

```dart
final headers = BrowserHeaders.generate(
  refererQuery: 'my search',
  baseHeaders: {
    'User-Agent': 'MyCustomUA/1.0',
    'Accept-Language': 'en-GB,en;q=0.9',
  },
);
```

## How it works

The package generates headers in coherent groups:

**Core headers (always included):**
- `User-Agent` - Random realistic browser UA
- `Accept` - Standard browser accept string
- `Accept-Language` - Fixed to `en-US,en;q=0.9`

**Optional groups (randomly included together):**
- Encoding group: `Accept-Encoding`, `Connection`
- Security group: `Cache-Control`, `Upgrade-Insecure-Requests`,
  `Sec-Fetch-Mode`, `Sec-Fetch-Site`, `Sec-Fetch-User`, `Sec-Fetch-Dest`
- Referrer: Either a search engine homepage or search URL (if `refererQuery`
  provided)

This ensures headers appear natural and coherent, like they came from a real
browser.
