import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../base/constant.dart';
import '../theme/app_theme.dart';
import '../widgets/app_network_image.dart';

/// Absolute URL for an uploads path. Bare filenames are profile pictures
/// (`uploads/profiles/<file>`), matching `organizer_avatar` / `winner_avatar`.
String? _resolveUploadUrl(dynamic value) {
  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty || raw == 'null' || raw == 'default_avatar.png') return null;
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    if (raw.contains('://micampus.co.in/') &&
        !raw.contains('://www.micampus.co.in/')) {
      return raw.replaceFirst('://micampus.co.in/', '://www.micampus.co.in/');
    }
    return raw;
  }
  var p = raw.replaceAll('\\', '/');
  while (p.startsWith('/')) {
    p = p.substring(1);
  }
  while (p.toLowerCase().startsWith('admin/')) {
    p = p.substring('admin/'.length);
  }
  if (p.toLowerCase().startsWith('uploads/')) {
    p = p.substring('uploads/'.length);
  }
  if (p.contains('/')) return '${Constant.uploadsBaseUrl}$p';
  return '${Constant.uploadsBaseUrl}profiles/$p';
}

/// Resolves a public profile image URL from common API field names.
String? winnerProfileImageUrl(dynamic winnerOrUser) {
  if (winnerOrUser is! Map) return null;
  for (final key in [
    'profile_pic',
    'image',
    'avatar',
    'photo',
    'photo_url',
    'winner_avatar',
    'profile_image',
    'user_image',
    'organizer_avatar',
  ]) {
    final url = _resolveUploadUrl(winnerOrUser[key]);
    if (url != null) return url;
  }
  return null;
}

/// Uploaded winner photo from `winner_photos.php` (null when `has_photo` is false).
String? winnerEventPhotoUrl(dynamic winner) {
  if (winner is! Map || winner['has_photo'] == false) return null;
  return _resolveUploadUrl(winner['photo_url']);
}

String winnerDisplayName(dynamic winner) {
  if (winner is! Map) return 'Winner';
  final name = (winner['winner_name'] ??
          winner['full_name'] ??
          winner['student_name'] ??
          winner['name'] ??
          '')
      .toString()
      .trim();
  return name.isEmpty ? 'Winner' : name;
}

/// `winner_department_class` (or `department_class`), null when missing/blank.
String? winnerDepartmentClass(dynamic winner) {
  if (winner is! Map) return null;
  final raw = winner['winner_department_class'] ?? winner['department_class'];
  if (raw == null) return null;
  final dept = raw.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  return dept.isEmpty || dept == 'null' ? null : dept;
}

/// `winner_is_student` (or `is_student`): 1 = student, 0 = faculty, null = unknown.
bool? winnerIsStudent(dynamic winner) {
  if (winner is! Map) return null;
  final raw = winner['winner_is_student'] ?? winner['is_student'];
  if (raw == null) return null;
  if (raw == 1 || raw == true || raw == '1') return true;
  if (raw == 0 || raw == false || raw == '0') return false;
  return null;
}

/// "Student · CSE 2nd Year" / "Faculty · Physics"; role alone when the
/// department is missing, '' when both are.
String winnerAffiliation(dynamic winner) {
  final dept = winnerDepartmentClass(winner);
  final isStudent = winnerIsStudent(winner);
  final role = isStudent == null ? null : (isStudent ? 'Student' : 'Faculty');
  return [if (role != null) role, if (dept != null) dept].join(' · ');
}

String winnerInitials(dynamic winner) {
  final parts = winnerDisplayName(winner)
      .replaceAll(RegExp(r'[^A-Za-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  final first = parts.first[0];
  final last = parts.length > 1 ? parts.last[0] : '';
  return (first + last).toUpperCase();
}

int winnerPosition(dynamic winner) {
  final raw = winner is Map ? winner['position'] : null;
  return raw is int ? raw : int.tryParse(raw?.toString() ?? '') ?? 0;
}

/// 1 → "1st", 2 → "2nd", 11 → "11th".
String winnerPositionLabel(int position) {
  if (position <= 0) return '';
  final mod100 = position % 100;
  if (mod100 >= 11 && mod100 <= 13) return '${position}th';
  switch (position % 10) {
    case 1:
      return '${position}st';
    case 2:
      return '${position}nd';
    case 3:
      return '${position}rd';
    default:
      return '${position}th';
  }
}

Color winnerMedalColor(int position) {
  switch (position) {
    case 1:
      return AppColors.gold;
    case 2:
      return const Color(0xFF9AA4B2);
    case 3:
      return const Color(0xFFC08457);
    default:
      return AppColors.navyMuted;
  }
}

/// Circular avatar: profile photo when available, else initials.
class WinnerAvatar extends StatelessWidget {
  final dynamic winner;
  final int position;
  final double size;

  const WinnerAvatar({
    super.key,
    required this.winner,
    this.position = 0,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final url = winnerProfileImageUrl(winner);
    final dim = size.w;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: AppNetworkImage(
          url: url,
          width: dim,
          height: dim,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fallback(dim),
        ),
      );
    }
    return _fallback(dim);
  }

  Widget _fallback(double dim) {
    final medal = position >= 1 && position <= 3;
    final tone = medal ? winnerMedalColor(position) : AppColors.border;
    return Container(
      width: dim,
      height: dim,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: medal ? tone.withValues(alpha: 0.15) : AppColors.surfaceMuted,
        border: Border.all(color: tone, width: 1.5),
      ),
      child: Text(
        winnerInitials(winner),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: (size * 0.36).sp,
          color: AppColors.accent,
        ),
      ),
    );
  }
}
