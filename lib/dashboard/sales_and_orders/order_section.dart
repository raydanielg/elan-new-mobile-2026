import 'package:flutter/material.dart';
import 'order_list_page.dart';

class OrderSection extends StatelessWidget {
  const OrderSection({
    super.key,
    required this.primary,
    required this.orderValueText,
    required this.onViewList,
    required this.searchController,
  });

  final Color primary;
  final String orderValueText;
  final VoidCallback onViewList;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OrderListPage()),
                  );
                  onViewList();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('View List →', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const Spacer(),
            Text(
              'Order Value: $orderValueText',
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search here..',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Date', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Center(
            child: Text(
              'No orders',
              style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6B7280)),
            ),
          ),
        ),
      ],
    );
  }
}
