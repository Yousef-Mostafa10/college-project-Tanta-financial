import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/language_provider.dart';

import 'Auth/login.dart';
import 'home/dashboard.dart';
import 'home/home.dart';
import 'utils/session_manager.dart';
import 'request/Myrequest/myrequest.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => LanguageProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null || token.isEmpty) return null;
    return prefs.getString("user_role") ?? "user";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'College Project',
          navigatorKey: SessionManager.navigatorKey, // ✅ ربط الـ key لإدارة الجلسة
          locale: languageProvider.currentLocale,
          supportedLocales: const [
            Locale('en', ''),
            Locale('ar', ''),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) return supportedLocales.first;

            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first; // Default to English
          },
          home: FutureBuilder<String?>(
            future: getUserRole(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                print("❌ Error in getUserRole: ${snapshot.error}");
                return const LoginPage();
              } else {
                final role = snapshot.data;
                if (role != null) {
                  if (role.toUpperCase() == 'ADMIN') {
                    return const AdministrativeDashboardPage();
                  } else {
                    return const MyRequestsPage();
                  }
                } else {
                  return const LoginPage();
                }
              }
            },
          ),
        );
      },
    );
  }
}