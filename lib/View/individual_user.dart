import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:college_project/l10n/app_localizations.dart';
import '../app_config.dart';
import '../utils/app_error_handler.dart';

class UserDetailsPage extends StatefulWidget {
  final int userId;

  const UserDetailsPage({super.key, required this.userId});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  Map userDetails = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final url = Uri.parse("${AppConfig.baseUrl}/users/\${widget.userId}");

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer \$token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userDetails = data['user'] ?? {};
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppErrorHandler.extractAndTranslate(
                context,
                response.body,
                fallback: AppLocalizations.of(context)!.translate('user_not_found'),
              )),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorHandler.translateException(context, e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('view_profile')),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ID: \${userDetails['id']}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text("${AppLocalizations.of(context)!.translate('name_label')}: \${userDetails['name']}",
                style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
