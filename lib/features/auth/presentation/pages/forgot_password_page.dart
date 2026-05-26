import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../../core/widgets/custom_alert.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _phoneError;
  String? _sentPhone;

  Future<void> _handleReset() async {
    final phone = _phoneController.text.trim();

    // Reset error
    setState(() => _phoneError = null);

    // Validate phone
    if (phone.isEmpty) {
      setState(() => _phoneError = 'Phone number is required');
      return;
    }
    
    if (phone.length < 9) {
      setState(() => _phoneError = 'Please enter a valid phone number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.instance.resetPasswordOtp('+255$phone');

      if (mounted) {
        setState(() => _isLoading = false);
        
        // Navigate to OTP verification page
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/otp-verification',
            arguments: {
              'username': '+255$phone',
              'phone': '+255$phone',
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Show user-friendly error message
        String errorMessage = 'Unable to send OTP. Please try again.';
        final errorString = e.toString();
        if (errorString.contains('not found') || errorString.contains('does not exist')) {
          errorMessage = 'Phone number not registered. Please check your number or contact support.';
        } else if (errorString.contains('network') || errorString.contains('connection')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (errorString.contains('rate limit') || errorString.contains('too many')) {
          errorMessage = 'Too many attempts. Please wait a few minutes before trying again.';
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
                          'RESET PASSWORD',
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
                        'Recover access',
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
                      'Enter your registered phone number below. We will send you an OTP SMS to regain access to your ledger.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NeoColors.textSecondary,
                            height: 1.5,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 36),

                    // Phone Number Input with 🇹🇿 Tanzania country code and "+255" prefix
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: NeoColors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _phoneError != null ? Colors.red.withOpacity(0.5) : NeoColors.cardBorder,
                              width: _phoneError != null ? 2 : 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.smartphone, 
                                color: _phoneError != null ? Colors.red.withOpacity(0.7) : NeoColors.textSecondary, 
                                size: 20
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '🇹🇿 +255',
                                style: TextStyle(
                                  color: NeoColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 1.5,
                                height: 24,
                                color: NeoColors.cardBorder,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  cursorColor: NeoColors.accentGreen,
                                  style: const TextStyle(color: NeoColors.textPrimary, fontSize: 15),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your phone number',
                                    hintStyle: TextStyle(color: NeoColors.textSecondary, fontSize: 14),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_phoneError != null)
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
                                  _phoneError!,
                                  style: TextStyle(
                                    color: Colors.red.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Reset Button
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
                              onPressed: _handleReset,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: NeoColors.accentGreen,
                                foregroundColor: NeoColors.background,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Send Reset OTP',
                                style: TextStyle(
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
}
