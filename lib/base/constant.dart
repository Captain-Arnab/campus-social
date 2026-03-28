import 'package:flutter/material.dart';

class Constant {
  // --- API Configuration ---
  static const String baseUrl = "https://micampus.co.in/admin/api/";
  
  // Upload base URLs (for building certificate/banner URLs)
  static const String uploadsBaseUrl = "https://micampus.co.in/admin/uploads/";
  static const String certificatesPath = "certificates/";

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
  // Backend (send_event_notification.php) should send FCM with "notification" payload and
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