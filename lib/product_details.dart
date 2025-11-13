// lib/screens/product_details_screen.dart

import 'package:flutter/material.dart';
// يجب استيراد ملف شاشة المسح للحصول على تعريف ProductDetails
import 'scanner.dart';

class ProductDetailsScreen extends StatelessWidget {
  final ProductDetails product;
  final String code; // متغير اختياري لعرض السعر/حالة التفاصيل

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.code,
  });

  // اللون الأخضر المستخدم في التصميم
  final Color primaryGreen = const Color(0xFF1E88E5);

  // ********** الدالة المطلوبة: _buildDetailRow **********
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // الجزء الأيسر: العنوان (Title)
          SizedBox(
            width: 150,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 20),
          // الجزء الأيمن: القيمة (Value)
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
  // ****************************************************

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0B8F57),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Product Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      backgroundColor: Color(0xFF0B8F57),
      body: SingleChildScrollView(
        // padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 235, 234, 234),
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // **بطاقة المنتج العلوية**
                  Center(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            // صورة المنتج
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                product.imageUrl.isNotEmpty
                                    ? product.imageUrl
                                    : 'https://via.placeholder.com/150?text=No+Image',
                                height: 150,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.image_not_supported,
                                    size: 100,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 15),
                            // اسم المنتج والسعر/الحالة
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              "Barcode: $code",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B8F57),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // **الوصف**
                  const Text(
                    'ingredients',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    product.ingredients,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // **تفاصيل المنتج (استخدام دالة _buildDetailRow)**
                  _buildDetailRow('Brand', product.brand),
                  _buildDetailRow('Category', product.category),
                  _buildDetailRow('Origin', product.origin),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0B8F57),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: AlignmentGeometry.bottomCenter,
              child: Container(
                color: Colors.black,
                width: double.infinity,
                margin: EdgeInsets.only(top: 20),
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Developed By Ahmed Soliman & Mohamed Khaled ©All Rights Received. ${DateTime.now().year}",
                      style: TextStyle(
                        fontSize: 8,
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
