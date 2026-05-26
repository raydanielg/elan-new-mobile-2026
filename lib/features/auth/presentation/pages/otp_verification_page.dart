import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../../core/widgets/custom_alert.dart';

class OtpVerificationPage extends StatefulWidget {
  final String username;
  final String? phone;

  const OtpVerificationPage({
    super.key,
    required this.username,
    this.phone,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );
  
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isOtpVerified = false;
  bool _isResending = false;
  
  int _resendCountdown = 60;
  Timer? _resendTimer;
  
  String? _otpError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0) return;
    
    setState(() => _isResending = true);
    try {
      await ApiService.instance.resetPasswordOtp(widget.username);
      if (mounted) {
        setState(() => _isResending = false);
        _startResendTimer();
        CustomAlert.show(
          context,
          title: 'OTP Resent',
          message: 'A new OTP has been sent to your phone number.',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResending = false);
        CustomAlert.show(
          context,
          title: 'Resend Failed',
          message: 'Unable to resend OTP. Please try again.',
          isSuccess: false,
        );
      }
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Auto-verify when all 4 digits are entered
    if (value.isNotEmpty && index == 3) {
      final otp = _otpControllers.map((c) => c.text).join();
      if (otp.length == 4) {
        _focusNodes[index].unfocus();
        _handleVerifyOtp();
      }
    }
  }

  void _onOtpBackspace(int index) {
    if (index > 0 && _otpControllers[index].text.isEmpty) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();

    // Reset errors
    setState(() {
      _otpError = null;
    });

    // Validate OTP
    if (otp.length != 4) {
      setState(() => _otpError = 'Please enter the 4-digit OTP code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Note: Backend doesn't have a separate OTP verification endpoint
      // We'll proceed to password reset after OTP is entered
      setState(() {
        _isLoading = false;
        _isOtpVerified = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        setState(() => _otpError = 'Invalid OTP code. Please try again.');
      }
    }
  }

  Future<void> _handleResetPassword() async {
    final otp = _otpControllers.map((c) => c.text).join();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Reset errors
    setState(() {
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    // Validate new password
    if (newPassword.isEmpty) {
      setState(() => _newPasswordError = 'New password is required');
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _newPasswordError = 'Password must be at least 6 characters');
      return;
    }

    // Validate confirm password
    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Please confirm your new password');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.instance.verifyOtpAndReset(
        username: widget.username,
        otp: otp,
        newPassword: newPassword,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        await CustomAlert.show(
          context,
          title: 'Password Reset Successful',
          message: response['message'] ?? 'Your password has been reset successfully. You can now sign in with your new password.',
          isSuccess: true,
        );
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Show user-friendly error message
        String errorMessage = 'Unable to reset password. Please try again.';
        final errorString = e.toString();
        if (errorString.contains('invalid') || errorString.contains('incorrect') || errorString.contains('wrong')) {
          errorMessage = 'Invalid OTP code. Please check the code and try again.';
          setState(() => _isOtpVerified = false);
        } else if (errorString.contains('expired') || errorString.contains('timeout')) {
          errorMessage = 'OTP code has expired. Please request a new code.';
          setState(() => _isOtpVerified = false);
        } else if (errorString.contains('network') || errorString.contains('connection')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (errorString.contains('password')) {
          errorMessage = 'Password reset failed. Please try again.';
        }
        CustomAlert.show(
          context,
          title: 'Reset Failed',
          message: errorMessage,
          isSuccess: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/onboarding/blue-lines-maze-white-background_1409-9685.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                NeoColors.background.withOpacity(0.95),
                NeoColors.background.withOpacity(0.97),
                NeoColors.background.withOpacity(0.98),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App Bar
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: NeoColors.cardBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: NeoColors.cardBorder, width: 1.5),
                          ),
                          child: IconButton(
                            icon: const Icon(LucideIcons.arrowLeft, color: NeoColors.textPrimary, size: 20),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'VERIFY OTP',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: NeoColors.textSecondary.withOpacity(0.5),
                              ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 50),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Title with gradient
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          NeoColors.textPrimary,
                          NeoColors.accentGreen,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'Enter OTP',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      widget.phone != null
                          ? 'We sent a 4-digit code to ${widget.phone}. Enter it below to verify your identity.'
                          : 'We sent a 4-digit code to your registered phone number. Enter it below to verify your identity.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NeoColors.textSecondary,
                            height: 1.5,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 36),

                    // OTP Input Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (index) {
                        return SizedBox(
                          width: 48,
                          height: 56,
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _otpError != null 
                                  ? Colors.red.withOpacity(0.7)
                                  : NeoColors.textPrimary,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: NeoColors.cardBg,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: _otpError != null 
                                      ? Colors.red.withOpacity(0.5)
                                      : NeoColors.cardBorder,
                                  width: _otpError != null ? 2 : 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: _focusNodes[index].hasFocus
                                      ? NeoColors.accentGreen
                                      : NeoColors.cardBorder,
                                  width: _focusNodes[index].hasFocus ? 2 : 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: NeoColors.accentGreen,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) => _onOtpChanged(index, value),
                            onSubmitted: (value) {
                              if (value.isEmpty) {
                                _onOtpBackspace(index);
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    if (_otpError != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 12),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.alertCircle,
                              size: 12,
                              color: Colors.red.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _otpError!,
                              style: TextStyle(
                                color: Colors.red.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Resend OTP with timer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: TextStyle(
                            color: NeoColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: _resendCountdown == 0 ? _handleResendOtp : null,
                          child: _isResending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: NeoColors.accentGreen,
                                  ),
                                )
                              : Text(
                                  _resendCountdown > 0
                                      ? 'Resend in ${_resendCountdown}s'
                                      : 'Resend',
                                  style: TextStyle(
                                    color: _resendCountdown > 0
                                        ? NeoColors.textSecondary
                                        : NeoColors.accentGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // Show password fields only after OTP is verified
                    if (_isOtpVerified) ...[
                      // New Password Field
                      _buildPasswordField(
                        controller: _newPasswordController,
                        hintText: 'New password',
                        obscureText: _obscureNewPassword,
                        errorText: _newPasswordError,
                        onToggle: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Confirm Password Field
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm new password',
                        obscureText: _obscureConfirmPassword,
                        errorText: _confirmPasswordError,
                        onToggle: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 48),
                    ] else ...[
                      const SizedBox(height: 48),
                    ],

                    // Verify/Reset Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: NeoColors.accentGreen,
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _isOtpVerified ? _handleResetPassword : _handleVerifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: NeoColors.accentGreen,
                                foregroundColor: NeoColors.background,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _isOtpVerified ? 'Reset Password' : 'Verify OTP',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required String? errorText,
    required VoidCallback onToggle,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: NeoColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? Colors.red.withOpacity(0.5) : NeoColors.cardBorder,
              width: hasError ? 2 : 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            cursorColor: NeoColors.accentGreen,
            style: const TextStyle(color: NeoColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: Icon(
                LucideIcons.lock, 
                color: hasError ? Colors.red.withOpacity(0.7) : NeoColors.textSecondary, 
                size: 20
              ),
              hintText: hintText,
              hintStyle: const TextStyle(color: NeoColors.textSecondary, fontSize: 14),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: GestureDetector(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    obscureText ? LucideIcons.eye : LucideIcons.eyeOff,
                    color: NeoColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Row(
              children: [
                Icon(
                  LucideIcons.alertCircle,
                  size: 12,
                  color: Colors.red.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  errorText!,
                  style: TextStyle(
                    color: Colors.red.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
