import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../base/constant.dart';
import '../utils/network_error_helper.dart';
import 'pref_service.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Constant.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 25),
      sendTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  /// Last server clock from API `server_time` (ISO 8601 with offset).
  static DateTime? lastServerTime;

  /// Reads top-level `server_time` from a response body and stores [lastServerTime].
  static void rememberServerTimeFromBody(dynamic data) {
    final map = parseResponseBody(data);
    if (map == null) return;
    final raw = map['server_time']?.toString().trim() ?? '';
    if (raw.isEmpty || raw == 'null') return;
    final t = DateTime.tryParse(raw);
    if (t != null) lastServerTime = t;
  }

  static void _rememberServerTime(Response r) {
    rememberServerTimeFromBody(r.data);
  }

  static Future<Options> _getAuthOptions() async {
    final token = await PrefService.getToken();
    if (token == null || token.isEmpty) {
      return Options();
    }
    return Options(headers: {"Authorization": "Bearer $token"});
  }

  static Map<String, dynamic> _networkErrorBody(DioException e) {
    return {
      'status': 'error',
      'message': NetworkErrorHelper.apiErrorMessage(e, apiMessage: e.message),
    };
  }

  static Map<String, dynamic>? responseDataMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  /// Parses API JSON whether Dio decoded it to a [Map] or left it as a [String].
  static Map<String, dynamic>? parseResponseBody(dynamic data) {
    final direct = responseDataMap(data);
    if (direct != null) return direct;
    if (data is String && data.trim().isNotEmpty) {
      try {
        return responseDataMap(jsonDecode(data));
      } catch (_) {}
    }
    return null;
  }

  /// Builds a user-facing error string from flat API error payloads (`message`, optional `field`).
  static String formatFieldError(
    Map<String, dynamic>? data, {
    String fallback = 'Request failed',
  }) {
    if (data == null) return fallback;
    final msg = data['message']?.toString().trim();
    final field = data['field']?.toString().trim();
    if (msg != null && msg.isNotEmpty) {
      if (field != null && field.isNotEmpty) return '$msg (field: $field)';
      return msg;
    }
    return fallback;
  }

  static String responseErrorHint(Response r) {
    final code = r.statusCode;
    final m = responseDataMap(r.data);
    if (m != null && m['message'] != null) {
      return m['message'].toString();
    }
    if (r.data is String) {
      final s = (r.data as String).trim();
      if (s.isNotEmpty) {
        if (s.length > 120) return '${s.substring(0, 120)}…';
        return s;
      }
    }
    if (code != null && code >= 400) {
      final emptyBody = r.data == null ||
          (r.data is String && (r.data as String).trim().isEmpty);
      if (emptyBody) {
        return 'Server error (HTTP $code). No response body — check PHP '
            'error_log; common causes: fatal error in send_event_notification.php '
            '/ send_organizer_notification.php, FCM helper, or database.';
      }
      return 'HTTP $code';
    }
    return code != null ? 'HTTP $code' : 'Request failed';
  }

  // --- Auth ---
  
  /// Request SMS OTP for mobile login (`send_login_otp` on backend).
  static Future<Response> sendLoginOtp({
    required String identifier,
    required String emailOrPhone,
    required bool isStudent,
  }) async {
    try {
      final response = await _dio.post(
        "users.php",
        queryParameters: {"action": "send_login_otp"},
        data: {
          "by_mobile": 1,
          "identifier": identifier.trim(),
          "email_or_phone": emailOrPhone.trim(),
          "is_student": isStudent ? 1 : 0,
        },
      );
      return response;
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: 'users.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  /// Password login, or SMS OTP login when [otp] is a non-empty 6-digit code (requires [byMobile]).
  static Future<Response> loginWithIdentifier(
    String identifier,
    String emailOrPhone,
    bool isStudent,
    bool byMobile, {
    String password = '',
    String? otp,
  }) async {
    try {
      final Map<String, dynamic> body = {
        "identifier": identifier.trim(),
        "email_or_phone": byMobile ? emailOrPhone.trim() : emailOrPhone.trim().toLowerCase(),
        "password": password,
        "is_student": isStudent ? 1 : 0,
        "by_mobile": byMobile ? 1 : 0,
      };
      if (otp != null && otp.isNotEmpty) {
        body["otp"] = otp;
      }
      final response = await _dio.post(
        "users.php",
        queryParameters: {"action": "login"},
        data: body,
      );
      debugPrint("🟢 Login Response: ${response.data}");
      return response;
    } on DioException catch (e) {
      debugPrint("🔴 Login DioException: ${e.message}");
      debugPrint("🔴 Response: ${e.response?.data}");
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: 'users.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  // Updated Register with all fields
  static Future<Response> register(
    String name,
    String email,
    String phone,
    String password,
    String bio,
    String interests,
    bool isStudent,
    String? rollNumber,
    String? empNumber, {
    String? departmentClass,
  }) async {
    try {
      final Map<String, dynamic> data = {
        "full_name": name.trim(),
        "email": email.trim().toLowerCase(),
        "phone": phone.trim(),
        "password": password,
        "bio": bio.trim(),
        "interests": interests.trim(),
        "is_student": isStudent ? 1 : 0,
      };
      if (departmentClass != null && departmentClass.trim().isNotEmpty) {
        data["department_class"] = departmentClass.trim();
      }
      
      // Add role-specific field
      if (isStudent) {
        data["roll_number"] = (rollNumber ?? '').trim();
      } else {
        data["emp_number"] = (empNumber ?? '').trim();
      }
      
      final response = await _dio.post("users.php", 
        queryParameters: {"action": "register"},
        data: data
      );
      debugPrint("🟢 Register Response: ${response.data}");
      return response;
    } on DioException catch (e) {
      debugPrint("🔴 Register DioException: ${e.message}");
      debugPrint("🔴 Response: ${e.response?.data}");
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'users.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  /// Result of pre-registration uniqueness checks.
  /// [emailTaken] / [phoneTaken] are null when that check could not be determined.
  static Future<({bool? emailTaken, bool? phoneTaken, String? message})>
      checkRegistrationAvailability({
    required String email,
    required String phone,
  }) async {
    bool? emailTaken;
    bool? phoneTaken;
    String? message;

    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = phone.trim();

    // Email + phone: users.php?action=check_availability
    // Expected (when backend supports it):
    // { status, email_exists, phone_exists } or message / field
    try {
      final availRes = await _dio.post(
        'users.php',
        queryParameters: const {'action': 'check_availability'},
        data: {
          'email': normalizedEmail,
          'phone': normalizedPhone,
        },
      );
      final avail = parseResponseBody(availRes.data);
      if (avail != null && avail.isNotEmpty) {
        if (avail.containsKey('email_exists') || avail.containsKey('email_taken')) {
          final v = avail['email_exists'] ?? avail['email_taken'];
          emailTaken = v == 1 || v == true || v == '1';
        }
        if (avail.containsKey('phone_exists') || avail.containsKey('phone_taken')) {
          final v = avail['phone_exists'] ?? avail['phone_taken'];
          phoneTaken = v == 1 || v == true || v == '1';
        }
        final field = avail['field']?.toString();
        final msg = avail['message']?.toString() ?? '';
        if (phoneTaken == null && field == 'phone') phoneTaken = true;
        if (emailTaken == null && field == 'email') emailTaken = true;
        if (msg.isNotEmpty) message = msg;
      }
    } on DioException catch (_) {
      // Endpoint may not exist yet — ignore
    } catch (_) {}

    // Dedicated phone check (optional backend)
    if (phoneTaken == null) {
      try {
        final phoneRes = await _dio.post(
          'users.php',
          queryParameters: const {'action': 'check_phone'},
          data: {'phone': normalizedPhone},
        );
        final phoneData = parseResponseBody(phoneRes.data);
        if (phoneData != null && phoneData.isNotEmpty) {
          final status = phoneData['status']?.toString();
          final msg = phoneData['message']?.toString().toLowerCase() ?? '';
          final exists = phoneData['exists'] ?? phoneData['phone_exists'] ?? phoneData['phone_taken'];
          if (exists == 1 || exists == true || exists == '1') {
            phoneTaken = true;
          } else if (status == 'success' &&
              (msg.contains('available') || msg.contains('not registered') || msg.contains('not found'))) {
            phoneTaken = false;
          } else if (status == 'error' &&
              (msg.contains('already') || msg.contains('registered') || msg.contains('exists'))) {
            phoneTaken = true;
          } else if (status == 'success' && msg.contains('found')) {
            phoneTaken = true;
          }
        }
      } on DioException catch (_) {
      } catch (_) {}
    }

    return (emailTaken: emailTaken, phoneTaken: phoneTaken, message: message);
  }

  /// Maps register API errors to a clear email vs phone message when possible.
  static String friendlyRegisterConflictMessage(
    String? apiMessage, {
    bool? emailTaken,
    bool? phoneTaken,
  }) {
    if (emailTaken == true && phoneTaken != true) {
      return 'Email ID already registered';
    }
    if (phoneTaken == true && emailTaken != true) {
      return 'Mobile number already registered';
    }
    if (emailTaken == true && phoneTaken == true) {
      return 'Email ID and mobile number are already registered';
    }
    final msg = (apiMessage ?? '').toLowerCase();
    if (msg.contains('email') && msg.contains('phone')) {
      return 'Email ID or mobile number already registered';
    }
    if (msg.contains('email')) return 'Email ID already registered';
    if (msg.contains('phone') || msg.contains('mobile')) {
      return 'Mobile number already registered';
    }
    return apiMessage?.trim().isNotEmpty == true
        ? apiMessage!.trim()
        : 'Email ID or mobile number already registered';
  }

  /// Step 1 — request OTP for password reset via identifier
  /// (roll number / employee ID / email / mobile).
  static Future<Response> requestForgotPasswordOtp(String identifier) async {
    try {
      return await _dio.post(
        Constant.forgotPasswordEndpoint,
        queryParameters: const {'action': 'request_otp'},
        data: {'identifier': identifier.trim()},
      );
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: Constant.forgotPasswordEndpoint),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  /// Step 2 — verify OTP; returns `reset_token` on success.
  static Future<Response> verifyForgotPasswordOtp({
    required String identifier,
    required String otp,
  }) async {
    try {
      return await _dio.post(
        Constant.forgotPasswordEndpoint,
        queryParameters: const {'action': 'verify_otp'},
        data: {
          'identifier': identifier.trim(),
          'otp': otp.trim(),
        },
      );
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: Constant.forgotPasswordEndpoint),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  /// Step 3 — set new password with reset token from verify_otp.
  static Future<Response> resetPasswordWithToken({
    required String resetToken,
    required String password,
    required String passwordConfirm,
  }) async {
    try {
      return await _dio.post(
        Constant.forgotPasswordEndpoint,
        queryParameters: const {'action': 'reset'},
        data: {
          'reset_token': resetToken,
          'password': password,
          'password_confirm': passwordConfirm,
        },
      );
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: Constant.forgotPasswordEndpoint),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  /// POST `users.php?action=switch_role` — student ↔ faculty (password + new roll/emp).
  static Future<Response> switchUserRole({
    required String userId,
    required String password,
    required int newIsStudent,
    String? rollNumber,
    String? empNumber,
  }) async {
    try {
      final uid = int.tryParse(userId) ?? userId;
      final body = <String, dynamic>{
        'user_id': uid,
        'password': password,
        'new_is_student': newIsStudent,
      };
      if (newIsStudent == 1) {
        body['roll_number'] = (rollNumber ?? '').trim();
      } else {
        body['emp_number'] = (empNumber ?? '').trim();
      }
      return await _dio.post(
        'users.php',
        queryParameters: const {'action': 'switch_role'},
        data: body,
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: 'users.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  // --- Events ---
  static Future<Response> getEvents({String? search, String? category, CancelToken? cancelToken}) async {
    try {
      Map<String, dynamic> queryParams = {"type": "live"};
      if (search != null) queryParams['search'] = search;
      if (category != null) queryParams['category'] = category;
      final response = await _dio.get(
        "events.php",
        queryParameters: queryParams,
        cancelToken: cancelToken,
        options: Options(receiveTimeout: const Duration(seconds: 20), sendTimeout: const Duration(seconds: 15)),
      );
      _rememberServerTime(response);
      return response;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      final fallback = e.response;
      if (fallback != null) _rememberServerTime(fallback);
      return fallback ?? Response(
        requestOptions: RequestOptions(path: 'events.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  /// GET single event by id (includes editor_ids, pending_edit, winners, volunteer_list, participant_list)
  static Future<Response> getEventById(int eventId) async {
    try {
      final response = await _dio.get("events.php", queryParameters: {"id": eventId});
      _rememberServerTime(response);
      return response;
    } on DioException catch (e) {
      final fallback = e.response;
      if (fallback != null) _rememberServerTime(fallback);
      return fallback ?? Response(
        requestOptions: RequestOptions(path: 'events.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  /// GET past events (event_date < NOW())
  static Future<Response> getPastEvents({String? search, String? category}) async {
    try {
      Map<String, dynamic> queryParams = {"type": "past"};
      if (search != null) queryParams['search'] = search;
      if (category != null) queryParams['category'] = category;
      final response = await _dio.get("events.php", queryParameters: queryParams);
      _rememberServerTime(response);
      return response;
    } on DioException catch (e) {
      final fallback = e.response;
      if (fallback != null) _rememberServerTime(fallback);
      return fallback ?? Response(
        requestOptions: RequestOptions(path: 'events.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  /// Closed events (`status=closed`) for winners carousel / winners list.
  static Future<Response> getClosedEvents() async {
    try {
      final response = await _dio.get(
        'events.php',
        queryParameters: const {'type': 'closed'},
      );
      _rememberServerTime(response);
      return response;
    } on DioException catch (e) {
      final fallback = e.response;
      if (fallback != null) _rememberServerTime(fallback);
      return fallback ??
          Response(
            requestOptions: RequestOptions(path: 'events.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  static Future<Response> createEvent(Map<String, dynamic> data, List<File> images) async {
    try {
      final payload = Map<String, dynamic>.from(data);
      if (!Constant.notifyAdminsBySmsOnEventSubmit) {
        payload['notify_admin_sms'] = '0';
      }
      FormData formData = FormData.fromMap(payload);
      for (var file in images) {
        formData.files.add(MapEntry(
          "banners[]",
          await MultipartFile.fromFile(file.path),
        ));
      }
      final authOpts = await _getAuthOptions();
      return await _dio.post(
        "events.php",
        data: formData,
        options: Options(
          headers: authOpts.headers,
          contentType: Headers.multipartFormDataContentType,
        ),
      );
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'events.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  // --- Profile Actions ---
  static Future<Response> getUserProfile(String userId) async {
    try {
      debugPrint("🔵 getUserProfile request for user: $userId");
      final response = await _dio.get("users.php", queryParameters: {"id": userId}, options: await _getAuthOptions());
      debugPrint("🔵 getUserProfile response: ${response.data}");
      return response;
    } on DioException catch (e) {
      debugPrint("🔴 getUserProfile error: ${e.message}");
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'users.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  static Future<Response> updateProfile(Map<String, dynamic> data) async {
    try {
      return await _dio.post("users.php", 
        queryParameters: {"action": "update_details"}, 
        data: data, 
        options: await _getAuthOptions()
      );
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'users.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  static Future<Response> uploadProfilePic(String userId, File image) async {
    try {
      FormData formData = FormData.fromMap({
        "user_id": userId,
        "profile_pic": await MultipartFile.fromFile(image.path),
      });
      return await _dio.post("users.php", 
        queryParameters: {"action": "upload_pic"}, 
        data: formData, 
        options: await _getAuthOptions()
      );
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'users.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  // --- Actions ---
  static Future<Response> toggleFavorite(String eventId) async {
    try {
      String? userId = await PrefService.getUserId();
      return await _dio.post("favorites.php", data: {"user_id": userId, "event_id": eventId}, options: await _getAuthOptions());
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'favorites.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  static Future<Response> getFavorites() async {
    try {
      String? userId = await PrefService.getUserId();
      return await _dio.get("favorites.php", queryParameters: {"user_id": userId}, options: await _getAuthOptions());
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'favorites.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  static Future<Response> joinEvent(String eventId) async {
    try {
      String? userId = await PrefService.getUserId();
      final response = await _dio.post(
        "attend.php",
        data: {"user_id": userId, "event_id": eventId},
        options: await _getAuthOptions(),
      );
      _rememberServerTime(response);
      return response;
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'attend.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  /// Leave attendee / viewer role for an event.
  static Future<Response> leaveEvent(String eventId) async {
    try {
      String? userId = await PrefService.getUserId();
      final response = await _dio.post(
        Constant.attendEndpoint,
        queryParameters: const {'action': 'leave'},
        data: {'event_id': eventId, 'user_id': userId},
        options: await _getAuthOptions(),
      );
      _rememberServerTime(response);
      return response;
    } on DioException catch (e) {
      final fallback = e.response;
      if (fallback != null) _rememberServerTime(fallback);
      return fallback ??
          Response(
            requestOptions: RequestOptions(path: Constant.attendEndpoint),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  /// Leave volunteer role for an event.
  static Future<Response> leaveVolunteer(String eventId) async {
    try {
      String? userId = await PrefService.getUserId();
      final response = await _dio.post(
        Constant.volunteersEndpoint,
        queryParameters: const {'action': 'leave'},
        data: {'event_id': eventId, 'user_id': userId},
        options: await _getAuthOptions(),
      );
      _rememberServerTime(response);
      return response;
    } on DioException catch (e) {
      final fallback = e.response;
      if (fallback != null) _rememberServerTime(fallback);
      return fallback ??
          Response(
            requestOptions: RequestOptions(path: Constant.volunteersEndpoint),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  /// Leave participant role for an event.
  static Future<Response> leaveParticipant(String eventId) async {
    try {
      String? userId = await PrefService.getUserId();
      final response = await _dio.post(
        'participant.php',
        queryParameters: const {'action': 'leave'},
        data: {'event_id': eventId, 'user_id': userId},
        options: await _getAuthOptions(),
      );
      _rememberServerTime(response);
      return response;
    } on DioException catch (e) {
      final fallback = e.response;
      if (fallback != null) _rememberServerTime(fallback);
      return fallback ??
          Response(
            requestOptions: RequestOptions(path: 'participant.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  static Future<Response> getAttendingEvents() async {
    try {
      String? userId = await PrefService.getUserId();
      if (userId == null) {
        return Response(
          requestOptions: RequestOptions(path: 'events.php'),
          statusCode: 400,
          data: {'status': 'error', 'message': 'User ID not found'}
        );
      }
      final response = await _dio.get("events.php", queryParameters: {
        "user_id": userId, 
        "type": "attending"
      }, options: await _getAuthOptions());
      _rememberServerTime(response);
      debugPrint("🔵 getAttendingEvents response: ${response.data}");
      return response;
    } on DioException catch (e) {
      debugPrint("🔴 getAttendingEvents error: ${e.message}");
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'events.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  static Future<Response> getVolunteeringEvents() async {
    try {
      String? userId = await PrefService.getUserId();
      if (userId == null) {
        return Response(
          requestOptions: RequestOptions(path: 'events.php'),
          statusCode: 400,
          data: {'status': 'error', 'message': 'User ID not found'}
        );
      }
      final response = await _dio.get("events.php", queryParameters: {
        "user_id": userId, 
        "type": "volunteering"
      }, options: await _getAuthOptions());
      _rememberServerTime(response);
      debugPrint("🔵 getVolunteeringEvents response: ${response.data}");
      return response;
    } on DioException catch (e) {
      debugPrint("🔴 getVolunteeringEvents error: ${e.message}");
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'events.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  static Future<Response> getHostedEvents() async {
    try {
      String? userId = await PrefService.getUserId();
      if (userId == null) {
        return Response(
          requestOptions: RequestOptions(path: 'events.php'),
          statusCode: 400,
          data: {'status': 'error', 'message': 'User ID not found'}
        );
      }
      final response = await _dio.get("events.php", queryParameters: {
        "user_id": userId, 
        // Fetch both approved and non-approved hosted events
        "type": "hosted_all"
      }, options: await _getAuthOptions());
      debugPrint("🔵 getHostedEvents response: ${response.data}");
      return response;
    } on DioException catch (e) {
      debugPrint("🔴 getHostedEvents error: ${e.message}");
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'events.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  static Future<Response> updateEvent({
    required int id,
    required String title,
    required String description,
    required String venue,
    String? eventDate,
    String? category,
    String? rules,
    String? eventEndDate,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        "id": id,
        "user_id": await PrefService.getUserId(),
        "title": title,
        "description": description,
        "venue": venue,
      };
      if (eventDate != null && eventDate.isNotEmpty) payload["event_date"] = eventDate;
      if (category != null && category.isNotEmpty) payload["category"] = category;
      if (rules != null) payload["rules"] = rules;
      if (eventEndDate != null) payload["event_end_date"] = eventEndDate;
      final response = await _dio.put(
        "events.php",
        data: payload,
        options: await _getAuthOptions(),
      );
      debugPrint("🔵 updateEvent response: ${response.data}");
      return response;
    } on DioException catch (e) {
      debugPrint("🔴 updateEvent error: ${e.message}");
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: 'events.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  /// Update event via POST multipart (same fields as create + optional banners). Use for organizer/editor edit with banner.
  static Future<Response> updateEventWithFormData({
    required int eventId,
    required String userId,
    required String title,
    required String description,
    required String venue,
    required String eventDate,
    required String category,
    List<File>? bannerFiles,
    String? rules,
    String? eventEndDate,
  }) async {
    try {
      final Map<String, dynamic> data = {
        "action": "update",
        "event_id": eventId,
        "user_id": userId,
        "title": title,
        "description": description,
        "venue": venue,
        "event_date": eventDate,
        "category": category,
        "rules": rules ?? '',
      };
      if (eventEndDate != null) data["event_end_date"] = eventEndDate;
      final formData = FormData.fromMap(Map<String, dynamic>.from(data));
      if (bannerFiles != null && bannerFiles.isNotEmpty) {
        for (var file in bannerFiles) {
          formData.files.add(MapEntry(
            "banners[]",
            await MultipartFile.fromFile(file.path),
          ));
        }
      }
      final response = await _dio.post(
        "events.php",
        data: formData,
        options: await _getAuthOptions(),
      );
      debugPrint("🔵 updateEventWithFormData response: ${response.data}");
      return response;
    } on DioException catch (e) {
      debugPrint("🔴 updateEventWithFormData error: ${e.message}");
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: 'events.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  static Future<Response> deleteEvent({required int id}) async {
    try {
      String? userId = await PrefService.getUserId();
      if (userId == null) {
        return Response(
          requestOptions: RequestOptions(path: 'events.php'),
          statusCode: 400,
          data: {'status': 'error', 'message': 'User ID not found'},
        );
      }

      final response = await _dio.delete(
        "events.php",
        queryParameters: {"id": id, "user_id": int.tryParse(userId) ?? userId},
        options: await _getAuthOptions(),
      );
      debugPrint("🔵 deleteEvent response: ${response.data}");
      return response;
    } on DioException catch (e) {
      debugPrint("🔴 deleteEvent error: ${e.message}");
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: 'events.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  static Future<Response> joinVolunteer(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("volunteers.php", data: data, options: await _getAuthOptions());
      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      try {
        return Response(
          requestOptions: RequestOptions(path: 'volunteers.php'),
          statusCode: 0,
          data: _networkErrorBody(e),
        );
      } catch (e2) {
        return Response(
          requestOptions: RequestOptions(path: 'volunteers.php'),
          statusCode: -1,
          data: {'status': 'error', 'message': 'Request failed'}
        );
      }
    } catch (e) {
      return Response(
        requestOptions: RequestOptions(path: 'volunteers.php'),
        statusCode: -1,
        data: {'status': 'error', 'message': 'Unexpected error: ${e.toString()}'}
      );
    }
  }

  /// Switch active volunteer ↔ participant for one approved event.
  static Future<Response> switchEventStaffRole(Map<String, dynamic> data) async {
    try {
      return await _dio.post(
        'event_staff_switch.php',
        data: data,
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      return Response(
        requestOptions: RequestOptions(path: 'event_staff_switch.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  static Future<Response> joinParticipant(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("participant.php", data: data, options: await _getAuthOptions());
      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      try {
        return Response(
          requestOptions: RequestOptions(path: 'participant.php'),
          statusCode: 0,
          data: _networkErrorBody(e),
        );
      } catch (e2) {
        return Response(
          requestOptions: RequestOptions(path: 'participant.php'),
          statusCode: -1,
          data: {'status': 'error', 'message': 'Request failed'}
        );
      }
    } catch (e) {
      return Response(
        requestOptions: RequestOptions(path: 'participant.php'),
        statusCode: -1,
        data: {'status': 'error', 'message': 'Unexpected error: ${e.toString()}'}
      );
    }
  }

  static Future<Response> getParticipatingEvents() async {
    try {
      String? userId = await PrefService.getUserId();
      if (userId == null) {
        return Response(
          requestOptions: RequestOptions(path: 'events.php'),
          statusCode: 400,
          data: {'status': 'error', 'message': 'User ID not found'}
        );
      }
      final response = await _dio.get("events.php", queryParameters: {
        "user_id": userId, 
        "type": "participating"
      }, options: await _getAuthOptions());
      _rememberServerTime(response);
      debugPrint("🔵 getParticipatingEvents response: ${response.data}");
      return response;
    } on DioException catch (e) {
      debugPrint("🔴 getParticipatingEvents error: ${e.message}");
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'events.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  /// Events the user can edit (admin granted permission via event_editors). Requires API view type=editing.
  static Future<Response> getEditingEvents() async {
    try {
      String? userId = await PrefService.getUserId();
      if (userId == null) {
        return Response(
          requestOptions: RequestOptions(path: 'events.php'),
          statusCode: 400,
          data: {'status': 'error', 'message': 'User ID not found'}
        );
      }
      final response = await _dio.get("events.php", queryParameters: {
        "user_id": userId,
        "type": "editing"
      }, options: await _getAuthOptions());
      return response;
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'events.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  // --- Winners (GET by event_id) ---
  static Future<Response> getWinnersByEventId(int eventId) async {
    try {
      return await _dio.get("event_winners.php", queryParameters: {"event_id": eventId});
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'event_winners.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  // --- E-Certificates (GET by user_id or event_id) ---
  static Future<Response> getCertificatesByUserId(String userId) async {
    try {
      return await _dio.get(
        "certificates.php",
        queryParameters: {"user_id": userId.trim()},
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'certificates.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  static Future<Response> getCertificatesByEventId(int eventId) async {
    try {
      return await _dio.get(
        "certificates.php",
        queryParameters: {"event_id": eventId},
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'certificates.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  /// Upload e-certificate for a user (admin): event_id, user_id, type (volunteer/participant), file
  static Future<Response> uploadCertificate({
    required int eventId,
    required String userId,
    required String type,
    required File file,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        "event_id": eventId,
        "user_id": userId,
        "type": type,
        "certificate": await MultipartFile.fromFile(file.path),
      });
      return await _dio.post(
        "certificates.php",
        data: formData,
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'certificates.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  // --- Event editors (admin grants edit permission) ---
  static Future<Response> addEventEditor({required int eventId, required String userId}) async {
    try {
      return await _dio.post(
        "event_editors.php",
        data: {"event_id": eventId, "user_id": userId, "action": "add"},
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'event_editors.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  static Future<Response> removeEventEditor({required int eventId, required String userId}) async {
    try {
      return await _dio.post(
        "event_editors.php",
        data: {"event_id": eventId, "user_id": userId, "action": "remove"},
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'event_editors.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  // --- FCM & Notifications ---

  /// Register FCM token for push notifications (user_id, fcm_token, optional device_id).
  static Future<Response> registerFcmToken({
    required String userId,
    required String fcmToken,
    String? deviceId,
  }) async {
    try {
      final data = <String, dynamic>{"user_id": userId, "fcm_token": fcmToken};
      if (deviceId != null && deviceId.isNotEmpty) data["device_id"] = deviceId;
      return await _dio.post("register_fcm_token.php", data: data, options: await _getAuthOptions());
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'register_fcm_token.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  /// Get list of notification dates (schedule, celebrations, events). Optional: from, to, include_events, include_celebrations.
  static Future<Response> getNotificationDates({
    String? from,
    String? to,
    bool includeEvents = true,
    bool includeCelebrations = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) queryParams['from'] = from;
      if (to != null) queryParams['to'] = to;
      if (!includeEvents) queryParams['include_events'] = '0';
      if (!includeCelebrations) queryParams['include_celebrations'] = '0';
      return await _dio.get(
        "notification_dates.php",
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'notification_dates.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  /// Organizer sends push + inbox to volunteers/participants/all
  /// (`recipient_type`: volunteers|participants|both|all). Server: send_organizer_notification.php.
  static Future<Response> sendEventNotification({
    required int eventId,
    required String organizerId,
    required String message,
    String recipientType = 'both',
  }) async {
    try {
      final auth = await _getAuthOptions();
      final opts = Options(
        headers: auth.headers,
        validateStatus: (s) => s != null && s < 600,
      );
      const primary = 'send_organizer_notification.php';
      const legacy = 'send_event_notification.php';
      Response r = await _dio.post(
        primary,
        data: {
          "event_id": eventId,
          "organizer_id": organizerId,
          "message": message,
          "recipient_type": recipientType,
        },
        options: opts,
      );
      if (r.statusCode == 404) {
        r = await _dio.post(
          legacy,
          data: {
            "event_id": eventId,
            "organizer_id": organizerId,
            "message": message,
            "recipient_type": recipientType,
          },
          options: opts,
        );
      }
      return r;
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: 'send_organizer_notification.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  /// Admin-configured app settings (e.g. logo path under uploads/app/).
  static Future<Response> getAppSettings() async {
    try {
      return await _dio.get(
        'app_settings.php',
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: 'app_settings.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  /// Active home-screen advertisement posts.
  static Future<Response> getAdPosts() async {
    try {
      return await _dio.get(
        'ad_posts.php',
        options: Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: 'ad_posts.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  // --- Inbox Notifications ---

  /// Fetch in-app notifications for [userId] within last [hours] (default 24, max 168).
  static Future<Response> getInboxNotifications({
    required String userId,
    int hours = 24,
  }) async {
    try {
      return await _dio.get(
        "user_notifications.php",
        queryParameters: {"user_id": userId, "hours": hours},
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: 'user_notifications.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  /// Mark specific notification IDs as read.
  static Future<Response> markNotificationsRead({
    required String userId,
    required List<int> notificationIds,
  }) async {
    try {
      return await _dio.post(
        "user_notifications.php",
        data: {
          "user_id": int.tryParse(userId) ?? userId,
          "action": "mark_read",
          "notification_ids": notificationIds,
        },
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: 'user_notifications.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  /// Mark all notifications as read within last [hours].
  static Future<Response> markAllNotificationsRead({
    required String userId,
    int hours = 24,
  }) async {
    try {
      return await _dio.post(
        "user_notifications.php",
        data: {
          "user_id": int.tryParse(userId) ?? userId,
          "action": "mark_all_read",
          "hours": hours,
        },
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: 'user_notifications.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  /// Organizer-only: `set_review` or `set_attendance`.
  /// Tries [event_organizer.php] then [event_organizer.php] — a 404 "File not found" usually means
  /// neither script is deployed under [Constant.baseUrl] (same directory as events.php).
  static Future<Response> eventOrganiserAction(Map<String, dynamic> body) async {
    const paths = ['event_organizer.php', 'event_organizer.php'];
    try {
      final auth = await _getAuthOptions();
      final opts = Options(
        headers: auth.headers,
        validateStatus: (s) => s != null && s < 600,
      );
      Response? last404;
      for (final path in paths) {
        final r = await _dio.post(path, data: body, options: opts);
        if (r.statusCode == 404) {
          last404 = r;
          continue;
        }
        return r;
      }
      return Response(
        requestOptions: last404?.requestOptions ?? RequestOptions(path: paths.last),
        statusCode: 404,
        data: {
          'status': 'error',
          'message':
              'Organizer API missing on server (404). Upload event_organizer.php to ${Constant.baseUrl} (same folder as events.php).',
        },
      );
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: 'event_organizer.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  /// Organizer `set_review` with optional file attachments (`review_files[]`).
  static Future<Response> eventOrganiserSetReviewMultipart({
    required int eventId,
    required int organizerId,
    required String organizerReview,
    List<File> reviewFiles = const [],
  }) async {
    try {
      final auth = await _getAuthOptions();
      final opts = Options(
        headers: auth.headers,
        validateStatus: (s) => s != null && s < 600,
      );
      final map = <String, dynamic>{
        'action': 'set_review',
        'event_id': eventId.toString(),
        'organizer_id': organizerId.toString(),
        'organizer_review': organizerReview,
      };
      final form = FormData.fromMap(map);
      for (final f in reviewFiles) {
        if (!await f.exists()) continue;
        form.files.add(
          MapEntry(
            'review_files[]',
            await MultipartFile.fromFile(
              f.path,
              filename: p.basename(f.path),
            ),
          ),
        );
      }
      return await _dio.post(
        'event_organizer.php',
        data: form,
        options: opts,
      );
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: 'event_organizer.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  /// Meeting minutes — submit text + optional attachment.
  static Future<Response> submitMeetingMinutes({
    required int eventId,
    required String content,
    File? attachment,
  }) async {
    try {
      final auth = await _getAuthOptions();
      final opts = Options(
        headers: auth.headers,
        validateStatus: (s) => s != null && s < 600,
      );
      final map = <String, dynamic>{
        'action': 'submit',
        'event_id': eventId.toString(),
        'content': content,
      };
      final form = FormData.fromMap(map);
      if (attachment != null && await attachment.exists()) {
        form.files.add(
          MapEntry(
            'attachment',
            await MultipartFile.fromFile(
              attachment.path,
              filename: p.basename(attachment.path),
            ),
          ),
        );
      }
      return await _dio.post(
        'meeting_minutes.php',
        data: form,
        options: opts,
      );
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: 'meeting_minutes.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  /// Meeting minutes — fetch current minutes + status for an event.
  static Future<Response> getMeetingMinutes(int eventId) async {
    try {
      final auth = await _getAuthOptions();
      return await _dio.get(
        'meeting_minutes.php',
        queryParameters: {
          'action': 'get',
          'event_id': eventId.toString(),
        },
        options: auth,
      );
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: 'meeting_minutes.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  /// Organizer closes a past event.
  static Future<Response> closeEvent({
    required int eventId,
    required int organizerId,
  }) async {
    try {
      return await eventOrganiserAction({
        'action': 'close',
        'event_id': eventId,
        'organizer_id': organizerId,
      });
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: 'event_organizer.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }

  /// Winner photos carousel (closed events).
  static Future<Response> getWinnerPhotos({int limit = 20}) async {
    try {
      return await _dio.get(
        'winner_photos.php',
        queryParameters: {'limit': limit},
      );
    } on DioException catch (e) {
      return e.response ??
          Response(
            requestOptions: RequestOptions(path: 'winner_photos.php'),
            statusCode: 0,
            data: _networkErrorBody(e),
          );
    }
  }
}