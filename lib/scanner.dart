import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfessionalBarcodeScanner extends StatefulWidget {
  const ProfessionalBarcodeScanner({super.key});

  @override
  State<ProfessionalBarcodeScanner> createState() =>
      _ProfessionalBarcodeScannerState();
}

class _ProfessionalBarcodeScannerState
    extends State<ProfessionalBarcodeScanner> {
  MobileScannerController? _cameraController;
  String _scannedBarcode = "No barcode scanned yet...";
  String _productDetails = "";
  String? _imageUrl;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(' Barcode Scanner'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          Expanded(flex: 2, child: _buildScannerView()),  
          Expanded(flex: 3, child: _buildResultView()),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    if (_cameraController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        MobileScanner(
          controller: _cameraController!,
          onDetect: (capture) {
            if (_isProcessing) return;

            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String? barcodeValue = barcodes.first.rawValue;
              if (barcodeValue != null) {
                _processBarcode(barcodeValue);
              }
            }
          },
        ),
        Center(
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.redAccent, width: 1),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white, size: 32),
            onPressed: () => _cameraController?.toggleTorch(),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 32),
            onPressed: () => _cameraController?.switchCamera(),
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Barcode Number:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _scannedBarcode,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _scannedBarcode == "No barcode scanned yet..."
                    ? Colors.grey
                    : Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            if (_imageUrl != null)
              Center(
                child: Image.network(
                  _imageUrl!,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 50),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              _productDetails,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processBarcode(String value) async {
    setState(() {
      _isProcessing = true;
      _scannedBarcode = value;
      _productDetails = "Fetching product data...";
      _imageUrl = null;
    });

    await _cameraController?.stop();

    try {
      final uri = Uri.parse(
        "https://world.openfoodfacts.net/api/v2/product/$value",
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['product'];
        if (data != null) {
          String name = data['product_name'] ?? "Name not found";
          String brand = data['brands'] ?? "";
          String quantity = data['quantity'] ?? "";
          String categories = data['categories'] ?? "";
          String details =
              "$name${brand.isNotEmpty ? "\nBrand: $brand" : ""}${quantity.isNotEmpty ? "\nQuantity: $quantity" : ""}${categories.isNotEmpty ? "\nCategories: $categories" : ""}";

          setState(() {
            _productDetails = details;
            _imageUrl = data['image_url'];
          });
        } else {
          setState(() {
            _productDetails = "Product not found in database";
          });
        }
      } else {
        setState(() {
          _productDetails = "Failed to fetch product data";
        });
      }
    } catch (e) {
      setState(() {
        _productDetails = "Error: $e";
      });
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _cameraController?.start();
      }
    });
  }
}
