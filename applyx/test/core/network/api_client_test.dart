import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:applyx/core/network/api_client.dart';
import 'package:applyx/core/network/api_exception.dart';

void main() {
  group('ApiClient', () {
    test('uses default base url when not provided', () async {
      final client = ApiClient(
        getToken: () async => null,
        httpClient: MockClient((request) async {
          expect(request.url.toString(), 'http://10.0.2.2:8000/v1/test');
          return http.Response('{}', 200);
        }),
      );
      await client.get('/test');
    });

    test('adds Authorization header when token is present', () async {
      final client = ApiClient(
        baseUrl: 'http://test.com',
        getToken: () async => 'test_token',
        httpClient: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer test_token');
          return http.Response('{"status": "ok"}', 200);
        }),
      );
      final response = await client.get('/path');
      expect(response, {'status': 'ok'});
    });

    test('does not add Authorization header when token is null', () async {
      final client = ApiClient(
        baseUrl: 'http://test.com',
        getToken: () async => null,
        httpClient: MockClient((request) async {
          expect(request.headers.containsKey('Authorization'), false);
          return http.Response('{}', 200);
        }),
      );
      await client.get('/path');
    });

    test('parses successful json response', () async {
      final client = ApiClient(
        baseUrl: 'http://test.com',
        getToken: () async => null,
        httpClient: MockClient((request) async {
          return http.Response('{"data": "value"}', 200);
        }),
      );
      final response = await client.get('/path');
      expect(response, {'data': 'value'});
    });

    test('parses API error envelope successfully', () async {
      final client = ApiClient(
        baseUrl: 'http://test.com',
        getToken: () async => null,
        httpClient: MockClient((request) async {
          final errorBody = jsonEncode({
            "error": {
              "code": "AUTH_REQUIRED",
              "message": "You must be logged in",
              "request_id": "req_123"
            }
          });
          return http.Response(errorBody, 401);
        }),
      );
      
      try {
        await client.get('/path');
        fail('Should have thrown an exception');
      } on ApiException catch (e) {
        expect(e.statusCode, 401);
        expect(e.code, 'AUTH_REQUIRED');
        expect(e.message, 'You must be logged in');
        expect(e.requestId, 'req_123');
      }
    });

    test('handles 500 without json envelope', () async {
      final client = ApiClient(
        baseUrl: 'http://test.com',
        getToken: () async => null,
        httpClient: MockClient((request) async {
          return http.Response('Internal Server Error', 500, reasonPhrase: 'Internal Server Error');
        }),
      );
      
      try {
        await client.get('/path');
        fail('Should have thrown an exception');
      } on ApiException catch (e) {
        expect(e.statusCode, 500);
        expect(e.code, 'HTTP_ERROR');
      }
    });
  });
}
