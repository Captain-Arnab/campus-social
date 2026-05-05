import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/app_bar_title_with_brand_logo.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../controllers/poster_controller.dart';
import '../utils/sweetalert_helper.dart';
import '../widgets/poster_themes.dart';

/// Character caps for poster fields (large type on fixed layouts — long text clips or overlaps).
class _PosterCopyLimits {
  static const int title = 48;
  static const int description = 140;
  static const int englishSubtitle = 36;
  static const int englishTitle = 40;
  static const int trainerName = 40;
  static const int venue = 56;
  static const int stadium = 48;
  static const int address = 72;
  static const int location = 56;
  static const int phone = 32;

  static String get titleGuidance =>
      'Headlines use very large type. Aim for about 6–8 short words (max $title characters) so nothing is cut off.';
  static String get descriptionGuidance =>
      'Optional. About 2–3 short lines (max $description characters). Extra text may be clipped on the poster.';
  static String get subtitleGuidance =>
      'Short phrase only (max $englishSubtitle characters), e.g. “Spoken English”.';
  static String get englishTitleGuidance =>
      'Short banner text (max $englishTitle characters), e.g. “ONLINE COURSE”.';
  static String get trainerGuidance => 'Max $trainerName characters so it fits next to the photo.';
  static String get venueGuidance => 'Max $venue characters; long venue names may wrap or clip.';
  static String get stadiumGuidance => 'Max $stadium characters.';
  static String get addressGuidance => 'Max $address characters; use line breaks sparingly.';
  static String get locationGuidance => 'Max $location characters.';
}

class PosterEditorView extends StatefulWidget {
  final int themeIndex;
  const PosterEditorView({super.key, required this.themeIndex});

  @override
  State<PosterEditorView> createState() => _PosterEditorViewState();
}

class _PosterEditorViewState extends State<PosterEditorView> {
  final controller = Get.put(PosterController());
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isProcessing = false;
  
  late TextEditingController titleController;
  late TextEditingController venueController;
  late TextEditingController descriptionController;
  late TextEditingController trainerNameController;
  late TextEditingController subtitleController;
  late TextEditingController phoneController;
  late TextEditingController coursePointController;
  late TextEditingController locationController;
  late TextEditingController stadiumNameController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    
    // Initialize data and images based on theme
    _initializeThemeData();
    
    // Initialize all controllers with updated values
    titleController = TextEditingController(
      text: widget.themeIndex == 2 ? controller.titleEnglish.value : controller.title.value
    );
    venueController = TextEditingController(text: controller.venue.value);
    descriptionController = TextEditingController(text: controller.description.value);
    trainerNameController = TextEditingController(text: controller.trainerName.value);
    subtitleController = TextEditingController(text: controller.subtitle.value);
    phoneController = TextEditingController(text: controller.phoneNumber.value);
    coursePointController = TextEditingController();
    locationController = TextEditingController(text: controller.location.value);
    stadiumNameController = TextEditingController(text: controller.stadiumName.value);
    addressController = TextEditingController(text: controller.address.value);
  }

  void _initializeThemeData() {
    switch (widget.themeIndex) {
      case 0: // Graduation Theme
        controller.initializeGraduationData();
        controller.loadGraduationSampleImages();
        break;
      case 1: // Tech Theme
        controller.initializeTechData();
        controller.loadTechSampleImages();
        break;
      case 2: // English Theme
        controller.initializeSampleEnglishData();
        controller.loadEnglishSampleImages();
        break;
      case 3: // Music Festival Theme
        controller.initializeMusicFestivalData();
        controller.loadMusicFestivalSampleImages();
        break;
      case 4: // Basketball Theme
        controller.initializeBasketballData();
        controller.loadBasketballSampleImages();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    venueController.dispose();
    descriptionController.dispose();
    trainerNameController.dispose();
    subtitleController.dispose();
    phoneController.dispose();
    coursePointController.dispose();
    locationController.dispose();
    stadiumNameController.dispose();
    addressController.dispose();
    super.dispose();
  }

  bool get isTechTheme => widget.themeIndex == 1;
  bool get isGraduationTheme => widget.themeIndex == 0;
  bool get isEnglishTheme => widget.themeIndex == 2;
  bool get isMusicFestivalTheme => widget.themeIndex == 3;
  bool get isBasketballTheme => widget.themeIndex == 4;

  String _inferCategory() {
    switch (widget.themeIndex) {
      case 0: return 'Cultural';     // Graduation
      case 1: return 'IT/Tech';      // Tech & Innovation
      case 2: return 'Academic';     // Online Course / English
      case 3: return 'Cultural';     // Music Festival
      case 4: return 'Sports';       // Basketball
      default: return 'IT/Tech';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        toolbarHeight: 44.h,
        title: AppBarTitleWithBrandLogo(
          onPrimaryBackground: false,
          logoUnit: 28,
          title: const Text("Customize Poster", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // --- PREVIEW ---
          Expanded(
            flex: 10,
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(15.w),
                  child: Container(
                    decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, 5))]),
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: Obx(() {
                        final img = controller.selectedImage.value;
                        final logo = controller.logoImage.value;
                        final desc = controller.description.value;
                        final trainerImg = controller.trainerImage.value;
                        final trainerNm = controller.trainerName.value;
                        final modeVal = controller.mode.value;
                        final qrCode = controller.qrCodeImage.value;
                        
                        switch (widget.themeIndex) {
                          case 0: return PosterTheme.graduationTheme(
                            title: controller.title.value, 
                            date: controller.posterDateRangeLine(), 
                            venue: controller.venue.value, 
                            time: controller.timeStr.value,
                            description: desc,
                            image: img,
                            logoImage: logo,
                            qrCodeImage: qrCode,
                          );
                          case 1: return PosterTheme.techTheme(
                            title: controller.title.value, 
                            date: controller.posterDateRangeLine(), 
                            venue: controller.venue.value,
                            time: controller.timeStr.value,
                            mode: modeVal,
                            trainerName: trainerNm,
                            description: desc,
                            image: img,
                            logoImage: logo,
                            trainerImage: trainerImg,
                          );
                          case 2: return PosterTheme.englishTheme(
                            title: controller.titleEnglish.value,
                            subtitle: controller.subtitle.value,
                            courseDateLine: controller.posterDateRangeLine(),
                            startTime: controller.startTime.value,
                            endTime: controller.endTime.value,
                            coursePoints: controller.coursePoints.toList(),
                            phoneNumber: controller.phoneNumber.value,
                            image: img,
                            logoImage: logo,
                          );
                          case 3: return PosterTheme.musicFestivalTheme(
                            title: controller.title.value,
                            date: controller.posterDateRangeLine(),
                            location: controller.location.value,
                            startTime: controller.startTimings.value,
                            endTime: controller.endTimings.value,
                            description: desc,
                            image: img,
                            logoImage: logo,
                            qrCodeImage: qrCode,
                          );
                          case 4: return PosterTheme.basketballTheme(
                            title: controller.title.value,
                            stadiumName: controller.stadiumName.value,
                            address: controller.address.value,
                            date: controller.posterDateRangeLine(),
                            startTime: controller.basketballStartTime.value,
                            endTime: controller.basketballEndTime.value,
                            image: img,
                            logoImage: logo,
                          );
                          default: return const SizedBox();
                        }
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- EDITING FIELDS ---
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                children: [
                   _buildPosterCopyGuidanceBanner(),
                   SizedBox(height: 12.h),
                   _buildPosterDateRangeSection(context),
                   SizedBox(height: 10.h),

                   // Basketball Theme Fields
                   if (isBasketballTheme) ...[
                     _buildTextField("Event Title", Icons.title, titleController, (v) => controller.title.value = v,
                         maxLength: _PosterCopyLimits.title, helperText: _PosterCopyLimits.titleGuidance),
                     SizedBox(height: 10.h),
                     
                     _buildTextField("Stadium Name", Icons.stadium, stadiumNameController, (v) => controller.stadiumName.value = v,
                         maxLength: _PosterCopyLimits.stadium, helperText: _PosterCopyLimits.stadiumGuidance),
                     SizedBox(height: 10.h),
                     
                     _buildTextField("Address", Icons.location_on, addressController, (v) => controller.address.value = v,
                         maxLength: _PosterCopyLimits.address, helperText: _PosterCopyLimits.addressGuidance),
                     SizedBox(height: 10.h),
                     
                     Row(
                       children: [
                         Expanded(child: _buildPickerButton("Start Time", Icons.schedule, controller.basketballStartTime, () => controller.pickBasketballStartTime(context))),
                         SizedBox(width: 10.w),
                         Expanded(child: _buildPickerButton("End Time", Icons.schedule, controller.basketballEndTime, () => controller.pickBasketballEndTime(context))),
                       ],
                     ),
                     SizedBox(height: 10.h),
                   ],
                   
                   // Music Festival Theme Fields
                   if (isMusicFestivalTheme) ...[
                     _buildTextField("Event Title", Icons.title, titleController, (v) => controller.title.value = v,
                         maxLength: _PosterCopyLimits.title, helperText: _PosterCopyLimits.titleGuidance),
                     SizedBox(height: 10.h),
                     
                     _buildTextField("Location", Icons.location_on, locationController, (v) => controller.location.value = v,
                         maxLength: _PosterCopyLimits.location, helperText: _PosterCopyLimits.locationGuidance),
                     SizedBox(height: 10.h),
                     
                     Row(
                       children: [
                         Expanded(child: _buildPickerButton("Start Time", Icons.schedule, controller.startTimings, () => controller.pickStartTime(context))),
                         SizedBox(width: 10.w),
                         Expanded(child: _buildPickerButton("End Time", Icons.schedule, controller.endTimings, () => controller.pickEndTime(context))),
                       ],
                     ),
                     SizedBox(height: 10.h),
                   ],
                   
                   // English Theme Fields
                   if (isEnglishTheme) ...[
                     _buildTextField("Subtitle (e.g., Spoken English)", Icons.text_fields, subtitleController, (v) => controller.subtitle.value = v,
                         maxLength: _PosterCopyLimits.englishSubtitle, helperText: _PosterCopyLimits.subtitleGuidance),
                     SizedBox(height: 10.h),
                     
                     _buildTextField("Title (e.g., ONLINE COURSE)", Icons.title, titleController, (v) => controller.titleEnglish.value = v,
                         maxLength: _PosterCopyLimits.englishTitle, helperText: _PosterCopyLimits.englishTitleGuidance),
                     SizedBox(height: 10.h),
                     
                     _buildTimeRangeSelector(),
                     SizedBox(height: 10.h),
                     
                     _buildTextField("Phone Number", Icons.phone, phoneController, (v) => controller.phoneNumber.value = v,
                         maxLength: _PosterCopyLimits.phone, helperText: 'Keep short (max ${_PosterCopyLimits.phone} characters).'),
                     SizedBox(height: 10.h),
                     
                     _buildCoursePointsSection(),
                     SizedBox(height: 10.h),
                   ],
                   
                   // Title Field (for non-English, non-Music Festival, and non-Basketball themes)
                   if (!isEnglishTheme && !isMusicFestivalTheme && !isBasketballTheme) ...[
                     _buildTextField("Event Title", Icons.title, titleController, (v) => controller.title.value = v,
                         maxLength: _PosterCopyLimits.title, helperText: _PosterCopyLimits.titleGuidance),
                     SizedBox(height: 10.h),
                   ],
                   
                   // Time (dates use shared From / To above)
                   if (!isEnglishTheme && !isMusicFestivalTheme && !isBasketballTheme) ...[
                     _buildPickerButton("Time", Icons.schedule, controller.timeStr, () => controller.pickTime(context)),
                     SizedBox(height: 10.h),
                   ],
                   
                   // Mode Selector (Only for Tech Theme)
                   if (isTechTheme) ...[
                     _buildModeSelector(),
                     SizedBox(height: 10.h),
                   ],
                   
                   // Venue Field (Hidden for Tech Online mode, English theme, Music Festival theme, and Basketball theme)
                   if (!isEnglishTheme && !isMusicFestivalTheme && !isBasketballTheme && (!isTechTheme || controller.mode.value == "Offline")) ...[
                     _buildTextField("Venue", Icons.location_on, venueController, (v) => controller.venue.value = v,
                         maxLength: _PosterCopyLimits.venue, helperText: _PosterCopyLimits.venueGuidance),
                     SizedBox(height: 10.h),
                   ],
                   
                   // Description Field (for non-English themes)
                   if (!isEnglishTheme && !isBasketballTheme) ...[
                     _buildTextField("Description (Optional)", Icons.description, descriptionController, (v) => controller.description.value = v,
                         maxLines: 3,
                         maxLength: _PosterCopyLimits.description,
                         helperText: _PosterCopyLimits.descriptionGuidance),
                     SizedBox(height: 10.h),
                   ],
                   
                   // Trainer Name (Only for Tech Theme)
                   if (isTechTheme) ...[
                     _buildTextField("Trainer Name (Optional)", Icons.person, trainerNameController, (v) => controller.trainerName.value = v,
                         maxLength: _PosterCopyLimits.trainerName, helperText: _PosterCopyLimits.trainerGuidance),
                     SizedBox(height: 10.h),
                   ],
                   
                   // Logo Button
                   OutlinedButton.icon(
                     onPressed: controller.pickLogo,
                     icon: const Icon(Icons.business, color: Colors.blue),
                     label: Obx(() => Text(
                       controller.logoImage.value != null ? "Logo Selected ✓" : "Upload Logo",
                       style: const TextStyle(color: Colors.black87)
                     )),
                     style: OutlinedButton.styleFrom(
                       minimumSize: Size(double.infinity, 45.h),
                       side: BorderSide(color: controller.logoImage.value != null ? Colors.green : Colors.grey, width: 1.5),
                     ),
                   ),
                   
                   SizedBox(height: 10.h),
                   
                   // Background Image Button
                   OutlinedButton.icon(
                     onPressed: controller.pickImage,
                     icon: const Icon(Icons.add_photo_alternate, color: Colors.orange),
                     label: Obx(() => Text(
                       controller.selectedImage.value != null 
                         ? (isTechTheme ? "Robot Image Selected ✓" : 
                            isEnglishTheme ? "Student Image Selected ✓" : 
                            isMusicFestivalTheme ? "Celebration Image Selected ✓" : 
                            isBasketballTheme ? "Court Action Image Selected ✓" :
                            "Background Image Selected ✓") 
                         : (isTechTheme ? "Upload Robot Image" : 
                            isEnglishTheme ? "Upload Student Image" : 
                            isMusicFestivalTheme ? "Upload Celebration Image" : 
                            isBasketballTheme ? "Upload Court Action Image" :
                            "Upload Background Image"),
                       style: const TextStyle(color: Colors.black87)
                     )),
                     style: OutlinedButton.styleFrom(
                       minimumSize: Size(double.infinity, 45.h),
                       side: BorderSide(color: controller.selectedImage.value != null ? Colors.green : Colors.grey, width: 1.5),
                     ),
                   ),
                   
                   SizedBox(height: 10.h),
                   
                   // QR Code Button (Only for Graduation Theme and Music Festival)
                   if (isGraduationTheme || isMusicFestivalTheme) ...[
                     OutlinedButton.icon(
                       onPressed: controller.pickQrCode,
                       icon: const Icon(Icons.qr_code_2, color: Colors.green),
                       label: Obx(() => Text(
                         controller.qrCodeImage.value != null ? "QR Code Selected ✓" : "Upload QR Code",
                         style: const TextStyle(color: Colors.black87)
                       )),
                       style: OutlinedButton.styleFrom(
                         minimumSize: Size(double.infinity, 45.h),
                         side: BorderSide(
                           color: controller.qrCodeImage.value != null ? Colors.green : Colors.grey, 
                           width: 1.5
                         ),
                       ),
                     ),
                     SizedBox(height: 10.h),
                   ],
                   
                   // Trainer Image Button (Only for Tech Theme)
                   if (isTechTheme) ...[
                     OutlinedButton.icon(
                       onPressed: controller.pickTrainerImage,
                       icon: const Icon(Icons.account_circle, color: Colors.purple),
                       label: Obx(() => Text(
                         controller.trainerImage.value != null ? "Trainer Photo Selected ✓" : "Upload Trainer Photo",
                         style: const TextStyle(color: Colors.black87)
                       )),
                       style: OutlinedButton.styleFrom(
                         minimumSize: Size(double.infinity, 45.h),
                         side: BorderSide(color: controller.trainerImage.value != null ? Colors.green : Colors.grey, width: 1.5),
                       ),
                     ),
                   ],
                   
                   SizedBox(height: 80.h),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // --- BOTTOM BAR ---
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(15.w),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))]),
        child: SafeArea(
          child: Row(
            children: [
              _buildMiniButton(Icons.picture_as_pdf, "PDF", () => controller.downloadPdf(_boundaryKey)),
              SizedBox(width: 10.w),
              _buildMiniButton(Icons.image, "JPG", () => controller.downloadImage(_boundaryKey)),
              SizedBox(width: 10.w),
              
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : () async {
                    setState(() => _isProcessing = true);
                    File? posterFile = await controller.saveForEvent(_boundaryKey);
                    setState(() => _isProcessing = false);

                    if (posterFile != null) {
                      if (controller.posterStartDate.value == null) {
                        SweetAlertHelper.showError(context, "Required", "Please choose a start date.");
                        setState(() => _isProcessing = false);
                        return;
                      }
                      if (!isEnglishTheme && !isMusicFestivalTheme && !isBasketballTheme &&
                          controller.timeStr.value.toUpperCase() == 'TIME') {
                        SweetAlertHelper.showError(context, "Required", "Please set the event time.");
                        setState(() => _isProcessing = false);
                        return;
                      }
                      final startTimeRaw = _posterSaveStartTimeRaw();
                      final endTimeRaw = _posterSaveEndTimeRaw();
                      final startIso = controller.posterEventStartDateTimeIso(startTimeRaw);
                      final endIso = controller.posterEventEndDateTimeIso(endTimeRaw);
                      if (endIso != null && startIso != null) {
                        final a = DateTime.tryParse(startIso.replaceAll(' ', 'T'));
                        final b = DateTime.tryParse(endIso.replaceAll(' ', 'T'));
                        if (a != null && b != null && b.isBefore(a)) {
                          SweetAlertHelper.showError(
                            context,
                            "Invalid",
                            "End date and time must be on or after the start.",
                          );
                          setState(() => _isProcessing = false);
                          return;
                        }
                      }
                      final result = <String, dynamic>{
                        'file': posterFile,
                        'title': isEnglishTheme
                            ? controller.titleEnglish.value
                            : controller.title.value,
                        'description': controller.description.value,
                        'venue': isBasketballTheme
                            ? '${controller.stadiumName.value}, ${controller.address.value}'
                            : isMusicFestivalTheme
                                ? controller.location.value
                                : controller.venue.value,
                        'date': startIso ?? controller.dateStr.value,
                        'time': startTimeRaw,
                        'category': _inferCategory(),
                      };
                      if (endIso != null) {
                        result['event_end_date'] = endIso;
                      }
                      Get.back(result: result);
                    } else {
                      SweetAlertHelper.showError(context, "Error", "Failed to generate poster");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5F15),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0
                  ),
                  child: _isProcessing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("USE THIS POSTER", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.grey[800]),
            Text(label, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.grey[800]))
          ],
        ),
      ),
    );
  }

  Widget _buildPosterCopyGuidanceBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.text_fields_rounded, color: Colors.orange.shade800, size: 22),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Posters use large text in fixed areas. Use the limits under each field — '
              'about ${_PosterCopyLimits.title} characters for titles and ${_PosterCopyLimits.description} for descriptions — '
              'so nothing runs past the design or overlaps other lines.',
              style: TextStyle(fontSize: 12.sp, color: Colors.orange.shade900, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController textController,
    Function(String) onChanged, {
    int maxLines = 1,
    int? maxLength,
    String? helperText,
  }) {
    return TextField(
      controller: textController,
      onChanged: onChanged,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperMaxLines: 4,
        helperStyle: TextStyle(fontSize: 11.sp, color: Colors.grey[700], height: 1.3),
        prefixIcon: Icon(icon, color: Colors.orange, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
        contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildPickerButton(String label, IconData icon, RxString value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 10.w),
        decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(10), color: Colors.white),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.orange),
            SizedBox(width: 8.w),
            Expanded(child: Obx(() => Text(
              value.value == label.toUpperCase() ? label : value.value, 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)
            ))),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Obx(() => Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(Icons.settings, size: 18, color: Colors.orange),
          SizedBox(width: 8.w),
          Text(
            "Mode:",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text("Online", style: TextStyle(fontSize: 12.sp)),
                    value: "Online",
                    groupValue: controller.mode.value,
                    onChanged: (val) => controller.mode.value = val!,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: Colors.orange,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text("Offline", style: TextStyle(fontSize: 12.sp)),
                    value: "Offline",
                    groupValue: controller.mode.value,
                    onChanged: (val) => controller.mode.value = val!,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  String _posterSaveStartTimeRaw() {
    if (isEnglishTheme) return controller.startTime.value;
    if (isMusicFestivalTheme) return controller.startTimings.value;
    if (isBasketballTheme) return controller.basketballStartTime.value;
    return controller.timeStr.value;
  }

  String _posterSaveEndTimeRaw() {
    if (isEnglishTheme) return controller.endTime.value;
    if (isMusicFestivalTheme) return controller.endTimings.value;
    if (isBasketballTheme) return controller.basketballEndTime.value;
    return controller.timeStr.value;
  }

  Widget _buildPosterDateRangeSection(BuildContext context) {
    return Obx(() {
      final start = controller.posterStartDate.value;
      final end = controller.posterEndDate.value;
      final df = DateFormat('dd MMM yyyy');
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.orange),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    "Event dates (shown on poster)",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text("From (required)", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
            SizedBox(height: 6.h),
            GestureDetector(
              onTap: () => controller.pickPosterStartDate(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, color: Colors.orange, size: 20),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        start != null ? df.format(start) : "Start date",
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "To (optional)",
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ),
                if (end != null)
                  GestureDetector(
                    onTap: controller.clearPosterEndDate,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 16, color: Colors.red.shade400),
                        SizedBox(width: 4.w),
                        Text("Clear", style: TextStyle(fontSize: 12.sp, color: Colors.red.shade400)),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6.h),
            GestureDetector(
              onTap: start == null ? null : () => controller.pickPosterEndDate(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                decoration: BoxDecoration(
                  border: Border.all(color: end != null ? Colors.grey.shade300 : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(10),
                  color: start == null ? Colors.grey.shade50 : null,
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_note, color: start == null ? Colors.grey : Colors.orange, size: 20),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        end != null ? df.format(end) : "End date (optional)",
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: start == null ? Colors.grey : (end != null ? Colors.black87 : Colors.grey.shade600),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTimeRangeSelector() {
    return Obx(() => Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: Colors.orange),
              SizedBox(width: 8.w),
              Text("Time Duration:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: controller.startTime.value),
                  decoration: const InputDecoration(
                    labelText: "Start Time (e.g., 08 AM)",
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => controller.startTime.value = val,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: controller.endTime.value),
                  decoration: const InputDecoration(
                    labelText: "End Time (e.g., 2 PM)",
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => controller.endTime.value = val,
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _buildCoursePointsSection() {
    return Obx(() => Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, size: 18, color: Colors.orange),
              SizedBox(width: 8.w),
              Text("Course Points:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
            ],
          ),
          SizedBox(height: 10.h),
          
          // Display existing points
          ...controller.coursePoints.asMap().entries.map((entry) {
            int idx = entry.key;
            String point = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(point, style: TextStyle(fontSize: 12.sp)),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 20.sp),
                    onPressed: () => controller.removeCoursePoint(idx),
                  ),
                ],
              ),
            );
          }).toList(),
          
          // Add new point
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: coursePointController,
                  decoration: const InputDecoration(
                    hintText: "Add course point...",
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              ElevatedButton(
                onPressed: () {
                  if (coursePointController.text.trim().isNotEmpty) {
                    controller.addCoursePoint(coursePointController.text);
                    coursePointController.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
                ),
                child: const Text("Add", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}