import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../utils/auth_input_validators.dart';
import '../utils/sweetalert_helper.dart';
import '../widgets/auth_widgets.dart';

/// 3-step password reset: identifier → OTP → new password.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final AuthController controller = Get.find<AuthController>();
  final PageController _pageController = PageController();

  final identifierCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  int _currentStep = 0;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _confirmPasswordError;

  static const _stepLabels = ['Account', 'Verify OTP', 'New Password'];

  @override
  void initState() {
    super.initState();
    controller.clearForgotPasswordState();
    controller.isLoading.value = false;
  }

  Future<void> _requestOtp() async {
    final id = identifierCtrl.text.trim();
    if (id.isEmpty) {
      SweetAlertHelper.showError(
        context,
        'Required',
        'Enter your roll number, employee ID, email, or mobile number',
      );
      return;
    }
    final ok = await controller.requestForgotPasswordOtp(id);
    if (!mounted || !ok) return;
    _goToStep(1);
  }

  Future<void> _verifyOtp() async {
    final otp = otpCtrl.text.trim();
    if (otp.length != 6) {
      SweetAlertHelper.showError(context, 'Invalid', 'Enter the 6-digit OTP');
      return;
    }
    final ok = await controller.verifyForgotPasswordOtp(
      identifier: identifierCtrl.text.trim(),
      otp: otp,
    );
    if (!mounted || !ok) return;
    _goToStep(2);
  }

  Future<void> _resetPassword() async {
    final pass = passCtrl.text;
    final confirm = confirmPassCtrl.text;
    if (pass.length < 6) {
      SweetAlertHelper.showError(
        context,
        'Invalid',
        'Password must be at least 6 characters',
      );
      return;
    }
    if (pass != confirm) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      return;
    }
    setState(() => _confirmPasswordError = null);
    await controller.resetPasswordWithToken(
      password: pass,
      passwordConfirm: confirm,
    );
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_currentStep == 0) {
      Get.back();
      return;
    }
    _goToStep(_currentStep - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    identifierCtrl.dispose();
    otpCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthGradientScaffold(
      title: 'Forgot Password',
      subtitle: 'Reset access to your account',
      scrollable: false,
      child: AuthCard(
        expand: true,
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
        child: Column(
          children: [
            AuthStepProgress(
              currentStep: _currentStep,
              totalSteps: 3,
              labels: _stepLabels,
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildStepIdentifier(),
                  _buildStepOtp(),
                  _buildStepPassword(),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            _buildNavBar(),
            SizedBox(height: 8.h),
            Center(
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Text(
                  'Back to Login',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    return Obx(() {
      final loading = controller.isLoading.value;
      final labels = ['Send OTP', 'Verify OTP', 'Reset Password'];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_currentStep > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: loading ? null : _back,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '← Back',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) SizedBox(height: 8.h),
          AuthPrimaryButton(
            label: labels[_currentStep],
            loading: loading,
            onPressed: loading
                ? null
                : () {
                    if (_currentStep == 0) {
                      _requestOtp();
                    } else if (_currentStep == 1) {
                      _verifyOtp();
                    } else {
                      _resetPassword();
                    }
                  },
          ),
        ],
      );
    });
  }

  Widget _inlineError() {
    return Obx(() {
      final err = controller.forgotPasswordError.value;
      if (err == null || err.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Text(
          err,
          style: TextStyle(color: AppColors.error, fontSize: 13.sp),
        ),
      );
    });
  }

  Widget _buildStepIdentifier() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter your roll number, employee ID, email, or mobile number. '
            'We will send a one-time code to reset your password.',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: 20.h),
          _inlineError(),
          AuthTextField(
            controller: identifierCtrl,
            label: 'Roll / Employee ID / Email / Mobile',
            prefixIcon: Icons.person_outline,
            hint: 'Your account identifier',
          ),
        ],
      ),
    );
  }

  Widget _buildStepOtp() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() {
            final channel = controller.forgotOtpChannel.value;
            final masked = controller.forgotOtpMasked.value;
            final channelLabel = channel == 'sms'
                ? 'SMS'
                : channel == 'email'
                    ? 'email'
                    : (channel ?? 'your contact');
            return Text(
              masked != null && masked.isNotEmpty
                  ? 'We sent a 6-digit code via $channelLabel to $masked'
                  : 'Enter the 6-digit code we sent you',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            );
          }),
          SizedBox(height: 20.h),
          _inlineError(),
          AuthTextField(
            controller: otpCtrl,
            label: 'OTP (6 digits)',
            prefixIcon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: AuthInputValidators.otp6Digits,
          ),
          SizedBox(height: 16.h),
          _ForgotOtpResendButton(
            controller: controller,
            onSend: () => controller.resendForgotPasswordOtp(
              identifierCtrl.text.trim(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPassword() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose a new password for your account.',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: 20.h),
          _inlineError(),
          AuthTextField(
            controller: passCtrl,
            label: 'New Password',
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
            errorText: _confirmPasswordError,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            onChanged: (_) {
              if (_confirmPasswordError != null &&
                  passCtrl.text == confirmPassCtrl.text) {
                setState(() => _confirmPasswordError = null);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ForgotOtpResendButton extends StatefulWidget {
  final AuthController controller;
  final Future<bool> Function() onSend;

  const _ForgotOtpResendButton({
    required this.controller,
    required this.onSend,
  });

  @override
  State<_ForgotOtpResendButton> createState() => _ForgotOtpResendButtonState();
}

class _ForgotOtpResendButtonState extends State<_ForgotOtpResendButton> {
  int _otpResendSeconds = 60;
  Timer? _otpResendTimer;

  @override
  void initState() {
    super.initState();
    _startOtpResendCooldown();
  }

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
                widget.controller.isSendingForgotOtp.value)
            ? null
            : _handleSend,
        icon: widget.controller.isSendingForgotOtp.value
            ? SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              )
            : const Icon(Icons.refresh, color: AppColors.accent),
        label: Text(
          _otpResendSeconds > 0
              ? 'Resend OTP in ${_otpResendSeconds}s'
              : 'Resend OTP',
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
