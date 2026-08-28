// edit_profile_view.dart - UI only change, no controller modifications
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/profile_controller.dart';
import '../utils/sweetalert_helper.dart';
import '../widgets/app_bar_title_with_brand_logo.dart';
import '../widgets/app_network_image.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final ProfileController controller = Get.find<ProfileController>();
  final nameCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final deptClassCtrl = TextEditingController();
  final interestSearchCtrl = TextEditingController();
  File? selectedImage;
  
  // Selected interests parsed from user data
  List<String> _selectedInterests = [];
  
  // Available interest options for dropdown
  final List<String> _interestOptions = [
    'IT/Tech', 'Coding', 'Open Source', 'Cultural', 'Dance', 'Art',
    'Sports', 'Fitness', 'Cricket', 'Football', 'Basketball', 'Social',
    'Volunteering', 'Photography', 'Academic', 'Literature', 'Debate',
    'Music', 'Singing', 'Entertainment', 'Drama', 'Fashion', 'History',
    'Swimming', 'Wrestling', 'Astronomy', 'Physics', 'Gaming'
  ];
  
  List<String> _filteredInterests = [];
  bool _showSuggestions = false;
  final FocusNode _interestFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    nameCtrl.text = controller.userData.value.fullName ?? "";
    bioCtrl.text = controller.userData.value.bio ?? "";
    deptClassCtrl.text = controller.userData.value.departmentClass ?? "";
    
    // Parse existing interests from user data into list
    final existingInterests = controller.userData.value.interests ?? "";
    if (existingInterests.isNotEmpty && existingInterests != 'General') {
      _selectedInterests = existingInterests
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    
    _filteredInterests = List.from(_interestOptions);
    
    // Listen to search field changes
    interestSearchCtrl.addListener(() {
      setState(() {
        final query = interestSearchCtrl.text.toLowerCase();
        if (query.isEmpty) {
          _filteredInterests = List.from(_interestOptions);
          _showSuggestions = false;
        } else {
          _filteredInterests = _interestOptions
              .where((interest) => interest.toLowerCase().contains(query))
              .toList();
          _showSuggestions = true;
        }
      });
    });
    
    // Listen to focus changes
    _interestFocusNode.addListener(() {
      setState(() {
        _showSuggestions = _interestFocusNode.hasFocus && interestSearchCtrl.text.isNotEmpty;
      });
    });
  }
  
  void _addInterest(String interest) {
    if (!_selectedInterests.contains(interest)) {
      setState(() {
        _selectedInterests.add(interest);
        interestSearchCtrl.clear();
        _showSuggestions = false;
      });
    }
  }

  void _removeInterest(String interest) {
    setState(() {
      _selectedInterests.remove(interest);
    });
  }

  @override
  Widget build(BuildContext context) {
    const radius = 16.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const AppBarTitleWithBrandLogo(
          onPrimaryBackground: true,
          title: Text(
            "Edit Profile",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0xFFFF5F15),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            // Soft gradient header → rounded bottom + shadow into content
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 36.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF5F15),
                    Color(0xFFFF7A3D),
                    Color(0xFFFFA07A),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.55, 1.0],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5F15).withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 58.w,
                              backgroundColor: Colors.white,
                              backgroundImage: selectedImage != null
                                  ? FileImage(selectedImage!)
                                  : (controller.userData.value.image != null &&
                                          controller.userData.value.image!.isNotEmpty
                                      ? appNetworkImageProvider(
                                          "https://micampus.co.in/admin/uploads/profiles/${controller.userData.value.image}",
                                        )
                                      : null),
                              child: selectedImage == null &&
                                      (controller.userData.value.image == null ||
                                          controller.userData.value.image!.isEmpty)
                                  ? Icon(Icons.person, size: 58.w, color: const Color(0xFFFF5F15))
                                  : null,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5F15), Color(0xFFFF9068)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    "Tap to update photo",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Personal Information", Icons.person_outline),
                  SizedBox(height: 14.h),
                  _buildTextField(
                    controller: nameCtrl,
                    label: "Full Name",
                    hint: "Enter your full name",
                    icon: Icons.badge_outlined,
                    inputType: TextInputType.name,
                  ),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: deptClassCtrl,
                    label: "Department / Class",
                    hint: "e.g. CSE 3rd Year, Section A",
                    icon: Icons.school_outlined,
                    helperText:
                        "Shown on your profile and used when you register as a participant",
                  ),

                  SizedBox(height: 20.h),

                  Obx(() {
                    final isSt = controller.userData.value.isStudent ?? true;
                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4EC),
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(color: const Color(0xFFFFD0B5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 18.sp, color: const Color(0xFF9A3412)),
                              SizedBox(width: 8.w),
                              Text(
                                "Account type",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF7C2D12),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            isSt
                                ? "You are registered as a student (login uses roll number)."
                                : "You are registered as faculty (login uses employee ID).",
                            style: TextStyle(
                              fontSize: 13.sp,
                              height: 1.35,
                              color: const Color(0xFF9A3412),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "Account type cannot be changed in the app. Contact support if you need help.",
                            style: TextStyle(
                              fontSize: 12.sp,
                              height: 1.35,
                              color: const Color(0xFF9A3412).withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  SizedBox(height: 28.h),

                  _buildSectionHeader("About You", Icons.description_outlined),
                  SizedBox(height: 14.h),
                  _buildTextField(
                    controller: bioCtrl,
                    label: "Bio",
                    hint: "Tell us about yourself...",
                    icon: Icons.edit_note,
                    maxLines: 4,
                    inputType: TextInputType.multiline,
                  ),

                  SizedBox(height: 28.h),

                  _buildSectionHeader("Your Interests", Icons.interests_outlined),
                  SizedBox(height: 14.h),

                  Stack(
                    children: [
                      Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(radius),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: interestSearchCtrl,
                              focusNode: _interestFocusNode,
                              style: TextStyle(fontSize: 15.sp, color: Colors.black87),
                              decoration: InputDecoration(
                                labelText: "Search Interests",
                                hintText: "Search or type your interests...",
                                helperText: "Tap suggestions or press Enter to add",
                                helperMaxLines: 2,
                                helperStyle: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey[600],
                                  height: 1.3,
                                ),
                                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF5F15), size: 22),
                                suffixIcon: interestSearchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            interestSearchCtrl.clear();
                                            _showSuggestions = false;
                                          });
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(radius),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(radius),
                                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(radius),
                                  borderSide: const BorderSide(color: Color(0xFFFF5F15), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                              ),
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) {
                                  _addInterest(value.trim());
                                }
                              },
                            ),
                          ),
                          if (_showSuggestions && _filteredInterests.isNotEmpty)
                            Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                margin: EdgeInsets.only(top: 8.h),
                                constraints: BoxConstraints(maxHeight: 200.h),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFFF5F15).withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.symmetric(vertical: 4.h),
                                  itemCount: _filteredInterests.length,
                                  separatorBuilder: (context, index) =>
                                      Divider(height: 1, color: Colors.grey[200]),
                                  itemBuilder: (context, index) {
                                    final interest = _filteredInterests[index];
                                    final isSelected = _selectedInterests.contains(interest);
                                    return InkWell(
                                      onTap: () {
                                        _addInterest(interest);
                                        _interestFocusNode.unfocus();
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                        color: isSelected ? Colors.grey[100] : Colors.transparent,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                interest,
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  color: isSelected ? Colors.grey[600] : Colors.black87,
                                                  fontWeight:
                                                      isSelected ? FontWeight.w500 : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                Icons.check_circle,
                                                color: const Color(0xFFFF5F15),
                                                size: 20.w,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          if (_showSuggestions &&
                              _filteredInterests.isEmpty &&
                              interestSearchCtrl.text.isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(top: 8.h),
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4EC),
                                border: Border.all(
                                  color: const Color(0xFFFF5F15).withValues(alpha: 0.3),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'No matching interests found',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: const Color(0xFF7C2D12),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 10.h),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _addInterest(interestSearchCtrl.text.trim());
                                      _interestFocusNode.unfocus();
                                    },
                                    icon: const Icon(Icons.add, size: 20),
                                    label: Text(
                                      'Add "${interestSearchCtrl.text.trim()}"',
                                      style: TextStyle(fontSize: 13.sp),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF5F15),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  if (_selectedInterests.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: _selectedInterests.map((interest) {
                          return Chip(
                            label: Text(interest),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => _removeInterest(interest),
                            backgroundColor: const Color(0xFFFF5F15).withValues(alpha: 0.1),
                            labelStyle: TextStyle(
                              color: const Color(0xFFFF5F15),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            deleteIconColor: const Color(0xFFFF5F15),
                            side: const BorderSide(color: Color(0xFFFF5F15), width: 1),
                          );
                        }).toList(),
                      ),
                    ),

                  SizedBox(height: 36.h),

                  Obx(
                    () => controller.isLoading.value
                        ? const Center(
                            child: CircularProgressIndicator(color: Color(0xFFFF5F15)),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5F15), Color(0xFFFF9068)],
                              ),
                              borderRadius: BorderRadius.circular(radius),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5F15).withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(vertical: 18.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(radius),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline, color: Colors.white),
                                  SizedBox(width: 10.w),
                                  Text(
                                    "Save Changes",
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5F15), Color(0xFFFF9068)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType inputType = TextInputType.text,
    String? helperText,
  }) {
    const radius = 16.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: inputType,
            maxLines: maxLines,
            style: TextStyle(fontSize: 15.sp, color: Colors.black87, height: 1.35),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
              prefixIcon: Icon(icon, color: const Color(0xFFFF5F15), size: 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: const BorderSide(color: Color(0xFFFF5F15), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: maxLines > 1 ? 16.h : 16.h,
              ),
            ),
          ),
        ),
        if (helperText != null) ...[
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(left: 4.w, right: 4.w),
            child: Text(
              helperText,
              style: TextStyle(
                fontSize: 12.sp,
                height: 1.35,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? img = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (img != null) {
        if (!mounted) return;
        setState(() => selectedImage = File(img.path));
      }
    } catch (e) {
      if (!mounted) return;
      SweetAlertHelper.showError(context, "Error", "Failed to pick image");
    }
  }

  Future<void> _saveProfile() async {
    // Validation
    if (nameCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(context, "Required", "Please enter your name");
      return;
    }

    // Convert selected interests list back to comma-separated string
    final interestsString = _selectedInterests.isEmpty 
        ? 'General' 
        : _selectedInterests.join(', ');

    // Call existing controller method (no changes needed in controller)
    bool success = await controller.updateProfile(
      nameCtrl.text.trim(),
      bioCtrl.text.trim(),
      interestsString,
      selectedImage,
      departmentClass: deptClassCtrl.text.trim(),
    );
    
    if (success) {
      Get.back();
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    bioCtrl.dispose();
    deptClassCtrl.dispose();
    interestSearchCtrl.dispose();
    _interestFocusNode.dispose();
    super.dispose();
  }
}