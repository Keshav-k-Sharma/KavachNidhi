import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/api_response.dart';
import 'package:frontend/features/subscriptions/data/subscriptions_api.dart'
    as subscriptions_api;

/// GET `/wallet/balance` — requires registered driver.
Future<Map<String, dynamic>?> fetchWalletBalance(ApiClient client) async {
  final http.Response res = await client.get('/wallet/balance', bearer: true);
  if (res.statusCode == 404 || res.statusCode == 401) {
    return null;
  }
  final ApiEnvelope<Map<String, dynamic>> env = ApiClient.parseEnvelope(res);
  if (!env.success || env.data == null) {
    return null;
  }
  return env.data;
}

/// GET `/drivers/risk-score` — uses current user (driver id = user id).
Future<Map<String, dynamic>?> fetchRiskScore(ApiClient client) async {
  final http.Response res = await client.get(
    '/drivers/risk-score',
    bearer: true,
  );
  if (res.statusCode == 404 || res.statusCode == 401) {
    return null;
  }
  final ApiEnvelope<Map<String, dynamic>> env = ApiClient.parseEnvelope(res);
  if (!env.success || env.data == null) {
    return null;
  }
  return env.data;
}

/// GET `/subscriptions/me` — active subscription or null data.
Future<Map<String, dynamic>?> fetchActiveSubscription(ApiClient client) async {
  return subscriptions_api.fetchActiveSubscription(client);
}

/// GET `/settlements/next` — requires registered driver.
Future<Map<String, dynamic>?> fetchNextSettlement(ApiClient client) async {
  final http.Response res = await client.get('/settlements/next', bearer: true);
  if (res.statusCode == 404 || res.statusCode == 401) {
    return null;
  }
  final ApiEnvelope<Map<String, dynamic>> env = ApiClient.parseEnvelope(res);
  if (!env.success || env.data == null) {
    return null;
  }
  return env.data;
}

/// GET `/wallet/transactions` — paginated list in `data`.
Future<List<dynamic>?> fetchWalletTransactions(
  ApiClient client, {
  int page = 1,
  int limit = 15,
}) async {
  final http.Response res = await client.get(
    '/wallet/transactions?page=$page&limit=$limit',
    bearer: true,
  );
  if (res.statusCode == 404 || res.statusCode == 401) {
    return null;
  }
  try {
    final Object? decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final bool success = decoded['success'] as bool? ?? false;
    if (!success) {
      return null;
    }
    final Object? raw = decoded['data'];
    if (raw is List<dynamic>) {
      return raw;
    }
    return null;
  } catch (_) {
    return null;
  }
}
