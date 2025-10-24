import 'package:closed_testing/home/page/app_detail_page.dart';
import 'package:closed_testing/login/pages/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> logoutUser() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      debugPrint("Error during logout: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // 🔹 Drawer Header with Diamond Info
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.green),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Closed Testing",
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  if (user != null)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Text(
                            "💎 Loading...",
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          );
                        }

                        final userData =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        final diamonds = userData?['diamonds'] ?? 0;

                        return Text(
                          "💎 $diamonds Diamonds",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    )
                  else
                    const Text(
                      "Not logged in",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                Navigator.pop(context);
                await logoutUser();
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        title: const Text("Closed Testers"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),

      // 🔹 Show Public Apps
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("apps")
            .where("isPublic", isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No public apps available yet.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final apps = snapshot.data!.docs;

          return ListView.builder(
            itemCount: apps.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, i) {
              final app = apps[i].data() as Map<String, dynamic>? ?? {};
              final appName = app['appName'] ?? 'Unnamed App';
              final description = app['description'] ?? 'No description provided';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: const CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage('assets/closed_testing.png'),
                    backgroundColor: Colors.white,
                  ),
                  title: Text(
                    appName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppDetailPage(appId: apps[i].id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
