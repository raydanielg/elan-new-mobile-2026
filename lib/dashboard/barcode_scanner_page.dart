import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Lazy initialization - only create controller when needed
  MobileScannerController get controller {
    _controller ??= MobileScannerController();
    return _controller!;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
      width: 250,
      height: 250,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            scanWindow: scanWindow,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.displayValue ?? barcodes.first.rawValue;
                if (code != null) {
                  Navigator.pop(context, code);
                }
              }
            },
          ),
          // Custom Scanning Overlay
          CustomPaint(
            painter: ScannerOverlayPainter(scanWindow: scanWindow),
            child: Container(),
          ),
          // Animated Laser Line
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return PositionContext(
                rect: scanWindow,
                animationValue: _animation.value,
              );
            },
          ),
          // Instructions
          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align barcode within the frame to scan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PositionContext extends StatelessWidget {
  final Rect rect;
  final double animationValue;

  const PositionContext({super.key, required this.rect, required this.animationValue});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left + 10,
      right: MediaQuery.of(context).size.width - rect.right + 10,
      top: rect.top + (rect.height * animationValue),
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          color: Colors.red,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;

  ScannerOverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(20)));

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final combinedPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    canvas.drawPath(combinedPath, backgroundPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(20)), borderPaint);
    
    // Corners
    final cornerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    final length = 30.0;
    // Top Left
    canvas.drawLine(Offset(scanWindow.left, scanWindow.top + length), Offset(scanWindow.left, scanWindow.top), cornerPaint);
    canvas.drawLine(Offset(scanWindow.left, scanWindow.top), Offset(scanWindow.left + length, scanWindow.top), cornerPaint);
    
    // Top Right
    canvas.drawLine(Offset(scanWindow.right - length, scanWindow.top), Offset(scanWindow.right, scanWindow.top), cornerPaint);
    canvas.drawLine(Offset(scanWindow.right, scanWindow.top), Offset(scanWindow.right, scanWindow.top + length), cornerPaint);
    
    // Bottom Left
    canvas.drawLine(Offset(scanWindow.left, scanWindow.bottom - length), Offset(scanWindow.left, scanWindow.bottom), cornerPaint);
    canvas.drawLine(Offset(scanWindow.left, scanWindow.bottom), Offset(scanWindow.left + length, scanWindow.bottom), cornerPaint);
    
    // Bottom Right
    canvas.drawLine(Offset(scanWindow.right - length, scanWindow.bottom), Offset(scanWindow.right, scanWindow.bottom), cornerPaint);
    canvas.drawLine(Offset(scanWindow.right, scanWindow.bottom), Offset(scanWindow.right, scanWindow.bottom - length), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
