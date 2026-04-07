import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // REQUIRED
import '../controller/AuthController.dart';
import 'Sign_up.dart';
import 'welcome_dashboard.dart';
import 'start_using.dart'; // NEW IMPORT
import 'forgot_password.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter both credential and password')));
      return;
    }

    setState(() => _loading = true);
    final auth = ref.read(authRepositoryProvider);

    try {
      final info = await auth.signIn(credential: credential, password: password);
      final userId = info['id'];

      if (userId != null) {
        final prefs = await SharedPreferences.getInstance();
        int loginCount = prefs.getInt('login_count_$userId') ?? 0;
        
        // Safety: If the listener in main.dart hasn't fired yet, increment here
        if (loginCount == 0) {
           loginCount = 1;
           await prefs.setInt('login_count_$userId', 1);
        }

        if (loginCount > 1) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const StartUsingPage()));
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const WelcomeDashboard()));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
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
                Image.asset('assets/images/handylingologo.png', height: 220),
                const SizedBox(height: 50),
                
                _buildLabel("Email or Username"),
                _buildTextField(_credentialController, false),
                const SizedBox(height: 24),
                
                _buildLabel("Password"),
                _buildTextField(_passwordController, true),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPassword())),
                    child: Text("Forgot Password?", style: GoogleFonts.inter(fontSize: 12, color: Colors.white, decoration: TextDecoration.underline)),
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(41)),
                    ),
                    child: _loading ? const CircularProgressIndicator() : Text("Sign In", style: GoogleFonts.inter(fontSize: 16, color: Colors.black)),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // --- CORRECTED GOOGLE SIGN IN ---
                InkWell(
                  onTap: () async {
                    setState(() => _loading = true);
                    try {
                      await ref.read(authRepositoryProvider).signInWithGoogle();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/google.png', height: 24),
                      const SizedBox(width: 12),
                      Text("Sign in with Google", style: GoogleFonts.inter(fontSize: 14, color: Colors.white, decoration: TextDecoration.underline)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 80),
                InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Sign_Up())),
                  child: Text("Don't have an account? Sign Up", style: GoogleFonts.inter(fontSize: 14, color: Colors.white, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(alignment: Alignment.centerLeft, child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: Colors.black)));
  }

  Widget _buildTextField(TextEditingController controller, bool obscure) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}