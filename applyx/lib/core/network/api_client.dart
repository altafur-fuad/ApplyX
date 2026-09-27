import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  final http.Client _httpClient;
  final Future<String?> Function() _getToken;
  final String _baseUrl;

  ApiClient({
    http.Client? httpClient,
    Future<String?> Function()? getToken,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _getToken = getToken ?? (() async => Supabase.instance.client.auth.currentSession?.accessToken),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await _getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<dynamic> get(String path) async {
    return _request(() async {
      final headers = await _getHeaders();
      return _httpClient.get(Uri.parse('$_baseUrl$path'), headers: headers);
    });
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    return _request(() async {
      final headers = await _getHeaders();
      return _httpClient.post(
        Uri.parse('$_baseUrl$path'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    return _request(() async {
      final headers = await _getHeaders();
      return _httpClient.put(
        Uri.parse('$_baseUrl$path'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    return _request(() async {
      final headers = await _getHeaders();
      return _httpClient.patch(
        Uri.parse('$_baseUrl$path'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  Future<dynamic> delete(String path) async {
    return _request(() async {
      final headers = await _getHeaders();
      return _httpClient.delete(Uri.parse('$_baseUrl$path'), headers: headers);
    });
  }

  Future<dynamic> _request(Future<http.Response> Function() requestFunc) async {
    try {
      final response = await requestFunc().timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        code: 'TIMEOUT',
        message: 'The request timed out.',
      );
    } on SocketException {
      throw ApiException(
        statusCode: 503,
        code: 'NETWORK_UNAVAILABLE',
        message: 'Network is unreachable.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 500,
        code: 'INTERNAL_ERROR',
        message: e.toString(),
      );
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body; 
      }
    } else {
      Map<String, dynamic> errorJson = {};
      try {
        errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw ApiException(
          statusCode: response.statusCode,
          code: 'HTTP_ERROR',
          message: 'An HTTP error occurred: ${response.statusCode} ${response.reasonPhrase}',
        );
      }
      throw ApiException.fromJson(response.statusCode, errorJson);
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
