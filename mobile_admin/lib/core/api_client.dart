import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/auth_models.dart';
import '../models/menu_models.dart';
import 'api_config.dart';

class ApiClient {
  static String? authToken;

  static Map<String, String> _headers({bool json = false}) {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    final token = authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Never _throwRequestError(String message, http.Response response) {
    final body = response.body.trim();
    final suffix = body.isEmpty ? '' : ': $body';
    throw Exception('$message (${response.statusCode})$suffix');
  }

  static void _log(String message) {
    debugPrint('[ApiClient] $message');
  }

  static Map<String, String> _sanitizeHeaders(Map<String, String> headers) {
    return headers.map((key, value) {
      if (key.toLowerCase() == 'authorization') {
        if (value.length <= 20) {
          return MapEntry(key, value);
        }
        return MapEntry(key, '${value.substring(0, 20)}...');
      }
      return MapEntry(key, value);
    });
  }

  static void _logRequest(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    _log('REQUEST $method $uri');
    if (headers != null && headers.isNotEmpty) {
      _log('REQUEST HEADERS ${jsonEncode(_sanitizeHeaders(headers))}');
    }
    if (body != null) {
      _log('REQUEST BODY $body');
    }
  }

  static void _logResponse(String method, Uri uri, http.Response response) {
    _log('RESPONSE $method $uri -> ${response.statusCode}');
    final body = response.body.trim();
    if (body.isNotEmpty) {
      _log('RESPONSE BODY $body');
    }
  }

  static Future<http.Response> _get(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    _logRequest('GET', uri, headers: headers);
    final response = await http.get(uri, headers: headers);
    _logResponse('GET', uri, response);
    return response;
  }

  static Future<http.Response> _post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    _logRequest('POST', uri, headers: headers, body: body);
    final response = await http.post(uri, headers: headers, body: body);
    _logResponse('POST', uri, response);
    return response;
  }

  static Future<http.Response> _put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    _logRequest('PUT', uri, headers: headers, body: body);
    final response = await http.put(uri, headers: headers, body: body);
    _logResponse('PUT', uri, response);
    return response;
  }

  static Future<http.Response> _delete(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    _logRequest('DELETE', uri, headers: headers);
    final response = await http.delete(uri, headers: headers);
    _logResponse('DELETE', uri, response);
    return response;
  }

  static Future<List<MenuSummary>> listMenus() async {
    final response = await _get(Uri.parse('${ApiConfig.baseUrl}/api/menus'));
    if (response.statusCode != 200) {
      _throwRequestError('Failed to load menus', response);
    }
    final decoded = jsonDecode(response.body) as List;
    return decoded.map((entry) => MenuSummary.fromJson(entry)).toList();
  }

  static Future<MenuData> getMenu(String menuId) async {
    final response = await _get(
      Uri.parse('${ApiConfig.baseUrl}/api/menus/$menuId'),
    );
    if (response.statusCode != 200) {
      _throwRequestError('Failed to load menu', response);
    }
    return MenuData.fromJson(jsonDecode(response.body));
  }

  static Future<MenuData> createMenu({
    required String hotelName,
    required String currency,
    required String hours,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/menus');
    final headers = _headers(json: true);
    final body = jsonEncode({
      'hotel': {
        'name': hotelName,
        'tagline': '',
        'currency': currency,
        'hours': hours,
      },
      'categories': <dynamic>[],
      'items': <dynamic>[],
      'labels': <String, String>{},
      'categoryAliases': <String, List<String>>{},
    });
    final response = await _post(uri, headers: headers, body: body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      _throwRequestError('Failed to create menu', response);
    }
    return MenuData.fromJson(jsonDecode(response.body));
  }

  static Future<MenuData> createItem(String menuId, MenuItemData item) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/menus/$menuId/items');
    final headers = _headers(json: true);
    final body = jsonEncode(item.toJson());
    final response = await _post(uri, headers: headers, body: body);
    if (response.statusCode >= 400) {
      _throwRequestError('Failed to create item', response);
    }
    return MenuData.fromJson(jsonDecode(response.body));
  }

  static Future<MenuData> updateItem(
    String menuId,
    String itemId,
    MenuItemData item,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/menus/$menuId/items/$itemId');
    final headers = _headers(json: true);
    final body = jsonEncode(item.toJson());
    final response = await _put(uri, headers: headers, body: body);
    if (response.statusCode >= 400) {
      _throwRequestError('Failed to update item', response);
    }
    return MenuData.fromJson(jsonDecode(response.body));
  }

  static Future<MenuData> deleteItem(String menuId, String itemId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/menus/$menuId/items/$itemId');
    final headers = _headers();
    final response = await _delete(uri, headers: headers);
    if (response.statusCode >= 400) {
      _throwRequestError('Failed to delete item', response);
    }
    return MenuData.fromJson(jsonDecode(response.body));
  }

  static Future<MenuData> createCategory(
    String menuId,
    CategoryData category,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/menus/$menuId/categories');
    final headers = _headers(json: true);
    final body = jsonEncode(category.toJson());
    final response = await _post(uri, headers: headers, body: body);
    if (response.statusCode >= 400) {
      _throwRequestError('Failed to create category', response);
    }
    return MenuData.fromJson(jsonDecode(response.body));
  }

  static Future<MenuData> updateCategory(
    String menuId,
    String categoryId,
    CategoryData category,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/menus/$menuId/categories/$categoryId',
    );
    final headers = _headers(json: true);
    final body = jsonEncode(category.toJson());
    final response = await _put(uri, headers: headers, body: body);
    if (response.statusCode >= 400) {
      _throwRequestError('Failed to update category', response);
    }
    return MenuData.fromJson(jsonDecode(response.body));
  }

  static Future<AuthResponse> loginWithGoogle(String idToken) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/google/login');
    final headers = _headers(json: true);
    final body = jsonEncode({'idToken': idToken});
    final response = await _post(uri, headers: headers, body: body);
    if (response.statusCode >= 400) {
      _throwRequestError('Google login failed', response);
    }
    final auth = AuthResponse.fromJson(jsonDecode(response.body));
    authToken = auth.token;
    return auth;
  }
}
