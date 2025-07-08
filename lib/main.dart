import 'package:flutter/material.dart';
import 'package:kfc_seller/DbHelper/mongdb.dart';
import 'package:kfc_seller/Screens/Cart/cart_provider.dart';
import 'package:kfc_seller/Screens/Home/splash_screen.dart';
import 'package:provider/provider.dart';
import 'Theme/app_theme.dart';

// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Connect to MongoDB
  MongoDatabase.connect().then((value) {
    print("Connected to MongoDB");
  }).catchError((error) {
    print("Error connecting to MongoDB: $error");
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ckicky Seller App',
      theme: AppTheme.lightTheme, // Sử dụng theme mới
      home: const SplashScreenRedesigned(), // Sử dụng splash screen mới
      debugShowCheckedModeBanner: false,
    );
  }
}
