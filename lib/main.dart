import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Auth/login.dart';
import 'home/dashboard.dart';
import 'home/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // لو فيه خطأ
            print("❌ Error in checkLoginStatus: ${snapshot.error}");
            return const LoginPage();
          } else {
            if (snapshot.data == true) {
              return const AdministrativeDashboardPage();
            } else {
              return const LoginPage();
            }
          }
        },
      ),
    );

  }
}