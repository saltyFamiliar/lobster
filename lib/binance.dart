import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;

const String api_key =
    '???';
const String api_secret =
    '???';
const String main_endpoint = 'https://api.binance.com';
const String spotEP = main_endpoint + '/api/v3/account';

Future<String> ping() async {
  const String endpoint_suffix = '/api/v3/time';
  final response = await http.get(main_endpoint + endpoint_suffix);
  return response.body;
}



Future<dynamic> fetchData(ep, qs) async {
  var sig = signData(qs);
  var request = ep + '?' + qs + '&signature=$sig';
  final response = await http.get(request, headers: {'X-MBX-APIKEY': api_key});
  return jsonDecode(response.body);
}

Future<dynamic> fetchPrices() async {
  var response = await http.get('https://api.binance.com/api/v3/ticker/price');
  var json = jsonDecode(response.body);
  return json;
}

String signData(String qs) {
  var hmacSha256 = crypto.Hmac(crypto.sha256, utf8.encode(api_secret));
  var digest = hmacSha256.convert(utf8.encode(qs));
  return digest.toString();
}

String timeStampQ() {
  return 'recvWindow=50000&timestamp=${DateTime.now().millisecondsSinceEpoch}';
}
