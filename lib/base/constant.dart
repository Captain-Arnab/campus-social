import 'package:flutter/material.dart';

class Constant {
  /// Public marketing / help site (opens in browser from the app).
  static const String websiteUrl = 'https://www.micampus.co.in/';

  // --- API Configuration ---
  static const String baseUrl = "https://www.micampus.co.in/admin/api/";

  /// When false, [ApiService.createEvent] sends `notify_admin_sms=0` so new/pending
  /// events should not trigger administrator SMS. The PHP API must honor this field.
  /// Set to true if the client wants admin SMS again.
  static const bool notifyAdminsBySmsOnEventSubmit = false;
  
  // Upload base URLs (for building certificate/banner URLs)
  static const String uploadsBaseUrl = "https://www.micampus.co.in/admin/uploads/";
  static const String certificatesPath = "certificates/";

  /// Absolute URL for a certificate [filePath] from the API.
  /// Supports full http(s) URLs, bare filenames, `certificates/...`, and
  /// `uploads/certificates/...` without duplicating path segments.
  static String certificateFileUrl(String filePath) {
    final trimmed = filePath.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    var p = trimmed.replaceAll('\\', '/');
    p = p.replaceFirst(RegExp(r'^/+'), '');
    // Paths from PHP often include "admin/" relative to site root; avoid doubling segments.
    while (p.toLowerCase().startsWith('admin/')) {
      p = p.substring('admin/'.length);
    }
    if (p.toLowerCase().startsWith('uploads/')) {
      p = p.substring('uploads/'.length);
    }
    if (p.toLowerCase().startsWith('certificates/')) {
      return '$uploadsBaseUrl$p';
    }
    return '$uploadsBaseUrl$certificatesPath$p';
  }

  /// Public URL for files stored under `uploads/` (ads, review files, app logo, etc.).
  /// [filePath] is typically like `uploads/review_files/x.pdf` from the API.
  static String uploadPublicUrl(String filePath) {
    final trimmed = filePath.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    var p = trimmed.replaceAll('\\', '/');
    p = p.replaceFirst(RegExp(r'^/+'), '');
    while (p.toLowerCase().startsWith('admin/')) {
      p = p.substring('admin/'.length);
    }
    if (p.toLowerCase().startsWith('uploads/')) {
      p = p.substring('uploads/'.length);
    }
    return '$uploadsBaseUrl$p';
  }

  // Endpoints
  static const String loginEndpoint = "users.php"; 
  static const String registerEndpoint = "users.php"; 
  static const String userUpdateEndpoint = "users.php"; 
  static const String eventsEndpoint = "events.php"; 
  static const String attendEndpoint = "attend.php";
  static const String forgotPasswordEndpoint = "forgot_password.php";
  static const String favoritesEndpoint = "favorites.php";
  static const String volunteersEndpoint = "volunteers.php";

  // --- Color Scheme ---
  static const Color primaryColor = Color(0xFFFF5F15);
  static const Color primaryLight = Color(0xFFFF9068);
  static const Color primaryDark = Color(0xFFE04E0B);
  static const Color accentColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);

  // Event Categories
  static const List<String> eventCategories = [
    "All",
    "IT/Tech",
    "Cultural",
    "Sports",
    "Academic",
    "Social"
  ];

  // FCM: Android notification channel (must match AndroidManifest + MainActivity).
  // Backend (send_organizer_notification.php) should send FCM with "notification" payload and
  // android_channel_id: "high_importance_channel" so notifications show when app is in background.
  static const String fcmAndroidChannelId = 'high_importance_channel';

  // Volunteer Roles
  static const List<String> volunteerRoles = [
    "Stage Manager",
    "Tech Support",
    "Crowd Management",
    "Registration",
    "Catering",
    "Decoration",
    "Photography",
    "Other"
  ];
}