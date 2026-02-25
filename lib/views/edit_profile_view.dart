// edit_profile_view.dart - UI only change, no controller modifications
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/profile_controller.dart';
import '../utils/sweetalert_helper.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final ProfileController controller = Get.find<ProfileController>();
  final nameCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
        ),
        backgroundColor: const Color(0xFFFF5F15),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Picture Section with Gradient Background
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 40.h),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF5F15), Color(0xFFFF9068)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        // Avatar with border
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8)
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60.w,
                            backgroundColor: Colors.white,
                            backgroundImage: selectedImage != null
                                ? FileImage(selectedImage!)
                                : (controller.userData.value.image != null && 
                                   controller.userData.value.image!.isNotEmpty
                                    ? NetworkImage("https://exdeos.com/AS/campus_social/uploads/profiles/${controller.userData.value.image}")
                                    : null) as ImageProvider?,
                            child: selectedImage == null &&
                                    (controller.userData.value.image == null || 
                                     controller.userData.value.image!.isEmpty)
                                ? Icon(Icons.person, size: 60.w, color: const Color(0xFFFF5F15))
                                : null,
                          ),
                        ),
                        // Camera icon
                        Positioned(
                          bottom: 0,
                          right: 0,
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
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8
                                )
                              ],
                            ),
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    "Tap to update photo",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Form Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Name Field
                  _buildSectionHeader("Personal Information", Icons.person_outline),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: nameCtrl,
                    label: "Full Name",
                    hint: "Enter your full name",
                    icon: Icons.badge_outlined,
                    inputType: TextInputType.name,
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Bio Field
                  _buildSectionHeader("About You", Icons.description_outlined),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: bioCtrl,
                    label: "Bio",
                    hint: "Tell us about yourself...",
                    icon: Icons.edit_note,
                    maxLines: 4,
                    inputType: TextInputType.multiline,
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Interests Section with Dropdown
                  _buildSectionHeader("Your Interests", Icons.interests_outlined),
                  SizedBox(height: 16.h),
                  
                  // Interests Search Field with Autocomplete Dropdown
                  Stack(
                    children: [
                      Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2)
                                )
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
                                helperStyle: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
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
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFFFF5F15), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                              ),
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) {
                                  _addInterest(value.trim());
                                }
                              },
                            ),
                          ),
                          
                          // Suggestions Dropdown
                          if (_showSuggestions && _filteredInterests.isNotEmpty)
                            Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                margin: EdgeInsets.only(top: 8.h),
                                constraints: BoxConstraints(maxHeight: 200.h),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: const Color(0xFFFF5F15).withOpacity(0.3), width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.symmetric(vertical: 4.h),
                                  itemCount: _filteredInterests.length,
                                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
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
                                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
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
                          
                          // "Add custom interest" button when no match
                          if (_showSuggestions && _filteredInterests.isEmpty && interestSearchCtrl.text.isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(top: 8.h),
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                border: Border.all(color: const Color(0xFFFF5F15).withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'No matching interests found',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.grey[700],
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
                  
                  // Selected Interests Chips (with X delete button)
                  if (_selectedInterests.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2)
                          )
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
                            backgroundColor: const Color(0xFFFF5F15).withOpacity(0.1),
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
                  
                  SizedBox(height: 48.h),
                  
                  // Save Button
                  Obx(() => controller.isLoading.value
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFFFF5F15))
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5F15), Color(0xFFFF9068)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF5F15).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 6)
                              )
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(vertical: 18.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)
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
                                    color: Colors.white
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  
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
    return Row(
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
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2)
          )
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        maxLines: maxLines,
        style: TextStyle(fontSize: 15.sp, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helperText,
          helperStyle: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
          prefixIcon: Icon(icon, color: const Color(0xFFFF5F15), size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF5F15), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: maxLines > 1 ? 16.h : 14.h
          ),
        ),
      ),
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
        setState(() => selectedImage = File(img.path));
      }
    } catch (e) {
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
      interestsString, // Pass as string like before
      selectedImage,
    );
    
    if (success) {
      Get.back();
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    bioCtrl.dispose();
    interestSearchCtrl.dispose();
    _interestFocusNode.dispose();
    super.dispose();
  }
}