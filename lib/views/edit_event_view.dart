import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../controllers/event_controller.dart';
import '../utils/sweetalert_helper.dart';
import '../utils/upload_file_validators.dart';
import '../widgets/app_bar_title_with_brand_logo.dart';
import 'template_gallery_view.dart';
import '../widgets/app_calendar_theme.dart';
import '../widgets/app_network_image.dart';
import '../base/constant.dart';

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
  late TextEditingController rulesCtrl;
  late TextEditingController dateCtrl;
  late TextEditingController venueCtrl;
  late String selectedCategory;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  DateTime? selectedEndDate;
  TimeOfDay? selectedEndTime;
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
    rulesCtrl = TextEditingController(text: (e['rules'] ?? '').toString());
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
    final rawEndDate = (e['event_end_date'] ?? '').toString();
    if (rawEndDate.isNotEmpty && rawEndDate != '0000-00-00 00:00:00') {
      final parsedEnd = DateTime.tryParse(rawEndDate.replaceAll(' ', 'T'));
      if (parsedEnd != null) {
        selectedEndDate = DateTime(parsedEnd.year, parsedEnd.month, parsedEnd.day);
        selectedEndTime = TimeOfDay(hour: parsedEnd.hour, minute: parsedEnd.minute);
      }
    }
    final banners = e['banners'];
    if (banners is List && banners.isNotEmpty) {
      _existingBannerName = banners.first.toString();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final raw = (widget.event['event_date'] ?? '').toString();
      if (raw.isEmpty) return;
      final parsed = DateTime.tryParse(raw.replaceAll(' ', 'T'));
      if (parsed == null) return;
      final eventDay = DateTime(parsed.year, parsed.month, parsed.day);
      final n = DateTime.now();
      final today = DateTime(n.year, n.month, n.day);
      if (!today.isBefore(eventDay) && mounted) {
        Get.back();
        SweetAlertHelper.showInfo(Get.context, 'Cannot edit', 'This event can no longer be edited.');
      }
    });
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    rulesCtrl.dispose();
    dateCtrl.dispose();
    venueCtrl.dispose();
    super.dispose();
  }

  Future<bool> _acceptPosterIfAllowed(File file) async {
    final err = await UploadFileValidators.posterSizeError(file);
    if (err != null) {
      if (mounted) {
        SweetAlertHelper.showError(context, 'Poster too large', err);
      }
      return false;
    }
    return true;
  }

  Future<void> _pickFromGallery() async {
    final XFile? img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null) return;
    final file = File(img.path);
    if (!await _acceptPosterIfAllowed(file)) return;
    if (!mounted) return;
    setState(() => selectedImage = file);
  }

  Future<void> _openPosterDesigner() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Event poster',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Use a design template or upload your own poster '
                  '(≤5MB, ≤1080×1920 px).',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'template'),
                  icon: const Icon(Icons.palette_outlined),
                  label: const Text('Use Template'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5F15),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
                SizedBox(height: 12.h),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'upload'),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Own'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF5F15),
                    side: const BorderSide(color: Color(0xFFFF5F15)),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || choice == null) return;
    if (choice == 'upload') {
      await _pickFromGallery();
      return;
    }

    final result = await Get.to(() => const TemplateGalleryView());
    if (result == null || !mounted) return;
    if (result is Map<String, dynamic>) {
      final file = result['file'];
      if (file is File) {
        if (!await _acceptPosterIfAllowed(file)) return;
        if (!mounted) return;
        setState(() => selectedImage = file);
      }
    } else if (result is File) {
      if (!await _acceptPosterIfAllowed(result)) return;
      if (!mounted) return;
      setState(() => selectedImage = result);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (ctx, child) => AppCalendarTheme.wrap(ctx, child),
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

  Future<void> _selectEndDate() async {
    final DateTime firstAllowed = selectedDate ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedEndDate ?? firstAllowed,
      firstDate: firstAllowed,
      lastDate: DateTime(2100),
      builder: (ctx, child) => AppCalendarTheme.wrap(ctx, child),
    );
    if (picked != null) setState(() => selectedEndDate = picked);
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedEndTime ?? TimeOfDay.now());
    if (picked != null) setState(() => selectedEndTime = picked);
  }

  void _updateDateTimeController() {
    if (selectedDate != null && selectedTime != null) {
      final full = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, selectedTime!.hour, selectedTime!.minute);
      dateCtrl.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(full);
    }
  }

  String? _buildEndDateString() {
    if (selectedEndDate == null) return null;
    final endTime = selectedEndTime ?? const TimeOfDay(hour: 23, minute: 59);
    final full = DateTime(selectedEndDate!.year, selectedEndDate!.month, selectedEndDate!.day, endTime.hour, endTime.minute);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(full);
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
    if (selectedEndDate != null) {
      final startDt = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, selectedTime!.hour, selectedTime!.minute);
      final endTime = selectedEndTime ?? const TimeOfDay(hour: 23, minute: 59);
      final endDt = DateTime(selectedEndDate!.year, selectedEndDate!.month, selectedEndDate!.day, endTime.hour, endTime.minute);
      if (endDt.isBefore(startDt)) {
        SweetAlertHelper.showError(context, "Invalid Date", "End date must be on or after the start date.");
        return false;
      }
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
      final sizeErr = await UploadFileValidators.posterSizeError(selectedImage!);
      if (sizeErr != null) {
        if (!mounted) return;
        SweetAlertHelper.showError(context, 'Poster too large', sizeErr);
        return;
      }
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
      rules: rulesCtrl.text.trim(),
      eventEndDate: _buildEndDateString(),
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
        title: const AppBarTitleWithBrandLogo(
          onPrimaryBackground: true,
          title: Text("Edit Event", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
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
                border: Border.all(color: const Color(0xFFFF5F15).withValues(alpha: 0.3), width: 2.5),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: selectedImage != null
                        ? Image.file(selectedImage!, fit: BoxFit.contain, width: double.infinity, height: double.infinity)
                        : (_existingBannerName != null && !_removeExistingBanner)
                            ? AppNetworkImage(
                                url: "${Constant.uploadsBaseUrl}events/$_existingBannerName",
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorWidget: (_, __, ___) => _buildEmptyBanner(),
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
            Text("From (Start)", style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                          Expanded(child: Text(selectedDate != null ? DateFormat('dd MMM yyyy').format(selectedDate!) : "Start Date", overflow: TextOverflow.ellipsis)),
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
                          Expanded(child: Text(selectedTime != null ? selectedTime!.format(context) : "Start Time", overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(child: Text("To (End) — Optional", style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black87))),
                if (selectedEndDate != null)
                  GestureDetector(
                    onTap: () => setState(() { selectedEndDate = null; selectedEndTime = null; }),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 16, color: Colors.red[400]),
                        SizedBox(width: 4.w),
                        Text("Clear", style: TextStyle(fontSize: 12.sp, color: Colors.red[400])),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectEndDate,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                      decoration: BoxDecoration(
                        border: Border.all(color: selectedEndDate != null ? Colors.grey[300]! : Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(12),
                        color: selectedEndDate != null ? null : Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: selectedEndDate != null ? const Color(0xFFFF5F15) : Colors.grey[400], size: 20),
                          SizedBox(width: 12.w),
                          Expanded(child: Text(
                            selectedEndDate != null ? DateFormat('dd MMM yyyy').format(selectedEndDate!) : "End Date",
                            style: TextStyle(color: selectedEndDate != null ? Colors.black87 : Colors.grey[500]),
                            overflow: TextOverflow.ellipsis,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: GestureDetector(
                    onTap: selectedEndDate != null ? _selectEndTime : null,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                      decoration: BoxDecoration(
                        border: Border.all(color: selectedEndDate != null ? Colors.grey[300]! : Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(12),
                        color: selectedEndDate != null ? null : Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: selectedEndDate != null ? const Color(0xFFFF5F15) : Colors.grey[400], size: 20),
                          SizedBox(width: 12.w),
                          Expanded(child: Text(
                            selectedEndTime != null ? selectedEndTime!.format(context) : "End Time",
                            style: TextStyle(color: selectedEndTime != null ? Colors.black87 : Colors.grey[500]),
                            overflow: TextOverflow.ellipsis,
                          )),
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
            SizedBox(height: 20.h),
            Text("Event rules", style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
            SizedBox(height: 8.h),
            TextField(
              controller: rulesCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Rules, eligibility, dress code...",
                prefixIcon: const Icon(Icons.gavel_outlined, color: Color(0xFFFF5F15)),
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
