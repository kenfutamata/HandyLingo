import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/AuthController.dart';
import 'Sign_up.dart';
import 'welcome_dashboard.dart';

class Sign_in extends ConsumerStatefulWidget {
  const Sign_in({super.key});

  @override
  ConsumerState<Sign_in> createState() => _SignInState();
}

class _SignInState extends ConsumerState<Sign_in> {
  final TextEditingController _credentialController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _signIn() async {
    final credential = _credentialController.text.trim();
    final password = _passwordController.text;

    if (credential.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both credential and password'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final auth = ref.read(authRepositoryProvider);

    try {
      final info = await auth.signIn(
        credential: credential,
        password: password,
      );

      // Navigate based on role
      final role = info['role'] ?? 'user';
      if (role == 'user') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeDashboard()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _credentialController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color.fromRGBO(60, 191, 243, 1),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 40),

                /// LOGO
                Image.asset('assets/images/handylingologo.png', height: 220),

                const SizedBox(height: 50),

                /// EMAIL FIELD
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Email or Username",
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _credentialController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// PASSWORD FIELD
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Password",
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                /// SIGN IN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(41),
                        side: const BorderSide(color: Colors.black),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const CircularProgressIndicator()
                        : Text(
                            "Sign In",
                            style: GoogleFonts.inter(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Or Sign in using",
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.black),
                  ),
                ),
                //Google Sign in
                const SizedBox(height: 24),
                InkWell(
                  onTap: () async {
                    const url = 'https://your-google-signin-url.com';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    } else {
                      throw 'Could not launch $url';
                    }
                  },
                  child: Image.asset('assets/images/google.png'),
                ),
                const SizedBox(height: 80),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Sign_Up()),
                    );
                  },
                  child: Text(
                    "Don't have an account? Sign Up",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
