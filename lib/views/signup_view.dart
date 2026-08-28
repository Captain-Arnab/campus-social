import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/auth_controller.dart';
import '../data/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/auth_input_validators.dart';
import '../utils/sweetalert_helper.dart';
import '../data/app_bootstrap.dart';
import '../utils/app_navigation.dart';
import '../widgets/auth_widgets.dart';
import 'bootstrap_views.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final AuthController controller = Get.put(AuthController());
  final PageController _pageController = PageController();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final rollNumberCtrl = TextEditingController();
  final empNumberCtrl = TextEditingController();
  final departmentClassCtrl = TextEditingController();
  final interestSearchCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;
  bool _isStudent = true;
  int _currentStep = 0;

  static const _stepLabels = [
    'Role & Identity',
    'Contact Details',
    'Profile (optional)',
    'Security',
  ];

  final List<String> _selectedInterests = [];
  final List<String> _interestOptions = [
    'IT/Tech',
    'Coding',
    'Open Source',
    'Cultural',
    'Dance',
    'Art',
    'Sports',
    'Fitness',
    'Cricket',
    'Football',
    'Basketball',
    'Social',
    'Volunteering',
    'Photography',
    'Academic',
    'Literature',
    'Debate',
    'Music',
    'Singing',
    'Entertainment',
    'Drama',
    'Fashion',
    'History',
    'Swimming',
    'Wrestling',
    'Astronomy',
    'Physics',
    'Gaming'
  ];

  List<String> _filteredInterests = [];
  bool _showSuggestions = false;
  final FocusNode _interestFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _rollEmpFocusNode = FocusNode();
  Timer? _interestFilterDebounce;
  Worker? _registerFieldWorker;
  String? _serverEmailError;
  String? _serverPhoneError;
  String? _serverRollEmpError;

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  void _clearServerFieldErrors() {
    if (_serverEmailError == null &&
        _serverPhoneError == null &&
        _serverRollEmpError == null) {
      return;
    }
    setState(() {
      _serverEmailError = null;
      _serverPhoneError = null;
      _serverRollEmpError = null;
    });
  }

  /// Jump to the right step and focus the input named by the register API `field`.
  /// API uses `mobile_number` / `employee_id`; request body uses `phone` / `emp_number`.
  void _applyRegisterFieldError(String field) {
    final key = field.toLowerCase().replaceAll('-', '_');
    final isEmail = key == 'email' || key.contains('email');
    final isPhone =
        key == 'mobile_number' ||
        key == 'phone' ||
        key.contains('mobile') ||
        key.contains('phone');
    final isRoll =
        key == 'roll_number' || key == 'roll' || key.contains('roll_number');
    final isEmp = key == 'employee_id' ||
        key == 'emp_number' ||
        key == 'employee_number' ||
        key.contains('employee');

    if (!isEmail && !isPhone && !isRoll && !isEmp) return;

    // Identity conflicts live on step 0; contact conflicts on step 1.
    final targetStep = (isRoll || isEmp) ? 0 : 1;
    if (_currentStep != targetStep) {
      _goToStep(targetStep);
    }

    // Align Student/Faculty toggle with the conflicting identity field.
    if (isRoll && !_isStudent) {
      setState(() => _isStudent = true);
    } else if (isEmp && _isStudent) {
      setState(() => _isStudent = false);
    }

    setState(() {
      _serverEmailError = isEmail ? 'Already registered' : null;
      _serverPhoneError = isPhone ? 'Already registered' : null;
      _serverRollEmpError =
          (isRoll || isEmp) ? 'Already registered' : null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (isEmail) {
        _emailFocusNode.requestFocus();
      } else if (isPhone) {
        _phoneFocusNode.requestFocus();
      } else {
        _rollEmpFocusNode.requestFocus();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _filteredInterests = List.from(_interestOptions);

    for (final c in [
      departmentClassCtrl,
      nameCtrl,
      passCtrl,
      confirmPassCtrl,
    ]) {
      c.addListener(_onFieldChanged);
    }
    rollNumberCtrl.addListener(() {
      _onFieldChanged();
      if (_serverRollEmpError != null) {
        setState(() => _serverRollEmpError = null);
      }
    });
    empNumberCtrl.addListener(() {
      _onFieldChanged();
      if (_serverRollEmpError != null) {
        setState(() => _serverRollEmpError = null);
      }
    });
    emailCtrl.addListener(() {
      _onFieldChanged();
      if (_serverEmailError != null) {
        setState(() => _serverEmailError = null);
      }
    });
    phoneCtrl.addListener(() {
      _onFieldChanged();
      if (_serverPhoneError != null) {
        setState(() => _serverPhoneError = null);
      }
    });

    _registerFieldWorker = ever<String?>(controller.registerErrorField, (field) {
      if (field == null || field.isEmpty) return;
      _applyRegisterFieldError(field);
    });

    interestSearchCtrl.addListener(() {
      _interestFilterDebounce?.cancel();
      _interestFilterDebounce = Timer(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        setState(() {
          final query = interestSearchCtrl.text.toLowerCase();
          if (query.isEmpty) {
            _filteredInterests = List.from(_interestOptions);
            _showSuggestions = false;
          } else {
            _filteredInterests = _interestOptions
                .where((interest) => interest.toLowerCase().contains(query))
                .toList();
            _showSuggestions = _interestFocusNode.hasFocus;
          }
        });
      });
    });

    _interestFocusNode.addListener(() {
      setState(() {
        _showSuggestions =
            _interestFocusNode.hasFocus && interestSearchCtrl.text.isNotEmpty;
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

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _next() async {
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 1) {
      if (!_validateStep2()) return;
      final ok = await _ensureContactAvailable();
      if (!ok) return;
    }
    // Step 3 is optional — always allow next
    if (_currentStep < 3) {
      _goToStep(_currentStep + 1);
    }
  }

  /// Blocks proceed when email/phone is already registered (checked before leaving Contact step).
  Future<bool> _ensureContactAvailable() async {
    final email = emailCtrl.text.trim();
    final phone = phoneCtrl.text.trim();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5F15)),
      ),
    );

    try {
      final result = await ApiService.checkRegistrationAvailability(
        email: email,
        phone: phone,
      );

      if (!mounted) return false;

      if (result.emailTaken == true) {
        SweetAlertHelper.showError(
          context,
          'Already registered',
          'Email ID already registered',
        );
        return false;
      }
      if (result.phoneTaken == true) {
        SweetAlertHelper.showError(
          context,
          'Already registered',
          'Mobile number already registered',
        );
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Contact availability check failed: $e');
      // Network failure — allow proceed; final register will still catch duplicates.
      return true;
    } finally {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _back() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  void _skipProfile() {
    _goToStep(3);
  }

  Future<void> _submit() async {
    if (!_validateStep4()) return;
    _clearServerFieldErrors();
    controller.registerErrorField.value = null;

    debugPrint('=== Registration Data ===');
    debugPrint('Name: ${nameCtrl.text.trim()}');
    debugPrint('Email: ${emailCtrl.text.trim()}');
    debugPrint('Phone: ${phoneCtrl.text.trim()}');
    debugPrint(
      'Bio: ${bioCtrl.text.trim().isEmpty ? 'No bio provided' : bioCtrl.text.trim()}',
    );
    debugPrint(
      'Interests: ${_selectedInterests.isEmpty ? 'General' : _selectedInterests.join(', ')}',
    );
    debugPrint('Is Student: $_isStudent');
    debugPrint(
      'Roll/Emp: ${_isStudent ? rollNumberCtrl.text.trim() : empNumberCtrl.text.trim()}',
    );

    controller.register(
      nameCtrl.text.trim(),
      emailCtrl.text.trim(),
      AuthInputValidators.phoneDigits(phoneCtrl.text),
      passCtrl.text,
      bioCtrl.text.trim().isEmpty ? 'No bio provided' : bioCtrl.text.trim(),
      _selectedInterests.isEmpty ? 'General' : _selectedInterests.join(', '),
      _isStudent,
      _isStudent ? rollNumberCtrl.text.trim() : null,
      _isStudent ? null : empNumberCtrl.text.trim(),
      departmentClass: departmentClassCtrl.text.trim(),
    );
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
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description, color: Colors.white),
                          SizedBox(width: 12.w),
                          Text(
                            'Terms and Conditions',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Terms & Conditions of Use',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'By registering and creating a profile on the MiCampusl App, you acknowledge and agree to the following:',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 16.h),
                            _buildTermSection(
                              '1. Accuracy of Information',
                              'You confirm that all details provided (name, contact information, hobbies/skills, and talent interests) are true and accurate to your knowledge and belief. Misrepresentation of identity, credentials, or any falsification of information will result in immediate suspension or permanent termination of your account, without prior notice. Such actions may also trigger disciplinary measures and, where applicable, legal proceedings under relevant laws and regulations.',
                            ),
                            _buildTermSection(
                              '2. Privacy, Consent & Data Usage',
                              'You consent to the collection and use of your personal data for the purposes of student engagement, event participation, peer networking, and reporting.  You may opt-in or opt-out of public visibility, event participation, media sharing, and peer connections at any time through your profile settings. You acknowledge and agree that all data provided and generated through your use of the MiCampusl App may be accessed, processed, analyzed, and utilized by M/S Skill Matters for developmental and research purposes. Suchusagemay include analytics, reporting, development initiatives, and program design, while ensuring compliance within the legal frameworks. Your contacts may be used for business promotion purposes.',
                            ),
                            _buildTermSection(
                              '3. Content & Conduct',
                              'You agree to use the platform responsibly, respecting organization guidelines, community standards, and applicable laws. Offensive, discriminatory, or unlawful content is strictly prohibited and may lead to disciplinary action. Administrators reserve the right to moderate, approve, or remove content/events that violate policies.',
                            ),
                            _buildTermSection(
                              '4. Event Participation & Compliance',
                              'Event creation and participation may require organization, legal, or police approvals depending on the nature of the event. You agree to abide by all event-specific Standard Operating Procedures (SOPs) and compliance requirements.',
                            ),
                            _buildTermSection(
                              '5. Media & Talent Showcase',
                              'By uploading photographs, videos, or talent-related content, you grant the Organisation limited rights to display and promote such content within the app and affiliated platforms. You retain ownership of your content but acknowledge that inappropriate or non compliant material may be removed.',
                            ),
                            _buildTermSection(
                              '6. Advertisements & Promotions',
                              'Sponsored content and advertisements may appear within the app.You may opt out of targeted promotions through your privacy settings.',
                            ),
                            _buildTermSection(
                              '7. Liability & Indemnity',
                              'The organization and app administrators are not liable for damages, losses, or disputes arising from peer interactions, event participation, or third-party promotions. You agree to indemnify the organization against any claims resulting from your misuse of the platform.',
                            ),
                            _buildTermSection(
                              '8. Integrity & Non-Defamation',
                              "You commit to maintaining the highest standards of integrity and to safeguarding the reputation of the institution at all times. Any defamatory remarks, false accusations, or conduct that damages the institution's image are strictly forbidden and will lead to disciplinary measures and potential legal action. You acknowledge that such violations undermine the trust and values of the institution and will be addressed with utmost seriousness. Defamatory statements, false allegations, or actions that harm the image of the institution are strictly prohibited and may result in disciplinary and legal consequences.",
                            ),
                            _buildTermSection(
                              '9. Prohibition of Criminal Use',
                              'The app must not be used for any criminal, unlawful, or fraudulent purposes. Any attempt to engage in illegal activities through the platform will result in immediate termination of access and may be reported to law enforcement authorities.',
                            ),
                            _buildTermSection(
                              '10. Drugs & Intoxicants',
                              'The use, promotion, or distribution of drugs, intoxicants, or other prohibited substances through the app directly / indirectly is strictly forbidden. Any violation of this clause will result in disciplinary action and may involve legal proceedings.',
                            ),
                            _buildTermSection(
                              '11. Acceptance of Terms',
                              "By clicking 'Register' or 'Sign Up' or 'Submit' you confirm that you have read, understood, and accepted these terms and conditions. Continued use of the app constitutes ongoing acceptance of updated policies and disclaimers.",
                            ),
                            SizedBox(height: 20.h),
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.accent.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                'I confirm that the information I have provided is accurate, and I consent to my data being collected, processed, and utilized by the institution and Skill Matters for academic, developmental, and research purposes & promotion purposes in accordance with the Registration Disclaimer.',
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
                                activeColor: AppColors.accent,
                              ),
                              Expanded(
                                child: Text(
                                  'I have read and agree to the Terms and Conditions of Use',
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
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 12.h),
                                    side: const BorderSide(
                                      color: AppColors.accent,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: AppColors.accent,
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
                                    backgroundColor: AppColors.accent,
                                    foregroundColor: Colors.white,
                                    padding:
                                        EdgeInsets.symmetric(vertical: 12.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    disabledBackgroundColor: Colors.grey[300],
                                  ),
                                  child: Text(
                                    'Accept',
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
              color: AppColors.accent,
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
    return AuthGradientScaffold(
      title: 'Create Account',
      subtitle: 'Join your campus community',
      scrollable: false,
      child: AuthCard(
        expand: true,
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
        child: Column(
          children: [
            AuthStepProgress(
              currentStep: _currentStep,
              totalSteps: 4,
              labels: _stepLabels,
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            _buildNavBar(),
            if (_currentStep == 0) ...[
              SizedBox(height: 12.h),
              Center(
                child: GestureDetector(
                  onTap: () => AppNavigation.offAll(
                    () => const LoginBootstrapView(),
                    prepare: AppBootstrap.prepareLogin,
                    loadingMessage: 'Preparing login...',
                  ),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13.sp,
                      ),
                      children: [
                        TextSpan(
                          text: 'Login',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _stepFieldsValid() {
    switch (_currentStep) {
      case 0:
        final idOk = _isStudent
            ? rollNumberCtrl.text.trim().isNotEmpty
            : empNumberCtrl.text.trim().isNotEmpty;
        return idOk && departmentClassCtrl.text.trim().isNotEmpty;
      case 1:
        return nameCtrl.text.trim().isNotEmpty &&
            emailCtrl.text.trim().isNotEmpty &&
            AuthInputValidators.isValidEmail(emailCtrl.text) &&
            AuthInputValidators.isValidPhone10(phoneCtrl.text);
      case 2:
        return true; // optional step
      case 3:
        return passCtrl.text.isNotEmpty &&
            passCtrl.text.length >= 6 &&
            passCtrl.text == confirmPassCtrl.text &&
            _agreeTerms;
      default:
        return false;
    }
  }

  Widget _buildNavBar() {
    final isLast = _currentStep == 3;
    final canProceed = _stepFieldsValid();
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _back,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                side: const BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: Text(
                'Back',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 15.sp,
                ),
              ),
            ),
          ),
        if (_currentStep > 0) SizedBox(width: 12.w),
        Expanded(
          child: isLast
              ? Obx(() {
                  // Always read .value so Obx has an observable dependency.
                  final loading = controller.isLoading.value;
                  return AuthPrimaryButton(
                    label: 'Create Account',
                    loading: loading,
                    onPressed: (!canProceed || loading)
                        ? null
                        : _submit,
                  );
                })
              : AuthPrimaryButton(
                  label: 'Next',
                  onPressed: canProceed ? _next : null,
                ),
        ),
      ],
    );
  }

  Widget _stepScroll(List<Widget> children) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildStep1() {
    return _stepScroll([
      AuthSegmentedControl<bool>(
        selected: _isStudent,
        onChanged: (val) => setState(() {
          _isStudent = val;
          _serverRollEmpError = null;
          if (val) {
            empNumberCtrl.clear();
          } else {
            rollNumberCtrl.clear();
          }
        }),
        options: const [
          (value: true, label: 'Student', icon: Icons.school_outlined),
          (value: false, label: 'Faculty', icon: Icons.work_outline),
        ],
      ),
      SizedBox(height: 18.h),
      AuthTextField(
        controller: _isStudent ? rollNumberCtrl : empNumberCtrl,
        focusNode: _rollEmpFocusNode,
        label: _isStudent ? 'Roll Number' : 'Employee Number',
        prefixIcon: _isStudent ? Icons.badge_outlined : Icons.badge_outlined,
        errorText: _serverRollEmpError,
      ),
      SizedBox(height: 16.h),
      AuthTextField(
        controller: departmentClassCtrl,
        label: 'Department / Class',
        hint: 'e.g. Computer Science - Year 2',
        prefixIcon: Icons.apartment_outlined,
        textCapitalization: TextCapitalization.words,
      ),
    ]);
  }

  Widget _buildStep2() {
    return _stepScroll([
      AuthTextField(
        controller: nameCtrl,
        label: 'Full Name',
        prefixIcon: Icons.person_outline,
        textCapitalization: TextCapitalization.words,
      ),
      SizedBox(height: 16.h),
      AuthTextField(
        controller: emailCtrl,
        focusNode: _emailFocusNode,
        label: 'Email Address',
        hint: 'name@example.com',
        prefixIcon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        errorText: _serverEmailError,
      ),
      SizedBox(height: 16.h),
      AuthTextField(
        controller: phoneCtrl,
        focusNode: _phoneFocusNode,
        label: 'Phone Number',
        hint: '10-digit mobile number',
        prefixIcon: Icons.phone_outlined,
        keyboardType: TextInputType.number,
        maxLength: 10,
        inputFormatters: AuthInputValidators.phone10Digits,
        errorText: _serverPhoneError,
      ),
    ]);
  }

  Widget _buildStep3() {
    return _stepScroll([
      Text(
        'These details are optional — you can skip and add them later.',
        style: TextStyle(
          fontSize: 13.sp,
          color: AppColors.textSecondary,
        ),
      ),
      SizedBox(height: 14.h),
      AuthTextField(
        controller: bioCtrl,
        label: 'Bio',
        hint: 'Tell us about yourself...',
        prefixIcon: Icons.description_outlined,
        maxLines: 3,
      ),
      SizedBox(height: 16.h),
      Text(
        'Interests',
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
        ),
      ),
      SizedBox(height: 8.h),
      Column(
        children: [
          AuthTextField(
            controller: interestSearchCtrl,
            focusNode: _interestFocusNode,
            label: 'Search interests',
            hint: 'Search or type your interests...',
            prefixIcon: Icons.search,
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
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _addInterest(value.trim());
              }
            },
          ),
          if (_showSuggestions && _filteredInterests.isNotEmpty)
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: EdgeInsets.only(top: 4.h),
                constraints: BoxConstraints(maxHeight: 160.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  itemCount: _filteredInterests.length,
                  separatorBuilder: (_, __) =>
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        color: isSelected ? Colors.grey[100] : Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                interest,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: isSelected
                                      ? Colors.grey[600]
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: AppColors.accent,
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
              margin: EdgeInsets.only(top: 4.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                ),
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
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
      SizedBox(height: 12.h),
      if (_selectedInterests.isNotEmpty)
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _selectedInterests.map((interest) {
              return Chip(
                label: Text(interest),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeInterest(interest),
                backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
                deleteIconColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent, width: 1),
              );
            }).toList(),
          ),
        ),
      SizedBox(height: 20.h),
      Center(
        child: TextButton(
          onPressed: _skipProfile,
          child: Text(
            'Skip for now',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.accent,
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildStep4() {
    return _stepScroll([
      AuthTextField(
        controller: passCtrl,
        label: 'Password',
        prefixIcon: Icons.lock_outline,
        obscureText: _obscurePassword,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textSecondary,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      SizedBox(height: 16.h),
      AuthTextField(
        controller: confirmPassCtrl,
        label: 'Confirm Password',
        prefixIcon: Icons.lock_outline,
        obscureText: _obscureConfirm,
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirm ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textSecondary,
          ),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ),
      SizedBox(height: 16.h),
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
              activeColor: AppColors.accent,
            ),
            Expanded(
              child: GestureDetector(
                onTap: _showTermsAndConditionsDialog,
                child: RichText(
                  text: TextSpan(
                    text: 'I agree to ',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      TextSpan(
                        text: 'Terms and Conditions',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.accent,
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
    ]);
  }

  bool _validateStep1() {
    if (_isStudent && rollNumberCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(
        context,
        'Required',
        'Please enter your roll number',
      );
      return false;
    }
    if (!_isStudent && empNumberCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(
        context,
        'Required',
        'Please enter your employee ID',
      );
      return false;
    }
    if (departmentClassCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(
        context,
        'Required',
        'Please enter your department or class',
      );
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (nameCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(
        context,
        'Required',
        'Please enter your full name',
      );
      return false;
    }
    if (emailCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(
        context,
        'Required',
        'Please enter your email',
      );
      return false;
    }
    if (!emailCtrl.text.trim().contains('@') ||
        !AuthInputValidators.isValidEmail(emailCtrl.text)) {
      SweetAlertHelper.showError(
        context,
        'Invalid',
        'Please enter a valid email address (must include @)',
      );
      return false;
    }
    if (phoneCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(
        context,
        'Required',
        'Please enter your phone number',
      );
      return false;
    }
    if (!AuthInputValidators.isValidPhone10(phoneCtrl.text)) {
      SweetAlertHelper.showError(
        context,
        'Invalid',
        'Please enter a valid 10-digit mobile number',
      );
      return false;
    }
    return true;
  }

  bool _validateStep4() {
    if (passCtrl.text.isEmpty) {
      SweetAlertHelper.showError(
        context,
        'Required',
        'Please enter a password',
      );
      return false;
    }
    if (passCtrl.text.length < 6) {
      SweetAlertHelper.showError(
        context,
        'Weak',
        'Password must be at least 6 characters',
      );
      return false;
    }
    if (passCtrl.text != confirmPassCtrl.text) {
      SweetAlertHelper.showError(
        context,
        'Mismatch',
        'Passwords do not match',
      );
      return false;
    }
    if (!_agreeTerms) {
      SweetAlertHelper.showError(
        context,
        'Required',
        'Please agree to Terms and Conditions',
      );
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _registerFieldWorker?.dispose();
    _interestFilterDebounce?.cancel();
    _pageController.dispose();
    for (final c in [
      departmentClassCtrl,
      nameCtrl,
      passCtrl,
      confirmPassCtrl,
    ]) {
      c.removeListener(_onFieldChanged);
    }
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    bioCtrl.dispose();
    rollNumberCtrl.dispose();
    empNumberCtrl.dispose();
    departmentClassCtrl.dispose();
    interestSearchCtrl.dispose();
    _interestFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _rollEmpFocusNode.dispose();
    super.dispose();
  }
}
