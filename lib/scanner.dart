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
      _showError('Failed To Load Data. Please Check Your Internet');
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
          _detectedBarcode = code;
          _lastDetectedCode = code;
          _isScanning = false;
        });
        // جلب التفاصيل يتم عبر الزر
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
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: const Text(
          "Barcode Scanner",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. منطقة الكاميرا
          MobileScanner(
            controller: cameraController,
            onDetect: _onBarcodeDetect,
            fit: BoxFit.cover,
          ),

          // 2. تراكب المربع المحدد والرمز
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 300,
                  height: 300,
                  decoration: ShapeDecoration(
                    shape: _ScannerOverlayShape(
                      borderColor: primaryGreen,
                      borderWidth: 3.0,
                      borderRadius: 40,
                      cutoutWidth: 250,
                      cutoutHeight: 250,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _lastDetectedCode ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 180),
              ],
            ),
          ),

          // 3. زر "View Details" في الأسفل
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _lastDetectedCode != null && !_isScanning
                      ? () => _fetchProductDetails(_lastDetectedCode!)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _detectedBarcode == 'Loading...'
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// كلاس مساعد لإنشاء الشكل المربع المحدد (مثل الزوايا)
class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double cutoutWidth;
  final double cutoutHeight;

  const _ScannerOverlayShape({
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.cutoutWidth,
    required this.cutoutHeight,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final center = rect.center;
    final cutoutRect = Rect.fromCenter(
      center: center,
      width: cutoutWidth,
      height: cutoutHeight,
    );

    const double cornerLength = 30;

    // 🔹 نرسم الزوايا الأربع بخطوط قصيرة + radius
    final r = borderRadius;

    // top-left
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(cutoutRect.left + r, cutoutRect.top + r),
        radius: r,
      ),
      3.14, // نصف دائرة من اليسار
      1.57, // ربع دائرة
      false,
      paint,
    );
    canvas.drawLine(
      Offset(cutoutRect.left + r, cutoutRect.top),
      Offset(cutoutRect.left + r + cornerLength, cutoutRect.top),
      paint,
    );
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.top + r),
      Offset(cutoutRect.left, cutoutRect.top + r + cornerLength),
      paint,
    );

    // top-right
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(cutoutRect.right - r, cutoutRect.top + r),
        radius: r,
      ),
      -1.57, // ربع دائرة من الأعلى يمين
      1.57,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(cutoutRect.right - r, cutoutRect.top),
      Offset(cutoutRect.right - r - cornerLength, cutoutRect.top),
      paint,
    );
    canvas.drawLine(
      Offset(cutoutRect.right, cutoutRect.top + r),
      Offset(cutoutRect.right, cutoutRect.top + r + cornerLength),
      paint,
    );

    // bottom-left
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(cutoutRect.left + r, cutoutRect.bottom - r),
        radius: r,
      ),
      1.57, // من تحت يسار
      1.57,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(cutoutRect.left + r, cutoutRect.bottom),
      Offset(cutoutRect.left + r + cornerLength, cutoutRect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.bottom - r),
      Offset(cutoutRect.left, cutoutRect.bottom - r - cornerLength),
      paint,
    );

    // bottom-right
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(cutoutRect.right - r, cutoutRect.bottom - r),
        radius: r,
      ),
      0, // من تحت يمين
      1.57,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(cutoutRect.right - r, cutoutRect.bottom),
      Offset(cutoutRect.right - r - cornerLength, cutoutRect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(cutoutRect.right, cutoutRect.bottom - r),
      Offset(cutoutRect.right, cutoutRect.bottom - r - cornerLength),
      paint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}
