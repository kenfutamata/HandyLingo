import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class SkeletonPainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;

  SkeletonPainter(this.poses, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.greenAccent;

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.red;

    for (final pose in poses) {
      // Draw Dots
      pose.landmarks.forEach((_, landmark) {
        canvas.drawCircle(
          Offset(
            landmark.x * size.width / imageSize.width,
            landmark.y * size.height / imageSize.height,
          ),
          4,
          dotPaint,
        );
      });

      // Helper to draw lines between joints
      void paintLine(PoseLandmarkType type1, PoseLandmarkType type2) {
        final joint1 = pose.landmarks[type1];
        final joint2 = pose.landmarks[type2];
        if (joint1 != null && joint2 != null) {
          canvas.drawLine(
            Offset(joint1.x * size.width / imageSize.width, joint1.y * size.height / imageSize.height),
            Offset(joint2.x * size.width / imageSize.width, joint2.y * size.height / imageSize.height),
            paint,
          );
        }
      }

      // Draw connections for Sign Language (Arms & Hands)
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
      paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}