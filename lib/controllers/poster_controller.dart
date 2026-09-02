import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:saver_gallery/saver_gallery.dart';
import '../utils/sweetalert_helper.dart';
import '../utils/poster_export_helper.dart';
import '../utils/upload_file_validators.dart';
import '../widgets/app_calendar_theme.dart';

class PosterController extends GetxController {
  // --- OBSERVABLE VARIABLES ---
  var title = "My Awesome Event".obs;
  var venue = "Campus Venue, Main Hall".obs;
  var dateStr = "DATE".obs;
  var timeStr = "TIME".obs;
  /// Shared start / end clock for all poster templates (paired with poster start/end dates).
  var slotStart = "9:00 AM".obs;
  var slotEnd = "5:00 PM".obs;
  var description = "Join us for an amazing event!".obs;
  
  // Tech template specific fields
  var mode = "Online".obs; // Online or Offline
  var trainerName = "".obs;
  /// Right-column tagline on Innovation & Technology poster (max length = [kDefaultTechTagline]).
  static const String kDefaultTechTagline = "Let's talk about the future";
  static int get kTechTaglineMaxLength => kDefaultTechTagline.length;
  var techTagline = kDefaultTechTagline.obs;

  // Spoken English template specific fields
  var titleEnglish = "ONLINE COURSE".obs;
  var subtitle = "Spoken English".obs;
  /// Event / course run dates on all poster templates (end optional).
  var posterStartDate = Rx<DateTime?>(null);
  var posterEndDate = Rx<DateTime?>(null);
  var phoneNumber = "800 829 5550 / 51".obs;
  var coursePoints = <String>[].obs;

  // Basketball specific fields (extended venue pair)
  var stadiumName = "Brocelle Stadium".obs;
  var address = "123 Anywhere St, Any City".obs;

  // Images
  Rx<File?> selectedImage = Rx<File?>(null);
  Rx<File?> logoImage = Rx<File?>(null);
  Rx<File?> trainerImage = Rx<File?>(null);
  Rx<File?> qrCodeImage = Rx<File?>(null);

  // FLAGS
  var isPickingImage = false.obs;
  var isPickingLogo = false.obs;
  var isPickingTrainer = false.obs;
  var isPickingQrCode = false.obs;

  void _initPosterDates() {
    final n = DateTime.now();
    posterStartDate.value = DateTime(n.year, n.month, n.day);
    posterEndDate.value = null;
  }

  // --- INITIALIZE SAMPLE DATA FOR GRADUATION THEME ---
  void initializeGraduationData() {
    title.value = "Graduation Party";
    description.value = "Class of 2025";
    dateStr.value = "DATE";
    timeStr.value = "TIME";
    slotStart.value = "9:00 AM";
    slotEnd.value = "5:00 PM";
    venue.value = "Campus Venue, Main Hall";
    _initPosterDates();
  }

  // --- LOAD SAMPLE IMAGES FOR GRADUATION THEME ---
  Future<void> loadGraduationSampleImages() async {
    try {
      // Logo left blank by default (user uploads their own).
      final bgImage = await assetToFile('assets/images/graduation/element2.png');
      
      if (bgImage != null) selectedImage.value = bgImage;
      
      debugPrint("Graduation sample images loaded successfully");
    } catch (e) {
      debugPrint("Error loading graduation sample images: $e");
    }
  }

  // --- INITIALIZE SAMPLE DATA FOR TECH THEME ---
  void initializeTechData() {
    title.value = "Innovation & Technology";
    description.value = "Join us for an innovation session";
    techTagline.value = kDefaultTechTagline;
    trainerName.value = "Ram Sett";
    mode.value = "Online";
    dateStr.value = "DATE";
    timeStr.value = "TIME";
    slotStart.value = "9:00 AM";
    slotEnd.value = "5:00 PM";
    venue.value = "Campus Venue, Main Hall";
    _initPosterDates();
  }

  // --- LOAD SAMPLE IMAGES FOR TECH THEME ---
  Future<void> loadTechSampleImages() async {
    try {
      // Logo left blank by default (user uploads their own).
      final robotImage = await assetToFile('assets/images/innovation/robot.png');
      final trainerPhoto = await assetToFile('assets/images/online_course/element.png');
      
      if (robotImage != null) selectedImage.value = robotImage;
      if (trainerPhoto != null) trainerImage.value = trainerPhoto;
      
      debugPrint("Tech sample images loaded successfully");
    } catch (e) {
      debugPrint("Error loading tech sample images: $e");
    }
  }

  // --- INITIALIZE SAMPLE DATA FOR SPOKEN ENGLISH THEME ---
  void initializeSampleEnglishData() {
    // Set sample course points
    coursePoints.value = [
      "Listening Course",
      "Writing Course", 
      "Pronunciation",
      "Speaking Course",
    ];
    
    // Layout banner title stays ONLINE COURSE; gallery name is Spoken English.
    titleEnglish.value = "ONLINE COURSE";
    subtitle.value = "Spoken English";
    venue.value = "Campus Venue, Main Hall";
    _initPosterDates();
    slotStart.value = "08 AM";
    slotEnd.value = "2 PM";
    phoneNumber.value = "800 829 5550 / 51";
  }

  // --- LOAD SAMPLE IMAGES FOR ENGLISH THEME ---
  Future<void> loadEnglishSampleImages() async {
    try {
      final logo = await assetToFile('assets/images/guru_nanak_logo.png');
      final studentImg = await assetToFile('assets/images/online_course/element.png');
      
      if (logo != null) logoImage.value = logo;
      if (studentImg != null) selectedImage.value = studentImg;
      
      debugPrint("English sample images loaded successfully");
    } catch (e) {
      debugPrint("Error loading english sample images: $e");
    }
  }

  // --- INITIALIZE SAMPLE DATA FOR MUSIC FESTIVAL THEME ---
  void initializeMusicFestivalData() {
    title.value = "Music Festival";
    // Caps match poster editor (music description max 30 chars).
    description.value = "Live music, food & friends!";
    venue.value = "Handover and Tyke Stadium";
    slotStart.value = "10 AM";
    slotEnd.value = "10 PM";
    dateStr.value = "DATE";
    _initPosterDates();
  }

  // --- LOAD SAMPLE IMAGES FOR MUSIC FESTIVAL THEME ---
  Future<void> loadMusicFestivalSampleImages() async {
    try {
      final logo = await assetToFile('assets/images/guru_nanak_logo.png');
      final celebrationImg = await assetToFile('assets/images/music/music.png');
      
      if (logo != null) logoImage.value = logo;
      if (celebrationImg != null) selectedImage.value = celebrationImg;
      
      debugPrint("Music Festival sample images loaded successfully");
    } catch (e) {
      debugPrint("Error loading music festival sample images: $e");
    }
  }

  // --- INITIALIZE SAMPLE DATA FOR BASKETBALL THEME ---
  void initializeBasketballData() {
    title.value = "Basketball Tournament";
    description.value = "Join us for an exciting match";
    stadiumName.value = "Brocelle Stadium";
    // Max 26 chars for address line on basketball poster.
    address.value = "123 Anywhere St, Any City";
    dateStr.value = "DATE";
    slotStart.value = "2 PM";
    slotEnd.value = "5 PM";
    _initPosterDates();
  }

  // --- LOAD SAMPLE IMAGES FOR BASKETBALL THEME ---
  Future<void> loadBasketballSampleImages() async {
    try {
      final logo = await assetToFile('assets/images/guru_nanak_logo.png');
      final courtActionImg = await assetToFile('assets/images/basketball/basketball.png');
      
      if (logo != null) logoImage.value = logo;
      if (courtActionImg != null) selectedImage.value = courtActionImg;
      
      debugPrint("Basketball sample images loaded successfully");
    } catch (e) {
      debugPrint("Error loading basketball sample images: $e");
    }
  }

  // --- HELPER METHOD TO CONVERT ASSET TO FILE ---
  Future<File?> assetToFile(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final fileName = assetPath.split('/').last;
      final file = File('${(await getTemporaryDirectory()).path}/$fileName');
      await file.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes, 
          byteData.lengthInBytes
        )
      );
      return file;
    } catch (e) {
      debugPrint("Error converting asset to file: $e");
      return null;
    }
  }

  // --- COURSE POINTS MANAGEMENT ---
  void addCoursePoint(String point) {
    if (point.trim().isNotEmpty) {
      coursePoints.add(point.trim());
    }
  }

  void removeCoursePoint(int index) {
    if (index >= 0 && index < coursePoints.length) {
      coursePoints.removeAt(index);
    }
  }

  void clearCoursePoints() {
    coursePoints.clear();
  }

  /// Poster date line: single start date, or `from — to` when end is set.
  String posterDateRangeLine() {
    final s = posterStartDate.value;
    if (s == null) return "Select start date";
    final fmt = DateFormat('dd MMM yyyy');
    final from = fmt.format(s);
    final e = posterEndDate.value;
    if (e == null) return from;
    final endDay = DateTime(e.year, e.month, e.day);
    final startDay = DateTime(s.year, s.month, s.day);
    if (endDay.isBefore(startDay)) return from;
    if (startDay == endDay) return from;
    return "$from — ${fmt.format(e)}";
  }

  /// `start — end` clock labels for graduation / tech footers.
  String posterHostTimeRangeLabel() {
    final a = slotStart.value.trim();
    final b = slotEnd.value.trim();
    if (a.isEmpty && b.isEmpty) return "TIME";
    if (b.isEmpty || a == b) return a.isEmpty ? b : a;
    return "$a — $b";
  }

  /// Date line + explicit **From:** / **To:** times for graduation & tech posters (uppercase for card).
  String posterHostDateTimeBlockUppercase() {
    final dateLine = posterDateRangeLine();
    final a = slotStart.value.trim();
    final b = slotEnd.value.trim();
    final fromT = a.isEmpty ? '—' : a;
    final toT = b.isEmpty ? '—' : b;
    return '${dateLine.toUpperCase()}\nFROM: ${fromT.toUpperCase()}\nTO: ${toT.toUpperCase()}';
  }

  /// One readable line: first day + start time through last day + end time when the run spans multiple days.
  String posterFullWhenCaption(String startTimeLabel, String endTimeLabel) {
    final s = posterStartDate.value;
    if (s == null) return "Select start date";
    final fmt = DateFormat('dd MMM yyyy');
    final from = fmt.format(s);
    final st = startTimeLabel.trim();
    final et = endTimeLabel.trim();
    final e = posterEndDate.value;
    if (e == null) {
      if (st.isEmpty && et.isEmpty) return from;
      if (et.isEmpty || st == et) return "$from · $st";
      return "$from · $st — $et";
    }
    final s0 = DateTime(s.year, s.month, s.day);
    final e0 = DateTime(e.year, e.month, e.day);
    if (e0.isBefore(s0)) {
      if (st.isEmpty && et.isEmpty) return from;
      if (et.isEmpty || st == et) return "$from · $st";
      return "$from · $st — $et";
    }
    if (s0 == e0) {
      if (st.isEmpty && et.isEmpty) return from;
      if (et.isEmpty || st == et) return "$from · $st";
      return "$from · $st — $et";
    }
    if (st.isEmpty && et.isEmpty) return "$from — ${fmt.format(e)}";
    if (st.isEmpty) return "$from — ${fmt.format(e)} · $et";
    if (et.isEmpty) return "$from · $st — ${fmt.format(e)}";
    return "$from · $st — ${fmt.format(e)} · $et";
  }

  bool get posterSpansMultipleCalendarDays {
    final s = posterStartDate.value;
    final e = posterEndDate.value;
    if (s == null || e == null) return false;
    return DateTime(s.year, s.month, s.day) != DateTime(e.year, e.month, e.day);
  }

  /// Shared slot start picker. [compactHour] formats as `"2 PM"` (basketball-style).
  Future<void> pickSlotStart(BuildContext context, {bool compactHour = false}) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseLooseTime(slotStart.value) ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFFF5F15))),
        child: child!,
      ),
    );
    if (picked != null && context.mounted) {
      slotStart.value = compactHour ? _formatCompactHour(picked) : picked.format(context);
      timeStr.value = posterHostTimeRangeLabel();
    }
  }

  /// Shared slot end picker. [compactHour] formats as `"5 PM"` (basketball-style).
  Future<void> pickSlotEnd(BuildContext context, {bool compactHour = false}) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseLooseTime(slotEnd.value) ?? const TimeOfDay(hour: 17, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFFF5F15))),
        child: child!,
      ),
    );
    if (picked != null && context.mounted) {
      slotEnd.value = compactHour ? _formatCompactHour(picked) : picked.format(context);
      timeStr.value = posterHostTimeRangeLabel();
    }
  }

  String _formatCompactHour(TimeOfDay picked) {
    final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
    final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour $period';
  }

  /// Used by poster editor validation (same rules as event ISO prefill).
  TimeOfDay? tryParsePosterTimeLabel(String raw) => _parseLooseTime(raw);

  TimeOfDay? _parseLooseTime(String raw) {
    final cleaned = raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
    final match = RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)?$').firstMatch(cleaned);
    if (match == null) return null;
    var hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    final period = match.group(3);
    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
      return TimeOfDay(hour: hour, minute: minute);
    }
    return null;
  }

  /// Start datetime for event form prefill from poster start date + time string.
  String? posterEventStartDateTimeIso(String startTimeRaw) {
    final d = posterStartDate.value;
    if (d == null) return null;
    final t = _parseLooseTime(startTimeRaw) ?? const TimeOfDay(hour: 9, minute: 0);
    final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
  }

  /// Optional end datetime from poster end date + time string.
  String? posterEventEndDateTimeIso(String endTimeRaw) {
    final d = posterEndDate.value;
    if (d == null) return null;
    final t = _parseLooseTime(endTimeRaw) ?? const TimeOfDay(hour: 17, minute: 0);
    final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> pickPosterStartDate(BuildContext context) async {
    final today = _dateOnly(DateTime.now());
    final cur = posterStartDate.value;
    final initial = cur == null
        ? today
        : (_dateOnly(cur).isBefore(today) ? today : _dateOnly(cur));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: DateTime(2100),
      builder: (ctx, child) => AppCalendarTheme.wrap(ctx, child),
    );
    if (picked == null) return;
    posterStartDate.value = DateTime(picked.year, picked.month, picked.day);
    final end = posterEndDate.value;
    if (end != null) {
      final pDay = DateTime(picked.year, picked.month, picked.day);
      final eDay = DateTime(end.year, end.month, end.day);
      if (eDay.isBefore(pDay)) {
        posterEndDate.value = null;
      }
    }
  }

  Future<void> pickPosterEndDate(BuildContext context) async {
    final start = posterStartDate.value;
    if (start == null) {
      SweetAlertHelper.showError(context, "Start date", "Please choose a start date first.");
      return;
    }
    final firstAllowed = DateTime(start.year, start.month, start.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: () {
        final cur = posterEndDate.value;
        if (cur == null) return firstAllowed;
        final c = DateTime(cur.year, cur.month, cur.day);
        return c.isBefore(firstAllowed) ? firstAllowed : c;
      }(),
      firstDate: firstAllowed,
      lastDate: DateTime(2100),
      builder: (ctx, child) => AppCalendarTheme.wrap(ctx, child),
    );
    if (picked == null) return;
    posterEndDate.value = DateTime(picked.year, picked.month, picked.day);
  }

  void clearPosterEndDate() {
    posterEndDate.value = null;
  }

  // --- IMAGE PICKERS ---
  Future<void> pickImage() async {
    if (isPickingImage.value) return;
    try {
      isPickingImage.value = true;
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) selectedImage.value = File(image.path);
    } catch (e) {
      debugPrint("Image Picker Error: $e");
    } finally {
      isPickingImage.value = false;
    }
  }

  Future<void> pickLogo() async {
    if (isPickingLogo.value) return;
    try {
      isPickingLogo.value = true;
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) logoImage.value = File(image.path);
    } catch (e) {
      debugPrint("Logo Picker Error: $e");
    } finally {
      isPickingLogo.value = false;
    }
  }

  Future<void> pickTrainerImage() async {
    if (isPickingTrainer.value) return;
    try {
      isPickingTrainer.value = true;
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) trainerImage.value = File(image.path);
    } catch (e) {
      debugPrint("Trainer Image Picker Error: $e");
    } finally {
      isPickingTrainer.value = false;
    }
  }

  Future<void> pickQrCode() async {
    if (isPickingQrCode.value) return;
    try {
      isPickingQrCode.value = true;
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) qrCodeImage.value = File(image.path);
    } catch (e) {
      debugPrint("QR Code Picker Error: $e");
    } finally {
      isPickingQrCode.value = false;
    }
  }

  void clearImage() => selectedImage.value = null;
  void clearLogo() => logoImage.value = null;
  void clearTrainerImage() => trainerImage.value = null;
  void clearQrCode() => qrCodeImage.value = null;

  // --- DATE PICKER ---
  Future<void> pickDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (ctx, child) => AppCalendarTheme.wrap(ctx, child),
    );
    
    if (picked != null) {
      String day = picked.day.toString();
      String suffix = "TH";
      if (day.endsWith("1") && day != "11") {
        suffix = "ST";
      } else if (day.endsWith("2") && day != "12") {
        suffix = "ND";
      } else if (day.endsWith("3") && day != "13") {
        suffix = "RD";
      }
      dateStr.value = "$day$suffix ${DateFormat('MMM yyyy').format(picked).toUpperCase()}";
    }
  }

  // --- BASKETBALL DATE PICKER (DD/MM/YYYY format) ---
  Future<void> pickBasketballDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (ctx, child) => AppCalendarTheme.wrap(ctx, child),
    );
    
    if (picked != null) {
      dateStr.value = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  // --- TIME PICKER ---
  Future<void> pickTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context, 
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFFF5F15))),
        child: child!,
      ),
    );
    if (picked != null && context.mounted) {
      timeStr.value = picked.format(context);
    }
  }

  // --- SAVE FOR EVENT (JPEG kept under 3 MB for upload) ---
  Future<File?> saveForEvent(GlobalKey key) async {
    try {
      return await PosterExportHelper.saveJpegUnderMaxSize(
        key,
        maxBytes: UploadFileValidators.maxPosterBytes,
        filePrefix: 'event_poster',
      );
    } catch (e) {
      debugPrint("saveForEvent Error: $e");
      return null;
    }
  }

  // --- DOWNLOAD IMAGE (also capped at 3 MB) ---
  Future<void> downloadImage(GlobalKey key) async {
     try {
       final bytes = await PosterExportHelper.encodeJpegBytesUnderMaxSize(
         key,
         maxBytes: UploadFileValidators.maxPosterBytes,
       );
       
       if (bytes != null) {
         await SaverGallery.saveImage(
           bytes,
           name: "gnu_poster_${DateTime.now().millisecondsSinceEpoch}.jpg",
           androidExistNotSave: false,
         );
         SweetAlertHelper.showSuccess(
           Get.context,
           "Success",
           "Poster saved to Gallery (within ${UploadFileValidators.formatMb(UploadFileValidators.maxPosterBytes)})!",
         );
       } else {
         SweetAlertHelper.showError(Get.context, "Error", "Could not save image");
       }
     } catch(e) { 
       SweetAlertHelper.showError(Get.context, "Error", "Could not save image"); 
     }
  }

  // --- DOWNLOAD PDF ---
  Future<void> downloadPdf(GlobalKey key) async {
    try {
      RenderRepaintBoundary? boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      ui.Image img = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      Uint8List? bytes = byteData?.buffer.asUint8List();
      if (bytes == null) return;
      
      final pdf = pw.Document();
      pdf.addPage(pw.Page(
        build: (pw.Context context) => pw.Center(child: pw.Image(pw.MemoryImage(bytes))),
        margin: pw.EdgeInsets.zero 
      ));
      
      final dir = await getExternalStorageDirectory(); 
      final path = dir?.path ?? (await getApplicationDocumentsDirectory()).path;
      final file = File("$path/gnu_event_${DateTime.now().millisecondsSinceEpoch}.pdf");
      
      await file.writeAsBytes(await pdf.save());
      SweetAlertHelper.showSuccess(Get.context, "PDF Saved", "Saved to: ${file.path}");
    } catch(e) { 
      SweetAlertHelper.showError(Get.context, "Error", "Could not save PDF"); 
    }
  }
}