import 'package:browser_headers/browser_headers.dart';
import 'package:http/http.dart' as http;

void main() async {
  final headers = BrowserHeaders.generate(
    baseHeaders: {'Referer': 'https://www.google.com/search?q=zillow'},
  );

  final res = await http.get(
    Uri.parse('https://www.zillow.com/'),
    headers: headers,
  );

  print(headers);
  print('Status: ${res.statusCode}');
}
