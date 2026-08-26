import 'package:dio/dio.dart';

/// Maps Dio / API network failures to short, user-facing copy (no raw exception dumps).
class NetworkErrorHelper {
  NetworkErrorHelper._();

  static const String timeoutMessage =
      'The server is responding slowly. Please check your connection and try again.';
  static const String offlineMessage =
      'Could not reach the server. Please check your internet connection and try again.';
  static const String genericMessage =
      'Something went wrong. Please try again.';

  static bool isTimeout(Object? error, {String? apiMessage}) {
    if (error is DioException) {
      return _isTimeoutType(error.type);
    }
    return _looksLikeTimeout(apiMessage) || _looksLikeTimeout(error?.toString());
  }

  static bool isRetryable(Object? error, {String? apiMessage}) {
    if (error is DioException) {
      return _isTimeoutType(error.type) ||
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.unknown;
    }
    final text = '${apiMessage ?? ''} ${error?.toString() ?? ''}'.toLowerCase();
    return _looksLikeTimeout(text) ||
        text.contains('network error') ||
        text.contains('connection') ||
        text.contains('socket') ||
        text.contains('failed host lookup');
  }

  static String userMessage(Object? error, {String? apiMessage}) {
    if (apiMessage != null && apiMessage.isNotEmpty) {
      if (_looksLikeTimeout(apiMessage)) return timeoutMessage;
      if (apiMessage.toLowerCase().startsWith('network error:')) {
        return _messageFromNetworkPrefix(apiMessage);
      }
    }

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return timeoutMessage;
        case DioExceptionType.connectionError:
          return offlineMessage;
        case DioExceptionType.badCertificate:
          return 'Secure connection failed. Please try again later.';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        default:
          break;
      }
    }

    if (_looksLikeTimeout(error?.toString())) return timeoutMessage;
    if (error != null || (apiMessage != null && apiMessage.isNotEmpty)) {
      return genericMessage;
    }
    return genericMessage;
  }

  /// User-facing message for synthetic API error payloads from [ApiService].
  static String apiErrorMessage(Object? error, {String? apiMessage}) {
    return userMessage(error, apiMessage: apiMessage);
  }

  static bool _isTimeoutType(DioExceptionType type) {
    return type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout;
  }

  static bool _looksLikeTimeout(Object? text) {
    if (text == null) return false;
    final lower = text.toString().toLowerCase();
    return lower.contains('timeout') || lower.contains('took longer than');
  }

  static String _messageFromNetworkPrefix(String apiMessage) {
    final lower = apiMessage.toLowerCase();
    if (_looksLikeTimeout(lower)) return timeoutMessage;
    if (lower.contains('connection') || lower.contains('socket')) {
      return offlineMessage;
    }
    return genericMessage;
  }
}
