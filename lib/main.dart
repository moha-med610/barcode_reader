import 'package:flutter/material.dart';
import 'package:qr_scanner/scanner.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(Home());
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(textTheme: GoogleFonts.oswaldTextTheme()),
      debugShowCheckedModeBanner: false,
      home: ScanProductScreen(),
    );
  }
}

// 0xFF0B8F57
