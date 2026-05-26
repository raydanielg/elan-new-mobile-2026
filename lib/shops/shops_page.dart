import 'package:flutter/material.dart';
import '../widgets/app_header.dart';

import '../api/api_service.dart';

class ShopsPage extends StatefulWidget {
  const ShopsPage({
    super.key,
    this.onSelectShop,
    this.selectedShopId,
  });

  final ValueChanged<_ShopItem>? onSelectShop;
  final String? selectedShopId;

  @override
  State<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends State<ShopsPage> {
  bool _loading = false;
  String? _error;
  List<_ShopItem> _shops = const [];
  String? _userId;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await Future.wait([
      _fetchUserId(),
      _fetchShops(),
    ]);
  }

  Future<void> _fetchUserId() async {
    try {
      final raw = await ApiService.instance.app.getData('session_user');
      if (!mounted) return;

      String? userId;
      if (raw is Map) {
        final data = (raw['data'] is Map) ? (raw['data'] as Map) : raw;
        userId = data['user_id']?.toString() ?? data['id']?.toString();
        userId = userId?.trim();
        if (userId != null && userId.isEmpty) userId = null;
      }

      setState(() {
        _userId = userId;
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _fetchShops() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ApiService.instance.app.getData('my_shops');
      final shops = _parseShops(raw);
      if (!mounted) return;
      setState(() {
        _shops = shops;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<_ShopItem> _parseShops(dynamic raw) {
    dynamic data = raw;
    if (raw is Map && raw['data'] != null) {
      data = raw['data'];
    }

    final out = <_ShopItem>[];

    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          final id = item['shop_id']?.toString() ?? item['id']?.toString() ?? '';
          final name = item['shop_name']?.toString() ??
              item['name']?.toString() ??
              item['business_name']?.toString() ??
              '';
          final owner = item['shop_owner']?.toString() ??
              item['owner']?.toString() ??
              item['owner_name']?.toString() ??
              item['user_name']?.toString() ??
              item['username']?.toString() ??
              item['full_name']?.toString() ??
              '';
          if (name.trim().isEmpty && id.trim().isEmpty) continue;
          out.add(
            _ShopItem(
              id: id.trim(),
              name: name.trim(),
              ownerName: owner.trim(),
            ),
          );
        } else if (item != null) {
          out.add(_ShopItem(id: '', name: item.toString(), ownerName: ''));
        }
      }
    } else if (data is Map) {
      // Sometimes API returns a single object.
      final id = data['shop_id']?.toString() ?? data['id']?.toString() ?? '';
      final name = data['shop_name']?.toString() ?? data['name']?.toString() ?? '';
      final owner = data['shop_owner']?.toString() ??
          data['owner']?.toString() ??
          data['owner_name']?.toString() ??
          data['user_name']?.toString() ??
          data['username']?.toString() ??
          data['full_name']?.toString() ??
          '';
      if (name.trim().isNotEmpty || id.trim().isNotEmpty) {
        out.add(
          _ShopItem(
            id: id.trim(),
            name: name.trim(),
            ownerName: owner.trim(),
          ),
        );
      }
    }

    return out;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;

    final totalShops = _shops.length;
    final userId = _userId ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: 'Shops',
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              _WelcomeCard(
                loading: _loading,
                subtitle: totalShops == 1
                    ? 'You have 1 shop connected.'
                    : 'You have $totalShops shops connected.',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 280,
                child: _loading
                    ? const SizedBox(
                        width: 340,
                        child: _VirtualShopCard(
                          loading: true,
                          totalProfitTzs: 'TZS ...',
                          appName: 'ElanLedgers',
                          userId: '',
                          shopId: '',
                          shopName: '',
                          ownerName: '',
                          validThru: '',
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _shops.isEmpty ? 1 : _shops.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          if (_shops.isEmpty) {
                            return const SizedBox(
                              width: 340,
                              child: _VirtualShopCard(
                                loading: false,
                                totalProfitTzs: 'TZS 0',
                                appName: 'ElanLedgers',
                                userId: '',
                                shopId: '',
                                shopName: 'No shops',
                                ownerName: '',
                                validThru: '',
                              ),
                            );
                          }

                          final s = _shops[i];
                          final validThru = _validThru();

                          return SizedBox(
                            width: 340,
                            child: _VirtualShopCard(
                              loading: false,
                              totalProfitTzs: _formatTzs(0),
                              appName: 'ElanLedgers',
                              userId: userId,
                              shopId: s.id,
                              shopName: s.name,
                              ownerName: s.ownerName,
                              validThru: validThru,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              if (_error != null)
                _ErrorCard(
                  message: _error!,
                  onRetry: _fetchShops,
                ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_shops.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'No shops found. Pull down to refresh.',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),
                    const Text(
                      'Your shops',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final s in _shops)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ShopCard(
                          shop: s,
                          selected: (widget.selectedShopId ?? '').trim().isNotEmpty &&
                              s.id == (widget.selectedShopId ?? '').trim(),
                          onTap: widget.onSelectShop == null
                              ? null
                              : () => widget.onSelectShop!(s),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopItem {
  const _ShopItem({required this.id, required this.name, required this.ownerName});

  final String id;
  final String name;
  final String ownerName;
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.loading, required this.subtitle});

  final bool loading;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final title = loading ? 'Hello' : 'Hello';
    final name = 'Welcome back';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3A0000),
            Color(0xFF800000),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title 👋✨',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loading ? 'Loading your shops…' : subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VirtualShopCard extends StatelessWidget {
  const _VirtualShopCard({
    required this.loading,
    required this.totalProfitTzs,
    required this.appName,
    required this.userId,
    required this.shopId,
    required this.shopName,
    required this.ownerName,
    required this.validThru,
  });

  final bool loading;
  final String totalProfitTzs;
  final String appName;
  final String userId;
  final String shopName;
  final String shopId;
  final String ownerName;
  final String validThru;

  @override
  Widget build(BuildContext context) {
    final displayName = shopName.trim().isEmpty ? 'Shop' : shopName.trim();
    final idPart = shopId.trim().isEmpty ? '----' : shopId.trim();
    final owner = ownerName.trim().isEmpty ? '-' : ownerName.trim();
    final uid = userId.trim().isEmpty ? '-' : userId.trim();
    final cardNumber = _cardNumberFromShopId(idPart);

    return Stack(
      children: [
        Container(
          height: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4D0000),
                Color(0xFF800000),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: const Text(
                      'CARD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Total Profit',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.90),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                loading ? 'TZS ...' : totalProfitTzs,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loading ? 'User ID: ...' : 'User ID: $uid',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                loading ? 'Shop ID: ...' : 'Shop ID: ${idPart.isEmpty ? '-' : idPart}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                loading
                    ? '----  ----  ----  ----'
                    : cardNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SHOP NAME',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.80),
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loading ? 'Loading…' : displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'OWNER',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.80),
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loading ? 'Loading…' : owner,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'VALID THRU',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.80),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loading ? '--/--' : validThru,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          right: -36,
          top: 24,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
        ),
        Positioned(
          right: 24,
          bottom: -46,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
      ],
    );
  }

  static String _chunk(String v, int len) {
    final s = v.replaceAll(RegExp(r'\s+'), '');
    if (s.isEmpty) return '----';
    if (s.length >= len) return s.substring(0, len);
    return s.padRight(len, '-');
  }

  static String _cardNumberFromShopId(String shopId) {
    final digits = shopId.replaceAll(RegExp(r'\D'), '');
    final base = digits.isEmpty ? '0000' : digits;
    final sixteen = (base + base + base + base).padRight(16, '0').substring(0, 16);
    final chunks = <String>[];
    for (int i = 0; i < 16; i += 4) {
      chunks.add(sixteen.substring(i, i + 4));
    }
    return chunks.join('  ');
  }
}

String _formatTzs(num v) {
  final s = v.toStringAsFixed(0);
  final chars = s.split('');
  final out = <String>[];
  int count = 0;
  for (int i = chars.length - 1; i >= 0; i--) {
    out.add(chars[i]);
    count++;
    if (count == 3 && i != 0) {
      out.add(',');
      count = 0;
    }
  }
  return 'TZS ${out.reversed.join()}';
}

String _validThru() {
  final now = DateTime.now();
  final future = DateTime(now.year + 3, now.month);
  final mm = future.month.toString().padLeft(2, '0');
  final yy = (future.year % 100).toString().padLeft(2, '0');
  return '$mm/$yy';
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.shop,
    required this.selected,
    required this.onTap,
  });

  final _ShopItem shop;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final border = selected
        ? primary.withValues(alpha: 0.55)
        : const Color(0xFFE5E7EB);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                (shop.name.trim().isEmpty
                    ? 'S'
                    : shop.name.trim().toUpperCase().substring(0, 1)),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name.isEmpty ? 'Shop' : shop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  if (shop.id.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${shop.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: selected
                  ? primary
                  : primary.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB91C1C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
