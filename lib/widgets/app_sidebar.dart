import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.userName,
    required this.userEmail,
    required this.userId,
    required this.avatarUrl,
    required this.counters,
    required this.onShare,
    required this.onSignOut,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String? userName;
  final String? userEmail;
  final String? userId;
  final String? avatarUrl;
  final Map<String, int> counters;
  final VoidCallback onShare;
  final VoidCallback onSignOut;

  static const Color _headerColor = _primaryMaroon;
  static const Color _primaryMaroon = Color(0xFF800000);
  static const Color _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final nameText = (userName ?? '').trim();
    final emailText = (userEmail ?? '').trim();
    final idText = (userId ?? '').trim();
    final headerName = nameText.isNotEmpty
        ? nameText
        : (emailText.isNotEmpty ? emailText : 'User');

    final initialsSrc = headerName.trim().toUpperCase();
    final initials = initialsSrc.isEmpty ? 'U' : initialsSrc.substring(0, 1);

    return Container(
      width: 280,
      color: _headerColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: Column(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: ClipOval(
                              child: SizedBox(
                                width: 54,
                                height: 54,
                                child: (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
                                    ? Image.network(
                                        avatarUrl!.trim(),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) {
                                          return Container(
                                            color: Colors.white,
                                            alignment: Alignment.center,
                                            child: Text(
                                              initials,
                                              style: const TextStyle(
                                                color: Color(0xFF111827),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 18,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: Colors.white,
                                        alignment: Alignment.center,
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            color: Color(0xFF111827),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 14,
                            top: 12,
                            child: Icon(Icons.add, color: Colors.red, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    headerName.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    idText.isEmpty ? '' : 'User ID: $idText',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.40)),

            _DashboardRow(
              selected: selectedIndex == 0,
              onTap: () => onSelected(0),
            ),

            Divider(height: 1, color: Colors.white.withValues(alpha: 0.40)),
            const SizedBox(height: 10),

            _SidebarListRow(
              icon: Icons.storefront_outlined,
              label: 'Shops',
              count: counters['shops'] ?? 0,
              selected: selectedIndex == 1,
              onTap: () => onSelected(1),
            ),
            _SidebarListRow(
              icon: Icons.group_outlined,
              label: 'Members',
              count: counters['members'] ?? 0,
              selected: selectedIndex == 2,
              onTap: () => onSelected(2),
            ),
            _SidebarListRow(
              icon: Icons.people_outline,
              label: 'Customers',
              count: counters['customers'] ?? 0,
              selected: selectedIndex == 3,
              onTap: () => onSelected(3),
            ),
            _SidebarListRow(
              icon: Icons.local_shipping_outlined,
              label: 'Suppliers',
              count: counters['suppliers'] ?? 0,
              selected: selectedIndex == 4,
              onTap: () => onSelected(4),
            ),
            _SidebarListRow(
              icon: Icons.inventory_2_outlined,
              label: 'Products',
              count: counters['products'] ?? 0,
              selected: selectedIndex == 5,
              onTap: () => onSelected(5),
            ),

            const Spacer(),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.40)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _BottomAction(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: onShare,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _BottomAction(
                      icon: Icons.logout,
                      label: 'Logout',
                      onTap: onSignOut,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardRow extends StatelessWidget {
  const _DashboardRow({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
                color: selected ? Colors.white.withValues(alpha: 0.14) : null,
              ),
              child: Icon(
                Icons.home_outlined,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Dashboard',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarListRow extends StatelessWidget {
  const _SidebarListRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.92), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              count.toString(),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
            ),
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.95)),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
