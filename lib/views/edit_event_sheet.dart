import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../controllers/event_controller.dart';
import '../utils/sweetalert_helper.dart';

/// Bottom sheet to edit an approved event (organizer or editor).
/// Sends event_date and category; may get pending_approval from API.
class EditEventSheet extends StatefulWidget {
  final dynamic event;

  const EditEventSheet({super.key, required this.event});

  @override
  State<EditEventSheet> createState() => _EditEventSheetState();
}

class _EditEventSheetState extends State<EditEventSheet> {
  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;
  late TextEditingController venueCtrl;
  late TextEditingController dateCtrl;
  late String selectedCategory;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final List<String> categories = ["IT/Tech", "Cultural", "Sports", "Academic", "Social"];

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    titleCtrl = TextEditingController(text: (e['title'] ?? '').toString());
    descCtrl = TextEditingController(text: (e['description'] ?? '').toString());
    venueCtrl = TextEditingController(text: (e['venue'] ?? '').toString());
    selectedCategory = (e['category'] ?? 'IT/Tech').toString();
    if (!categories.contains(selectedCategory)) selectedCategory = categories.first;
    final rawDate = (e['event_date'] ?? '').toString();
    if (rawDate.isNotEmpty) {
      final parsed = DateTime.tryParse(rawDate.replaceAll(' ', 'T'));
      if (parsed != null) {
        selectedDate = DateTime(parsed.year, parsed.month, parsed.day);
        selectedTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
        dateCtrl = TextEditingController(text: rawDate);
      } else {
        dateCtrl = TextEditingController();
      }
    } else {
      dateCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    venueCtrl.dispose();
    dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (d != null && mounted) {
      setState(() => selectedDate = d);
      await _pickTime();
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (t != null && mounted) {
      setState(() {
        selectedTime = t;
        final d = selectedDate ?? DateTime.now();
        dateCtrl.text = '${DateFormat('yyyy-MM-dd').format(d)} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
      });
    }
  }

  void _save() async {
    if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty || venueCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(context, "Required", "Please fill title, description and venue.");
      return;
    }
    if (selectedDate == null || selectedTime == null) {
      SweetAlertHelper.showError(context, "Required", "Please set date and time.");
      return;
    }
    final dateStr = '${DateFormat('yyyy-MM-dd').format(selectedDate!)} ${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}:00';
    final EventController controller = Get.find<EventController>();
    await controller.updateApprovedEvent(
      event: widget.event,
      title: titleCtrl.text.trim(),
      description: descCtrl.text.trim(),
      venue: venueCtrl.text.trim(),
      eventDate: dateStr,
      category: selectedCategory,
    );
    if (context.mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Text("Edit Event", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  children: [
                    _field("Title", titleCtrl),
                    _field("Description", descCtrl, maxLines: 3),
                    _field("Venue", venueCtrl),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: "Category",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => selectedCategory = v ?? selectedCategory),
                    ),
                    SizedBox(height: 12.h),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(selectedDate != null ? dateCtrl.text : "Pick date & time"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF5F15),
                        side: const BorderSide(color: Color(0xFFFF5F15)),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Obx(() {
                      final controller = Get.find<EventController>();
                      return ElevatedButton(
                        onPressed: controller.isLoading.value ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5F15),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: controller.isLoading.value
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Save changes"),
                      );
                    }),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
