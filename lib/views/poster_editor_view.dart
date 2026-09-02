import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_bar_title_with_brand_logo.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../controllers/poster_controller.dart';
import '../utils/sweetalert_helper.dart';
import '../utils/upload_file_validators.dart';
import '../widgets/poster_themes.dart';

/// Character caps for poster fields (large type on fixed layouts — long text clips or overlaps).
class _PosterCopyLimits {
  static const int title = 48;
  static const int description = 140;
  static const int graduationTitle = 20;
  static const int graduationDescription = 85;
  static const int graduationVenue = 50;
  static const int techTitle = 25;
  static const int techDescription = 62;
  static const int englishSubtitle = 15;
  static const int englishTitle = 14;
  static const int musicTitle = 14;
  static const int musicVenue = 25;
  static const int musicDescription = 30;
  static const int basketballTitle = 22;
  static const int basketballStadium = 18;
  static const int basketballAddress = 26;
  static const int basketballDescription = 60;
  static const int trainerName = 40;
  static const int venue = 56;
  static const int phone = 32;
  static const int englishVenue = 40;

  static String get graduationTitleGuidance =>
      'Graduation headline: max $graduationTitle characters so it fits the layout.';
  static String get graduationDescriptionGuidance =>
      'Optional. Max $graduationDescription characters on the poster.';
  static String get graduationVenueGuidance =>
      'Max $graduationVenue characters for the venue line.';
  static String get techTitleGuidance =>
      'Innovation & Technology headline: max $techTitle characters.';
  static String get techDescriptionGuidance =>
      'Max $techDescription characters; extra text is clipped on the poster.';
  static String get techTaglineGuidance =>
      'Right-column tagline (max ${PosterController.kTechTaglineMaxLength} characters, same length as the default phrase).';
  static String get descriptionGuidance =>
      'Optional. About 2–3 short lines (max $description characters). Extra text may be clipped on the poster.';
  static String get subtitleGuidance =>
      'Spoken English subtitle: max $englishSubtitle characters.';
  static String get englishTitleGuidance =>
      'Banner title: max $englishTitle characters (e.g. ONLINE COURSE).';
  static String get musicTitleGuidance => 'Music poster headline: max $musicTitle characters.';
  static String get musicVenueGuidance => 'Venue line: max $musicVenue characters.';
  static String get musicDescriptionGuidance => 'Info box text: max $musicDescription characters.';
  static String get basketballTitleGuidance => 'Event title: max $basketballTitle characters.';
  static String get basketballStadiumGuidance => 'Stadium name: max $basketballStadium characters.';
  static String get basketballAddressGuidance => 'Address: max $basketballAddress characters.';
  static String get basketballDescriptionGuidance =>
      'Optional. Max $basketballDescription characters on the poster.';
  static String get englishVenueGuidance => 'Max $englishVenue characters for the venue line.';
  static String get trainerGuidance => 'Max $trainerName characters so it fits next to the photo.';
  static String get venueGuidance => 'Max $venue characters; long venue names may wrap or clip.';
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
  late TextEditingController stadiumNameController;
  late TextEditingController addressController;
  late TextEditingController techTaglineController;

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
    stadiumNameController = TextEditingController(text: controller.stadiumName.value);
    addressController = TextEditingController(text: controller.address.value);
    techTaglineController = TextEditingController(text: controller.techTagline.value);
    _clampAllPosterInputsToLimits(syncToRx: true);
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
      case 2: // Spoken English Theme
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
    stadiumNameController.dispose();
    addressController.dispose();
    techTaglineController.dispose();
    super.dispose();
  }

  bool get isTechTheme => widget.themeIndex == 1;
  bool get isGraduationTheme => widget.themeIndex == 0;
  bool get isEnglishTheme => widget.themeIndex == 2;
  bool get isMusicFestivalTheme => widget.themeIndex == 3;
  bool get isBasketballTheme => widget.themeIndex == 4;

  TimeOfDay? _parseTimeForPoster(String raw) => controller.tryParsePosterTimeLabel(raw);

  /// Hard-clamp all poster text fields to theme max lengths (inputFormatters + maxLength also block typing).
  void _clampAllPosterInputsToLimits({required bool syncToRx}) {
    void clip(TextEditingController c, int max) {
      if (c.text.length > max) {
        c.text = c.text.substring(0, max);
        c.selection = TextSelection.collapsed(offset: c.text.length);
      }
    }

    if (isGraduationTheme) {
      clip(titleController, _PosterCopyLimits.graduationTitle);
      clip(venueController, _PosterCopyLimits.graduationVenue);
      clip(descriptionController, _PosterCopyLimits.graduationDescription);
      if (syncToRx) {
        controller.title.value = titleController.text;
        controller.venue.value = venueController.text;
        controller.description.value = descriptionController.text;
      }
    } else if (isTechTheme) {
      clip(techTaglineController, PosterController.kTechTaglineMaxLength);
      clip(titleController, _PosterCopyLimits.techTitle);
      clip(descriptionController, _PosterCopyLimits.techDescription);
      clip(venueController, _PosterCopyLimits.venue);
      if (syncToRx) {
        controller.techTagline.value = techTaglineController.text;
        controller.title.value = titleController.text;
        controller.description.value = descriptionController.text;
        controller.venue.value = venueController.text;
      }
    } else if (isEnglishTheme) {
      clip(subtitleController, _PosterCopyLimits.englishSubtitle);
      clip(titleController, _PosterCopyLimits.englishTitle);
      clip(phoneController, _PosterCopyLimits.phone);
      clip(venueController, _PosterCopyLimits.englishVenue);
      if (syncToRx) {
        controller.subtitle.value = subtitleController.text;
        controller.titleEnglish.value = titleController.text;
        controller.phoneNumber.value = phoneController.text;
        controller.venue.value = venueController.text;
      }
    } else if (isMusicFestivalTheme) {
      clip(titleController, _PosterCopyLimits.musicTitle);
      clip(venueController, _PosterCopyLimits.musicVenue);
      clip(descriptionController, _PosterCopyLimits.musicDescription);
      if (syncToRx) {
        controller.title.value = titleController.text;
        controller.venue.value = venueController.text;
        controller.description.value = descriptionController.text;
      }
    } else if (isBasketballTheme) {
      clip(titleController, _PosterCopyLimits.basketballTitle);
      clip(stadiumNameController, _PosterCopyLimits.basketballStadium);
      clip(addressController, _PosterCopyLimits.basketballAddress);
      clip(descriptionController, _PosterCopyLimits.basketballDescription);
      if (syncToRx) {
        controller.title.value = titleController.text;
        controller.stadiumName.value = stadiumNameController.text;
        controller.address.value = addressController.text;
        controller.description.value = descriptionController.text;
      }
    }
  }

  String _inferCategory() {
    switch (widget.themeIndex) {
      case 0: return 'Cultural';     // Graduation
      case 1: return 'IT/Tech';      // Tech & Innovation
      case 2: return 'Academic';     // Spoken English
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
        title: const AppBarTitleWithBrandLogo(
          onPrimaryBackground: false,
          logoUnit: 28,
          title: Text("Customize Poster", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                    decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 5))]),
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
                        
                        final schedHost = controller.posterHostDateTimeBlockUppercase();
                        final schedSlot = controller.posterFullWhenCaption(
                          controller.slotStart.value,
                          controller.slotEnd.value,
                        );
                        switch (widget.themeIndex) {
                          case 0: return PosterTheme.graduationTheme(
                            title: controller.title.value,
                            scheduleCaption: schedHost,
                            venue: controller.venue.value,
                            description: desc,
                            image: img,
                            logoImage: logo,
                            qrCodeImage: qrCode,
                          );
                          case 1: return PosterTheme.techTheme(
                            title: controller.title.value,
                            scheduleCaption: schedHost,
                            techTagline: controller.techTagline.value,
                            venue: controller.venue.value,
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
                            scheduleCaption: schedSlot,
                            venue: controller.venue.value,
                            coursePoints: controller.coursePoints.toList(),
                            phoneNumber: controller.phoneNumber.value,
                            image: img,
                            logoImage: logo,
                          );
                          case 3: return PosterTheme.musicFestivalTheme(
                            title: controller.title.value,
                            date: controller.posterDateRangeLine(),
                            venue: controller.venue.value,
                            startTime: controller.slotStart.value,
                            endTime: controller.slotEnd.value,
                            scheduleDetail: controller.posterSpansMultipleCalendarDays ? schedSlot : '',
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
                            startTime: controller.slotStart.value,
                            endTime: controller.slotEnd.value,
                            scheduleDetail: controller.posterSpansMultipleCalendarDays ? schedSlot : '',
                            description: desc,
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
                         maxLength: _PosterCopyLimits.basketballTitle, helperText: _PosterCopyLimits.basketballTitleGuidance),
                     SizedBox(height: 10.h),
                     
                     _buildTextField("Stadium Name", Icons.stadium, stadiumNameController, (v) => controller.stadiumName.value = v,
                         maxLength: _PosterCopyLimits.basketballStadium, helperText: _PosterCopyLimits.basketballStadiumGuidance),
                     SizedBox(height: 10.h),
                     
                     _buildTextField("Address", Icons.location_on, addressController, (v) => controller.address.value = v,
                         maxLength: _PosterCopyLimits.basketballAddress, helperText: _PosterCopyLimits.basketballAddressGuidance),
                     SizedBox(height: 10.h),
                     
                     Row(
                       children: [
                         Expanded(child: _buildPickerButton("Start Time", Icons.schedule, controller.slotStart, () => controller.pickSlotStart(context, compactHour: true))),
                         SizedBox(width: 10.w),
                         Expanded(child: _buildPickerButton("End Time", Icons.schedule, controller.slotEnd, () => controller.pickSlotEnd(context, compactHour: true))),
                       ],
                     ),
                     SizedBox(height: 10.h),

                     _buildTextField("Description (Optional)", Icons.description, descriptionController, (v) => controller.description.value = v,
                         maxLines: 3,
                         maxLength: _PosterCopyLimits.basketballDescription,
                         helperText: _PosterCopyLimits.basketballDescriptionGuidance),
                     SizedBox(height: 10.h),
                   ],
                   
                   // Music Festival Theme Fields
                   if (isMusicFestivalTheme) ...[
                     _buildTextField("Event Title", Icons.title, titleController, (v) => controller.title.value = v,
                         maxLength: _PosterCopyLimits.musicTitle, helperText: _PosterCopyLimits.musicTitleGuidance),
                     SizedBox(height: 10.h),
                     
                     _buildTextField("Venue", Icons.location_on, venueController, (v) => controller.venue.value = v,
                         maxLength: _PosterCopyLimits.musicVenue, helperText: _PosterCopyLimits.musicVenueGuidance),
                     SizedBox(height: 10.h),

                     _buildTextField("Description (Optional)", Icons.description, descriptionController, (v) => controller.description.value = v,
                         maxLines: 3,
                         maxLength: _PosterCopyLimits.musicDescription,
                         helperText: _PosterCopyLimits.musicDescriptionGuidance),
                     SizedBox(height: 10.h),
                     
                     Row(
                       children: [
                         Expanded(child: _buildPickerButton("Start Time", Icons.schedule, controller.slotStart, () => controller.pickSlotStart(context))),
                         SizedBox(width: 10.w),
                         Expanded(child: _buildPickerButton("End Time", Icons.schedule, controller.slotEnd, () => controller.pickSlotEnd(context))),
                       ],
                     ),
                     SizedBox(height: 10.h),
                   ],
                   
                   // Spoken English Theme Fields
                   if (isEnglishTheme) ...[
                     _buildTextField("Subtitle (e.g., Spoken English)", Icons.text_fields, subtitleController, (v) => controller.subtitle.value = v,
                         maxLength: _PosterCopyLimits.englishSubtitle, helperText: _PosterCopyLimits.subtitleGuidance),
                     SizedBox(height: 10.h),
                     
                     _buildTextField("Title (e.g., ONLINE COURSE)", Icons.title, titleController, (v) => controller.titleEnglish.value = v,
                         maxLength: _PosterCopyLimits.englishTitle, helperText: _PosterCopyLimits.englishTitleGuidance),
                     SizedBox(height: 10.h),

                     _buildTextField("Venue", Icons.location_on, venueController, (v) => controller.venue.value = v,
                         maxLength: _PosterCopyLimits.englishVenue, helperText: _PosterCopyLimits.englishVenueGuidance),
                     SizedBox(height: 10.h),
                     
                     _buildTimeRangeSelector(),
                     SizedBox(height: 10.h),
                     
                     _buildTextField("Phone Number", Icons.phone, phoneController, (v) => controller.phoneNumber.value = v,
                         maxLength: _PosterCopyLimits.phone, helperText: 'Keep short (max ${_PosterCopyLimits.phone} characters).'),
                     SizedBox(height: 10.h),
                     
                     _buildCoursePointsSection(),
                     SizedBox(height: 10.h),
                   ],

                   // Graduation — strict field limits + From/To times
                   if (isGraduationTheme) ...[
                     _buildTextField("Event Title", Icons.title, titleController, (v) => controller.title.value = v,
                         maxLength: _PosterCopyLimits.graduationTitle, helperText: _PosterCopyLimits.graduationTitleGuidance),
                     SizedBox(height: 10.h),
                     _buildTextField("Venue", Icons.location_on, venueController, (v) => controller.venue.value = v,
                         maxLength: _PosterCopyLimits.graduationVenue, helperText: _PosterCopyLimits.graduationVenueGuidance),
                     SizedBox(height: 10.h),
                     Row(
                       children: [
                         Expanded(
                           child: _buildPickerButton(
                             "From",
                             Icons.schedule,
                             controller.slotStart,
                             () => controller.pickSlotStart(context),
                           ),
                         ),
                         SizedBox(width: 10.w),
                         Expanded(
                           child: _buildPickerButton(
                             "To",
                             Icons.schedule,
                             controller.slotEnd,
                             () => controller.pickSlotEnd(context),
                           ),
                         ),
                       ],
                     ),
                     SizedBox(height: 10.h),
                     _buildTextField("Description (Optional)", Icons.description, descriptionController, (v) => controller.description.value = v,
                         maxLines: 3,
                         maxLength: _PosterCopyLimits.graduationDescription,
                         helperText: _PosterCopyLimits.graduationDescriptionGuidance),
                     SizedBox(height: 10.h),
                   ],

                   // Innovation & Technology — tagline, title, From/To times, mode, description, optional venue, trainer
                   if (isTechTheme) ...[
                     _buildTextField(
                       "Poster subtitle (e.g. Let's talk about the future)",
                       Icons.short_text_rounded,
                       techTaglineController,
                       (v) => controller.techTagline.value = v,
                       maxLength: PosterController.kTechTaglineMaxLength,
                       helperText: _PosterCopyLimits.techTaglineGuidance,
                     ),
                     SizedBox(height: 10.h),
                     _buildTextField("Event Title", Icons.title, titleController, (v) => controller.title.value = v,
                         maxLength: _PosterCopyLimits.techTitle, helperText: _PosterCopyLimits.techTitleGuidance),
                     SizedBox(height: 10.h),
                     Row(
                       children: [
                         Expanded(
                           child: _buildPickerButton(
                             "From",
                             Icons.schedule,
                             controller.slotStart,
                             () => controller.pickSlotStart(context),
                           ),
                         ),
                         SizedBox(width: 10.w),
                         Expanded(
                           child: _buildPickerButton(
                             "To",
                             Icons.schedule,
                             controller.slotEnd,
                             () => controller.pickSlotEnd(context),
                           ),
                         ),
                       ],
                     ),
                     SizedBox(height: 10.h),
                     _buildModeSelector(),
                     SizedBox(height: 10.h),
                     _buildTextField("Description (Optional)", Icons.description, descriptionController, (v) => controller.description.value = v,
                         maxLines: 3,
                         maxLength: _PosterCopyLimits.techDescription,
                         helperText: _PosterCopyLimits.techDescriptionGuidance),
                     SizedBox(height: 10.h),
                     Obx(() {
                       if (controller.mode.value != "Offline") return const SizedBox.shrink();
                       return Column(
                         crossAxisAlignment: CrossAxisAlignment.stretch,
                         children: [
                           _buildTextField("Venue", Icons.location_on, venueController, (v) => controller.venue.value = v,
                               maxLength: _PosterCopyLimits.venue, helperText: _PosterCopyLimits.venueGuidance),
                           SizedBox(height: 10.h),
                         ],
                       );
                     }),
                   ],
                   
                   // Description Field (Music Festival only — grad/tech/English use their own blocks)
                   if (isMusicFestivalTheme) ...[
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
        padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 15.w),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))]),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                margin: EdgeInsets.only(bottom: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5F15).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF5F15).withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18.sp, color: const Color(0xFFFF5F15)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Keep posters within 3 MB. The app auto-compresses when you tap USE THIS POSTER or JPG.',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
            children: [
              _buildMiniButton(Icons.picture_as_pdf, "PDF", () {
                _clampAllPosterInputsToLimits(syncToRx: true);
                controller.downloadPdf(_boundaryKey);
              }),
              SizedBox(width: 10.w),
              _buildMiniButton(Icons.image, "JPG", () {
                _clampAllPosterInputsToLimits(syncToRx: true);
                controller.downloadImage(_boundaryKey);
              }),
              SizedBox(width: 10.w),
              
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : () async {
                    setState(() => _isProcessing = true);
                    _clampAllPosterInputsToLimits(syncToRx: true);
                    final scaffoldContext = context;
                    File? posterFile = await controller.saveForEvent(_boundaryKey);
                    if (!scaffoldContext.mounted) return;
                    setState(() => _isProcessing = false);

                    if (posterFile != null) {
                      final sizeErr = await UploadFileValidators.posterSizeError(posterFile);
                      if (sizeErr != null) {
                        if (!scaffoldContext.mounted) return;
                        SweetAlertHelper.showError(scaffoldContext, 'Poster too large', sizeErr);
                        return;
                      }
                      if (controller.posterStartDate.value == null) {
                        SweetAlertHelper.showError(scaffoldContext, "Required", "Please choose a start date.");
                        setState(() => _isProcessing = false);
                        return;
                      }
                      final startTimeRaw = _posterSaveStartTimeRaw();
                      final endTimeRaw = _posterSaveEndTimeRaw();
                      if (isGraduationTheme || isTechTheme) {
                        if (_parseTimeForPoster(startTimeRaw) == null || _parseTimeForPoster(endTimeRaw) == null) {
                          SweetAlertHelper.showError(scaffoldContext, "Required", "Please set valid start and end times.");
                          setState(() => _isProcessing = false);
                          return;
                        }
                      } else if (!isEnglishTheme && !isMusicFestivalTheme && !isBasketballTheme &&
                          controller.timeStr.value.toUpperCase() == 'TIME') {
                        SweetAlertHelper.showError(scaffoldContext, "Required", "Please set the event time.");
                        setState(() => _isProcessing = false);
                        return;
                      }
                      final startIso = controller.posterEventStartDateTimeIso(startTimeRaw);
                      final endIso = controller.posterEventEndDateTimeIso(endTimeRaw);
                      if (endIso != null && startIso != null) {
                        final a = DateTime.tryParse(startIso.replaceAll(' ', 'T'));
                        final b = DateTime.tryParse(endIso.replaceAll(' ', 'T'));
                        if (a != null && b != null && b.isBefore(a)) {
                          SweetAlertHelper.showError(
                            scaffoldContext,
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
                      SweetAlertHelper.showError(scaffoldContext, "Error", "Failed to generate poster");
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
    final String msg;
    if (isGraduationTheme) {
      msg =
          'Graduation poster: title max ${_PosterCopyLimits.graduationTitle} characters, '
          'description max ${_PosterCopyLimits.graduationDescription}, venue max ${_PosterCopyLimits.graduationVenue}. '
          'Times show as From / To on the card, like dates.';
    } else if (isTechTheme) {
      msg =
          'Innovation & Technology poster: title max ${_PosterCopyLimits.techTitle} characters, '
          'description max ${_PosterCopyLimits.techDescription}, '
          'subtitle max ${PosterController.kTechTaglineMaxLength} characters. '
          'Times show as From / To on the card, like dates.';
    } else if (isEnglishTheme) {
      msg =
          'Spoken English poster: subtitle max ${_PosterCopyLimits.englishSubtitle} characters, '
          'title max ${_PosterCopyLimits.englishTitle} characters.';
    } else if (isMusicFestivalTheme) {
      msg =
          'Music festival poster: title max ${_PosterCopyLimits.musicTitle} characters, '
          'venue max ${_PosterCopyLimits.musicVenue}, description max ${_PosterCopyLimits.musicDescription}.';
    } else if (isBasketballTheme) {
      msg =
          'Basketball poster: title max ${_PosterCopyLimits.basketballTitle} characters, '
          'stadium max ${_PosterCopyLimits.basketballStadium}, address max ${_PosterCopyLimits.basketballAddress}.';
    } else {
      msg =
          'Posters use large text in fixed areas. Use the limits under each field — '
          'about ${_PosterCopyLimits.title} characters for titles and ${_PosterCopyLimits.description} for descriptions — '
          'so nothing runs past the design or overlaps other lines.';
    }
    final sizeNote =
        ' Upload size must stay within 3 MB; the app auto-compresses when you save.';
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
              '$msg$sizeNote',
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
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      inputFormatters: maxLength != null ? [LengthLimitingTextInputFormatter(maxLength)] : null,
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
          const Icon(Icons.settings, size: 18, color: Colors.orange),
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
    if (isEnglishTheme || isMusicFestivalTheme || isBasketballTheme ||
        isGraduationTheme || isTechTheme) {
      return controller.slotStart.value;
    }
    return controller.timeStr.value;
  }

  String _posterSaveEndTimeRaw() {
    if (isEnglishTheme || isMusicFestivalTheme || isBasketballTheme ||
        isGraduationTheme || isTechTheme) {
      return controller.slotEnd.value;
    }
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
                const Icon(Icons.calendar_today, size: 18, color: Colors.orange),
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
                    const Icon(Icons.event, color: Colors.orange, size: 20),
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
              const Icon(Icons.access_time, size: 18, color: Colors.orange),
              SizedBox(width: 8.w),
              Text("Time Duration:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: controller.slotStart.value),
                  decoration: const InputDecoration(
                    labelText: "Start Time (e.g., 08 AM)",
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => controller.slotStart.value = val,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: controller.slotEnd.value),
                  decoration: const InputDecoration(
                    labelText: "End Time (e.g., 2 PM)",
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => controller.slotEnd.value = val,
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
              const Icon(Icons.checklist, size: 18, color: Colors.orange),
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
          }),
          
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