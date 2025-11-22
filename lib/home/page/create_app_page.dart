import 'package:closed_testing/navigation/pages/navigation_bar_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAppPage extends StatefulWidget {
  const CreateAppPage({super.key});
  @override
  State<CreateAppPage> createState() => _CreateAppPageState();
}

class _CreateAppPageState extends State<CreateAppPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _googleGroupController = TextEditingController();
  final _webLinkController = TextEditingController();
  final _appLinkController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _googleGroupController.dispose();
    _webLinkController.dispose();
    _appLinkController.dispose();
    super.dispose();
  }

  Future<bool> _isDuplicateApp(String name, String webLink, String appLink) async {
    final user = FirebaseAuth.instance.currentUser!;
    final apps = FirebaseFirestore.instance.collection('apps');

    final nameQuery = await apps
        .where('userId', isEqualTo: user.uid)
        .where('appName', isEqualTo: name)
        .limit(1)
        .get();
    if (nameQuery.docs.isNotEmpty) return true;

    if (webLink.isNotEmpty) {
      final webQuery = await apps
          .where('userId', isEqualTo: user.uid)
          .where('webAppLink', isEqualTo: webLink)
          .limit(1)
          .get();
      if (webQuery.docs.isNotEmpty) return true;
    }

    final appQuery = await apps
        .where('userId', isEqualTo: user.uid)
        .where('appLink', isEqualTo: appLink)
        .limit(1)
        .get();
    if (appQuery.docs.isNotEmpty) return true;

    return false;
  }

  Future<void> _registerApp() async {
    if (!_formKey.currentState!.validate()) return;

    final appName = _nameController.text.trim();
    final googleGroup = _googleGroupController.text.trim();
    final webLink = _webLinkController.text.trim();
    final appLink = _appLinkController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in before registering an app.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (!googleGroup.startsWith('https://groups.google.com/')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Google Group link.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (!(appLink.contains("play.google.com") || appLink.contains("google.com"))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Closed Testing or Play Store link!'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔥 CHECK DIAMONDS BEFORE DOING ANYTHING
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userSnap = await userDocRef.get();
      int diamonds = (userSnap['diamonds'] ?? 0) as int;

      if (diamonds < 25) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough diamonds! You need 25 diamonds to register an app.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // 🔥 Check duplicates
      final isDuplicate = await _isDuplicateApp(appName, webLink, appLink);

      if (isDuplicate) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Duplicate app found! Please use different details.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // 🔥 CREATE APP ENTRY FIRST
      await FirebaseFirestore.instance.collection('apps').add({
        'userId': user.uid,
        'appName': appName,
        'description': _descController.text.trim(),
        'googleGroup': googleGroup,
        'webAppLink': webLink,
        'appLink': appLink,
        'installs': 0,
        'isPublic': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🔥 ONLY AFTER SUCCESS: DEDUCT 25 DIAMONDS
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final freshSnap = await transaction.get(userDocRef);
        int current = (freshSnap['diamonds'] ?? 0) as int;
        transaction.update(userDocRef, {'diamonds': current - 25});
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App registered successfully! 25 diamonds deducted.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NavigationBarPage()),
      );

    } catch (e) {
      debugPrint('Firestore Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to register app: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const greenDark = Color(0xFF2E7D32);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Register App', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: greenDark.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: const DecorationImage(
                      image: AssetImage('assets/closed_testing.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Text(
                            'App Details',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: greenDark,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(_nameController, 'App Name', true),
                          _buildTextField(_descController, 'Description', true),
                          _buildTextField(_googleGroupController, 'Google Group Link', true),
                          _buildTextField(_webLinkController, 'Join on Web App Link', false),
                          _buildTextField(_appLinkController, 'Join on Android App Link', true),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: greenDark,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                              onPressed: _isLoading ? null : _registerApp,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Submit',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Make sure Google Group and Closed Testing links are correct before submitting.',
                  style: TextStyle(
                    color: greenDark.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool required, {
    void Function(String)? onChanged,
  }) {
    const greenDark = Color(0xFF2E7D32);
    const greenLight = Color(0xFF81C784);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        validator: required ? (v) => v!.isEmpty ? 'Please enter $label' : null : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: greenDark),
          filled: true,
          fillColor: const Color(0xFFF9FBE7),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: greenLight),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: greenDark, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
