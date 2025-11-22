import 'package:closed_testing/home/page/create_app_page.dart';
import 'package:closed_testing/home/page/home_page.dart';
import 'package:closed_testing/home/page/my_apps_page.dart';
import 'package:closed_testing/login/pages/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NavigationBarPage extends StatefulWidget {
  const NavigationBarPage({super.key});

  @override
  State<NavigationBarPage> createState() => _NavigationBarPageState();
}

class _NavigationBarPageState extends State<NavigationBarPage> {
  int currentIndex = 0;

  final List<Widget> pages = [
    const HomePage(),
    const CreateAppPage(),
    const MyAppsPage(),
  ];

  Future<void> _handleCreateTap(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    // ⛔ If user is anonymous or not logged in → show popup instead of redirect
    if (user == null || user.isAnonymous) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text(
            'You must be logged in to create a new app for testing.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close popup
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
      return;
    }

    // Check if Firestore profile exists
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      // ⛔ Firestore profile missing → show same popup
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Account Not Set Up'),
          content: const Text(
            'Please log in again to complete your account setup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
      return;
    }

    // Check diamonds
    int diamonds = (docSnapshot.data()?['diamonds'] ?? 0) as int;

    if (diamonds >= 25) {
      // Enough diamonds → allow navigation
      setState(() {
        currentIndex = 1; // CreateAppPage
      });
    } else {
      // Not enough diamonds → show popup
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Not Enough Diamonds'),
          content: const Text(
            'You need at least 25 diamonds to create a new app.\n\n'
            'Test other apps to earn more diamonds!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 1, 112, 5),
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) async {
          if (index == 1) {
            await _handleCreateTap(context);
          } else {
            setState(() => currentIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.white),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.create, color: Colors.white),
            label: "Create",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.android_outlined, color: Colors.white),
            label: "MyApps",
          ),
        ],
      ),
    );
  }
}
