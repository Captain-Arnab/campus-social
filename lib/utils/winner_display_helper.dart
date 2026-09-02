import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../base/constant.dart';
import '../theme/app_theme.dart';
import '../widgets/app_network_image.dart';

/// Resolves a public profile image URL from common API field names.
String? winnerProfileImageUrl(dynamic winnerOrUser) {
  if (winnerOrUser is! Map) return null;
  for (final key in [
    'profile_pic',
    'image',
    'avatar',
    'photo',
    'photo_url',
    'profile_image',
    'user_image',
    'organizer_avatar',
  ]) {
    final raw = (winnerOrUser[key] ?? '').toString().trim();
    if (raw.isEmpty || raw == 'null' || raw == 'default_avatar.png') continue;
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
    if (p.toLowerCase().startsWith('profiles/')) {
      return '${Constant.uploadsBaseUrl}$p';
    }
    return '${Constant.uploadsBaseUrl}profiles/$p';
  }
  return null;
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

/// Circular avatar: profile photo when available, else rank badge / initials fallback.
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
    final gold = position == 1;
    return Container(
      width: dim,
      height: dim,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gold ? AppColors.gold : AppColors.surfaceMuted,
        border: Border.all(
          color: gold ? AppColors.gold : AppColors.border,
          width: 1.5,
        ),
      ),
      child: position > 0
          ? Text(
              '$position',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: (size * 0.38).sp,
                color: gold ? Colors.white : AppColors.navy,
              ),
            )
          : Icon(Icons.person, size: (size * 0.45).sp, color: AppColors.textSecondary),
    );
  }
}
