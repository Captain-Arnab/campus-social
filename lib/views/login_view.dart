import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/auth_controller.dart';
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
  final TextEditingController passCtrl = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isStudent = true; // Default to student
  bool _loginByMobile = false; // Toggle between email/mobile

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
                      child: Image.asset(
                        'assets/images/logo.jpeg',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.event, size: 60.w, color: const Color(0xFFFF5F15));
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  
                  Text(
                    "Campus Social",
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
                        
                        SizedBox(height: 8.h),
                        
                        // (Toggle moved above input field)
                        
                        SizedBox(height: 24.h),
                        
                        // Login Button
                        Obx(() => controller.isLoading.value
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5F15)))
                            : ElevatedButton(
                                onPressed: () async {
                                  if (!_validateLogin()) return;
                                  
                                  // OTP disabled temporarily: login directly.
                                  await controller.loginWithIdentifier(
                                    identifierCtrl.text.trim(),
                                    emailPhoneCtrl.text.trim(),
                                    passCtrl.text,
                                    _isStudent,
                                    _loginByMobile, // byMobile
                                  );
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
    } else {
      if (!GetUtils.isEmail(emailPhoneCtrl.text.trim())) {
        SweetAlertHelper.showError(context, "Invalid", "Please enter a valid email address");
        return false;
      }
    }
    if (passCtrl.text.isEmpty) {
      SweetAlertHelper.showError(context, "Required", "Please enter your password");
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    identifierCtrl.dispose();
    emailPhoneCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }
}