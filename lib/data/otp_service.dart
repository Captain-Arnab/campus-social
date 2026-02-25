import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../base/constant.dart';

class OtpService {
  // NOTE:
  // - In production you SHOULD NOT call the SMS gateway directly from the app
  //   (credentials + OTP generation must live on your backend).
  // - This file keeps the current approach, but improves TLS handling + logging.

  static Dio _dio = Dio();

  /// Temporarily allow insecure TLS only in debug/profile to unblock testing
  /// when the SMS provider serves an incomplete certificate chain.
  /// Keep this `false` for release builds.
  static const bool _allowBadCertificatesForSmsInDebug = true;

  static Dio _createDio({required bool allowBadCertificates}) {
    final dio = Dio();

    if (allowBadCertificates && !kReleaseMode) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return client;
        },
      );
    }

    return dio;
  }
  
  // SMS Gateway credentials
  static const String smsApiUrl = "https://sms.adwingsdigital.com/api/send-otp";
  static const String smsUsername = "harvinder";
  static const String smsPassword = "Harvinder@2026";
  
  // Email credentials - use your backend URL
  static String get emailApiUrl => "${Constant.baseUrl}send_email_otp.php";
  static const String emailId = "micampusco@gmail.com";
  static const String emailAppPassword = "rjht knaj obpk isob";
  
  // Send OTP via SMS
  static Future<Map<String, dynamic>> sendSmsOtp(String phone) async {
    try {
      final otp = _generateOtp();
      // Never log OTPs.
      debugPrint("🔵 Sending SMS OTP to: $phone");
      
      Future<Response<dynamic>> doPost(Dio dio) {
        return dio.post(
          smsApiUrl,
          data: {
            "username": smsUsername,
            "password": smsPassword,
            "mobile": phone,
            "message":
                "Your MiCampusl verification code is: $otp. Valid for 5 minutes.",
            "senderid": "MICMPS", // Update with your DLT approved sender ID
          },
        );
      }

      Response response;
      try {
        response = await doPost(_dio);
      } on DioException catch (e) {
        // If the provider SSL chain is broken, Dart will throw HandshakeException.
        final isHandshake = e.error is HandshakeException ||
            e.type == DioExceptionType.badCertificate;

        if (isHandshake &&
            _allowBadCertificatesForSmsInDebug &&
            !kReleaseMode) {
          debugPrint(
            "🟠 SMS OTP TLS handshake failed; retrying with insecure TLS (debug only). "
            "Fix the SMS provider certificate chain for production.",
          );
          final insecureDio = _createDio(allowBadCertificates: true);
          response = await doPost(insecureDio);
        } else {
          rethrow;
        }
      }
      
      debugPrint("🟢 SMS Response: ${response.data}");
      
      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'otp': otp,
          'message': 'OTP sent successfully'
        };
      }
      return {
        'status': 'error',
        'message': 'Failed to send OTP'
      };
    } catch (e) {
      debugPrint("🔴 SMS OTP Error: $e");
      // Provide a clearer hint for the common TLS issue.
      if (e is HandshakeException || e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        return {
          'status': 'error',
          'message':
              'SSL handshake failed. The SMS provider certificate chain looks invalid/missing intermediate certs. '
              'Ask provider to fix SSL chain. (Debug builds may allow insecure retry if enabled).',
        };
      }
      return {
        'status': 'error',
        'message': 'Network error: ${e.toString()}'
      };
    }
  }
  
  // Send OTP via Email
  static Future<Map<String, dynamic>> sendEmailOtp(String email) async {
    try {
      final otp = _generateOtp();
      // Never log OTPs.
      debugPrint("🔵 Sending Email OTP to: $email");
      debugPrint("🔵 Email API URL: $emailApiUrl");
      
      final response = await _dio.post(
        emailApiUrl,
        data: {
          "email": email,
          "otp": otp,
          "sender_email": emailId,
          "sender_password": emailAppPassword,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => true, // Accept any status code
        ),
      );
      
      debugPrint("🟢 Email Response Status: ${response.statusCode}");
      debugPrint("🟢 Email Response Data: ${response.data}");
      
      // Check if response.data is null
      if (response.data == null) {
        debugPrint("🔴 Response data is null");
        return {
          'status': 'error',
          'message': 'No response from email server. Please check backend configuration.'
        };
      }
      
      // Check response status
      if (response.statusCode == 200 && response.data is Map) {
        if (response.data['status'] == 'success') {
          return {
            'status': 'success',
            'otp': otp,
            'message': 'OTP sent to your email'
          };
        } else {
          return {
            'status': 'error',
            'message': response.data['message'] ?? 'Failed to send OTP'
          };
        }
      }
      
      return {
        'status': 'error',
        'message': 'Invalid response from server'
      };
    } on DioException catch (e) {
      debugPrint("🔴 Email OTP DioException: ${e.message}");
      debugPrint("🔴 Response: ${e.response?.data}");
      debugPrint("🔴 Status Code: ${e.response?.statusCode}");
      
      return {
        'status': 'error',
        'message': 'Network error: ${e.message}'
      };
    } catch (e) {
      debugPrint("🔴 Email OTP Error: $e");
      return {
        'status': 'error',
        'message': 'Unexpected error: ${e.toString()}'
      };
    }
  }
  
  // Generate 6-digit OTP
  static String _generateOtp() {
    return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
  }
  
  // Verify OTP (compare stored OTP with user input)
  static bool verifyOtp(String enteredOtp, String sentOtp) {
    return enteredOtp == sentOtp;
  }
}