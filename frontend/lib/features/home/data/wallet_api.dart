import 'package:http/http.dart' as http;

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/api_response.dart';

/// Fetches wallet row from `GET /wallet/balance` (requires driver registration).
Future<Map<String, dynamic>?> fetchWalletBalance(ApiClient client) async {
  final http.Response res = await client.get('/wallet/balance', bearer: true);
  if (res.statusCode == 404) {
    return null;
  }
  final ApiEnvelope<Map<String, dynamic>> env = ApiClient.parseEnvelope(res);
  if (!env.success || env.data == null) {
    return null;
  }
  return env.data;
}
