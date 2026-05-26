import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../../core/api/api_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Header with back button
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: NeoColors.cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: NeoColors.cardBorder, width: 1.5),
                      ),
                      child: const Icon(
                        LucideIcons.arrowLeft,
                        color: NeoColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Profile Avatar Section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: NeoColors.accentGreen,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: Container(
                          color: NeoColors.cardBg,
                          child: const Icon(
                            LucideIcons.user,
                            color: NeoColors.textSecondary,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'John Doe',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'john.doe@example.com',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NeoColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Profile Options
              _buildProfileOption(
                context,
                icon: LucideIcons.user,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                onTap: () {},
              ),
              const SizedBox(height: 16),
              _buildProfileOption(
                context,
                icon: LucideIcons.lock,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () {},
              ),
              const SizedBox(height: 16),
              _buildProfileOption(
                context,
                icon: LucideIcons.bell,
                title: 'Notifications',
                subtitle: 'Manage notification preferences',
                onTap: () {},
              ),
              const SizedBox(height: 16),
              _buildProfileOption(
                context,
                icon: LucideIcons.store,
                title: 'Shop Settings',
                subtitle: 'Configure your shop details',
                onTap: () {},
              ),
              const SizedBox(height: 16),
              _buildProfileOption(
                context,
                icon: LucideIcons.helpCircle,
                title: 'Help & Support',
                subtitle: 'Get help with your account',
                onTap: () {},
              ),
              const SizedBox(height: 16),
              _buildProfileOption(
                context,
                icon: LucideIcons.shield,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                onTap: () {},
              ),
              const SizedBox(height: 40),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: NeoButton(
                  text: 'Logout',
                  icon: LucideIcons.logOut,
                  isSecondary: true,
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: NeoColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: NeoColors.cardBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: NeoColors.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: NeoColors.accentGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: NeoColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: NeoColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: NeoColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeoColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: NeoColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: NeoColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: NeoColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          NeoButton(
            text: 'Logout',
            height: 44,
            onPressed: () async {
              await ApiService.instance.signout();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
