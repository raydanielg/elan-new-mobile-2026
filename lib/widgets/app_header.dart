import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.titleWidget,
    this.onMenuPressed,
    this.actions,
    this.userInitials,
    this.userName,
    this.userEmail,
    this.userBadge,
    this.onProfile,
    this.onSettings,
    this.onLogout,
    this.backgroundColor,
    this.foregroundColor,
    this.showUserMenu = true,
    this.onAvatarTap,
  });

  final String title;
  final Widget? titleWidget;
  final VoidCallback? onMenuPressed;
  final List<Widget>? actions;
  final String? userInitials;
  final String? userName;
  final String? userEmail;
  final String? userBadge;
  final VoidCallback? onProfile;
  final VoidCallback? onSettings;
  final VoidCallback? onLogout;

  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showUserMenu;
  final VoidCallback? onAvatarTap;

  static const Color _headerColor = Color(0xFF111827);

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? _headerColor;
    final effectiveForegroundColor = foregroundColor ?? Colors.white;
    final effectiveActions = <Widget>[
      ...?actions,
      if (showUserMenu)
        _UserMenu(
          initials: userInitials,
          userName: userName,
          userEmail: userEmail,
          badge: userBadge,
          onProfile: onProfile,
          onSettings: onSettings,
          onLogout: onLogout,
        )
      else
        _UserAvatar(
          initials: userInitials,
          onTap: onAvatarTap,
        ),
      const SizedBox(width: 6),
    ];

    return AppBar(
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      elevation: 0,
      leading: onMenuPressed == null
          ? null
          : IconButton(
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu),
              tooltip: 'Menu',
            ),
      titleSpacing: 0,
      title: titleWidget == null
          ? Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: effectiveForegroundColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : titleWidget,
      actions: effectiveActions,
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.initials,
    required this.onTap,
  });

  final String? initials;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = Padding(
      padding: const EdgeInsets.only(right: 12),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white.withValues(alpha: 0.18),
        child: Text(
          (initials == null || initials!.trim().isEmpty)
              ? 'U'
              : initials!.trim().toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    if (onTap == null) return avatar;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: avatar,
    );
  }
}

enum _UserMenuAction { profile, settings, logout }

class _UserMenu extends StatelessWidget {
  const _UserMenu({
    required this.initials,
    required this.userName,
    required this.userEmail,
    required this.badge,
    required this.onProfile,
    required this.onSettings,
    required this.onLogout,
  });

  final String? initials;
  final String? userName;
  final String? userEmail;
  final String? badge;
  final VoidCallback? onProfile;
  final VoidCallback? onSettings;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (userName == null || userName!.trim().isEmpty)
        ? 'User'
        : userName!.trim();
    final email = (userEmail == null || userEmail!.trim().isEmpty)
        ? ''
        : userEmail!.trim();
    final badgeText = (badge == null || badge!.trim().isEmpty)
        ? ''
        : badge!.trim();

    return PopupMenuButton<_UserMenuAction>(
      tooltip: 'User menu',
      position: PopupMenuPosition.under,
      color: Colors.white,
      constraints: const BoxConstraints(minWidth: 288),
      onSelected: (action) {
        switch (action) {
          case _UserMenuAction.profile:
            onProfile?.call();
            break;
          case _UserMenuAction.settings:
            onSettings?.call();
            break;
          case _UserMenuAction.logout:
            onLogout?.call();
            break;
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<_UserMenuAction>(
            enabled: false,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF111827),
                    child: Text(
                      (initials == null || initials!.trim().isEmpty)
                          ? 'U'
                          : initials!.trim().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (badgeText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF800000).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFF800000).withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        badgeText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF800000),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _UserMenuAction.profile,
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 18,
                  color: Color(0xFF111827),
                ),
                SizedBox(width: 10),
                Text(
                  'Profile',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: _UserMenuAction.settings,
            child: Row(
              children: [
                const Icon(
                  Icons.settings_outlined,
                  size: 18,
                  color: Color(0xFF111827),
                ),
                SizedBox(width: 10),
                Text(
                  'Settings',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _UserMenuAction.logout,
            child: Row(
              children: [
                const Icon(
                  Icons.logout,
                  size: 18,
                  color: Color(0xFFB91C1C),
                ),
                SizedBox(width: 10),
                Text(
                  'Logout',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB91C1C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ];
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                child: Text(
                  (initials == null || initials!.trim().isEmpty)
                      ? 'U'
                      : initials!.trim().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
