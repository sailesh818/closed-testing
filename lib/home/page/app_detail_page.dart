import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDetailPage extends StatefulWidget {
  final String appId;
  const AppDetailPage({super.key, required this.appId});

  @override
  State<AppDetailPage> createState() => _AppDetailPageState();
}

class _AppDetailPageState extends State<AppDetailPage> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmittingFeedback = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  // Anonymous login
  Future<User?> _ensureLoggedIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      final userCredential = await auth.signInAnonymously();
      return userCredential.user;
    }
    return auth.currentUser;
  }

  // Increment install counter
  Future<void> _incrementInstall() async {
    final appRef =
        FirebaseFirestore.instance.collection('apps').doc(widget.appId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(appRef);
      if (!snapshot.exists) return;

      final currentInstalls = snapshot.data()?['installs'] ?? 0;
      transaction.update(appRef, {'installs': currentInstalls + 1});
    });
  }

  // Give diamonds once per app
  Future<void> _addDiamondsForTesting() async {
    final user = await _ensureLoggedIn();
    if (user == null) return;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      await userRef.set({'diamonds': 0, 'testedApps': []});
    }

    final data = snapshot.data() ?? {};
    final List testedApps =
        data['testedApps'] != null ? List.from(data['testedApps']) : [];

    if (!testedApps.contains(widget.appId)) {
      await userRef.update({
        'diamonds': FieldValue.increment(5),
        'testedApps': FieldValue.arrayUnion([widget.appId]),
      });
    }
  }

  // Open external link and return if launched successfully
  Future<bool> _openLink(String url) async {
    if (url.isEmpty) return false;
    final uri = Uri.parse(url);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // Submit feedback
  Future<void> _submitFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmittingFeedback = true);

    try {
      final user = await _ensureLoggedIn();
      if (user == null) return;

      final email = user.isAnonymous ? "Anonymous" : (user.email ?? "Anonymous");

      await FirebaseFirestore.instance
          .collection('apps')
          .doc(widget.appId)
          .collection('feedback')
          .add({
        'userId': user.uid,
        'email': email,
        'message': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _feedbackController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit feedback: $e')),
      );
    } finally {
      setState(() => _isSubmittingFeedback = false);
    }
  }

  // Feedback section
  Widget _buildFeedbackSection() {
    final feedbackRef = FirebaseFirestore.instance
        .collection('apps')
        .doc(widget.appId)
        .collection('feedback')
        .orderBy('createdAt', descending: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        const Text(
          'Feedback',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _feedbackController,
                decoration: InputDecoration(
                  hintText: 'Write your feedback...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _isSubmittingFeedback
                ? const CircularProgressIndicator()
                : IconButton(
                    icon: const Icon(Icons.send, color: Colors.green),
                    onPressed: _submitFeedback,
                  ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: feedbackRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return const Text('No feedback yet.');
            }

            final docs = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final message = data['message'] ?? '';
                final email = data['email'] ?? 'Anonymous';

                return Card(
                  child: ListTile(
                    title: Text(message),
                    subtitle: Text("By: $email"),
                  ),
                );
              },
            );
          },
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Details'),
        backgroundColor: Colors.lightBlue,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('apps')
            .doc(widget.appId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text('App not found.'));
          }

          final appData = snapshot.data!;
          final appName = appData['appName'] ?? 'Unnamed';
          final description = appData['description'] ?? '';
          final installs = appData['installs'] ?? 0;
          final googleGroup = appData['googleGroup'] ?? '';
          final appLink = appData['appLink'] ?? '';
          final webAppLink = appData['webAppLink'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: const AssetImage('assets/closed_testing.png'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    appName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Text(description, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                Text("Installs: $installs", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),

                // Google Group
                if (googleGroup.isNotEmpty)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => _openLink(googleGroup),
                    child: const Text("Join Google Group"),
                  ),
                const SizedBox(height: 12),

                // Install Android
                if (appLink.isNotEmpty)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: () async {
                      await _ensureLoggedIn();

                      bool launched = await _openLink(appLink);
                      if (launched) {
                        await _incrementInstall();
                        await _addDiamondsForTesting();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Failed to open Play Store link")),
                        );
                      }
                    },
                    child: const Text("Install on Android"),
                  ),
                const SizedBox(height: 12),

                // Web Version
                if (webAppLink.isNotEmpty)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: () async {
                      await _ensureLoggedIn();

                      bool launched = await _openLink(webAppLink);
                      if (launched) {
                        await _incrementInstall();
                        await _addDiamondsForTesting();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Failed to open web link")),
                        );
                      }
                    },
                    child: const Text("Use Web Version"),
                  ),
                const SizedBox(height: 20),

                _buildFeedbackSection(),
              ],
            ),
          );
        },
      ),
    );
  }
}
