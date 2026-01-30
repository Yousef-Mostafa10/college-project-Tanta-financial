// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import '../Auth/login.dart';
// import '../View/individual_user.dart';
// import '../drawer.dart';
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   String username = "";
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUser();
//   }
//
//   Future<void> _loadUser() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       username = prefs.getString('username') ?? "Guest";
//     });
//   }
//
//   Future<void> logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(builder: (context) => const LoginPage()),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("University Request System"),
//         backgroundColor: Colors.teal,
//       ),
//       drawer: CustomDrawer(
//         userName: "Yousef Mostafa",
//         userEmail: "yousef@example.com",
//         userDepartment: "Computer Science",
//         onLogout:logout,
//       ),
//       body: const Center(
//         child: Text(
//           "Welcome to Home Page 👋",
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//       ),
//     );
//   }
// }
//
// // -----------------------------------
// // صفحة عرض كل المستخدمين
// // -----------------------------------
// class ViewAllUsersPage extends StatefulWidget {
//   const ViewAllUsersPage({super.key});
//
//   @override
//   State<ViewAllUsersPage> createState() => _ViewAllUsersPageState();
// }
//
// class _ViewAllUsersPageState extends State<ViewAllUsersPage> {
//   List users = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchUsers();
//   }
//
//   Future<void> fetchUsers() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token') ?? "";
//     final url = Uri.parse("http://192.168.1.19:3000/users");
//
//     try {
//       final response = await http.get(
//         url,
//         headers: {"Authorization": "Bearer $token"},
//       );
//
//       print("Status code: ${response.statusCode}");
//       print("Body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//
//         // تأكد أن data['users'] دايمًا List
//         final userList = data['users'] is List ? List.from(data['users']) : [data['users']];
//
//         setState(() {
//           users = userList;
//           print("@@@@@@@@@@@@@@@@@@@@@@@${users.length}");
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Failed to load users: ${response.statusCode}")),
//         );
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e")),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("All Users"),
//         backgroundColor: Colors.teal,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//         itemCount: users.length,
//         itemBuilder: (context, index) {
//           final user = users[index];
//           return Padding(
//             padding: const EdgeInsets.all(8),
//             child: InkWell(
//               onTap: () {
//                 Navigator.of(context).push(
//                   MaterialPageRoute(
//                     builder: (context) => UserDetailsPage(userId: user['id']),
//                   ),
//                 );
//               },
//               child: Card(
//                 margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 elevation: 4,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: Colors.teal.shade100,
//                     child: Text(user['name'][0].toUpperCase()),
//                   ),
//                   title: Text(
//                     user['name'],
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Text("User ID: ${user['id']}"),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
