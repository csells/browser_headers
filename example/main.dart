// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:browser_headers/browser_headers.dart';
import 'package:http/http.dart' as http;

void main() async {
  // get some realistic headers for an HTTP GET from a browser
  final headers = BrowserHeaders.generate(
    refererQuery: 'zillow 11222 Dilling Street, Studio City, CA',
  );

  // make the HTTP GET request
  const url =
      'https://www.zillow.com/homedetails/11222-Dilling-St-North-Hollywood-CA-91602/20025974_zpid/';
  final res = await http.get(Uri.parse(url), headers: headers);

  // bundle and pretty print the request details
  print(
    const JsonEncoder.withIndent(
      '  ',
    ).convert({'url': url, 'headers': headers, 'statusCode': res.statusCode}),
  );
}
