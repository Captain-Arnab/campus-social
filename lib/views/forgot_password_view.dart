import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/auth_controller.dart';
import '../utils/sweetalert_helper.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final AuthController controller = Get.find<AuthController>();
  final emailCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF5F15),
              Color(0xFFE04E0B),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_reset, size: 60.w, color: Colors.white),
                  ),
                  SizedBox(height: 24.h),
                  
                  Text(
                    "Forgot Password?",
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Don't worry, we'll help you reset it",
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
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
                        Icon(
                          Icons.email_outlined,
                          size: 60.w,
                          color: const Color(0xFFFF5F15),
                        ),
                        SizedBox(height: 20.h),
                        
                        Text(
                          "Reset Password",
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "Enter your registered email address and we'll send you instructions to reset your password",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: 32.h),
                        
                        TextField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email Address",
                            hintText: "Enter your email",
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
                        
                        SizedBox(height: 32.h),
                        
                        Obx(() => controller.isLoading.value
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5F15)))
                            : ElevatedButton(
                                onPressed: () {
                                  if (emailCtrl.text.trim().isEmpty) {
                                    SweetAlertHelper.showError(context, "Required", "Please enter your email address");
                                    return;
                                  }
                                  controller.forgotPassword(emailCtrl.text.trim());
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF5F15),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "Send Reset Link",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              )),
                        
                        SizedBox(height: 16.h),
                        
                        Center(
                          child: GestureDetector(
                            onTap: () => Get.back(),
                            child: Text(
                              "Back to Login",
                              style: TextStyle(
                                color: const Color(0xFFFF5F15),
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white, size: 20),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            "If you don't receive an email within 5 minutes, please check your spam folder",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12.sp,
                            ),
                          ),
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
}