import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../../core/widgets/custom_alert.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _fullNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isLoadingCategories = false;
  String? _selectedLobId;
  List<Map<String, dynamic>> _lobCategories = [];
  String? _fullNameError;
  String? _businessNameError;
  String? _businessCategoryError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _fetchLobCategories();
  }

  Future<void> _fetchLobCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final response = await ApiService.instance.fetchConstants();
      if (response != null && response is Map) {
        final constants = response['constants'];
        if (constants != null && constants is Map) {
          final businessCategory = constants['business_category'];
          if (businessCategory != null && businessCategory is List) {
            setState(() {
              _lobCategories = List<Map<String, dynamic>>.from(businessCategory);
              print('Loaded ${_lobCategories.length} categories');
            });
          }
        }
      }
    } catch (e) {
      // Handle error silently or show a message
      print('Error fetching business categories: $e');
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final businessName = _businessNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Reset errors
    setState(() {
      _fullNameError = null;
      _businessNameError = null;
      _businessCategoryError = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    // Validate full name
    if (fullName.isEmpty) {
      setState(() => _fullNameError = 'Full name is required');
      return;
    }
    if (fullName.length < 2) {
      setState(() => _fullNameError = 'Full name must be at least 2 characters');
      return;
    }

    // Validate business name
    if (businessName.isEmpty) {
      setState(() => _businessNameError = 'Business name is required');
      return;
    }
    if (businessName.length < 2) {
      setState(() => _businessNameError = 'Business name must be at least 2 characters');
      return;
    }

    // Validate business category
    if (_selectedLobId == null) {
      setState(() => _businessCategoryError = 'Business category is required');
      return;
    }

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

    // Validate phone
    if (phone.isEmpty) {
      setState(() => _phoneError = 'Phone number is required');
      return;
    }
    if (phone.length < 9) {
      setState(() => _phoneError = 'Please enter a valid phone number');
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

    // Validate confirm password
    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Please confirm your password');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.instance.register(
        username: fullName,
        shopName: businessName,
        shopType: 'Retail',
        phone: '+255$phone',
        email: email,
        password: password,
        country: 'Tanzania',
        iso: 'TZ',
        lobId: _selectedLobId,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        await CustomAlert.show(
          context,
          title: 'Account Created',
          message: response['message'] ?? 'Your account has been created successfully! You can now sign in.',
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
        String errorMessage = 'Unable to create account. Please try again.';
        final errorString = e.toString();
        if (errorString.contains('email') || errorString.contains('already exists')) {
          errorMessage = 'This email is already registered. Please use a different email or sign in.';
        } else if (errorString.contains('phone') || errorString.contains('mobile')) {
          errorMessage = 'This phone number is already registered. Please use a different number.';
        } else if (errorString.contains('network') || errorString.contains('connection')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (errorString.contains('password')) {
          errorMessage = 'Password is too weak. Please use a stronger password.';
        }
        CustomAlert.show(
          context,
          title: 'Registration Failed',
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
                    const SizedBox(height: 16),

                    // Title with gradient
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          NeoColors.textPrimary,
                          NeoColors.accentGreen,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'Create account',
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
                      'Fill in your details below to get started. You\'ll be able to sign in once your account is created.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NeoColors.textSecondary,
                            height: 1.5,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 28),

                    // Full Name Input
                    _buildInputField(
                      controller: _fullNameController,
                      hintText: 'Full name',
                      icon: LucideIcons.user,
                      errorText: _fullNameError,
                    ),
                    const SizedBox(height: 16),

                    // Business Name Input
                    _buildInputField(
                      controller: _businessNameController,
                      hintText: 'Business name',
                      icon: LucideIcons.building2,
                      errorText: _businessNameError,
                    ),
                    const SizedBox(height: 16),

                    // Business Category Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: NeoColors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _businessCategoryError != null ? Colors.red.withOpacity(0.5) : NeoColors.cardBorder,
                              width: _businessCategoryError != null ? 2 : 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.layers,
                                color: _businessCategoryError != null ? Colors.red.withOpacity(0.7) : NeoColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _isLoadingCategories
                                    ? const Text(
                                        'Loading categories...',
                                        style: TextStyle(color: NeoColors.textSecondary, fontSize: 15),
                                      )
                                    : DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          hint: const Text(
                                            'Select business category',
                                            style: TextStyle(color: NeoColors.textSecondary, fontSize: 15),
                                          ),
                                          value: _selectedLobId,
                                          isExpanded: true,
                                          icon: const Icon(LucideIcons.chevronDown, size: 20, color: NeoColors.textSecondary),
                                          style: const TextStyle(color: NeoColors.textPrimary, fontSize: 15),
                                          dropdownColor: NeoColors.cardBg,
                                          items: _lobCategories.isEmpty
                                              ? []
                                              : _lobCategories.map((category) {
                                                  return DropdownMenuItem<String>(
                                                    value: category['lob_id']?.toString(),
                                                    child: Text(
                                                      category['lob_name']?.toString() ?? 'Unknown',
                                                      style: const TextStyle(color: NeoColors.textPrimary, fontSize: 15),
                                                    ),
                                                  );
                                                }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedLobId = value;
                                              _businessCategoryError = null;
                                            });
                                          },
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        if (_businessCategoryError != null)
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
                                  _businessCategoryError!,
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
                    const SizedBox(height: 16),

                    // Email Input
                    _buildInputField(
                      controller: _emailController,
                      hintText: 'Enter your email address',
                      icon: LucideIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                    ),
                    const SizedBox(height: 16),

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
                              // Tanzanian flag and "+255" prefix (matches screenshot)
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
                    const SizedBox(height: 16),

                    // Password Input
                    _buildInputField(
                      controller: _passwordController,
                      hintText: 'Create a password',
                      icon: LucideIcons.lock,
                      obscureText: _obscurePassword,
                      errorText: _passwordError,
                      suffix: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        child: Icon(
                          _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                          color: NeoColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Input
                    _buildInputField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm your password',
                      icon: LucideIcons.lock,
                      obscureText: _obscureConfirmPassword,
                      errorText: _confirmPasswordError,
                      suffix: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        child: Icon(
                          _obscureConfirmPassword ? LucideIcons.eye : LucideIcons.eyeOff,
                          color: NeoColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Continue Button
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
                              onPressed: _handleRegister,
                            ),
                    ),
                    const SizedBox(height: 16),
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
