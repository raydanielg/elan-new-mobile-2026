import 'package:flutter/material.dart';

class BarcodesSection extends StatelessWidget {
  const BarcodesSection({
    super.key,
    required this.primary,
    required this.quickAction,
  });

  final Color primary;
  final Widget Function(String label) quickAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              quickAction('Cat'),
              quickAction('Product'),
              quickAction('Import'),
              quickAction('Supplier'),
              quickAction('Transfer'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Barcodes',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF111827),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: const [
                    Expanded(
                      flex: 6,
                      child: Text(
                        'Barcode',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text(
                        'Name',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _FakeBarcode(height: 54),
                          SizedBox(height: 8),
                          Text(
                            '002505330051',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text('DELL HP', style: TextStyle(fontWeight: FontWeight.w900)),
                          SizedBox(height: 8),
                          Text('995.00', style: TextStyle(fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 240),
            ],
          ),
        ),
      ],
    );
  }
}

class _FakeBarcode extends StatelessWidget {
  const _FakeBarcode({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _FakeBarcodePainter(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
        ),
      ),
    );
  }
}

class _FakeBarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final left = 10.0;
    final top = 6.0;
    final bottom = size.height - 6.0;

    double x = left;
    final bars = <double>[2, 1, 3, 1, 1, 2, 2, 1, 4, 1, 1, 3, 2, 1, 1, 2, 3, 1, 2, 1, 4, 1, 2, 1, 1, 3];

    for (var i = 0; i < bars.length; i++) {
      final w = bars[i];
      if (i % 2 == 0) {
        canvas.drawRect(Rect.fromLTRB(x, top, x + w, bottom), paint);
      }
      x += w + 1;
      if (x > size.width - 10) break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
