import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDetailPage extends StatelessWidget {
  final String appId;
  const AppDetailPage({super.key, required this.appId});

  // ✅ Ensure user is logged in (prevents "permission denied")
  Future<void> _ensureLoggedIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }

  // ✅ Securely increment installs (matches Firestore rules)
  Future<void> _incrementInstall(String appId) async {
    await _ensureLoggedIn();

    final appRef = FirebaseFirestore.instance.collection('apps').doc(appId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(appRef);
      if (!snapshot.exists) return;

      final currentInstalls = snapshot.data()?['installs'] ?? 0;
      transaction.update(appRef, {'installs': currentInstalls + 1});
    });
  }

  // ✅ Reward user + track tested apps
  Future<void> _addDiamondsForTesting(String appId) async {
    await _ensureLoggedIn();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      // If user doc doesn’t exist, create it
      await userRef.set({
        'diamonds': 0,
        'testedApps': [],
      });
    }

    final data = snapshot.data() ?? {};
    final List testedApps =
        data['testedApps'] != null ? List.from(data['testedApps']) : [];

    // Reward only once per app
    if (!testedApps.contains(appId)) {
      await userRef.update({
        'diamonds': FieldValue.increment(5),
        'testedApps': FieldValue.arrayUnion([appId]),
      });
    }
  }

  // ✅ Safe URL launcher
  Future<void> _openLink(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Details'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('apps')
            .doc(appId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'App not found or has been removed.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final app = snapshot.data!;
          final appName = app['appName'] ?? 'Unnamed App';
          final description = app['description'] ?? 'No description available.';
          final installs = app['installs'] ?? 0;
          final googleGroup = app['googleGroup'] ?? '';
          final appLink = app['appLink'] ?? '';
          final webAppLink = app['webAppLink'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 45,
                    backgroundImage:
                        const AssetImage('assets/closed_testing.png'),
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: Text(
                    appName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  description,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),

                Text(
                  'Installs: $installs',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),

                // ✅ Google Group link
                if (googleGroup.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.group),
                      onPressed: () => _openLink(googleGroup),
                      label: const Text(
                        'Join Google Group',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // ✅ Android app test link
                if (appLink.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.download),
                      onPressed: () async {
                        try {
                          // Ensure user is logged in
                          await _ensureLoggedIn();

                          // Increment installs count
                          await _incrementInstall(appId);

                          // Reward user 5 diamonds (if first time)
                          await _addDiamondsForTesting(appId);

                          // Launch the app link
                          await _openLink(appLink);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      },
                      label: const Text(
                        'Join on Android',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // ✅ Web app test link
                if (webAppLink.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.public),
                      onPressed: () async {
                        try {
                          await _ensureLoggedIn();
                          await _incrementInstall(appId);
                          await _addDiamondsForTesting(appId);
                          await _openLink(webAppLink);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      },
                      label: const Text(
                        'Join on Web',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
