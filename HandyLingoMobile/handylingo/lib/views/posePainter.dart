class PosePainter extends CustomPainter {
  PosePainter(this.pose, this.absoluteImageSize, this.isFrontCamera);

  final Pose pose;
  final Size absoluteImageSize;
  final bool isFrontCamera;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.greenAccent;

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.red;

    // ML Kit returns coordinates relative to the input image.
    // In portrait mode, the image width/height are swapped.
    final double scaleX = size.width / absoluteImageSize.height;
    final double scaleY = size.height / absoluteImageSize.width;

    double translateX(double x) {
      if (isFrontCamera) {
        // Mirror the X coordinate for front camera
        return size.width - (x * scaleX);
      }
      return x * scaleX;
    }

    double translateY(double y) {
      return y * scaleY;
    }

    // Helper to draw lines between joints
    void paintLine(PoseLandmarkType type1, PoseLandmarkType type2) {
      final p1 = pose.landmarks[type1];
      final p2 = pose.landmarks[type2];
      
      // Only draw if confidence is high enough (prevents "jumpy" lines)
      if (p1 != null && p2 != null && p1.likelihood > 0.5 && p2.likelihood > 0.5) {
        canvas.drawLine(
          Offset(translateX(p1.x), translateY(p1.y)),
          Offset(translateX(p2.x), translateY(p2.y)),
          paint,
        );
      }
    }

    // Draw Skeleton Connections
    paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

    // Draw individual joints (Dots)
    pose.landmarks.forEach((_, landmark) {
      if (landmark.likelihood > 0.5) {
        canvas.drawCircle(
          Offset(translateX(landmark.x), translateY(landmark.y)),
          5,
          dotPaint,
        );
      }
    });
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) => true;
}