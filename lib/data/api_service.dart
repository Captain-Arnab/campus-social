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

  static Future<Response> forgotPassword(String email) async {
    try {
      final normalized = email.trim().toLowerCase();
      return await _dio.post("forgot_password.php", 
        queryParameters: {"action": "check_email"},
        data: {"email": normalized}
      );
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'forgot_password.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  static Future<Response> resetPassword(String email, String newPassword) async {
    try {
      final normalized = email.trim().toLowerCase();
      return await _dio.post("forgot_password.php",
        queryParameters: {"action": "reset"},
        data: {"email": normalized, "password": newPassword}
      );
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'forgot_password.php'),
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
      return await _dio.get(
        "events.php",
        queryParameters: queryParams,
        cancelToken: cancelToken,
        options: Options(receiveTimeout: const Duration(seconds: 20), sendTimeout: const Duration(seconds: 15)),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'events.php'),
        statusCode: 0,
        data: _networkErrorBody(e),
      );
    }
  }

  /// GET single event by id (includes editor_ids, pending_edit, winners, volunteer_list, participant_list)
  static Future<Response> getEventById(int eventId) async {
    try {
      return await _dio.get("events.php", queryParameters: {"id": eventId});
    } on DioException catch (e) {
      return e.response ?? Response(
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
      return await _dio.get("events.php", queryParameters: queryParams);
    } on DioException catch (e) {
      return e.response ?? Response(
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
      return await _dio.post("events.php", data: formData, options: await _getAuthOptions());
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
      return await _dio.post("attend.php", data: {"user_id": userId, "event_id": eventId}, options: await _getAuthOptions());
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'attend.php'),
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
}