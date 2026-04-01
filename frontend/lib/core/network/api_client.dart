import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/network/api_response.dart';

typedef TokenGetter = String? Function();
typedef UnauthorizedCallback = void Function();

/// HTTP client for KavachNidhi API with optional bearer auth.
class ApiClient {
  ApiClient({
    String? baseUrl,
    this.tokenGetter,
    this.onUnauthorized,
  }) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;
  TokenGetter? tokenGetter;
  UnauthorizedCallback? onUnauthorized;

  Uri _uri(String path) {
    final String p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$p');
  }

  Map<String, String> _headers({bool withBearer = false}) {
    final Map<String, String> h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withBearer) {
      final String? t = tokenGetter?.call();
      if (t != null && t.isNotEmpty) {
        h['Authorization'] = 'Bearer $t';
      }
    }
    return h;
  }

  void _maybeHandleUnauthorized(int statusCode, bool auth) {
    if (auth && statusCode == 401) {
      onUnauthorized?.call();
    }
  }

  Future<http.Response> postJson(
    String path,
    Map<String, dynamic> body, {
    bool bearer = false,
  }) async {
    final http.Response res = await http.post(
      _uri(path),
      headers: _headers(withBearer: bearer),
      body: jsonEncode(body),
    );
    _maybeHandleUnauthorized(res.statusCode, bearer);
    return res;
  }

  Future<http.Response> get(
    String path, {
    bool bearer = false,
  }) async {
    final http.Response res = await http.get(
      _uri(path),
      headers: _headers(withBearer: bearer),
    );
    _maybeHandleUnauthorized(res.statusCode, bearer);
    return res;
  }

  /// Parses `{ success, data, error }` from a JSON response body.
  static ApiEnvelope<Map<String, dynamic>> parseEnvelope(http.Response res) {
    try {
      return ApiEnvelope.fromJsonMap(res.body);
    } catch (_) {
      return ApiEnvelope<Map<String, dynamic>>(
        success: false,
        error: res.reasonPhrase ?? 'Request failed',
      );
    }
  }
}
