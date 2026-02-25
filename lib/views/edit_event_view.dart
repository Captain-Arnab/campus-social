import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../controllers/event_controller.dart';
import '../utils/sweetalert_helper.dart';
import 'template_gallery_view.dart';

/// Full edit form for an approved event (organizer or editor). Same fields as create: banner, title, category, date, venue, description.
class EditEventView extends StatefulWidget {
  final dynamic event;

  const EditEventView({super.key, required this.event});

  @override
  State<EditEventView> createState() => _EditEventViewState();
}

class _EditEventViewState extends State<EditEventView> {
  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;
  late TextEditingController dateCtrl;
  late TextEditingController venueCtrl;
  late String selectedCategory;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  File? selectedImage;
  String? _existingBannerName;
  bool _removeExistingBanner = false;
  final List<String> categories = ["IT/Tech", "Cultural", "Sports", "Academic", "Social"];
  final EventController controller = Get.find<EventController>();

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    titleCtrl = TextEditingController(text: (e['title'] ?? '').toString());
    descCtrl = TextEditingController(text: (e['description'] ?? '').toString());
    venueCtrl = TextEditingController(text: (e['venue'] ?? '').toString());
    dateCtrl = TextEditingController();
    selectedCategory = (e['category'] ?? 'IT/Tech').toString();
    if (!categories.contains(selectedCategory)) selectedCategory = categories.first;
    final rawDate = (e['event_date'] ?? '').toString();
    if (rawDate.isNotEmpty) {
      final parsed = DateTime.tryParse(rawDate.replaceAll(' ', 'T'));
      if (parsed != null) {
        selectedDate = DateTime(parsed.year, parsed.month, parsed.day);
        selectedTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
        dateCtrl.text = rawDate;
      }
    }
    final banners = e['banners'];
    if (banners is List && banners.isNotEmpty) {
      _existingBannerName = banners.first.toString();
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    dateCtrl.dispose();
    venueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final XFile? img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => selectedImage = File(img.path));
  }

  Future<void> _openPosterDesigner() async {
    final File? posterFile = await Get.to(() => const TemplateGalleryView());
    if (posterFile != null) setState(() => selectedImage = posterFile);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
      _updateDateTimeController();
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedTime ?? TimeOfDay.now());
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        _updateDateTimeController();
      });
    }
  }

  void _updateDateTimeController() {
    if (selectedDate != null && selectedTime != null) {
      final full = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, selectedTime!.hour, selectedTime!.minute);
      dateCtrl.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(full);
    }
  }

  bool _validateForm() {
    if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty || venueCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(context, "Required", "Please fill title, description and venue.");
      return false;
    }
    if (selectedDate == null || selectedTime == null) {
      SweetAlertHelper.showError(context, "Required", "Please set date and time.");
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validateForm()) return;
    _updateDateTimeController();
    final dateStr = dateCtrl.text.trim();
    if (dateStr.isEmpty) {
      SweetAlertHelper.showError(context, "Required", "Please set date and time.");
      return;
    }
    List<File>? bannerFiles;
    if (selectedImage != null) {
      bannerFiles = [selectedImage!];
    }
    final success = await controller.updateApprovedEventWithFormData(
      event: widget.event,
      title: titleCtrl.text.trim(),
      description: descCtrl.text.trim(),
      venue: venueCtrl.text.trim(),
      eventDate: dateStr,
      category: selectedCategory,
      bannerFiles: bannerFiles,
    );
    if (success && mounted) {
      SweetAlertHelper.showSuccess(
        context,
        "Success",
        "Changes saved successfully.",
        onConfirm: () {
          if (mounted) Get.back();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Edit Event", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFFF5F15),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Get.back()),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Event Banner", style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openPosterDesigner,
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
                border: Border.all(color: const Color(0xFFFF5F15).withOpacity(0.3), width: 2.5),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: selectedImage != null
                        ? Image.file(selectedImage!, fit: BoxFit.contain, width: double.infinity, height: double.infinity)
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
                  if (selectedImage != null || (_existingBannerName != null && !_removeExistingBanner))
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
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
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
            Text("Date & Time", style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
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
            Obx(
              () => controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5F15)))
                  : ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5F15),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Center(child: Text("Save changes", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold))),
                      ),
                    ),
            ),
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
          Text("No banner selected", style: TextStyle(color: Colors.grey[500], fontSize: 14.sp)),
        ],
      );

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
