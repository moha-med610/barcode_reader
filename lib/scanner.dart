import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ProfessionalBarcodeScanner extends StatefulWidget {
  const ProfessionalBarcodeScanner({super.key});

  @override
  State<ProfessionalBarcodeScanner> createState() =>
      _ProfessionalBarcodeScannerState();
}

class _ProfessionalBarcodeScannerState
    extends State<ProfessionalBarcodeScanner> {
  MobileScannerController? _cameraController; // ممكن يكون null
  String _scannedBarcode = "لا يوجد باركود ممسوح بعد...";
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
        title: const Text('Barcode Scanner'),
        backgroundColor: Colors.indigo,
        elevation: 4,
      ),
      body: Column(
        children: [
          Expanded(flex: 7, child: _buildScannerView()),
          Expanded(flex: 3, child: _buildResultView()),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    if (_cameraController == null) {
      // منع crash قبل ما الcontroller يتحضر
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
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.redAccent, width: 2),
              borderRadius: BorderRadius.circular(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Barcode Number: ',
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _scannedBarcode == "No Barcode Scan Yet.."
                  ? Colors.grey
                  : Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _processBarcode(String value) async {
    setState(() {
      _isProcessing = true;
      _scannedBarcode = value;
    });

    await _cameraController?.stop();

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
