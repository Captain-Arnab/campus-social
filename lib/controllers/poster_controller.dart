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

class PosterController extends GetxController {
  // --- OBSERVABLE VARIABLES ---
  var title = "My Awesome Event".obs;
  var venue = "Campus Venue, Main Hall".obs;
  var dateStr = "DATE".obs;
  var timeStr = "TIME".obs;
  var description = "Join us for an amazing event!".obs;
  
  // Tech template specific fields
  var mode = "Online".obs; // Online or Offline
  var trainerName = "".obs;

  // English template specific fields
  var titleEnglish = "Online Course".obs;
  var subtitle = "Spoken English".obs;
  var startDay = "MONDAY".obs;
  var endDay = "FRIDAY".obs;
  var startTime = "8 AM".obs;
  var endTime = "2 PM".obs;
  var phoneNumber = "800 829 5550 / 51".obs;
  var coursePoints = <String>[].obs;

  // Music Festival specific fields
  var location = "Handover and Tyke Stadium".obs;
  var startTimings = "10 AM".obs;
  var endTimings = "10 PM".obs;

  // Basketball specific fields
  var stadiumName = "Brocelle Stadium".obs;
  var address = "123 Anywhere St., Any City".obs;
  var basketballStartTime = "2 PM".obs;
  var basketballEndTime = "5 PM".obs;

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

  // --- INITIALIZE SAMPLE DATA FOR GRADUATION THEME ---
  void initializeGraduationData() {
    title.value = "Graduation Party";
    description.value = "Class of 2025";
    dateStr.value = "DATE";
    timeStr.value = "TIME";
    venue.value = "Campus Venue, Main Hall";
  }

  // --- LOAD SAMPLE IMAGES FOR GRADUATION THEME ---
  Future<void> loadGraduationSampleImages() async {
    try {
      final logo = await assetToFile('assets/images/guru_nanak_logo.png');
      final bgImage = await assetToFile('assets/images/basketball/element2.png');
      
      if (logo != null) logoImage.value = logo;
      if (bgImage != null) selectedImage.value = bgImage;
      
      debugPrint("Graduation sample images loaded successfully");
    } catch (e) {
      debugPrint("Error loading graduation sample images: $e");
    }
  }

  // --- INITIALIZE SAMPLE DATA FOR TECH THEME ---
  void initializeTechData() {
    title.value = "Innovation & Technology";
    description.value = "Guru Nanak University session of Innovation & Technology";
    trainerName.value = "Ram Sett";
    mode.value = "Online";
    dateStr.value = "DATE";
    timeStr.value = "TIME";
    venue.value = "Campus Venue, Main Hall";
  }

  // --- LOAD SAMPLE IMAGES FOR TECH THEME ---
  Future<void> loadTechSampleImages() async {
    try {
      final logo = await assetToFile('assets/images/guru_nanak_logo.png');
      final robotImage = await assetToFile('assets/images/innovation/robot.png');
      final trainerPhoto = await assetToFile('assets/images/online_course/element.png');
      
      if (logo != null) logoImage.value = logo;
      if (robotImage != null) selectedImage.value = robotImage;
      if (trainerPhoto != null) trainerImage.value = trainerPhoto;
      
      debugPrint("Tech sample images loaded successfully");
    } catch (e) {
      debugPrint("Error loading tech sample images: $e");
    }
  }

  // --- INITIALIZE SAMPLE DATA FOR ENGLISH THEME ---
  void initializeSampleEnglishData() {
    // Set sample course points
    coursePoints.value = [
      "Listening Course",
      "Writing Course", 
      "Pronunciation",
      "Speaking Course",
    ];
    
    // Set other English theme defaults
    titleEnglish.value = "ONLINE COURSE";
    subtitle.value = "Spoken English";
    startDay.value = "SUNDAY";
    endDay.value = "THURSDAY";
    startTime.value = "08 AM";
    endTime.value = "2 PM";
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
    description.value = "Join us for an amazing event!";
    location.value = "Handover and Tyke Stadium";
    startTimings.value = "10 AM";
    endTimings.value = "10 PM";
    dateStr.value = "DATE";
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
    stadiumName.value = "Brocelle Stadium";
    address.value = "123 Anywhere St., Any City";
    dateStr.value = "DATE";
    basketballStartTime.value = "2 PM";
    basketballEndTime.value = "5 PM";
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFFF5F15))),
        child: child!,
      ),
    );
    
    if (picked != null) {
      String day = picked.day.toString();
      String suffix = "TH";
      if (day.endsWith("1") && day != "11") suffix = "ST";
      else if (day.endsWith("2") && day != "12") suffix = "ND";
      else if (day.endsWith("3") && day != "13") suffix = "RD";
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFFF6B35))),
        child: child!,
      ),
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
    if (picked != null) timeStr.value = picked.format(context);
  }

  // --- BASKETBALL START TIME PICKER ---
  Future<void> pickBasketballStartTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context, 
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFFF6B35))
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      basketballStartTime.value = '$hour $period';
    }
  }

  // --- BASKETBALL END TIME PICKER ---
  Future<void> pickBasketballEndTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context, 
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFFF6B35))
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      basketballEndTime.value = '$hour $period';
    }
  }

  // --- START TIME PICKER ---
  Future<void> pickStartTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context, 
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFFF5F15))
        ),
        child: child!,
      ),
    );
    if (picked != null) startTimings.value = picked.format(context);
  }

  // --- END TIME PICKER ---
  Future<void> pickEndTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context, 
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFFF5F15))
        ),
        child: child!,
      ),
    );
    if (picked != null) endTimings.value = picked.format(context);
  }

  // --- SAVE FOR EVENT ---
  Future<File?> saveForEvent(GlobalKey key) async {
    try {
      RenderRepaintBoundary? boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/event_poster_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      return file; 
    } catch (e) {
      debugPrint("Error: $e");
      return null;
    }
  }

  // --- DOWNLOAD IMAGE ---
  Future<void> downloadImage(GlobalKey key) async {
     try {
       RenderRepaintBoundary? boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
       if (boundary == null) return;
       
       ui.Image image = await boundary.toImage(pixelRatio: 3.0);
       ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
       Uint8List? bytes = byteData?.buffer.asUint8List();
       
       if (bytes != null) {
         await SaverGallery.saveImage(bytes, fileName: "gnu_poster_${DateTime.now().millisecondsSinceEpoch}.png", skipIfExists: false);
         Get.snackbar("Success", "Poster saved to Gallery!", backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
       }
     } catch(e) { 
       Get.snackbar("Error", "Could not save image", backgroundColor: Colors.red, colorText: Colors.white); 
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
      Get.snackbar("PDF Saved", "Saved to: ${file.path}", backgroundColor: Colors.green, colorText: Colors.white, duration: const Duration(seconds: 4));
    } catch(e) { 
      Get.snackbar("Error", "Could not save PDF", backgroundColor: Colors.red); 
    }
  }
}