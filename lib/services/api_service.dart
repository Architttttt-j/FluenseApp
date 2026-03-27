// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../models/client_model.dart';
import '../models/attendance_model.dart';
import '../models/visit_model.dart';
import '../models/goal_model.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  // ─── Token management ───────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // ─── Headers ────────────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Auth ───────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse(AppConfig.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        if (data['token'] != null) await saveToken(data['token']);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error or timeout. Please check your connection or server.'};
    }
  }

  static Future<UserModel?> getMe() async {
    try {
      final res = await http.get(
        Uri.parse(AppConfig.meEndpoint),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return UserModel.fromJson(data['user'] ?? data);
      }
    } catch (_) {
      // Return null if request fails or times out
    }
    return null;
  }

  // ─── Attendance ─────────────────────────────────────────────────────────────

  static Future<AttendanceModel?> getTodayAttendance(String mrId) async {
    final today = DateTime.now();
    final date =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final res = await http.get(
      Uri.parse('${AppConfig.attendanceEndpoint}?mrId=$mrId&date=$date'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['data'] ?? []);
      if (list.isNotEmpty) return AttendanceModel.fromJson(list[0]);
    }
    return null;
  }

  static Future<bool> checkIn({
    required String mrId,
    required double lat,
    required double lng,
  }) async {
    final today = DateTime.now();
    final date =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final time =
        '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}';
    final res = await http.post(
      Uri.parse('${AppConfig.attendanceEndpoint}/checkin'),
      headers: await _headers(),
      body: jsonEncode({
        'mrId': mrId,
        'date': date,
        'checkIn': time,
        'checkInLocation': {'lat': lat, 'lng': lng},
      }),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  static Future<bool> checkOut({
    required String mrId,
    required double lat,
    required double lng,
  }) async {
    final today = DateTime.now();
    final date =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final time =
        '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}';
    final res = await http.post(
      Uri.parse('${AppConfig.attendanceEndpoint}/checkout'),
      headers: await _headers(),
      body: jsonEncode({
        'mrId': mrId,
        'date': date,
        'checkOut': time,
        'checkOutLocation': {'lat': lat, 'lng': lng},
      }),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  static Future<List<AttendanceModel>> getAttendanceHistory(String mrId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.attendanceEndpoint}?mrId=$mrId&limit=30'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['data'] ?? []);
      return list.map<AttendanceModel>((j) => AttendanceModel.fromJson(j)).toList();
    }
    return [];
  }

  // ─── Clients ────────────────────────────────────────────────────────────────

  static Future<List<ClientModel>> getClients({String? regionId, String? type}) async {
    String url = AppConfig.clientsEndpoint;
    final params = <String, String>{};
    if (regionId != null) params['regionId'] = regionId;
    if (type != null) params['type'] = type;
    if (params.isNotEmpty) {
      url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }
    final res = await http.get(Uri.parse(url), headers: await _headers());
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['data'] ?? []);
      return list.map<ClientModel>((j) => ClientModel.fromJson(j)).toList();
    }
    return [];
  }

  static Future<ClientModel?> getClientById(String clientId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.clientsEndpoint}/$clientId'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return ClientModel.fromJson(data['data'] ?? data);
    }
    return null;
  }

  // ─── Visits ─────────────────────────────────────────────────────────────────

  static Future<List<VisitModel>> getTodayVisits(String mrId) async {
    final today = DateTime.now();
    final date =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final res = await http.get(
      Uri.parse('${AppConfig.visitsEndpoint}?mrId=$mrId&date=$date'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['data'] ?? []);
      return list.map<VisitModel>((j) => VisitModel.fromJson(j)).toList();
    }
    return [];
  }

  static Future<List<VisitModel>> getClientVisitHistory(String clientId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.visitsEndpoint}?clientId=$clientId&limit=20'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['data'] ?? []);
      return list.map<VisitModel>((j) => VisitModel.fromJson(j)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> startVisit({
    required String mrId,
    required String clientId,
    required double lat,
    required double lng,
  }) async {
    final today = DateTime.now();
    final date =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final time =
        '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}';
    final res = await http.post(
      Uri.parse('${AppConfig.visitsEndpoint}/start'),
      headers: await _headers(),
      body: jsonEncode({
        'mrId': mrId,
        'clientId': clientId,
        'date': date,
        'checkIn': time,
        'checkInLocation': {'lat': lat, 'lng': lng},
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return {'success': true, 'visitId': data['_id'] ?? data['id'] ?? data['visitId']};
    }
    return {'success': false, 'message': data['message'] ?? 'Failed to start visit'};
  }

  static Future<bool> endVisit({
    required String visitId,
    required double lat,
    required double lng,
    required List<String> products,
    String? notes,
    String? collaboratorMrId,
    String? photoBase64,
  }) async {
    final today = DateTime.now();
    final time =
        '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}';
    final res = await http.patch(
      Uri.parse('${AppConfig.visitsEndpoint}/$visitId/end'),
      headers: await _headers(),
      body: jsonEncode({
        'checkOut': time,
        'checkOutLocation': {'lat': lat, 'lng': lng},
        'products': products,
        'notes': notes,
        if (collaboratorMrId != null) 'collaboratorMrId': collaboratorMrId,
        if (photoBase64 != null) 'photoBase64': photoBase64,
      }),
    );
    return res.statusCode == 200;
  }

  // ─── Goals ──────────────────────────────────────────────────────────────────

  static Future<GoalModel?> getTodayGoal(String mrId) async {
    final today = DateTime.now();
    final date =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final res = await http.get(
      Uri.parse('${AppConfig.goalsEndpoint}?mrId=$mrId&date=$date'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['data'] ?? []);
      if (list.isNotEmpty) return GoalModel.fromJson(list[0]);
    }
    return null;
  }

  // ─── Users (for collaborative work) ─────────────────────────────────────────

  static Future<List<UserModel>> getMRsInRegion(String regionId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.usersEndpoint}?regionId=$regionId&role=mr'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['data'] ?? []);
      return list.map<UserModel>((j) => UserModel.fromJson(j)).toList();
    }
    return [];
  }

  // ─── Report log ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getReportLog(String mrId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.visitsEndpoint}?mrId=$mrId&limit=30'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['data'] ?? []);
      return List<Map<String, dynamic>>.from(list);
    }
    return [];
  }
}
