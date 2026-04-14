import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/AuthController.dart';
import 'Sign_up.dart';
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

  /// Handles the Sign In process
  Future<void> _signIn() async {
    final credential = _credentialController.text.trim();
    final password = _passwordController.text;

    if (credential.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both credential and password')),
      );
      return;
    }

    setState(() => _loading = true);
    final auth = ref.read(authRepositoryProvider);

    try {
      // 1. Perform Authentication via Supabase
      final info = await auth.signIn(credential: credential, password: password);
      final userId = info['id'];

      if (userId != null) {
        // 2. Access SharedPreferences to handle login count logic
        final prefs = await SharedPreferences.getInstance();
        String key = 'login_count_$userId';
        
        int loginCount = prefs.getInt(key) ?? 0;
        loginCount++; // Increment the count
        await prefs.setInt(key, loginCount);

        // 3. Navigation Decision
        if (!mounted) return;
        
        if (loginCount > 1) {
          // Returning user -> Go straight to feature
          Navigator.of(context).pushReplacementNamed('/start-using');
        } else {
          // New/First-time user -> Go to Welcome Dashboard
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Handles Google Sign In
  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // Note: Navigation for Google Sign-In is usually handled by the 
      // AuthState listener in main.dart because it involves an external browser.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
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
                // Logo
                Image.asset('assets/images/handylingologo.png', height: 220),
                const SizedBox(height: 50),
                
                // Input Fields
                _buildLabel("Email or Username"),
                _buildTextField(_credentialController, false),
                const SizedBox(height: 24),
                
                _buildLabel("Password"),
                _buildTextField(_passwordController, true),
                
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const ForgotPassword())
                    ),
                    child: Text(
                      "Forgot Password?", 
                      style: GoogleFonts.inter(
                        fontSize: 12, 
                        color: Colors.white, 
                        decoration: TextDecoration.underline
                      ),
                    ),
                  ),
                ),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(41)),
                    ),
                    child: _loading 
                      ? const CircularProgressIndicator(color: Colors.blue) 
                      : Text(
                          "Sign In", 
                          style: GoogleFonts.inter(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)
                        ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Google Sign In
                InkWell(
                  onTap: _loading ? null : _signInWithGoogle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/google.png', height: 24),
                      const SizedBox(width: 12),
                      Text(
                        "Sign in with Google", 
                        style: GoogleFonts.inter(
                          fontSize: 14, 
                          color: Colors.white, 
                          decoration: TextDecoration.underline
                        )
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 80),
                
                // Sign Up Link
                InkWell(
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const Sign_Up())
                  ),
                  child: Text(
                    "Don't have an account? Sign Up", 
                    style: GoogleFonts.inter(
                      fontSize: 14, 
                      color: Colors.white, 
                      decoration: TextDecoration.underline
                    )
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for Labels
  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft, 
      child: Text(
        text, 
        style: GoogleFonts.inter(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w500)
      )
    );
  }

  // Helper widget for TextFields
  Widget _buildTextField(TextEditingController controller, bool obscure) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), 
            borderSide: BorderSide.none
          ),
        ),
      ),
    );
  }
}