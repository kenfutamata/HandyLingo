import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Sign_Up extends StatelessWidget {
  const Sign_Up({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3CBFF3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              /// Logo
              Image.asset(
                'assets/images/handylingologo.png',
                height: 180,
              ),

              const SizedBox(height: 20),

              Text(
                "Create your Account",
                style: GoogleFonts.inter(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 30),

              _buildTextField("First Name"),
              _buildTextField("Last Name"),
              _buildTextField("Username"),
              _buildTextField("Email"),
              _buildTextField("Password", isPassword: true),
              _buildTextField("Confirm Password", isPassword: true),

              const SizedBox(height: 16),

              Text(
                "By creating an account, you agree to our\nTerms of Use and Privacy Policy",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 24),

              /// Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    // TODO: Sign up logic
                  },
                  child: Text(
                    "Sign Up",
                    style: GoogleFonts.inter(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
