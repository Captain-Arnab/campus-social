import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/poster_controller.dart';
import '../utils/sweetalert_helper.dart';
import '../widgets/poster_themes.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        toolbarHeight: 30.h,
        title: const Text("Customize Poster", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                            date: controller.dateStr.value, 
                            venue: controller.venue.value, 
                            time: controller.timeStr.value,
                            description: desc,
                            image: img,
                            logoImage: logo,
                            qrCodeImage: qrCode,
                          );
                          case 1: return PosterTheme.techTheme(
                            title: controller.title.value, 
                            date: controller.dateStr.value, 
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
                            startDay: controller.startDay.value,
                            endDay: controller.endDay.value,
                            startTime: controller.startTime.value,
                            endTime: controller.endTime.value,
                            coursePoints: controller.coursePoints.toList(),
                            phoneNumber: controller.phoneNumber.value,
                            image: img,
                            logoImage: logo,
                          );
                          case 3: return PosterTheme.musicFestivalTheme(
                            title: controller.title.value,
                            date: controller.dateStr.value,
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
                            date: controller.dateStr.value,
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
                   // Basketball Theme Fields
                   if (isBasketballTheme) ...[
                     _buildTextField("Event Title", Icons.title, titleController, (v) => controller.title.value = v),
                     SizedBox(height: 10.h),
                     
                     _buildTextField("Stadium Name", Icons.stadium, stadiumNameController, (v) => controller.stadiumName.value = v),
                     SizedBox(height: 10.h),
                     
                     _buildTextField("Address", Icons.location_on, addressController, (v) => controller.address.value = v),
                     SizedBox(height: 10.h),
                     
                     _buildPickerButton("Date", Icons.calendar_today, controller.dateStr, () => controller.pickBasketballDate(context)),
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
                     _buildTextField("Event Title", Icons.title, titleController, (v) => controller.title.value = v),
                     SizedBox(height: 10.h),
                     
                     _buildPickerButton("Date", Icons.calendar_today, controller.dateStr, () => controller.pickDate(context)),
                     SizedBox(height: 10.h),
                     
                     _buildTextField("Location", Icons.location_on, locationController, (v) => controller.location.value = v),
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
                     _buildTextField("Subtitle (e.g., Spoken English)", Icons.text_fields, subtitleController, (v) => controller.subtitle.value = v),
                     SizedBox(height: 10.h),
                     
                     _buildTextField("Title (e.g., ONLINE COURSE)", Icons.title, titleController, (v) => controller.titleEnglish.value = v),
                     SizedBox(height: 10.h),
                     
                     _buildDaySelector(),
                     SizedBox(height: 10.h),
                     
                     _buildTimeRangeSelector(),
                     SizedBox(height: 10.h),
                     
                     _buildTextField("Phone Number", Icons.phone, phoneController, (v) => controller.phoneNumber.value = v),
                     SizedBox(height: 10.h),
                     
                     _buildCoursePointsSection(),
                     SizedBox(height: 10.h),
                   ],
                   
                   // Title Field (for non-English, non-Music Festival, and non-Basketball themes)
                   if (!isEnglishTheme && !isMusicFestivalTheme && !isBasketballTheme) ...[
                     _buildTextField("Event Title", Icons.title, titleController, (v) => controller.title.value = v),
                     SizedBox(height: 10.h),
                   ],
                   
                   // Date & Time Row (for non-English, non-Music Festival, and non-Basketball themes)
                   if (!isEnglishTheme && !isMusicFestivalTheme && !isBasketballTheme) ...[
                     Row(children: [
                       Expanded(child: _buildPickerButton("Date", Icons.calendar_today, controller.dateStr, () => controller.pickDate(context))),
                       SizedBox(width: 10.w),
                       Expanded(child: _buildPickerButton("Time", Icons.schedule, controller.timeStr, () => controller.pickTime(context))),
                     ]),
                     SizedBox(height: 10.h),
                   ],
                   
                   // Mode Selector (Only for Tech Theme)
                   if (isTechTheme) ...[
                     _buildModeSelector(),
                     SizedBox(height: 10.h),
                   ],
                   
                   // Venue Field (Hidden for Tech Online mode, English theme, Music Festival theme, and Basketball theme)
                   if (!isEnglishTheme && !isMusicFestivalTheme && !isBasketballTheme && (!isTechTheme || controller.mode.value == "Offline")) ...[
                     _buildTextField("Venue", Icons.location_on, venueController, (v) => controller.venue.value = v),
                     SizedBox(height: 10.h),
                   ],
                   
                   // Description Field (for non-English themes)
                   if (!isEnglishTheme && !isBasketballTheme) ...[
                     _buildTextField("Description (Optional)", Icons.description, descriptionController, (v) => controller.description.value = v, maxLines: 3),
                     SizedBox(height: 10.h),
                   ],
                   
                   // Trainer Name (Only for Tech Theme)
                   if (isTechTheme) ...[
                     _buildTextField("Trainer Name (Optional)", Icons.person, trainerNameController, (v) => controller.trainerName.value = v),
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
                      Get.back(result: posterFile); 
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

  Widget _buildTextField(String label, IconData icon, TextEditingController textController, Function(String) onChanged, {int maxLines = 1}) {
    return TextField(
      controller: textController,
      onChanged: onChanged,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
        contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
        filled: true, 
        fillColor: Colors.white
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

  Widget _buildDaySelector() {
    final days = ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"];
    
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
              Icon(Icons.calendar_today, size: 18, color: Colors.orange),
              SizedBox(width: 8.w),
              Text("Schedule Days:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: controller.startDay.value,
                  decoration: const InputDecoration(
                    labelText: "From",
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: days.map((day) => DropdownMenuItem(value: day, child: Text(day, style: TextStyle(fontSize: 11.sp)))).toList(),
                  onChanged: (val) => controller.startDay.value = val!,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: controller.endDay.value,
                  decoration: const InputDecoration(
                    labelText: "To",
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: days.map((day) => DropdownMenuItem(value: day, child: Text(day, style: TextStyle(fontSize: 11.sp)))).toList(),
                  onChanged: (val) => controller.endDay.value = val!,
                ),
              ),
            ],
          ),
        ],
      ),
    ));
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