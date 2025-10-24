import 'package:closed_testing/home/page/create_app_page.dart';
import 'package:closed_testing/home/page/home_page.dart';
import 'package:closed_testing/home/page/my_apps_page.dart';
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
    const MyAppsPage()
  ];

  Future<void> _handleCreateTap(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create an app.')),
      );
      return;
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User profile not found.')),
      );
      return;
    }

    int diamonds = (docSnapshot.data()?['diamonds'] ?? 0) as int;

    if (diamonds >= 25) {
      // ✅ Only check, don’t deduct yet
      setState(() {
        currentIndex = 1; // Navigate to CreateAppPage
      });
    } else {
      // Show popup for insufficient diamonds
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
