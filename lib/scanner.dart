// lib/screens/scan_product_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_details.dart'; // تأكد من أن هذا الملف يحتوي على ProductDetailsScreen

// نموذج بيانات المنتج
class ProductDetails {
  final String name;
  final String brand;
  final String category;
  final String origin;
  final String imageUrl;
  final String ingredients;

  ProductDetails({
    required this.name,
    required this.brand,
    required this.category,
    required this.origin,
    required this.imageUrl,
    required this.ingredients,
  });
}

class ScanProductScreen extends StatefulWidget {
  const ScanProductScreen({super.key});

  @override
  State<ScanProductScreen> createState() => _ScanProductScreenState();
}

class _ScanProductScreenState extends State<ScanProductScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  final Color primaryGreen = const Color(0xFF0B8F57);
  bool _isScanning = true;
  String _detectedBarcode = 'Scan a Barcode...';
  String? _lastDetectedCode;

  // دالة جلب البيانات من Open Food Facts
  Future<void> _fetchProductDetails(String barcode) async {
    setState(() {
      _detectedBarcode = 'Loading...';
      _isScanning = false;
    });

    final url = Uri.parse(
      'https://world.openfoodfacts.net/api/v2/product/$barcode',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == 1 && data['product'] != null) {
          final productData = data['product'];

          final ProductDetails product = ProductDetails(
            name: productData['product_name'] ?? 'Unknown Product',
            brand: productData['brands'] ?? 'N/A',
            category: productData['categories'] ?? 'N/A',
            origin: productData['countries'] ?? 'N/A',
            imageUrl: productData['image_url'] ?? '',
            ingredients: productData['ingredients_text'] ?? 'N/A',
          );

          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailsScreen(product: product, code: barcode),
            ),
          ).then((_) => _startScanning());
        } else {
          _showError('Product not found for this barcode.');
          _startScanning();
        }
      } else {
        _showError('Product Not Found. Status code: ${response.statusCode}');
        _startScanning();
      }
    } catch (e) {
      _showError('Failed to load product. Please Check Your Internet');
      _startScanning();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _startScanning() {
    if (!_isScanning) {
      cameraController.start();
    }
    setState(() {
      _isScanning = true;
      _detectedBarcode = 'Scan a Barcode...';
      _lastDetectedCode = null;
    });
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && _isScanning) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code != _lastDetectedCode) {
        cameraController.stop();
        setState(() {
          _detectedBarcode = 'Loading...';
          _lastDetectedCode = code;
          _isScanning = false;
        });
        // جلب التفاصيل مباشرة بدون زر
        _fetchProductDetails(code);
      }
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startScanning();
    _lastDetectedCode = null;
    _isScanning = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. كاميرا تغطي الشاشة كلها
          Positioned.fill(
            child: MobileScanner(
              controller: cameraController,
              onDetect: _onBarcodeDetect,
              fit: BoxFit.cover,
            ),
          ),

          // 2. AppBar أعلى الشاشة
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Container(
                height: 80,
                width: 300,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                child: const Center(
                  child: Text(
                    "Barcode Scanner",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Overlay المربع مع الكود و مؤشر التحميل
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(300, 300),
                      painter: ScannerOverlayPainter(
                        borderColor: primaryGreen,
                        borderWidth: 3,
                        borderRadius: 20,
                        cutoutWidth: 250,
                        cutoutHeight: 250,
                      ),
                    ),
                    // الكود أو مؤشر التحميل
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _lastDetectedCode ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_detectedBarcode == 'Loading...')
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// كلاس مساعد لإنشاء الشكل المربع المحدد (مثل الزوايا)
class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double cutoutWidth;
  final double cutoutHeight;

  ScannerOverlayPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.cutoutWidth,
    required this.cutoutHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: cutoutWidth,
      height: cutoutHeight,
    );
    final r = borderRadius;
    const double cornerLength = 30;

    // Top-left
    canvas.drawLine(
      Offset(rect.left + r, rect.top),
      Offset(rect.left + r + cornerLength, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top + r),
      Offset(rect.left, rect.top + r + cornerLength),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(rect.left, rect.top, r * 2, r * 2),
      3.1415926535,
      3.1415926535 / 2,
      false,
      paint,
    );

    // Top-right
    canvas.drawLine(
      Offset(rect.right - r, rect.top),
      Offset(rect.right - r - cornerLength, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top + r),
      Offset(rect.right, rect.top + r + cornerLength),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(rect.right - 2 * r, rect.top, r * 2, r * 2),
      -3.1415926535 / 2,
      3.1415926535 / 2,
      false,
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(rect.left + r, rect.bottom),
      Offset(rect.left + r + cornerLength, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom - r),
      Offset(rect.left, rect.bottom - r - cornerLength),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(rect.left, rect.bottom - 2 * r, r * 2, r * 2),
      3.1415926535 / 2,
      3.1415926535 / 2,
      false,
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(rect.right - r, rect.bottom),
      Offset(rect.right - r - cornerLength, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom - r),
      Offset(rect.right, rect.bottom - r - cornerLength),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(rect.right - 2 * r, rect.bottom - 2 * r, r * 2, r * 2),
      0,
      3.1415926535 / 2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
