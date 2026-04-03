import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:frontend/core/network/api_client.dart';

/// Returns list of tier maps: { tier, base_rate, cap_amount }
Future<List<Map<String, dynamic>>> fetchTiers(ApiClient client) async {
  final http.Response res =
      await client.get('/subscriptions/tiers', bearer: true);
  final Map<String, dynamic> decoded =
      jsonDecode(res.body) as Map<String, dynamic>;
  if (decoded['success'] != true) return <Map<String, dynamic>>[];
  final Object? data = decoded['data'];
  if (data is List) {
    return data.whereType<Map<String, dynamic>>().toList();
  }
  return <Map<String, dynamic>>[];
}

/// Returns active subscription map or null if none exists.
Future<Map<String, dynamic>?> fetchMySubscription(ApiClient client) async {
  final http.Response res =
      await client.get('/subscriptions/me', bearer: true);
  if (res.statusCode == 404) return null;
  final Map<String, dynamic> decoded =
      jsonDecode(res.body) as Map<String, dynamic>;
  if (decoded['success'] != true) return null;
  final Object? data = decoded['data'];
  return data is Map<String, dynamic> ? data : null;
}

/// Subscribe to a tier. Throws on failure.
Future<Map<String, dynamic>> subscribeToTier(
  ApiClient client,
  String tier,
) async {
  final http.Response res = await client.postJson(
    '/subscriptions/subscribe',
    <String, dynamic>{'tier': tier},
    bearer: true,
  );
  final Map<String, dynamic> decoded =
      jsonDecode(res.body) as Map<String, dynamic>;
  if (decoded['success'] != true) {
    throw Exception(decoded['error'] ?? 'Subscribe failed');
  }
  return decoded['data'] as Map<String, dynamic>;
}
