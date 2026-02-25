import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/auth_controller.dart';
import 'login_view.dart';
// import 'otp_verification_view.dart'; // OTP disabled temporarily

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final AuthController controller = Get.put(AuthController());
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final rollNumberCtrl = TextEditingController();
  final empNumberCtrl = TextEditingController();
  final interestSearchCtrl = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;
  bool _isStudent = true;
  
  final List<String> _selectedInterests = [];
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
    _filteredInterests = List.from(_interestOptions);
    
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

  void _showTermsAndConditionsDialog() {
    bool dialogAgreeTerms = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5F15),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.description,
                            color: Colors.white,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            "Terms and Conditions",
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Terms & Conditions of Use",
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              "By registering and creating a profile on the MiCampusl App, you acknowledge and agree to the following:",
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 16.h),
                            _buildTermSection(
                              "1. Accuracy of Information",
                              "You confirm that all details provided (name, contact information, hobbies/skills, and talent interests) are true and accurate to your knowledge and belief. Misrepresentation of identity, credentials, or any falsification of information will result in immediate suspension or permanent termination of your account, without prior notice. Such actions may also trigger disciplinary measures and, where applicable, legal proceedings under relevant laws and regulations.",
                            ),
                            
                            _buildTermSection(
                              "2. Privacy, Consent & Data Usage",
                              "You consent to the collection and use of your personal data for the purposes of student engagement, event participation, peer networking, and reporting.  You may opt-in or opt-out of public visibility, event participation, media sharing, and peer connections at any time through your profile settings. You acknowledge and agree that all data provided and generated through your use of the MiCampusl App may be accessed, processed, analyzed, and utilized by M/S Skill Matters for developmental and research purposes. Suchusagemay include analytics, reporting, development initiatives, and program design, while ensuring compliance within the legal frameworks. Your contacts may be used for business promotion purposes.",
                            ),
                            
                            _buildTermSection(
                              "3. Content & Conduct",
                              "You agree to use the platform responsibly, respecting organization guidelines, community standards, and applicable laws. Offensive, discriminatory, or unlawful content is strictly prohibited and may lead to disciplinary action. Administrators reserve the right to moderate, approve, or remove content/events that violate policies.",
                            ),
                            
                            _buildTermSection(
                              "4. Event Participation & Compliance",
                              "Event creation and participation may require organization, legal, or police approvals depending on the nature of the event. You agree to abide by all event-specific Standard Operating Procedures (SOPs) and compliance requirements.",
                            ),
                            
                            _buildTermSection(
                              "5. Media & Talent Showcase",
                              "By uploading photographs, videos, or talent-related content, you grant the Organisation limited rights to display and promote such content within the app and affiliated platforms. You retain ownership of your content but acknowledge that inappropriate or non compliant material may be removed.",
                            ),
                            
                            _buildTermSection(
                              "6. Advertisements & Promotions",
                              "Sponsored content and advertisements may appear within the app.You may opt out of targeted promotions through your privacy settings.",
                            ),
                            
                            _buildTermSection(
                              "7. Liability & Indemnity",
                              "The organization and app administrators are not liable for damages, losses, or disputes arising from peer interactions, event participation, or third-party promotions. You agree to indemnify the organization against any claims resulting from your misuse of the platform.",
                            ),
                            
                            _buildTermSection(
                              "8. Integrity & Non-Defamation",
                              "You commit to maintaining the highest standards of integrity and to safeguarding the reputation of the institution at all times. Any defamatory remarks, false accusations, or conduct that damages the institution's image are strictly forbidden and will lead to disciplinary measures and potential legal action. You acknowledge that such violations undermine the trust and values of the institution and will be addressed with utmost seriousness. Defamatory statements, false allegations, or actions that harm the image of the institution are strictly prohibited and may result in disciplinary and legal consequences.",
                            ),
                            
                            _buildTermSection(
                              "9. Prohibition of Criminal Use",
                              "The app must not be used for any criminal, unlawful, or fraudulent purposes. Any attempt to engage in illegal activities through the platform will result in immediate termination of access and may be reported to law enforcement authorities.",
                            ),
                            
                            _buildTermSection(
                              "10. Drugs & Intoxicants",
                              "The use, promotion, or distribution of drugs, intoxicants, or other prohibited substances through the app directly / indirectly is strictly forbidden. Any violation of this clause will result in disciplinary action and may involve legal proceedings.",
                            ),

                            _buildTermSection(
                              "11. Acceptance of Terms",
                              "By clicking 'Register' or 'Sign Up' or 'Submit' you confirm that you have read, understood, and accepted these terms and conditions. Continued use of the app constitutes ongoing acceptance of updated policies and disclaimers.",
                            ),
                            
                            SizedBox(height: 20.h),
                            
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFF5F15).withOpacity(0.3)),
                              ),
                              child: Text(
                                "I confirm that the information I have provided is accurate, and I consent to my data being collected, processed, and utilized by the institution and Skill Matters for academic, developmental, and research purposes & promotion purposes in accordance with the Registration Disclaimer.",
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Agreement Checkbox and Buttons
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(
                          top: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: dialogAgreeTerms,
                                onChanged: (val) {
                                  setDialogState(() {
                                    dialogAgreeTerms = val ?? false;
                                  });
                                },
                                activeColor: const Color(0xFFFF5F15),
                              ),
                              Expanded(
                                child: Text(
                                  "I have read and agree to the Terms and Conditions of Use",
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                    side: const BorderSide(color: Color(0xFFFF5F15)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: const Color(0xFFFF5F15),
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: dialogAgreeTerms
                                      ? () {
                                          setState(() {
                                            _agreeTerms = true;
                                          });
                                          Navigator.of(context).pop();
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF5F15),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    disabledBackgroundColor: Colors.grey[300],
                                  ),
                                  child: Text(
                                    "Accept",
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTermSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF5F15),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF5F15), Color(0xFFE04E0B)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20.h),
                // Logo
                Center(
                  child: Container(
                    width: 100.w,
                    height: 100.w,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.jpeg',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.event, size: 50.w, color: const Color(0xFFFF5F15));
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  "Join the Campus Community",
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 24.h),
                
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Student/Faculty Selection
                      Text(
                        "I am a:",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text("Student"),
                              value: true,
                              groupValue: _isStudent,
                              activeColor: const Color(0xFFFF5F15),
                              onChanged: (val) => setState(() => _isStudent = val!),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text("Faculty"),
                              value: false,
                              groupValue: _isStudent,
                              activeColor: const Color(0xFFFF5F15),
                              onChanged: (val) => setState(() => _isStudent = val!),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Roll Number (Student) / Employee ID (Faculty)
                      TextField(
                        controller: _isStudent ? rollNumberCtrl : empNumberCtrl,
                        decoration: InputDecoration(
                          labelText: _isStudent ? "Roll Number" : "Employee ID",
                          prefixIcon: Icon(
                            _isStudent ? Icons.badge : Icons.work_outline,
                            color: const Color(0xFFFF5F15),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFF5F15), width: 2),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Full Name
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: "Full Name",
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFFF5F15)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFF5F15), width: 2),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Email
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email Address",
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFF5F15)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFF5F15), width: 2),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Phone
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFFFF5F15)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFF5F15), width: 2),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Bio
                      TextField(
                        controller: bioCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Bio",
                          hintText: "Tell us about yourself...",
                          prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFFFF5F15)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFF5F15), width: 2),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Interests Search Field
                      Text(
                        "Interests",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      
                      // Search TextField with Autocomplete
                      Stack(
                        children: [
                          Column(
                            children: [
                              TextField(
                                controller: interestSearchCtrl,
                                focusNode: _interestFocusNode,
                                decoration: InputDecoration(
                                  hintText: "Search or type your interests...",
                                  prefixIcon: const Icon(Icons.search, color: Color(0xFFFF5F15)),
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
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFFF5F15), width: 2),
                                  ),
                                ),
                                onSubmitted: (value) {
                                  if (value.trim().isNotEmpty) {
                                    _addInterest(value.trim());
                                  }
                                },
                              ),
                              
                              // Suggestions Dropdown
                              if (_showSuggestions && _filteredInterests.isNotEmpty)
                                Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    margin: EdgeInsets.only(top: 4.h),
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
                              
                              // "Others" button when no match
                              if (_showSuggestions && _filteredInterests.isEmpty && interestSearchCtrl.text.isNotEmpty)
                                Container(
                                  margin: EdgeInsets.only(top: 4.h),
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
                      
                      SizedBox(height: 12.h),
                      
                      // Selected Interests Chips
                      if (_selectedInterests.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
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
                      
                      SizedBox(height: 16.h),
                      
                      // Password
                      TextField(
                        controller: passCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFF5F15)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey[600],
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFF5F15), width: 2),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Confirm Password
                      TextField(
                        controller: confirmPassCtrl,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: "Confirm Password",
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFF5F15)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey[600],
                            ),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFF5F15), width: 2),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Terms Checkbox - Modified to open dialog
                      InkWell(
                        onTap: _showTermsAndConditionsDialog,
                        child: Row(
                          children: [
                            Checkbox(
                              value: _agreeTerms,
                              onChanged: (val) {
                                if (val == true) {
                                  _showTermsAndConditionsDialog();
                                } else {
                                  setState(() => _agreeTerms = false);
                                }
                              },
                              activeColor: const Color(0xFFFF5F15),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: _showTermsAndConditionsDialog,
                                child: RichText(
                                  text: TextSpan(
                                    text: "I agree to ",
                                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                                    children: [
                                      TextSpan(
                                        text: "Terms and Conditions",
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: const Color(0xFFFF5F15),
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // Sign Up Button - MODIFIED WITH OTP INTEGRATION
                      Obx(() => controller.isLoading.value
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5F15)))
                        : ElevatedButton(
                            onPressed: () async {
                              if (!_validateForm()) return;
                              
                              // Debug print
                              debugPrint("=== Registration Data ===");
                              debugPrint("Name: ${nameCtrl.text.trim()}");
                              debugPrint("Email: ${emailCtrl.text.trim()}"); // Not used for OTP (SMS-only auth)
                              debugPrint("Phone: ${phoneCtrl.text.trim()}");
                              debugPrint("Bio: ${bioCtrl.text.trim().isEmpty ? 'No bio provided' : bioCtrl.text.trim()}");
                              debugPrint("Interests: ${_selectedInterests.isEmpty ? 'General' : _selectedInterests.join(', ')}");
                              debugPrint("Is Student: $_isStudent");
                              debugPrint("Roll/Emp: ${_isStudent ? rollNumberCtrl.text.trim() : empNumberCtrl.text.trim()}");
                              
                              // OTP disabled temporarily: register directly.
                              controller.register(
                                nameCtrl.text.trim(),
                                emailCtrl.text.trim(),
                                phoneCtrl.text.trim(),
                                passCtrl.text,
                                bioCtrl.text.trim().isEmpty ? 'No bio provided' : bioCtrl.text.trim(),
                                _selectedInterests.isEmpty ? 'General' : _selectedInterests.join(', '),
                                _isStudent,
                                _isStudent ? rollNumberCtrl.text.trim() : null,
                                _isStudent ? null : empNumberCtrl.text.trim(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5F15),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text(
                              "Create Account",
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                            ),
                          )),
                      
                      SizedBox(height: 16.h),
                      
                      // Login Link
                      Center(
                        child: GestureDetector(
                          onTap: () => Get.off(() => const LoginView()),
                          child: RichText(
                            text: TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(color: Colors.grey[700], fontSize: 14.sp),
                              children: [
                                TextSpan(
                                  text: "Login",
                                  style: TextStyle(
                                    color: const Color(0xFFFF5F15),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _validateForm() {
    if (_isStudent && rollNumberCtrl.text.trim().isEmpty) {
      Get.snackbar("Required", "Please enter your roll number", backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (!_isStudent && empNumberCtrl.text.trim().isEmpty) {
      Get.snackbar("Required", "Please enter your employee ID", backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (nameCtrl.text.trim().isEmpty) {
      Get.snackbar("Required", "Please enter your full name", backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (emailCtrl.text.trim().isEmpty) {
      Get.snackbar("Required", "Please enter your email", backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (!GetUtils.isEmail(emailCtrl.text.trim())) {
      Get.snackbar("Invalid", "Please enter a valid email address", backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (phoneCtrl.text.trim().isEmpty) {
      Get.snackbar("Required", "Please enter your phone number", backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    // Bio is now optional
    // Interests are now optional
    if (passCtrl.text.isEmpty) {
      Get.snackbar("Required", "Please enter a password", backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (passCtrl.text.length < 6) {
      Get.snackbar("Weak", "Password must be at least 6 characters", backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (passCtrl.text != confirmPassCtrl.text) {
      Get.snackbar("Mismatch", "Passwords do not match", backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (!_agreeTerms) {
      Get.snackbar("Required", "Please agree to Terms and Conditions", backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    bioCtrl.dispose();
    rollNumberCtrl.dispose();
    empNumberCtrl.dispose();
    interestSearchCtrl.dispose();
    _interestFocusNode.dispose();
    super.dispose();
  }
}