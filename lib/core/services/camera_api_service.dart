import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../data/models/camera.dart';

class CameraApiService {
  static String get _baseUrl =>
      dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:3000';

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  static Future<List<Camera>> fetchCameras({
    required String token,
    String? search,
    double? minRange,
    double? maxRange,
    int? surveyorId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = <String, String>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (minRange != null) query['min_range'] = minRange.toString();
    if (maxRange != null) query['max_range'] = maxRange.toString();
    if (surveyorId != null) query['surveyor_id'] = surveyorId.toString();
    if (fromDate != null) query['from_date'] = fromDate.toIso8601String();
    if (toDate != null) query['to_date'] = toDate.toIso8601String();

    final uri = Uri.parse(
      '$_baseUrl/api/cameras',
    ).replace(queryParameters: query);
    final response = await http.get(uri, headers: _headers(token));

    if (response.statusCode != 200) {
      throw Exception('Failed to load cameras (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Camera.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<SurveyorUser>> fetchSurveyors({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/cameras/surveyors/list'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load surveyors (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => SurveyorUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<Camera> addCamera({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/cameras/add'),
      headers: _headers(token),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201) {
      String message = 'Failed to add camera';
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['message'] != null) {
          message = body['message'].toString();
        } else {
          message = response.body;
        }
      } catch (_) {
        message = response.body;
      }
      throw Exception('(${response.statusCode}) $message');
    }

    return Camera.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<Camera> updateCamera({
    required String token,
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/cameras/$id'),
      headers: _headers(token),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update camera (${response.statusCode})');
    }

    return Camera.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> deleteCamera({
    required String token,
    required int id,
  }) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/cameras/$id'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete camera (${response.statusCode})');
    }
  }
}
