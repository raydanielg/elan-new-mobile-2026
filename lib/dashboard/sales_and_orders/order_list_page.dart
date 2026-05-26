import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _orderCard() {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 110,
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Feb 25, 2026 00:00', style: TextStyle(fontWeight: FontWeight.w900)),
                        SizedBox(height: 6),
                        Text('Order #ORD-102', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6B7280))),
                        SizedBox(height: 6),
                        Text('By EZRA DANIEL', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text('Total: 15,000.00', style: TextStyle(fontWeight: FontWeight.w900)),
                      SizedBox(height: 4),
                      Text('Status: Pending', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.orange)),
                      SizedBox(height: 4),
                      Text('Items: 3', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.expand_more, color: primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: 'Order List',
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back', style: TextStyle(fontWeight: FontWeight.w900)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF111827),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search orders...',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Date', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: const [
                  Expanded(
                    child: Text('25 February, 2026', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  Text('Total: 30,000.00', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                ],
              ),
            ),
            _orderCard(),
            _orderCard(),
          ],
        ),
      ),
    );
  }
}
