import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../controllers/event_controller.dart';
import '../data/app_bootstrap.dart';
import '../utils/sweetalert_helper.dart';
import '../utils/upload_file_validators.dart';
import 'template_gallery_view.dart';
import '../utils/app_navigation.dart';
import 'bootstrap_views.dart';
import '../widgets/app_calendar_theme.dart';
import '../widgets/app_network_image.dart';
import '../widgets/campus_app_bar.dart';
import '../theme/app_theme.dart';
import '../base/constant.dart';

class CreateEventView extends StatefulWidget {
  final dynamic existingEvent; // if provided => edit (pending) mode
  const CreateEventView({super.key, this.existingEvent});

  @override
  State<CreateEventView> createState() => CreateEventViewState();
}

class CreateEventViewState extends State<CreateEventView> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final rulesCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final venueCtrl = TextEditingController();
  String selectedCategory = "IT/Tech";
  File? selectedImage;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  DateTime? selectedEndDate;
  TimeOfDay? selectedEndTime;
  final List<String> categories = ["IT/Tech", "Cultural", "Sports", "Academic", "Social"];

  late final EventController controller;
  String? _existingBannerName;
  bool _removeExistingBanner = false;

  @override
  void initState() {
    super.initState();
    controller = AppBootstrap.ensureEventController();
    Get.put(this);

    // Prefill fields when editing an existing (pending) event
    final e = widget.existingEvent;
    if (e is Map) {
      titleCtrl.text = (e['title'] ?? '').toString();
      descCtrl.text = (e['description'] ?? '').toString();
      rulesCtrl.text = (e['rules'] ?? '').toString();
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
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    rulesCtrl.dispose();
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
    final XFile? img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
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
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Event poster',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.h),
                Text(
                  'Use a design template or upload your own poster '
                  '(≤5MB, ≤1080×1920 px).',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'template'),
                  icon: const Icon(Icons.palette_outlined),
                  label: const Text('Use Template'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_fieldRadius),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'upload'),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Own'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_fieldRadius),
                    ),
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

    if (!mounted || result == null) return;

    // result can be a Map (new flow with prefill data) or a File (legacy)
    if (result is Map<String, dynamic>) {
      final file = result['file'];
      if (file is File) {
        if (!await _acceptPosterIfAllowed(file)) return;
        if (!mounted) return;
        setState(() {
          selectedImage = file;
          _prefillFromPosterData(result);
        });
        SweetAlertHelper.showSuccess(context, "Success", "Poster & event details applied!");
      } else {
        setState(() => _prefillFromPosterData(result));
      }
    } else if (result is File) {
      if (!await _acceptPosterIfAllowed(result)) return;
      if (!mounted) return;
      setState(() => selectedImage = result);
      SweetAlertHelper.showSuccess(context, "Success", "Poster added successfully!");
    }
  }

  void _prefillFromPosterData(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString().trim();
    if (title.isNotEmpty && _isUserFilled(title)) {
      titleCtrl.text = title;
    }

    final description = (data['description'] ?? '').toString().trim();
    if (description.isNotEmpty && _isUserFilled(description)) {
      descCtrl.text = description;
    }

    final venue = (data['venue'] ?? '').toString().trim();
    if (venue.isNotEmpty && _isUserFilled(venue)) {
      venueCtrl.text = venue;
    }

    final category = (data['category'] ?? '').toString().trim();
    if (category.isNotEmpty && categories.contains(category)) {
      selectedCategory = category;
    }

    final dateRaw = (data['date'] ?? '').toString().trim();
    final timeRaw = (data['time'] ?? '').toString().trim();
    _applyPosterDateTime(dateRaw, timeRaw);

    final endRaw = (data['event_end_date'] ?? '').toString().trim();
    if (endRaw.isNotEmpty) {
      final parsedEnd = DateTime.tryParse(endRaw.replaceAll(' ', 'T'));
      if (parsedEnd != null) {
        selectedEndDate = DateTime(parsedEnd.year, parsedEnd.month, parsedEnd.day);
        selectedEndTime = TimeOfDay(hour: parsedEnd.hour, minute: parsedEnd.minute);
      }
    }
  }

  bool _isUserFilled(String value) {
    final placeholder = value.toUpperCase();
    const defaults = {
      'DATE', 'TIME', 'MY AWESOME EVENT', 'JOIN US FOR AN AMAZING EVENT!',
      'CAMPUS VENUE, MAIN HALL', 'ONLINE COURSE', 'SPOKEN ENGLISH',
    };
    return !defaults.contains(placeholder);
  }

  void _applyPosterDateTime(String dateRaw, String timeRaw) {
    if (dateRaw.isEmpty || dateRaw.toUpperCase() == 'DATE') return;

    final parsedDate = DateTime.tryParse(dateRaw);
    if (parsedDate != null) {
      selectedDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    } else {
      try {
        final formats = [
          DateFormat('MMM dd, yyyy'),
          DateFormat('dd MMM yyyy'),
          DateFormat('yyyy-MM-dd'),
          DateFormat('dd/MM/yyyy'),
        ];
        for (final fmt in formats) {
          try {
            final d = fmt.parseStrict(dateRaw);
            selectedDate = DateTime(d.year, d.month, d.day);
            break;
          } catch (_) {}
        }
      } catch (_) {}
    }

    if (timeRaw.isNotEmpty && timeRaw.toUpperCase() != 'TIME') {
      final timeParsed = _parseTimeString(timeRaw);
      if (timeParsed != null) {
        selectedTime = timeParsed;
      }
    }

    _updateDateTimeController();
  }

  TimeOfDay? _parseTimeString(String raw) {
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

  String? _buildEndDateString() {
    if (selectedEndDate == null) return null;
    final endTime = selectedEndTime ?? const TimeOfDay(hour: 23, minute: 59);
    final full = DateTime(selectedEndDate!.year, selectedEndDate!.month, selectedEndDate!.day, endTime.hour, endTime.minute);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(full);
  }

  void _publishEvent() async {
    if (!_validateForm()) return;

    if (selectedImage != null) {
      final sizeErr = await UploadFileValidators.posterSizeError(selectedImage!);
      if (sizeErr != null) {
        if (!mounted) return;
        SweetAlertHelper.showError(context, 'Poster too large', sizeErr);
        return;
      }
    }

    final isEdit = widget.existingEvent != null;
    final endDateStr = _buildEndDateString();
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
            rules: rulesCtrl.text.trim(),
            eventEndDate: endDateStr,
          )
        : await controller.createEvent(
            titleCtrl.text.trim(),
            descCtrl.text.trim(),
            dateCtrl.text.trim(),
            selectedCategory,
            venueCtrl.text.trim(),
            selectedImage,
            rules: rulesCtrl.text.trim(),
            eventEndDate: endDateStr,
          );

    if (!mounted) return;

    if (success) {
      final String successBody = isEdit
          ? (Constant.notifyAdminsBySmsOnEventSubmit
              ? "Event updated successfully (pending). Administrators are notified by SMS."
              : "Event updated successfully (pending). It will appear in your list once reviewed.")
          : (Constant.notifyAdminsBySmsOnEventSubmit
              ? "Your event was submitted for approval. Administrators are notified by SMS so they can review it in the admin panel."
              : "Your event was submitted for approval. Administrators can review it in the admin panel.");
      SweetAlertHelper.showSuccess(
        context,
        "Success",
        successBody,
        onConfirm: () async {
          if (isEdit) {
            await AppNavigation.offAll(
              () => const HomeBootstrapView(initialBottomTabIndex: 1, initialMyEventsTabIndex: 1),
              prepare: AppBootstrap.prepareHome,
              loadingMessage: 'Loading MiCampus...',
            );
          } else {
            await AppNavigation.offAll(
              () => const HomeBootstrapView(),
              prepare: AppBootstrap.prepareHome,
              loadingMessage: 'Loading MiCampus...',
            );
          }
        },
      );
    }
    // Errors are shown by EventController.createEvent with server message/field.
  }

  bool _validateForm() {
    if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty || selectedDate == null || selectedTime == null || venueCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(context, "Required", "Please fill all fields");
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

  static const double _fieldRadius = 14;

  TextStyle get _fieldTextStyle => TextStyle(
        fontSize: 15.sp,
        color: Colors.black87,
        height: 1.35,
      );

  TextStyle get _labelStyle => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    bool alignLabelTop = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
      prefixIcon: alignLabelTop
          ? Padding(
              padding: EdgeInsets.only(bottom: 48.h),
              child: Icon(icon, color: const Color(0xFFFF5F15)),
            )
          : Icon(icon, color: const Color(0xFFFF5F15)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: Color(0xFFFF5F15), width: 1.8),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: const Color(0xFFFF5F15).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18.sp, color: const Color(0xFFFF5F15)),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        SizedBox(height: 10.h),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingEvent != null;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.cream,
      resizeToAvoidBottomInset: true,
      appBar: CampusAppBar(
        titleText: isEdit ? 'Edit Pending Event' : 'Host an Event',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('Event Banner', Icons.image_outlined),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openPosterDesigner,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Add Poster'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_fieldRadius),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                height: 300.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_fieldRadius),
                  color: Colors.grey[200],
                  border: Border.all(
                    color: const Color(0xFFFF5F15).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(_fieldRadius - 1),
                      child: selectedImage != null
                          ? Image.file(
                              selectedImage!,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : (_existingBannerName != null && !_removeExistingBanner)
                              ? AppNetworkImage(
                                  url:
                                      '${Constant.uploadsBaseUrl}events/$_existingBannerName',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorWidget: (_, __, ___) => _buildEmptyBanner(),
                                )
                              : _buildEmptyBanner(),
                    ),
                    if (selectedImage != null ||
                        (_existingBannerName != null && !_removeExistingBanner))
                      Positioned(
                        top: 10,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            if (selectedImage != null) {
                              selectedImage = null;
                            } else {
                              _removeExistingBanner = true;
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 28.h),

              _sectionHeader('Details', Icons.edit_note_outlined),
              SizedBox(height: 16.h),
              _buildLabeledField(
                label: 'Event Title',
                child: TextField(
                  controller: titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  style: _fieldTextStyle,
                  decoration: _inputDecoration(
                    hint: "What's the name of your event?",
                    icon: Icons.event_outlined,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              _buildLabeledField(
                label: 'Category',
                child: DropdownButtonFormField<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    hint: 'Select category',
                    icon: Icons.category_outlined,
                  ),
                  items: categories
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedCategory = val);
                  },
                ),
              ),
              SizedBox(height: 20.h),
              _buildLabeledField(
                label: 'Description',
                child: TextField(
                  controller: descCtrl,
                  maxLines: 5,
                  minLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: _fieldTextStyle,
                  decoration: _inputDecoration(
                    hint: 'Tell students about your event...',
                    icon: Icons.description_outlined,
                    alignLabelTop: true,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              _buildLabeledField(
                label: 'Event rules / dress code',
                child: TextField(
                  controller: rulesCtrl,
                  maxLines: 5,
                  minLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: _fieldTextStyle,
                  decoration: _inputDecoration(
                    hint: 'Rules, eligibility, dress code, judging criteria...',
                    icon: Icons.gavel_outlined,
                    alignLabelTop: true,
                  ),
                ),
              ),

              SizedBox(height: 28.h),

              _sectionHeader('When', Icons.schedule_outlined),
              SizedBox(height: 16.h),
              _buildDateTimeSection(),

              SizedBox(height: 28.h),

              _sectionHeader('Where', Icons.place_outlined),
              SizedBox(height: 16.h),
              _buildLabeledField(
                label: 'Venue / Location',
                child: TextField(
                  controller: venueCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: _fieldTextStyle,
                  decoration: _inputDecoration(
                    hint: 'Where will the event be held?',
                    icon: Icons.location_on_outlined,
                  ),
                ),
              ),

              SizedBox(height: 36.h),

              Obx(
                () => controller.isLoading.value
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFF5F15)),
                      )
                    : ElevatedButton(
                        onPressed: _publishEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5F15),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_fieldRadius),
                          ),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Center(
                            child: Text(
                              isEdit ? 'Save Changes' : 'Publish Event',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              SizedBox(height: 12.h),
            ],
          ),
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
            'No banner selected',
            style: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
          ),
        ],
      );

  Widget _dateTimeChip({
    required VoidCallback? onTap,
    required IconData icon,
    required String text,
    required bool active,
  }) {
    return Material(
      color: active ? Colors.white : Colors.grey[50],
      borderRadius: BorderRadius.circular(_fieldRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_fieldRadius),
        child: Container(
          constraints: BoxConstraints(minHeight: 56.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_fieldRadius),
            border: Border.all(
              color: active ? Colors.grey.shade300 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: active ? const Color(0xFFFF5F15) : Colors.grey[400],
                size: 20,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: active ? Colors.black87 : Colors.grey[500],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('From (Start)', style: _labelStyle),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _dateTimeChip(
                onTap: _selectDate,
                icon: Icons.calendar_today,
                text: selectedDate != null
                    ? DateFormat('dd MMM yyyy').format(selectedDate!)
                    : 'Start Date',
                active: selectedDate != null,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _dateTimeChip(
                onTap: _selectTime,
                icon: Icons.access_time,
                text: selectedTime != null
                    ? selectedTime!.format(context)
                    : 'Start Time',
                active: selectedTime != null,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              child: Text('To (End) — Optional', style: _labelStyle),
            ),
            if (selectedEndDate != null)
              GestureDetector(
                onTap: () => setState(() {
                  selectedEndDate = null;
                  selectedEndTime = null;
                }),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 16, color: Colors.red[400]),
                    SizedBox(width: 4.w),
                    Text(
                      'Clear',
                      style: TextStyle(fontSize: 12.sp, color: Colors.red[400]),
                    ),
                  ],
                ),
              ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _dateTimeChip(
                onTap: _selectEndDate,
                icon: Icons.calendar_today,
                text: selectedEndDate != null
                    ? DateFormat('dd MMM yyyy').format(selectedEndDate!)
                    : 'End Date',
                active: selectedEndDate != null,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _dateTimeChip(
                onTap: selectedEndDate != null ? _selectEndTime : null,
                icon: Icons.access_time,
                text: selectedEndTime != null
                    ? selectedEndTime!.format(context)
                    : 'End Time',
                active: selectedEndTime != null,
              ),
            ),
          ],
        ),
      ],
    );
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
      setState(() {
        selectedDate = picked;
        _updateDateTimeController();
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
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
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedEndTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => selectedEndTime = picked);
  }

  void _updateDateTimeController() {
    if (selectedDate != null && selectedTime != null) {
      final DateTime fullDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );
      dateCtrl.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(fullDateTime);
    }
  }
}
