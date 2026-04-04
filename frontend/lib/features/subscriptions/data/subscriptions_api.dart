import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/api_response.dart';

Future<List<Map<String, dynamic>>> fetchSubscriptionTiers(ApiClient client) async {
  final http.Response res = await client.get('/subscriptions/tiers', bearer: true);
  return _parseListEnvelope(res.body);
}

Future<Map<String, dynamic>?> fetchActiveSubscription(ApiClient client) async {
  final http.Response res = await client.get('/subscriptions/me', bearer: true);
  if (res.statusCode == 404 || res.statusCode == 401) {
    return null;
  }
  final ApiEnvelope<Map<String, dynamic>> env = ApiClient.parseEnvelope(res);
  if (!env.success) {
    return null;
  }
  return env.data;
}

Future<List<Map<String, dynamic>>> fetchSubscriptionHistory(ApiClient client) async {
  final http.Response res = await client.get('/subscriptions/history', bearer: true);
  return _parseListEnvelope(res.body);
}

Future<Map<String, dynamic>?> subscribeTier(
  ApiClient client, {
  required String tier,
}) async {
  final http.Response res = await client.postJson(
    '/subscriptions/subscribe',
    <String, dynamic>{'tier': tier},
    bearer: true,
  );
  return _parseMutationEnvelope(res.body);
}

Future<Map<String, dynamic>?> upgradeTier(
  ApiClient client, {
  required String tier,
}) async {
  final http.Response res = await client.putJson(
    '/subscriptions/upgrade',
    <String, dynamic>{'tier': tier},
    bearer: true,
  );
  return _parseMutationEnvelope(res.body);
}

Future<Map<String, dynamic>?> cancelTier(
  ApiClient client, {
  required String reason,
}) async {
  final http.Response res = await client.deleteJson(
    '/subscriptions/cancel',
    <String, dynamic>{'reason': reason},
    bearer: true,
  );
  return _parseMutationEnvelope(res.body);
}

List<Map<String, dynamic>> _parseListEnvelope(String body) {
  try {
    final Object? decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return const <Map<String, dynamic>>[];
    }
    final bool success = decoded['success'] as bool? ?? false;
    if (!success) {
      return const <Map<String, dynamic>>[];
    }
    final Object? data = decoded['data'];
    if (data is! List<dynamic>) {
      return const <Map<String, dynamic>>[];
    }
    return data
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  } catch (_) {
    return const <Map<String, dynamic>>[];
  }
}

Map<String, dynamic>? _parseMutationEnvelope(String body) {
  try {
    final Object? decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final bool success = decoded['success'] as bool? ?? false;
    if (!success) {
      return null;
    }
    final Object? data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      return null;
    }
    return data;
  } catch (_) {
    return null;
  }
}
