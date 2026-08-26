import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/auth_controller.dart';
import '../data/app_bootstrap.dart';
import '../theme/app_theme.dart';
import '../utils/app_navigation.dart';
import '../utils/sweetalert_helper.dart';
import '../widgets/auth_widgets.dart';
import 'signup_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthController controller = Get.put(AuthController());
  final TextEditingController identifierCtrl = TextEditingController();
  final TextEditingController emailPhoneCtrl = TextEditingController();
  final TextEditingController otpCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isStudent = true;
  bool _loginByMobile = false;

  Future<void> _onLogin() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return AuthGradientScaffold(
      title: 'MiCampus',
      subtitle: 'Discover & Join Campus Events',
      child: AuthCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              'Login to continue',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 28.h),
            AuthSegmentedControl<bool>(
              selected: _isStudent,
              onChanged: (val) => setState(() {
                _isStudent = val;
                identifierCtrl.clear();
              }),
              options: const [
                (value: true, label: 'Student', icon: Icons.school_outlined),
                (value: false, label: 'Faculty', icon: Icons.work_outline),
              ],
            ),
            SizedBox(height: 18.h),
            AuthTextField(
              controller: identifierCtrl,
              label: _isStudent ? 'Roll Number' : 'Employee ID',
              prefixIcon: _isStudent ? Icons.badge_outlined : Icons.work_outline,
            ),
            SizedBox(height: 16.h),
            AuthSegmentedControl<bool>(
              selected: _loginByMobile,
              onChanged: (val) => setState(() {
                _loginByMobile = val;
                emailPhoneCtrl.clear();
                otpCtrl.clear();
              }),
              options: const [
                (value: false, label: 'Email', icon: Icons.email_outlined),
                (value: true, label: 'Mobile', icon: Icons.phone_outlined),
              ],
            ),
            SizedBox(height: 12.h),
            AuthTextField(
              controller: emailPhoneCtrl,
              label: _loginByMobile ? 'Mobile Number' : 'Email Address',
              prefixIcon:
                  _loginByMobile ? Icons.phone_outlined : Icons.email_outlined,
              keyboardType: _loginByMobile
                  ? TextInputType.phone
                  : TextInputType.emailAddress,
            ),
            if (_loginByMobile) ...[
              SizedBox(height: 14.h),
              Text(
                'We will text a 6-digit code to the mobile number registered on your account.',
                style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
              ),
              SizedBox(height: 12.h),
              _LoginOtpResendButton(
                controller: controller,
                onSend: _onSendLoginOtp,
              ),
              SizedBox(height: 12.h),
              AuthTextField(
                controller: otpCtrl,
                label: 'OTP (6 digits)',
                prefixIcon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              SizedBox(height: 8.h),
              Text(
                'Or use your password',
                style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
              ),
            ],
            SizedBox(height: 16.h),
            AuthTextField(
              controller: passCtrl,
              label: _loginByMobile ? 'Password (optional with OTP)' : 'Password',
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
            SizedBox(height: 24.h),
            Obx(
              () => AuthPrimaryButton(
                label: 'Login',
                loading: controller.isLoading.value,
                onPressed: controller.isLoading.value ? null : _onLogin,
              ),
            ),
            SizedBox(height: 18.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
                ),
                GestureDetector(
                  onTap: () => AppNavigation.to(
                    () => const SignupView(),
                    prepare: AppBootstrap.prepareLogin,
                    loadingMessage: 'Loading...',
                  ),
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _validateLogin() {
    if (identifierCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(
        context,
        'Required',
        _isStudent
            ? 'Please enter your roll number'
            : 'Please enter your employee ID',
      );
      return false;
    }
    if (emailPhoneCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(
        context,
        'Required',
        _loginByMobile
            ? 'Please enter your mobile number'
            : 'Please enter your email',
      );
      return false;
    }
    if (_loginByMobile) {
      if (!GetUtils.isPhoneNumber(emailPhoneCtrl.text.trim())) {
        SweetAlertHelper.showError(
          context,
          'Invalid',
          'Please enter a valid mobile number',
        );
        return false;
      }
      final otp = otpCtrl.text.trim();
      if (otp.isNotEmpty && otp.length != 6) {
        SweetAlertHelper.showError(
          context,
          'Invalid',
          'Enter the 6-digit OTP or leave it blank to use password',
        );
        return false;
      }
      if (otp.length != 6 && passCtrl.text.isEmpty) {
        SweetAlertHelper.showError(
          context,
          'Required',
          'Enter the OTP from SMS, or your password',
        );
        return false;
      }
    } else {
      if (!GetUtils.isEmail(emailPhoneCtrl.text.trim())) {
        SweetAlertHelper.showError(
          context,
          'Invalid',
          'Please enter a valid email address',
        );
        return false;
      }
      if (passCtrl.text.isEmpty) {
        SweetAlertHelper.showError(
          context,
          'Required',
          'Please enter your password',
        );
        return false;
      }
    }
    return true;
  }

  bool _validateSendOtp() {
    if (identifierCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(
        context,
        'Required',
        _isStudent
            ? 'Please enter your roll number'
            : 'Please enter your employee ID',
      );
      return false;
    }
    if (emailPhoneCtrl.text.trim().isEmpty) {
      SweetAlertHelper.showError(
        context,
        'Required',
        'Please enter your mobile number',
      );
      return false;
    }
    if (!GetUtils.isPhoneNumber(emailPhoneCtrl.text.trim())) {
      SweetAlertHelper.showError(
        context,
        'Invalid',
        'Please enter a valid mobile number',
      );
      return false;
    }
    return true;
  }

  Future<bool> _onSendLoginOtp() async {
    if (!_validateSendOtp()) return false;
    return controller.sendLoginOtp(
      identifierCtrl.text.trim(),
      emailPhoneCtrl.text.trim(),
      _isStudent,
    );
  }

  @override
  void dispose() {
    identifierCtrl.dispose();
    emailPhoneCtrl.dispose();
    otpCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }
}

class _LoginOtpResendButton extends StatefulWidget {
  final AuthController controller;
  final Future<bool> Function() onSend;

  const _LoginOtpResendButton({
    required this.controller,
    required this.onSend,
  });

  @override
  State<_LoginOtpResendButton> createState() => _LoginOtpResendButtonState();
}

class _LoginOtpResendButtonState extends State<_LoginOtpResendButton> {
  int _otpResendSeconds = 0;
  Timer? _otpResendTimer;

  Future<void> _handleSend() async {
    final ok = await widget.onSend();
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

  @override
  void dispose() {
    _otpResendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => OutlinedButton.icon(
        onPressed: (_otpResendSeconds > 0 ||
                widget.controller.isSendingLoginOtp.value)
            ? null
            : _handleSend,
        icon: widget.controller.isSendingLoginOtp.value
            ? SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              )
            : const Icon(Icons.sms_outlined, color: AppColors.accent),
        label: Text(
          _otpResendSeconds > 0
              ? 'Resend OTP in ${_otpResendSeconds}s'
              : 'Send OTP via SMS',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          side: const BorderSide(color: AppColors.accent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
    );
  }
}
