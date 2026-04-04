import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:frontend/core/network/api_client.dart';

class ApiCallResult<T> {
  const ApiCallResult({required this.success, this.data, this.error});

  final bool success;
  final T? data;
  final String? error;
}

Future<ApiCallResult<List<Map<String, dynamic>>>> fetchSubscriptionTiersResult(
  ApiClient client,
) async {
  final http.Response res = await client.get(
    '/subscriptions/tiers',
    bearer: true,
  );
  return _parseListResult(res);
}

Future<List<Map<String, dynamic>>> fetchSubscriptionTiers(
  ApiClient client,
) async {
  final ApiCallResult<List<Map<String, dynamic>>> result =
      await fetchSubscriptionTiersResult(client);
  return result.data ?? const <Map<String, dynamic>>[];
}

Future<ApiCallResult<Map<String, dynamic>?>> fetchActiveSubscriptionResult(
  ApiClient client,
) async {
  final http.Response res = await client.get('/subscriptions/me', bearer: true);
  return _parseMapResult(res, acceptNullData: true);
}

Future<Map<String, dynamic>?> fetchActiveSubscription(ApiClient client) async {
  final ApiCallResult<Map<String, dynamic>?> result =
      await fetchActiveSubscriptionResult(client);
  return result.success ? result.data : null;
}

Future<ApiCallResult<List<Map<String, dynamic>>>>
fetchSubscriptionHistoryResult(ApiClient client) async {
  final http.Response res = await client.get(
    '/subscriptions/history',
    bearer: true,
  );
  return _parseListResult(res);
}

Future<List<Map<String, dynamic>>> fetchSubscriptionHistory(
  ApiClient client,
) async {
  final ApiCallResult<List<Map<String, dynamic>>> result =
      await fetchSubscriptionHistoryResult(client);
  return result.data ?? const <Map<String, dynamic>>[];
}

Future<ApiCallResult<Map<String, dynamic>?>> fetchWalletBalanceResult(
  ApiClient client,
) async {
  final http.Response res = await client.get('/wallet/balance', bearer: true);
  return _parseMapResult(res, acceptNullData: true, treat404AsEmpty: true);
}

Future<ApiCallResult<Map<String, dynamic>?>> fetchMandateStatusResult(
  ApiClient client,
) async {
  final http.Response res = await client.get(
    '/payments/mandate/status',
    bearer: true,
  );
  return _parseMapResult(res, acceptNullData: true, treat404AsEmpty: true);
}

Future<ApiCallResult<Map<String, dynamic>>> createMandateResult(
  ApiClient client,
) async {
  final http.Response res = await client.postJson(
    '/payments/mandate/create',
    const <String, dynamic>{},
    bearer: true,
  );
  return _requireMapData(
    _parseMapResult(res),
    fallbackError: 'Unable to create mandate right now.',
  );
}

Future<ApiCallResult<Map<String, dynamic>>> subscribeTierResult(
  ApiClient client, {
  required String tier,
}) async {
  final http.Response res = await client.postJson(
    '/subscriptions/subscribe',
    <String, dynamic>{'tier': tier},
    bearer: true,
  );
  return _requireMapData(_parseMapResult(res));
}

Future<Map<String, dynamic>?> subscribeTier(
  ApiClient client, {
  required String tier,
}) async {
  final ApiCallResult<Map<String, dynamic>> result = await subscribeTierResult(
    client,
    tier: tier,
  );
  return result.success ? result.data : null;
}

Future<ApiCallResult<Map<String, dynamic>>> upgradeTierResult(
  ApiClient client, {
  required String tier,
}) async {
  final http.Response res = await client.putJson(
    '/subscriptions/upgrade',
    <String, dynamic>{'tier': tier},
    bearer: true,
  );
  return _requireMapData(_parseMapResult(res));
}

Future<Map<String, dynamic>?> upgradeTier(
  ApiClient client, {
  required String tier,
}) async {
  final ApiCallResult<Map<String, dynamic>> result = await upgradeTierResult(
    client,
    tier: tier,
  );
  return result.success ? result.data : null;
}

Future<ApiCallResult<Map<String, dynamic>>> cancelTierResult(
  ApiClient client, {
  required String reason,
}) async {
  final http.Response res = await client.deleteJson(
    '/subscriptions/cancel',
    <String, dynamic>{'reason': reason},
    bearer: true,
  );
  return _requireMapData(_parseMapResult(res));
}

Future<Map<String, dynamic>?> cancelTier(
  ApiClient client, {
  required String reason,
}) async {
  final ApiCallResult<Map<String, dynamic>> result = await cancelTierResult(
    client,
    reason: reason,
  );
  return result.success ? result.data : null;
}

ApiCallResult<List<Map<String, dynamic>>> _parseListResult(http.Response res) {
  try {
    final Object? decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      return ApiCallResult<List<Map<String, dynamic>>>(
        success: false,
        error: 'Invalid response from server.',
      );
    }
    final bool success = decoded['success'] as bool? ?? false;
    if (!success) {
      return ApiCallResult<List<Map<String, dynamic>>>(
        success: false,
        error: _extractEnvelopeError(decoded) ?? 'Request failed.',
      );
    }
    final Object? data = decoded['data'];
    if (data is! List<dynamic>) {
      return const ApiCallResult<List<Map<String, dynamic>>>(
        success: true,
        data: <Map<String, dynamic>>[],
      );
    }
    return ApiCallResult<List<Map<String, dynamic>>>(
      success: true,
      data: data
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
    );
  } catch (_) {
    return ApiCallResult<List<Map<String, dynamic>>>(
      success: false,
      error: _httpErrorFromResponse(res),
    );
  }
}

ApiCallResult<Map<String, dynamic>?> _parseMapResult(
  http.Response res, {
  bool acceptNullData = false,
  bool treat404AsEmpty = false,
}) {
  if (treat404AsEmpty && res.statusCode == 404) {
    return const ApiCallResult<Map<String, dynamic>?>(
      success: true,
      data: null,
    );
  }
  try {
    final Object? decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      return ApiCallResult<Map<String, dynamic>?>(
        success: false,
        error: _httpErrorFromResponse(res),
      );
    }

    final String? detail = decoded['detail'] as String?;
    if (detail != null && detail.trim().isNotEmpty) {
      return ApiCallResult<Map<String, dynamic>?>(
        success: false,
        error: detail,
      );
    }

    final bool success = decoded['success'] as bool? ?? false;
    if (!success) {
      return ApiCallResult<Map<String, dynamic>?>(
        success: false,
        error: _extractEnvelopeError(decoded) ?? _httpErrorFromResponse(res),
      );
    }

    final Object? data = decoded['data'];
    if (acceptNullData && data == null) {
      return const ApiCallResult<Map<String, dynamic>?>(
        success: true,
        data: null,
      );
    }

    if (data is! Map<String, dynamic>) {
      return ApiCallResult<Map<String, dynamic>?>(
        success: false,
        error: 'Invalid response payload.',
      );
    }
    return ApiCallResult<Map<String, dynamic>?>(success: true, data: data);
  } catch (_) {
    return ApiCallResult<Map<String, dynamic>?>(
      success: false,
      error: _httpErrorFromResponse(res),
    );
  }
}

String? _extractEnvelopeError(Map<String, dynamic> decoded) {
  final String? error = decoded['error'] as String?;
  if (error != null && error.trim().isNotEmpty) {
    return error;
  }
  return null;
}

String _httpErrorFromResponse(http.Response res) {
  try {
    final Object? decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      final String? detail = decoded['detail'] as String?;
      if (detail != null && detail.trim().isNotEmpty) {
        return detail;
      }
      final String? err = _extractEnvelopeError(decoded);
      if (err != null) {
        return err;
      }
    }
  } catch (_) {
    // Fall through to generic error text.
  }
  if (res.reasonPhrase != null && res.reasonPhrase!.trim().isNotEmpty) {
    return res.reasonPhrase!;
  }
  return 'Request failed (${res.statusCode}).';
}

ApiCallResult<Map<String, dynamic>> _requireMapData(
  ApiCallResult<Map<String, dynamic>?> result, {
  String fallbackError = 'Invalid response payload.',
}) {
  if (!result.success) {
    return ApiCallResult<Map<String, dynamic>>(
      success: false,
      error: result.error ?? fallbackError,
    );
  }
  final Map<String, dynamic>? data = result.data;
  if (data == null) {
    return ApiCallResult<Map<String, dynamic>>(
      success: false,
      error: fallbackError,
    );
  }
  return ApiCallResult<Map<String, dynamic>>(success: true, data: data);
}
