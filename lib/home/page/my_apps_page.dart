import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_detail_page.dart';

class MyAppsPage extends StatelessWidget {
  const MyAppsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // 🔍 Check if User is Logged In
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Apps")),
        body: const Center(
          child: Text(
            "You are not logged in yet.",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    final userId = user.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('My Apps')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('apps')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Something went wrong. Please try again later.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "You haven't registered any apps yet.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final app = docs[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundImage: AssetImage('assets/closed_testing.png'),
                    radius: 24,
                  ),
                  title: Text(app['appName'] ?? 'Unnamed App'),
                  subtitle: Text(app['description'] ?? 'No description provided'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppDetailPage(appId: app.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),

      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     Navigator.pushNamed(context, '/create');
      //   },
      //   label: const Text('Add New App'),
      //   icon: const Icon(Icons.add),
      // ),
    );
  }
}
