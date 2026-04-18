import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/auth_controller.dart';
import '../data/app_branding.dart';
import '../utils/sweetalert_helper.dart';
import 'signup_view.dart';
// import 'forgot_password_view.dart'; // Email-based flow (disabled - SMS-only auth)

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthController controller = Get.put(AuthController());
  final TextEditingController identifierCtrl = TextEditingController(); // Roll/Emp ID
  final TextEditingController emailPhoneCtrl = TextEditingController(); // Email or Mobile (toggle)
  final TextEditingController otpCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isStudent = true; // Default to student
  bool _loginByMobile = false; // Toggle between email/mobile
  int _otpResendSeconds = 0;
  Timer? _otpResendTimer;

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
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Image
                  Container(
                    width: 120.w,
                    height: 120.w,
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
                      child: AppBranding.logoBox(
                        width: 96.w,
                        height: 96.w,
                        fit: BoxFit.contain,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  
                  Text(
                    "MiCampus",
                    style: TextStyle(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Discover & Join Campus Events",
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                  SizedBox(height: 48.h),
                  
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
                        Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "Login to continue",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: 32.h),
                        
                        // Student/Faculty Selection
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text("Student"),
                                value: true,
                                groupValue: _isStudent,
                                activeColor: const Color(0xFFFF5F15),
                                onChanged: (val) => setState(() {
                                  _isStudent = val!;
                                  identifierCtrl.clear();
                                }),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text("Faculty"),
                                value: false,
                                groupValue: _isStudent,
                                activeColor: const Color(0xFFFF5F15),
                                onChanged: (val) => setState(() {
                                  _isStudent = val!;
                                  identifierCtrl.clear();
                                }),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16.h),
                        
                        // Roll Number / Employee ID
                        TextField(
                          controller: identifierCtrl,
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
                        
                        // Toggle: Email / Mobile (default: Email)
                        SegmentedButton<bool>(
                          segments: const <ButtonSegment<bool>>[
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('Email'),
                              icon: Icon(Icons.email_outlined),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('Mobile'),
                              icon: Icon(Icons.phone_outlined),
                            ),
                          ],
                          selected: <bool>{_loginByMobile},
                          onSelectionChanged: (selection) {
                            setState(() {
                              _loginByMobile = selection.first;
                              emailPhoneCtrl.clear();
                              otpCtrl.clear();
                              _cancelOtpResendTimer();
                            });
                          },
                          style: ButtonStyle(
                            foregroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.white;
                              }
                              return const Color(0xFFFF5F15);
                            }),
                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return const Color(0xFFFF5F15);
                              }
                              return Colors.transparent;
                            }),
                            side: WidgetStateProperty.all(
                              BorderSide(color: const Color(0xFFFF5F15).withOpacity(0.4)),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 12.h),

                        // Email or Mobile (toggle)
                        TextField(
                          controller: emailPhoneCtrl,
                          keyboardType: _loginByMobile ? TextInputType.phone : TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: _loginByMobile ? "Mobile Number" : "Email Address",
                            prefixIcon: Icon(
                              _loginByMobile ? Icons.phone_outlined : Icons.email_outlined,
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
                        
                        if (_loginByMobile) ...[
                          SizedBox(height: 16.h),
                          Text(
                            "We will text a 6-digit code to the mobile number registered on your account.",
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                          ),
                          SizedBox(height: 12.h),
                          Obx(() => OutlinedButton.icon(
                                onPressed: (_otpResendSeconds > 0 || controller.isSendingLoginOtp.value)
                                    ? null
                                    : () => _onSendLoginOtp(),
                                icon: controller.isSendingLoginOtp.value
                                    ? SizedBox(
                                        width: 18.w,
                                        height: 18.w,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFFFF5F15),
                                        ),
                                      )
                                    : const Icon(Icons.sms_outlined, color: Color(0xFFFF5F15)),
                                label: Text(
                                  _otpResendSeconds > 0
                                      ? "Resend OTP in ${_otpResendSeconds}s"
                                      : "Send OTP via SMS",
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFF5F15),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  side: const BorderSide(color: Color(0xFFFF5F15)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              )),
                          SizedBox(height: 12.h),
                          TextField(
                            controller: otpCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              counterText: '',
                              labelText: "OTP (6 digits)",
                              prefixIcon: const Icon(Icons.pin_outlined, color: Color(0xFFFF5F15)),
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
                          SizedBox(height: 8.h),
                          Text(
                            "Or use your password",
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                          ),
                        ],
                        
                        SizedBox(height: 16.h),
                        
                        // Password (email: required; mobile: optional if OTP used)
                        TextField(
                          controller: passCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: _loginByMobile ? "Password (optional with OTP)" : "Password",
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
                        
                        SizedBox(height: 24.h),
                        
                        // Login Button
                        Obx(() => controller.isLoading.value
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5F15)))
                            : ElevatedButton(
                                onPressed: () async {
                                  if (!_validateLogin()) return;
                                  final id = identifierCtrl.text.trim();
                                  final contact = emailPhoneCtrl.text.trim();
                                  final otp = otpCtrl.text.trim();
                                  if (_loginByMobile && otp.length == 6) {
                                    await controller.loginWithIdentifier(
                                      id,
                                      contact,
                                      _isStudent,
                                      true,
                                      password: '',
                                      otp: otp,
                                    );
                                  } else {
                                    await controller.loginWithIdentifier(
                                      id,
                                      contact,
                                      _isStudent,
                                      _loginByMobile,
                                      password: passCtrl.text,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF5F15),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "Login",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              )),
                        
                        SizedBox(height: 16.h),
                        
                        // Signup Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ", style: TextStyle(color: Colors.grey[600])),
                            GestureDetector(
                              onTap: () => Get.to(() => const SignupView()),
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: Color(0xFFFF5F15),
                                  fontWeight: FontWeight.bold,
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
          ),
        ),
      ),
    );
  }

  bool _validateLogin() {
    if (identifierCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(context, "Required", _isStudent ? "Please enter your roll number" : "Please enter your employee ID");
      return false;
    }
    if (emailPhoneCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(context, "Required", _loginByMobile ? "Please enter your mobile number" : "Please enter your email");
      return false;
    }
    if (_loginByMobile) {
      if (!GetUtils.isPhoneNumber(emailPhoneCtrl.text.trim())) {
        SweetAlertHelper.showError(context, "Invalid", "Please enter a valid mobile number");
        return false;
      }
      final otp = otpCtrl.text.trim();
      if (otp.isNotEmpty && otp.length != 6) {
        SweetAlertHelper.showError(context, "Invalid", "Enter the 6-digit OTP or leave it blank to use password");
        return false;
      }
      if (otp.length != 6 && passCtrl.text.isEmpty) {
        SweetAlertHelper.showError(
          context,
          "Required",
          "Enter the OTP from SMS, or your password",
        );
        return false;
      }
    } else {
      if (!GetUtils.isEmail(emailPhoneCtrl.text.trim())) {
        SweetAlertHelper.showError(context, "Invalid", "Please enter a valid email address");
        return false;
      }
      if (passCtrl.text.isEmpty) {
        SweetAlertHelper.showError(context, "Required", "Please enter your password");
        return false;
      }
    }
    return true;
  }

  bool _validateSendOtp() {
    if (identifierCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(context, "Required", _isStudent ? "Please enter your roll number" : "Please enter your employee ID");
      return false;
    }
    if (emailPhoneCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(context, "Required", "Please enter your mobile number");
      return false;
    }
    if (!GetUtils.isPhoneNumber(emailPhoneCtrl.text.trim())) {
      SweetAlertHelper.showError(context, "Invalid", "Please enter a valid mobile number");
      return false;
    }
    return true;
  }

  Future<void> _onSendLoginOtp() async {
    if (!_validateSendOtp()) return;
    final ok = await controller.sendLoginOtp(
      identifierCtrl.text.trim(),
      emailPhoneCtrl.text.trim(),
      _isStudent,
    );
    if (!mounted || !ok) return;
    _startOtpResendCooldown();
  }

  void _startOtpResendCooldown() {
    _otpResendTimer?.cancel();
    setState(() => _otpResendSeconds = 60);
    _otpResendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_otpResendSeconds <= 1) {
          _otpResendSeconds = 0;
          t.cancel();
        } else {
          _otpResendSeconds--;
        }
      });
    });
  }

  void _cancelOtpResendTimer() {
    _otpResendTimer?.cancel();
    _otpResendTimer = null;
    _otpResendSeconds = 0;
  }

  @override
  void dispose() {
    _cancelOtpResendTimer();
    identifierCtrl.dispose();
    emailPhoneCtrl.dispose();
    otpCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }
}