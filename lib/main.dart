import 'package:flutter/material.dart';
import 'food_detector_screen.dart'; // 🟩 Imports our custom page feature cleanly

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FoodDetectorScreen(),
  ));
}
