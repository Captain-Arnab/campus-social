import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../base/constant.dart';
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
    String? token = await PrefService.getToken();
    return Options(headers: {"Authorization": "Bearer $token"});
  }

  // --- Auth ---
  
  // Updated Login with identifier (roll/emp number), email/phone, and role
  static Future<Response> loginWithIdentifier(
    String identifier,
    String emailOrPhone,
    String password,
    bool isStudent,
    bool byMobile,
  ) async {
    try {
      final response = await _dio.post("users.php", 
        queryParameters: {"action": "login"},
        data: {
          "identifier": identifier, // roll_number or emp_number
          "email_or_phone": emailOrPhone,
          "password": password,
          "is_student": isStudent ? 1 : 0,
          "by_mobile": byMobile ? 1 : 0,
        }
      );
      debugPrint("🟢 Login Response: ${response.data}");
      return response;
    } on DioException catch (e) {
      debugPrint("🔴 Login DioException: ${e.message}");
      debugPrint("🔴 Response: ${e.response?.data}");
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'users.php'),
        statusCode: 0,
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
    String? empNumber,
  ) async {
    try {
      final Map<String, dynamic> data = {
        "full_name": name,
        "email": email,
        "phone": phone,
        "password": password,
        "bio": bio,
        "interests": interests,
        "is_student": isStudent ? 1 : 0,
      };
      
      // Add role-specific field
      if (isStudent) {
        data["roll_number"] = rollNumber;
      } else {
        data["emp_number"] = empNumber;
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
      );
    }
  }

  static Future<Response> forgotPassword(String email) async {
    try {
      return await _dio.post("forgot_password.php", 
        queryParameters: {"action": "check_email"},
        data: {"email": email}
      );
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'forgot_password.php'),
        statusCode: 0,
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
      );
    }
  }

  static Future<Response> resetPassword(String email, String newPassword) async {
    try {
      return await _dio.post("forgot_password.php",
        queryParameters: {"action": "reset"},
        data: {"email": email, "password": newPassword}
      );
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'forgot_password.php'),
        statusCode: 0,
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
      );
    }
  }

  static Future<Response> createEvent(Map<String, dynamic> data, List<File> images) async {
    try {
      FormData formData = FormData.fromMap(data);
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
            data: {'status': 'error', 'message': 'Network error: ${e.message}'},
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
      };
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
            data: {'status': 'error', 'message': 'Network error: ${e.message}'},
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
            data: {'status': 'error', 'message': 'Network error: ${e.message}'},
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
          data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
          data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
      );
    }
  }

  // --- E-Certificates (GET by user_id or event_id) ---
  static Future<Response> getCertificatesByUserId(String userId) async {
    try {
      return await _dio.get(
        "event_certificates.php",
        queryParameters: {"user_id": userId.trim()},
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'event_certificates.php'),
        statusCode: 0,
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
      );
    }
  }

  static Future<Response> getCertificatesByEventId(int eventId) async {
    try {
      return await _dio.get(
        "event_certificates.php",
        queryParameters: {"event_id": eventId},
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'event_certificates.php'),
        statusCode: 0,
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
        "event_certificates.php",
        data: formData,
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      return e.response ?? Response(
        requestOptions: RequestOptions(path: 'event_certificates.php'),
        statusCode: 0,
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
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
        data: {'status': 'error', 'message': 'Network error: ${e.message}'}
      );
    }
  }
}