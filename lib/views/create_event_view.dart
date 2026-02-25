import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../controllers/event_controller.dart';
import 'template_gallery_view.dart'; 
import 'home_view.dart';

class CreateEventView extends StatefulWidget {
  final dynamic existingEvent; // if provided => edit (pending) mode
  const CreateEventView({super.key, this.existingEvent});

  @override
  State<CreateEventView> createState() => CreateEventViewState();
}

class CreateEventViewState extends State<CreateEventView> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final venueCtrl = TextEditingController();
  String selectedCategory = "IT/Tech";
  File? selectedImage;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final List<String> categories = ["IT/Tech", "Cultural", "Sports", "Academic", "Social"];

  final EventController controller = Get.find<EventController>();
  String? _existingBannerName;
  bool _removeExistingBanner = false;

  @override
  void initState() {
    super.initState();
    Get.put(this);

    // Prefill fields when editing an existing (pending) event
    final e = widget.existingEvent;
    if (e is Map) {
      titleCtrl.text = (e['title'] ?? '').toString();
      descCtrl.text = (e['description'] ?? '').toString();
      venueCtrl.text = (e['venue'] ?? '').toString();

      final cat = (e['category'] ?? '').toString();
      if (cat.isNotEmpty && categories.contains(cat)) {
        selectedCategory = cat;
      }

      final rawDate = (e['event_date'] ?? '').toString();
      if (rawDate.isNotEmpty) {
        dateCtrl.text = rawDate;
        final parsed = DateTime.tryParse(rawDate.replaceAll(' ', 'T'));
        if (parsed != null) {
          selectedDate = DateTime(parsed.year, parsed.month, parsed.day);
          selectedTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
        }
      }

      final banners = e['banners'];
      if (banners is List && banners.isNotEmpty) {
        _existingBannerName = banners.first.toString();
      }
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    dateCtrl.dispose();
    venueCtrl.dispose();
    Get.delete<CreateEventViewState>();
    super.dispose();
  }

  void updateSelectedImage(File file) {
    setState(() {
      selectedImage = file;
    });
  }

  Future<void> _pickFromGallery() async {
    final XFile? img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (img != null) {
      setState(() => selectedImage = File(img.path));
    }
  }

  // FIXED: Navigate to template gallery and wait for result
  Future<void> _openPosterDesigner() async {
    final File? posterFile = await Get.to(() => const TemplateGalleryView());
    
    if (posterFile != null) {
      setState(() {
        selectedImage = posterFile;
      });
      
      Get.snackbar(
        "Success",
        "Poster added successfully!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    }
  }

  void _publishEvent() async {
    if (!_validateForm()) return;

    final isEdit = widget.existingEvent != null;
    final success = isEdit
        ? await controller.replacePendingHostedEvent(
            oldEvent: widget.existingEvent,
            title: titleCtrl.text.trim(),
            desc: descCtrl.text.trim(),
            date: dateCtrl.text.trim(),
            category: selectedCategory,
            venue: venueCtrl.text.trim(),
            newBanner: selectedImage,
            existingBannerName:
                _removeExistingBanner ? null : _existingBannerName,
          )
        : await controller.createEvent(
            titleCtrl.text.trim(),
            descCtrl.text.trim(),
            dateCtrl.text.trim(),
            selectedCategory,
            venueCtrl.text.trim(),
            selectedImage,
          );

    if (success) {
      // Show success message
      Get.snackbar(
        "Success",
        isEdit
            ? "Event updated successfully (pending)."
            : "Event creation successful, please wait for admin to approve.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: EdgeInsets.all(15.w),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      // Navigate back (edit) or to Home (create)
      Future.delayed(const Duration(seconds: 1), () {
        if (isEdit) {
          // Redirect to My Events -> Hosting
          Get.offAll(() => const HomeView(
                initialBottomTabIndex: 1,
                initialMyEventsTabIndex: 1,
              ));
        } else {
          Get.offAll(() => const HomeView());
        }
      });
    } else {
      Get.snackbar(
        "Error",
        isEdit ? "Failed to update event. Please try again." : "Failed to create event. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  bool _validateForm() {
    if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty || selectedDate == null || selectedTime == null || venueCtrl.text.trim().isEmpty) {
      Get.snackbar("Required", "Please fill all fields", backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingEvent != null;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isEdit ? "Edit Pending Event" : "Host an Event",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFFF5F15),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Event Banner",
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openPosterDesigner, // FIXED: Now properly handles result
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text("Design Poster"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF5F15),
                      side: const BorderSide(color: Color(0xFFFF5F15)),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload Own"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15.h),
            
            Container(
              height: 350.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey[200],
                border: Border.all(
                  color: const Color(0xFFFF5F15).withOpacity(0.3),
                  width: 2.5,
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: selectedImage != null
                        ? Image.file(
                            selectedImage!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : (_existingBannerName != null && !_removeExistingBanner)
                            ? Image.network(
                                "https://exdeos.com/AS/campus_social/uploads/events/$_existingBannerName",
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) => _buildEmptyBanner(),
                              )
                            : _buildEmptyBanner(),
                  ),
                  if (selectedImage != null ||
                      (_existingBannerName != null && !_removeExistingBanner))
                    Positioned(
                      top: 10,
                      right: 5,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          if (selectedImage != null) {
                            selectedImage = null;
                          } else {
                            _removeExistingBanner = true;
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child:
                              const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 25.h),

            _buildSection("Event Title", "What's the name of your event?", titleCtrl, Icons.event_outlined, TextInputType.text),
            SizedBox(height: 20.h),

            Text("Category", style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
            SizedBox(height: 8.h),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFFFF5F15)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => selectedCategory = val!),
            ),

            SizedBox(height: 20.h),
            _buildDateTimeSection(),
            SizedBox(height: 20.h),
            _buildSection("Venue/Location", "Where will the event be held?", venueCtrl, Icons.location_on_outlined, TextInputType.text),
            SizedBox(height: 20.h),

            Text("Description", style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
            SizedBox(height: 8.h),
            TextField(
              controller: descCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Tell students about your event...",
                prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFFFF5F15)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            SizedBox(height: 40.h),

            Obx(() => controller.isLoading.value
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5F15)))
                : ElevatedButton(
                    onPressed: _publishEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5F15),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Center(
                        child: Text(
                          isEdit ? "Save Changes" : "Publish Event",
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBanner() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 40, color: Colors.grey[400]),
          SizedBox(height: 8.h),
          Text(
            "No banner selected",
            style: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
          ),
        ],
      );

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Date & Time", style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFFFF5F15), size: 20),
                      SizedBox(width: 12.w),
                      Text(selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : "Select Date"),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: GestureDetector(
                onTap: _selectTime,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFFFF5F15), size: 20),
                      SizedBox(width: 12.w),
                      Text(selectedTime != null ? selectedTime!.format(context) : "Select Time"),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
    if (picked != null) setState(() { selectedDate = picked; _updateDateTimeController(); });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() { selectedTime = picked; _updateDateTimeController(); });
  }

  void _updateDateTimeController() {
    if (selectedDate != null && selectedTime != null) {
      final DateTime fullDateTime = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, selectedTime!.hour, selectedTime!.minute);
      dateCtrl.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(fullDateTime);
    }
  }

  Widget _buildSection(String label, String hint, TextEditingController ctrl, IconData icon, TextInputType inputType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
        SizedBox(height: 8.h),
        TextField(
          controller: ctrl,
          keyboardType: inputType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFFFF5F15)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}