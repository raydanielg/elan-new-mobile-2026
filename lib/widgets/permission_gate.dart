import 'package:flutter/material.dart';
import '../services/permission_service.dart';

/// Widget that conditionally shows/hides content based on user permissions
class PermissionGate extends StatelessWidget {
  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
    this.showPlaceholder = false,
  });

  /// Permission key required to show the child
  final String permission;
  
  /// Widget to show if permission is granted
  final Widget child;
  
  /// Widget to show if permission is denied (optional)
  final Widget? fallback;
  
  /// If true, shows a placeholder container when permission is denied
  final bool showPlaceholder;

  @override
  Widget build(BuildContext context) {
    final hasPerm = PermissionService().hasPermission(permission);
    
    if (hasPerm) {
      return child;
    }
    
    if (fallback != null) {
      return fallback!;
    }
    
    if (showPlaceholder) {
      return const SizedBox.shrink();
    }
    
    return const SizedBox.shrink();
  }
}

/// Widget that shows a permission denied message
class PermissionDenied extends StatelessWidget {
  const PermissionDenied({
    super.key,
    this.message,
    this.icon,
    this.onRequestPermission,
  });

  final String? message;
  final IconData? icon;
  final VoidCallback? onRequestPermission;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.lock_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'You do not have permission to access this feature.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (onRequestPermission != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRequestPermission,
                icon: const Icon(Icons.person_add),
                label: const Text('Request Access'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget that wraps a button/ action and shows a permission denied dialog when tapped without permission
class PermissionProtected extends StatelessWidget {
  const PermissionProtected({
    super.key,
    required this.permission,
    required this.child,
    this.onDenied,
    this.showSnackbar = true,
  });

  final String permission;
  final Widget child;
  final VoidCallback? onDenied;
  final bool showSnackbar;

  void _handleTap(BuildContext context) {
    final hasPerm = PermissionService().hasPermission(permission);
    
    if (!hasPerm) {
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have permission to perform this action'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      onDenied?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: AbsorbPointer(
        absorbing: !PermissionService().hasPermission(permission),
        child: Opacity(
          opacity: PermissionService().hasPermission(permission) ? 1.0 : 0.5,
          child: child,
        ),
      ),
    );
  }
}

/// Extension method on Widget to add permission gating
extension PermissionExtension on Widget {
  /// Wrap widget with PermissionGate
  Widget requiresPermission(
    String permission, {
    Widget? fallback,
    bool showPlaceholder = false,
  }) {
    return PermissionGate(
      permission: permission,
      fallback: fallback,
      showPlaceholder: showPlaceholder,
      child: this,
    );
  }
}
