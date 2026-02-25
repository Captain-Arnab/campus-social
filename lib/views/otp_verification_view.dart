import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../controllers/auth_controller.dart';

class OtpVerificationView extends StatefulWidget {
  final String emailOrPhone;
  final bool isMobile;
  final VoidCallback onVerified;
  
  const OtpVerificationView({
    super.key,
    required this.emailOrPhone,
    required this.isMobile,
    required this.onVerified,
  });

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  final AuthController controller = Get.find<AuthController>();
  final TextEditingController otpController = TextEditingController();
  int remainingSeconds = 300; // 5 minutes
  
  @override
  void initState() {
    super.initState();
    _startTimer();
  }
  
  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && remainingSeconds > 0) {
        setState(() => remainingSeconds--);
        _startTimer();
      }
    });
  }
  
  String get timerText {
    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF5F15),
        title: const Text('Verify OTP'),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40.h),
            Icon(
              widget.isMobile ? Icons.sms : Icons.email,
              size: 80.w,
              color: const Color(0xFFFF5F15),
            ),
            SizedBox(height: 24.h),
            Text(
              'Verification Code',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'We have sent a verification code to',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              widget.emailOrPhone,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF5F15),
              ),
            ),
            SizedBox(height: 40.h),
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: otpController,
              keyboardType: TextInputType.number,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 50.h,
                fieldWidth: 45.w,
                activeFillColor: Colors.white,
                selectedFillColor: Colors.white,
                inactiveFillColor: Colors.white,
                activeColor: const Color(0xFFFF5F15),
                selectedColor: const Color(0xFFFF5F15),
                inactiveColor: Colors.grey[300]!,
              ),
              enableActiveFill: true,
              onCompleted: (value) {
                _verifyOtp();
              },
            ),
            SizedBox(height: 24.h),
            Text(
              'Time remaining: $timerText',
              style: TextStyle(
                fontSize: 14.sp,
                color: remainingSeconds < 60 ? Colors.red : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: otpController.text.length == 6 ? _verifyOtp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5F15),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 48.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(
                'Verify OTP',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16.h),
            TextButton(
              onPressed: remainingSeconds == 0
                  ? () async {
                      // OTP disabled temporarily.
                      final sent = await controller.sendLoginOtp(widget.emailOrPhone, true);
                      if (sent) {
                        setState(() => remainingSeconds = 300);
                      }
                    }
                  : null,
              child: Text(
                'Resend OTP',
                style: TextStyle(
                  color: remainingSeconds == 0 ? const Color(0xFFFF5F15) : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _verifyOtp() {
    if (controller.verifyOtp(otpController.text)) {
      widget.onVerified();
    }
  }
  
  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }
}