import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../base/constant.dart';
import '../data/pref_service.dart';
import 'sweetalert_helper.dart';

/// Confirmed backend field for forced-download streaming URL
/// (`download_certificate.php?id=...`). Prefer this for the app download action
/// over [certificate_url] / [url] (direct file URLs).
const String kCertificateDownloadUrlField = 'download_url';

/// Certificate readiness from [certificates.php] (`pending` / `ready`).
/// Check this — not empty URL fields — when status is pending (URLs are `""`).
String certificateStatusFromRecord(dynamic item) {
  if (item is! Map) return '';
  return (item['status'] ?? '').toString().trim().toLowerCase();
}

/// True when the certificate is not ready for view/download.
bool certificateIsPending(dynamic item) =>
    certificateStatusFromRecord(item) == 'pending';

/// Resolves the best public URL for a certificate row from [certificates.php].
/// Prefers [kCertificateDownloadUrlField] (`download_url`). Skips empty strings.
/// Callers must gate on [certificateIsPending] / status before downloading.
String certificateUrlFromRecord(dynamic item) {
  if (item is! Map) return '';
  if (certificateIsPending(item)) return '';
  for (final key in [
    kCertificateDownloadUrlField,
    'certificate_url',
    'url',
    'file_path',
    'certificate_path',
    'certificate_file',
    'filepath',
    'cert_path',
    'file',
    'filename',
    'path',
  ]) {
    final raw = item[key];
    if (raw == null) continue;
    final v = raw.toString().trim();
    if (v.isEmpty || v == 'null') continue;
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    final built = Constant.certificateFileUrl(v);
    if (built.isNotEmpty) return built;
  }
  return '';
}

/// Supported certificate file kinds (PDF or common images).
enum _CertFormat {
  pdf,
  png,
  jpeg,
}

extension _CertFormatExt on _CertFormat {
  String get defaultExtension {
    switch (this) {
      case _CertFormat.pdf:
        return 'pdf';
      case _CertFormat.png:
        return 'png';
      case _CertFormat.jpeg:
        return 'jpg';
    }
  }

  String get mimeType {
    switch (this) {
      case _CertFormat.pdf:
        return 'application/pdf';
      case _CertFormat.png:
        return 'image/png';
      case _CertFormat.jpeg:
        return 'image/jpeg';
    }
  }
}

bool _looksLikePdf(List<int> bytes) {
  if (bytes.length < 5) return false;
  return bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46 &&
      bytes[4] == 0x2D;
}

bool _looksLikePng(List<int> bytes) {
  if (bytes.length < 8) return false;
  return bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A;
}

bool _looksLikeJpeg(List<int> bytes) {
  if (bytes.length < 3) return false;
  return bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
}

_CertFormat? _formatFromContentType(String ct) {
  if (ct.contains('application/pdf')) return _CertFormat.pdf;
  if (ct.contains('image/png')) return _CertFormat.png;
  if (ct.contains('image/jpeg') ||
      ct.contains('image/jpg') ||
      ct.contains('image/pjpeg')) {
    return _CertFormat.jpeg;
  }
  // application/octet-stream: infer from magic bytes / URL below.
  return null;
}

/// Dio instance for certificate URLs (full URL, not [Constant.baseUrl]).
final Dio _certificateDio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 25),
    receiveTimeout: const Duration(seconds: 120),
    sendTimeout: const Duration(seconds: 25),
    followRedirects: true,
    maxRedirects: 5,
    validateStatus: (code) => code != null && code < 500,
  ),
);

_CertFormat? _formatFromMagic(List<int> bytes) {
  if (_looksLikePdf(bytes)) return _CertFormat.pdf;
  if (_looksLikePng(bytes)) return _CertFormat.png;
  if (_looksLikeJpeg(bytes)) return _CertFormat.jpeg;
  return null;
}

_CertFormat? _formatFromUrl(String url) {
  final path = url.split('?').first.toLowerCase();
  if (path.endsWith('.pdf')) return _CertFormat.pdf;
  if (path.endsWith('.png')) return _CertFormat.png;
  if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return _CertFormat.jpeg;
  return null;
}

/// Avoid treating HTML/JSON error pages as certificates when URL has a file extension.
bool _probablyNotHtmlErrorPage(List<int> bytes) {
  if (bytes.isEmpty) return false;
  final first = bytes[0];
  if (first == 0x3C || first == 0x7B || first == 0x5B) return false;
  try {
    final n = bytes.length > 120 ? 120 : bytes.length;
    final head = utf8.decode(bytes.sublist(0, n), allowMalformed: true).trimLeft();
    final lower = head.toLowerCase();
    if (lower.startsWith('<!doctype') || lower.startsWith('<html')) return false;
  } catch (_) {}
  return true;
}

String _nonBinaryHint(List<int> bytes) {
  try {
    final head = bytes.length > 400 ? bytes.sublist(0, 400) : bytes;
    final s = utf8.decode(head, allowMalformed: true).trim();
    if (s.isEmpty) return 'Empty response.';
    final line = s.split('\n').first.trim();
    if (line.length > 160) return '${line.substring(0, 160)}…';
    return line;
  } catch (_) {
    return 'Unrecognized file format.';
  }
}

String _safeCertificateFileName(String url, String? hint, _CertFormat format) {
  try {
    final uri = Uri.parse(url);
    if (uri.pathSegments.isNotEmpty) {
      var last = uri.pathSegments.last;
      if (last.isNotEmpty) {
        final lower = last.toLowerCase();
        if (RegExp(r'\.(pdf|png|jpe?g)$').hasMatch(lower)) {
          return last.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_');
        }
      }
    }
  } catch (_) {}
  final base = (hint ?? 'certificate').replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_');
  return '$base.${format.defaultExtension}';
}

class _FetchedCertificate {
  _FetchedCertificate({
    required this.bytes,
    required this.format,
    required this.fileName,
  });

  final List<int> bytes;
  final _CertFormat format;
  final String fileName;
}

/// Fetches certificate bytes (PDF or PNG/JPEG). Sends Bearer token when logged in.
Future<_FetchedCertificate?> _fetchCertificate(String url, String? title) async {
  final uri = Uri.tryParse(url);
  if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
    debugPrint('Certificate fetch: bad URL');
    return null;
  }
  final headers = <String, String>{
    'Accept': 'application/pdf,image/png,image/jpeg,image/jpg,*/*;q=0.8',
    'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (compatible; MiCampus/1.0)',
  };
  try {
    final token = await PrefService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
  } catch (_) {}

  try {
    final res = await _certificateDio.getUri<List<int>>(
      uri,
      options: Options(
        headers: headers,
        responseType: ResponseType.bytes,
      ),
    );
    final status = res.statusCode ?? 0;
    if (status < 200 || status >= 400) {
      final raw = res.data;
      List<int> body = const [];
      if (raw is List<int>) body = raw;
      if (raw is Uint8List) body = raw;
      final hint = body.isEmpty
          ? '(empty body)'
          : utf8.decode(
              body.length > 200 ? body.sublist(0, 200) : body,
              allowMalformed: true,
            );
      debugPrint('Certificate fetch: HTTP $status for $url — $hint');
      return null;
    }
    final raw = res.data;
    List<int> body;
    if (raw is Uint8List) {
      body = raw;
    } else if (raw is List<int>) {
      body = raw;
    } else {
      debugPrint('Certificate fetch: unexpected response body type');
      return null;
    }
    if (body.isEmpty) {
      debugPrint('Certificate fetch: empty body');
      return null;
    }
    final ct = (res.headers.value('content-type') ?? '').toLowerCase();

    _CertFormat? format = _formatFromContentType(ct);
    format ??= _formatFromMagic(body);
    if (format == null && _probablyNotHtmlErrorPage(body)) {
      format = _formatFromUrl(url);
    }

    if (format == null) {
      debugPrint('Certificate fetch: unknown format — ${_nonBinaryHint(body)}');
      return null;
    }

    final fileName = _safeCertificateFileName(url, title, format);
    return _FetchedCertificate(bytes: body, format: format, fileName: fileName);
  } catch (e, st) {
    debugPrint('Certificate fetch error: $e');
    debugPrint('$st');
    return null;
  }
}

/// Closes the loading dialog. [popDialog] must be set in [showDialog]'s builder
/// (sync) so we can pop after awaits without relying on root [Navigator.canPop],
/// which is often false under [GetMaterialApp] while a dialog is open.
void _dismissCertificateLoader(VoidCallback? popDialog) {
  try {
    popDialog?.call();
  } catch (e) {
    debugPrint('Certificate loader pop: $e');
  }
  try {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  } catch (e) {
    debugPrint('Certificate loader Get.back: $e');
  }
}

/// Bottom sheet: View or Download (PDF, PNG, JPEG).
Future<void> showCertificateViewDownloadSheet(
  BuildContext context, {
  required String url,
  String? title,
}) async {
  if (url.isEmpty) {
    SweetAlertHelper.showError(context, 'Certificate', 'No file URL available.');
    return;
  }
  final parentContext = context;
  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility, color: Color(0xFFFF5F15)),
              title: const Text('View'),
              subtitle: const Text('Open PDF or image in another app'),
              onTap: () {
                Navigator.pop(sheetContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  openCertificateForView(parentContext, url, title: title);
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Color(0xFFFF5F15)),
              title: const Text('Download'),
              subtitle: Text(
                Platform.isAndroid
                    ? 'Save to app Documents (MiCampus/Certificates)'
                    : 'Save to MiCampus/Certificates',
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  downloadCertificateToDevice(parentContext, url, title: title);
                });
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> openCertificateForView(
  BuildContext context,
  String url, {
  String? title,
}) async {
  if (!context.mounted) return;
  VoidCallback? popLoader;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogCtx) {
      popLoader = () {
        if (dialogCtx.mounted) {
          Navigator.of(dialogCtx).pop();
        }
      };
      return const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: Color(0xFFFF5F15)),
          ),
        ),
      );
    },
  );
  try {
    final fetched = await _fetchCertificate(url, title);
    if (fetched == null || fetched.bytes.isEmpty) {
      if (context.mounted) {
        SweetAlertHelper.showError(
          context,
          'Certificate',
          'Could not load the file. Check your connection or try opening in browser.',
        );
      }
      return;
    }
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/micampus_view_${fetched.fileName}');
    await file.writeAsBytes(fetched.bytes, flush: true);

    final result = await OpenFilex.open(
      file.path,
      type: fetched.format.mimeType,
    );
    if (result.type != ResultType.done) {
      debugPrint('OpenFilex: ${result.type} ${result.message}');
      final uri = Uri.tryParse(url);
      if (uri != null) {
        try {
          final ok = await canLaunchUrl(uri);
          if (ok || uri.isScheme('https') || uri.isScheme('http')) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return;
          }
        } catch (e) {
          debugPrint('launchUrl fallback: $e');
        }
      }
      if (context.mounted) {
        final msg = result.message.isNotEmpty
            ? result.message
            : 'No app found to open this file. Try Download or open the link in a browser.';
        SweetAlertHelper.showError(context, 'Certificate', msg);
      }
    }
  } catch (e) {
    debugPrint('openCertificateForView: $e');
    if (context.mounted) {
      SweetAlertHelper.showError(
        context,
        'Certificate',
        'Could not open the file: $e',
      );
    }
    try {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  } finally {
    _dismissCertificateLoader(popLoader);
  }
}

Future<void> downloadCertificateToDevice(
  BuildContext context,
  String url, {
  String? title,
}) async {
  if (!context.mounted) return;
  VoidCallback? popLoader;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogCtx) {
      popLoader = () {
        if (dialogCtx.mounted) {
          Navigator.of(dialogCtx).pop();
        }
      };
      return const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: Color(0xFFFF5F15)),
          ),
        ),
      );
    },
  );
  try {
    final fetched = await _fetchCertificate(url, title);
    if (fetched == null || fetched.bytes.isEmpty) {
      if (context.mounted) {
        SweetAlertHelper.showError(
          context,
          'Certificate',
          'Could not download the file. Check your connection.',
        );
      }
      return;
    }
    // Android: public Downloads from path_provider is often not writable (scoped storage);
    // app documents always works. Desktop/iOS: prefer Downloads when available.
    Directory baseDir = await getApplicationDocumentsDirectory();
    if (!Platform.isAndroid) {
      try {
        final downloads = await getDownloadsDirectory().timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );
        if (downloads != null) {
          baseDir = downloads;
        }
      } catch (_) {}
    }
    final folder = Directory('${baseDir.path}/MiCampus/Certificates');
    await folder.create(recursive: true);
    final out = File('${folder.path}/${fetched.fileName}');
    await out.writeAsBytes(fetched.bytes, flush: true);
    if (context.mounted) {
      SweetAlertHelper.showSuccess(
        context,
        'Downloaded',
        'Saved to:\n${out.path}',
      );
    }
  } catch (e) {
    debugPrint('downloadCertificateToDevice: $e');
    if (context.mounted) {
      SweetAlertHelper.showError(
        context,
        'Certificate',
        'Download failed: $e',
      );
    }
  } finally {
    _dismissCertificateLoader(popLoader);
  }
}
