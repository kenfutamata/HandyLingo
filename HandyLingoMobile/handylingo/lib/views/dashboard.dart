import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DashboardSLtoTA extends StatelessWidget {
  const DashboardSLtoTA({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(213, 232, 240, 1),

      /// Top Bar
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color.fromRGBO(60, 191, 243, 1),
        title: Text(
          "HandyLingo",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset(
              'assets/images/downloadremovebgpreview_2.png',
              width: 22,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          /// Camera Preview Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  "Camera Feed",
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// Hint Text
          Text(
            "Tap or Hold to Translate",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 70),
        ],
      ),

      /// Floating Translate Button (Ellipse Stack)
      floatingActionButton: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            "assets/images/ellipse_1.svg",
            height: 80,
            width: 80,
          ),
          SvgPicture.asset(
            "assets/images/ellipse_2.svg",
            height: 60,
            width: 60,
          ),
          SvgPicture.asset(
            "assets/images/ellipse_3.svg",
            height: 30,
            width: 30,
          ),
          IconButton(
            icon: const Icon(Icons.translate),
            color: Colors.black,
            onPressed: () {},
          ),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      /// Bottom Bar
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromRGBO(60, 191, 243, 1),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 66,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// 3D Button
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.view_in_ar, size: 22),
                    Text(
                      "3D",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                /// Account Button
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person, size: 22),
                    Text("Account", style: GoogleFonts.inter(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
