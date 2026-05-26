import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../../core/widgets/custom_alert.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Reset errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // Validate email
    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      return;
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      return;
    }

    // Validate password
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      return;
    }
    
    if (password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.instance.signin(email, password);
      
      if (mounted) {
        setState(() => _isLoading = false);
        // Show stunning SweetAlert-like success popup
        await CustomAlert.show(
          context,
          title: 'Success',
          message: response['message'] ?? 'Signed in successfully!',
          isSuccess: true,
        );
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Show user-friendly error message
        String errorMessage = 'Unable to sign in. Please check your credentials and try again.';
        final errorString = e.toString();
        if (errorString.contains('invalid') || errorString.contains('credentials')) {
          errorMessage = 'Invalid email or password. Please try again.';
        } else if (errorString.contains('network') || errorString.contains('connection')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (errorString.contains('not found') || errorString.contains('does not exist')) {
          errorMessage = 'Account not found. Please check your email or create an account.';
        }
        CustomAlert.show(
          context,
          title: 'Sign In Failed',
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
                              Navigator.pushReplacementNamed(context, '/');
                            },
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'ELAN LEDGERS',
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

                    // Main Header Title with gradient
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          NeoColors.textPrimary,
                          NeoColors.accentGreen,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'Sign in',
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
                      'Enter your registered email address and your account password to continue.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NeoColors.textSecondary,
                            height: 1.5,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 36),

                    // Email Field
                    _buildInputField(
                      controller: _emailController,
                      hintText: 'Enter your email address',
                      icon: LucideIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    _buildInputField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      hintText: 'Enter your password',
                      icon: LucideIcons.lock,
                      obscureText: _obscurePassword,
                      errorText: _passwordError,
                      suffix: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                          // Keep focus on the password field
                          _passwordFocusNode.requestFocus();
                        },
                        child: Icon(
                          _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                          color: NeoColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Forgot Password Link
                    Row(
                      children: [
                        Text(
                          'Forgot your password? ',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NeoColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/forgot-password');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: NeoColors.accentGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Reset it here',
                              style: TextStyle(
                                color: NeoColors.accentGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: NeoColors.accentGreen,
                              ),
                            )
                          : NeoButton(
                              text: 'Continue',
                              onPressed: _handleLogin,
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Register Redirect
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NeoColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              color: NeoColors.accentGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildInputField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
    String? errorText,
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
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            cursorColor: NeoColors.accentGreen,
            style: const TextStyle(color: NeoColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon, 
                color: hasError ? Colors.red.withOpacity(0.7) : NeoColors.textSecondary, 
                size: 20
              ),
              hintText: hintText,
              hintStyle: const TextStyle(color: NeoColors.textSecondary, fontSize: 14),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: suffix != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: suffix,
                    )
                  : null,
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
