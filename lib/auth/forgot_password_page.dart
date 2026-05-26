import 'package:flutter/material.dart';
import '../api/api_service.dart';

const Color _kMaroonPrimary = Color(0xFF800000);

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedLanguage = 'English';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ApiService.instance.auth.resetSendOtp(
        username: _emailController.text.trim(),
      );
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_selectedLanguage == 'English'
              ? 'OTP sent. Please check your phone/email.'
              : 'OTP imetumwa. Tafadhali angalia simu/email yako.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/onboarding/elanbrandlogo.png',
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your Smart Business manager.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildMenuItem(
              title: 'Go back?',
              action: 'Back to Login',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required String action,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      subtitle: Text(
        action,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _kMaroonPrimary,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      drawer: _buildDrawer(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image covering full screen
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/onboarding/abstract-wavy-lines-pattern-light-gray-white-background_1246797-2872.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Semi-transparent overlay
          Container(
            color: Colors.white.withOpacity(0.85),
          ),
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Menu icon
                    IconButton(
                      onPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      icon: const Icon(Icons.menu, color: Colors.black87),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 30),
                    // Welcome text with wave emoji
                    Row(
                      children: [
                        Text(
                          _selectedLanguage == 'English' ? 'Reset' : 'Weka Upya',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                    const Text('🔐', style: TextStyle(fontSize: 28)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      _selectedLanguage == 'English'
                          ? 'Reset your Elanledgers password'
                          : 'Weka upya neno lako la siri la Elanledgers',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            controller: _emailController,
                            label: _selectedLanguage == 'English'
                                ? 'Email or phone'
                                : 'Barua pepe au simu',
                            hint: _selectedLanguage == 'English'
                                ? 'Enter email or phone'
                                : 'Weka barua pepe au simu',
                            icon: Icons.person_outline,
                            validator: (v) => (v?.trim().isEmpty ?? true)
                                ? (_selectedLanguage == 'English'
                                    ? 'This field is required'
                                    : 'Sehemu hii inahitajika')
                                : null,
                          ),
                          const SizedBox(height: 20),
                          // New Password
                          _buildTextField(
                            controller: _passwordController,
                            label: _selectedLanguage == 'English'
                                ? 'New Password'
                                : 'Neno la Siri Jipya',
                            hint: _selectedLanguage == 'English'
                                ? 'Enter new password'
                                : 'Weka neno la siri jipya',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            validator: (v) {
                              if (v?.isEmpty ?? true) {
                                return _selectedLanguage == 'English'
                                    ? 'Password is required'
                                    : 'Neno la siri linahitajika';
                              }
                              if ((v?.length ?? 0) < 6) {
                                return _selectedLanguage == 'English'
                                    ? 'Password must be at least 6 characters'
                                    : 'Neno la siri lazima liwe na angalau herufi 6';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Confirm Password
                          _buildTextField(
                            controller: _confirmPasswordController,
                            label: _selectedLanguage == 'English'
                                ? 'Confirm Password'
                                : 'Thibitisha Neno la Siri',
                            hint: _selectedLanguage == 'English'
                                ? 'Re-enter password'
                                : 'Weka tena neno la siri',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            onToggleVisibility: () => setState(
                              () => _obscureConfirmPassword = !_obscureConfirmPassword,
                            ),
                            validator: (v) {
                              if (v?.isEmpty ?? true) {
                                return _selectedLanguage == 'English'
                                    ? 'Please confirm your password'
                                    : 'Tafadhali thibitisha neno lako la siri';
                              }
                              if (v != _passwordController.text) {
                                return _selectedLanguage == 'English'
                                    ? 'Passwords do not match'
                                    : 'Maneno ya siri hayalingani';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          // Simple Reset Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: _kMaroonPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _selectedLanguage == 'English'
                                          ? 'Reset Password'
                                          : 'Weka Upya Neno la Siri',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
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
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: _kMaroonPrimary,
              size: 20,
            ),
            suffixIcon: isPassword && onToggleVisibility != null
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: _kMaroonPrimary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
          ),
        ),
      ],
    );
  }
}
